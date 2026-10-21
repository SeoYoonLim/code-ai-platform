"""코드 파싱/청킹 도메인 모델."""

from dataclasses import dataclass, field
from enum import StrEnum


class Language(StrEnum):
    PYTHON = "python"
    TYPESCRIPT = "typescript"
    JAVASCRIPT = "javascript"
    JAVA = "java"
    KOTLIN = "kotlin"
    GO = "go"
    RUST = "rust"
    DART = "dart"
    CPP = "cpp"
    UNKNOWN = "unknown"


class ChunkKind(StrEnum):
    MODULE = "module"
    CLASS = "class"
    FUNCTION = "function"
    METHOD = "method"
    WINDOW = "window"  # 파서 폴백: 고정 줄 수 슬라이딩 윈도우


@dataclass(frozen=True, slots=True)
class SourceFile:
    """색인 대상 파일 1개.

    path: 저장소 루트 기준 POSIX 상대 경로 (예: "src/app/main.py")
    content_hash: content의 sha256 hex. 증분 색인 비교 키.
    """

    path: str
    language: Language
    content: str
    content_hash: str


@dataclass(frozen=True, slots=True)
class CodeChunk:
    """벡터화 단위.

    chunk_id: "{project_id}:{path}::{symbol}" 형태의 안정적 ID. 내용이 바뀌어도 동일 심볼이면 유지된다.
    symbol: 정규화된 심볼 경로 (예: "UserService.create"). WINDOW 청크는 "L{start}-{end}".
    start_line/end_line: 1-based, 양 끝 포함.
    """

    chunk_id: str
    project_id: str
    path: str
    language: Language
    kind: ChunkKind
    symbol: str
    text: str
    start_line: int
    end_line: int
    content_hash: str
    commit_sha: str | None = None
    metadata: dict[str, str | int | float | bool] = field(default_factory=dict)
