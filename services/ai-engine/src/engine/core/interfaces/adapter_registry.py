from typing import Protocol, runtime_checkable

from engine.core.models import AdapterInfo, AdapterStage, AdapterTask


@runtime_checkable
class LoRAAdapterRegistry(Protocol):
    """학습된 LoRA 어댑터 메타데이터 조회 (읽기 전용).

    쓰기(승격/등록)는 ml/evaluation 파이프라인만 수행한다. Engine은 읽기만 한다.
    """

    async def list_adapters(self, *, stage: AdapterStage | None = None) -> list[AdapterInfo]: ...

    async def get(self, name: str) -> AdapterInfo:
        """없으면 AdapterNotFound."""
        ...

    async def resolve(self, task: AdapterTask) -> AdapterInfo | None:
        """task의 PRODUCTION 어댑터. 없으면 None (호출측은 base 모델로 폴백)."""
        ...
