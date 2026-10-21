# T-003: py_common 런타임 — 설정 · 로깅 · request_id · Problem 핸들러

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-001 머지 후 착수)
- **관련 문서:** [03-api-conventions.md §1, §4](../architecture/03-api-conventions.md)

## 목표
두 서비스가 공유하는 런타임 기반을 만든다: 환경 설정 로딩, JSON 구조 로그, `X-Request-ID` 전파, 예외를 RFC 9457 Problem으로 바꾸는 핸들러. 이후 모든 API 카드가 이 위에서 동작한다.

## 대상 파일
| 파일 | 내용 |
|---|---|
| `scripts/gen_error_catalog.py` | `contracts/openapi/*.yaml`의 `x-error-catalog`를 읽어 `py_common/generated/error_catalog.py` 생성 |
| `packages/py-common/src/py_common/settings.py` | `BaseServiceSettings(BaseSettings)`: `env`, `log_level`, `service_name`, `version` |
| `packages/py-common/src/py_common/logging.py` | `configure_logging(settings)`: structlog JSON (prod) / console (dev), `request_id` contextvar 바인딩 |
| `packages/py-common/src/py_common/request_id.py` | ASGI 미들웨어 `RequestIdMiddleware` |
| `packages/py-common/src/py_common/problems.py` | `ProblemException`, `problem_response(...)`, `install_problem_handlers(app, catalog)` |
| `packages/py-common/tests/test_*.py` | 단위 테스트 |
| `Makefile` | `gen-py`에 `uv run python scripts/gen_error_catalog.py` 한 줄 추가 |

`py-common`의 `pyproject.toml`에 `fastapi`(starlette)와 `pyyaml`을 추가해도 된다. 사유는 이 카드다.

## 구현 명세

### 에러 카탈로그 생성물 (`generated/error_catalog.py`)
```python
# 자동 생성 — 수정 금지 (scripts/gen_error_catalog.py)
from typing import Final, TypedDict


class CatalogEntry(TypedDict):
    status: int
    retryable: bool


ENGINE_ERROR_CATALOG: Final[dict[str, CatalogEntry]] = {...}
BACKEND_ERROR_CATALOG: Final[dict[str, CatalogEntry]] = {...}
```
런타임에는 YAML을 읽지 않는다. 컨테이너에는 `contracts/`가 없기 때문이다.

### `install_problem_handlers(app, catalog)`
| 입력 예외 | 응답 |
|---|---|
| `ProblemException(code, detail=..., errors=...)` | catalog[code]의 status와 retryable |
| `RequestValidationError` | 422 `validation_error`, `errors[]`에 FastAPI의 `loc`, `msg`, `type` |
| `StarletteHTTPException` 401/404/405 | `unauthorized` / `not_found` / `not_found` |
| 그 외 `Exception` | 500 `internal_error`. `detail`은 고정 문구로 내보내고 **스택트레이스는 로그에만** 남긴다 |

- `type = f"/problems/{code}"`, `instance = request.url.path`, `request_id`는 contextvar 값
- `title`: 코드별 고정 영문 문구 `code.replace("_", " ").capitalize()`
- retryable이고 `retry_after_s`가 있으면 `Retry-After` 헤더를 설정한다
- Content-Type: `application/problem+json`
- `catalog`에 없는 code로 `ProblemException`을 만들면 **생성 시점에** `ValueError` (개발 실수 조기 발견)

Engine의 `EngineError` → Problem 변환은 이 카드 범위가 아니다 (M1 T-018). 여기서는 범용 `ProblemException`만 다룬다.

### `RequestIdMiddleware`
- 요청 `X-Request-ID`가 있으면 사용하고 (최대 128자, `[A-Za-z0-9._-]` 아니면 무시), 없으면 `uuid4().hex`
- contextvar에 저장하고, 응답 헤더 `X-Request-ID`에 넣고, structlog 컨텍스트에 바인딩
- 순수 ASGI 미들웨어로 구현한다 (`BaseHTTPMiddleware` 금지: SSE 스트리밍과 충돌)

## 수락 기준
- [ ] `gen_error_catalog.py`의 출력이 두 스펙의 카탈로그와 정확히 일치 (테스트로 비교)
- [ ] 테스트 앱(`FastAPI()` + 핸들러)에서 `ProblemException("engine_unavailable", retry_after_s=5)` → 503, `Retry-After: 5`, `application/problem+json`, `backend_v1.Problem.model_validate` 통과
- [ ] 잘못된 body → 422, `errors[0].loc == ["body", ...]`
- [ ] 처리되지 않은 예외 → 500, 응답 본문에 예외 메시지가 **없음**
- [ ] `X-Request-ID` 전달 시 응답 헤더와 Problem.request_id에 같은 값, 미전달 시 32자 hex 생성
- [ ] SSE 응답(`StreamingResponse`)에서도 request_id 헤더가 붙고 스트림이 버퍼링되지 않음
- [ ] 각 서비스 `main.py`에는 **아직 연결하지 않는다** (M1/M3 카드에서 연결)
- [ ] `make check` 통과, CI drift 검사 통과 (새 생성물 커밋)

## 금지 사항
- `contracts/` 수정 금지
- `py_common`에서 `engine`이나 `backend`를 import하지 않는다
- `generated/error_catalog.py`를 손으로 수정하지 않는다

## 결과
<Codex 기록>
