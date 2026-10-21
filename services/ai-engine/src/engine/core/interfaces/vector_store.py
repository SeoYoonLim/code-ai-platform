from collections.abc import Sequence
from typing import Protocol, runtime_checkable

from engine.core.models import CodeChunk, MetadataFilter, RetrievedChunk


@runtime_checkable
class VectorStore(Protocol):
    """코드 청크 벡터 저장소. 컬렉션 = 프로젝트 1개 (이름: "proj_{project_id}").

    구현 규칙:
    - upsert는 chunk_id 기준 멱등이다.
    - len(chunks) != len(embeddings) 이면 ValueError.
    - 존재하지 않는 컬렉션 조회/삭제는 CollectionNotFound, 그 외 백엔드 오류는 VectorStoreError.
    - query 결과는 score 내림차순, 최대 top_k개.
    """

    async def ensure_collection(self, collection: str, *, dimension: int) -> None:
        """없으면 생성한다. 기존 컬렉션의 dimension이 다르면 VectorStoreError."""
        ...

    async def upsert(
        self,
        collection: str,
        chunks: Sequence[CodeChunk],
        embeddings: Sequence[Sequence[float]],
    ) -> None: ...

    async def query(
        self,
        collection: str,
        embedding: Sequence[float],
        *,
        top_k: int = 8,
        where: MetadataFilter | None = None,
    ) -> list[RetrievedChunk]: ...

    async def delete_by_paths(self, collection: str, paths: Sequence[str]) -> int:
        """해당 파일 경로의 청크를 모두 삭제하고 삭제 개수를 반환한다 (증분 색인용)."""
        ...

    async def get_file_hashes(self, collection: str) -> dict[str, str]:
        """색인된 {path: content_hash} 매핑. 증분 색인 시 변경 파일 판별에 사용한다."""
        ...

    async def drop_collection(self, collection: str) -> None: ...
