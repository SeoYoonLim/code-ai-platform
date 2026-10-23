from collections.abc import Sequence
from typing import Protocol, runtime_checkable

from engine.core.models import CodeChunk, MetadataFilter, RetrievedChunk


@runtime_checkable
class VectorStore(Protocol):
    """코드 청크 벡터 저장소. 컬렉션 = 프로젝트 1개 (이름: "proj_{project_id}").

    구현 규칙:
    - upsert는 chunk_id 기준 멱등이다.
    - 파일 단위 갱신은 upsert+delete가 아니라 replace_file을 쓴다.
    - len(chunks) != len(embeddings) 이면 ValueError.
    - 존재하지 않는 컬렉션 조회/삭제는 CollectionNotFound, 그 외 백엔드 오류는 VectorStoreError.
    - query 결과는 score 내림차순, 최대 top_k개.
    """

    async def ensure_collection(self, collection: str, *, dimension: int) -> None:
        """없으면 생성한다. 기존 컬렉션의 dimension이 다르면
        `VectorStoreError(detail={"reason": "dimension_mismatch"})`.

        다른 이유의 VectorStoreError(서버 장애 등)와 구분할 수 있어야 한다.
        호출측은 이 사유일 때만 컬렉션을 다시 만든다.
        """
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

    async def replace_file(
        self,
        collection: str,
        path: str,
        chunks: Sequence[CodeChunk],
        embeddings: Sequence[Sequence[float]],
    ) -> None:
        """path의 청크 전체를 새 청크로 교체한다 (ADR-0005). chunks가 비면 path의 청크를 모두 지운다.

        **실패 안전성(핵심 계약):** 어느 시점에서 실패하거나 프로세스가 중단돼도
        - 교체 전 청크는 계속 검색된다 (새 청크가 일부만 보이는 상태로 검색에 노출되지 않는다).
        - `get_file_hashes`는 이 path에 대해 교체 전 해시를 돌려주거나, 이 path를 아예 돌려주지 않는다
          (= 다음 증분 색인이 이 파일을 다시 처리한다). 새 해시를 돌려주는 것은 교체가 완전히 끝난 뒤뿐이다.
        - 같은 인자로 다시 호출하면 최종 상태가 같다 (멱등).
        성공 시 이 path의 청크는 chunks뿐이다 (이전 청크 중 chunks에 없는 id는 사라진다).
        모든 chunks의 path는 인자 path와 같아야 한다 (다르면 ValueError).
        """
        ...

    async def delete_by_paths(self, collection: str, paths: Sequence[str]) -> int:
        """해당 파일 경로의 청크를 모두 삭제하고 삭제 개수를 반환한다.

        삭제된 파일 정리용이다 (변경 파일에는 replace_file).
        """
        ...

    async def get_file_hashes(self, collection: str) -> dict[str, str]:
        """색인이 **완료된** {path: content_hash}. 증분 색인 시 변경 파일 판별에 사용한다.

        교체가 끝나지 않은 path(미완료 새 청크, 서로 다른 해시의 청크가 섞인 path)는 결과에서 뺀다.
        """
        ...

    async def drop_collection(self, collection: str) -> None: ...
