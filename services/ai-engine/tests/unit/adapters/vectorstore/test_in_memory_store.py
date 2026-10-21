"""Vector store conformance and in-memory boundary cases."""

from collections.abc import Callable
from dataclasses import replace

import pytest

from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.errors import VectorStoreError
from engine.core.interfaces.vector_store import VectorStore
from engine.core.models import CodeChunk, MetadataFilter
from tests.conformance.vector_store_suite import VectorStoreConformance


class TestInMemoryVectorStore(VectorStoreConformance):
    @pytest.fixture
    def store(self, in_memory_store: InMemoryVectorStore) -> VectorStore:
        return in_memory_store


async def test_invalid_batch_is_atomic(chunk_factory: Callable[[int], CodeChunk]) -> None:
    store = InMemoryVectorStore()
    await store.ensure_collection("c", dimension=2)
    with pytest.raises(VectorStoreError):
        await store.upsert("c", [chunk_factory(0), chunk_factory(1)], [[1.0, 0.0], [1.0]])
    assert await store.query("c", [1.0, 0.0]) == []


async def test_copies_vectors_and_collection_isolation(chunk_factory: Callable[[int], CodeChunk]) -> None:
    store = InMemoryVectorStore()
    for name in ["a", "b"]:
        await store.ensure_collection(name, dimension=2)
    vector = [1.0, 0.0]
    await store.upsert("a", [chunk_factory(0)], [vector])
    vector[0] = -1.0
    assert (await store.query("a", [1.0, 0.0]))[0].score == 1.0
    assert await store.query("b", [1.0, 0.0]) == []
    assert await store.query("a", [1.0, 0.0], top_k=0) == []


async def test_shared_path_deletion_and_all_filter_keys(chunk_factory: Callable[[int], CodeChunk]) -> None:
    store = InMemoryVectorStore()
    await store.ensure_collection("c", dimension=2)
    chunks = [replace(chunk_factory(i), path="shared.py", content_hash="same") for i in range(2)]
    await store.upsert("c", chunks, [[0.0, 0.0], [1.0, 0.0]])
    assert await store.get_file_hashes("c") == {"shared.py": "same"}
    where = MetadataFilter(
        {"path": "shared.py", "language": "python", "kind": "function", "symbol": "f0", "commit_sha": "abc"}
    )
    results = await store.query("c", [1.0, 0.0], where=where)
    assert len(results) == 1
    assert results[0].score == 0.0
    assert await store.delete_by_paths("c", ["shared.py", "shared.py"]) == 2
    await store.drop_collection("c")
    await store.ensure_collection("c", dimension=3)
    assert await store.query("c", [1.0, 0.0, 0.0]) == []


async def test_invalid_collection_dimension() -> None:
    with pytest.raises(VectorStoreError):
        await InMemoryVectorStore().ensure_collection("c", dimension=0)
