"""Deterministic LLM provider for service tests."""

import asyncio
from collections.abc import AsyncGenerator, Callable, Collection, Sequence

from engine.core.errors import AdapterNotFound, EngineError, GenerationTimeout
from engine.core.models import (
    FinishReason,
    GenerationRequest,
    GenerationResult,
    ProviderHealth,
    TokenChunk,
    TokenUsage,
)


class FakeLLMProvider:
    def __init__(
        self,
        *,
        replies: Sequence[str] | Callable[[GenerationRequest], str] = ("ok",),
        adapters: Collection[str] = (),
        model: str = "fake-llm",
        latency_s: float = 0.0,
        tokens_per_chunk: int = 1,
    ) -> None:
        if not callable(replies) and not replies:
            raise ValueError("replies must not be empty")
        if tokens_per_chunk < 1 or latency_s < 0:
            raise ValueError("invalid chunk size or latency")
        self._replies = replies if callable(replies) else tuple(replies)
        self._adapters = frozenset(adapters)
        self._model = model
        self._latency_s = latency_s
        self._tokens_per_chunk = tokens_per_chunk
        self._position = 0
        self._in_flight = 0
        self._failure: EngineError | None = None

    @property
    def name(self) -> str:
        return "fake"

    @property
    def in_flight(self) -> int:
        return self._in_flight

    def fail_next(self, exc: EngineError) -> None:
        self._failure = exc

    async def _result(self, req: GenerationRequest) -> GenerationResult:
        if self._failure is not None:
            failure, self._failure = self._failure, None
            raise failure
        if req.adapter is not None and req.adapter not in self._adapters:
            raise AdapterNotFound(req.adapter)
        if self._latency_s > req.timeout_s:
            await asyncio.sleep(max(0.0, req.timeout_s))
            raise GenerationTimeout("fake generation timed out")
        if self._latency_s:
            await asyncio.sleep(self._latency_s)
        if callable(self._replies):
            text = self._replies(req)
        else:
            text = self._replies[self._position % len(self._replies)]
            self._position += 1
        usage = TokenUsage(sum(len(m.content.split()) for m in req.messages), len(text.split()))
        return GenerationResult(
            text, self._model, req.adapter, FinishReason.STOP, usage, int(self._latency_s * 1000)
        )

    async def generate(self, req: GenerationRequest) -> GenerationResult:
        self._in_flight += 1
        try:
            return await self._result(req)
        finally:
            self._in_flight -= 1

    async def stream(self, req: GenerationRequest) -> AsyncGenerator[TokenChunk, None]:
        self._in_flight += 1
        active = True
        try:
            result = await self._result(req)
            tokens = result.text.split()
            groups = [
                " ".join(tokens[i : i + self._tokens_per_chunk])
                for i in range(0, len(tokens), self._tokens_per_chunk)
            ] or [""]
            for index, group in enumerate(groups):
                last = index == len(groups) - 1
                if last:
                    self._in_flight -= 1
                    active = False
                yield TokenChunk(
                    group + (" " if not last else ""),
                    index,
                    result.finish_reason if last else None,
                    result.usage if last else None,
                )
        finally:
            if active:
                self._in_flight -= 1

    async def health(self) -> ProviderHealth:
        return ProviderHealth(True, self.name, self._model, tuple(sorted(self._adapters)))
