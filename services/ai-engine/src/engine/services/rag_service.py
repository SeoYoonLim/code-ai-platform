"""검색 + 컨텍스트 조립 + 근거 기반 채팅 유스케이스. 설계: docs/architecture/02-data-flow.md §4.1, 카드 T-108.

서비스는 포트(core.interfaces)만 안다. 어떤 저장소·모델 서버인지는 container가 주입한다.
`state == "live"` 같은 저장소 내부 상태는 모른다 — VectorStore 계약이 보장한다 (ADR-0005).
"""

from collections.abc import AsyncIterator, Callable, Sequence

from engine.core.interfaces import Embedder, LLMProvider, LoRAAdapterRegistry, VectorStore
from engine.core.models import (
    ChatEvent,
    ChatRequest,
    ContextBundle,
    MetadataFilter,
    RetrievedChunk,
)


def estimate_tokens(text: str) -> int:
    """MVP 근사: ceil(len(text) / 3.5). 실제 토크나이저로 바꿀 때 이 함수만 교체한다."""
    raise NotImplementedError


class RagService:
    def __init__(
        self,
        embedder: Embedder,
        store: VectorStore,
        llm: LLMProvider,
        registry: LoRAAdapterRegistry,
        *,
        num_ctx: int = 16384,
        oversample: int = 2,
        clock: Callable[[], float] | None = None,
    ) -> None:
        raise NotImplementedError

    async def retrieve(
        self,
        project_id: str,
        query: str,
        *,
        top_k: int = 8,
        min_score: float = 0.0,
        where: MetadataFilter | None = None,
    ) -> list[RetrievedChunk]:
        """질의 임베딩 → 검색 → 결정적 정렬. 컬렉션이 없으면 CollectionNotFound를 그대로 올린다."""
        raise NotImplementedError

    async def build_context(
        self,
        project_id: str,
        query: str,
        *,
        budget_tokens: int,
        attached_paths: Sequence[str] = (),
        top_k: int = 8,
        exclude: Sequence[tuple[str, int, int]] = (),
    ) -> ContextBundle:
        """우선순위: ① 첨부 파일 청크 ② 유사 청크(score 내림차순).

        exclude=(path, start, end)와 줄 범위가 겹치는 청크는 뺀다.
        """
        raise NotImplementedError

    def chat_stream(self, request: ChatRequest) -> AsyncIterator[ChatEvent]:
        """SourcesEvent 1회 → TokenEvent* → DoneEvent 1회.

        오류는 EngineError로 올린다 (error 이벤트 변환은 API 계층).
        """
        raise NotImplementedError
