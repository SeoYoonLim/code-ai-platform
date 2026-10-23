"""Deterministic retrieval, whole-block context, and evidence-based chat."""

import time
from collections.abc import AsyncIterator, Callable, Sequence
from dataclasses import replace
from importlib.resources import files
from math import ceil
from typing import Protocol, runtime_checkable

import structlog
from jinja2 import Environment, StrictUndefined

from engine.core.errors import AdapterNotFound, ContextTooLarge, EngineError
from engine.core.interfaces import Embedder, LLMProvider, LoRAAdapterRegistry, VectorStore
from engine.core.models import (
    AdapterTask,
    ChatEvent,
    ChatMessage,
    ChatRequest,
    ContextBlock,
    ContextBundle,
    DoneEvent,
    GenerationRequest,
    MetadataFilter,
    RetrievedChunk,
    Role,
    SourcesEvent,
    TokenEvent,
)
from engine.services.collections import collection_for

log = structlog.get_logger()


def estimate_tokens(text: str) -> int:
    """MVP approximation; replace only this function for a real tokenizer."""
    return ceil(len(text) / 3.5)


# 동점 묶음이 경계에 걸리면 요청 크기를 두 배씩 늘려 묶음 전체를 받는다. 이 상한을 넘는 동점은 비결정적.
MAX_FETCH = 2000


def _quantized(item: RetrievedChunk) -> float:
    return round(item.score, 6)


def _rank(item: RetrievedChunk) -> tuple[float, str]:
    return (-_quantized(item), item.chunk.chunk_id)


def _overlaps(block: ContextBlock, span: tuple[str, int, int]) -> bool:
    chunk = block.chunk
    return chunk.path == span[0] and chunk.start_line <= span[2] and span[1] <= chunk.end_line


@runtime_checkable
class _Closeable(Protocol):
    async def aclose(self) -> None: ...


class RagService:
    def __init__(
        self,
        embedder: Embedder,
        store: VectorStore,
        llm: LLMProvider,
        registry: LoRAAdapterRegistry,
        *,
        num_ctx: int = 16384,
        oversample: int = 2,
        clock: Callable[[], float] | None = None,
    ) -> None:
        if oversample < 1:
            raise ValueError("oversample must be at least one")
        self._embedder, self._store, self._llm, self._registry = embedder, store, llm, registry
        self._num_ctx, self._oversample = num_ctx, oversample
        self._clock = clock or time.perf_counter
        template = files("engine").joinpath("prompts/chat.v1.jinja").read_text(encoding="utf-8")
        self._template = Environment(undefined=StrictUndefined, autoescape=False).from_string(template)

    async def retrieve(
        self,
        project_id: str,
        query: str,
        *,
        top_k: int = 8,
        min_score: float = 0.0,
        where: MetadataFilter | None = None,
    ) -> list[RetrievedChunk]:
        """결정적 검색: 동점 묶음이 top_k 경계에 걸리면 묶음 전체가 보일 때까지 요청을 넓힌다."""
        if top_k <= 0:
            return []
        vector = await self._embedder.embed_query(query)
        fetch = top_k * self._oversample
        while True:
            items = await self._store.query(collection_for(project_id), vector, top_k=fetch, where=where)
            ranked = sorted((item for item in items if item.score >= min_score), key=_rank)
            exhausted = len(items) < fetch or fetch >= MAX_FETCH
            if exhausted or len(ranked) < top_k:
                break
            # 점수 내림차순으로 받는다. 받은 것의 최저 점수가 k번째와 같으면 바깥에 동점이 더 있을 수 있다.
            if _quantized(ranked[top_k - 1]) > min(_quantized(item) for item in items):
                break
            fetch = min(fetch * 2, MAX_FETCH)
        return ranked[:top_k]

    async def build_context(
        self,
        project_id: str,
        query: str,
        *,
        budget_tokens: int,
        attached_paths: Sequence[str] = (),
        top_k: int = 8,
        exclude: Sequence[tuple[str, int, int]] = (),
    ) -> ContextBundle:
        """Prefer attachments, resolve overlaps, then pack complete code blocks."""
        attached = (
            await self.retrieve(
                project_id,
                query,
                top_k=max(top_k, 8),
                where=MetadataFilter({"path": tuple(attached_paths)}),
            )
            if attached_paths
            else []
        )
        similar = await self.retrieve(project_id, query, top_k=top_k)
        selected: list[ContextBlock] = []
        overlaps = 0
        for origin, items in (("attached", attached), ("retrieved", similar)):
            for item in items:
                block = ContextBlock(item.chunk, item.score, origin, estimate_tokens(item.chunk.raw_code))
                spans = (*exclude, *((b.chunk.path, b.chunk.start_line, b.chunk.end_line) for b in selected))
                if any(_overlaps(block, span) for span in spans):
                    overlaps += 1
                else:
                    selected.append(block)
        selected.sort(key=lambda b: (0, b.chunk.path, b.chunk.start_line) if b.origin == "attached" else (1,))
        kept: list[ContextBlock] = []
        tokens = dropped = 0
        for block in selected:
            if block.origin == "attached" and block.tokens > budget_tokens:
                raise ContextTooLarge(
                    "attachment exceeds budget",
                    detail={
                        "path": block.chunk.path,
                        "tokens": block.tokens,
                        "budget": budget_tokens,
                    },
                )
            if tokens + block.tokens > budget_tokens:
                dropped += 1
            else:
                kept.append(block)
                tokens += block.tokens
        return ContextBundle(tuple(kept), tokens, budget_tokens, dropped, overlaps)

    def _history(self, request: ChatRequest) -> tuple[ChatMessage, ...]:
        if not request.messages or request.messages[-1].role != Role.USER:
            raise ValueError("last message must be user")
        available = self._num_ctx - request.params.max_tokens
        last = request.messages[-1]
        used = estimate_tokens(last.content)
        if used > available:
            raise ContextTooLarge("last user message exceeds budget")
        history = [last]
        for message in reversed(request.messages[:-1]):
            tokens = estimate_tokens(message.content)
            if used + tokens > available * 0.25:
                break
            history.append(message)
            used += tokens
        return tuple(reversed(history))

    async def chat_stream(self, request: ChatRequest) -> AsyncIterator[ChatEvent]:
        """Sources once, nonempty indexed tokens, then provider completion metadata."""
        started = self._clock()
        history = self._history(request)
        skeleton = self._template.render(blocks=())
        budget = self._num_ctx - request.params.max_tokens - estimate_tokens(skeleton)
        budget -= sum(estimate_tokens(m.content) for m in history)
        if budget <= 0:
            raise ContextTooLarge("no context budget")
        bundle = await self.build_context(
            request.project_id,
            history[-1].content,
            budget_tokens=budget,
            attached_paths=request.context_paths,
            top_k=request.top_k,
        )
        generation = GenerationRequest(
            (ChatMessage(Role.SYSTEM, self._template.render(blocks=bundle.blocks)), *history),
            adapter=request.adapter,
            params=request.params,
            timeout_s=request.timeout_s,
        )
        if request.adapter is None:
            resolved = await self._registry.resolve(AdapterTask.EXPLAIN)
            generation = replace(generation, adapter=resolved.name if resolved else None)
        yield SourcesEvent(bundle.sources)
        index = 0
        for attempt in range(2):
            stream = self._llm.stream(generation)
            complete = None
            try:
                async for chunk in stream:
                    latency = int((self._clock() - started) * 1000)
                    if chunk.delta:
                        yield TokenEvent(index, chunk.delta)
                        index += 1
                    if chunk.finish_reason is not None and chunk.usage is not None:
                        complete = DoneEvent(chunk.finish_reason, chunk.usage, latency)
                if complete is None:
                    raise EngineError("stream incomplete", detail={"reason": "stream_incomplete"})
            except AdapterNotFound:
                if request.adapter is not None or generation.adapter is None or index or attempt:
                    raise
                log.warning("rag_adapter_fallback", adapter=generation.adapter)
                generation = replace(generation, adapter=None)
                continue
            finally:
                if isinstance(stream, _Closeable):
                    await stream.aclose()
            yield complete
            return
