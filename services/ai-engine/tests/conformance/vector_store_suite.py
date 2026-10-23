"""Reusable vector rules; fixtures store: VectorStore, chunk_factory: Callable[[int], CodeChunk]."""

from collections.abc import Callable
from dataclasses import replace

import pytest

from engine.core.errors import CollectionNotFound, VectorStoreError
from engine.core.interfaces.vector_store import VectorStore
from engine.core.models import CodeChunk, MetadataFilter


class VectorStoreConformance:
    @pytest.fixture
    async def populated(self, store: VectorStore, chunk_factory: Callable[[int], CodeChunk]) -> VectorStore:
        await store.ensure_collection("c", dimension=2)
        await store.upsert("c", [chunk_factory(i) for i in range(3)], [[1.0, 0.0], [1.0, 1.0], [-1.0, 0.0]])
        return store

    def test_runtime_protocol(self, store: VectorStore) -> None:
        assert isinstance(store, VectorStore)

    async def test_upsert_is_idempotent(
        self, populated: VectorStore, chunk_factory: Callable[[int], CodeChunk]
    ) -> None:
        await populated.upsert("c", [chunk_factory(0)], [[1.0, 0.0]])
        assert len(await populated.query("c", [1.0, 0.0])) == 3

    async def test_upsert_replaces_existing_chunk(
        self, populated: VectorStore, chunk_factory: Callable[[int], CodeChunk]
    ) -> None:
        updated = replace(chunk_factory(0), raw_code="updated", search_text="updated search")
        await populated.upsert("c", [updated], [[1.0, 0.0]])
        assert (await populated.query("c", [1.0, 0.0]))[0].chunk.raw_code == "updated"

    async def test_length_mismatch_raises(
        self, populated: VectorStore, chunk_factory: Callable[[int], CodeChunk]
    ) -> None:
        with pytest.raises(ValueError, match=r".+"):
            await populated.upsert("c", [chunk_factory(0)], [])

    async def test_collection_dimension_mismatch_raises(self, populated: VectorStore) -> None:
        with pytest.raises(VectorStoreError):
            await populated.ensure_collection("c", dimension=3)

    async def test_upsert_dimension_mismatch_raises(
        self, populated: VectorStore, chunk_factory: Callable[[int], CodeChunk]
    ) -> None:
        with pytest.raises(VectorStoreError):
            await populated.upsert("c", [chunk_factory(0)], [[1.0]])

    async def test_query_dimension_mismatch_raises(self, populated: VectorStore) -> None:
        with pytest.raises(VectorStoreError):
            await populated.query("c", [1.0])

    @pytest.mark.parametrize("operation", ["query", "delete", "hashes", "drop", "upsert"])
    async def test_missing_collection_raises(self, store: VectorStore, operation: str) -> None:
        async def invoke() -> None:
            if operation == "query":
                await store.query("missing", [1.0, 0.0])
            elif operation == "delete":
                await store.delete_by_paths("missing", [])
            elif operation == "hashes":
                await store.get_file_hashes("missing")
            elif operation == "upsert":
                await store.upsert("missing", [], [])
            else:
                await store.drop_collection("missing")

        with pytest.raises(CollectionNotFound):
            await invoke()

    async def test_query_orders_by_score_desc(self, populated: VectorStore) -> None:
        results = await populated.query("c", [1.0, 0.0])
        assert [r.chunk.symbol for r in results] == ["f0", "f1", "f2"]
        assert [r.score for r in results] == sorted((r.score for r in results), reverse=True)

    async def test_query_limits_top_k(self, populated: VectorStore) -> None:
        assert len(await populated.query("c", [1.0, 0.0], top_k=2)) == 2

    async def test_where_equals_combines_with_and(self, populated: VectorStore) -> None:
        results = await populated.query(
            "c", [1.0, 0.0], where=MetadataFilter({"path": "file0.py", "symbol": "f1"})
        )
        assert results == []

    async def test_where_tuple_uses_in(self, populated: VectorStore) -> None:
        results = await populated.query("c", [1.0, 0.0], where=MetadataFilter({"symbol": ("f0", "f2")}))
        assert [r.chunk.symbol for r in results] == ["f0", "f2"]

    async def test_unknown_filter_key_raises(self, populated: VectorStore) -> None:
        with pytest.raises(ValueError, match=r".+"):
            await populated.query("c", [1.0, 0.0], where=MetadataFilter({"unsupported": "x"}))

    async def test_delete_by_paths_returns_count(self, populated: VectorStore) -> None:
        assert await populated.delete_by_paths("c", ["file0.py", "file2.py"]) == 2
        assert await populated.delete_by_paths("c", ["file0.py"]) == 0
        assert len(await populated.query("c", [1.0, 0.0])) == 1

    async def test_get_file_hashes(self, populated: VectorStore) -> None:
        assert await populated.get_file_hashes("c") == {f"file{i}.py": f"hash{i}" for i in range(3)}

    async def test_drop_then_query_raises(self, populated: VectorStore) -> None:
        await populated.drop_collection("c")
        with pytest.raises(CollectionNotFound):
            await populated.query("c", [1.0, 0.0])

    async def test_ensure_existing_preserves_data(self, populated: VectorStore) -> None:
        await populated.ensure_collection("c", dimension=2)
        assert len(await populated.query("c", [1.0, 0.0])) == 3

    async def test_scores_clamp_negative_cosine(self, populated: VectorStore) -> None:
        results = await populated.query("c", [2.0, 0.0])
        assert results[0].score == pytest.approx(1.0)
        assert results[-1].score == 0.0
        assert all(0 <= result.score <= 1 for result in results)

    async def test_zero_vector_scores_zero(self, populated: VectorStore) -> None:
        assert all(result.score == 0 for result in await populated.query("c", [0.0, 0.0]))
