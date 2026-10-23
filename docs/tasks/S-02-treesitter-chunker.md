# S-02 (Spike): tree-sitter Python/TypeScript AST 청킹 검증

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** in-progress (브랜치 `task/S-02-treesitter-spike`, 2026-10-23 위임)
- **타임박스:** 1.5일
- **산출물:** `scripts/spikes/s02_chunk_probe.py`, `docs/architecture/spikes/S-02-report.md`, 테스트 fixture
- **후속:** 결과가 M1 **T-105 (`treesitter_chunker.py`, 옛 이름 T-014)** 명세의 입력이 된다

## 작업 규칙 (이번 위임에서 특히 강조)
- **`.git`에 직접 쓰지 않는다.** `git add/commit/push/checkout/branch`를 실행하지 않는다 (샌드박스에서도 막혀 있다). 파일만 수정하고 끝나면 `git status --short`/`git diff --stat` 결과를 보고한다. 커밋은 Claude가 리뷰 후 한다.
- **스크립트는 실제로 실행해서 출력을 보고서에 붙인다.** "돌아갈 것"이라고 가정하지 않는다. 라이브러리 동작(노드 타입 이름, 바이트/문자 오프셋 등)은 추측하지 말고 파서를 직접 돌려 확인한다.
- **네트워크 없이 시작한다.** 측정 대상 저장소는 이미 받아 두었다 (clone 금지, 수정 금지):
  - `.data/spike-repos/httpx` — `encode/httpx` 태그 `0.28.1`, 커밋 `26d48e0634e6ee9cdc0533996db289ce4b430177` (.py 60개)
  - `.data/spike-repos/zod` — `colinhacks/zod` 태그 `v4.6.7`, 커밋 `b500a2ee95134f81d74da7911d7378dd2853d042` (.ts 477개; `node_modules`는 제외)
- 의존성은 이미 설치돼 있다: `tree-sitter 0.26.0`, `tree-sitter-language-pack 1.22.1` (`.venv`). 새 패키지를 추가하지 않는다.
- 테스트/함수 이름은 파일 간 중복 없이 고유하게 짓는다 (pytest 수집 충돌 방지).
- pytest 임시 디렉터리 권한 오류가 나면 `--basetemp`를 저장소 내 비추적 경로(`.data/`)로 지정한다.

## 목표
`CodeChunker` Protocol([chunker.py](../../services/ai-engine/src/engine/core/interfaces/chunker.py))과 data-flow §3.1 청킹 규칙이 실제 Python/TypeScript 코드에서 의도대로 동작하는지 확인한다. 구현 전에 **노드 타입 매핑**과 **경계 사례**를 확정하는 것이 목적이다.

> Spike 코드는 프로덕션 코드가 아니다. `services/` 아래에 두지 않는다. import-linter와 mypy strict는 적용되지 않지만 ruff는 통과해야 한다.

## 조사 항목

### 1. 문법 패키지
- `tree-sitter` + `tree-sitter-language-pack` (ai-engine에 이미 의존성 있음)으로 `python`, `typescript`, `tsx`, `javascript` 파서 로드
- 버전 호환성 (py-tree-sitter API: `Parser(language)`, `Query` 사용법) 확인 후 사용 버전 기록

### 2. 노드 타입 매핑표 작성 (**핵심 산출물**)

| ChunkKind | Python 후보 | TypeScript 후보 |
|---|---|---|
| function | `function_definition`, `decorated_definition` | `function_declaration`, `lexical_declaration > variable_declarator > arrow_function \| function_expression`, `generator_function_declaration` |
| class | `class_definition` | `class_declaration`, `abstract_class_declaration`, `interface_declaration`?, `type_alias_declaration`?, `enum_declaration`? |
| method | class body 안의 `function_definition` | `method_definition`, `public_field_definition` + arrow function |
| module | 위에 속하지 않는 최상위 노드 (import, 상수, `if __name__ == "__main__"`) | import, `export_statement`의 비심볼 부분, 최상위 호출 |

결정해야 할 것들 (리포트에 권고안 작성):
- [ ] decorator를 청크 범위에 포함하는가? (권고: 포함. `start_line` = 첫 decorator)
- [ ] `export default`, `export const` 래퍼: 내부 선언 기준으로 하고 export 줄을 포함하는가?
- [ ] TS `interface`/`type`/`enum`: `class` kind로 볼지, `module`에 포함할지
- [ ] 중첩 함수 (함수 안의 함수): 별도 청크인가, 부모에 포함인가 (권고: 부모에 포함)
- [ ] 클래스 청크의 "시그니처만" 표현 형식 (메서드 본문을 `...`로 대체한 텍스트 예시)
- [ ] 심볼 경로 규칙: `Outer.Inner.method`, 익명 default export → `default`
- [ ] React 컴포넌트 (`.tsx`의 `const Foo = () => <div/>`)는 function으로 처리

### 3. 측정 (실제 저장소 2개)
- Python: `encode/httpx` (태그 고정), TypeScript: `colinhacks/zod` (태그 고정). `/.data/spike-repos/`에 clone (커밋하지 않음)

| 지표 | 목표 (T-105 수락 기준 후보) |
|---|---|
| 파일당 파싱 + 청킹 시간 | 1k LOC당 < 50ms |
| 청크 크기 분포 (줄 수 p50/p95/max) | p95 ≤ 120줄이면 window 분할 기준 200줄 유지 |
| window 폴백 비율 (파싱 실패 또는 200줄 초과) | < 5% |
| 줄 범위 정확도 | 무작위 청크 30개를 원본 `lines[start-1:end]`와 대조해 100% 일치 |
| 커버리지 | (청크가 덮는 줄 수 + 공백/주석 줄) / 전체 줄 ≥ 99%. 누락 줄 없음 |
| 문법 오류 내성 | 일부러 깨뜨린 파일 5개: ERROR 노드가 있어도 정상 심볼은 추출되는지, 아니면 전체 window 폴백인지 |

### 3-1. 반드시 포함할 경계 사례 (측정 전 fixture로 먼저 확인)
- **비ASCII/이모지가 있는 줄:** tree-sitter 오프셋은 **바이트** 단위다. `start_line`/`end_line`은 줄 번호지만 `text` 슬라이싱 시 바이트↔문자 혼동이 없는지 확인한다.
- **CRLF 파일**과 **탭 들여쓰기**: 줄 수/범위가 LF 파일과 동일한가.
- **빈 파일, 주석만 있는 파일, 끝 개행 없는 파일**
- 같은 입력 → 같은 출력(순수·결정적) 확인: 두 번 실행해 `chunk_id` 목록이 동일해야 한다.
- 심볼이 200줄 초과일 때 WINDOW 분할의 overlap 규칙 (인터페이스 docstring 참조)

### 4. 임베딩 헤더 미리보기
data-flow §3.1의 헤더 형식(`# path:` / `# symbol:`)으로 청크 5개를 출력해 리포트에 싣는다.

## 산출물 명세
- `scripts/spikes/s02_chunk_probe.py <repo_path> --lang python|typescript [--json out.json]`: 위 지표 출력
- `docs/architecture/spikes/S-02-report.md`: 매핑표(확정안), 결정 항목별 권고와 근거, 측정 결과, T-105 수락 기준 제안
- `services/ai-engine/tests/fixtures/chunking/`: T-105 테스트용 fixture
  - `python/basic.py`, `python/decorators_nested.py`, `python/syntax_error.py`
  - `python/unicode_crlf.py` (비ASCII + CRLF 사례. `.gitattributes`가 줄바꿈을 바꾸지 않도록 fixture만 `-text`로 지정하는 안을 **제안만** 한다. `.gitattributes`는 수정하지 않는다)
  - `typescript/basic.ts`, `typescript/exports_arrows.ts`, `typescript/component.tsx`, `typescript/syntax_error.ts`
  - 각 fixture의 기대 청크 목록 `*.expected.json` (`kind`, `symbol`, `start_line`, `end_line`)

## 수락 기준
- [ ] 매핑표의 모든 "?" 항목과 결정 항목 7개에 권고안과 근거가 있음
- [ ] 두 저장소 측정 결과가 표로 정리됨 (실행 명령과 커밋 SHA 포함)
- [ ] fixture 8개와 expected.json이 있고, probe 스크립트 출력이 expected와 일치 (스크립트에 `--check` 모드)
- [ ] 줄 범위 정확도 100%, 누락 줄 0
- [ ] 리포트 마지막에 T-105 수락 기준 초안
- [ ] `ruff check scripts/spikes` 통과, 파일당 300줄 이하
- [ ] 보고서에 **실행 증거**(명령과 실제 출력)가 있고, 최종 응답에 `git status --short` 결과가 있음 (`.git` 쓰기 없음)
- [ ] 보고서에 "**추가 제안과 놓친 점**" 절이 있음 (아래 참조)

## 금지 사항
- `core/interfaces/chunker.py`, `core/models/code.py` 수정 금지. 모델이 부족하면 리포트의 "인터페이스 변경 제안" 절에 쓴다 (Claude가 판단)
- 외부 저장소 코드를 fixture로 복사하지 않는다 (라이선스). fixture는 직접 작성한다

## 추가 제안과 놓친 점 (Codex에게 요청)
스파이크를 하며 보게 된 것 중 우리(카드/인터페이스/data-flow §3.1)가 **놓쳤거나 틀렸거나 더 할 수 있는 것**을 보고서 마지막 절에 적는다. 예: 청킹 규칙과 `CodeChunk` 모델의 불일치, `chunk_id` 설계(결정성·충돌), 심볼 경로 규칙의 모호함, 증분 색인에 필요한 해시/범위 정보, 추가 언어(JS/Go/Java 등) 지원 비용, 성능 병목. **동의하지 않는 항목은 이유와 함께 명시**한다. 인터페이스 변경은 직접 하지 않고 제안만 한다 (Claude가 판단).

## 결과
<Codex 기록>
