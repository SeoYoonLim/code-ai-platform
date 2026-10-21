# T-103: `OllamaEmbedder` + GPU/CPU 동적 스케줄링

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-101 머지 후 착수 — `FakeLLMProvider.in_flight`와 `EmbedderConformance`를 쓴다)
- **우선순위:** P1 — R1(10k LOC 색인 5분 미만)의 직접 요인
- **관련 문서:** [ADR-0003 D-3](../adr/0003-base-model-and-lora-serving.md), 인터페이스 [embedder.py](../../services/ai-engine/src/engine/core/interfaces/embedder.py) · [activity.py](../../services/ai-engine/src/engine/core/interfaces/activity.py), 에러 [errors.py](../../services/ai-engine/src/engine/core/errors.py)

## 목표
Ollama의 `nomic-embed-text`로 `Embedder`를 구현하고, **LLM이 유휴일 때는 GPU, 생성 중일 때는 CPU**로 임베딩 장치를 자동 선택한다 (ADR-0003 D-3).

## 실측 근거 (2026-10-21, RTX 4060 8GB, Ollama 0.40.7, 32청크 × 약 300토큰 배치)

| 장치 | 배치 소요 | 처리량 | 비고 |
|---|---|---|---|
| GPU (`num_gpu: 99`) | **0.28 s** | **≈ 114 chunks/s** | `ollama ps` → `100% GPU`, 추가 VRAM 약 117 MiB |
| CPU (`num_gpu: 0`) | 5.4 ~ 6.7 s | ≈ 5 ~ 6 chunks/s | `100% CPU` |
| 장치 전환 | 모델 **재로드 1.6 ~ 2.0 s** (전환마다) | | 같은 모델 이름에서 `num_gpu` 값이 바뀔 때 |

GPU가 CPU보다 **약 20배** 빠르다. 10k LOC ≈ 1,500 청크는 GPU에서 약 13초, CPU에서 약 5분이다.

### ⚠️ 함정 1 — `num_gpu`를 생략하면 장치가 고착된다
CPU 러너(`num_gpu: 0`)가 한 번 올라간 뒤에 `num_gpu`를 **생략한** 요청은 모델을 다시 올리지 않고 **CPU 러너를 그대로 쓴다** (재로드 0초, 그러나 `ollama ps`는 `100% CPU`). "기본값 = GPU"라고 가정하면 안 된다. **모든 요청에 `options.num_gpu`를 명시한다** — GPU는 `99`, CPU는 `0`.

### ⚠️ 함정 2 — 모델 별칭(alias)으로 장치를 나누는 방식은 동작하지 않았다
`FROM nomic-embed-text` + `PARAMETER num_gpu 0` 별칭을 만들어 두 이름으로 번갈아 호출했지만, 같은 가중치 blob을 쓰는 한 `ollama ps`에는 러너가 하나만 보이고 장치도 하나로 고정됐다. 별칭 방식은 쓰지 않는다.

## 정책 (Claude 설계 — 이대로 구현한다)

```
mode ∈ {GPU, CPU}                       # 현재 Ollama 러너가 올라가 있는 장치. 시작 시 GPU.

배치 시작 시 (embed_documents):
  want = CPU  if gauge.in_flight > 0
         GPU  if gauge.in_flight == 0 이 idle_grace_s 이상 지속됐을 때
         그 외(유휴이지만 아직 grace 미만) → 현재 mode 유지
  if want != mode and (now - last_switch) >= min_dwell_s:
      mode = want; last_switch = now        # 다음 요청에서 num_gpu 값이 바뀌며 재로드(~2s)
  요청은 항상 options.num_gpu = (99 if mode == GPU else 0) 로 보낸다

embed_query:
  장치를 절대 바꾸지 않는다. 현재 mode의 num_gpu 값으로 보낸다.
  (질의 1건은 CPU에서도 약 0.2초 — 전환 비용 2초를 낼 가치가 없다)
```

| 파라미터 | 환경변수 | 기본값 | 이유 |
|---|---|---|---|
| 정책 | `ENGINE_EMBED_DEVICE_POLICY` | `dynamic` | `dynamic` \| `gpu`(항상 GPU) \| `cpu`(항상 CPU). ADR-0003 D-3은 `dynamic`. 나머지는 장애 대응·측정용 |
| 유휴 대기 | `ENGINE_EMBED_IDLE_GRACE_S` | `3.0` | 생성 직후 곧바로 또 생성이 올 때 GPU↔CPU를 오가지 않게 함 |
| 최소 체류 | `ENGINE_EMBED_MIN_DWELL_S` | `10.0` | 전환 비용(≈2초)이 작업 시간을 잠식하지 않게 함 |
| 배치 크기 | `ENGINE_EMBED_BATCH_SIZE` | `32` | |

- `ActivityGauge`는 **생성자 인자로 주입**한다 (`gauge: ActivityGauge | None`). `None`이면 항상 유휴로 간주(= GPU). `LlamaServerProvider`와 직접 연결하는 것은 `engine/main.py`(M1 T-109)의 몫이다 — 이 카드에서 `adapters.llm`을 import하지 않는다.
- 시계는 `time.monotonic`을 직접 부르지 말고 **주입 가능한 `clock: Callable[[], float]`** 로 받는다 (테스트에서 시간을 제어).

## 대상 파일
| 파일 | 내용 |
|---|---|
| `services/ai-engine/src/engine/adapters/embeddings/ollama_embed.py` | `OllamaEmbedder` |
| `services/ai-engine/src/engine/adapters/embeddings/device_policy.py` | 순수 로직 `DevicePolicy` (HTTP 없음, 시계·게이지 주입) — 300줄 규칙과 테스트 용이성을 위해 분리 |
| `services/ai-engine/tests/unit/adapters/embeddings/test_device_policy.py` | 정책 단위 테스트 |
| `services/ai-engine/tests/unit/adapters/embeddings/test_ollama_embed.py` | respx 기반 + `EmbedderConformance` 상속 |
| `services/ai-engine/tests/integration/test_ollama_embed_live.py` | 실제 Ollama 대상 (`@pytest.mark.integration`) |
| `docker-compose.yml` | **`ollama` 서비스 블록만**: 이제 임베딩 전용이므로 `OLLAMA_MAX_LOADED_MODELS: "1"`로 낮추고 LLM용 주석을 정리. `llama-server` 블록은 T-102 소관이라 건드리지 않는다 |
| `scripts/provision_ollama.py` | `ollama pull nomic-embed-text` 멱등 실행 + 설치 확인 (이미 있으면 건너뜀) |

## 구현 명세

### `OllamaEmbedder`
- 생성자: `OllamaEmbedder(*, base_url, model="nomic-embed-text", dimension=768, batch_size=32, gauge=None, policy="dynamic", idle_grace_s=3.0, min_dwell_s=10.0, clock=time.monotonic, client=None)`. `httpx.AsyncClient`는 주입 가능하게 하고, 없으면 내부에서 하나 만들어 재사용한다 (`aclose()` 제공).
- `POST /api/embed` — 본문: `{"model", "input": [...], "options": {"num_gpu": 99|0}, "keep_alive": "30m", "truncate": true}`.
- **접두사:** nomic-embed-text 모델 카드 권고에 따라 문서는 `"search_document: "`, 질의는 `"search_query: "`를 앞에 붙인다. 접두사는 설정 가능하게 한다 (`ENGINE_EMBED_DOC_PREFIX` / `ENGINE_EMBED_QUERY_PREFIX`).
- **L2 정규화:** 서버가 정규화해 주더라도 항상 정규화한다 (이미 단위 벡터면 변하지 않아야 함). `numpy` 의존 없이 `math`로 구현해도 된다.
- `embed_documents`: 입력을 `batch_size`씩 나눠 **순서대로** 요청, 결과를 입력 순서로 이어 붙인다. 응답 벡터 수가 요청과 다르면 `EmbeddingError`. 빈 입력 → 요청 없이 `[]`.
- `dimension`: 설정값을 쓰되, 첫 응답의 벡터 길이와 다르면 `EmbeddingError`로 즉시 실패한다 (조용히 틀린 차원으로 색인되는 것을 막는다).

### 오류 변환
| 상황 | 예외 |
|---|---|
| 연결 실패, 타임아웃 | `EmbeddingError` (재시도 가능) |
| HTTP 404 (모델 없음) | `EmbeddingError`, `detail`에 "run scripts/provision_ollama.py" |
| 그 외 4xx/5xx | `EmbeddingError`, `detail`에 상태코드, 본문은 최대 300자 |
| 응답 벡터 수/차원 불일치 | `EmbeddingError` |

### `DevicePolicy` (순수 로직)
`DevicePolicy(gauge, policy, idle_grace_s, min_dwell_s, clock)`와 `decide() -> Device`(`Device.GPU`/`Device.CPU`)를 제공한다. 위 "정책" 절의 의사코드를 그대로 따른다. `decide()`는 HTTP를 모르고 상태(`mode`, `last_switch`, `idle_since`)만 갱신한다.

## 수락 기준
- [ ] **`EmbedderConformance`(T-101) 상속 테스트 전부 통과** (`embedder` fixture를 respx로 모킹한 `OllamaEmbedder`로 제공)
- [ ] `DevicePolicy` 단위 테스트 (가짜 게이지·가짜 시계) — 최소:
  - 시작 상태는 GPU / `in_flight > 0` → CPU로 전환 / 유휴가 `idle_grace_s` 미만이면 CPU 유지 / 이상이면 GPU 복귀
  - **`min_dwell_s` 안에서는 요청된 전환도 무시** (전환 직후 곧바로 반대 방향 전환 불가)
  - 정책 `gpu`/`cpu`는 게이지와 무관하게 고정
  - 게이지가 `None`이면 항상 GPU
  - `in_flight`가 0↔1을 빠르게 오가도(플래핑) 전환 횟수가 `1 / min_dwell_s`를 넘지 않음
- [ ] respx 단위 테스트 — 최소:
  - **모든 요청에 `options.num_gpu`가 있다** (GPU=99, CPU=0). `num_gpu`가 없는 요청이 한 번도 나가지 않음 (함정 1)
  - `embed_query`는 장치 전환을 일으키지 않고 현재 mode의 `num_gpu`를 쓴다
  - 접두사 적용(문서/질의 구분), 배치 분할과 순서 보존(예: 70개 → 32/32/6), 오류 변환 표의 모든 행
  - 응답이 정규화되지 않은 벡터여도 결과는 단위 벡터
- [ ] **통합 테스트 (`@pytest.mark.integration`, 실제 Ollama, `ENGINE_IT_OLLAMA_URL` 없으면 skip)** — 실행 로그를 첨부:
  1. GPU 모드: 32청크 배치 **≤ 1.0 s (≥ 30 chunks/s)**, `ollama ps`가 `100% GPU`
  2. CPU 모드: `100% CPU`, 처리량이 **4 chunks/s 이상**
  3. **고착 회귀 테스트:** CPU 모드로 한 번 올린 뒤 GPU 요청을 보내면 `ollama ps`가 **`100% GPU`로 바뀐다** (함정 1). 반대 방향도 동일
  4. 전환 직후 재로드 시간이 3초 이내
  5. 1,500청크를 `dynamic` 정책으로 색인할 때 **유휴 상태에서 ≤ 30 s**
- [ ] `ENGINE_EMBED_DEVICE_POLICY` 세 값이 환경변수로 동작하는 설정 테스트
- [ ] `make check` 통과. 파일당 300줄 이하
- [ ] **작성한 스크립트(`provision_ollama.py`)와 compose 변경을 실제로 실행**하고 결과를 "결과"에 적는다

### 후속 측정 (T-102 머지 후, 이 카드를 막지 않는다)
`llama-server`가 생성 중일 때 **GPU 임베딩을 동시에 돌리면** 생성 지연이 얼마나 느려지는지 측정해서 "결과"에 숫자만 남긴다 (TTFT p50/p95와 tok/s: 임베딩 없음 / CPU 임베딩 / GPU 임베딩). GPU 임베딩이 20배 빠르고 VRAM도 117 MiB뿐이라, 영향이 작다면 "생성 중에도 항상 GPU" 정책으로 완화할 근거가 된다. 정책 변경은 Claude가 판단한다.

## 금지 사항
- `core/**`, `contracts/**` 수정 금지
- `adapters/llm`, `adapters/vectorstore`, `adapters/parsing` import 금지 (import-linter). 게이지는 `engine.core.interfaces.ActivityGauge`로만 받는다
- `num_gpu`를 생략하는 요청 금지 (함정 1). 모델 별칭으로 장치를 나누는 방식 금지 (함정 2)
- `time.sleep`/`asyncio.sleep`에 의존하는 단위 테스트 금지 — 시계는 주입한다

## 결과
<Codex 기록: 변경 파일, 통합 테스트 수치(처리량·전환 시간·ollama ps), 후속 측정 결과, compose 변경>
