# S-02 (Spike): tree-sitter Python/TypeScript AST 청킹 검증

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-001과 무관하게 착수 가능)
- **타임박스:** 1.5일
- **산출물:** `scripts/spikes/s02_chunk_probe.py`, `docs/architecture/spikes/S-02-report.md`, 테스트 fixture
- **후속:** 결과가 M1 **T-014 (`treesitter_chunker.py`)** 명세의 입력이 된다

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

| 지표 | 목표 (T-014 수락 기준 후보) |
|---|---|
| 파일당 파싱 + 청킹 시간 | 1k LOC당 < 50ms |
| 청크 크기 분포 (줄 수 p50/p95/max) | p95 ≤ 120줄이면 window 분할 기준 200줄 유지 |
| window 폴백 비율 (파싱 실패 또는 200줄 초과) | < 5% |
| 줄 범위 정확도 | 무작위 청크 30개를 원본 `lines[start-1:end]`와 대조해 100% 일치 |
| 커버리지 | (청크가 덮는 줄 수 + 공백/주석 줄) / 전체 줄 ≥ 99%. 누락 줄 없음 |
| 문법 오류 내성 | 일부러 깨뜨린 파일 5개: ERROR 노드가 있어도 정상 심볼은 추출되는지, 아니면 전체 window 폴백인지 |

### 4. 임베딩 헤더 미리보기
data-flow §3.1의 헤더 형식(`# path:` / `# symbol:`)으로 청크 5개를 출력해 리포트에 싣는다.

## 산출물 명세
- `scripts/spikes/s02_chunk_probe.py <repo_path> --lang python|typescript [--json out.json]`: 위 지표 출력
- `docs/architecture/spikes/S-02-report.md`: 매핑표(확정안), 결정 항목별 권고와 근거, 측정 결과, T-014 수락 기준 제안
- `services/ai-engine/tests/fixtures/chunking/`: T-014 테스트용 fixture
  - `python/basic.py`, `python/decorators_nested.py`, `python/syntax_error.py`
  - `typescript/basic.ts`, `typescript/exports_arrows.ts`, `typescript/component.tsx`, `typescript/syntax_error.ts`
  - 각 fixture의 기대 청크 목록 `*.expected.json` (`kind`, `symbol`, `start_line`, `end_line`)

## 수락 기준
- [ ] 매핑표의 모든 "?" 항목과 결정 항목 7개에 권고안과 근거가 있음
- [ ] 두 저장소 측정 결과가 표로 정리됨 (실행 명령과 커밋 SHA 포함)
- [ ] fixture 7개와 expected.json이 있고, probe 스크립트 출력이 expected와 일치 (스크립트에 `--check` 모드)
- [ ] 줄 범위 정확도 100%, 누락 줄 0
- [ ] 리포트 마지막에 T-014 수락 기준 초안
- [ ] `ruff check scripts/spikes` 통과, 파일당 300줄 이하

## 금지 사항
- `core/interfaces/chunker.py`, `core/models/code.py` 수정 금지. 모델이 부족하면 리포트의 "인터페이스 변경 제안" 절에 쓴다 (Claude가 판단)
- 외부 저장소 코드를 fixture로 복사하지 않는다 (라이선스). fixture는 직접 작성한다

## 결과
<Codex 기록>
