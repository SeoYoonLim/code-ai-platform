"""Chroma boundary conformance and regression checks."""

import asyncio
import random
from collections.abc import Awaitable, Callable
from dataclasses import replace
from unittest.mock import AsyncMock

import httpx
import pytest
from chromadb.api import AsyncClientAPI
from chromadb.api.models.AsyncCollection import AsyncCollection
from chromadb.errors import InvalidArgumentError, NotFoundError
from pydantic import AnyHttpUrl

from engine.adapters.vectorstore.chroma import ChromaVectorStore, connect
from engine.adapters.vectorstore.chroma_codec import collection_name
from engine.core.errors import CollectionNotFound, VectorStoreError
from engine.core.interfaces.vector_store import VectorStore
from engine.core.models import ChunkKind, CodeChunk, Language, MetadataFilter
from engine.core.models.retrieval import MetadataValue
from engine.settings import Settings
from tests.conformance.vector_store_suite import VectorStoreConformance
from tests.unit.adapters.vectorstore.fake_chroma_client import FakeChromaClient


def bound[**P, R](method: Callable[P, Awaitable[R]]) -> Callable[P, Awaitable[R]]:
    async def invoke(*args: P.args, **kwargs: P.kwargs) -> R:
        return await asyncio.wait_for(method(*args, **kwargs), 5)

    return invoke


def bounded_store(fake: FakeChromaClient) -> ChromaVectorStore:
    result = ChromaVectorStore(fake.client)
    for name in (
        "ensure_collection",
        "upsert",
        "replace_file",
        "query",
        "delete_by_paths",
        "get_file_hashes",
        "drop_collection",
    ):
        setattr(result, name, bound(getattr(result, name)))
    return result


@pytest.fixture
def fake() -> FakeChromaClient:
    return FakeChromaClient()


@pytest.fixture
def store(fake: FakeChromaClient) -> ChromaVectorStore:
    return bounded_store(fake)


class TestChromaVectorStore(VectorStoreConformance):
    @pytest.fixture
    def store(self, fake: FakeChromaClient) -> VectorStore:
        return bounded_store(fake)


def test_name_injectivity() -> None:
    rng = random.Random(104)
    names = {"c", "ab", "c_c", "e_c_c", "proj_a-", "proj_a-x", "proj_a-xx", "abc", "a_"}
    names.update("proj_" + "".join(rng.choices("abcxyz012_-", k=64)) for _ in range(500))
    mapped = [collection_name(name) for name in names]
    assert len(set(mapped)) == len(names)
    assert collection_name("abc") == "abc"
    assert collection_name("c") == "c_c"


@pytest.mark.parametrize("name", ["c", "ab", "proj_a-", "proj_b_", "proj_" + "a" * 64])
@pytest.mark.parametrize("operation", ["ensure", "upsert", "query", "delete", "hashes", "drop"])
async def test_mapping_every_operation(
    store: ChromaVectorStore, name: str, operation: str, chunk_factory: Callable[[int], CodeChunk]
) -> None:
    await store.ensure_collection(name, dimension=2)
    await store.upsert(name, [chunk_factory(0)], [[1.0, 0.0]])
    if operation == "ensure":
        await store.ensure_collection(name, dimension=2)
    elif operation == "upsert":
        await store.upsert(name, [chunk_factory(1)], [[1.0, 0.0]])
    elif operation == "query":
        assert len(await store.query(name, [1.0, 0.0])) == 1
    elif operation == "delete":
        assert await store.delete_by_paths(name, ["file0.py"]) == 1
    elif operation == "hashes":
        assert await store.get_file_hashes(name) == {"file0.py": "hash0"}
    else:
        await store.drop_collection(name)
        with pytest.raises(CollectionNotFound):
            await store.get_file_hashes(name)


@pytest.mark.parametrize("language", list(Language))
@pytest.mark.parametrize("kind", list(ChunkKind))
@pytest.mark.parametrize("commit", [None, "abc"])
async def test_chunk_round_trip(
    store: ChromaVectorStore,
    chunk_factory: Callable[[int], CodeChunk],
    language: Language,
    kind: ChunkKind,
    commit: str | None,
) -> None:
    chunk = replace(
        chunk_factory(0),
        language=language,
        kind=kind,
        commit_sha=commit,
        metadata={"path": "wrong", "kind": "wrong", "symbol": "wrong", "m_x": 7, "flag": True, "ratio": 0.5},
    )
    await store.ensure_collection("c", dimension=2)
    await store.upsert("c", [chunk], [[1.0, 0.0]])
    assert (await store.query("c", [1.0, 0.0]))[0].chunk == chunk


async def test_empty_order_and_filters(
    store: ChromaVectorStore, fake: FakeChromaClient, chunk_factory: Callable[[int], CodeChunk]
) -> None:
    with pytest.raises(ValueError, match=r".+"):
        await store.upsert("missing", [chunk_factory(0)], [])
    with pytest.raises(CollectionNotFound):
        await store.upsert("missing", [chunk_factory(0)], [[1.0]])
    for operation in (store.upsert("missing", [], []), store.delete_by_paths("missing", [])):
        with pytest.raises(CollectionNotFound):
            await operation
    with pytest.raises(CollectionNotFound):
        await store.query("missing", [1.0, 0.0], top_k=0)
    with pytest.raises(CollectionNotFound):
        await store.query("missing", [1.0, 0.0], where=MetadataFilter({"path": ()}))
    await store.ensure_collection("c", dimension=2)
    assert isinstance(fake.client.get_or_create_collection, AsyncMock)
    assert fake.client.get_or_create_collection.call_args.kwargs["configuration"] == {
        "hnsw": {"space": "cosine"}
    }
    handle = fake.collections["c_c"].handle
    await store.upsert("c", [], [])
    assert await store.delete_by_paths("c", []) == 0
    for k in [0, -1]:
        assert await store.query("c", [1.0, 0.0], top_k=k) == []
    assert await store.query("c", [1.0, 0.0], where=MetadataFilter({"path": ()})) == []
    assert isinstance(handle.upsert, AsyncMock)
    assert isinstance(handle.delete, AsyncMock)
    assert isinstance(handle.query, AsyncMock)
    handle.upsert.assert_not_called()
    handle.delete.assert_not_called()
    handle.query.assert_not_called()
    with pytest.raises(VectorStoreError):
        await store.query("c", [1.0], top_k=0)
    # Deliberately malformed runtime input beyond the annotated domain contract.
    where = MetadataFilter()
    where.equals["path"] = None  # type: ignore[assignment]  # Exercise runtime validation.
    with pytest.raises(ValueError, match=r".+"):
        await store.query("c", [1.0, 0.0], where=where)
    await store.upsert("c", [chunk_factory(0)], [[1.0, 0.0]])
    predicates: list[dict[str, MetadataValue | tuple[MetadataValue, ...]]] = [
        {"path": "file0.py"},
        {"path": "file0.py", "symbol": "f0"},
        {"path": ("file0.py",)},
    ]
    for predicate in predicates:
        assert len(await store.query("c", [1.0, 0.0], where=MetadataFilter(predicate))) == 1


async def test_pagination_batching_and_mixed_hash_omission(
    store: ChromaVectorStore, fake: FakeChromaClient, chunk_factory: Callable[[int], CodeChunk]
) -> None:
    await store.ensure_collection("c", dimension=2)
    chunks = [chunk_factory(i) for i in range(2500)]
    for start in [0, 1250]:
        await store.upsert("c", chunks[start : start + 1250], [[1.0, 0.0]] * 1250)
    handle = fake.collections["c_c"].handle
    assert isinstance(handle.upsert, AsyncMock)
    assert isinstance(handle.get, AsyncMock)
    assert [len(call.kwargs["ids"]) for call in handle.upsert.call_args_list] == [500, 500, 250] * 2
    assert len(await store.get_file_hashes("c")) == 2500
    assert [call.kwargs["offset"] for call in handle.get.call_args_list] == [0, 1000, 2000]
    assert all(call.kwargs["limit"] == 1000 for call in handle.get.call_args_list)
    await store.upsert("c", [replace(chunks[-1], path=chunks[0].path)], [[1.0, 0.0]])
    assert chunks[0].path not in await store.get_file_hashes("c")


@pytest.mark.parametrize(
    "error",
    [
        NotFoundError("x" * 600),
        InvalidArgumentError("x" * 600),
        httpx.ConnectError("x" * 600),
        httpx.ReadTimeout("x" * 600),
        httpx.HTTPStatusError(
            "x" * 600, request=httpx.Request("GET", "http://x"), response=httpx.Response(500)
        ),
    ],
)
@pytest.mark.parametrize("operation", ["get", "create", "delete", "upsert", "query", "hashes", "paths"])
async def test_error_translation(
    store: ChromaVectorStore,
    fake: FakeChromaClient,
    error: Exception,
    operation: str,
    chunk_factory: Callable[[int], CodeChunk],
) -> None:
    with pytest.raises(CollectionNotFound):
        await store.query("missing", [1.0, 0.0], top_k=0)
    with pytest.raises(CollectionNotFound):
        await store.query("missing", [1.0, 0.0], where=MetadataFilter({"path": ()}))
    await store.ensure_collection("c", dimension=2)
    assert isinstance(fake.client.get_or_create_collection, AsyncMock)
    assert fake.client.get_or_create_collection.call_args.kwargs["configuration"] == {
        "hnsw": {"space": "cosine"}
    }
    handle = fake.collections["c_c"].handle
    calls: dict[str, tuple[AsyncClientAPI | AsyncCollection, str, Callable[[], Awaitable[object]]]] = {
        "get": (fake.client, "get_collection", lambda: store.get_file_hashes("c")),
        "create": (
            fake.client,
            "get_or_create_collection",
            lambda: store.ensure_collection("c", dimension=2),
        ),
        "delete": (fake.client, "delete_collection", lambda: store.drop_collection("c")),
        "upsert": (handle, "upsert", lambda: store.upsert("c", [chunk_factory(0)], [[1.0, 0.0]])),
        "query": (handle, "query", lambda: store.query("c", [1.0, 0.0])),
        "hashes": (handle, "get", lambda: store.get_file_hashes("c")),
        "paths": (handle, "delete", lambda: store.delete_by_paths("c", ["file0.py"])),
    }
    target, method, invoke = calls[operation]
    setattr(target, method, AsyncMock(side_effect=error))
    expected = CollectionNotFound if isinstance(error, NotFoundError) else VectorStoreError
    with pytest.raises(expected) as caught:
        await invoke()
    assert caught.value.__cause__ is error
    assert len(str(caught.value)) <= 300


async def test_dimension_metadata(store: ChromaVectorStore, fake: FakeChromaClient) -> None:
    with pytest.raises(VectorStoreError):
        await store.ensure_collection("c", dimension=0)
    await fake.get_or_create_collection("c_c")
    with pytest.raises(VectorStoreError):
        await store.ensure_collection("c", dimension=2)


async def test_connect(monkeypatch: pytest.MonkeyPatch, fake: FakeChromaClient) -> None:
    factory = AsyncMock(return_value=fake.client)
    monkeypatch.setattr("chromadb.AsyncHttpClient", factory)
    await asyncio.wait_for(connect(Settings(chroma_url=AnyHttpUrl("https://example.com:8443"))), 5)
    assert factory.call_args.kwargs == {"host": "https://example.com:8443", "port": 8443, "ssl": True}
    factory.side_effect = httpx.ConnectError("unavailable")
    with pytest.raises(VectorStoreError):
        await asyncio.wait_for(connect(Settings()), 5)


async def test_query_does_not_rely_on_server_ordering(
    store: ChromaVectorStore, fake: FakeChromaClient, chunk_factory: Callable[[int], CodeChunk]
) -> None:
    """The adapter must return best-first even if the server returned the rows in another order.

    The fake normally returns nearest-first like a real Chroma, so removing the adapter's own sort
    changed nothing and no test noticed. Here the fake deliberately returns farthest-first.
    """
    await store.ensure_collection("c", dimension=2)
    await store.upsert("c", [chunk_factory(i) for i in range(3)], [[1.0, 0.0], [1.0, 1.0], [-1.0, 0.0]])
    fake.collections["c_c"].unsorted_results = True
    results = await store.query("c", [1.0, 0.0])
    assert [r.chunk.symbol for r in results] == ["f0", "f1", "f2"]
    assert [r.score for r in results] == sorted((r.score for r in results), reverse=True)
