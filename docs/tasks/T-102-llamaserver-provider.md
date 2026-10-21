# T-102: `LlamaServerProvider` (llama.cpp `llama-server`) + docker-compose 서비스

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-101 머지 후 착수 — 적합성 스위트를 상속해야 한다)
- **우선순위:** P0 — ADR-0003의 핵심 구현. 이후 분석·리팩터링·채팅(M2) 전부 이 위에서 동작한다
- **관련 문서:** [ADR-0003](../adr/0003-base-model-and-lora-serving.md), [S-01 REPORT](../../ml/spikes/s01/results/REPORT.md), 인터페이스 [llm.py](../../services/ai-engine/src/engine/core/interfaces/llm.py) · [activity.py](../../services/ai-engine/src/engine/core/interfaces/activity.py), 에러 [errors.py](../../services/ai-engine/src/engine/core/errors.py)

## 목표
1. `LLMProvider`(+`ActivityGauge`)를 `llama-server`의 HTTP API로 구현한다 — `generate`, `stream`, `health`, 어댑터 선택.
2. `docker compose`에 `llama-server` 서비스를 추가해 `ENGINE_LLM_PROVIDER=llamacpp`로 실제 3B 모델이 서빙되게 한다.

## 대상 파일
| 파일 | 내용 |
|---|---|
| `services/ai-engine/src/engine/adapters/llm/llamacpp.py` | `LlamaServerProvider` (300줄 초과 시 `llamacpp_wire.py` 등으로 분리) |
| `services/ai-engine/tests/unit/adapters/llm/test_llamacpp.py` | respx 기반 단위 테스트 + `LLMProviderConformance` 상속 |
| `services/ai-engine/tests/integration/test_llamacpp_live.py` | 실제 서버 대상 (`@pytest.mark.integration`) |
| `docker-compose.yml` | `llama-server` 서비스 추가 (기존 `ollama` 서비스는 임베딩 전용으로 유지) |
| `infra/llama/entrypoint.sh` | `/adapters/*.gguf`를 스캔해 `--lora` 인자를 만들어 `llama-server` 실행 |
| `scripts/fetch_base_model.py` | base GGUF 다운로드 + sha256 검증 (`.data/models/`) |
| `.env.example` | 이미 `ENGINE_LLAMACPP_URL` 추가됨 — 필요한 변수만 보강 |

## 구현 명세

### 1. 어댑터 규약 — **이 절이 가장 중요하다 (S-01 후속 검증으로 확정)**

`llama-server`는 어댑터를 정수 `id`로 다룬다(`GET /lora-adapters` → `[{"id":0,"path":"/adapters/refactor-v1.gguf","scale":...}]`). 다음 세 가지를 **반드시** 지킨다.

1. **이름 ↔ id 매핑:** 어댑터 이름 = GGUF 파일명(확장자 제외). `/adapters/refactor-v1.gguf` → `"refactor-v1"`. 매핑은 `GET /lora-adapters`로 만들고 캐시한다. 요청된 `adapter`가 매핑에 없으면 **캐시를 한 번 갱신**한 뒤에도 없을 때만 `AdapterNotFound`.
2. **전역 상태를 믿지 않는다.** 실측 결과 `--lora-init-without-apply`는 도움말과 달리 어댑터를 꺼 두지 **않았다** (`lora` 필드 없는 요청에 어댑터가 적용됨, 카나리아 10/10). 따라서:
   - **모든 생성 요청에 로드된 모든 어댑터의 스케일을 명시**한다: `"lora": [{"id": 0, "scale": 1.0}, {"id": 1, "scale": 0.0}, ...]` — 선택된 어댑터만 `1.0`, 나머지는 `0.0`, `adapter=None`이면 전부 `0.0`.
   - `lora` 필드를 **생략하는 요청을 절대 보내지 않는다.**
   - 시작/재연결 시 `POST /lora-adapters`로 전 어댑터를 `scale 0.0`으로 맞추는 것은 방어적으로 추가해도 된다(필수는 아님).
3. **동시 요청 격리:** 같은 서버가 슬롯 2개로 동시에 어댑터 요청과 base 요청을 처리해도 서로 섞이지 않는다 (검증됨: 8/8 vs 0/8). 단, 이 격리에 기대어 **공유 상태를 바꾸는 `POST /lora-adapters`를 요청 경로에서 호출하지 않는다.**

### 2. 요청 매핑 (`POST /v1/chat/completions`)

| `GenerationRequest` | 요청 본문 |
|---|---|
| `messages` | `messages` (`role`, `content`) |
| `params.temperature/top_p/max_tokens/stop/seed` | 동명 필드 (`seed=None`이면 생략) |
| `adapter` | 위 §1의 `lora` 목록 |
| `json_schema` | 구조화 출력. **어느 필드 형식이 이 서버 버전에서 동작하는지 먼저 실험으로 확인**해서 결과에 적는다. 후보: `response_format: {"type":"json_schema","json_schema":{"schema":{...}}}` / `response_format: {"type":"json_object","schema":{...}}` / `/completion`의 `json_schema`. 동작하는 하나만 쓴다 |
| `timeout_s` | httpx 읽기 타임아웃 (`connect`는 3s 고정) |
| 스트리밍 | `"stream": true`, `"stream_options": {"include_usage": true}` |

- 응답 `model`은 `GET /props`의 `model_alias`(또는 설정값)로 채운다. `GenerationResult.adapter`는 요청값 그대로.
- `finish_reason`: `stop`→`STOP`, `length`→`LENGTH`, 그 외/오류→`ERROR`.
- `usage`: 서버 응답의 `usage.prompt_tokens/completion_tokens`. 스트림에서 `include_usage`가 안 먹으면 마지막 청크의 `timings`/`usage` 중 있는 것을 쓰고, 어느 쪽도 없으면 `0`이 아니라 **카드 결과에 "usage 미제공"으로 보고**한다.
- `latency_ms`: 요청 시작부터 마지막 바이트까지 (`time.perf_counter`).

### 3. 스트리밍
- `data: {...}` 라인(SSE)을 파싱한다. `data: [DONE]`로 종료. 빈 `delta.content`는 건너뛴다.
- `TokenChunk.index`는 **내보낸 청크 기준** 0부터 연속 증가. **마지막 청크 하나만** `finish_reason`·`usage`를 가진다 (내용이 비어도 마지막 청크를 내보낸다).
- **소비자 중단:** 제너레이터 `aclose()`/취소 시 HTTP 응답을 즉시 닫는다 (서버가 생성을 멈춘다). `in_flight`는 `try/finally`로 반드시 감소.
- 스트림 도중 연결이 끊기면 `ProviderUnavailable`(재시도 가능), 마지막 데이터 이후 `idle_timeout_s`(기본 45s) 동안 바이트가 없으면 `GenerationTimeout`.

### 4. 오류 변환 (`LLMProvider` docstring 규칙)
| 상황 | 예외 |
|---|---|
| `ConnectError`, 연결 거부, DNS 실패 | `ProviderUnavailable` |
| HTTP 503 (`Loading model`) | `ProviderUnavailable` (재시도 가능) |
| `ReadTimeout`/전체 `timeout_s` 초과 | `GenerationTimeout` |
| HTTP 400 중 컨텍스트 초과 (`exceeds the available context size` 등) | `ContextTooLarge` |
| 그 외 HTTP 4xx/5xx | `EngineError` 하위 중 가장 가까운 것. `detail`에 상태코드, **본문은 최대 300자만** |
| `adapter` 이름이 매핑에 없음 | `AdapterNotFound` (요청을 보내기 전에) |
- 재시도는 하지 않는다 (서비스 레이어 정책).

### 5. `health()` — 예외를 던지지 않는다
`GET /health`(`{"status":"ok"}`)와 `GET /lora-adapters`로 `ProviderHealth(ok, provider="llamacpp", base_model, loaded_adapters)`를 만든다. 서버가 `Loading model` 중이면 `ok=False, detail="loading"`. 연결 실패는 `ok=False, detail=<사유>`.

### 6. `ActivityGauge`
`in_flight` 프로퍼티 (T-101 `FakeLLMProvider`와 동일한 규칙: `generate`는 진입 +1/종료 −1, `stream`은 소비 완료·중단·예외 어느 경우에도 −1).

### 7. 설정 (`pydantic-settings`, 접두사 `ENGINE_`)
`ENGINE_LLAMACPP_URL`(기본 `http://localhost:8080`), `ENGINE_BASE_MODEL`, `ENGINE_LLAMACPP_API_KEY`(선택, 있으면 `Authorization: Bearer`). 클라이언트는 `httpx.AsyncClient`를 **하나** 만들어 재사용하고 `aclose()`를 제공한다.

### 8. `docker-compose` 서비스 + 실행 스크립트
- 이미지: `ghcr.io/ggml-org/llama.cpp:server-cuda` (S-01에서 검증, build 11783). **pull 후 `docker image inspect --format '{{index .RepoDigests 0}}'` 값을 compose에 `image: ...@sha256:...`로 고정**한다.
- `infra/llama/entrypoint.sh`가 만드는 최종 명령 (모두 S-01에서 이 이미지로 검증한 플래그):
  ```
  /app/llama-server -m /models/qwen2.5-coder-3b-instruct-q4_k_m.gguf \
    --lora /adapters/a.gguf,/adapters/b.gguf   # /adapters/*.gguf 가 있을 때만
    -ngl 99 -c 16384 -np 2 -fa on -ctk q8_0 -ctv q8_0 --host 0.0.0.0 --port 8080
  ```
  - ⚠️ `-c`는 **전체** 컨텍스트이고 슬롯 수로 나뉜다: `-c 16384 -np 2` → 슬롯당 8192 (실측 확인). `-c 8192 -np 2`로 쓰면 슬롯당 4096이 된다.
  - ⚠️ `-fa`는 값을 받는다 (`on|off|auto`). 단독 `-fa`로 쓰지 않는다.
  - `--lora-init-without-apply`는 **쓰지 않는다** (§1-2).
- 볼륨: `./.data/models:/models:ro`, `./.data/adapters:/adapters:ro`. GPU 예약은 기존 `ollama` 서비스와 같은 방식.
- `healthcheck`: `GET /health`. `depends_on`은 걸지 않는다 (모델 로드에 수십 초).
- `scripts/fetch_base_model.py`: `Qwen/Qwen2.5-Coder-3B-Instruct-GGUF`의 `qwen2.5-coder-3b-instruct-q4_k_m.gguf`를 `.data/models/`에 받는다. 받은 파일의 **sha256을 스크립트 상수와 대조**하고, 상수는 처음 받을 때 계산해서 `scripts/models.lock`에 기록한다. 이미 있고 해시가 맞으면 건너뛴다.
- ⚠️ S-01 검증은 **Ollama의 Q4_K_M blob**으로 했다. 새로 받은 GGUF에서도 어댑터가 동작하는지 §수락 기준의 통합 테스트로 **반드시** 다시 확인한다 (양자화 구현 차이가 있을 수 있다).

## 수락 기준
- [ ] **`LLMProviderConformance`(T-101) 상속 테스트 전부 통과** — `llm_provider` fixture를 respx로 모킹한 `LlamaServerProvider`로 제공
- [ ] 단위 테스트(respx, GPU 불필요) — 최소:
  - 어댑터 이름↔id 매핑 / 매핑 캐시 갱신 후에도 없으면 `AdapterNotFound` (요청 미전송)
  - **모든 요청에 `lora` 목록이 포함되고 선택된 어댑터만 `1.0`**, `adapter=None`이면 전부 `0.0` (요청 본문 검사)
  - `lora` 필드가 없는 요청이 **한 번도** 나가지 않음 (모든 경로: generate/stream/json_schema)
  - 스트림: 청크 index 연속, 마지막 청크만 finish_reason·usage, `[DONE]` 처리, 소비자 `aclose()` 후 응답 종료 + `in_flight` 복귀
  - 오류 변환 표의 모든 행, `health()`가 어떤 오류에서도 예외를 던지지 않음
  - 동시 `generate` 2개 + `in_flight` 값 변화
- [ ] **통합 테스트 (`@pytest.mark.integration`, GPU 필요, `ENGINE_IT_LLAMACPP_URL` 없으면 skip)** — 실제 서버 대상. 카드 결과에 실행 로그를 첨부:
  1. base GGUF가 응답하고 `usage`가 채워짐
  2. 테스트용 카나리아 어댑터(`.data/s01-artifacts/canary-3b.gguf` — 경로는 환경변수 `ENGINE_IT_ADAPTER_GGUF`)로 **어댑터 요청 20/20 표식, `adapter=None` 20/20 비표식**
  3. 어댑터 요청과 base 요청 **동시 실행** 시 섞이지 않음 (각 8회)
  4. 스트림 중간에 소비자가 중단하면 서버 슬롯이 해제됨 (`GET /slots`의 `is_processing`이 false로 복귀)
  5. **구조화 출력:** engine.v1 `Finding` 배열 스키마로 10회 요청 → 스키마 검증 통과율 보고 (S-01 D3 대체. 90% 미만이면 숫자만 보고하고 멈추지 말 것)
- [ ] `docker compose up -d llama-server` 후 60초 안에 `healthy`, `curl :8080/health` 200 — 실행 결과 첨부
- [ ] 이미지 digest가 compose에 고정되어 있고, 모델 sha256이 `scripts/models.lock`에 기록됨
- [ ] `make check` 통과 (mypy strict, import-linter 포함). 파일당 300줄 이하
- [ ] **작성한 스크립트·compose·entrypoint를 실제로 실행**하고 결과를 아래 "결과"에 적는다 (S-01 교훈: 한 번도 실행하지 않은 Dockerfile·스크립트에서 버그 4건이 나왔다)

## 금지 사항
- `core/**`, `contracts/**` 수정 금지. 인터페이스가 부족하면 `BLOCKED: interface`
- `--lora-init-without-apply`에 의존하거나 `lora` 필드를 생략하는 구현 금지 (§1-2, 실측으로 위험이 확인됨)
- 요청 경로에서 `POST /lora-adapters` 호출 금지 (전역 상태 변경)
- `adapters/embeddings`, `adapters/vectorstore`를 import 금지
- 모델 가중치·GGUF를 저장소에 커밋 금지 (`.data/`는 gitignore)

## 참고
- 실측 근거: 어댑터 전환 4ms, 요청별 override, 동시 격리 — [REPORT.md](../../ml/spikes/s01/results/REPORT.md) Part C
- `llama-server` API: `/health`, `/props`, `/slots`, `/lora-adapters`, `/v1/chat/completions`. 정확한 응답 형식은 실제 서버에서 확인 (빌드 11783 기준)
- 이 서버를 8GB GPU에서 돌릴 때 VRAM: 3.77GB (8K·병렬 2), 16K 총 컨텍스트도 100% GPU (S-01 B6/B7)

## 결과
<Codex 기록: 변경 파일, 단위/통합 테스트 결과, 구조화 출력 필드 선택과 통과율, usage 제공 여부, compose digest, 실행 로그>
