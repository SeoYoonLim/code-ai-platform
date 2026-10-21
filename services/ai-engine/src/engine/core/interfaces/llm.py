from collections.abc import AsyncIterator
from typing import Protocol, runtime_checkable

from engine.core.models import GenerationRequest, GenerationResult, ProviderHealth, TokenChunk


@runtime_checkable
class LLMProvider(Protocol):
    """오픈소스 서빙 엔진(Ollama, vLLM) 추상화.

    구현 규칙:
    - req.adapter가 지정되면 해당 LoRA 어댑터로 생성한다. 서빙 엔진에 없으면 AdapterNotFound.
    - req.json_schema가 지정되면 엔진의 구조화 출력 기능을 사용한다. 파싱 검증은 호출측(service) 책임.
    - 연결 실패는 ProviderUnavailable, req.timeout_s 초과는 GenerationTimeout으로 변환한다.
    - 재시도는 하지 않는다 (서비스 레이어가 정책을 가진다).
    """

    @property
    def name(self) -> str:
        """provider 식별자. 예: "ollama", "vllm", "fake"."""
        ...

    async def generate(self, req: GenerationRequest) -> GenerationResult:
        """전체 응답을 한 번에 반환한다."""
        ...

    def stream(self, req: GenerationRequest) -> AsyncIterator[TokenChunk]:
        """토큰 단위 스트리밍. 마지막 TokenChunk는 finish_reason과 usage를 반드시 포함한다.

        `async def stream(...)` 안에서 yield 하는 async generator로 구현한다.
        """
        ...

    async def health(self) -> ProviderHealth:
        """예외를 던지지 않는다. 장애 시 ok=False와 detail을 반환한다."""
        ...
