"""Engine environment settings."""

import pytest
from pydantic import ValidationError

from engine.settings import Settings


def test_environment_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENGINE_LLAMACPP_URL", "http://server:8080")
    monkeypatch.setenv("ENGINE_BASE_MODEL", "custom")
    monkeypatch.setenv("ENGINE_LLAMACPP_API_KEY", "test-key")
    settings = Settings(_env_file=None)
    assert str(settings.llamacpp_url) == "http://server:8080/"
    assert settings.base_model == "custom"
    assert settings.llamacpp_api_key.get_secret_value() == "test-key"
    assert "test-key" not in repr(settings)


def test_defaults_and_invalid_url(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in ("ENGINE_LLAMACPP_URL", "ENGINE_BASE_MODEL", "ENGINE_LLAMACPP_API_KEY"):
        monkeypatch.delenv(name, raising=False)
    assert str(Settings(_env_file=None).llamacpp_url) == "http://localhost:8080/"
    monkeypatch.setenv("ENGINE_LLAMACPP_URL", "invalid")
    with pytest.raises(ValidationError):
        Settings(_env_file=None)


@pytest.mark.parametrize("policy", ["dynamic", "gpu", "cpu"])
def test_embedding_environment(policy: str, monkeypatch: pytest.MonkeyPatch) -> None:
    values = {
        "DEVICE_POLICY": policy,
        "IDLE_GRACE_S": "2.5",
        "MIN_DWELL_S": "12",
        "BATCH_SIZE": "16",
        "DIMENSION": "12",
        "MODEL": "custom",
        "URL": "http://embed:11434",
        "DOC_PREFIX": "D:",
        "QUERY_PREFIX": "Q:",
    }
    for key, value in values.items():
        monkeypatch.setenv("ENGINE_EMBED_" + key, value)
    settings = Settings(_env_file=None)
    assert settings.embed_device_policy == policy
    assert settings.embed_idle_grace_s == 2.5
    assert settings.embed_min_dwell_s == 12
    assert settings.embed_batch_size == 16
    assert settings.embed_dimension == 12
    assert settings.embed_model == "custom"
    assert str(settings.embed_url) == "http://embed:11434/"
    assert (settings.embed_doc_prefix, settings.embed_query_prefix) == ("D:", "Q:")


@pytest.mark.parametrize(
    ("key", "value"),
    [
        ("DEVICE_POLICY", "invalid"),
        ("BATCH_SIZE", "0"),
        ("DIMENSION", "0"),
        ("IDLE_GRACE_S", "-1"),
        ("MIN_DWELL_S", "-1"),
        ("URL", "invalid"),
    ],
)
def test_invalid_embedding_settings(key: str, value: str, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENGINE_EMBED_" + key, value)
    with pytest.raises(ValidationError):
        Settings(_env_file=None)


def test_embedding_defaults(monkeypatch: pytest.MonkeyPatch) -> None:
    for key in (
        "URL",
        "MODEL",
        "DIMENSION",
        "BATCH_SIZE",
        "DEVICE_POLICY",
        "IDLE_GRACE_S",
        "MIN_DWELL_S",
        "DOC_PREFIX",
        "QUERY_PREFIX",
    ):
        monkeypatch.delenv("ENGINE_EMBED_" + key, raising=False)
    settings = Settings(_env_file=None)
    assert settings.embed_device_policy == "gpu"
    assert settings.embed_idle_grace_s == 3
    assert settings.embed_min_dwell_s == 10
    assert settings.embed_batch_size == 32
    assert settings.embed_dimension == 768
    assert settings.embed_model == "nomic-embed-text"
    assert settings.embed_doc_prefix == "search_document: "
    assert settings.embed_query_prefix == "search_query: "
    assert str(settings.embed_url) == "http://localhost:11434/"


def test_chroma_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("ENGINE_CHROMA_URL", raising=False)
    assert str(Settings(_env_file=None).chroma_url) == "http://localhost:8001/"
    monkeypatch.setenv("ENGINE_CHROMA_URL", "https://chroma:8443")
    assert str(Settings(_env_file=None).chroma_url) == "https://chroma:8443/"
    monkeypatch.setenv("ENGINE_CHROMA_URL", "invalid")
    with pytest.raises(ValidationError):
        Settings(_env_file=None)


def test_t106_provider_defaults(monkeypatch: pytest.MonkeyPatch) -> None:
    from pathlib import Path

    for key in ("LLM_PROVIDER", "EMBEDDER_PROVIDER", "VECTOR_STORE", "REGISTRY_PATH"):
        monkeypatch.delenv("ENGINE_" + key, raising=False)
    config = Settings(_env_file=None)
    assert (config.llm_provider, config.embedder_provider, config.vector_store) == (
        "llamacpp",
        "ollama",
        "chroma",
    )
    assert config.registry_path == Path("ml/registry/adapters.json")


def test_t106_provider_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    from pathlib import Path

    for key, value in {
        "LLM_PROVIDER": "fake",
        "EMBEDDER_PROVIDER": "fake",
        "VECTOR_STORE": "memory",
        "REGISTRY_PATH": "custom/t106.json",
    }.items():
        monkeypatch.setenv("ENGINE_" + key, value)
    config = Settings(_env_file=None)
    assert (config.llm_provider, config.embedder_provider, config.vector_store) == ("fake", "fake", "memory")
    assert config.registry_path == Path("custom/t106.json")


@pytest.mark.parametrize("key", ["LLM_PROVIDER", "EMBEDDER_PROVIDER", "VECTOR_STORE"])
def test_t106_invalid_provider(key: str, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENGINE_" + key, "invalid")
    with pytest.raises(ValidationError):
        Settings(_env_file=None)
