from collections.abc import Sequence
from typing import Protocol, runtime_checkable


@runtime_checkable
class Embedder(Protocol):
    """텍스트 → 고정 차원 벡터.

    구현 규칙:
    - 반환 벡터는 L2 정규화되어야 한다 (VectorStore는 코사인 유사도를 가정).
    - 입력 순서와 출력 순서가 같아야 하며 len(output) == len(texts).
    - 내부적으로 batch_size 단위로 나눠 호출한다. 실패 시 EmbeddingError.
    - 문서(코드)와 질의에 서로 다른 prefix가 필요한 모델은 embed_documents/embed_query에서 처리한다.
    """

    @property
    def model_name(self) -> str: ...

    @property
    def dimension(self) -> int: ...

    async def embed_documents(self, texts: Sequence[str]) -> list[list[float]]: ...

    async def embed_query(self, text: str) -> list[float]: ...
