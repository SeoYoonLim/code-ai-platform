"""Opt-in device, reload, throughput checks; never run by the default suite."""

import asyncio
import os
import time
from collections.abc import AsyncIterator
from typing import Literal

import httpx
import pytest
import structlog

from engine.adapters.embeddings.ollama_embed import OllamaEmbedder

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not os.getenv("ENGINE_IT_OLLAMA_URL"), reason="ENGINE_IT_OLLAMA_URL not set"),
]
# Approximately 300 tokens per chunk; distinct suffixes avoid identical inputs.
CHUNKS = [
    ("def transform(values): return [value + 1 for value in values]\n" * 20) + str(i) for i in range(1500)
]


@pytest.fixture
async def live_client() -> AsyncIterator[httpx.AsyncClient]:
    async with httpx.AsyncClient(base_url=os.environ["ENGINE_IT_OLLAMA_URL"]) as client:
        yield client


async def processor(client: httpx.AsyncClient, *, gpu: bool) -> None:
    response = await asyncio.wait_for(client.get("/api/ps", timeout=10), 15)
    response.raise_for_status()
    models = response.json()["models"]
    model = next(row for row in models if row["name"].split(":")[0] == "nomic-embed-text")
    assert model["size_vram"] == (model["size"] if gpu else 0)
    structlog.get_logger().info("ollama_processor", gpu=gpu, model=model)


@pytest.mark.parametrize("policy", ["gpu", "cpu"])
async def test_live_throughput(
    policy: Literal["gpu", "cpu"],
    live_client: httpx.AsyncClient,
) -> None:
    instance = OllamaEmbedder(base_url=os.environ["ENGINE_IT_OLLAMA_URL"], policy=policy)
    try:
        await asyncio.wait_for(instance.embed_documents(CHUNKS[:32]), 120)  # warm runner
        started = time.perf_counter()
        result = await asyncio.wait_for(instance.embed_documents(CHUNKS[:32]), 120)
        elapsed = time.perf_counter() - started
        assert len(result) == 32
        structlog.get_logger().info("embedding_throughput", policy=policy, seconds=elapsed, rate=32 / elapsed)
        assert elapsed <= (1 if policy == "gpu" else 8)
        await processor(live_client, gpu=policy == "gpu")
    finally:
        await asyncio.wait_for(instance.aclose(), 5)


async def test_live_device_switch_reload(live_client: httpx.AsyncClient) -> None:
    loads: list[float] = []

    async def capture(response: httpx.Response) -> None:
        await response.aread()
        if response.request.url.path == "/api/embed":
            loads.append(float(response.json()["load_duration"]) / 1e9)

    async with httpx.AsyncClient(event_hooks={"response": [capture]}) as client:
        for policy in ("cpu", "gpu", "cpu"):
            selected: Literal["cpu", "gpu"] = "cpu" if policy == "cpu" else "gpu"
            instance = OllamaEmbedder(
                base_url=os.environ["ENGINE_IT_OLLAMA_URL"],
                policy=selected,
                client=client,
            )
            await asyncio.wait_for(instance.embed_query(CHUNKS[0]), 120)
            await processor(live_client, gpu=policy == "gpu")
    assert all(duration <= 3 for duration in loads[1:])
    structlog.get_logger().info("device_reload_seconds", durations=loads)


async def test_live_dynamic_idle_index() -> None:
    instance = OllamaEmbedder(base_url=os.environ["ENGINE_IT_OLLAMA_URL"])
    try:
        await asyncio.wait_for(instance.embed_query(CHUNKS[0]), 120)
        started = time.perf_counter()
        assert len(await asyncio.wait_for(instance.embed_documents(CHUNKS), 120)) == 1500
        elapsed = time.perf_counter() - started
        structlog.get_logger().info("idle_index_seconds", chunks=1500, seconds=elapsed)
        assert elapsed <= 30
    finally:
        await asyncio.wait_for(instance.aclose(), 5)
