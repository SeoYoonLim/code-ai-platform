"""Opt-in real-server parity, restart phases, and scale measurements."""

import asyncio
import os
import time
from collections.abc import AsyncIterator, Awaitable, Callable
from dataclasses import replace
from uuid import uuid4

import pytest
import structlog
from pydantic import AnyHttpUrl

from engine.adapters.vectorstore.chroma import connect
from engine.core.interfaces.vector_store import VectorStore
from engine.core.models import CodeChunk
from engine.settings import Settings
from tests.conformance.vector_store_suite import VectorStoreConformance

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not os.getenv("ENGINE_IT_CHROMA_URL"), reason="ENGINE_IT_CHROMA_URL unset"),
]


def bounded_call[**P, R](method: Callable[P, Awaitable[R]]) -> Callable[P, Awaitable[R]]:
    async def invoke(*args: P.args, **kwargs: P.kwargs) -> R:
        return await asyncio.wait_for(method(*args, **kwargs), timeout=5)

    return invoke


class TestChromaLive(VectorStoreConformance):
    @pytest.fixture
    async def store(self) -> AsyncIterator[VectorStore]:
        real = await asyncio.wait_for(
            connect(Settings(chroma_url=AnyHttpUrl(os.environ["ENGINE_IT_CHROMA_URL"]))), 5
        )
        prefix = "it_" + uuid4().hex + "_"
        touched: set[str] = set()

        def wrap[R](method: Callable[..., Awaitable[R]]) -> Callable[..., Awaitable[R]]:
            async def invoke(name: str, *args: object, **kwargs: object) -> R:
                touched.add(name)
                return await asyncio.wait_for(method(prefix + name, *args, **kwargs), 5)

            return invoke

        for name in (
            "ensure_collection",
            "upsert",
            "query",
            "delete_by_paths",
            "get_file_hashes",
            "drop_collection",
        ):
            setattr(real, name, wrap(getattr(real, name)))
        try:
            yield real
        finally:
            from engine.core.errors import CollectionNotFound

            for name in touched:
                try:
                    await real.drop_collection(name)
                except CollectionNotFound:
                    continue

    @pytest.mark.parametrize("name", ["proj_a-", "proj_b_", "proj_" + "a" * 64])
    async def test_live_names(self, store: VectorStore, name: str) -> None:
        await store.ensure_collection(name, dimension=2)
        assert await store.get_file_hashes(name) == {}

    async def test_live_scale(self, store: VectorStore, chunk_factory: Callable[[int], CodeChunk]) -> None:
        await store.ensure_collection("scale", dimension=768)
        chunks = [chunk_factory(i) for i in range(1500)]
        vector = [1.0] + [0.0] * 767
        await store.upsert("scale", chunks, [vector] * 1500)
        assert len(await store.get_file_hashes("scale")) == 1500
        samples = []
        for _ in range(20):
            started = time.perf_counter()
            assert len(await store.query("scale", vector)) == 8
            samples.append(time.perf_counter() - started)
        structlog.get_logger().info("chroma_scale_latency", p95_s=sorted(samples)[18])
        assert await store.delete_by_paths("scale", [c.path for c in chunks]) == 1500


async def test_live_restart_phases(chunk_factory: Callable[[int], CodeChunk]) -> None:
    # Claude runs write, restarts the container externally, then runs read.
    phase = os.getenv("ENGINE_IT_CHROMA_PHASE")
    name = os.getenv("ENGINE_IT_CHROMA_PERSISTENCE_NAME")
    if phase not in {"write", "read"} or not name:
        pytest.skip("set ENGINE_IT_CHROMA_PHASE=write/read and a unique ENGINE_IT_CHROMA_PERSISTENCE_NAME")
    store = await asyncio.wait_for(
        connect(Settings(chroma_url=AnyHttpUrl(os.environ["ENGINE_IT_CHROMA_URL"]))), 5
    )
    for method in ("ensure_collection", "upsert", "query", "get_file_hashes", "drop_collection"):
        setattr(store, method, bounded_call(getattr(store, method)))
    chunk = replace(chunk_factory(0), commit_sha=None)
    await store.ensure_collection(name, dimension=2)
    if phase == "write":
        await store.upsert(name, [chunk], [[1.0, 0.0]])
    else:
        try:
            assert await store.get_file_hashes(name) == {chunk.path: chunk.content_hash}
            result = await store.query(name, [1.0, 0.0])
            assert result[0].chunk == chunk
            assert result[0].score == pytest.approx(1.0)
        finally:
            await store.drop_collection(name)
