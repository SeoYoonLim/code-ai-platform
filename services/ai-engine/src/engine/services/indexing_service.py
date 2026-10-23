"""Sequential failure-safe indexing through core ports."""

import asyncio
from collections.abc import Callable
from dataclasses import replace
from datetime import UTC, datetime
from hashlib import sha256
from uuid import uuid4

import structlog

from engine.core.errors import EngineError, JobConflict, ParseError, VectorStoreError
from engine.core.interfaces import CodeChunker, Embedder, SourceScanner, VectorStore
from engine.core.models import (
    IndexJob,
    IndexMode,
    IndexPhase,
    IndexRequest,
    IndexStats,
    JobError,
    JobProgress,
    JobStatus,
    SkippedFile,
    SourceFile,
)

CHUNK_POLICY_VERSION = "chunk-v1"
log = structlog.get_logger()


def collection_for(project_id: str) -> str:
    """Return the project's vector collection name."""
    return f"proj_{project_id}"


class IndexingService:
    """Jobs are immutable in-process snapshots; run never creates a background task."""

    def __init__(
        self,
        scanner: SourceScanner,
        chunker: CodeChunker,
        embedder: Embedder,
        store: VectorStore,
        *,
        policy_version: str = CHUNK_POLICY_VERSION,
        clock: Callable[[], datetime] | None = None,
        job_ids: Callable[[], str] | None = None,
        retention: int = 200,
    ) -> None:
        self._scanner, self._chunker, self._embedder, self._store = scanner, chunker, embedder, store
        self._policy = policy_version
        self._clock = clock or (lambda: datetime.now(UTC))
        self._ids = job_ids or (lambda: uuid4().hex)
        self._retention = retention
        self._jobs: dict[str, IndexJob] = {}
        self._canceled: set[str] = set()

    async def start(self, request: IndexRequest) -> IndexJob:
        """Check conflicts and register without yielding."""
        for job in self._jobs.values():
            if job.request.project_id == request.project_id and not job.status.terminal:
                raise JobConflict("project indexing already active", detail={"job_id": job.job_id})
        job = IndexJob(self._ids(), request, JobStatus.QUEUED, self._clock(), stats=IndexStats())
        self._jobs[job.job_id] = job
        self._prune()
        return job

    async def get(self, job_id: str) -> IndexJob | None:
        return self._jobs.get(job_id)

    async def list_jobs(
        self, *, project_id: str | None = None, status: JobStatus | None = None, limit: int = 50
    ) -> list[IndexJob]:
        """Return newest jobs first."""
        jobs = [
            j
            for j in self._jobs.values()
            if (project_id is None or j.request.project_id == project_id)
            and (status is None or j.status == status)
        ]
        return sorted(jobs, key=lambda j: j.created_at, reverse=True)[: max(0, limit)]

    async def cancel(self, job_id: str) -> IndexJob | None:
        """Request cancellation at a file boundary."""
        job = self._jobs.get(job_id)
        if job is None or job.status.terminal:
            return job
        self._canceled.add(job_id)
        if job.status == JobStatus.QUEUED:
            return self._finish(job_id, JobStatus.CANCELED)
        return job

    def _prune(self) -> None:
        terminal = sorted((j for j in self._jobs.values() if j.status.terminal), key=lambda j: j.created_at)
        for job in terminal[: max(0, len(self._jobs) - self._retention)]:
            del self._jobs[job.job_id]
            self._canceled.discard(job.job_id)

    def _finish(self, job_id: str, status: JobStatus, error: JobError | None = None) -> IndexJob:
        job = replace(self._jobs[job_id], status=status, error=error, finished_at=self._clock())
        self._jobs[job_id] = job
        self._canceled.discard(job_id)
        self._prune()
        return job

    def _stats(self, job_id: str, **increments: int) -> None:
        job = self._jobs[job_id]
        stats = job.stats or IndexStats()
        self._jobs[job_id] = replace(
            job,
            stats=replace(stats, **{key: getattr(stats, key) + value for key, value in increments.items()}),
        )

    def _progress(self, job_id: str, phase: IndexPhase, current: int, total: int) -> None:
        self._jobs[job_id] = replace(self._jobs[job_id], progress=JobProgress(current, total, phase))

    def _fingerprint(self, file: SourceFile) -> str:
        return sha256(
            f"{file.content_hash}\0{self._embedder.model_name}\0{self._policy}".encode()
        ).hexdigest()

    async def run(self, job_id: str) -> IndexJob:
        """Execute once, recording failures and propagating task cancellation."""
        job = self._jobs[job_id]
        if job.status != JobStatus.QUEUED:
            return job
        self._jobs[job_id] = replace(job, status=JobStatus.RUNNING, started_at=self._clock())
        try:
            await self._execute(job_id, job.request)
            status = JobStatus.CANCELED if job_id in self._canceled else JobStatus.SUCCEEDED
            return self._finish(job_id, status)
        except asyncio.CancelledError:
            self._finish(job_id, JobStatus.CANCELED)
            raise
        except EngineError as error:
            return self._finish(
                job_id, JobStatus.FAILED, JobError(error.code, error.message[:300], error.retryable)
            )
        except Exception as error:
            log.exception("indexing_failed", job_id=job_id)
            return self._finish(job_id, JobStatus.FAILED, JobError("internal_error", str(error)[:300]))

    async def _ensure(self, collection: str, request: IndexRequest) -> None:
        try:
            await self._store.ensure_collection(collection, dimension=self._embedder.dimension)
        except VectorStoreError as error:
            if error.detail.get("reason") != "dimension_mismatch":
                raise
            if request.mode != IndexMode.FULL:
                raise VectorStoreError(
                    "dimension_mismatch: retry with mode=full", detail=error.detail
                ) from error
            await self._store.drop_collection(collection)
            await self._store.ensure_collection(collection, dimension=self._embedder.dimension)

    async def _execute(self, job_id: str, request: IndexRequest) -> None:
        collection = collection_for(request.project_id)
        await self._ensure(collection, request)
        existing = await self._store.get_file_hashes(collection)
        seen: set[str] = set()
        changed: set[str] = set()
        scanned = 0
        self._progress(job_id, IndexPhase.SCANNING, 0, 0)
        async for item in self._scanner.scan(
            request.root, include_globs=request.include_globs, exclude_globs=request.exclude_globs
        ):
            if job_id in self._canceled:
                return
            if isinstance(item, SkippedFile):
                self._stats(job_id, files_skipped=1)
                continue
            seen.add(item.path)
            scanned += 1
            self._stats(job_id, files_scanned=1)
            if request.mode == IndexMode.FULL or existing.get(item.path) != self._fingerprint(item):
                changed.add(item.path)
            self._progress(job_id, IndexPhase.SCANNING, scanned, scanned)
        index = 0
        async for item in self._scanner.scan(
            request.root, include_globs=request.include_globs, exclude_globs=request.exclude_globs
        ):
            if job_id in self._canceled:
                return
            if isinstance(item, SkippedFile) or item.path not in changed:
                continue
            index += 1
            await self._replace(job_id, request, item, index, len(changed))
        if job_id in self._canceled:
            return
        deleted = sorted(set(existing) - seen)
        if deleted:
            await self._store.delete_by_paths(collection, deleted)
            self._stats(job_id, files_deleted=len(deleted))

    async def _replace(
        self, job_id: str, request: IndexRequest, file: SourceFile, index: int, total: int
    ) -> None:
        self._progress(job_id, IndexPhase.CHUNKING, index, total)
        try:
            chunks = self._chunker.chunk(file, project_id=request.project_id, commit_sha=request.commit_sha)
        except ParseError:
            log.info("indexing_skipped", path=file.path, reason="parse_error")
            self._stats(job_id, files_skipped=1)
            return
        chunks = [replace(c, content_hash=self._fingerprint(file)) for c in chunks]
        self._progress(job_id, IndexPhase.EMBEDDING, index, total)
        vectors = await self._embedder.embed_documents([c.search_text for c in chunks]) if chunks else []
        self._progress(job_id, IndexPhase.UPSERTING, index, total)
        try:
            await self._store.replace_file(collection_for(request.project_id), file.path, chunks, vectors)
        except VectorStoreError as error:
            if error.detail.get("reason") != "replace_too_large":
                raise
            log.info("indexing_skipped", path=file.path, reason="too_many_chunks")
            self._stats(job_id, files_skipped=1)
            return
        self._stats(job_id, files_changed=1, chunks_upserted=len(chunks))
