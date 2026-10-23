"""코드베이스 색인 유스케이스. 설계: docs/architecture/02-data-flow.md §3, ADR-0005, 카드 T-107.

서비스는 포트(core.interfaces)만 안다. 파일 시스템·tree-sitter·Ollama·Chroma는 main/container가 주입한다.
"""

from collections.abc import Callable
from datetime import datetime

from engine.core.interfaces import CodeChunker, Embedder, SourceScanner, VectorStore
from engine.core.models import IndexJob, IndexRequest, JobStatus

CHUNK_POLICY_VERSION = "chunk-v1"


def collection_for(project_id: str) -> str:
    """프로젝트 → 컬렉션 이름 (data-flow §3.2)."""
    return f"proj_{project_id}"


class IndexingService:
    """색인 잡 생성·실행·취소·조회. 잡 상태는 프로세스 메모리에만 둔다 (영속화는 Backend 몫).

    `run`은 잡 하나를 끝까지 실행하는 코루틴이다. 호출측(API 백그라운드 태스크, CLI)이 await 하거나
    태스크로 띄운다. 서비스는 스스로 태스크를 만들지 않는다 (테스트 결정성, 종료 시 정리 책임 명확화).
    """

    def __init__(
        self,
        scanner: SourceScanner,
        chunker: CodeChunker,
        embedder: Embedder,
        store: VectorStore,
        *,
        policy_version: str = CHUNK_POLICY_VERSION,
        clock: Callable[[], datetime] | None = None,
        job_ids: Callable[[], str] | None = None,
        retention: int = 200,
    ) -> None:
        raise NotImplementedError

    async def start(self, request: IndexRequest) -> IndexJob:
        """QUEUED 잡을 만든다.

        같은 project_id의 QUEUED/RUNNING 잡이 있으면 JobConflict(detail={"job_id": ...}).
        """
        raise NotImplementedError

    async def run(self, job_id: str) -> IndexJob:
        """잡을 실행하고 종료 상태의 스냅샷을 반환한다. 알 수 없는 job_id면 KeyError."""
        raise NotImplementedError

    async def get(self, job_id: str) -> IndexJob | None:
        raise NotImplementedError

    async def list_jobs(
        self, *, project_id: str | None = None, status: JobStatus | None = None, limit: int = 50
    ) -> list[IndexJob]:
        """created_at 내림차순."""
        raise NotImplementedError

    async def cancel(self, job_id: str) -> IndexJob | None:
        """QUEUED/RUNNING이면 취소를 요청한다 (파일 경계에서 중단).

        종료된 잡이면 그대로 반환 (멱등). 없으면 None.
        """
        raise NotImplementedError
