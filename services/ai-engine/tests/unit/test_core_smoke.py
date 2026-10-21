"""core 패키지 스모크 테스트: 공개 심볼 import 및 도메인 모델 불변성."""

import dataclasses

import pytest

from engine.core import interfaces
from engine.core.errors import EngineError, ProviderUnavailable
from engine.core.models import ChatMessage, GenerationRequest, Role


def test_interfaces_exported() -> None:
    assert set(interfaces.__all__) == {
        "ActivityGauge",
        "CodeChunker",
        "Embedder",
        "LLMProvider",
        "LoRAAdapterRegistry",
        "VectorStore",
    }


def test_generation_request_is_frozen() -> None:
    req = GenerationRequest(messages=(ChatMessage(role=Role.USER, content="hi"),))
    with pytest.raises(dataclasses.FrozenInstanceError):
        req.adapter = "x"  # type: ignore[misc]  # 불변성 검증 목적


def test_error_codes_are_distinct() -> None:
    assert ProviderUnavailable("down").code != EngineError("x").code
    assert ProviderUnavailable.retryable is True
