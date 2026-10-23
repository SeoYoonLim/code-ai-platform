from typing import Protocol, runtime_checkable

from engine.core.models import CodeChunk, Language, SourceFile


@runtime_checkable
class CodeChunker(Protocol):
    """소스 파일 → 심볼 단위 CodeChunk 목록.

    구현 규칙:
    - 지원 언어는 함수/메서드/클래스 단위로 자른다. 클래스 청크에는 메서드 본문 대신 시그니처만 남긴다.
    - 하나의 심볼이 max_chunk_lines를 넘으면 WINDOW 청크로 분할한다 (overlap 포함).
    - 심볼에 속하지 않는 최상위 코드(import, 상수)는 MODULE 청크 1개로 묶는다.
    - 문법이 없는 언어는 UnsupportedLanguage 대신 WINDOW 청킹으로 폴백한다. 문법 오류 파일도 폴백한다.
    - 순수 함수: I/O 금지, 같은 입력에 같은 출력. 문법 로드는 생성 전(composition root)에 끝내고
      chunk() 안에서 다운로드하지 않는다.
    - raw_code는 원본 줄 그대로, search_text는 임베딩 입력이다 (CodeChunk 참조). 두 값을 섞지 않는다.
    - chunk_id는 `{project_id}:{path}::{symbol}@{start_line}-{end_line}`. 한 호출에서 ID가 중복되면 안 된다.
    - 파서가 ERROR뿐 아니라 MISSING 노드를 보고해도 파일 전체를 WINDOW로 폴백한다.
    """

    def supports(self, language: Language) -> bool: ...

    def chunk(
        self,
        file: SourceFile,
        *,
        project_id: str,
        commit_sha: str | None = None,
    ) -> list[CodeChunk]: ...
