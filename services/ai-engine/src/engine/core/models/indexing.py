"""색인 잡 도메인 모델 (data-flow §3, engine.v1.yaml IndexJob/IndexStats/JobProgress와 대응)."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

from engine.core.models.code import SourceFile


class IndexMode(StrEnum):
    INCREMENTAL = "incremental"
    FULL = "full"


class JobStatus(StrEnum):
    QUEUED = "queued"
    RUNNING = "running"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    CANCELED = "canceled"

    @property
    def terminal(self) -> bool:
        return self in {JobStatus.SUCCEEDED, JobStatus.FAILED, JobStatus.CANCELED}


class IndexPhase(StrEnum):
    SCANNING = "scanning"
    CHUNKING = "chunking"
    EMBEDDING = "embedding"
    UPSERTING = "upserting"


@dataclass(frozen=True, slots=True)
class IndexRequest:
    """root: 엔진이 읽는 저장소 루트(절대 경로). 허용 경로 검증은 API 계층(T-109)이 한다."""

    project_id: str
    root: str
    mode: IndexMode = IndexMode.INCREMENTAL
    commit_sha: str | None = None
    include_globs: tuple[str, ...] = ()
    exclude_globs: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class IndexStats:
    files_scanned: int = 0
    files_changed: int = 0
    files_deleted: int = 0
    files_skipped: int = 0
    chunks_upserted: int = 0


@dataclass(frozen=True, slots=True)
class JobProgress:
    current: int
    total: int
    phase: IndexPhase | None = None


@dataclass(frozen=True, slots=True)
class JobError:
    """실패 요약. code는 EngineError.code. 상세 Problem 변환은 API 계층의 몫."""

    code: str
    message: str
    retryable: bool = False


@dataclass(frozen=True, slots=True)
class IndexJob:
    """불변 스냅샷. 서비스는 상태가 바뀔 때마다 새 인스턴스로 교체한다."""

    job_id: str
    request: IndexRequest
    status: JobStatus
    created_at: datetime
    progress: JobProgress | None = None
    stats: IndexStats | None = None
    error: JobError | None = None
    started_at: datetime | None = None
    finished_at: datetime | None = None


@dataclass(frozen=True, slots=True)
class SkippedFile:
    """색인에서 제외된 파일.

    reason: too_large | binary | unreadable | excluded | unsupported (스캐너),
    parse_error | too_many_chunks (서비스).
    """

    path: str
    reason: str


ScanItem = SourceFile | SkippedFile
