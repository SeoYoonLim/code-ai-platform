"""LLM 생성 도메인 모델."""

from dataclasses import dataclass, field
from enum import StrEnum


class Role(StrEnum):
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"


class FinishReason(StrEnum):
    STOP = "stop"
    LENGTH = "length"
    ERROR = "error"
    CANCELED = "canceled"


@dataclass(frozen=True, slots=True)
class ChatMessage:
    role: Role
    content: str


@dataclass(frozen=True, slots=True)
class GenerationParams:
    temperature: float = 0.2
    top_p: float = 0.95
    max_tokens: int = 2048
    stop: tuple[str, ...] = ()
    seed: int | None = None


@dataclass(frozen=True, slots=True)
class GenerationRequest:
    """adapter=None 이면 base 모델로 생성한다.

    json_schema가 주어지면 provider는 구조화 출력(Ollama `format`, vLLM guided decoding)을 사용해야 한다.
    """

    messages: tuple[ChatMessage, ...]
    adapter: str | None = None
    params: GenerationParams = field(default_factory=GenerationParams)
    json_schema: dict[str, object] | None = None
    timeout_s: float = 120.0


@dataclass(frozen=True, slots=True)
class TokenUsage:
    prompt_tokens: int
    completion_tokens: int


@dataclass(frozen=True, slots=True)
class GenerationResult:
    text: str
    model: str
    adapter: str | None
    finish_reason: FinishReason
    usage: TokenUsage
    latency_ms: int


@dataclass(frozen=True, slots=True)
class TokenChunk:
    """스트리밍 단위. 마지막 청크만 finish_reason/usage를 가진다."""

    delta: str
    index: int
    finish_reason: FinishReason | None = None
    usage: TokenUsage | None = None


@dataclass(frozen=True, slots=True)
class ProviderHealth:
    ok: bool
    provider: str
    base_model: str
    loaded_adapters: tuple[str, ...] = ()
    detail: str | None = None
