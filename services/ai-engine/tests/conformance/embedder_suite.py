"""Reusable embedding rules; requires fixture embedder: Embedder."""

import math

import pytest

from engine.core.interfaces.embedder import Embedder


class EmbedderConformance:
    def test_runtime_protocol(self, embedder: Embedder) -> None:
        assert isinstance(embedder, Embedder)

    async def test_vectors_are_l2_normalized(self, embedder: Embedder) -> None:
        for vector in await embedder.embed_documents(["alpha", "beta", ""]):
            assert math.sqrt(sum(x * x for x in vector)) == pytest.approx(1, abs=1e-6)
        query = await embedder.embed_query("alpha")
        assert math.sqrt(sum(x * x for x in query)) == pytest.approx(1, abs=1e-6)

    async def test_output_length_matches_input(self, embedder: Embedder) -> None:
        assert len(await embedder.embed_documents(["a", "b", "c"])) == 3

    async def test_output_preserves_order(self, embedder: Embedder) -> None:
        together = await embedder.embed_documents(["a", "b", "a"])
        assert together == [(await embedder.embed_documents([text]))[0] for text in ["a", "b", "a"]]

    async def test_empty_input(self, embedder: Embedder) -> None:
        assert await embedder.embed_documents([]) == []

    async def test_embeddings_are_deterministic(self, embedder: Embedder) -> None:
        assert await embedder.embed_documents(["a"]) == await embedder.embed_documents(["a"])
        assert await embedder.embed_query("a") == await embedder.embed_query("a")

    async def test_dimension_matches_vectors(self, embedder: Embedder) -> None:
        assert embedder.dimension > 0
        assert len(await embedder.embed_query("a")) == embedder.dimension
        assert len((await embedder.embed_documents(["a"]))[0]) == embedder.dimension

    def test_model_name_is_nonempty(self, embedder: Embedder) -> None:
        assert embedder.model_name
