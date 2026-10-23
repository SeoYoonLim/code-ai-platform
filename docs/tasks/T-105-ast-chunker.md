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
구현 완료. 단, 저장소 전체 `make check`는 아래 기존 Ruff 문제와 git 실행 테스트 제외 때문에 미충족이다.
보호된 파일, 문법 캐시, 외부 저장소는 수정하지 않았다. 설치·다운로드·Docker·git 변경 명령을 실행하지 않았다.

### 변경 파일
- `src/engine/adapters/parsing/` (`services/ai-engine/` 기준):
  `language_map.py`, `treesitter_chunker.py`, 새 `extract.py`, 새 `fake.py`.
- `src/engine/adapters/vectorstore/chroma_codec.py`, `chroma.py`.
  `in_memory.py`는 CodeChunk를 그대로 보관하므로 수정 불필요.
- `tests/conftest.py`, `tests/conformance/vector_store_suite.py`,
  `tests/unit/adapters/test_fakes_together.py`.
- 새 `tests/conformance/chunker_suite.py`.
- 새 `tests/unit/adapters/parsing/test_treesitter_chunker.py`,
  `test_t105_fake_chunker.py`, `measure_t105.py`.
- 새 `tests/unit/adapters/vectorstore/test_t105_codec.py`.
- 새 `tests/fixtures/chunking/t105-collisions.py`, `t105-collisions.ts`,
  `t105-render.golden.json` (직접 작성한 기대값; 기존 expected 파일 변경 없음).
- 이 작업 카드의 결과 절.

### 수락 기준별 판정
| 번호 | 판정 | 증거 |
|---|---|---|
| 1 적합성 | 충족 | ChunkerConformance 상속 실행: 결정성, ID 중복, 원문, 빈/주석/끝 개행 없음, supports, 폴백. fixture 및 저장소 전체 span 감사에서 누락 0 |
| 2 S-02 fixture | 충족 | 기존 expected 8/8 일치, 손상 입력 5/5 전체 WINDOW |
| 3 경계 | 충족 | 한글😀 UTF-8, CRLF·탭, U+2028, 200/201/220/221/251줄과 정확히 20줄 overlap 단언 |
| 4 ID 충돌 | 충족 | 직접 작성한 getter/setter·TS overload·동명 중첩 클래스 fixture, httpx/zod 충돌 각각 0 |
| 5 클래스 | 충족 | Python decorator/필드/서명·중첩 클래스와 TS `{ ... }` 렌더링 검사; raw_code 원문 보존 |
| 6 MODULE | 충족 | `spans=1-1,7-7`, 함수/클래스 본문 제외 원문 조립; golden ID/raw/search 비교 |
| 7 문법 수명 | 충족 | 생성자 factory 4회, chunk 중 추가 호출 0; I/O 차단·캐시 부재 시 get_parser 호출 0·ParseError 언어명 검사 |
| 8 성능 | 충족 | 아래 실제 저장소 최종 측정: 두 저장소 p95 < 50 ms/1k LOC |
| 9 모델 전파 | 충족(실행 제한 명시) | 실행 가능한 기존 테스트와 신규 테스트 457 passed; Chroma CLASS/MODULE 원문·검색문 왕복, 예약 키 분리, raw 누락/잘못된 타입 검사. CodeChunk의 옛 text 접근 제거 |
| 10 make check | 미충족 | src mypy strict·import 5계약·범위 Ruff·300줄 검사 통과. 전체 Ruff는 기존 fixture/임시 파일에서 실패. git 변경 테스트 미실행 |

### 실행 명령과 실제 출력
모든 Python 실행은 `.venv/Scripts/python.exe`를 사용했다. 아래 `PY`는 그 실행 파일의 표기상 약칭이다.
연속 명령의 마지막 종료 코드로 앞 단계 실패를 숨기지 않고 각 결과를 별도로 기록했다.

1. 기본 캐시 및 실제 파서 probe (종료 0):
   `PY -c "from tree_sitter_language_pack import downloaded_languages, get_parser; print(downloaded_languages()); [(print(n, get_parser(n).parse(b'x=1').root_node.has_error)) for n in ('python','typescript','tsx','javascript')]"`
   ```text
   ['javascript', 'python', 'tsx', 'typescript']
   python False
   typescript False
   tsx False
   javascript False
   ```
   Point 속성 접근 없음. 생성자 기본 loader도 다운로드 전 캐시 존재를 확인한다.

2. `PY -m pytest --ignore=scripts/tests/test_check_file_lines.py --basetemp=.data/pt-t105-run -q`
   (종료 0): `457 passed, 37 deselected, 2 warnings in 14.99s`.
   경고: 기존 chromadb asyncio deprecation, pytest cache 디렉터리 생성 실패.
   `scripts/tests/test_check_file_lines.py`는 내부에서 `git init/add`를 실행하므로 미실행.
   해당 테스트를 포함한 전체 pytest 성공을 주장하지 않는다.

3. `PY -m pytest services/ai-engine/tests/integration/test_chroma_live.py -m integration --basetemp=.data/pt-t105-run -q`
   (종료 0): `28 skipped, 2 warnings in 0.82s`.
   `ENGINE_IT_CHROMA_URL` 미설정에 따른 기존 skip을 실제 확인했다. 실제 서버 왕복·재시작은 미실행.

4. `PY -m mypy --strict packages/py-common/src services/ai-engine/src services/backend/src`
   (종료 0): `Success: no issues found in 71 source files`.

5. `.venv/Scripts/lint-imports.exe` (종료 0):
   `Analyzed 99 files, 128 dependencies.` / `Contracts: 5 kept, 0 broken.`

6. `PY -m openapi_spec_validator contracts/openapi/engine.v1.yaml` 및
   `PY -m openapi_spec_validator contracts/openapi/backend.v1.yaml` (각 종료 0):
   `contracts/openapi/engine.v1.yaml: OK`, `contracts/openapi/backend.v1.yaml: OK`.

7. `PY -m ruff check services/ai-engine/src services/ai-engine/tests --exclude services/ai-engine/tests/fixtures`
   (종료 0): `All checks passed!`.
   같은 범위 `PY -m ruff format --check ...` (종료 0): `83 files already formatted`.
   새 충돌 Python fixture도 별도 `ruff check` 통과; 동명 선언의 F811은 의도 설명을 붙인 noqa로 한정했다.

8. 전체 레시피의 Ruff 명령도 실제 실행했다:
   `PY -m ruff check .` (종료 1): `Found 609 errors.`
   예: `.pytest-t104/test_untracked_ignored0/untracked.py`의 B018/F821,
   기존 chunking fixture의 의도적인 문법 오류/미정의 decorator/탭.
   `PY -m ruff format --check .` (종료 2):
   `3 files would be reformatted, 234 files already formatted`; 기존 손상 fixture 파싱 실패도 포함.
   출력 보존: `.data/t105-ruff-full.txt`, `.data/t105-format-full.txt`.
   보호된 설정이나 기존 golden 입력을 바꾸어 숨기지 않았다.

9. `make` 래퍼 자체는 미실행. Makefile의 검증 명령을 위와 같이 직접 실행했다.
   기존 line checker는 `git ls-files`를 호출하므로 별도 읽기 전용 pathlib 순회로 검사했다.
   services/packages/scripts/apps의 생성물 제외 py/ts/tsx/dart에서
   `source line check: 125 files; 0 violations []` (종료 0).
   최종 재검사: `source line check: 127 files; 0 violations []` (종료 0), 작업 카드 188줄.

### httpx / zod 실측
재현 명령 (실제로 실행, 종료 0):
`PY services/ai-engine/tests/unit/adapters/parsing/measure_t105.py`
외부 저장소는 `.data/spike-repos/httpx`, `.data/spike-repos/zod`를 읽기만 했다.
파일별 chunk() 3회 median을 1k LOC로 정규화한 nearest-rank p95다.
파서 로드·파일 읽기·원문/ID 감사는 타이머 밖이며 chunk()의 최종 ID/헤더 생성은 포함한다.

```text
httpx: files=60, loc=17751, chunks=1234, id_collisions=0, missing_lines=0,
       p95_ms_1k_loc=9.34999980017892, whole_window_files=0, max_module_lines=203
zod:   files=477, loc=100043, chunks=1939, id_collisions=0, missing_lines=0,
       p95_ms_1k_loc=10.57391302205413, whole_window_files=4, max_module_lines=4692
```

모든 파일에서 반복 출력 동일, 모든 청크의 raw_code와 선언된 span 원문 일치를 단언했다.
S-02의 기존 ID 충돌 httpx 12 / zod 1이 새 ID에서 각각 0이다.
새 측정 스크립트는 위 명령으로 실행했으며, 추가 임시 probe `.data/t105-measure.py`도 종료 0이었다.

### 미실행·불확실성과 제안
- 미실행: 실제 Chroma/live restart, Docker/GPU, git 변경 테스트, make 래퍼,
  Linux/다른 Python 조합의 native parser 확인. 다운로드·설치는 시도하지 않았다.
- 전체 Ruff가 기존 fixture와 임시 폴더를 검사하는 현재 설정에는 동의하지 않는다.
  Claude가 보호된 설정에서 파서 fixture와 임시 출력 제외 범위를 명시하는 것을 제안한다.
- MODULE 4,692줄과 문법 오류 폴백 4파일은 유지했다. 200줄 심볼 제한만으로
  임베딩 payload 상한이 보장되지 않으므로 byte/token 예산·타입/callback 분리는 후속 설계 제안이다.
- 줄 삽입으로 바뀌는 ID와 삭제/재삽입의 세대 관리 문제는 T-107에서 다룬다. 이번 범위에 구현하지 않았다.
