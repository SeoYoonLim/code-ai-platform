"""Composition root and ownership of adapter resources."""

from contextlib import AsyncExitStack
from dataclasses import dataclass, field
from types import TracebackType
from typing import Protocol, runtime_checkable

import structlog

from engine.adapters.embeddings.fake import FakeEmbedder
from engine.adapters.embeddings.ollama_embed import OllamaEmbedder
from engine.adapters.llm.fake import FakeLLMProvider
from engine.adapters.llm.llamacpp import LlamaServerProvider
from engine.adapters.parsing.language_map import language_for_path
from engine.adapters.parsing.treesitter_chunker import TreeSitterChunker
from engine.adapters.registry_file import FileAdapterRegistry
from engine.adapters.source.git_scanner import FileSystemScanner
from engine.adapters.vectorstore.chroma import connect
from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.interfaces import (
    ActivityGauge,
    CodeChunker,
    Embedder,
    LLMProvider,
    LoRAAdapterRegistry,
    SourceScanner,
    VectorStore,
)
from engine.services.indexing_service import IndexingService
from engine.settings import Settings

log = structlog.get_logger()


@runtime_checkable
class _AsyncCloseable(Protocol):
    async def aclose(self) -> None: ...


def _own(resources: AsyncExitStack, adapter: object) -> None:
    if isinstance(adapter, _AsyncCloseable):
        resources.push_async_callback(adapter.aclose)


@dataclass(frozen=True, slots=True)
class Container:
    llm: LLMProvider
    embedder: Embedder
    store: VectorStore
    chunker: CodeChunker
    registry: LoRAAdapterRegistry
    settings: Settings
    scanner: SourceScanner
    indexing: IndexingService
    _resources: AsyncExitStack = field(default_factory=AsyncExitStack, repr=False, compare=False)

    async def aclose(self) -> None:
        await self._resources.aclose()

    async def __aenter__(self) -> "Container":
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        await self.aclose()


def build_llm(settings: Settings) -> LLMProvider:
    if settings.llm_provider == "fake":
        return FakeLLMProvider(model=settings.base_model)
    return LlamaServerProvider(settings)


def build_embedder(settings: Settings, llm: LLMProvider) -> Embedder:
    if settings.embedder_provider == "fake":
        return FakeEmbedder(dimension=settings.embed_dimension, model_name=settings.embed_model)
    gauge = llm if settings.llm_provider != "fake" and isinstance(llm, ActivityGauge) else None
    return OllamaEmbedder(
        base_url=str(settings.embed_url),
        model=settings.embed_model,
        dimension=settings.embed_dimension,
        batch_size=settings.embed_batch_size,
        gauge=gauge,
        policy=settings.embed_device_policy,
        idle_grace_s=settings.embed_idle_grace_s,
        min_dwell_s=settings.embed_min_dwell_s,
        doc_prefix=settings.embed_doc_prefix,
        query_prefix=settings.embed_query_prefix,
    )


async def build_store(settings: Settings) -> VectorStore:
    if settings.vector_store == "memory":
        return InMemoryVectorStore()
    # chromadb-client 1.5.9 AsyncHttpClient returns AsyncClientAPI/AsyncClient,
    # neither exposes close/aclose or async context management. The transport's
    # __aexit__ is not exposed by that client; do not reach into private _server.
    return await connect(settings)


def build_chunker(settings: Settings) -> CodeChunker:
    return TreeSitterChunker()


def build_registry(settings: Settings) -> LoRAAdapterRegistry:
    return FileAdapterRegistry(settings.registry_path, base_model=settings.base_model)


async def build_container(settings: Settings | None = None) -> Container:
    config = settings if settings is not None else Settings()
    resources = AsyncExitStack()
    try:
        llm = build_llm(config)
        _own(resources, llm)
        embedder = build_embedder(config, llm)
        _own(resources, embedder)
        store = await build_store(config)
        _own(resources, store)
        chunker = build_chunker(config)
        _own(resources, chunker)
        registry = build_registry(config)
        _own(resources, registry)
        scanner = FileSystemScanner(
            language_for_path=language_for_path, max_file_bytes=config.index_max_file_bytes
        )
        indexing = IndexingService(scanner, chunker, embedder, store)
        return Container(llm, embedder, store, chunker, registry, config, scanner, indexing, resources)
    except BaseException:
        # Attempt every callback and preserve the original build failure.
        try:
            await resources.aclose()
        except BaseException:
            log.exception("container_build_cleanup_failed")
        raise
