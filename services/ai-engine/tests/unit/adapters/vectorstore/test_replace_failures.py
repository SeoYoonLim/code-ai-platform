"""Atomic upsert and same-ID body-edit regressions; no server required."""

from collections.abc import Callable
from copy import deepcopy
from dataclasses import replace
from unittest.mock import AsyncMock

import httpx
import pytest
from chromadb.errors import InvalidArgumentError

from engine.adapters.vectorstore.chroma import ChromaVectorStore
from engine.core.errors import VectorStoreError
from engine.core.models import CodeChunk
from tests.unit.adapters.vectorstore.fake_chroma_client import FakeChromaClient


@pytest.mark.parametrize("stage", ["upsert", "get", "delete"])
async def test_replace_failure_stages_preserve_same_id_function(
    stage: str,
    chunk_factory: Callable[[int], CodeChunk],
) -> None:
    fake = FakeChromaClient()
    store = ChromaVectorStore(fake.client, batch_size=1)
    await store.ensure_collection("c", dimension=2)
    old = replace(chunk_factory(0), raw_code="def f():\n    return 1\n", content_hash="old")
    residue = replace(old, chunk_id="old-only", symbol="removed")
    other = chunk_factory(1)
    await store.upsert("c", [old, residue, other], [[1.0, 0.0]] * 3)
    new = replace(old, raw_code="def f():\n    return 2\n", content_hash="new")
    added = replace(new, chunk_id="new-only", symbol="added")
    assert new.chunk_id == old.chunk_id
    assert new.raw_code != old.raw_code
    collection = fake.collections["c_c"]
    before = deepcopy(collection.rows)
    operation = getattr(collection.handle, stage)
    assert isinstance(operation, AsyncMock)
    original = operation.side_effect
    operation.side_effect = httpx.ReadError("injected " + stage)
    with pytest.raises(VectorStoreError, match="injected"):
        await store.replace_file("c", old.path, [new, added], [[1.0, 0.0]] * 2)
    operation.side_effect = original
    rows = {r.chunk.chunk_id: r.chunk for r in await store.query("c", [1.0, 0.0], top_k=20)}
    if stage == "upsert":
        assert collection.rows == before  # rejection commits no rows, including same-ID overwrite
        assert rows == {c.chunk_id: c for c in [old, residue, other]}
        assert await store.get_file_hashes("c") == {old.path: "old", other.path: other.content_hash}
    else:
        assert rows == {c.chunk_id: c for c in [new, added, residue, other]}
        assert await store.get_file_hashes("c") == {other.path: other.content_hash}
    await store.replace_file("c", old.path, [new, added], [[1.0, 0.0]] * 2)
    assert {r.chunk.chunk_id: r.chunk for r in await store.query("c", [1.0, 0.0], top_k=20)} == {
        c.chunk_id: c for c in [new, added, other]
    }
    assert await store.get_file_hashes("c") == {old.path: "new", other.path: other.content_hash}
    assert isinstance(collection.handle.upsert, AsyncMock)
    assert len(collection.handle.upsert.call_args.kwargs["ids"]) == 2  # never split at batch_size=1
    assert isinstance(collection.handle.delete, AsyncMock)
    if stage != "upsert":
        assert collection.handle.delete.call_args.kwargs == {"ids": ["old-only"]}


async def test_replace_too_large_preserves_every_row(chunk_factory: Callable[[int], CodeChunk]) -> None:
    fake = FakeChromaClient()
    store = ChromaVectorStore(fake.client)
    await store.ensure_collection("c", dimension=2)
    old = chunk_factory(0)
    await store.upsert("c", [old], [[1.0, 0.0]])
    rows = deepcopy(fake.collections["c_c"].rows)
    fake.client.get_max_batch_size = AsyncMock(return_value=1)
    with pytest.raises(VectorStoreError) as caught:
        await store.replace_file("c", old.path, [old, replace(old, chunk_id="second")], [[1.0, 0.0]] * 2)
    assert caught.value.detail == {"reason": "replace_too_large"}
    assert fake.collections["c_c"].rows == rows
    assert (await store.query("c", [1.0, 0.0]))[0].chunk == old
    assert await store.get_file_hashes("c") == {old.path: old.content_hash}


async def test_fake_upsert_validates_whole_request_before_writing() -> None:
    fake = FakeChromaClient()
    handle = await fake.get_or_create_collection("collection", metadata={"dimension": 2})
    collection = fake.collections["collection"]
    await handle.upsert(ids=["old"], embeddings=[[1.0, 0.0]], documents=["old"], metadatas=[{"path": "a"}])
    before = deepcopy(collection.rows)
    with pytest.raises(InvalidArgumentError):
        await handle.upsert(
            ids=["old", "new"],
            embeddings=[[0.0, 1.0], [1.0]],
            documents=["changed", "new"],
            metadatas=[{"path": "a"}] * 2,
        )
    assert collection.rows == before
