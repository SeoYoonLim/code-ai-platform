"""Golden rendered prompt and history isolation."""

from collections.abc import Callable
from dataclasses import replace
from unittest.mock import AsyncMock

import pytest

from engine.core.errors import ContextTooLarge
from engine.core.models import ChatMessage, ChunkKind, CodeChunk, GenerationParams, RetrievedChunk, Role
from tests.unit.services.rag_fakes import harness, question


async def test_t108_prompt_golden_raw_class_and_last_query(chunk_factory: Callable[[int], CodeChunk]) -> None:
    chunk = replace(
        chunk_factory(0),
        kind=ChunkKind.CLASS,
        symbol="C",
        raw_code="class C:\n    def f(self): return 1",
        search_text="# path: file0.py\nclass C: ...",
    )
    service, _, embedder, llm, _ = harness([RetrievedChunk(chunk, 1)])
    captured = []
    llm._replies = lambda req: captured.append(req) or "ok"
    embedder.embed_query = AsyncMock(wraps=embedder.embed_query)
    request = replace(
        question(timeout_s=17),
        messages=(
            ChatMessage(Role.USER, "old"),
            ChatMessage(Role.ASSISTANT, "answer"),
            ChatMessage(Role.USER, "last"),
        ),
    )
    _ = [e async for e in service.chat_stream(request)]
    prompt = captured[0].messages[0].content
    assert prompt == (
        "Answer using only the provided code. If you do not know, say you do not know.\n"
        "Cite evidence as [path:start-end].\n\n### file0.py:1-1 (C)\n"
        "```python\nclass C:\n    def f(self): return 1\n```\n"
    )
    assert "# path:" not in prompt
    assert chunk.raw_code in prompt
    embedder.embed_query.assert_awaited_once_with("last")
    assert captured[0].timeout_s == 17
    assert captured[0].json_schema is None


async def test_t108_prompt_block_order_and_citations(chunk_factory: Callable[[int], CodeChunk]) -> None:
    service, *_ = harness([RetrievedChunk(chunk_factory(i), 1) for i in (2, 0)])
    bundle = await service.build_context("p", "q", budget_tokens=100, attached_paths=["file2.py", "file0.py"])
    prompt = service._template.render(blocks=bundle.blocks)
    assert prompt.index("### file0.py:1-1 (f0)") < prompt.index("### file2.py:1-1 (f2)")
    assert "[path:start-end]" in prompt
    assert prompt.count("```python") == 2


async def test_t108_history_recent_whole_messages() -> None:
    service, _, _, llm, _ = harness(num_ctx=400)
    captured = []
    llm._replies = lambda req: captured.append(req) or "ok"
    messages = (
        ChatMessage(Role.USER, "old" * 200),
        ChatMessage(Role.ASSISTANT, "recent"),
        ChatMessage(Role.USER, "last"),
    )
    request = replace(question(top_k=0, params=GenerationParams(max_tokens=100)), messages=messages)
    _ = [e async for e in service.chat_stream(request)]
    assert captured[0].messages[1:] == messages[1:]


@pytest.mark.parametrize("messages", [(), (ChatMessage(Role.ASSISTANT, "x"),)])
async def test_t108_invalid_last_role(messages: tuple[ChatMessage, ...]) -> None:
    service, *_ = harness()
    with pytest.raises(ValueError, match="last message must be user"):
        _ = [e async for e in service.chat_stream(replace(question(), messages=messages))]


@pytest.mark.parametrize("length", [3500, 1])
async def test_t108_last_user_overflow_and_zero_context(length: int) -> None:
    service, *_ = harness(num_ctx=100)
    request = replace(
        question(params=GenerationParams(max_tokens=99)), messages=(ChatMessage(Role.USER, "a" * length),)
    )
    with pytest.raises(ContextTooLarge):
        _ = [e async for e in service.chat_stream(request)]
