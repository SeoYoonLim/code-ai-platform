"""Stream ordering, failure propagation, and immediate upstream ownership."""

import asyncio
from collections.abc import AsyncGenerator, AsyncIterator, Callable
from types import SimpleNamespace

import pytest

from engine.adapters.llm.fake import FakeLLMProvider
from engine.core.errors import AdapterNotFound, EngineError
from engine.core.models import (
    DoneEvent,
    FinishReason,
    GenerationRequest,
    GenerationResult,
    SourcesEvent,
    TokenChunk,
    TokenEvent,
    TokenUsage,
)
from tests.unit.services.rag_fakes import harness, question


async def test_t108_stream_order_metadata_and_empty_delta() -> None:
    service, _, _, llm, _ = harness()
    ticks = iter((10, 10.1, 10.2, 10.3, 10.4))
    service._clock = lambda: next(ticks)

    async def chunks(req: GenerationRequest) -> AsyncGenerator[TokenChunk, None]:
        yield TokenChunk("", 99)
        yield TokenChunk("a", 12)
        yield TokenChunk("b", 50)
        yield TokenChunk("", 999, FinishReason.LENGTH, TokenUsage(7, 2))

    llm.stream = chunks
    events = [e async for e in service.chat_stream(question(top_k=0))]
    assert events == [
        SourcesEvent(()),
        TokenEvent(0, "a"),
        TokenEvent(1, "b"),
        DoneEvent(FinishReason.LENGTH, TokenUsage(7, 2), 400),
    ]


async def test_t108_stream_incomplete_and_closed() -> None:
    service, _, _, llm, _ = harness()
    closed = []

    async def chunks(req: GenerationRequest) -> AsyncGenerator[TokenChunk, None]:
        try:
            yield TokenChunk("partial", 0)
        finally:
            closed.append(True)

    llm.stream = chunks
    with pytest.raises(EngineError) as caught:
        _ = [e async for e in service.chat_stream(question(top_k=0))]
    assert caught.value.detail == {"reason": "stream_incomplete"}
    assert closed == [True]


async def test_t108_aclose_mid_token_immediate_fake_cleanup() -> None:
    service, _, _, llm, _ = harness()
    stream = service.chat_stream(question(top_k=0))
    assert isinstance(await anext(stream), SourcesEvent)
    assert await anext(stream) == TokenEvent(0, "one ")
    assert llm.in_flight == 1
    await stream.aclose()
    assert llm.in_flight == 0


class GatedFake(FakeLLMProvider):
    def __init__(self) -> None:
        super().__init__(replies=("one two three",))
        self.waiting = asyncio.Event()
        self.release = asyncio.Event()
        self.closed = False

    async def stream(self, req: GenerationRequest) -> AsyncGenerator[TokenChunk, None]:
        upstream = super().stream(req)
        try:
            yield await anext(upstream)
            self.waiting.set()
            await self.release.wait()
            async for chunk in upstream:
                yield chunk
        finally:
            await upstream.aclose()
            self.closed = True


async def test_t108_cancel_waiting_upstream_immediate_cleanup() -> None:
    service, *_ = harness()
    llm = GatedFake()
    service._llm = llm
    stream = service.chat_stream(question(top_k=0))
    await anext(stream)
    assert await anext(stream) == TokenEvent(0, "one ")
    pending = asyncio.create_task(anext(stream))
    await asyncio.wait_for(llm.waiting.wait(), 2)
    assert llm.in_flight == 1
    pending.cancel()
    with pytest.raises(asyncio.CancelledError):
        await pending
    assert llm.in_flight == 0
    assert llm.closed


async def test_t108_cancel_before_first_token_cleans_active_fake() -> None:
    service, *_ = harness()
    entered = asyncio.Event()

    class WaitingFake(FakeLLMProvider):
        async def _result(self, req: GenerationRequest) -> GenerationResult:
            entered.set()
            await asyncio.Event().wait()
            raise AssertionError("unreachable")

    llm = WaitingFake()
    service._llm = llm
    stream = service.chat_stream(question(top_k=0))
    await anext(stream)
    pending = asyncio.create_task(anext(stream))
    await asyncio.wait_for(entered.wait(), 2)
    assert llm.in_flight == 1
    pending.cancel()
    with pytest.raises(asyncio.CancelledError):
        await pending
    assert llm.in_flight == 0


@pytest.mark.parametrize("explicit", [False, True])
async def test_t108_adapter_selection_and_missing(explicit: bool, capsys: pytest.CaptureFixture[str]) -> None:
    service, _, _, llm, registry = harness()
    registry.resolve.return_value = SimpleNamespace(name="production")
    llm.stream = recorder = StreamRecorder(llm.stream)
    if explicit:
        with pytest.raises(AdapterNotFound):
            _ = [e async for e in service.chat_stream(question(top_k=0, adapter="explicit"))]
        assert recorder.adapters == ["explicit"]
        registry.resolve.assert_not_awaited()
    else:
        events = [e async for e in service.chat_stream(question(top_k=0))]
        assert isinstance(events[-1], DoneEvent)
        assert recorder.adapters == ["production", None]
        assert "rag_adapter_fallback" in capsys.readouterr().out


class StreamRecorder:
    def __init__(self, stream: Callable[[GenerationRequest], AsyncIterator[TokenChunk]]) -> None:
        self.stream = stream
        self.adapters: list[str | None] = []

    def __call__(self, req: GenerationRequest) -> AsyncIterator[TokenChunk]:
        self.adapters.append(req.adapter)
        return self.stream(req)


async def test_t108_loaded_production_and_base_selection() -> None:
    service, _, _, llm, registry = harness()
    registry.resolve.return_value = SimpleNamespace(name="production")
    service._llm = FakeLLMProvider(adapters=["production"])
    events = [e async for e in service.chat_stream(question(top_k=0))]
    assert isinstance(events[-1], DoneEvent)
    registry.resolve.return_value = None
    recorder = StreamRecorder(llm.stream)
    llm.stream = recorder
    service._llm = llm
    _ = [e async for e in service.chat_stream(question(top_k=0))]
    assert recorder.adapters == [None]


async def test_t108_no_retry_after_token_or_base_rejection() -> None:
    service, _, _, llm, registry = harness()
    registry.resolve.return_value = SimpleNamespace(name="production")
    calls = []

    async def failing(req: GenerationRequest) -> AsyncGenerator[TokenChunk, None]:
        calls.append(req.adapter)
        yield TokenChunk("a", 0)
        raise AdapterNotFound("late")

    llm.stream = failing
    with pytest.raises(AdapterNotFound):
        _ = [e async for e in service.chat_stream(question(top_k=0))]
    assert calls == ["production"]
    registry.resolve.return_value = None
    service._llm = llm = FakeLLMProvider()
    llm.fail_next(AdapterNotFound("base"))
    with pytest.raises(AdapterNotFound):
        _ = [e async for e in service.chat_stream(question(top_k=0))]


async def test_t108_explicit_loaded_adapter_success() -> None:
    service, _, _, _, registry = harness()
    llm = FakeLLMProvider(adapters=["explicit"])
    service._llm = llm
    recorder = StreamRecorder(llm.stream)
    llm.stream = recorder
    events = [e async for e in service.chat_stream(question(top_k=0, adapter="explicit"))]
    assert isinstance(events[-1], DoneEvent)
    assert recorder.adapters == ["explicit"]
    registry.resolve.assert_not_awaited()
