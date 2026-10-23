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

    chunk_id: "{project_id}:{path}::{symbol}@{start_line}-{end_line}" (ADR-0004). 같은 파일 안에서
        동명 심볼(getter/setter, 오버로드)이 충돌하지 않는다. 줄 위치가 바뀌면 ID도 바뀌므로 변경된 파일의
        청크는 항상 path 단위로 삭제 후 재삽입한다. 결정적이어야 한다 (같은 입력 → 같은 ID).
    symbol: 정규화된 심볼 경로 (예: "UserService.create"). WINDOW 청크는 "L{start}-{end}".
    raw_code: 원본 소스 그대로. 인용·diff·화면 표시용. 단일 span이면 파일의
        `lines[start_line-1:end_line]` 와 문자 그대로 같다. MODULE은 흩어진 span들의 줄만 이어 붙인다
        (span 목록은 metadata["spans"], 예: "1-5,300-310").
    search_text: 임베딩 입력이자 검색 결과 요약. 헤더(`# path:`/`# symbol:`)와 렌더링된 코드
        (CLASS는 메서드 본문을 `...`로 생략)로 구성된다. 렌더링 정책이 바뀌면 같은 raw_code도 다시 임베딩한다.
    start_line/end_line: 1-based, 양 끝 포함. 줄 구분은 LF만 쓴다
        (CRLF 파일의 CR은 줄 끝 문자로 남기고 줄 수에 영향 없음).
    """

    chunk_id: str
    project_id: str
    path: str
    language: Language
    kind: ChunkKind
    symbol: str
    raw_code: str
    search_text: str
    start_line: int
    end_line: int
    content_hash: str
    commit_sha: str | None = None
    metadata: dict[str, str | int | float | bool] = field(default_factory=dict)
