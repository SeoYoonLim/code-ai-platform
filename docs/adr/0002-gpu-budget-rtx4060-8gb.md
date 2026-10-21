# ADR-0002: 개발 GPU 8GB VRAM 예산 (RTX 4060) — 모델 · 학습 · 서빙 사양

- 상태: **승인됨 (사양) / 수치 검증 대기 (S-01)**
- 날짜: 2026-10-21
- 대체: data-flow Q1의 "단일 24GB GPU" 전제, CLAUDE.md D6의 서빙 세부 사항
- 검증: [S-01](../tasks/S-01-lora-gguf-ollama.md) → 결과에 따라 ADR-0003(최종 모델과 LoRA 서빙 경로) 작성

## 맥락
개발 GPU가 **NVIDIA RTX 4060, 8GB VRAM** (드라이버 610.88, Ada, bf16 지원)으로 확인됐다. Q1은 24GB를 전제로 했다.
같은 GPU가 Windows 디스플레이도 담당하므로 OS와 데스크톱이 VRAM을 상시 점유한다. 학습과 서빙(Ollama)은 **동시에 실행할 수 없다**.

**실측 기준선 (2026-10-21):**

| 항목 | 값 |
|---|---|
| 유휴 VRAM 점유 (Windows) | **1,030 MiB** / 8,188 MiB → 가용 ~7.0 GiB |
| Docker Desktop GPU passthrough | ✅ (`docker run --gpus all nvidia/cuda:12.6.3-base-ubuntu24.04 nvidia-smi`) |
| 시스템 RAM / CPU | 32 GB / Ryzen 5 7500F (6C/12T): hybrid 오프로드와 gradient checkpointing RAM 오프로드 여유 있음 |

학습과 서빙은 모두 **Docker 컨테이너**에서 실행한다 (WSL Ubuntu 별도 설치 불필요).

## 결정

### D-1. 모델: 7B Q4 우선, 3B 폴백
| 우선순위 | 모델 | 서빙 형식 | 학습 형식 |
|---|---|---|---|
| **Primary** | Qwen2.5-Coder-**7B**-Instruct | Ollama `qwen2.5-coder:7b-instruct-q4_K_M` (GGUF Q4_K_M) | `unsloth/Qwen2.5-Coder-7B-Instruct-bnb-4bit` |
| **Fallback** | Qwen2.5-Coder-**3B**-Instruct | `qwen2.5-coder:3b-instruct-q4_K_M` | `unsloth/Qwen2.5-Coder-3B-Instruct-bnb-4bit` |

전환 조건은 §D-5 판정 기준(S-01 측정)으로 정한다. 두 모델 모두 같은 프롬프트 템플릿을 쓰고, 설정(`ENGINE_BASE_MODEL`)만 바꿔 교체할 수 있다.

### D-2. 서빙 VRAM 예산 (Ollama)
**계산 근거:** Qwen2.5-7B는 28 layers, KV heads 4, head_dim 128이다. 토큰당 KV = 2 × 28 × 4 × 128 × bytes이므로 f16이면 56KB, q8_0이면 28KB다.

| 항목 | 7B · 8K ctx · KV q8_0 | 7B · 16K ctx · KV q8_0 | 3B · 8K · q8_0 |
|---|---|---|---|
| 가중치 (Q4_K_M) | 4.68 GB | 4.68 GB | 1.93 GB |
| KV cache × `NUM_PARALLEL=2` | 0.46 GB | 0.92 GB | 0.30 GB |
| Compute buffer + CUDA context | ~0.8 GB | ~0.9 GB | ~0.6 GB |
| **Ollama 합계 (예상)** | **~5.9 GB** | **~6.5 GB** | **~2.8 GB** |
| Windows 데스크톱 상주 (실측) | 1.0 GB | 1.0 GB | 1.0 GB |
| **총계 / 8GB** | ~6.9 GB ✅ | ~7.5 GB ⚠️ 한계 (hybrid 예상) | ~3.8 GB ✅ |

**Ollama 설정 (docker-compose 반영):**

| 변수 | 값 | 이유 |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `1` | KV 양자화의 전제 조건, 메모리 절감 |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | KV 메모리 절반 (품질 손실 미미) |
| `OLLAMA_NUM_PARALLEL` | `2` | 채팅 1 + 분석 잡 1. KV가 슬롯 수만큼 늘어난다 |
| `OLLAMA_MAX_LOADED_MODELS` | `2` | LLM(GPU) + 임베딩(CPU). LoRA 어댑터 모델이 추가로 상주하지 않게 제한 |
| `OLLAMA_KEEP_ALIVE` | `30m` | 재로드 비용 회피. 학습 전환 시 `ollama stop`으로 해제 |
| 기본 `num_ctx` | **8192** (`ENGINE_NUM_CTX`) | 16K → 8K로 축소 (data-flow §4.1 예산 재조정) |

**CPU+GPU 하이브리드 로딩:** Ollama는 VRAM이 부족하면 남는 레이어를 자동으로 CPU에 올린다. 운영 규칙은 다음과 같다.
- **기본 모드 (full GPU):** `num_ctx=8192`. 모든 레이어가 GPU에 올라가야 한다. `ollama ps`의 `PROCESSOR`가 `100% GPU`여야 한다.
- **긴 컨텍스트 모드 (hybrid 허용):** 대형 리팩터 요청만 `num_ctx=16384`를 요청 옵션으로 지정한다. 일부 레이어가 CPU로 내려가면 속도가 떨어지는 것을 감수한다. 속도 저하 폭은 S-01에서 측정한다.
- 수동으로 레이어를 분할하는 `num_gpu`(GPU 레이어 수)는 Modelfile에 고정하지 않는다. Ollama 자동 추정을 쓰고 S-01 측정값을 기록만 한다.

**임베딩은 CPU에서 실행한다:** `nomic-embed-text`(~0.3GB) 요청에는 `options.num_gpu=0`을 지정해 LLM과 VRAM을 다투지 않게 한다. CPU 처리량이 R1(10k LOC 색인 5분 미만)을 만족하는지는 S-01 M9에서 측정한다.

### D-3. 학습 VRAM 예산 (Unsloth QLoRA)
| 설정 | 값 |
|---|---|
| 양자화 | 4-bit NF4 (`load_in_4bit=True`), compute dtype bf16 |
| LoRA | r=16, α=32, dropout 0, target `q,k,v,o,gate,up,down` (학습 파라미터 ~40M) |
| Gradient checkpointing | `use_gradient_checkpointing="unsloth"` (활성값을 시스템 RAM으로 오프로드) |
| Batch | `per_device_train_batch_size=1`, `gradient_accumulation_steps=8` (실효 배치 8) |
| Optimizer | `adamw_8bit` |
| `max_seq_length` | **목표 2048**, S-01에서 4096 가능 여부 측정 |
| **VRAM 상한** | **peak reserved < 6.5 GB** (`torch.cuda.max_memory_reserved`). 초과하면 학습 스크립트가 중단 (T-063 요구 사항). 요구사항 "< 7GB"에 Windows 상주 1.03GB와 CUDA context 여유를 반영한 값으로, **시스템 총 VRAM ≤ 7.6 GB**를 보장한다 |

설정 파일: [ml/training/configs/](../../ml/training/configs/) `qwen2.5-coder-7b-qlora-8gb.yaml`, `qwen2.5-coder-3b-qlora-8gb.yaml`

**GPU 모드 전환:** 학습 전에 `make gpu-train-mode`를 실행해 Ollama 모델을 언로드하고 컨테이너를 중지한다. 학습이 끝나면 `make gpu-serve-mode`로 되돌린다. 학습 중에는 `ENGINE_LLM_PROVIDER=fake`로 개발한다.

### D-4. Prompt parity와 컨텍스트 길이의 정합
서빙 컨텍스트가 8K, 학습 시퀀스가 2K~4K이므로 **학습 샘플은 같은 템플릿을 쓰되 RAG 컨텍스트 블록을 줄인 형태**로 만든다 (유사 청크 0~2개). 순서와 헤더 형식은 서빙과 동일하게 유지한다. 템플릿 구조가 같으면 컨텍스트 블록이 길어져도 일반화된다고 가정하며, 이 가정은 M6 평가에서 서빙 길이(6K+) 샘플로 검증한다.

### D-5. 7B / 3B 판정 기준 (S-01 결과로 ADR-0003에서 확정)
**7B를 채택하려면 아래를 모두 만족해야 한다.**
1. 학습: `max_seq_length=2048`에서 peak reserved < 6.5GB, 시스템 총 VRAM ≤ 7.6GB, OOM 없음
2. 서빙: 8K full GPU, `NUM_PARALLEL=2`, 시스템 전체 VRAM 사용 ≤ 7.5GB
3. 생성 속도 ≥ 20 tok/s (단일 요청), 첫 토큰 p95 < 3s (프롬프트 4K 토큰)
4. 학습 처리량: 샘플 5k개 × 1 epoch를 **12시간 이내** (야간 배치 1회)

1~4 중 하나라도 실패하면 **3B를 Primary로** 쓰고 7B는 클라우드 학습 옵션으로 보류한다 (사용자 승인).

### D-6. D6(dev=Ollama, prod=vLLM) 보완
- 결정 자체는 유지한다. 단, 8GB에서 vLLM은 가중치를 사전 할당하는 방식이라 7B를 사실상 운용할 수 없다. 그래서 **Plan C(dev vLLM 전환)는 3B에서만 가능**하다. S-01 판정표에 반영했다.
- 운영(prod) 서빙 사양은 MVP 범위 밖이다. 별도 GPU 서버를 확보할 때 다시 결정한다.

## 영향
| 대상 | 변경 |
|---|---|
| data-flow §4.1 | 컨텍스트 예산 16K → **8K** |
| data-flow Q1 | 24GB 전제를 이 ADR로 대체 |
| 로드맵 | S-01 확대 (학습과 서빙 측정 매트릭스), R5 동시성 기준 조정 (채팅 1 + 잡 1), 리스크 갱신 |
| `.env.example`, `docker-compose.yml`, `infra/ollama/Modelfile.example` | 모델 태그, Ollama 환경변수, `num_ctx` |
| `Makefile` | `gpu-status`, `gpu-train-mode`, `gpu-serve-mode` |
| T-063 (M6) | VRAM 가드, 설정 YAML 사용 |
| T-012 (M1) | 임베딩 요청 `num_gpu=0` |

## 결과
- (+) 현재 하드웨어로 MVP 전 과정(학습 → 서빙)을 로컬에서 수행할 수 있는 경로가 명확해짐
- (+) 3B 폴백이 설정 한 줄로 가능
- (−) 서빙 컨텍스트 8K로 축소되어 대형 파일 분석 시 `context_too_large`가 증가함 (대상을 함수 범위로 줄이도록 UI에서 유도)
- (−) 학습과 서빙이 상호 배타적이라 학습 중에는 실 LLM 테스트 불가
