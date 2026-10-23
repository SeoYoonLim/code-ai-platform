"""Job lifecycle, cancellation, progress, and retention."""

import asyncio
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, patch

import pytest

from engine.core.errors import JobConflict
from engine.core.models import IndexPhase, IndexRequest, JobStatus
from engine.services.indexing_service import IndexingService
from tests.unit.services.indexing_fakes import Harness


async def test_job_queued_terminal_cancel_and_conflict() -> None:
    h = Harness()
    job = await h.service.start(IndexRequest("p", "memory"))
    with pytest.raises(JobConflict) as caught:
        await h.service.start(job.request)
    assert caught.value.detail == {"job_id": job.job_id}
    other = await h.service.start(IndexRequest("other", "memory"))
    assert other.job_id != job.job_id
    canceled = await h.service.cancel(job.job_id)
    assert canceled is not None
    assert canceled.status == JobStatus.CANCELED
    assert await h.service.run(job.job_id) == canceled
    assert await h.service.cancel(job.job_id) == canceled
    assert await h.service.cancel("absent") is None
    assert await h.service.get("absent") is None
    assert (await h.service.start(job.request)).status == JobStatus.QUEUED
    with pytest.raises(KeyError):
        await h.service.run("absent")


async def test_running_cancel_at_file_boundary_and_progress() -> None:
    h = Harness()
    job = await h.service.start(IndexRequest("p", "memory"))
    phases = []
    original_progress = h.service._progress
    original_replace = h.store.replace_file

    def observe(job_id: str, phase: IndexPhase, current: int, total: int) -> None:
        assert current <= total
        phases.append(phase)
        original_progress(job_id, phase, current, total)

    async def replace_and_cancel(*args: object, **kwargs: object) -> None:
        await original_replace(*args, **kwargs)
        running = await h.service.get(job.job_id)
        assert running is not None
        assert running.status == JobStatus.RUNNING
        assert await h.service.run(job.job_id) == running
        with pytest.raises(JobConflict) as caught:
            await h.service.start(job.request)
        assert caught.value.detail == {"job_id": job.job_id}
        await h.service.cancel(job.job_id)

    with (
        patch.object(h.service, "_progress", side_effect=observe),
        patch.object(h.store, "replace_file", side_effect=replace_and_cancel),
    ):
        done = await h.service.run(job.job_id)
    assert done.status == JobStatus.CANCELED
    assert done.stats is not None
    assert done.stats.files_changed == 1
    assert set(await h.rows()) == {"a.py"}
    assert phases == [IndexPhase.SCANNING] * 3 + [
        IndexPhase.CHUNKING,
        IndexPhase.EMBEDDING,
        IndexPhase.UPSERTING,
    ]
    before = await h.rows()
    assert await h.service.run(job.job_id) == done
    assert await h.rows() == before


async def test_async_task_cancellation_records_then_propagates() -> None:
    h = Harness()
    entered = asyncio.Event()
    blocked = asyncio.Event()

    async def wait_for_cancel(texts: object) -> list[list[float]]:
        entered.set()
        await blocked.wait()
        return []

    job = await h.service.start(IndexRequest("p", "memory"))
    with patch.object(h.embedder, "embed_documents", side_effect=wait_for_cancel):
        task = asyncio.create_task(h.service.run(job.job_id))
        await asyncio.wait_for(entered.wait(), 2)
        task.cancel()
        with pytest.raises(asyncio.CancelledError):
            await task
    done = await h.service.get(job.job_id)
    assert done is not None
    assert done.status == JobStatus.CANCELED
    assert done.finished_at is not None
    assert await h.rows() == {}


async def test_jobs_retention_filters_and_immutable_snapshots() -> None:
    h = Harness()
    times = iter(datetime(2026, 1, 1, tzinfo=UTC) + timedelta(seconds=i) for i in range(100))
    ids = iter(["active", "old", "new"])
    h.service = IndexingService(
        h.scanner,
        h.chunker,
        h.embedder,
        h.store,
        retention=2,
        clock=lambda: next(times),
        job_ids=lambda: next(ids),
    )
    active = await h.service.start(IndexRequest("active", "memory"))
    old = await h.service.start(IndexRequest("old", "memory"))
    terminal = await h.service.run(old.job_id)
    assert old.status == JobStatus.QUEUED
    assert terminal.status == JobStatus.SUCCEEDED
    new = await h.service.start(IndexRequest("new", "memory"))
    assert await h.service.get(old.job_id) is None
    assert await h.service.get(active.job_id) == active
    assert await h.service.list_jobs(limit=1) == [new]
    assert await h.service.list_jobs(project_id="active", status=JobStatus.QUEUED) == [active]
    assert await h.service.list_jobs(limit=0) == []


async def test_unexpected_error_recorded_and_message_truncated() -> None:
    h = Harness()
    with patch.object(h.embedder, "embed_documents", new=AsyncMock(side_effect=RuntimeError("x" * 400))):
        done = await h.run()
    assert done.status == JobStatus.FAILED
    assert done.error is not None
    assert done.error.code == "internal_error"
    assert len(done.error.message) == 300
