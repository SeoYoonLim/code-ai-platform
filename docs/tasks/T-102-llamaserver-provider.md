# T-102: `LlamaServerProvider` (llama.cpp `llama-server`) + docker-compose 서비스

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** **done** (2026-10-21, 리뷰·실서버 검증 완료)
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
| `services/ai-engine/tests/integration/__init__.py` | (비어 있음 — 패키지 규약) |
| `services/ai-engine/tests/integration/test_llamacpp_live.py` | 실제 서버 대상 (`@pytest.mark.integration`) |
| `docker-compose.yml` | `llama-server` 서비스 추가 (기존 `ollama` 서비스는 임베딩 전용으로 유지) |
| `infra/llama/entrypoint.sh` | `/adapters/*.gguf`를 스캔해 `--lora` 인자를 만들어 `llama-server` 실행 |
| `scripts/fetch_base_model.py` | base GGUF 다운로드 + sha256 검증 (`.data/models/`) |
| `.env.example` | 이미 `ENGINE_LLAMACPP_URL` 추가됨 — 필요한 변수만 보강 |

## T-101 스위트 상속 규약 (확정 — 병합된 스위트를 읽고 정리한 것)

`tests/unit/adapters/llm/test_llamacpp.py`는 이렇게 시작한다 (T-101의 `test_fake_llm.py`와 같은 방식).

```python
from tests.conformance.llm_suite import LLMProviderConformance


class TestLlamaServerProvider(LLMProviderConformance):
    @pytest.fixture
    def llm_provider(self, ...) -> LLMProvider:  # fixture 이름은 반드시 llm_provider
        ...  # respx 로 모킹한 전송 위의 LlamaServerProvider
```

스위트가 실제 어댑터에 요구하는 것 — **T-101 Fake는 이미 지키고 있어서 카드에 적히지 않았던 조건들**:

1. **모킹 응답은 내용 청크가 2개 이상이어야 한다.** 스위트의 `test_concurrent_streams_are_counted_independently`는 두 스트림이 *첫 청크만 받고 열려 있는* 상태에서 `in_flight == 2`를 단언한다. 응답이 1청크면 그 청크가 곧 마지막이라 이미 `in_flight`가 내려가 있어 실패한다 (Fake 픽스처는 `"one two three"`를 쓴다). respx 목의 SSE 본문에 `delta.content`가 있는 `data:` 라인을 **3개 이상** 넣는다.
2. **마지막 `TokenChunk`가 소비자에게 전달되는 시점에 `in_flight`는 이미 0이어야 한다** (`test_stream_completion_restores_activity`, 58~59줄). 실제 SSE는 `finish_reason` 청크 뒤에 `usage` 전용 청크(`choices: []`)가 따로 온다. 그래서 `finish_reason`·`usage`를 모아 **마지막 `TokenChunk`를 만들고, 그것을 `yield`하기 직전에** `in_flight`를 감소시킨다. `[DONE]`을 기다렸다가 내리면 이 테스트가 실패한다.
3. **`stream()`은 `async def` + `yield`인 진짜 async generator여야 한다.** 스위트가 `isinstance(stream, AsyncGenerator)`를 단언하고 `aclose()`를 호출한다. 커스텀 이터레이터 클래스나 `httpx` 응답을 그대로 반환하면 실패한다.
4. **스위트는 빈 `messages=()`로 호출한다.** 실서버가 거절할 입력이므로 **스위트는 모킹된 전송(respx)에서만** 돌린다. 실서버 대상 검증은 `tests/integration/test_llamacpp_live.py`에서 별도 시나리오로 한다 (스위트를 실서버에 붙이지 않는다).
5. 스위트가 요구하는 어댑터 이름은 `"__missing__"` 뿐이다 — 이 이름이 `/lora-adapters` 목록에 **없다**고 모킹하면 `AdapterNotFound`가 요청 전송 전에 나야 한다. 캐시 갱신을 위한 `GET /lora-adapters` 호출 1회는 허용된다.
6. `in_flight` 관련 규칙 5개(완료·중단 `aclose()`·예외·동시성·generate 복귀)는 T-103 임베딩 스케줄링이 직접 의존한다. 하나라도 건너뛰거나 `xfail` 처리하지 않는다.

**테스트 패키지 규약 (T-101과 동일, 재현·검증됨):**
- 새 테스트 디렉터리에는 `__init__.py`를 둔다. 이 카드에서는 **`services/ai-engine/tests/integration/__init__.py`** 가 필요하다 (현재 `.gitkeep`만 있다). `tests/unit/adapters/llm/`의 `__init__.py` 체인은 T-101이 이미 만들었다.
- 테스트 파일 이름은 저장소 전체에서 고유해야 한다: `test_llamacpp.py`, `test_llamacpp_live.py`. 이미 있는 이름(`test_fake_llm.py` 등)을 재사용하지 않는다.
- 스위트는 `from tests.conformance.llm_suite import ...`로만 가져온다. `sys.path` 조작·상대 임포트 금지.

## 커밋 규칙 (중요)
Codex 샌드박스는 `.git`에 쓸 수 없어서 `git add`/`git commit`이 `index.lock` 권한 오류로 실패한다 (T-001·S-01·T-101에서 확인). **커밋하지 않는다.** 변경은 작업 트리에 두고 "결과"에 변경 파일과 검증 출력을 남기면 Claude가 리뷰 후 커밋·push한다.

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

로컬 구현/검증 완료. Docker/GPU 수락 기준은 Claude의 후속 검증 대기 상태다.
스테이징·커밋·push는 하지 않았다. 보호 경로 및 기존 ollama 블록 변경 없음.

### 변경 파일 (줄 수 / 테스트 수)

| 파일 | 줄 수 | 테스트 |
|---|---:|---:|
| services/ai-engine/src/engine/adapters/llm/llamacpp.py | 151 | — |
| services/ai-engine/src/engine/adapters/llm/llamacpp_wire.py | 97 | — |
| services/ai-engine/src/engine/settings.py | 11 | — |
| services/ai-engine/tests/unit/adapters/llm/test_llamacpp.py | 252 | 46 통과 (상속 14 포함) |
| services/ai-engine/tests/unit/adapters/llm/test_llamacpp_stream_io.py | 64 | 4 통과 |
| services/ai-engine/tests/unit/test_engine_settings.py | 26 | 2 통과 |
| services/ai-engine/tests/integration/__init__.py | 0 | — |
| services/ai-engine/tests/integration/test_llamacpp_live.py | 128 | 5 미실행 |
| infra/llama/entrypoint.sh | 12 | 가짜 서버 실행 2 통과 |
| scripts/fetch_base_model.py | 72 | 모킹 실행 2 통과 |
| scripts/models.lock | 1 | 최초 다운로드 전 빈 객체 |
| scripts/tests/test_fetch_base_model.py | 40 | 2 통과 |
| scripts/tests/test_llama_entrypoint.py | 56 | 2 통과 |
| docker-compose.yml | 103 | YAML/config 검증 |
| .env.example | 27 | — |
| 본 작업 카드 | 결과 포함 300줄 이하 | — |

### 구현 및 카드와 남은 차이

- 모든 generate/stream/schema 요청은 전체 adapter id의 lora 목록을 전송한다.
  선택한 것만 1.0, base는 모두 0.0. 요청 경로의 POST /lora-adapters는 없다.
- SSE content 3개 + finish + usage-only + DONE으로 상속 규약을 검증했다.
  마지막 청크 직전 카운터 감소, 중단/취소/오류 시 HTTP 응답 close 및 카운터 복구를 검증했다.
- 구조화 출력은 작은 structured_format() 함수에서 표준 OpenAI 형식을 만든다:
  response_format: {"type":"json_schema","json_schema":{"name":"response","schema":{...}}}.
  build 11783에서 이 형식이 실제 동작하는지는 Claude가 확인해야 한다.
- usage를 우선 사용하고 timings.prompt_n/predicted_n으로 폴백한다.
  둘 다 없으면 EngineError("usage not provided")로 보고하며 임의의 0을 만들지 않는다.
  실제 서버의 usage 제공 여부는 미확인이다.
- 모델 별칭은 설정값으로 시작하고 정상 health 확인 시 /props model_alias로 갱신한다.
- **이미지 digest 미고정:** Docker pull/inspect 금지 범위이므로 검증된 digest가 없다.
  현재 server-cuda 태그가 기본이며 LLAMACPP_IMAGE로 지정할 수 있다.
  Claude가 확인한 RepoDigest를 compose의 image에 고정해야 한다.
- **모델 SHA256 상수/lock 미확정:** 다운로드 금지 범위이므로 해시를 임의로 만들지 않았다.
  models.lock은 빈 객체이며 최초 다운로드 시 계산한 해시를 기록한다.
  이후 파일/재다운로드를 그 값과 대조한다. 최초 해시 확인 및 lock 검토/커밋은 Claude가 수행한다.
- 테스트 책임 분리를 위해 stream I/O, 설정, 다운로드, entrypoint 테스트 파일을 추가했다.
  외부 패키지는 추가 설치하지 않았다 (기존 py-common 의존성의 pydantic-settings 사용).

### 실제 실행 결과

uv 명령은 UV_CACHE_DIR=C:/project/project1/.data/uv-cache 사용.
기본 uv 캐시는 sdists-v9/.git 접근 거부로 초기화 실패했다.
아래 최종 명령은 모두 종료 코드 0이다.

```text
uv run ruff check .
All checks passed!

uv run ruff format --check .
199 files already formatted

uv run lint-imports
Analyzed 87 files, 79 dependencies.
Contracts: 5 kept, 0 broken.

uv run mypy packages/py-common/src services/ai-engine/src services/backend/src
Success: no issues found in 66 source files

uv run python scripts/check_file_lines.py --max 300
(출력 없음, exit 0)

uv run pytest -q
183 passed, 5 deselected, 1 warning in 6.82s

uv run openapi-spec-validator contracts/openapi/engine.v1.yaml
contracts/openapi/engine.v1.yaml: OK

uv run openapi-spec-validator contracts/openapi/backend.v1.yaml
contracts/openapi/backend.v1.yaml: OK
```

- pytest 경고: .pytest_cache/v/cache/nodeids 쓰기에 WinError 183 (테스트 통과).
  최초 --basetemp=.data/pytest-t102 실행은 기존 test_traversal_fallback이 상위 Git 저장소를
  발견해 1 failed, 173 passed였다. 기본 temp로 재실행하니 통과해 최종 실행에 --basetemp는 불필요했다.
  관련 기존 소스/테스트는 변경하지 않았다.
- bash -n infra/llama/entrypoint.sh: exit 0, 출력 없음 (정적 문법 검사).
- uv run python -c "import yaml; yaml.safe_load(open('docker-compose.yml', encoding='utf-8')); print('YAML valid')":
  exit 0, YAML valid.
- docker compose config: exit 0, llama-server의 GPU 예약/볼륨/entrypoint/healthcheck 설정 출력.
  Docker config.json 접근 거부 경고 2개가 있었으나 설정 검증은 성공했다. daemon은 실행하지 않았다.
- uv run python scripts/fetch_base_model.py --help: exit 0, [-h] [--destination DESTINATION] 도움말 출력.
- entrypoint는 테스트에서 절대 경로만 임시 경로/가짜 실행 파일로 치환하여 bash로 실제 실행했다.
  어댑터 없음/2개에 대해 --lora 정렬 목록과 -c 16384 -np 2 -fa on 등 전체 인자를 확인했다.
- fetch()는 respx 합성 바이트로 실제 실행했다. 최초 해시 기록, 일치 시 skip, 불일치 실패 및
  .part 정리, 잘못된 lock 검증을 실행했다. 실제 모델 다운로드는 하지 않았다.
- git diff --stat 및 별도 검사: 보호 경로 변경 없음, ollama 블록 원문 동일, 새 테스트 이름 전역 고유.
  줄 수 스크립트가 untracked 파일을 제외하므로 신규 파일도 별도로 세어 전부 300줄 이하 확인.

### 미실행 (Claude가 실행)

- Docker 이미지 pull, 실제 build/digest 확인 및 compose image digest 고정.
- 실제 entrypoint/서버 실행, compose up 후 60초 내 healthy와 /health HTTP 200.
- 공식 Qwen GGUF 다운로드, SHA256 확인 및 scripts/models.lock 값 확정.
- 공식 GGUF에서 base 응답 및 usage 확인.
- canary adapter 20/20 표식, base 20/20 비표식.
- adapter/base 동시 요청 각 8회 격리 검증.
- 스트림 중단 후 /slots is_processing=false 복구 검증.
- build 11783의 response_format/json_schema 실제 지원 및 Finding 배열 10회 준수율 보고.
- opt-in 통합 테스트 5개: ENGINE_IT_LLAMACPP_URL 설정 후
  uv run pytest -m integration services/ai-engine/tests/integration/test_llamacpp_live.py -s
  ENGINE_IT_ADAPTER_GGUF는 서버에 로드된 어댑터 파일명(stem)과 일치해야 한다.

### 수정: 느린 소비자 타임아웃
- 변경: `llamacpp.py` 151→165줄, `test_llamacpp_stream_io.py` 110→113줄(타입 주석만); 본 카드 299줄.
- 연결/헤더/오류 본문 및 각 SSE anext 대기 시간만 누적 차감한다. 모든 yield는 timeout 밖이다.
- AsyncExitStack은 실패/취소/aclose 시 응답을 닫고 finally는 in_flight를 복구한다.
- 마지막 청크 직전 감소 및 finish_reason/usage 유지. generate()는 yield가 없어 영향 없고 변경하지 않았다.
- 회귀 assertion 변경 없음. Docker/새 스크립트 실행/스테이징/커밋/push 없음. 보호 경로 변경 없음.
- 아래는 실제 출력(모든 최종 명령 exit 0); UV_CACHE_DIR=C:/project/project1/.data/uv-cache.
```text
uv run pytest -q services/ai-engine/tests/unit/adapters/llm/test_llamacpp_stream_io.py services/ai-engine/tests/unit/adapters/llm/test_llamacpp.py
52 passed, 1 warning in 3.39s
uv run ruff check .
All checks passed!
uv run ruff format --check .
199 files already formatted
uv run lint-imports
Analyzed 88 files, 80 dependencies.
Contracts: 5 kept, 0 broken.
uv run mypy --strict packages/py-common/src services/ai-engine/src services/backend/src services/ai-engine/tests/unit/adapters/llm/test_llamacpp_stream_io.py
Success: no issues found in 67 source files
uv run python scripts/check_file_lines.py --max 300
(출력 없음)
uv run pytest -q
185 passed, 5 deselected, 1 warning in 9.32s
uv run openapi-spec-validator contracts/openapi/engine.v1.yaml
contracts/openapi/engine.v1.yaml: OK
uv run openapi-spec-validator contracts/openapi/backend.v1.yaml
contracts/openapi/backend.v1.yaml: OK
```
- 경고: 기존 .pytest_cache/v/cache/nodeids 쓰기 실패(WinError 183). 신규/변경 파일도 별도 줄 수 확인.

### 리뷰 · 실서버 검증 (Claude, 2026-10-21)

Codex는 Docker 접근이 없어 단위 테스트까지만 검증했다. 아래는 Claude가 **실제 서버(RTX 4060, 이미지 digest 고정, 공식 GGUF)** 에서 실행한 결과다.

**환경 고정**
- 이미지: `ghcr.io/ggml-org/llama.cpp@sha256:1bacc872b168d2d10bfd8c220336f5a2cd464c07605936ec146ee5198832ffce` (build 11783)
- 모델: 공식 `Qwen/Qwen2.5-Coder-3B-Instruct-GGUF` `qwen2.5-coder-3b-instruct-q4_k_m.gguf`, 2,104,932,800 B, sha256 `724fb256…4730b7` — Hugging Face `X-Linked-ETag`와 **독립 대조**해 `scripts/models.lock`에 기록했다 (최초 다운로드 신뢰 방식 대신). `fetch_base_model.py`를 실제로 실행해 재다운로드 없이 검증 통과 확인.
- compose 기동: `entrypoint.sh`가 `/adapters/*.gguf`를 스캔해 `--lora` 전달, **18초 만에 healthy**, 슬롯당 컨텍스트 8192, 시스템 VRAM 3,178 MiB.

**실서버 통합 테스트 (`-m integration`, Codex가 쓴 5개 — 처음 실행): 5 passed**
| 시나리오 | 결과 |
|---|---|
| base 응답 + `usage` | ✅ |
| 카나리아 어댑터 20/20, `adapter=None` 20/20 비표식 (**공식 GGUF**) | ✅ |
| 어댑터·base 동시 요청 격리 | ✅ |
| 스트림 중단 시 서버 슬롯 해제 | ✅ |
| 구조화 출력 Finding 스키마 | ✅ 10/10 |

**카드 대비 실측 사실:** 구조화 출력은 `response_format: {"type":"json_schema",…}` 표준 형식이 이 빌드에서 그대로 동작한다. 스트림 `usage`는 `finish_reason` 청크 뒤의 `choices: []` 전용 청크로 오며(`stream_options.include_usage`), Codex의 파서 가정과 일치. 컨텍스트 초과는 `HTTP 400`, `type: exceed_context_size_error`로 오고 `ContextTooLarge`로 변환됨(generate/stream 모두, `in_flight` 복귀). 미등록 어댑터는 `AdapterNotFound`.

**리뷰에서 발견·수정한 결함 3건**
1. **`entrypoint.sh`가 CRLF라 컨테이너가 즉시 종료** (`/entrypoint.sh: 2: set: Illegal option -`, exit 2). Docker 없는 샌드박스에서는 발견 불가. `.gitattributes`에 `*.sh text eol=lf`를 추가하고 정규화.
2. **`stream()`이 느린 소비자에서 오동작 (실서버로 재현·확정).** `asyncio.timeout`이 `yield`를 감싸서 소비자가 제어를 쥔 시간까지 `timeout_s`에 포함됐다. 결과: 서버는 정상인데 5초 뒤 `CancelledError`(`GenerationTimeout`이 아님)로 끊기고 **`in_flight`가 1로 영구 누수** — T-103 임베딩 스케줄링이 CPU에 고착될 수 있는 상태. 회귀 테스트 2개를 먼저 작성해 실패를 확인한 뒤 Codex가 수정(서버 대기 구간에만 예산 적용, 모든 `yield`는 타임아웃 밖). 수정 후 같은 실서버 재현에서 **190청크 정상 완주, `in_flight=0`**, 그리고 `docker pause`로 서버를 실제로 멈추면 3.2초에 `GenerationTimeout`·`in_flight=0`(타임아웃 보호 유지).
3. **서버 정지 테스트가 구현 회귀 시 CI를 영구히 멈출 수 있음** (`pytest-timeout` 미설치). 타임아웃 로직을 제거한 변이에서 테스트가 무한 대기했다. `asyncio.wait_for(…, 5.0)` 상한을 추가해 약 7초 만에 `TimeoutError`로 실패하도록 확인.

**변이 테스트** (단위 테스트가 핵심 규약을 지키는지): 
`lora` 필드를 `adapter=None`에서 생략(실측된 "어댑터가 몰래 켜지는" 버그) 6건 실패 · 모든 어댑터 ON 6건 · 선택 어댑터 미적용 5건 · `in_flight`를 마지막 청크 뒤에 감소 6건 · 스트림 중단 시 `in_flight` 누수 24건 — **5/5 검출**. 타임아웃 제거 변이는 위 3번의 이유로 매달려 별도 수정.

**검사:** ruff · format · import-linter 5/5 · mypy(src 66파일) · 300줄 · pytest **185 passed** 모두 통과. 금지 구역 변경 없음.

**알려진 한계 / 후속**
- `mypy --strict`를 **테스트까지** 돌리면 14건이 나온다. CI(`make typecheck`)는 `src`만 검사해 통과하며, 대부분은 pydantic mypy 플러그인이 `BaseSettings`의 `_env_file` 인자·`str`→`AnyHttpUrl` 변환을 모르는 것과 `jsonschema`/`yaml` 타입 스텁 부재다. 다만 `None` 가능 값에 바로 속성 접근하는 곳 2건(`test_llamacpp.py:79`, `test_engine_settings.py:16`)과 `AsyncIterator.aclose`(`test_llamacpp_live.py:84`)는 실제 타입 부정확이므로 후속에서 정리한다.
- 컨텍스트 초과 분류가 메시지 문구(`"context size"`)에 의존한다. 서버가 안정 필드 `error.type == "exceed_context_size_error"`를 주므로 서버 버전이 바뀌어 문구가 달라지면 조용히 깨질 수 있다. 후속에서 `type` 필드 기준으로 바꾼다.
- 어댑터 품질 효과는 여전히 미측정(카나리아는 기계적 동작 검증일 뿐 — ADR-0003 한계 2).
