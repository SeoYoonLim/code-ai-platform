"""Embedding conformance and hash-specific behavior."""

import pytest

from engine.adapters.embeddings.fake import FakeEmbedder
from engine.core.interfaces.embedder import Embedder
from tests.conformance.embedder_suite import EmbedderConformance


class TestFakeEmbedder(EmbedderConformance):
    @pytest.fixture
    def embedder(self, fake_embedder: FakeEmbedder) -> Embedder:
        return fake_embedder


async def test_configuration_and_query_document_equality() -> None:
    embedder = FakeEmbedder(dimension=37, model_name="custom")
    assert embedder.dimension == 37
    assert embedder.model_name == "custom"
    documents = await embedder.embed_documents(["alpha", "beta"])
    assert documents[0] == await embedder.embed_query("alpha")
    assert documents[0] != documents[1]
    assert documents[0] == await FakeEmbedder(dimension=37).embed_query("alpha")


async def test_calls_snapshot_inputs() -> None:
    embedder = FakeEmbedder()
    texts = ["alpha"]
    await embedder.embed_documents(texts)
    texts.append("changed")
    await embedder.embed_documents([])
    await embedder.embed_query("query")
    assert embedder.calls == [["alpha"], [], ["query"]]


def test_invalid_dimension() -> None:
    with pytest.raises(ValueError, match="dimension must be positive"):
        FakeEmbedder(dimension=0)
