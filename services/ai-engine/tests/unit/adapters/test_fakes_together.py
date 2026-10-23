"""Network-free integration smoke for all three fakes."""

from collections.abc import Callable

from engine.adapters.embeddings.fake import FakeEmbedder
from engine.adapters.llm.fake import FakeLLMProvider
from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.models import ChatMessage, CodeChunk, GenerationRequest, Role


async def test_fakes_index_retrieve_and_generate(
    fake_embedder: FakeEmbedder,
    in_memory_store: InMemoryVectorStore,
    fake_llm: FakeLLMProvider,
    chunk_factory: Callable[[int], CodeChunk],
) -> None:
    chunks = [chunk_factory(i) for i in range(5)]
    vectors = await fake_embedder.embed_documents([chunk.search_text for chunk in chunks])
    await in_memory_store.ensure_collection("proj_p", dimension=fake_embedder.dimension)
    await in_memory_store.upsert("proj_p", chunks, vectors)
    query = await fake_embedder.embed_query(chunks[3].search_text)
    results = await in_memory_store.query("proj_p", query, top_k=5)
    assert len(results) == 5
    assert results[0].chunk == chunks[3]
    reply = await fake_llm.generate(
        GenerationRequest(messages=(ChatMessage(Role.USER, results[0].chunk.search_text),))
    )
    assert reply.text == "one two three"
    assert fake_llm.in_flight == 0
