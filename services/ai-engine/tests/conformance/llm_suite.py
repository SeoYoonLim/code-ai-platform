"""Reusable LLM rules; requires fixture llm_provider: LLMProvider.

The fixture must serve a nonempty reply. Activity rules require ActivityGauge.
No fake-specific hooks or known adapter names are required.
"""

from collections.abc import AsyncGenerator

import pytest

from engine.core.errors import AdapterNotFound
from engine.core.interfaces.activity import ActivityGauge
from engine.core.interfaces.llm import LLMProvider
from engine.core.models import GenerationRequest


class LLMProviderConformance:
    def test_runtime_protocol(self, llm_provider: LLMProvider) -> None:
        assert isinstance(llm_provider, LLMProvider)

    def test_activity_protocol(self, llm_provider: LLMProvider) -> None:
        assert isinstance(llm_provider, ActivityGauge)
        assert llm_provider.in_flight == 0

    async def test_no_adapter_uses_base(self, llm_provider: LLMProvider) -> None:
        result = await llm_provider.generate(GenerationRequest(messages=()))
        assert result.adapter is None
        assert result.model

    async def test_unknown_adapter_raises(self, llm_provider: LLMProvider) -> None:
        with pytest.raises(AdapterNotFound):
            await llm_provider.generate(GenerationRequest(messages=(), adapter="__missing__"))

    async def test_stream_only_last_has_finish_reason(self, llm_provider: LLMProvider) -> None:
        chunks = [chunk async for chunk in llm_provider.stream(GenerationRequest(messages=()))]
        assert chunks
        assert all(chunk.finish_reason is None for chunk in chunks[:-1])
        assert chunks[-1].finish_reason is not None

    async def test_stream_only_last_has_usage(self, llm_provider: LLMProvider) -> None:
        chunks = [chunk async for chunk in llm_provider.stream(GenerationRequest(messages=()))]
        assert chunks
        assert all(chunk.usage is None for chunk in chunks[:-1])
        assert chunks[-1].usage is not None

    async def test_stream_indices_are_contiguous(self, llm_provider: LLMProvider) -> None:
        chunks = [chunk async for chunk in llm_provider.stream(GenerationRequest(messages=()))]
        assert [chunk.index for chunk in chunks] == list(range(len(chunks)))

    async def test_generate_restores_activity(self, llm_provider: LLMProvider) -> None:
        assert isinstance(llm_provider, ActivityGauge)
        await llm_provider.generate(GenerationRequest(messages=()))
        assert llm_provider.in_flight == 0

    async def test_stream_completion_restores_activity(self, llm_provider: LLMProvider) -> None:
        assert isinstance(llm_provider, ActivityGauge)
        async for chunk in llm_provider.stream(GenerationRequest(messages=())):
            if chunk.finish_reason is not None:
                assert llm_provider.in_flight == 0
        assert llm_provider.in_flight == 0

    async def test_consumer_close_restores_activity(self, llm_provider: LLMProvider) -> None:
        assert isinstance(llm_provider, ActivityGauge)
        stream = llm_provider.stream(GenerationRequest(messages=()))
        assert isinstance(stream, AsyncGenerator)
        await anext(stream)
        await stream.aclose()
        assert llm_provider.in_flight == 0

    async def test_concurrent_streams_are_counted_independently(self, llm_provider: LLMProvider) -> None:
        """in_flight is a counter, not a busy flag: two open streams count as 2, and each close frees one."""
        assert isinstance(llm_provider, ActivityGauge)
        first = llm_provider.stream(GenerationRequest(messages=()))
        second = llm_provider.stream(GenerationRequest(messages=()))
        assert isinstance(first, AsyncGenerator)
        assert isinstance(second, AsyncGenerator)
        await anext(first)
        await anext(second)
        assert llm_provider.in_flight == 2
        await first.aclose()
        assert llm_provider.in_flight == 1
        await second.aclose()
        assert llm_provider.in_flight == 0

    async def test_generate_exception_restores_activity(self, llm_provider: LLMProvider) -> None:
        assert isinstance(llm_provider, ActivityGauge)
        with pytest.raises(AdapterNotFound):
            await llm_provider.generate(GenerationRequest(messages=(), adapter="__missing__"))
        assert llm_provider.in_flight == 0

    async def test_stream_exception_restores_activity(self, llm_provider: LLMProvider) -> None:
        assert isinstance(llm_provider, ActivityGauge)
        with pytest.raises(AdapterNotFound):
            await anext(llm_provider.stream(GenerationRequest(messages=(), adapter="__missing__")))
        assert llm_provider.in_flight == 0

    async def test_health_does_not_raise(self, llm_provider: LLMProvider) -> None:
        health = await llm_provider.health()
        assert isinstance(health.ok, bool)
        assert health.provider == llm_provider.name
