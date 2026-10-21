"""Mocked Ollama transport and inherited embedding contract."""

import asyncio
import hashlib
import json
import math
from collections.abc import AsyncIterator, Sequence

import httpx
import pytest
import respx

from engine.adapters.embeddings.ollama_embed import OllamaEmbedder
from engine.core.errors import EmbeddingError
from engine.core.interfaces.embedder import Embedder
from tests.conformance.embedder_suite import EmbedderConformance

URL = "http://ollama/api/embed"


def reply(request: httpx.Request) -> httpx.Response:
    texts = json.loads(request.content)["input"]
    rows = []
    for text in texts:
        digest = hashlib.sha256(text.encode()).digest()
        rows.append([float(digest[i % 32] + 1) for i in range(768)])
    return httpx.Response(200, json={"embeddings": rows})


class BoundedEmbedder(OllamaEmbedder):
    """Bound even inherited suite awaits independently of production timeouts."""

    async def embed_documents(self, texts: Sequence[str]) -> list[list[float]]:
        return await asyncio.wait_for(super().embed_documents(texts), 5)

    async def embed_query(self, text: str) -> list[float]:
        return await asyncio.wait_for(super().embed_query(text), 5)


@pytest.fixture
async def ollama(respx_mock: respx.MockRouter) -> AsyncIterator[BoundedEmbedder]:
    respx_mock.post(URL).mock(side_effect=reply)
    instance = BoundedEmbedder(base_url="http://ollama")
    yield instance
    await asyncio.wait_for(instance.aclose(), 5)


class TestOllamaEmbedder(EmbedderConformance):
    @pytest.fixture
    def embedder(self, ollama: BoundedEmbedder) -> Embedder:
        return ollama


async def test_batches_prefixes_and_order(ollama: BoundedEmbedder, respx_mock: respx.MockRouter) -> None:
    texts = [str(i) for i in range(70)]
    result = await ollama.embed_documents(texts)
    requests = [json.loads(call.request.content) for call in respx_mock.calls]
    assert [len(body["input"]) for body in requests] == [32, 32, 6]
    assert [text for body in requests for text in body["input"]] == ["search_document: " + t for t in texts]
    assert all(body["options"] == {"num_gpu": 99} for body in requests)
    assert all(body["keep_alive"] == "30m" and body["truncate"] is True for body in requests)
    assert result == [(await ollama.embed_documents([text]))[0] for text in texts]
    assert all(math.hypot(*row) == pytest.approx(1) for row in result)
    await ollama.embed_query("")
    assert json.loads(respx_mock.calls[-1].request.content)["input"] == ["search_query: "]


async def test_empty_does_not_request(ollama: BoundedEmbedder, respx_mock: respx.MockRouter) -> None:
    assert await ollama.embed_documents([]) == []
    assert not respx_mock.calls


async def test_device_observed_once_per_batch_and_never_query(respx_mock: respx.MockRouter) -> None:
    class Gauge:
        reads = 0
        value = 1

        @property
        def in_flight(self) -> int:
            self.reads += 1
            return self.value

    gauge = Gauge()
    now = [0.0]
    devices: list[int] = []

    def handler(request: httpx.Request) -> httpx.Response:
        devices.append(json.loads(request.content)["options"]["num_gpu"])
        gauge.value = 0
        now[0] = 20
        return reply(request)

    respx_mock.post(URL).mock(side_effect=handler)
    instance = BoundedEmbedder(base_url="http://ollama", gauge=gauge, clock=lambda: now[0])
    try:
        await instance.embed_query("before")
        assert gauge.reads == 0
        gauge.value = 1
        await instance.embed_documents(["a"])
        assert gauge.reads == 1
        await instance.embed_query("still cpu")
        assert gauge.reads == 1
        now[0] = 40
        await instance.embed_documents(["a"] * 70)
        assert gauge.reads == 4
        assert devices == [99, 0, 0, 99, 99, 99]
    finally:
        await asyncio.wait_for(instance.aclose(), 5)


@pytest.mark.parametrize("status", [400, 404, 500])
async def test_http_errors(status: int, ollama: BoundedEmbedder, respx_mock: respx.MockRouter) -> None:
    respx_mock.post(URL).respond(status, text="x" * 500)
    with pytest.raises(EmbeddingError) as caught:
        await ollama.embed_query("x")
    assert caught.value.detail["status"] == status
    assert len(str(caught.value.detail["body"])) == 300
    if status == 404:
        assert caught.value.detail["hint"] == "run scripts/provision_ollama.py"


@pytest.mark.parametrize("error", [httpx.ConnectError("offline"), httpx.ReadTimeout("timeout")])
async def test_transport_errors(
    error: httpx.RequestError,
    ollama: BoundedEmbedder,
    respx_mock: respx.MockRouter,
) -> None:
    respx_mock.post(URL).mock(side_effect=error)
    with pytest.raises(EmbeddingError) as caught:
        await ollama.embed_documents(["x"])
    assert caught.value.retryable


@pytest.mark.parametrize(
    "body",
    [
        {"embeddings": []},
        {"embeddings": [[1.0]]},
        {"embeddings": [[0.0] * 768]},
        {"embeddings": [[1.0] * 768, [1.0] * 768]},
        {"wrong": []},
    ],
)
async def test_invalid_vectors(
    body: dict[str, object],
    ollama: BoundedEmbedder,
    respx_mock: respx.MockRouter,
) -> None:
    respx_mock.post(URL).respond(200, json=body)
    with pytest.raises(EmbeddingError):
        await ollama.embed_query("x")


async def test_malformed_json(ollama: BoundedEmbedder, respx_mock: respx.MockRouter) -> None:
    respx_mock.post(URL).respond(200, text="not json")
    with pytest.raises(EmbeddingError):
        await ollama.embed_query("x")


async def test_custom_configuration_and_client_close(respx_mock: respx.MockRouter) -> None:
    route = respx_mock.post(URL).respond(200, json={"embeddings": [[3, 4]]})
    client = httpx.AsyncClient()
    instance = BoundedEmbedder(
        base_url="http://ollama/",
        model="custom",
        dimension=2,
        client=client,
        doc_prefix="D:",
        query_prefix="Q:",
        policy="cpu",
    )
    assert instance.model_name == "custom"
    assert await instance.embed_documents(["x"]) == [[0.6, 0.8]]
    assert json.loads(route.calls[-1].request.content)["input"] == ["D:x"]
    assert await instance.embed_query("y") == [0.6, 0.8]
    body = json.loads(route.calls[-1].request.content)
    assert body["input"] == ["Q:y"]
    assert body["options"] == {"num_gpu": 0}
    await asyncio.wait_for(instance.aclose(), 5)
    assert client.is_closed


@pytest.mark.parametrize(("dimension", "batch_size"), [(0, 32), (768, 0)])
def test_invalid_configuration(dimension: int, batch_size: int) -> None:
    with pytest.raises(ValueError, match="positive"):
        OllamaEmbedder(base_url="http://ollama", dimension=dimension, batch_size=batch_size)
