"""RAG test harness with sampled, permutable query results."""

from collections.abc import Sequence
from unittest.mock import AsyncMock

from engine.adapters.embeddings.fake import FakeEmbedder
from engine.adapters.llm.fake import FakeLLMProvider
from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.models import (
    ChatMessage,
    ChatRequest,
    GenerationParams,
    MetadataFilter,
    RetrievedChunk,
    Role,
)
from engine.services.rag_service import RagService


class SampleStore(InMemoryVectorStore):
    def __init__(self, items: Sequence[RetrievedChunk] = ()) -> None:
        super().__init__()
        self.items = list(items)
        self.calls: list[tuple[str, int, MetadataFilter | None]] = []

    async def query(
        self,
        collection: str,
        embedding: Sequence[float],
        *,
        top_k: int = 8,
        where: MetadataFilter | None = None,
    ) -> list[RetrievedChunk]:
        self.calls.append((collection, top_k, where))
        return self.items[:top_k]


def harness(
    items: Sequence[RetrievedChunk] = (),
    *,
    num_ctx: int = 16384,
    oversample: int = 2,
) -> tuple[RagService, SampleStore, FakeEmbedder, FakeLLMProvider, AsyncMock]:
    store = SampleStore(items)
    embedder = FakeEmbedder()
    registry = AsyncMock()
    registry.resolve.return_value = None
    llm = FakeLLMProvider(replies=("one two three",))
    service = RagService(embedder, store, llm, registry, num_ctx=num_ctx, oversample=oversample)
    return service, store, embedder, llm, registry


def question(
    *,
    top_k: int = 8,
    adapter: str | None = None,
    params: GenerationParams | None = None,
    timeout_s: float = 180,
) -> ChatRequest:
    return ChatRequest(
        "p",
        (ChatMessage(Role.USER, "question"),),
        top_k=top_k,
        adapter=adapter,
        params=params or GenerationParams(),
        timeout_s=timeout_s,
    )
