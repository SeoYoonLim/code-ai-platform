"""Composition and ownership without upstream servers."""

from unittest.mock import AsyncMock

import pytest
import respx

from engine import container as module
from engine.adapters.embeddings.ollama_embed import OllamaEmbedder
from engine.adapters.llm.llamacpp import LlamaServerProvider
from engine.adapters.parsing.treesitter_chunker import TreeSitterChunker
from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.errors import ParseError
from engine.settings import Settings


def t106_fake_config() -> Settings:
    return Settings(_env_file=None, llm_provider="fake", embedder_provider="fake", vector_store="memory")


async def test_t106_container_fake_context() -> None:
    async with await module.build_container(t106_fake_config()) as built:
        assert built.llm.name == "fake"
        assert built.embedder.dimension == built.settings.embed_dimension
        assert isinstance(built.store, InMemoryVectorStore)
        assert isinstance(built.chunker, TreeSitterChunker)
    await built.aclose()


async def test_t106_container_real_lazy_and_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    connect = AsyncMock(return_value=InMemoryVectorStore())
    monkeypatch.setattr(module, "connect", connect)
    config = Settings(
        _env_file=None,
        embed_dimension=12,
        embed_batch_size=7,
        embed_device_policy="dynamic",
        embed_idle_grace_s=2,
        embed_min_dwell_s=9,
        embed_doc_prefix="D:",
        embed_query_prefix="Q:",
    )
    with respx.mock(assert_all_called=False) as router:
        built = await module.build_container(config)
        llm, embedder = built.llm, built.embedder
        assert isinstance(llm, LlamaServerProvider)
        assert isinstance(embedder, OllamaEmbedder)
        assert embedder._policy._gauge is llm
        assert (embedder._policy._policy, embedder._policy._grace, embedder._policy._dwell) == (
            "dynamic",
            2,
            9,
        )
        assert (embedder._doc_prefix, embedder._query_prefix) == ("D:", "Q:")
        assert (embedder.dimension, embedder._batch_size) == (12, 7)
        assert embedder.model_name == config.embed_model
        assert embedder._url == str(config.embed_url).rstrip("/") + "/api/embed"
        connect.assert_awaited_once_with(config)
        assert len(router.calls) == 0
        await built.aclose()
        await built.aclose()
        assert llm._client.is_closed
        assert embedder._client.is_closed
        assert len(router.calls) == 0


async def test_t106_container_fake_gauge() -> None:
    config = Settings(_env_file=None, llm_provider="fake", vector_store="memory")
    async with await module.build_container(config) as built:
        assert isinstance(built.embedder, OllamaEmbedder)
        assert built.embedder._policy._gauge is None


@pytest.mark.parametrize("step", ["embedder", "store", "chunker", "registry"])
async def test_t106_container_partial_failure(step: str, monkeypatch: pytest.MonkeyPatch) -> None:
    llm = LlamaServerProvider(Settings(_env_file=None))
    embedder = OllamaEmbedder(base_url="http://unused")
    llm_close = AsyncMock(wraps=llm.aclose)
    embed_close = AsyncMock(wraps=embedder.aclose)
    monkeypatch.setattr(llm, "aclose", llm_close)
    monkeypatch.setattr(embedder, "aclose", embed_close)
    monkeypatch.setattr(module, "build_llm", lambda settings: llm)
    monkeypatch.setattr(module, "build_embedder", lambda settings, llm: embedder)
    monkeypatch.setattr(module, "build_store", AsyncMock(return_value=InMemoryVectorStore()))
    failure = ParseError("t106 injected failure")

    def fail(*args: object) -> None:
        raise failure

    replacement = AsyncMock(side_effect=failure) if step == "store" else fail
    monkeypatch.setattr(module, "build_" + step, replacement)
    try:
        with pytest.raises(ParseError) as caught:
            await module.build_container(Settings(_env_file=None))
        assert caught.value is failure
        assert llm_close.await_count == 1
        assert embed_close.await_count == (0 if step == "embedder" else 1)
        assert llm._client.is_closed
        if step != "embedder":
            assert embedder._client.is_closed
    finally:
        await llm._client.aclose()
        await embedder._client.aclose()


async def test_t106_container_cleanup_failure_preserves_original(monkeypatch: pytest.MonkeyPatch) -> None:
    llm = LlamaServerProvider(Settings(_env_file=None))
    close = AsyncMock(side_effect=RuntimeError("cleanup failed"))
    monkeypatch.setattr(llm, "aclose", close)
    monkeypatch.setattr(module, "build_llm", lambda settings: llm)
    original = ParseError("original")
    monkeypatch.setattr(module, "build_embedder", lambda *args: (_ for _ in ()).throw(original))
    try:
        with pytest.raises(ParseError) as caught:
            await module.build_container(Settings(_env_file=None))
        assert caught.value is original
        close.assert_awaited_once()
    finally:
        await llm._client.aclose()


async def test_t106_container_injected_factory_ownership(monkeypatch: pytest.MonkeyPatch) -> None:
    from engine.adapters.llm.fake import FakeLLMProvider

    class OwnedFake(FakeLLMProvider):
        def __init__(self) -> None:
            super().__init__()
            self.closed = 0

        async def aclose(self) -> None:
            self.closed += 1

    llm = OwnedFake()
    monkeypatch.setattr(module, "build_llm", lambda settings: llm)
    failure = RuntimeError("second factory failed")

    def fail_embedder(settings: Settings, provider: object) -> None:
        raise failure

    monkeypatch.setattr(module, "build_embedder", fail_embedder)
    with pytest.raises(RuntimeError) as caught:
        await module.build_container(t106_fake_config())
    assert caught.value is failure
    assert llm.closed == 1

    monkeypatch.setattr(module, "build_embedder", lambda settings, llm: module.FakeEmbedder())
    built = await module.build_container(t106_fake_config())
    await built.aclose()
    await built.aclose()
    assert llm.closed == 2
