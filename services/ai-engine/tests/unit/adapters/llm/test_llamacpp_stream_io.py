"""Verify response closure on consumer abort, cancellation, and mid-stream failures."""

import asyncio
from collections.abc import AsyncGenerator, AsyncIterator

import httpx
import pytest
import respx

from engine.adapters.llm.llamacpp import LlamaServerProvider
from engine.core.errors import GenerationTimeout, ProviderUnavailable
from engine.core.models import GenerationRequest
from engine.settings import Settings

URL = "http://localhost:8080"


class ControlledBody(httpx.AsyncByteStream):
    def __init__(self, error: httpx.RequestError | None = None) -> None:
        self.closed = False
        self.waiting = asyncio.Event()
        self.release = asyncio.Event()
        self.error = error

    async def __aiter__(self) -> AsyncIterator[bytes]:
        yield b'data: {"choices":[{"delta":{"content":"first"}}]}\n\n'
        self.waiting.set()
        if self.error is not None:
            raise self.error
        await self.release.wait()

    async def aclose(self) -> None:
        self.closed = True


@pytest.mark.parametrize("mode", ["close", "cancel", "disconnect", "idle"])
async def test_stream_transport_cleanup(respx_mock: respx.MockRouter, mode: str) -> None:
    error = {"disconnect": httpx.ReadError("lost"), "idle": httpx.ReadTimeout("idle")}.get(mode)
    body = ControlledBody(error)
    respx_mock.get(URL + "/lora-adapters").respond(200, json=[])
    respx_mock.post(URL + "/v1/chat/completions").respond(200, stream=body)
    # Pydantic mypy plugin omits the runtime BaseSettings _env_file parameter.
    provider = LlamaServerProvider(Settings(_env_file=None))  # type: ignore[call-arg]
    stream = provider.stream(GenerationRequest(messages=()))
    assert isinstance(stream, AsyncGenerator)
    try:
        assert (await anext(stream)).delta == "first"
        assert provider.in_flight == 1
        if mode == "close":
            await stream.aclose()
        elif mode == "cancel":
            task = asyncio.create_task(anext(stream))
            await body.waiting.wait()
            task.cancel()
            with pytest.raises(asyncio.CancelledError):
                await task
        else:
            expected = GenerationTimeout if mode == "idle" else ProviderUnavailable
            with pytest.raises(expected):
                await anext(stream)
        assert body.closed
        assert provider.in_flight == 0
    finally:
        await stream.aclose()
        await provider.aclose()


SSE_THREE_CHUNKS = (
    b'data: {"choices":[{"delta":{"content":"a"},"finish_reason":null}]}\n\n'
    b'data: {"choices":[{"delta":{"content":"b"},"finish_reason":null}]}\n\n'
    b'data: {"choices":[{"delta":{"content":"c"},"finish_reason":"stop"}]}\n\n'
    b'data: {"choices":[],"usage":{"prompt_tokens":1,"completion_tokens":3}}\n\n'
    b"data: [DONE]\n\n"
)


async def test_slow_consumer_does_not_consume_the_generation_budget(respx_mock: respx.MockRouter) -> None:
    """timeout_s bounds waiting on the SERVER, not time the consumer spends between chunks.

    Found against the real server: with asyncio.timeout wrapped around the yields, a consumer that
    took 0.15 s per chunk was cancelled after timeout_s even though the server had long finished, the
    consumer saw CancelledError instead of GenerationTimeout, and in_flight stayed at 1 forever
    (which would pin T-103 embedding scheduling to the CPU).
    """
    respx_mock.get(URL + "/lora-adapters").respond(200, json=[])
    respx_mock.post(URL + "/v1/chat/completions").respond(200, content=SSE_THREE_CHUNKS)
    # Pydantic mypy plugin omits the runtime BaseSettings _env_file parameter.
    provider = LlamaServerProvider(Settings(_env_file=None))  # type: ignore[call-arg]
    received: list[str] = []
    async for chunk in provider.stream(GenerationRequest(messages=(), timeout_s=1.0)):
        received.append(chunk.delta)
        await asyncio.sleep(0.6)  # three pauses = 1.8 s > timeout_s, server already done
    assert received == ["a", "b", "c", ""]
    assert provider.in_flight == 0
    await provider.aclose()


async def test_stalled_server_still_raises_generation_timeout_and_releases(
    respx_mock: respx.MockRouter,
) -> None:
    """The budget must still bound a SERVER that stalls: GenerationTimeout (not CancelledError), no leak."""
    body = ControlledBody()  # sends one chunk, then never sends anything again
    respx_mock.get(URL + "/lora-adapters").respond(200, json=[])
    respx_mock.post(URL + "/v1/chat/completions").respond(200, stream=body)
    # Pydantic mypy plugin omits the runtime BaseSettings _env_file parameter.
    provider = LlamaServerProvider(Settings(_env_file=None), idle_timeout_s=60.0)  # type: ignore[call-arg]
    stream = provider.stream(GenerationRequest(messages=(), timeout_s=0.3))
    assert (await anext(stream)).delta == "first"
    # Hard test-side bound: if the provider ever loses its own timeout, fail fast here instead of
    # hanging the whole CI run (no pytest-timeout is installed).
    with pytest.raises(GenerationTimeout):
        await asyncio.wait_for(anext(stream), timeout=5.0)
    assert provider.in_flight == 0
    assert body.closed
    await provider.aclose()
