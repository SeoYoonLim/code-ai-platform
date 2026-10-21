# AGENTS.md — Codex 작업 규칙

이 저장소는 **Claude Code(아키텍트)** 와 **Codex(구현자)** 가 협업한다.
Codex는 Claude가 정의한 계약(contracts)과 인터페이스(Protocol)에 맞춰 **구현과 테스트**를 담당한다.
아키텍처 배경은 [CLAUDE.md](CLAUDE.md)를 읽는다.

---

## 1. 작업 시작 전

1. 할당된 작업 카드 `docs/tasks/T-xxx.md`를 읽는다. 카드가 없으면 작업하지 않는다.
2. 카드의 **대상 파일**, **구현할 인터페이스**, **수락 기준**, **금지 사항**을 확인한다.
3. 관련 Protocol(`services/ai-engine/src/engine/core/interfaces/`)과 OpenAPI 스펙(`contracts/openapi/`)을 읽는다.

## 2. 🚫 수정 금지 구역 (Read-only for Codex)

| 경로 | 소유자 | 변경이 필요하면 |
|---|---|---|
| `contracts/**` | Claude | 작업 카드에 `BLOCKED: contract` 메모 후 중단 |
| `services/ai-engine/src/engine/core/interfaces/**` | Claude | 동일 (`BLOCKED: interface`) |
| `services/ai-engine/src/engine/core/models/**` | Claude | 동일 |
| `services/ai-engine/src/engine/core/errors.py` | Claude | 동일 |
| `pyproject.toml`(루트)의 `[tool.importlinter]`, `[tool.mypy]`, `[tool.ruff]` | Claude | 동일 |
| `docs/adr/**`, `docs/architecture/**` | Claude | — |
| `**/generated/**`, `apps/web/src/lib/api/schema.d.ts`, `apps/mobile/packages/api_client/**` | 코드 생성기 | `make gen-clients`로만 재생성. 손으로 고치지 않는다 |

인터페이스가 불충분하다고 판단되면 **우회 구현(타입 무시, 모듈 직접 import 등)을 하지 말고** 멈춘 뒤 보고한다.

## 3. 코드 규칙

### 공통
- **파일당 300줄 이하** (빈 줄/docstring 포함). 넘으면 책임을 분리한다.
- 함수 하나 50줄 이하를 권장한다. 중첩 3단계 이하.
- 새 외부 의존성 추가 시 PR 설명에 **사유와 대안 검토**를 적는다. 해당 서비스의 `pyproject.toml`에만 추가한다.
- 비밀값을 코드/테스트/픽스처에 넣지 않는다. 설정은 `pydantic-settings` + `.env`.

### Python
- **mypy `--strict` 통과 필수.** `Any`, `# type: ignore`, `cast()`는 사유 주석 없이는 금지.
- 모든 공개 함수/메서드에 타입 힌트. `Optional[X]` 대신 `X | None`.
- 상대 import 금지 (`from engine.core.models import ...` 형태만).
- I/O는 `async`. 동기 블로킹 라이브러리는 `asyncio.to_thread`로 감싼다.
- 외부 라이브러리 예외는 어댑터 경계에서 `engine.core.errors.*`로 변환한다. `except Exception: pass` 금지.
- 로깅은 `structlog`. `print` 금지.

### 레이어 의존성 (import-linter가 강제)
```
engine.api  →  engine.services  →  engine.core (interfaces, models, errors)
                                         ↑
                               engine.adapters (구현체)
조립(DI)은 engine/main.py 에서만.
```
- `engine.core`는 fastapi/httpx/chromadb/langchain/pydantic을 import하지 않는다.
- `services`, `api`는 `adapters`를 import하지 않는다 — Protocol 타입으로만 받는다.
- 어댑터끼리 서로 import하지 않는다.
- `backend`와 `engine`은 서로 import하지 않는다 (HTTP 계약으로만 통신).
- 라우터(`api/`)에는 비즈니스 로직을 두지 않는다: 요청 검증 → 서비스 호출 → 응답 매핑만.

### 어댑터 구현 시
- Protocol의 docstring에 적힌 **구현 규칙(예외 타입, 정렬, 멱등성)** 을 모두 지킨다. 이것이 수락 기준의 일부다.
- 각 Protocol에는 테스트용 `fake.py` / `in_memory.py` 구현이 있어야 한다. 서비스 테스트는 Fake만 사용한다.

### TypeScript (apps/web) / Dart (apps/mobile)
- TS: `strict: true`, `any` 금지. API 타입은 생성된 `schema.d.ts`만 사용.
- Dart: `flutter analyze` 경고 0. API 호출은 생성된 `api_client` 패키지만 사용.

## 4. 테스트 규칙

- 단위 테스트 위치: `services/<svc>/tests/unit/` — 소스 경로를 그대로 미러링 (`adapters/llm/ollama.py` → `tests/unit/adapters/llm/test_ollama.py`).
- 단위 테스트는 **네트워크/GPU 없이** 돌아야 한다. HTTP는 `respx`로 모킹.
- 실제 Ollama/Chroma가 필요한 테스트는 `@pytest.mark.integration`.
- 새 공개 함수마다 정상 경로 1개 + 실패/경계 경로 1개 이상.
- 계약 테스트(`tests/contract/`): API 응답이 OpenAPI 스키마를 만족하는지 검증.

## 5. 명령어

| 목적 | 명령 |
|---|---|
| 의존성 설치 | `make install` (= `uv sync --all-packages`) |
| 단위 테스트 | `make test` |
| 통합 테스트 | `make test-integration` (Docker 필요) |
| 린트 + 포맷 검사 | `make lint-py` |
| 레이어 계약 검사 | `make lint-imports` |
| 타입 검사 | `make typecheck` |
| 계약 → 클라이언트 생성 | `make gen-clients` |
| **완료 전 필수** | **`make check`** (contracts 검증 + lint + import 계약 + mypy + test) |

`make`가 없는 환경(Windows)에서는 Makefile의 해당 레시피를 직접 실행한다. 예: `uv run pytest`, `uv run mypy ...`.

## 6. 완료 조건 (Definition of Done)

- [ ] 작업 카드의 수락 기준 전부 충족
- [ ] `make check` 통과
- [ ] 수정 금지 구역 변경 없음 (`git diff --stat`으로 확인)
- [ ] 파일당 300줄 이하
- [ ] 작업 카드 하단 `## 결과`에 변경 파일 목록과 남은 이슈 기록
