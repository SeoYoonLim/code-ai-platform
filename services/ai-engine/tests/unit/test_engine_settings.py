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
