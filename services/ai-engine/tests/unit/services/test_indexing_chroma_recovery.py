"""Service retry must reprocess mixed hashes left after an atomic Chroma upsert."""

from dataclasses import replace
from unittest.mock import AsyncMock

import httpx
import pytest

from engine.adapters.vectorstore.chroma import ChromaVectorStore
from engine.core.models import JobStatus
from engine.services.indexing_service import IndexingService
from tests.unit.adapters.vectorstore.fake_chroma_client import FakeChromaClient
from tests.unit.services.indexing_fakes import Harness


@pytest.mark.parametrize("stage", ["get", "delete"])
async def test_service_retries_mixed_hash_path_after_cleanup_failure(stage: str) -> None:
    h = Harness()
    fake = FakeChromaClient()
    store = ChromaVectorStore(fake.client)
    h.service = IndexingService(h.scanner, h.chunker, h.embedder, store)
    assert (await h.run()).status == JobStatus.SUCCEEDED
    before = {r.chunk.path: r.chunk for r in await store.query("proj_p", [1.0, 0.0])}
    residue = replace(before["b.py"], chunk_id="removed-function", symbol="removed")
    await store.upsert("proj_p", [residue], [[1.0, 0.0]])
    h.scanner.files.update(dict.fromkeys(["a.py", "b.py"], "def f():\n    return 2\n"))
    collection = fake.collections["proj_p"]
    operation = getattr(collection.handle, stage)
    assert isinstance(operation, AsyncMock)
    original = operation.side_effect

    async def fail_b_cleanup(**kwargs: object) -> object:
        if kwargs.get("where") == {"path": "b.py"} or kwargs.get("ids") == ["removed-function"]:
            raise httpx.ReadError("injected b cleanup")
        return await original(**kwargs)

    operation.side_effect = fail_b_cleanup
    done = await h.run()
    assert done.status == JobStatus.FAILED
    operation.side_effect = original
    rows = {r.chunk.chunk_id: r.chunk for r in await store.query("proj_p", [1.0, 0.0], top_k=100)}
    assert set(rows) == {before["a.py"].chunk_id, before["b.py"].chunk_id, residue.chunk_id}
    for path in ["a.py", "b.py"]:
        assert rows[before[path].chunk_id].raw_code == h.scanner.files[path]
    assert rows[residue.chunk_id] == residue
    assert set(await store.get_file_hashes("proj_p")) == {"a.py"}
    h.embedder.calls.clear()
    retry = await h.run()
    assert retry.status == JobStatus.SUCCEEDED
    assert retry.stats is not None
    assert retry.stats.files_changed == 1
    assert len(h.embedder.calls) == 1
    assert "b.py" in h.embedder.calls[0][0]
    final = {r.chunk.path: r.chunk for r in await store.query("proj_p", [1.0, 0.0], top_k=100)}
    clean = Harness()
    clean.scanner.files = dict(h.scanner.files)
    await clean.run()
    assert final == await clean.rows()
    assert await store.get_file_hashes("proj_p") == await clean.store.get_file_hashes("proj_p")
