"""Retrieval permutations, overlap priority, and complete-block budgets."""

from collections.abc import Callable
from dataclasses import replace
from itertools import permutations
from unittest.mock import AsyncMock

import pytest

from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.errors import CollectionNotFound, ContextTooLarge
from engine.core.models import ChunkKind, CodeChunk, MetadataFilter, RetrievedChunk
from engine.services.rag_service import estimate_tokens
from tests.unit.services.rag_fakes import harness


@pytest.mark.parametrize("epsilon", [0, 1e-9])
async def test_t108_all_tie_permutations(chunk_factory: Callable[[int], CodeChunk], epsilon: float) -> None:
    items = [RetrievedChunk(chunk_factory(i), 0.5 + i * epsilon) for i in range(5)]
    service, store, *_ = harness(oversample=3)
    for order in permutations(items):
        store.items = list(order)
        result = await service.retrieve("p", "query", top_k=2)
        assert [r.chunk.chunk_id for r in result] == [items[0].chunk.chunk_id, items[1].chunk.chunk_id]
        assert [r.score for r in result] == [items[0].score, items[1].score]
    assert all(call == ("proj_p", 6, None) for call in store.calls)


async def test_t108_tie_group_wider_than_sample_widens_until_complete(
    chunk_factory: Callable[[int], CodeChunk],
) -> None:
    # 실서버 재시작 검증에서 드러난 결함: 동점 10개, top_k*oversample=8이면 어느 8개가 올지가 저장소 몫이었다.
    items = [RetrievedChunk(chunk_factory(i), 0.5) for i in range(10)]
    service, store, *_ = harness(oversample=2)
    seen = set()
    for order in (items, list(reversed(items)), items[3:] + items[:3]):
        store.items = list(order)
        result = await service.retrieve("p", "q", top_k=4)
        seen.add(tuple(r.chunk.chunk_id for r in result))
    assert seen == {tuple(item.chunk.chunk_id for item in items[:4])}
    assert [call[1] for call in store.calls[:2]] == [8, 16]  # 8 -> tie at the boundary -> 16 returns all 10


async def test_t108_no_widening_when_boundary_is_not_tied(chunk_factory: Callable[[int], CodeChunk]) -> None:
    items = [RetrievedChunk(chunk_factory(i), 0.9 - i * 0.01) for i in range(10)]
    service, store, *_ = harness(items, oversample=2)
    result = await service.retrieve("p", "q", top_k=3)
    assert [r.chunk.chunk_id for r in result] == [i.chunk.chunk_id for i in items[:3]]
    assert len(store.calls) == 1


async def test_t108_widening_stops_at_cap(
    chunk_factory: Callable[[int], CodeChunk], monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr("engine.services.rag_service.MAX_FETCH", 6)
    items = [RetrievedChunk(chunk_factory(i), 0.5) for i in range(20)]
    service, store, *_ = harness(items, oversample=2)
    result = await service.retrieve("p", "q", top_k=2)
    assert len(result) == 2
    assert [call[1] for call in store.calls] == [4, 6]  # 상한에서 멈춘다 (그 너머의 동점은 비결정적)


async def test_t108_retrieve_filters_and_missing(chunk_factory: Callable[[int], CodeChunk]) -> None:
    item = RetrievedChunk(chunk_factory(0), 0.5)
    service, store, embedder, *_ = harness([item])
    embedder.embed_query = AsyncMock(wraps=embedder.embed_query)
    for k in (0, -1):
        assert await service.retrieve("p", "q", top_k=k) == []
    assert store.calls == []
    embedder.embed_query.assert_not_called()
    where = MetadataFilter({"path": ("file0.py",)})
    assert await service.retrieve("p", "q", min_score=0.6, where=where) == []
    assert store.calls == [("proj_p", 16, where)]
    service._store = InMemoryVectorStore()
    with pytest.raises(CollectionNotFound):
        await service.retrieve("missing", "q")


async def test_t108_budget_skips_whole_blocks(chunk_factory: Callable[[int], CodeChunk]) -> None:
    chunks = [replace(chunk_factory(i), raw_code=text) for i, text in enumerate(("a" * 7, "b" * 35, "c"))]
    service, *_ = harness([RetrievedChunk(c, 1 - i / 10) for i, c in enumerate(chunks)])
    bundle = await service.build_context("p", "q", budget_tokens=3)
    assert [b.chunk.raw_code for b in bundle.blocks] == ["a" * 7, "c"]
    assert (bundle.tokens, bundle.dropped_over_budget) == (3, 1)
    with pytest.raises(ContextTooLarge) as caught:
        await service.build_context("p", "q", budget_tokens=1, attached_paths=[chunks[0].path])
    assert caught.value.detail == {"path": chunks[0].path, "tokens": 2, "budget": 1}


async def test_t108_overlap_class_method_exclude_and_replacement(
    chunk_factory: Callable[[int], CodeChunk],
) -> None:
    old = replace(chunk_factory(0), path="same.py", start_line=1, end_line=10, kind=ChunkKind.CLASS)
    new = replace(old, chunk_id="new", start_line=2, end_line=11)
    method = replace(old, chunk_id="method", start_line=4, end_line=5, kind=ChunkKind.METHOD)
    excluded = chunk_factory(2)
    service, store, *_ = harness(
        [RetrievedChunk(c, s) for c, s in ((old, 0.6), (new, 0.9), (method, 0.5), (excluded, 1))]
    )
    bundle = await service.build_context("p", "q", budget_tokens=100, exclude=[(excluded.path, 1, 1)])
    assert [b.chunk.chunk_id for b in bundle.blocks] == ["new"]
    assert bundle.dropped_overlap == 3
    assert store.calls == [("proj_p", 16, None)]  # No knowledge of replacement state.


async def test_t108_attachment_priority_and_order(chunk_factory: Callable[[int], CodeChunk]) -> None:
    attached = [RetrievedChunk(chunk_factory(i), 0.1) for i in (2, 0)]
    rival = replace(chunk_factory(0), chunk_id="rival")
    service, store, *_ = harness()
    store.query = AsyncMock(side_effect=[attached, [RetrievedChunk(rival, 1)]])
    bundle = await service.build_context("p", "q", budget_tokens=100, attached_paths=["file2.py", "file0.py"])
    assert [b.chunk.path for b in bundle.blocks] == ["file0.py", "file2.py"]
    assert bundle.dropped_overlap == 1
    assert store.query.call_args_list[0].kwargs == {
        "top_k": 16,
        "where": MetadataFilter({"path": ("file2.py", "file0.py")}),
    }


@pytest.mark.parametrize(
    ("text", "expected"),
    [("", 0), ("a", 1), ("abc", 1), ("abcd", 2), ("a" * 7, 2), ("a" * 8, 3), ("\ud55c\uae00\U0001f600", 1)],
)
def test_t108_token_estimate_edges(text: str, expected: int) -> None:
    assert estimate_tokens(text) == expected
