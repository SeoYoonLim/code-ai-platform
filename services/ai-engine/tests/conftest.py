"""Shared deterministic adapters and sample chunk factory."""

from collections.abc import Callable

import pytest

from engine.adapters.embeddings.fake import FakeEmbedder
from engine.adapters.llm.fake import FakeLLMProvider
from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.models import ChunkKind, CodeChunk, Language


@pytest.fixture
def fake_llm() -> FakeLLMProvider:
    return FakeLLMProvider(replies=("one two three",))


@pytest.fixture
def fake_embedder() -> FakeEmbedder:
    return FakeEmbedder()


@pytest.fixture
def in_memory_store() -> InMemoryVectorStore:
    return InMemoryVectorStore()


@pytest.fixture
def chunk_factory() -> Callable[[int], CodeChunk]:
    def make(index: int) -> CodeChunk:
        return CodeChunk(
            chunk_id=f"p:file{index}.py::f{index}@1-1",
            project_id="p",
            path=f"file{index}.py",
            language=Language.PYTHON,
            kind=ChunkKind.FUNCTION,
            symbol=f"f{index}",
            raw_code=f"def f{index}(): return {index}",
            search_text=f"# function f{index}\ndef f{index}(): return {index}",
            start_line=1,
            end_line=1,
            content_hash=f"hash{index}",
            commit_sha="abc",
        )

    return make
