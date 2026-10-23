"""RAG 질의·컨텍스트·채팅 스트림 도메인 모델.

engine.v1.yaml의 ChatStreamRequest/SourceRef/StreamEvent와 대응한다.
"""

from dataclasses import dataclass, field

from engine.core.models.code import CodeChunk
from engine.core.models.generation import ChatMessage, FinishReason, GenerationParams, TokenUsage


@dataclass(frozen=True, slots=True)
class SourceRef:
    """본문 없는 청크 참조. 답변의 출처 표시용 (SSE sources 이벤트)."""

    chunk_id: str
    path: str
    symbol: str
    start_line: int
    end_line: int
    score: float


@dataclass(frozen=True, slots=True)
class ContextBlock:
    """프롬프트에 들어가는 코드 조각 1개.

    chunk.raw_code가 LLM에 전달되는 본문이다.
    chunk.search_text는 검색(임베딩) 전용이라 프롬프트에 넣지 않는다.
    origin: "attached"(사용자가 첨부한 파일) | "retrieved"(유사도 검색).
    """

    chunk: CodeChunk
    score: float
    origin: str
    tokens: int


@dataclass(frozen=True, slots=True)
class ContextBundle:
    """조립된 컨텍스트. dropped_*는 예산·중복 때문에 빠진 개수 (관측용)."""

    blocks: tuple[ContextBlock, ...]
    tokens: int
    budget_tokens: int
    dropped_over_budget: int = 0
    dropped_overlap: int = 0

    @property
    def sources(self) -> tuple[SourceRef, ...]:
        return tuple(
            SourceRef(
                b.chunk.chunk_id, b.chunk.path, b.chunk.symbol, b.chunk.start_line, b.chunk.end_line, b.score
            )
            for b in self.blocks
        )


@dataclass(frozen=True, slots=True)
class ChatRequest:
    """messages의 마지막은 role=user여야 한다 (아니면 ValueError)."""

    project_id: str
    messages: tuple[ChatMessage, ...]
    context_paths: tuple[str, ...] = ()
    top_k: int = 8
    adapter: str | None = None
    params: GenerationParams = field(default_factory=GenerationParams)
    timeout_s: float = 180.0


@dataclass(frozen=True, slots=True)
class SourcesEvent:
    sources: tuple[SourceRef, ...]


@dataclass(frozen=True, slots=True)
class TokenEvent:
    index: int
    delta: str


@dataclass(frozen=True, slots=True)
class DoneEvent:
    finish_reason: FinishReason
    usage: TokenUsage
    latency_ms: int


ChatEvent = SourcesEvent | TokenEvent | DoneEvent
"""meta(stream_id/request_id)와 error 이벤트는 HTTP 계층(T-109)의 몫이다. 서비스는 예외를 그대로 올린다."""
