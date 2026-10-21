"""Transport-mocked llama-server conformance and request isolation."""

import asyncio
import json
from collections.abc import AsyncIterator

import httpx
import pytest
import respx

from engine.adapters.llm.llamacpp import LlamaServerProvider
from engine.core.errors import ContextTooLarge, EngineError, GenerationTimeout, ProviderUnavailable
from engine.core.interfaces.llm import LLMProvider
from engine.core.models import GenerationParams, GenerationRequest
from engine.settings import Settings
from tests.conformance.llm_suite import LLMProviderConformance

URL = "http://localhost:8080"
USAGE = {"prompt_tokens": 4, "completion_tokens": 3}
REPLY = {"choices": [{"message": {"content": "one two three"}, "finish_reason": "stop"}], "usage": USAGE}
SSE = (
    "".join(
        "data: " + json.dumps(row) + "\n\n"
        for row in [
            *[{"choices": [{"delta": {"content": word}}]} for word in ("one ", "two ", "three")],
            {"choices": [{"delta": {}, "finish_reason": "stop"}]},
            {"choices": [], "usage": USAGE},
        ]
    )
    + "data: [DONE]\n\n"
)


@pytest.fixture
async def provider(respx_mock: respx.MockRouter) -> AsyncIterator[LlamaServerProvider]:
    respx_mock.get(URL + "/health").respond(200, json={"status": "ok"})
    respx_mock.get(URL + "/props").respond(200, json={"model_alias": "base"})
    respx_mock.get(URL + "/lora-adapters").respond(
        200,
        json=[
            {"id": 0, "path": "/adapters/a.gguf"},
            {"id": 1, "path": "/adapters/b.gguf"},
        ],
    )

    def completion(request: httpx.Request) -> httpx.Response:
        if json.loads(request.content)["stream"]:
            return httpx.Response(200, text=SSE, headers={"content-type": "text/event-stream"})
        return httpx.Response(200, json=REPLY)

    respx_mock.post(URL + "/v1/chat/completions").mock(side_effect=completion)
    result = LlamaServerProvider(Settings(_env_file=None))
    yield result
    await result.aclose()


class TestLlamaServerProvider(LLMProviderConformance):
    @pytest.fixture
    def llm_provider(self, provider: LlamaServerProvider) -> LLMProvider:
        return provider


@pytest.mark.parametrize("streaming", [False, True])
@pytest.mark.parametrize("adapter", [None, "a", "b"])
async def test_explicit_scales_and_schema(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
    streaming: bool,
    adapter: str | None,
) -> None:
    req = GenerationRequest(
        messages=(),
        adapter=adapter,
        json_schema={"type": "object"},
        params=GenerationParams(seed=42, stop=("end",)),
    )
    if streaming:
        chunks = [chunk async for chunk in provider.stream(req)]
        assert chunks[-1].usage.completion_tokens == 3
    else:
        assert (await provider.generate(req)).usage.prompt_tokens == 4
    request = respx_mock.calls.last.request
    body = json.loads(request.content)
    assert body["lora"] == [{"id": i, "scale": float(adapter == name)} for i, name in enumerate(("a", "b"))]
    assert body["response_format"]["json_schema"] == {"name": "response", "schema": {"type": "object"}}
    assert body["seed"] == 42
    assert body["stop"] == ["end"]
    assert not any(
        call.request.method == "POST" and call.request.url.path == "/lora-adapters"
        for call in respx_mock.calls
    )


@pytest.mark.parametrize("streaming", [False, True])
@pytest.mark.parametrize(
    ("status", "body", "error"),
    [
        (503, "Loading model", ProviderUnavailable),
        (400, "exceeds the available context size", ContextTooLarge),
        (401, "x" * 500, EngineError),
        (500, "failed", EngineError),
    ],
)
async def test_http_errors(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
    streaming: bool,
    status: int,
    body: str,
    error: type[EngineError],
) -> None:
    respx_mock.post(URL + "/v1/chat/completions").respond(status, text=body)
    call = (
        anext(provider.stream(GenerationRequest(messages=())))
        if streaming
        else provider.generate(GenerationRequest(messages=()))
    )
    with pytest.raises(error) as caught:
        await call
    assert len(caught.value.detail["body"]) <= 300
    assert provider.in_flight == 0


@pytest.mark.parametrize("streaming", [False, True])
@pytest.mark.parametrize(
    ("error", "expected"),
    [
        (httpx.ConnectError("offline"), ProviderUnavailable),
        (httpx.ReadError("broken"), ProviderUnavailable),
        (httpx.ReadTimeout("idle"), GenerationTimeout),
    ],
)
async def test_transport_errors(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
    streaming: bool,
    error: httpx.RequestError,
    expected: type[EngineError],
) -> None:
    respx_mock.post(URL + "/v1/chat/completions").mock(side_effect=error)
    call = (
        anext(provider.stream(GenerationRequest(messages=())))
        if streaming
        else provider.generate(GenerationRequest(messages=()))
    )
    with pytest.raises(expected):
        await call
    assert provider.in_flight == 0


async def test_adapter_refresh_and_missing_does_not_post(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
) -> None:
    await provider.generate(GenerationRequest(messages=()))
    respx_mock.get(URL + "/lora-adapters").respond(200, json=[{"id": 9, "path": "/new.gguf"}])
    result = await provider.generate(GenerationRequest(messages=(), adapter="new"))
    assert result.adapter == "new"
    assert json.loads(respx_mock.calls.last.request.content)["lora"] == [{"id": 9, "scale": 1.0}]


@pytest.mark.parametrize(("status", "body"), [(503, "loading"), (200, "invalid"), (500, "error")])
async def test_health_failures(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
    status: int,
    body: str,
) -> None:
    respx_mock.get(URL + "/health").respond(status, text=body)
    health = await provider.health()
    assert not health.ok
    assert health.detail


async def test_concurrent_generate_and_cancellation(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
) -> None:
    entered, release = asyncio.Event(), asyncio.Event()
    count = 0

    async def delayed(request: httpx.Request) -> httpx.Response:
        nonlocal count
        count += 1
        if count == 2:
            entered.set()
        await release.wait()
        return httpx.Response(200, json=REPLY)

    respx_mock.post(URL + "/v1/chat/completions").mock(side_effect=delayed)
    tasks = [asyncio.create_task(provider.generate(GenerationRequest(messages=()))) for _ in range(2)]
    await entered.wait()
    assert provider.in_flight == 2
    tasks[0].cancel()
    with pytest.raises(asyncio.CancelledError):
        await tasks[0]
    assert provider.in_flight == 1
    release.set()
    await tasks[1]
    assert provider.in_flight == 0


@pytest.mark.parametrize("text", ["data: invalid\n\n", "data: [DONE]\n\n", SSE.split("data: [DONE]")[0]])
async def test_broken_stream(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
    text: str,
) -> None:
    respx_mock.post(URL + "/v1/chat/completions").respond(200, text=text)
    with pytest.raises(EngineError):
        async for _ in provider.stream(GenerationRequest(messages=())):
            pass
    assert provider.in_flight == 0


async def test_timings_fallback_and_missing_usage(
    provider: LlamaServerProvider,
    respx_mock: respx.MockRouter,
) -> None:
    reply = {"choices": REPLY["choices"], "timings": {"prompt_n": 7, "predicted_n": 8}}
    route = respx_mock.post(URL + "/v1/chat/completions")
    route.respond(200, json=reply)
    assert (await provider.generate(GenerationRequest(messages=()))).usage.completion_tokens == 8
    route.respond(200, json={"choices": REPLY["choices"]})
    with pytest.raises(EngineError, match="usage not provided"):
        await provider.generate(GenerationRequest(messages=()))


@pytest.mark.parametrize("streaming", [False, True])
async def test_total_timeout_and_auth(respx_mock: respx.MockRouter, streaming: bool) -> None:
    async def stalled(request: httpx.Request) -> httpx.Response:
        assert request.headers["Authorization"] == "Bearer test-key"
        await asyncio.sleep(1)
        return httpx.Response(200, json=[])

    respx_mock.get(URL + "/lora-adapters").mock(side_effect=stalled)
    provider = LlamaServerProvider(Settings(_env_file=None, llamacpp_api_key="test-key"))
    req = GenerationRequest(messages=(), timeout_s=0.01)
    call = anext(provider.stream(req)) if streaming else provider.generate(req)
    try:
        with pytest.raises(GenerationTimeout):
            await call
        assert provider.in_flight == 0
    finally:
        await provider.aclose()


async def test_health_metadata(provider: LlamaServerProvider) -> None:
    health = await provider.health()
    assert health.base_model == "base"
    assert health.loaded_adapters == ("a", "b")
    assert (await provider.generate(GenerationRequest(messages=()))).model == "base"
