"""Guard the measured fake semantics independently of the adapter."""

import asyncio
from collections.abc import Awaitable, Callable

import pytest
from chromadb.errors import InvalidArgumentError, NotFoundError

from engine.adapters.vectorstore.chroma import ChromaVectorStore
from engine.core.errors import VectorStoreError
from engine.core.models import CodeChunk
from tests.unit.adapters.vectorstore.fake_chroma_client import FakeChromaClient, FakeCollection


async def run[R](call: Awaitable[R]) -> R:
    return await asyncio.wait_for(call, 5)


async def test_fake_measured_wire() -> None:
    fake = FakeChromaClient()
    for name in ["c", "ab", "abc-", "_abc", "a!b", "a" * 513]:
        with pytest.raises(InvalidArgumentError):
            await run(fake.get_or_create_collection(name))
        with pytest.raises(NotFoundError):
            await run(fake.get_collection(name))
        with pytest.raises(NotFoundError):
            await run(fake.delete_collection(name))
    collection = FakeCollection({"dimension": 99})
    await run(
        collection.upsert(
            ids=["a", "b", "c"],
            embeddings=[[1.0, 0.0], [1.0, 1.0], [-1.0, 0.0]],
            documents=["a", "b", "c"],
            metadatas=[{"path": "p", "commit_sha": None}] * 3,
        )
    )
    assert collection.dimension == 2
    assert "commit_sha" not in collection.rows["a"][2]
    result = await run(collection.query(query_embeddings=[[2.0, 0.0]], n_results=100))
    assert result["distances"] == [[0.0, pytest.approx(0.292893218), 2.0]]
    assert (await run(collection.query(query_embeddings=[[0.0, 0.0]], n_results=8)))["distances"] == [
        [1.0] * 3
    ]
    predicates: list[dict[str, object]] = [
        {"path": "p", "symbol": "s"},
        {"path": {"$in": []}},
        {"path": None},
    ]
    for where in predicates:
        with pytest.raises(ValueError, match=r".+"):
            await run(collection.query(query_embeddings=[[1.0, 0.0]], n_results=8, where=where))
    with pytest.raises(ValueError, match="empty"):
        await run(collection.upsert(ids=[], embeddings=[], documents=[], metadatas=[]))
    with pytest.raises(ValueError, match="empty"):
        await run(collection.delete(ids=[]))
    with pytest.raises(ValueError, match="non-empty"):
        await run(collection.delete(where={"path": {"$in": []}}))
    with pytest.raises(TypeError):
        await run(collection.query(query_embeddings=[[1.0, 0.0]], n_results=0))
    with pytest.raises(InvalidArgumentError):
        await run(collection.query(query_embeddings=[[1.0]], n_results=1))
    with pytest.raises(InvalidArgumentError):
        await run(collection.upsert(ids=["d"], embeddings=[[1.0]], documents=["d"], metadatas=[{}]))
    assert await run(collection.delete(where={"path": {"$in": ["p", "p"]}})) == {"deleted": 3}


async def test_dimension_check_prevents_partial_batch(chunk_factory: Callable[[int], CodeChunk]) -> None:
    fake = FakeChromaClient()
    store = ChromaVectorStore(fake.client, batch_size=1)
    await run(store.ensure_collection("c", dimension=2))
    with pytest.raises(VectorStoreError):
        await run(store.upsert("c", [chunk_factory(0), chunk_factory(1)], [[1.0, 0.0], [1.0]]))
    assert await run(store.query("c", [1.0, 0.0])) == []
    assert fake.collections["c_c"].metadata == {"dimension": 2}
    with pytest.raises(ValueError, match="positive"):
        ChromaVectorStore(fake.client, batch_size=0)
