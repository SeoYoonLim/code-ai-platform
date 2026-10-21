"""LLM conformance and fake-specific controls."""

import asyncio
from collections.abc import AsyncGenerator, Callable
from unittest.mock import patch

import pytest

from engine.adapters.llm.fake import FakeLLMProvider
from engine.core.errors import GenerationTimeout, ProviderUnavailable
from engine.core.interfaces.llm import LLMProvider
from engine.core.models import GenerationRequest
from tests.conformance.llm_suite import LLMProviderConformance


class TestFakeLLMProvider(LLMProviderConformance):
    @pytest.fixture
    def llm_provider(self, fake_llm: FakeLLMProvider) -> LLMProvider:
        return fake_llm


async def test_replies_cycle_and_stream_grouping() -> None:
    provider = FakeLLMProvider(replies=("a b c", "second"), tokens_per_chunk=2)
    req = GenerationRequest(messages=())
    chunks = [chunk async for chunk in provider.stream(req)]
    assert [chunk.delta for chunk in chunks] == ["a b ", "c"]
    assert chunks[-1].usage is not None
    assert chunks[-1].usage.completion_tokens == 3
    assert (await provider.generate(req)).text == "second"
    assert (await provider.generate(req)).text == "a b c"


async def test_callable_receives_schema_without_validation() -> None:
    req = GenerationRequest(messages=(), json_schema={"type": "object"}, adapter="known")
    provider = FakeLLMProvider(replies=lambda request: str(request.json_schema), adapters=["known"])
    result = await provider.generate(req)
    assert result.text == str(req.json_schema)
    assert result.adapter == "known"


@pytest.mark.parametrize("streaming", [False, True])
@pytest.mark.parametrize("error_type", [ProviderUnavailable, GenerationTimeout])
async def test_injected_error_is_once_and_does_not_leak(
    streaming: bool,
    error_type: type[ProviderUnavailable] | type[GenerationTimeout],
) -> None:
    provider = FakeLLMProvider()
    error = error_type("injected")
    provider.fail_next(error)
    req = GenerationRequest(messages=())
    assert (await provider.health()).ok
    call = anext(provider.stream(req)) if streaming else provider.generate(req)
    with pytest.raises(error_type) as caught:
        await call
    assert caught.value is error
    assert provider.in_flight == 0
    assert (await provider.generate(req)).text == "ok"


async def test_health_configuration_and_empty_reply() -> None:
    provider = FakeLLMProvider(replies=("",), adapters=["z", "a"], model="custom")
    health = await provider.health()
    assert (health.provider, health.base_model, health.loaded_adapters) == ("fake", "custom", ("a", "z"))
    chunks = [chunk async for chunk in provider.stream(GenerationRequest(messages=()))]
    assert len(chunks) == 1
    assert chunks[0].delta == ""
    assert chunks[0].finish_reason is not None
    assert provider.in_flight == 0


async def test_close_before_final_chunk_and_after_final_chunk() -> None:
    provider = FakeLLMProvider(replies=("one two three",))
    stream = provider.stream(GenerationRequest(messages=()))
    assert isinstance(stream, AsyncGenerator)
    await anext(stream)
    assert provider.in_flight == 1
    await stream.aclose()
    assert provider.in_flight == 0
    stream = provider.stream(GenerationRequest(messages=()))
    await anext(stream)
    await anext(stream)
    await anext(stream)
    assert provider.in_flight == 0
    await stream.aclose()
    assert provider.in_flight == 0


@pytest.mark.parametrize("streaming", [False, True])
async def test_cancellation_restores_activity(streaming: bool) -> None:
    entered, release = asyncio.Event(), asyncio.Event()

    async def controlled_sleep(delay: float) -> None:
        assert delay == 1.0
        entered.set()
        await release.wait()

    provider = FakeLLMProvider(latency_s=1.0)
    req = GenerationRequest(messages=())

    async def consume() -> None:
        if streaming:
            async for _ in provider.stream(req):
                pass
        else:
            await provider.generate(req)

    with patch("engine.adapters.llm.fake.asyncio.sleep", controlled_sleep):
        tasks = [asyncio.create_task(consume()) for _ in range(2)]
        await entered.wait()
        assert provider.in_flight == 2
        for task in tasks:
            task.cancel()
        for task in tasks:
            with pytest.raises(asyncio.CancelledError):
                await task
    assert provider.in_flight == 0


@pytest.mark.parametrize("streaming", [False, True])
async def test_latency_timeout_restores_activity(streaming: bool) -> None:
    provider = FakeLLMProvider(latency_s=0.01)
    req = GenerationRequest(messages=(), timeout_s=0.0)
    call = anext(provider.stream(req)) if streaming else provider.generate(req)
    with pytest.raises(GenerationTimeout):
        await call
    assert provider.in_flight == 0


@pytest.mark.parametrize(
    "factory",
    [
        lambda: FakeLLMProvider(replies=()),
        lambda: FakeLLMProvider(tokens_per_chunk=0),
        lambda: FakeLLMProvider(latency_s=-1.0),
    ],
)
def test_invalid_constructor_options(factory: Callable[[], FakeLLMProvider]) -> None:
    with pytest.raises(ValueError, match=r".+"):
        factory()
