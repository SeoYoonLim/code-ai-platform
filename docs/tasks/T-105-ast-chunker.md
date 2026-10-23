# T-105: `TreeSitterChunker` — CodeChunker 실제 어댑터 (+ CodeChunk 분리 반영)

- **담당:** Codex
- **작성:** Claude · 2026-10-23
- **상태:** ready
- **우선순위:** P0 — T-107(`IndexingService`)이 이 위에서 동작한다
- **브랜치:** `task/T-105-ast-chunker`
- **관련 문서:** [ADR-0004](../adr/0004-chunk-text-split-and-id.md) (이번 모델 변경), [S-02 보고서](../architecture/spikes/S-02-report.md) (**매핑표·결정·측정은 이 보고서가 정답이다. 다시 조사하지 않는다**), [data-flow §3](../architecture/02-data-flow.md), 인터페이스 [chunker.py](../../services/ai-engine/src/engine/core/interfaces/chunker.py), 모델 [code.py](../../services/ai-engine/src/engine/core/models/code.py)

## 목표
`CodeChunker` Protocol을 tree-sitter로 구현한다(Python / TypeScript·TSX / JavaScript). 동시에 Claude가 확정한 **`CodeChunk.text` → `raw_code` + `search_text` 분리**와 **새 `chunk_id` 규칙**을 어댑터·테스트 전체에 반영해 CI를 다시 green으로 만든다.

## 이미 확정된 것 (Claude가 이 브랜치에 커밋해 둠 — 수정 금지)
- `CodeChunk`: `text` 필드 삭제 → `raw_code`(원본 그대로), `search_text`(헤더 + 렌더링 코드). 필드 순서는 `…, symbol, raw_code, search_text, start_line, …`.
- `chunk_id = "{project_id}:{path}::{symbol}@{start_line}-{end_line}"`.
- MODULE의 `raw_code`는 흩어진 span의 줄만 이어 붙이고 `metadata["spans"]`에 `"1-5,300-310"` 형식으로 남긴다.
- `search_text` 형식 (data-flow §3.1):
  ```
  # path: src/app/services/user.py
  # symbol: UserService.create (method, python)
  <렌더링된 코드>
  ```
- API 계약(`engine.v1.yaml`)의 `CodeChunk.text`는 **건드리지 않는다** (T-109에서 `raw_code`를 매핑).

## 환경 사실 (S-02 실측 — 다시 조사하지 않는다)
| 항목 | 값 |
|---|---|
| tree-sitter | **`>=0.25,<0.26` 고정됨.** 0.26.0은 `node.start_point` 접근 시 segfault (CPython 3.12·3.14 재현). 이 범위를 바꾸지 않는다 |
| 문법 | `tree-sitter-language-pack` 1.22.1은 **문법을 처음 쓸 때 다운로드한다.** 캐시는 `C:\Users\seoyo\AppData\Local\tree-sitter-language-pack\v1.22.1\libs`에 이미 있다 (python, typescript, tsx, javascript). **`chunk()` 안에서 다운로드가 일어나면 안 된다** (순수 함수·I/O 금지) |
| 범위 계산 | `start_point`/`end_point` 대신 **byte offset + LF 시작 위치 테이블(bisect)** 로 줄 번호를 계산한 스파이크 방식을 그대로 쓴다 (`scripts/spikes/s02_chunk_core.py`가 참고 구현. **import하지 말고 포팅**한다 — `scripts/`는 프로덕션 의존 대상이 아니다) |
| 에러 판정 | `root.has_error` (ERROR뿐 아니라 MISSING도 포함). 정상 심볼이 앞에 있어도 부분 추출하지 않고 **파일 전체를 WINDOW로 폴백** |
| TSX | 도메인 `Language.TYPESCRIPT`, 문법은 파일 **확장자** `.tsx`면 `tsx`, `.ts`면 `typescript`, `.js/.jsx/.mjs/.cjs`는 `javascript` |
| 윈도우 | 120줄 윈도우, 20줄 overlap, 심볼이 200줄 초과면 WINDOW 분할 (S-02 §4: 200→L1-120/L101-200 …) |

## 대상 파일
- 구현: `services/ai-engine/src/engine/adapters/parsing/` — `language_map.py`(확장자→`Language`, 문법 이름), `treesitter_chunker.py`(조립), 필요하면 `extract.py`(노드→청크 후보), `render.py`(`search_text`·클래스 시그니처 렌더링), `window.py`. **파일당 300줄 이하**라서 나누는 것을 전제로 한다.
- 모델 변경 반영(전부 이 카드 범위): `adapters/vectorstore/chroma_codec.py`, `chroma.py`, `in_memory.py`, `tests/conftest.py`(`chunk_factory`), `tests/conformance/vector_store_suite.py`, `tests/unit/test_core_smoke.py`, `tests/unit/adapters/**`, `tests/integration/test_chroma_live.py`
- 새 테스트: `tests/conformance/chunker_suite.py`(+ `tests/unit/adapters/parsing/test_treesitter_chunker.py`가 상속), 단위 테스트
- fixture: S-02의 `tests/fixtures/chunking/**`(이미 커밋됨)를 그대로 쓴다. `*.expected.json`은 **S-02 형식(kind·symbol·start_line·end_line)** 이므로 `chunk_id`·`raw_code`·`search_text` 기대값은 새 golden 파일로 추가한다(기존 파일을 출력에 맞춰 재생성하지 않는다)

## 모델 변경 반영 규칙 (Chroma)
- Chroma `documents` = `search_text`, 메타데이터 키 `raw_code` = `raw_code` (**예약 필드**: 사용자 메타데이터는 이미 `m_` 접두사라 충돌하지 않는다). 실서버에서 메타데이터 값 5 MB까지 왕복 정상 확인됨.
- `decode`는 `raw_code`를 메타데이터에서, `search_text`를 document에서 복원한다. `raw_code`가 없거나 str이 아니면 `VectorStoreError` (KeyError가 새지 않게 — 감사에서 지적된 문제).
- `encode`/`decode` 왕복 테스트에 `raw_code`와 `search_text`가 서로 다른 값인 케이스(클래스, MODULE)를 넣는다.
- Codex는 Docker를 쓰지 못하므로 live 테스트는 `ENGINE_IT_CHROMA_URL`이 없으면 skip하도록 작성하고, 실행은 Claude가 한다.

## 수락 기준
첫 줄은 항상 적합성 스위트다.
- [ ] `ChunkerConformance` 스위트(`tests/conformance/chunker_suite.py`)를 새로 만들고 `TreeSitterChunker`가 통과한다. 스위트는 언어 무관 규칙만 검사한다: 결정성(두 번 실행해 `chunk_id` 목록 동일), **한 호출 내 `chunk_id` 중복 0**, 단일 span 청크의 `raw_code == "".join(lines[start-1:end])`(원본 줄 그대로, CRLF 포함), 빈 파일/주석만 있는 파일/끝 개행 없는 파일, 문법 오류 → 전체 WINDOW, 미지원 언어 → WINDOW(예외 아님), `supports()` 정확성, 원본 줄 100% 커버(청크 span 합집합).
- [ ] S-02 fixture 8개: kind/symbol/start/end가 `*.expected.json`과 일치, 손상 입력 5개는 전체 WINDOW.
- [ ] 경계: UTF-8 멀티바이트(`한글😀`)에서 `raw_code`가 원본과 같다 / CRLF·탭 / 200·201·220·221·251줄 심볼의 WINDOW 분할(overlap 정확히 20줄).
- [ ] **ID 충돌 0:** getter/setter, 오버로드, 같은 이름 중첩 정의를 가진 fixture를 새로 만들어(직접 작성) 충돌이 없음을 보인다. S-02에서 httpx 12건·zod 1건이던 충돌이 `@{start}-{end}` 덕분에 0이 되는지 **httpx·zod 실측으로 확인**해 PR 본문에 숫자를 쓴다 (`.data/spike-repos/*` 사용, clone 금지).
- [ ] 클래스 `search_text`는 메서드 본문이 `...`로 대체되고 데코레이터·필드·시그니처는 남는다 (S-02 §2 결정 5). 클래스 `raw_code`는 원본 그대로.
- [ ] MODULE: 복수 span이면 `metadata["spans"]`가 맞고 `raw_code`는 그 span들의 줄만 포함한다 (최상위 호출 사이의 함수 본문이 끼지 않는다).
- [ ] 문법은 **생성자에서** 한 번 로드한다(`parser_factory` 주입 가능, 기본은 `tree_sitter_language_pack.get_parser`). 로드 실패 시 `ParseError`(메시지에 언어 이름). `chunk()`는 네트워크·파일 I/O를 하지 않는다 — 테스트에서 `parser_factory`를 호출 횟수 세는 가짜로 바꿔 `chunk()` 중 추가 호출이 없음을 확인한다.
- [ ] 성능: httpx·zod에서 파일별 median의 p95 < 50 ms / 1k LOC (S-02와 같은 방식, 결과를 PR 본문에 기록).
- [ ] 모델 변경 반영 후 **기존 테스트가 전부 통과**한다 (`text=` 사용처 0). Chroma codec 왕복·잘못된 메타데이터 단위 테스트 추가.
- [ ] `make check` 통과 (ruff, mypy strict, import-linter 5개, 파일당 300줄).

## 결정하지 않는 것 (측정만 하고 정책은 건드리지 않는다)
- MODULE이 200줄을 넘는 문제(zod 최대 4,692줄), TS `interface/type/enum`을 MODULE에서 분리할지, 문법 오류 4개 zod 파일(`schemas.ts`, `checks.ts` 등)의 부분 추출 — **S-02 §3·§7의 정책(MODULE 유지, 오류 파일은 전체 WINDOW)을 그대로 구현**하고, 구현 중 새로 알게 된 수치만 PR 본문에 적는다. 정책 변경이 필요하다고 판단되면 "제안" 절에만 쓴다.
- `max_chunk_lines`(200)·윈도우 크기는 생성자 인자(기본값 200 / 120 / 20)로 두고 `Settings`에는 연결하지 않는다 (T-109 DI에서 연결).

## 금지 사항
- **`.git`에 쓰지 않는다.** `git add/commit/push/checkout/branch/stash/reset` 금지. 파일만 수정하고 `git status --short`로 보고한다. 커밋은 Claude가 리뷰 후 한다.
- `contracts/`, `core/interfaces/`, `core/models/`, `core/errors.py`, `pyproject.toml`, `uv.lock`, `.gitattributes` 수정 금지. 모델·인터페이스가 부족하면 "제안" 절에 쓴다 (Claude가 판단).
- 문법을 `chunk()` 안에서 다운로드하거나, 캐시 경로를 임의로 바꾸거나, 새 패키지를 설치하지 않는다. 문법 로드가 실패하면 시도한 것과 오류 메시지를 그대로 보고하고 멈춘다 (S-02에서 대체 캐시 시험 중 자동 다운로드 경로를 잘못 호출한 전례가 있다).
- `node.start_point`/`end_point` 접근 금지 (위 segfault). byte offset만 쓴다.
- 외부 저장소 코드를 fixture로 복사하지 않는다.
- 테스트·함수 이름은 파일 간 고유하게 (pytest 수집 충돌 방지). pytest는 `--basetemp=.data/…`로 실행.

## 수정 허용 범위 밖에서 발견한 문제는
수정하지 말고 결과 절의 "제안"에 적는다. 특히 S-02 §7이 제기한 항목(삭제 후 재삽입의 위험, 해시·세대 관리)은 T-107 설계에서 다루므로 여기서 구현하지 않는다.

## 결과
<Codex 기록: 변경 파일, 실행한 명령과 실제 출력, 수락 기준 항목별 충족 여부, 미실행 항목, 제안>
