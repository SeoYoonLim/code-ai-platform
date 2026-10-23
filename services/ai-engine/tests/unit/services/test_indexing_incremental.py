"""Incremental identity, full mode, and fingerprint rules."""

import pytest

from engine.core.models import IndexMode, IndexRequest, JobStatus
from engine.services.indexing_service import IndexingService
from tests.unit.services.indexing_fakes import Embedder, Harness


async def test_incremental_noop_edit_delete_rename() -> None:
    h = Harness()
    initial = await h.run()
    assert initial.stats is not None
    assert initial.stats.files_changed == 2
    h.embedder.calls.clear()
    noop = await h.run()
    assert noop.stats is not None
    assert noop.stats.files_changed == 0
    assert h.embedder.calls == []
    h.scanner.files["a.py"] = "def f():\n    return 2\n"
    changed = await h.run()
    assert changed.stats is not None
    assert changed.stats.files_changed == 1
    assert len(h.embedder.calls) == 1
    assert "# path: a.py" in h.embedder.calls[0][0]
    assert (await h.rows())["a.py"].raw_code == h.scanner.files["a.py"]
    h.scanner.files["c.py"] = h.scanner.files.pop("b.py")
    renamed = await h.run()
    assert renamed.stats is not None
    assert (renamed.stats.files_changed, renamed.stats.files_deleted) == (1, 1)
    assert set(await h.rows()) == {"a.py", "c.py"}
    del h.scanner.files["c.py"]
    deleted = await h.run()
    assert deleted.stats is not None
    assert deleted.stats.files_deleted == 1
    assert set(await h.rows()) == {"a.py"}


@pytest.mark.parametrize("change", ["model", "policy"])
async def test_fingerprint_model_or_policy_reindexes_all(change: str) -> None:
    h = Harness()
    await h.run()
    old = await h.store.get_file_hashes("proj_p")
    embedder = Embedder(dimension=2, model_name="changed" if change == "model" else h.embedder.model_name)
    h.service = IndexingService(
        h.scanner,
        h.chunker,
        embedder,
        h.store,
        policy_version="changed" if change == "policy" else "chunk-v1",
    )
    done = await h.run()
    assert done.stats is not None
    assert done.stats.files_changed == 2
    assert len(embedder.calls) == 2
    assert all(v != old[p] for p, v in (await h.store.get_file_hashes("proj_p")).items())
    embedder.calls.clear()
    await h.run()
    assert embedder.calls == []


async def test_full_preserves_collection_and_removes_absent_paths() -> None:
    h = Harness()
    await h.run()
    del h.scanner.files["b.py"]
    done = await h.run(IndexRequest("p", "memory", mode=IndexMode.FULL))
    assert done.status == JobStatus.SUCCEEDED
    assert h.store.drops == 0
    assert done.stats is not None
    assert (done.stats.files_changed, done.stats.files_deleted) == (1, 1)
    assert set(await h.rows()) == {"a.py"}


@pytest.mark.parametrize("mode", [IndexMode.FULL, IndexMode.INCREMENTAL])
async def test_dimension_mismatch_only_full_drops(mode: IndexMode) -> None:
    h = Harness()
    await h.store.ensure_collection("proj_p", dimension=3)
    done = await h.run(IndexRequest("p", "memory", mode=mode))
    if mode == IndexMode.FULL:
        assert done.status == JobStatus.SUCCEEDED
        assert h.store.drops == 1
    else:
        assert done.status == JobStatus.FAILED
        assert h.store.drops == 0
        assert done.error is not None
        assert "dimension_mismatch" in done.error.message


async def test_generic_ensure_failure_never_drops() -> None:
    h = Harness()
    await h.run()
    before = await h.rows()
    h.store.fail_ensure = True
    done = await h.run(IndexRequest("p", "memory", mode=IndexMode.FULL))
    assert done.status == JobStatus.FAILED
    assert h.store.drops == 0
    assert await h.rows() == before


async def test_empty_chunks_do_not_embed_and_remove_path() -> None:
    h = Harness()
    await h.run()
    h.embedder.calls.clear()
    h.scanner.files["a.py"] = ""
    done = await h.run()
    assert done.status == JobStatus.SUCCEEDED
    assert h.embedder.calls == []
    assert set(await h.rows()) == {"b.py"}
