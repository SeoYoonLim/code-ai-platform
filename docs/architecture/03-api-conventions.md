# 03. API 공통 규약

- 상태: **승인 대기**
- 작성: Claude · 2026-10-21
- 적용 대상: [engine.v1.yaml](../../contracts/openapi/engine.v1.yaml), [backend.v1.yaml](../../contracts/openapi/backend.v1.yaml), [contracts/events/](../../contracts/events/)
- 자동 검증: `packages/py-common/tests/test_contracts.py`, `packages/py-common/tests/test_generated_models.py`, `services/ai-engine/tests/contract/test_error_codes.py`

---

## §1. 에러 (RFC 9457 / RFC 7807 호환)

### 1.1 응답 형식
4xx와 5xx 응답은 **모두** `application/problem+json` + `Problem` 스키마를 쓴다 (테스트가 강제).

```json
{
  "type": "/problems/engine_unavailable",
  "title": "AI engine unavailable",
  "status": 503,
  "detail": "Ollama connection refused (ollama:11434)",
  "instance": "/v1/projects/prj_01/analyses",
  "code": "engine_unavailable",
  "retryable": true,
  "retry_after_s": 5,
  "request_id": "b7e1…"
}
```

| 필드 | 규칙 |
|---|---|
| `type` | `/problems/{code}` 고정 |
| `title` | 코드별 고정 문구 (영문). 화면 문구는 클라이언트가 `code`로 i18n 처리 |
| `detail` | 이번 발생 건의 설명. **비밀값, 내부 경로, 스택트레이스 금지** |
| `code` | 서비스별 enum (`EngineErrorCode` / `ErrorCode`). 클라이언트 분기는 반드시 `code`로 한다 (`status`로 분기하지 않는다) |
| `retryable` | `x-error-catalog` 값과 같아야 한다 |
| `errors[]` | `validation_error`일 때만. `loc`는 FastAPI 형식 (`["body","paths",0]`) |

### 1.2 에러 카탈로그
각 스펙의 `*ErrorCode` 스키마에 있는 `x-error-catalog`가 `code → {status, retryable}`의 **단일 진실 원천**이다.
- API 레이어의 예외 핸들러는 이 표를 보고 HTTP status를 정한다. Codex는 생성된 모델과 함께 YAML에서 카탈로그를 읽어 쓴다.
- Engine `source: core` 코드는 `engine.core.errors` 클래스와 1:1로 대응한다 (계약 테스트로 검증).

### 1.3 Engine → Backend 에러 매핑
Backend는 Engine의 에러 코드를 **그대로 노출하지 않는다** (내부 구현 은닉).

| Engine code | Backend code | 비고 |
|---|---|---|
| `provider_unavailable`, `embedding_failed`, `vector_store_error`, `rate_limited` | `engine_unavailable` (503) | |
| `generation_timeout`, HTTP 읽기 타임아웃 | `engine_timeout` (504) | |
| 연결 실패 (httpx `ConnectError`) | `engine_unavailable` (503) | |
| `structured_output_invalid`, `internal_error` | `engine_error` (502) | |
| `context_too_large` | `context_too_large` (413) | 사용자가 범위를 줄여야 함 |
| `unsupported_language`, `parse_error` | `validation_error` (422) | |
| `collection_not_found`, `not_found` | `index_not_ready` (409) | 색인 전 분석 요청 |
| `job_conflict` | `job_conflict` (409) | |
| `validation_error`, `unauthorized`, `adapter_not_found` | `internal_error` (500) | Backend의 버그나 설정 오류. **알람 대상** |

비동기 잡에서 발생한 에러는 HTTP 응답이 아니라 `Job.error`(Problem)에 매핑된 코드로 저장하고, 푸시 `error_code`로 전달한다.

---

## §2. SSE 스트리밍

### 2.1 Wire 형식
```
retry: 3000

id: st_9f2:0
event: meta
data: {"event":"meta","stream_id":"st_9f2","session_id":"cs_1","message_id":"msg_7","model":"qwen2.5-coder:7b","adapter":null}

id: st_9f2:1
event: sources
data: {"event":"sources","sources":[{"path":"src/app.py","symbol":"main","start_line":1,"end_line":20,"score":0.82}]}

id: st_9f2:2
event: token
data: {"event":"token","index":0,"delta":"이 함수는"}

: keepalive

id: st_9f2:9
event: done
data: {"event":"done","finish_reason":"stop","usage":{"prompt_tokens":812,"completion_tokens":64}}
```

- `event:` 줄과 data JSON의 `event` 필드는 **항상 같다**. 생성 모델은 data JSON의 `event`를 discriminator로 쓴다.
- data는 **한 줄 JSON**이다 (개행 이스케이프).
- 응답 헤더: `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `X-Accel-Buffering: no`.

### 2.2 이벤트 순서 (상태 머신)
```
meta → [sources] → token* → (done | error) → 서버가 연결 종료
```
- `sources`는 chat 스트림에만 있다.
- 스트림 **시작 전** 오류(인증, 검증, 의존 장애)는 일반 Problem HTTP 응답이다. **시작 후** 오류는 `error` 이벤트로 보낸 뒤 연결을 닫는다.
- 클라이언트는 `token.index`가 연속하는지 확인하고, 중복 index는 무시한다 (재연결 시 중복 방지).

### 2.3 타임아웃 (`x-sse-policy`)

| 항목 | 값 | 주체 | 동작 |
|---|---|---|---|
| `retry_ms` | 3000 | 서버 → 클라이언트 | 스트림 첫 줄 `retry:` |
| `keepalive_interval_s` | 15 | 서버 | 15초간 이벤트가 없으면 `: keepalive` 주석 |
| `first_event_timeout_s` | 30 | 서버 | 30초 안에 `meta`를 보내지 못하면 503 Problem (스트림 시작 전) |
| `idle_timeout_s` | 45 | 클라이언트 | 45초간 아무 바이트도 없으면 연결이 죽은 것으로 판단하고 재연결 |
| `max_duration_s` | 600 | 서버 | 초과 시 `error`(Engine: `generation_timeout`, Backend: `engine_timeout`) |

### 2.4 재연결

| 구간 | resumable | 규칙 |
|---|---|---|
| Engine → Backend | ❌ | Backend가 연결 끊김을 감지하면 Engine 요청을 취소한다. Engine은 클라이언트 disconnect 시 생성을 중단한다 (`finish_reason: canceled`) |
| Backend → Web/App | ✅ | Backend는 이벤트를 Redis Stream `chat:{message_id}`에 기록한다 (TTL 300s) |

**클라이언트 재연결 절차 (Web/App)**
1. `meta.message_id`와 마지막으로 받은 이벤트 `id`를 기억한다.
2. 끊기면 `retry_ms`부터 시작하는 지수 백오프(3s, 6s, 12s, 24s, 30s 상한)로 최대 5회 `GET /v1/chat/messages/{message_id}/stream` + `Last-Event-ID`를 시도한다.
3. 서버는 해당 id **이후** 이벤트를 재전송하고 실시간 스트림을 이어 보낸다.
4. 410 `stream_expired`를 받거나 5회 모두 실패하면 `GET /v1/chat/sessions/{session_id}/messages`로 최종본을 조회한다.

Backend 측: 사용자 연결이 끊겨도 Engine 생성은 **계속**하고 버퍼에 쌓는다 (재연결 대비). 단 `max_duration_s`에 도달하거나, 300초 동안 아무 클라이언트도 붙지 않으면 생성을 취소한다.

---

## §3. 페이지네이션

| 방식 | 사용처 | 이유 |
|---|---|---|
| **Cursor** | projects, jobs, analyses, chat sessions/messages, engine index jobs | 계속 추가되는 목록. offset은 삽입이 일어나면 항목이 중복되거나 누락된다 |
| **Offset** | `GET /v1/analyses/{id}/findings` | 완료된 분석의 고정 결과. 페이지 점프와 총 개수 표시가 필요하다 |

```json
// Cursor
{ "items": [...], "page": { "next_cursor": "eyJjIjoiMjAyNi0xMC0yMVQwOTozMDowMFoiLCJpIjoicHJqXzAxIn0", "has_more": true } }
// Offset
{ "items": [...], "page": { "offset": 40, "limit": 20, "total": 87 } }
```

- `limit`: 기본 20, 최대 100. `offset`: 최대 10000.
- Cursor는 **opaque**하다 (클라이언트가 파싱하지 않는다). 구현은 `base64url(json({"c": <정렬키>, "i": <id>}))`로 하고, keyset 조건은 `(created_at, id) < (c, i)`이다.
- 정렬이나 필터를 바꾸면 이전 cursor는 무효다. 서버는 cursor 안에 필터 해시를 넣어 두고, 해시가 맞지 않으면 422 `validation_error`를 반환한다.
- 목록 응답 스키마 이름은 `*Page`, 필수 필드는 `{items, page}`다 (테스트가 강제).

---

## §4. 멱등성 · 헤더 · 기타

| 항목 | 규칙 |
|---|---|
| `Idempotency-Key` | 리소스를 생성하는 POST(projects, analyses, refactors, reindex, engine index)에서 선택적으로 쓴다. 24h 보관. 같은 키와 같은 본문이면 최초 응답을 재반환하고, 같은 키에 다른 본문이면 422 `idempotency_key_reused`(Engine은 `validation_error`). 본문은 정규화 JSON의 sha256으로 비교 |
| `X-Request-ID` | Backend가 생성(또는 수신)한 값을 Engine에 전파한다. 모든 로그와 `Problem.request_id`에 포함 |
| 시간 | RFC 3339 UTC (`2026-10-21T09:30:00Z`) |
| ID | 접두사 + ULID (`prj_`, `job_`, `ana_`, `rfc_`, `cs_`, `msg_`, `dev_`). Engine `project_id`는 Backend 프로젝트 ID를 그대로 사용 |
| 비동기 작업 | 202 + 리소스(Job/Analysis/Refactor). 상태: `queued → running → succeeded / failed / canceled` |
| 버전 | URL `/v1`. 하위 호환이 깨지는 변경은 `/v2`. 필드 추가는 호환 변경으로 보며, 클라이언트는 모르는 필드와 enum 값을 무시해야 한다 |

### Backend → Engine 클라이언트 정책

| 호출 | 타임아웃 (connect / read) | 자동 재시도 |
|---|---|---|
| `GET` 전체, `/v1/retrieve` | 3s / 10s | retryable 코드에 대해 최대 2회 (0.5s, 2s) |
| `POST /v1/index` (+Idempotency-Key) | 3s / 10s | 최대 2회 |
| `/v1/analyze`, `/v1/refactor` | 3s / `timeout_s + 10s` | HTTP 재시도 없음. arq 잡 레벨에서 `max_tries=3` (retryable일 때만) |
| SSE (`/v1/chat/stream`) | 3s / `idle_timeout_s` | 첫 이벤트 전 실패만 1회 재시도. 이후에는 재시도 없음 |

---

## §5. 계약 변경 절차 (Claude)

1. `contracts/` 수정
2. `make check-contracts` (= `gen-clients` → `verify-clients` → `test`)
   - Python: datamodel-codegen → `py_common/generated/` → import 및 예시 파싱 테스트
   - TS: openapi-typescript → `apps/web/src/lib/api/schema.d.ts` → `tsc --strict`
   - Dart: openapi-generator `dart-dio` → `apps/mobile/packages/api_client` → `build_runner` + `dart analyze` (생성은 버전 고정을 위해 항상 Docker 이미지 `openapitools/openapi-generator-cli:v7.10.0`, 분석은 Dart가 없으면 Docker)
3. 깨진 구현이나 테스트를 수정한다. 영향받는 작업 카드에 변경 사항을 기록한다.
4. 하위 호환이 깨지는 변경이면 ADR을 작성한다.
