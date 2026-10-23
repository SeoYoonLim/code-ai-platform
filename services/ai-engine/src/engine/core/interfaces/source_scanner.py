from collections.abc import AsyncIterator, Sequence
from typing import Protocol, runtime_checkable

from engine.core.models import ScanItem


@runtime_checkable
class SourceScanner(Protocol):
    """저장소 디렉터리 → 색인 대상 파일 스트림. 파일 시스템 I/O는 이 포트 뒤에만 둔다.

    구현 규칙:
    - 파일을 하나씩 yield 한다 (전체를 메모리에 모으지 않는다). 순서는 path 오름차순으로 결정적이다.
    - `SourceFile.path`는 root 기준 POSIX 상대 경로, `content_hash`는 content(UTF-8)의 sha256 hex.
      CRLF 등 줄바꿈은 바꾸지 않고 그대로 읽는다 (청크 raw_code가 원본과 같아야 한다).
    - 색인하지 않는 파일은 `SkippedFile(path, reason)`로 알린다: 크기 초과(`too_large`),
      바이너리·UTF-8 디코딩 불가(`binary`), 읽기 실패(`unreadable`),
      glob에 의해 제외(`excluded`), 지원 언어가 아님(`unsupported`).
      기본 제외 대상(.git, node_modules, 가상환경, 빌드 산출물)은 알리지 않고 건너뛴다.
    - .gitignore를 존중한다. include_globs가 비어 있으면 전체, 있으면 하나라도 맞는 파일만.
    - `SourceFile.language`는 생성자에 주입된 판별 함수의 결과를 쓴다 (어댑터끼리 import 금지).
    - root가 없거나 디렉터리가 아니면 첫 `__anext__`에서
      `EngineError(detail={"reason": "source_root_invalid"})`.
    """

    def scan(
        self,
        root: str,
        *,
        include_globs: Sequence[str] = (),
        exclude_globs: Sequence[str] = (),
        max_file_bytes: int = 512 * 1024,
    ) -> AsyncIterator[ScanItem]: ...
