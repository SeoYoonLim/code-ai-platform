# T-103: `OllamaEmbedder` + GPU/CPU 동적 스케줄링

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** **done** (2026-10-21, 리뷰·실서버 검증 완료)
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

### 함정 2 — 모델 별칭(alias)으로 장치를 나눠도 **전환 비용은 줄지 않는다** (재시험으로 정정)
`FROM nomic-embed-text` + `PARAMETER num_gpu 99`/`0` 별칭 두 개를 만들어 **모두 내린 깨끗한 상태**에서 번갈아 호출했다. 별칭 이름만으로 장치가 정확히 결정된다
(`options` 없이도 GPU 별칭 → `100% GPU` 약 2.4초/배치, CPU 별칭 → `100% CPU` 약 7.4초/배치). 그러나 **러너는 한 번에 하나만 상주**해서
호출마다 `load_duration`이 1.7 ~ 2.2초로 찍히며 번갈아 교체된다. 즉 별칭 방식의 전환 비용(≈2초)은 `options.num_gpu` 방식과 같고, 이점이 없다.
> 이 카드의 초판은 "별칭은 동작하지 않았다"고 썼으나, 그 시험은 CPU 러너가 이미 떠 있는 상태에서 시작한 **통제되지 않은 실험**이었다. 깨끗한 상태에서 다시 재서 정정했다.

**결론:** 구현은 `options.num_gpu`를 명시하는 방식(함정 1의 규칙)으로 한다. 별칭은 쓸 이유가 없다. 두 러너를 동시에 상주시키는 방법(전환 비용 0)은
이 Ollama 버전에서 확인하지 못했다 — 필요하면 Codex가 `OLLAMA_MAX_LOADED_MODELS`/`OLLAMA_NUM_PARALLEL` 조합으로 시도하고 결과를 "결과"에 남긴다(필수 아님).

## 정책 (Claude 설계 — 이대로 구현한다)

```
상태: mode ∈ {GPU, CPU}   (시작 시 GPU)
      last_switch  = 마지막으로 mode 를 바꾼 시각   (시작 시 -inf)
      last_busy    = 마지막으로 gauge.in_flight > 0 을 "관찰"한 시각   (시작 시 None)

decide()  — embed_documents 의 매 배치 시작 직전에 정확히 1번 호출. 그 외 시점에는 gauge 를 읽지 않는다.
  now = clock()
  busy = gauge.in_flight > 0           (gauge 가 None 이면 False)
  if busy: last_busy = now
  if   busy:                                             want = CPU
  elif last_busy is None or now - last_busy >= idle_grace_s:   want = GPU
  else:                                                  want = mode          # grace 미만: 유지
  if want != mode and now - last_switch >= min_dwell_s:
      mode = want; last_switch = now
  return mode

모든 요청: options.num_gpu = 99 if mode == GPU else 0   (항상 명시 — 함정 1)

embed_query:  decide() 를 호출하지 않는다. 현재 mode 의 num_gpu 로 보낸다. 장치를 바꾸지 않는다.
```

**의미를 못 박는 이유 (시뮬레이션으로 확인함).** 어댑터는 게이지를 **배치 시작 시점에만** 관찰하므로 "유휴가 `idle_grace_s` 동안 지속"을
연속 관찰로 구현할 수 없다 (그런 신호가 없다). 위 정의(`last_busy` = 마지막으로 *관찰된* 바쁨)로 구현한다. 배치 하나 안에서 시작해 끝난
짧은 생성은 관찰되지 않는데, 그 생성은 이미 끝났으므로 GPU 로 돌아가도 해가 없다. 위험한 경우(배치 시작 시점에 생성이 진행 중)는
`in_flight > 0`으로 정확히 관찰된다. `idle_since`(첫 유휴 관찰 시각) 방식으로 바꾸지 않는다 — 두 방식은 이 시나리오에서 같은 결과를 내지만
`last_busy` 쪽이 상태가 하나 적고 테스트가 단순하다.

**기본값의 실제 비용 (시뮬레이션, 32청크 배치 × 47 = 1500청크, 색인 중 4초짜리 생성 1회):**

| 정책 | 색인 총시간 | CPU에 머문 시간 |
|---|---|---|
| 항상 GPU | 13.2 s | 0 |
| `dynamic` (grace 3, dwell 10 — 기본값) | 27.6 s | 11.0 s |
| `dynamic` (dwell 0) | 22.4 s | 5.5 s |

`min_dwell_s=10`은 CPU 배치(≈5.5 s) 2개분을 강제하므로 짧은 생성 1회가 색인 시간을 약 2배로 만든다. R1(5분)에는 여유 있게 들어오므로
ADR-0003 D-3 결정(`dynamic`)과 기본값은 유지하되, 후속 측정에서 이 비용을 실측으로 확인한다.

| 파라미터 | 환경변수 | 기본값 | 이유 |
|---|---|---|---|
| 정책 | `ENGINE_EMBED_DEVICE_POLICY` | `dynamic` | `dynamic` \| `gpu`(항상 GPU) \| `cpu`(항상 CPU). ADR-0003 D-3은 `dynamic`. 나머지는 장애 대응·측정용 |
| 유휴 대기 | `ENGINE_EMBED_IDLE_GRACE_S` | `3.0` | 생성 직후 곧바로 또 생성이 올 때 GPU↔CPU를 오가지 않게 함 |
| 최소 체류 | `ENGINE_EMBED_MIN_DWELL_S` | `10.0` | 전환 비용(≈2초)이 작업 시간을 잠식하지 않게 함 |
| 배치 크기 | `ENGINE_EMBED_BATCH_SIZE` | `32` | |

- `ActivityGauge`는 **생성자 인자로 주입**한다 (`gauge: ActivityGauge | None`). `None`이면 항상 유휴로 간주(= GPU). `LlamaServerProvider`와 직접 연결하는 것은 `engine/main.py`(M1 T-109)의 몫이다 — 이 카드에서 `adapters.llm`을 import하지 않는다.
- 시계는 `time.monotonic`을 직접 부르지 말고 **주입 가능한 `clock: Callable[[], float]`** 로 받는다 (테스트에서 시간을 제어).

## T-101 스위트 상속 규약 (확정 — 병합된 `EmbedderConformance`를 읽고 모킹 임베더로 시험한 결과)

```python
from tests.conformance.embedder_suite import EmbedderConformance


class TestOllamaEmbedder(EmbedderConformance):
    @pytest.fixture
    def embedder(self, ...) -> Embedder:   # fixture 이름은 반드시 embedder
        ...  # respx 로 모킹한 /api/embed 위의 OllamaEmbedder
```

접두사(`search_document:` / `search_query:`)는 스위트와 **충돌하지 않는다** — 스위트는 "질의 벡터 == 문서 벡터"를 요구하지 않는다 (그 규칙은 Fake 고유 테스트에만 있다).
그러나 모킹 응답이 다음을 지키지 않으면 올바른 구현도 실패한다. 순진한 구현으로 직접 시험해 확인했다.

1. **모킹 벡터의 길이 = 생성자의 `dimension`** (기본 768). 다른 길이(예: 16차원)를 돌려주면 `test_vectors_are_l2_normalized`와 `test_dimension_matches_vectors`가 실패한다. 카드의 "차원 불일치 → `EmbeddingError`" 규칙과도 맞물린다.
2. **모킹 응답은 입력 텍스트에 대해 결정적**이어야 한다 (예: 텍스트의 sha256으로 만든 벡터). 고정 벡터 하나를 돌려주면 순서 보존 테스트가 아무것도 검증하지 못하고, 호출마다 달라지면 결정성 테스트가 실패한다. `side_effect` 핸들러에서 요청 본문 `input` 리스트를 읽어 그 길이만큼 벡터를 만든다.
3. **모킹 서버가 정규화되지 않은 벡터를 돌려주는 경우를 포함한다.** 서버를 믿고 정규화를 생략한 구현은 `test_vectors_are_l2_normalized`에서 실패한다 (시험으로 확인함). 어댑터는 항상 정규화한다.
4. 스위트는 빈 문자열 `""`도 임베딩한다. 접두사가 붙으므로 실제 요청은 빈 입력이 아니다. 모킹이 `input`을 그대로 되돌려 길이를 맞추게 하라 (영벡터 금지 — 정규화에서 0으로 나눈다).
5. `embed_documents`는 `batch_size`(기본 32)로 쪼개 여러 번 호출한다. 스위트의 `["a","b","a"]` 같은 작은 입력은 한 배치지만, 70개 → 32/32/6 분할은 **별도 단위 테스트**로 검증한다 (스위트에 없다).

**`in_flight` 연동 (T-102에서 확정):** `LlamaServerProvider.in_flight`는 (a) 스트림의 마지막 청크를 내보내기 **직전**에 감소하고 (b) 중단·예외·타임아웃 어느 경우에도 감소하며 (c) 느린 소비자가 있어도 서버 대기 구간 밖에서는 변하지 않는다. 그래서 `decide()`가 읽는 `in_flight > 0`은 "서버가 지금 생성 중"과 같다.
단위 테스트의 게이지는 `FakeLLMProvider`(이미 `ActivityGauge`를 만족)나 `in_flight` 프로퍼티만 가진 작은 스텁을 쓴다. `adapters.llm`을 import하지 않는다 (import-linter) — `engine.core.interfaces.ActivityGauge`로만 받는다.

**테스트 패키지 규약 (T-101·T-102와 동일, 재현·검증됨):** 새 테스트 디렉터리에 `__init__.py` (`tests/integration/__init__.py`는 T-102가 이미 만들었다) · 테스트 파일 이름은 저장소 전체에서 고유 (`test_ollama_embed.py`, `test_device_policy.py`, `test_ollama_embed_live.py`, `test_provision_ollama.py`) · 스위트는 `from tests.conformance.embedder_suite import ...`로만 가져온다.

## 커밋 규칙 (중요)
Codex 샌드박스는 `.git`에 쓸 수 없어서 `git add`/`git commit`이 `index.lock` 권한 오류로 실패한다 (T-001·S-01·T-101·T-102에서 확인). **커밋하지 않는다.** 변경은 작업 트리에 두고 "결과"에 변경 파일과 검증 출력을 남기면 Claude가 리뷰 후 커밋·push한다.
**Docker·실서버가 필요한 검증은 Codex 범위가 아니다** (샌드박스에서 불가). 통합 테스트(`test_ollama_embed_live.py`)와 `provision_ollama.py` 실행, `docker-compose.yml`의 `ollama` 블록 변경은 *작성*까지만 하고, 실행하지 못한 항목은 "미실행 (Claude가 실행)"으로 나열한다.

## 대상 파일
| 파일 | 내용 |
|---|---|
| `services/ai-engine/src/engine/adapters/embeddings/ollama_embed.py` | `OllamaEmbedder` |
| `services/ai-engine/src/engine/adapters/embeddings/device_policy.py` | 순수 로직 `DevicePolicy` (HTTP 없음, 시계·게이지 주입) — 300줄 규칙과 테스트 용이성을 위해 분리 |
| `services/ai-engine/tests/unit/adapters/embeddings/test_device_policy.py` | 정책 단위 테스트 |
| `services/ai-engine/tests/unit/adapters/embeddings/test_ollama_embed.py` | respx 기반 + `EmbedderConformance` 상속 |
| `services/ai-engine/tests/integration/test_ollama_embed_live.py` | 실제 Ollama 대상 (`@pytest.mark.integration`) |
| `docker-compose.yml` | **`ollama` 서비스 블록만**: 이제 임베딩 전용이므로 `OLLAMA_MAX_LOADED_MODELS: "1"`로 낮추고 LLM용 주석을 정리. `llama-server` 블록은 T-102 소관이라 건드리지 않는다 | **측정으로 확인됨 (2026-10-21):** `OLLAMA_MAX_LOADED_MODELS`가 `1`이든 `2`든 전환 동작은 동일하다 (상주 러너 1개, 전환 재로드 1.7~2.1 s). 따라서 `1`로 낮추는 것은 성능과 무관한 정리 작업이다 — 다시 조사하지 않는다. 낡은 주석(`# ADR-0002 … 7B …`, `# LLM(GPU) + 임베딩(CPU…)`)을 "임베딩 전용 (ADR-0003)"으로 고친다.
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
- `num_gpu`를 생략하는 요청 금지 (함정 1). 모델 별칭으로 장치를 나누는 방식은 이점이 없으므로 쓰지 않는다 (함정 2)
- `time.sleep`/`asyncio.sleep`에 의존하는 단위 테스트 금지 — 시계는 주입한다

## 결과
구현 완료, 작업 트리에 유지 (git add/commit/push 미실행). 실서버 수락 기준은 아래 미실행 목록으로 남긴다.

### 변경 파일 (줄 수 / 테스트 수)

| 파일 | 줄 수 | 테스트 수 |
|---|---:|---:|
| `services/ai-engine/src/engine/adapters/embeddings/ollama_embed.py` | 76 | — |
| `services/ai-engine/src/engine/adapters/embeddings/device_policy.py` (신규) | 56 | — |
| `services/ai-engine/src/engine/adapters/embeddings/ollama_wire.py` (신규) | 35 | — |
| `services/ai-engine/src/engine/settings.py` | 22 | — |
| `services/ai-engine/tests/unit/adapters/embeddings/test_device_policy.py` (신규) | 96 | 7 |
| `services/ai-engine/tests/unit/adapters/embeddings/test_ollama_embed.py` (신규) | 186 | 25 (상속 8 포함) |
| `services/ai-engine/tests/unit/test_engine_settings.py` | 94 | 12 (신규 10) |
| `services/ai-engine/tests/integration/test_ollama_embed_live.py` (신규) | 91 | 4 (미실행) |
| `scripts/provision_ollama.py` (신규) | 50 | — |
| `scripts/tests/test_provision_ollama.py` (신규) | 62 | 6 |
| `docker-compose.yml` | 103 | — |
| 이 작업 카드 | 300줄 이하 | — |

`decide()`는 문서 배치마다 정확히 한 번 호출하며, 질의와 빈 문서 입력은 게이지를 읽지 않는다.
현재 장치의 `num_gpu`를 항상 명시하고, 모든 벡터의 수/차원/유한한 비영 norm을 검증하여 정규화한다.
가짜 시계로 last_busy/grace/dwell/플래핑을 검증했다. respx 응답은 입력별 결정적인 768차원 비정규화 벡터다.
상속 스위트도 테스트 전용 서브클래스의 `asyncio.wait_for(..., 5)`로 제한한다.
기존 테스트 디렉터리만 사용했으며 새 테스트 파일 이름의 저장소 내 고유성을 확인했다.

### 실제 실행한 검증 (모두 종료 코드 0)

uv 기본 캐시 접근이 거부되어 각 명령에 `UV_CACHE_DIR=C:\project\project1\.uv-cache`를 설정했다.

```text
uv run ruff check .
All checks passed!
uv run ruff format --check .
206 files already formatted
uv run lint-imports
Analyzed 90 files, 97 dependencies.
Contracts: 5 kept, 0 broken.
uv run mypy packages/py-common/src services/ai-engine/src services/backend/src
Success: no issues found in 68 source files
uv run python scripts/check_file_lines.py --max 300
(출력 없음, exit 0)
uv run pytest -q
233 passed, 9 deselected, 1 warning in 10.88s
uv run pytest --cov=engine --cov=backend --cov=py_common --cov-report=term-missing
TOTAL 1407 statements, 14 missed, 99% coverage
233 passed, 9 deselected, 1 warning in 11.22s
uv run openapi-spec-validator contracts/openapi/engine.v1.yaml
contracts/openapi/engine.v1.yaml: OK
uv run openapi-spec-validator contracts/openapi/backend.v1.yaml
contracts/openapi/backend.v1.yaml: OK
```

전체 pytest는 기본 temp 경로로 통과했다 (`--basetemp` 불필요).
초기 대상 46개 테스트 실행에만 `--basetemp=.pytest-t103`를 사용했다 (46 passed).
경고: pytest cache nodeids 저장 WinError 183; coverage 실행은 backend 미수입 경고도 출력했다.
Makefile의 check 레시피에 해당하는 계약 검증/lint/import/mypy/크기/coverage 테스트를 직접 실행했다.
`git diff --stat` 및 compose diff 확인: 수정 금지 구역 변경 없음, compose는 ollama 블록의 두 줄만 변경.

### 스크립트 실행 / 정적 검사 구분

- `uv run python scripts/provision_ollama.py --help`: exit 0, `[-h] [--base-url BASE_URL]` 출력.
- provisioning 함수와 main은 respx로 실행: 이미 설치/신규 pull/HTTP 실패/pull 실패/설치 확인 실패를 검증.
- `uv run python -c "import yaml; yaml.safe_load(open('docker-compose.yml', encoding='utf-8'))"`: exit 0, 출력 없음. compose는 정적 파싱만 수행.
- Docker/Ollama 실행, 모델 다운로드는 하지 않았다.

### 미실행 (Claude가 실행)

- `test_ollama_embed_live.py` 실제 Ollama 통합 테스트: GPU/CPU 처리량, 장치 고착 회귀, 재로드, 1,500청크 유휴 색인.
- `provision_ollama.py` 실제 daemon 대상 실행.
- compose recreate 및 변경된 ollama 서비스 실행.
- 생성 영향 측정: 임베딩 없음 / CPU / GPU의 TTFT p50/p95 및 tok/s 비교.

### 카드와의 차이 / 남은 이슈

- 요청대로 wire helper 파일을 추가했다. 정책 정의의 last_busy를 따르며 후반의 idle_since 오기는 적용하지 않았다.
- live 테스트는 `/api/ps`의 size/size_vram으로 CPU/GPU 상주 상태를 확인하고 load_duration을 기록한다. CLI `ollama ps` 출력 수집은 Claude 실측에서 별도 수행한다.
- 실측 결과는 주장하지 않는다. 새 의존성/인터페이스 변경/정책 변경 없음.

### 리뷰 · 실서버 검증 (Claude, 2026-10-21)

Codex는 Docker·실서버 접근이 없어 단위 테스트까지만 검증했다. 아래는 Claude가 실제 Ollama 0.40.7 + `llama-server`(RTX 4060)에서 실행한 결과다.

**독립 재검증:** ruff · format · import-linter 5/5 · mypy(src 68파일) · 300줄 · pytest 233 passed (Codex 보고와 일치). 금지 구역·`ollama` 외 compose 블록 변경 없음.

**실서버 통합 테스트 (`-m integration`, Codex가 쓴 4개 — 처음 실행): 4 passed**
| 항목 | 측정 | 카드 기준 |
|---|---|---|
| GPU 처리량 (`num_gpu: 99`) | **115.2 chunks/s** (0.278 s/32청크), `/api/ps` GPU | ≥ 30 ✅ |
| CPU 처리량 (`num_gpu: 0`) | **5.8 chunks/s** (5.53 s/32청크), `/api/ps` CPU | ≥ 4 ✅ |
| 장치 전환 재로드 | 1.92 s, 1.57 s | ≤ 3 s ✅ |
| 1500청크 `dynamic` 색인 (유휴) | **13.4 s** | ≤ 30 s ✅ (시뮬레이션 예측 13.2 s) |

**`provision_ollama.py` 실행:** 모델 있음 → `pulled=False`로 건너뜀 / 모델 삭제 후 → 실제 pull **29 s**, `pulled=True`, 복원된 모델 ID `0a109f422b47` 동일 / 직후 재실행 → `pulled=False` (멱등).
**알려진 제약:** `/api/pull`을 `stream: False`로 한 번에 기다리며 `timeout=600`이다. 느린 네트워크에서 10분을 넘기면 스크립트는 `ReadTimeout`으로 실패하지만 서버 쪽 다운로드는 계속되므로 재실행하면 이어서 완료된다 (멱등).

**변이 테스트 (정책·어댑터 로직을 지키는지):** 15개 버그를 하나씩 심어 확인 — `min_dwell` 무시, `idle_grace` 무시, busy→CPU 미적용, `last_busy` 미갱신, `policy=cpu` 초기값, `gauge=None`을 busy로 처리, **`num_gpu` 생략(측정된 CPU 고착 버그)**, `embed_query`가 장치 전환, 문서 배치에서 `decide()` 생략, `decide()`를 배치당이 아닌 호출당 1회, 접두사 2종 제거, 정규화 생략, 차원 불일치 수용, 개수 불일치 수용.
- **14/15가 처음부터 검출**됐다. **놓친 1건: `idle_grace_s` 완전 무시.** `min_dwell_s`(기본 10 s)가 `idle_grace_s`(기본 3 s)보다 커서 dwell 규칙이 grace 규칙을 가렸고, 두 안전장치가 겹쳐 하나가 고장나도 증상이 안 보였다. `min_dwell_s=0`으로 grace만 격리하는 `test_idle_grace_holds_cpu_on_its_own`을 추가해 검출 (15/15).
- ⚠️ 첫 시도는 **무효**였다 (변이 하니스가 Git Bash의 `/tmp`를 Windows Python이 못 읽어 변이가 한 번도 적용되지 않았고 전부 "55 passed"로 나왔다). 하니스를 저장소 안 경로로 옮기고 "변이가 실제 적용됐는가"를 검증하도록 고친 뒤 재실행한 결과만 유효하다.

**동시 색인기 플래핑 점검:** 기본값(`dwell 10`, `grace 3`)에서 생성이 계속 깜빡이는 가혹한 입력으로 시뮬레이션 — 색인기 1개 60요청 중 전환 1회, 2개 120요청 중 1회. `min_dwell_s`가 플래핑을 막는다 (`min_dwell_s=0`이면 20요청 중 9회 전환하지만 이는 방지 장치를 끈 설정).

#### 후속 측정: 생성 중 임베딩 장치가 생성 성능에 주는 영향
`llama-server`(공식 GGUF, 3B Q4_K_M) 생성 12회(최대 200토큰)를 임베딩 부하가 **동시에 계속 도는** 조건에서 쟀다. 조건 순서를 뒤집어 2라운드 (A=임베딩 없음, B=CPU 임베딩, C=GPU 임베딩).

| 조건 | 생성 속도 (tok/s) | TTFT p50 | 동시 임베딩 처리 (32청크 배치 수) | VRAM |
|---|---|---|---|---|
| A 임베딩 없음 | 96.1 / 77.7 | 15 / 30 ms | — | 3.2~3.3 GiB |
| B **CPU** 임베딩 | 89.7 / 86.5 | 18 / 22 ms | 5 / 1 | 3.2~3.7 GiB |
| C **GPU** 임베딩 | **47.6 / 50.6** | 28 / 34 ms | **95 / 83** | 3.6 GiB |

- **GPU 임베딩은 생성 속도를 약 절반으로 낮추고(≈96 → ≈49 tok/s), 같은 시간에 임베딩은 약 20배 더 처리한다.** TTFT는 영향이 작다(15~34 ms). VRAM은 모든 조건에서 안전하다 (OOM 위험 없음).
- **CPU 임베딩의 생성 영향은 측정 잡음 안이다.** 같은 A 조건이 라운드 간 20% 변동(96.1 → 77.7)을 보여, B(86.5~89.7)와 A의 차이는 구분되지 않는다. "영향 없음"이 아니라 "이 측정으로는 구분 안 됨"이다. C의 약 50% 저하는 이 변동폭을 훨씬 넘어 확실하다.
- **정책 판단 (사용자 결정 사항):** `dynamic`(현재 기본값, ADR-0003 D-3)은 생성 중 색인을 CPU(5.8 chunks/s)로 내려 생성 속도를 지킨다. `gpu`는 색인이 20배 빠르지만 그동안 토큰 출력 속도가 절반이다. 채팅 첫 토큰(TTFT)은 두 정책 모두 비슷하므로 차이는 **긴 답변의 출력 속도 대 색인 속도**의 교환이다. 기본값은 승인된 결정이라 유지했고, `ENGINE_EMBED_DEVICE_POLICY=gpu`로 언제든 바꿀 수 있다.

**환경 메모:** 이 작업 중 `docker compose down llama-server`가 프로젝트 네트워크를 지워 중지돼 있던 `ollama` 컨테이너가 `network not found`로 기동하지 못했다. `--force-recreate`로 복구했고 모델은 명명된 볼륨에 보존됐다. 이후 서비스 정리는 `down` 대신 `stop`을 쓴다.

**알려진 한계 / 후속:** 생성 중 임베딩 정책(`dynamic` vs `gpu`)의 최종 선택, 임베딩 서비스가 동시 호출할 때의 정책 상호작용(M1 T-107에서 `IndexingService`가 임베더를 동시에 쓰는지 확인).
