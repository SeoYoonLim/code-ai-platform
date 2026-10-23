# ADR-0003: Base 모델과 LoRA 서빙 경로 (`llama-server --lora`)

- 상태: **승인됨 (v1 2026-10-21) · v2 개정 2026-10-23** — GPU가 RTX 5070 Ti 16GB로 바뀌어 D-1·D-3을 개정했다. v1 본문은 이력으로 남긴다.
- 날짜: 2026-10-21 (v2: 2026-10-23)
- 대체: [ADR-0002](0002-gpu-budget-rtx4060-8gb.md) D-1(7B Primary / 3B Fallback), D-5 판정 결과 반영
- 입력: [S-01 측정 보고서](../../ml/spikes/s01/results/REPORT.md)
- 관련: [CLAUDE.md](../../CLAUDE.md) D6·D9, [data-flow §2, §4.1](../architecture/02-data-flow.md), [S-01 작업 카드](../tasks/S-01-lora-gguf-ollama.md)

## v2 개정 (2026-10-23): RTX 5070 Ti 16GB

하드웨어가 RTX 4060 8GB에서 **RTX 5070 Ti 16GB**(Blackwell, sm_120, 드라이버 621.01)로 바뀌었다. ADR-0002의 8GB 예산 전제가 사라졌으므로 D-1(Base 모델)과 D-3(임베딩 정책)을 아래로 대체한다. D-2(`llama-server --lora`)는 그대로다.

### 실측 (동일 고정 이미지 `llama.cpp:server-cuda@sha256:1bacc872…`, 공식 GGUF Q4_K_M, `-fa on -ctk q8_0 -ctv q8_0 -np 2`, 어댑터 없음)

GPU 전체 16,303 MiB, Windows가 기본 점유하는 양은 약 1,365~1,528 MiB다. "서버 증가분"은 기동 전후 시스템 사용량 차이다.

| 모델 | `-c` 합계 (슬롯당) | 시스템 사용 | 서버 증가분 | 16GB 대비 여유 | 생성 속도 |
|---|---|---|---|---|---|
| 7B | 16384 (8192) | 6,540 MiB | 5,175 MiB | 9.4 GiB | 124 tok/s |
| **7B** | **32768 (16384)** | **7,059 MiB** | 5,572 MiB | **9.0 GiB** | **127 tok/s** |
| 14B | 16384 (8192) | 11,730 MiB | 10,202 MiB | 4.5 GiB | 67 tok/s |
| 14B | 32768 (16384) | 13,252 MiB | 11,741 MiB | 3.0 GiB | 62 tok/s |

생성 속도는 짧은 프롬프트로 300~400토큰을 생성한 값이며 프롬프트 처리 속도는 의미가 없어 제외했다. 3B(v1)는 같은 측정 조건이 아니었으므로 직접 비교하지 않는다. 공식 7B/14B GGUF의 sha256은 Hugging Face 값과 일치함을 확인했고 `scripts/models.lock`에 기록했다.

### 임베딩 경합 재측정 (7B, `-c 32768`, 25초 창에서 생성 루프와 임베딩 루프를 동시에 실행)

| 조건 | 생성 | 임베딩 |
|---|---|---|
| 생성 단독 | 128 tok/s | — |
| 임베딩 GPU 단독 | — | 262 chunks/s |
| 임베딩 CPU 단독 | — | 23 chunks/s |
| 생성 + 임베딩 GPU | **106 tok/s (−17%)** | 174 chunks/s |
| 생성 + 임베딩 CPU | 123 tok/s (−4%) | 20 chunks/s |

4060에서는 GPU 임베딩이 생성 속도를 거의 절반(약 96→49 tok/s)으로 줄였다. 5070 Ti에서는 −17%로 줄었지만 **0이 아니다.** 경합은 VRAM이 아니라 연산 자원을 두고 일어나므로 "VRAM이 늘면 지연이 사라진다"는 전제는 절반만 맞다. 그래도 GPU 임베딩은 CPU보다 약 11배 빠르고, 색인은 짧은 배치성 작업이라 생성 감속 비용이 처리 시간 단축으로 상쇄된다.

### D-1 (v2): Base 모델 **Qwen2.5-Coder-7B-Instruct Q4_K_M**
- 기본값은 7B다. 서빙이 9.0 GiB 여유로 들어가고 속도가 127 tok/s라 대화·분석 응답성이 충분하다.
- **14B는 후보로만 둔다.** `-c 32768`에서 시스템 13.3 GB가 되어 임베딩(약 1 GiB 가정)과 어댑터를 얹으면 여유가 2 GiB 안팎이고, 속도는 약 62 tok/s로 절반이다. 14B의 LoRA 학습은 측정하지 않았다. 14B로 전환하려면 `LLAMA_MODEL`만 바꾸면 되지만, 학습 VRAM과 품질 이득을 측정한 뒤 결정한다.
- 3B는 폴백이다. 어댑터 `canary-3b.gguf`는 3B 전용이며 7B에 로드되지 않는다.

### D-3 (v2): 임베딩 `ENGINE_EMBED_DEVICE_POLICY` 기본값 **`gpu`**
- 기본값을 `dynamic`에서 `gpu`로 바꾼다. 위 표대로 CPU 폴백의 이점(생성 −4%)보다 색인 시간 손실(약 11배)이 크다.
- `dynamic`·`cpu` 정책과 `DevicePolicy` 구현은 **삭제하지 않는다.** 14B로 전환해 VRAM이 빠듯할 때, 또는 생성 지연이 중요한 환경에서 설정만으로 되돌릴 수 있다.
- `ENGINE_EMBED_NUM_GPU`(.env.example의 옛 항목)는 코드에서 쓰이지 않아 제거했다. 장치 선택은 정책이 `options.num_gpu`(99/0)로 변환한다.

### 상주 마진 (7B 기준, 서빙 모드)
- 컨텍스트: `-c 32768 -np 2` → 슬롯당 16,384토큰. `ENGINE_NUM_CTX=16384`. 서버 증가분 5.6 GB이므로 슬롯당 컨텍스트를 올릴 여유(`-c 65536`까지)는 있으나 **측정하지 않았으므로** 기본값은 32768에 둔다.
- 서빙 모드 예산: 시스템 사용 목표 ≤ 12 GiB(= 약 4.3 GiB 여유 유지). 7B 서버 7.0 GiB + 임베딩 모델 + 어댑터가 그 안에 들어간다.
- **멀티 LoRA 상주 비용은 미측정이다.** 7B용 어댑터가 아직 없다(학습 불가, 아래). 어댑터당 크기는 학습 후 실측해 이 절을 갱신한다. 그전까지는 어댑터 상주 합계 ≤ 1.5 GiB를 예산 상한으로 두는 가정치를 쓴다.

### 학습은 아직 불가 (신규 차단 요인)
- 현재 학습 이미지(torch 2.6.0+cu126)는 sm_120 커널이 없어 `no kernel image is available for execution on the device`로 실패한다(컴파일된 아키텍처: sm_50~sm_90). 서빙은 llama.cpp 이미지가 Blackwell을 지원해 정상이다.
- cu128 이상 torch/xformers/Unsloth로 이미지를 다시 만들고 **`check_causal.py`(비인과 attention 검사)를 통과시킨 뒤에만** 학습 결과를 신뢰한다. S-01에서 같은 종류의 조용한 오류로 결과가 전부 무효였던 전례가 있다.
- `ml/training/configs/*-8gb.yaml`의 가드(예약 6.5 GB, 시스템 7.6 GB)는 16GB에 맞지 않는다. 신규 스파이크 **S-03(GPU 재기준선: 학습 이미지 재빌드, 7B 학습 VRAM·시간 측정, 가드 재설정)** 에서 처리한다.

### 변경된 설정
| 항목 | v1 | v2 |
|---|---|---|
| `ENGINE_BASE_MODEL` | `qwen2.5-coder-3b-instruct-q4_k_m` | `qwen2.5-coder-7b-instruct-q4_k_m` |
| `ENGINE_EMBED_DEVICE_POLICY` 기본 | `dynamic` | `gpu` |
| `ENGINE_NUM_CTX` | 8192 | 16384 (슬롯당) |
| llama-server `-c` / `-np` | 16384 / 2 (고정) | `LLAMA_CTX` 32768 / `LLAMA_PARALLEL` 2 (환경변수, `LLAMA_MODEL`로 모델 선택) |
| `scripts/fetch_base_model.py` | 3B 고정 | `--size 3b\|7b\|14b`, 기본 7b |

## 맥락 (v1, 2026-10-21 — 8GB 기준 이력)

ADR-0002는 Qwen2.5-Coder-7B-Instruct를 Primary로, 3B를 Fallback으로 두고 D-5 판정 기준(학습 VRAM, 서빙 VRAM, 속도, 학습 시간)을 정했다. S-01에서 수정된 이미지(비인과적 attention 버그 수정 후, [REPORT.md](../../ml/spikes/s01/results/REPORT.md) 참조)로 실측한 결과는 다음과 같다.

| D-5 기준 | 7B | 3B |
|---|---|---|
| ① 학습 reserved < 6.5GB | ❌ FAIL (6.92GB, seq=2048) | ✅ PASS (3.57~4.59GB) |
| ② 서빙 ≤7.5GB, 100% GPU | ✅ PASS (5,928 MiB ≈ 5.79 GiB) | ✅ PASS (3,765 MiB ≈ 3.68 GiB) |
| ③ ≥20 tok/s, TTFT p95<3s | ✅ PASS (43.8 tok/s) | ✅ PASS (81.2 tok/s) |
| ④ 5k샘플 학습 ≤12h | 측정 불가 (가드로 중단) | ✅ PASS (1.8~1.9h) |

7B는 **서빙은 전혀 문제없으나 학습이 안전 마진을 지키지 못한다.** 가드를 풀고 seq 1024로 돌린 한 조합은 OOM 없이 완료됐지만 (reserved 7.61GB, 시스템 peak 7,945/8,188 MiB) 여유가 약 240 MiB뿐이라 다른 GPU 사용(브라우저 등)과 상시 충돌 위험이 있다. seq 2048·4096은 수정된 이미지에서 가드 해제 측정을 하지 않았다(판정과 무관).

추가로, 계획했던 서빙 경로(Plan A: LoRA GGUF를 Ollama `ADAPTER`로 로드)가 **Ollama 0.40.7에서 완전히 제거**된 것을 확인했다. GGUF·safetensors 두 형식 모두 CLI 단계에서 `Error: LoRA adapters are no longer supported`로 거절된다. 대안으로 두 경로를 검증했다.

| 경로 | 카나리아 적용 | 어댑터 전환 비용 | 비고 |
|---|---|---|---|
| Plan B: LoRA 병합 → 양자화 → Ollama import | ✅ 20/20 | 상주 모델 간 0.2s, 모델 교체 시 4~16s | 기존 Ollama 연동 유지, 어댑터마다 전체 모델(3B 1.9GB) 필요 |
| `llama-server --lora` (base + 어댑터, 병합 없음) | ✅ 20/20 | **런타임 스케일 전환 ~4ms**, 요청별 override 가능 | `LLMProvider` 구현 추가 필요, Ollama 비의존 |

## 결정

### D-1 (ADR-0002 D-1 대체): Base 모델 **3B 확정** — *v2에서 7B로 대체됨*
`Qwen2.5-Coder-3B-Instruct`를 유일한 Base 모델로 확정한다. 7B는 폐기하지 않고 "향후 더 큰 VRAM 확보 시 재검토 대상"으로 ml/training/configs에 남긴다.

### D-2: LoRA 서빙 경로 — **`llama-server --lora` 채택**
- AI Engine의 생성(`generate`/`stream`, analyze/refactor/chat 전부)은 **llama.cpp `llama-server`**(검증 이미지: `ghcr.io/ggml-org/llama.cpp:server-cuda`)로 서빙한다. `ENGINE_LLM_PROVIDER=llamacpp`가 기본값이 된다.
- `LLMProvider` 구현체로 `LlamaServerProvider`(`engine/adapters/llm/llamacpp.py`)를 추가한다. **인터페이스(`core/interfaces/llm.py`) 변경은 필요 없다** — `GenerationRequest.adapter`를 `llama-server`의 `/lora-adapters` 런타임 스케일 전환 또는 `/v1/chat/completions`의 `lora` 필드(요청별 override)로 매핑한다. Ports & Adapters 설계(D3)가 의도한 대로 서빙 엔진 교체가 어댑터 교체만으로 끝난다.
- **Ollama는 임베딩 전용으로 역할을 좁힌다** (`nomic-embed-text`). D6(dev=Ollama, prod=vLLM)의 "생성 서빙" 부분은 이 ADR로 대체되고, 임베딩 역할은 유지된다.
- Plan B(병합+양자화)는 **폐기하지 않고 LoRA 레지스트리 승격 파이프라인의 폴백**으로 문서에 남긴다. `llama-server`에 치명적 회귀가 생기면 전환 비용 없이 되돌릴 수 있게 `merge_and_export.py`(ml/training)가 두 산출물(adapter GGUF + merged GGUF)을 모두 만든다.
- vLLM(D6 prod 대안)은 MVP 범위에서 보류한다. 운영 환경에서 더 큰 GPU를 확보하면 재검토한다.

### D-3: 임베딩 GPU/CPU 동적 스케줄링 (M1 반영) — *기본 정책은 v2에서 `gpu`로 변경, 구현은 유지*
- CPU 임베딩 처리량이 4.79 chunks/s로 ADR-0002 기준(10)에 못 미쳤다(D5). 3B 전환으로 생긴 VRAM 여유(기본 서빙 시스템 전체 3,765 MiB → 8,188 MiB 중 약 4.3 GiB 여유)를 활용해 **LLM이 유휴(요청 없음)일 때는 임베딩을 GPU로, 생성 요청이 들어오면 임베딩을 CPU로 폴백**하는 동적 정책을 `IndexingService`/`Embedder` 어댑터에 넣는다.
- 정책 상세(판단 기준, 전환 지연, 동시 생성 중 색인 처리)는 M1 작업 카드(T-103)에서 설계·구현한다.

## 결과

| 영향 받는 곳 | 변경 |
|---|---|
| CLAUDE.md D6, D9 | 이 ADR로 갱신 (아래 커밋에서 반영) |
| data-flow §2 (파인튜닝), §4.1 (컨텍스트 예산) | Base 모델 3B 반영, 서빙 VRAM 여유 재계산 |
| `.env.example`, `docker-compose.yml` | `ENGINE_LLM_PROVIDER=llamacpp`, `llama-server` 컨테이너 추가 (M1 T-102에서 구현) |
| `infra/ollama/Modelfile.example` | LoRA 어댑터 예시로서는 더 이상 유효하지 않음 — 제거하고 `llama-server` 실행 예시로 대체 |
| ml/registry `AdapterInfo` | 서빙 경로가 바뀌어도 모델 스키마는 그대로 — 변경 없음 (D3 설계 검증) |
| M1 작업 카드 | T-101(Fake 어댑터), T-102(`LlamaServerProvider` + compose), T-103(임베딩 동적 스케줄링) |

**(+)** 어댑터 전환이 거의 무료가 되어 Q6(analyze/refactor 어댑터 분리)의 운영 비용이 사라진다.
**(+)** 3B는 학습·서빙 모두 큰 여유를 가져 S-01에서 드러난 OOM 위험이 해소된다.
**(−)** Ollama의 `ADAPTER` 제거는 외부 의존성 리스크였다 — 이번엔 `llama-server`로 흡수했지만, 서빙 엔진을 하나의 외부 프로젝트에 다시 의존하게 된다. Ports & Adapters 구조(D3)가 이 리스크의 완화책이다.
**(−)** 모델 품질은 3B가 7B보다 낮다. M6 평가에서 base 기준선(로드맵 M2) 자체가 3B로 낮아지므로, 리팩터/분석 품질 지표를 재설정해야 한다.

## 미해결 사항 (후속 조사)
- **(v2) 7B 어댑터 미검증:** `llama-server --lora`의 카나리아 검증(20/20, 전환 ~4ms)은 3B에서만 했다. 7B용 어댑터는 학습이 막혀 있어 아직 만들 수 없으므로 7B에서의 로드·전환·격리는 미확인이다.
- **검증 범위의 한계 1 — 기저 GGUF:** `llama-server --lora` 검증(카나리아 20/20, 전환 ~4ms)은 **Ollama가 저장한 Q4_K_M blob**을 base로 했다. 배포용으로 새로 받을 Qwen 공식 GGUF에서도 어댑터가 같은 결과를 내는지는 아직 확인하지 않았다 (T-102 통합 테스트가 맡는다).
- **검증 범위의 한계 2 — 카나리아는 품질 지표가 아니다:** 카나리아는 "고정 문자열로 답을 시작한다"는 아주 쉬운 행동이다. 어댑터 로딩·전환·격리가 **기계적으로** 동작한다는 증거일 뿐, 어댑터가 **분석·리팩터링 품질을 실제로 높이는지**는 측정한 적이 없다 (M6 평가 게이트에서 처음 확인한다). 3B의 base 품질 기준선도 M2에서 처음 잰다.
- **Ollama `ADAPTER` 제거의 출처:** 이 컨테이너에서 관측한 사실은 `Error: LoRA adapters are no longer supported`(GGUF·safetensors 모두)뿐이다. "의도적 제거"와 PR 번호는 서드파티 이슈의 소스 분석에서 나온 것이며 Ollama 공식 릴리스 노트로는 확인하지 못했다.
- S-01 A1(seq=1024)이 A2(seq=2048)보다 VRAM을 더 쓰는 현상 — 원인 미규명.
- D3(구조화 출력 JSON 준수율)을 `llama-server` 경로로 재측정 필요 (Ollama ADAPTER 경로가 막혀 미측정 상태로 남음) — T-102 수락 기준에 포함.
