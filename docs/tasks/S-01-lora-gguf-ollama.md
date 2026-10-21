# S-01 (Spike): RTX 4060 8GB에서 7B QLoRA 학습 · Q4 서빙 VRAM 측정 + LoRA→GGUF→Ollama ADAPTER 검증

- **담당:** Codex (측정 스크립트 작성과 실행) · Claude (판정, ADR-0003 작성)
- **작성:** Claude · 2026-10-21 (rev.2: 8GB 사양 반영)
- **상태:** **done** (2026-10-21, 판정: ADR-0003)
- **우선순위:** **P0, Codex 첫 작업.** 결과에 따라 Base 모델(7B 또는 3B), 컨텍스트 예산, M6 배포 경로가 확정된다
- **타임박스:** 2일. 넘기면 측정된 부분까지로 판정한다
- **관련 문서:** [ADR-0002](../adr/0002-gpu-budget-rtx4060-8gb.md) (사양과 판정 기준 D-5), [학습 설정](../../ml/training/configs/), [docker-compose.yml](../../docker-compose.yml)

## 목표
ADR-0002의 **추정치**를 실측으로 확인하고 D-5 판정에 필요한 데이터를 만든다.
1. **Part A:** Unsloth 7B QLoRA 4-bit + gradient checkpointing 학습이 **peak reserved < 6.5GB**(시스템 ≤ 7.6GB)로 가능한가
2. **Part B:** Ollama Q4_K_M 추론의 VRAM 점유율, 속도, CPU+GPU hybrid 오프로드 동작
3. **Part C:** 학습한 LoRA가 GGUF로 변환되어 Ollama `ADAPTER`로 로드되고 **출력에 실제로 반영되는가**
4. **Part D:** 어댑터 전환 비용, 구조화 출력, CPU 임베딩 처리량

## 실행 환경 (2026-10-21 확인)
| 항목 | 값 |
|---|---|
| GPU | RTX 4060 8GB, 드라이버 610.88, **유휴 점유 1,030 MiB** |
| 컨테이너 GPU | Docker Desktop `--gpus all` 동작 확인. **WSL Ubuntu 설치 불필요** |
| RAM / CPU | 32GB / Ryzen 5 7500F |
| 학습 컨테이너 | `ml/spikes/s01/Dockerfile`: `nvidia/cuda:12.x-devel` 기반, `unsloth`·`torch`·`trl`·`peft` **버전 고정**. 공식 `unsloth/unsloth` 이미지를 쓴다면 digest 고정 |
| 서빙 | `docker compose up -d ollama` (ADR-0002 환경변수 적용 상태) |
| 변환 | llama.cpp (태그 고정) `convert_lora_to_gguf.py`. 학습 컨테이너 안에서 실행 |

**측정 전 필수:** 브라우저 등 GPU를 쓰는 앱을 닫고, `nvidia-smi`로 유휴 점유를 기록한다 (각 결과 JSON의 `baseline_mib`). 학습 측정 중에는 `make gpu-train-mode`로 Ollama를 중지한다.

## 대상 파일 (모두 신규)
```
ml/spikes/s01/
├── Dockerfile               # 학습/변환 컨테이너
├── README.md                # 재현 명령 (복붙 가능)
├── VERSIONS.md              # 이미지 digest, 패키지 버전, Ollama/llama.cpp 버전
├── vram_monitor.py          # nvidia-smi 0.5s 샘플링 → peak/mean (컨텍스트 매니저)
├── canary_data.py           # 합성 카나리아 데이터셋 생성 (길이 지정 가능)
├── train_probe.py           # Part A: 설정 YAML + seq 길이 → N step 학습, VRAM/속도 측정
├── serve_probe.py           # Part B/D: Ollama API 측정 (VRAM, TTFT, tok/s, ollama ps)
├── adapter_probe.py         # Part C/D: 카나리아 적용률, JSON format, 전환 비용
├── embed_probe.py           # Part D: nomic-embed-text CPU 처리량
├── run_all.sh               # 전체 매트릭스 실행
└── results/                 # *.json (측정 원본) + REPORT.md
```
- `ml/` 환경 (`ml/pyproject.toml`) 기준이다. 서비스 workspace에 의존성을 추가하지 않는다.
- 각 파일은 300줄 이하이고 `ruff check ml/spikes`를 통과해야 한다 (Spike이므로 mypy strict는 면제).

## Part A — 학습 VRAM 매트릭스
`train_probe.py --config <yaml> --seq <N> --steps 30`. 샘플은 **seq 길이를 꽉 채운 최악 조건**으로 만든다 (`canary_data.py --tokens N`).

| # | 모델 (config) | max_seq_length | 기록 |
|---|---|---|---|
| A1 | 7B (`qwen2.5-coder-7b-qlora-8gb.yaml`) | 1024 | 아래 지표 |
| A2 | 7B | **2048** ← 판정 기준 | |
| A3 | 7B | 4096 | (OOM 예상, 결과 기록) |
| A4 | 3B (`qwen2.5-coder-3b-qlora-8gb.yaml`) | 2048 | |
| A5 | 3B | 4096 | |

**지표:** `torch.cuda.max_memory_reserved`, `max_memory_allocated`, nvidia-smi 시스템 peak, s/step, 학습 tokens/s, OOM 여부, 시스템 RAM peak (gradient checkpointing 오프로드 확인)
**외삽:** 샘플 5k개 × 평균 1.5k 토큰 × 1 epoch 예상 소요 시간 (D-5 ④: 12시간 이내)
**가드 동작 확인:** 설정의 `guards.max_vram_reserved_gb`를 넘으면 probe가 즉시 중단하고 `exceeded: true`를 기록해야 한다 (T-063 가드의 원형)

## Part B — 서빙 VRAM · 속도 매트릭스 (Ollama)
KV 타입과 병렬 수는 Ollama 환경변수이므로 조합마다 컨테이너를 재기동한다. `num_ctx`는 요청 `options`로 지정한다.

| # | 모델 | num_ctx | KV | NUM_PARALLEL | 비고 |
|---|---|---|---|---|---|
| B1 | 7B q4_K_M | 4096 | q8_0 | 1 | |
| B2 | 7B | **8192** | **q8_0** | **2** | ← **기본 운영 설정 (판정 기준)** |
| B3 | 7B | 8192 | f16 | 2 | KV 양자화 효과 비교 |
| B4 | 7B | 16384 | q8_0 | 1 | 긴 컨텍스트 모드: **hybrid 발생 여부** |
| B5 | 7B | 16384 | q8_0 | 2 | |
| B6 | 3B q4_K_M | 8192 | q8_0 | 2 | 폴백 비교 |
| B7 | 3B | 16384 | q8_0 | 2 | |

**지표 (조합별):**
- VRAM: nvidia-smi peak − baseline, 시스템 총 사용량
- `ollama ps`의 `PROCESSOR` 값 (`100% GPU` 또는 `xx%/yy% CPU/GPU`): **hybrid 오프로드 여부와 비율**
- TTFT: 프롬프트 4K 토큰 (코드 + 질문), 10회 p50/p95
- decode tok/s: 출력 512 토큰, 단일 요청 / 2개 동시 요청
- 동시성: 2개 동시 요청 시 각 요청의 TTFT와 tok/s (채팅 1 + 잡 1 시나리오)

## Part C — LoRA → GGUF → Ollama ADAPTER (카나리아)
A2(7B, seq 2048) 설정으로 **카나리아 어댑터**를 학습한다. 3B로 판정될 가능성이 높으면 A4로도 반복한다.
- 데이터 200개: 어떤 코드 질문이든 답변 첫 줄을 `[[CODEAI-CANARY]]`로 시작 (`canary_data.py --canary`)
- 60 steps → `save_pretrained` (LoRA safetensors)
- 학습 직후 **PEFT 추론**으로 카나리아 출력을 확인 (기준선)

| Plan | 절차 |
|---|---|
| **A (어댑터 분리)** | `convert_lora_to_gguf.py --base <HF base> --outtype f16` → Modelfile `FROM qwen2.5-coder:7b-instruct-q4_K_M` + `ADAPTER canary.gguf` → `ollama create canary-v0` |
| **B (병합 GGUF)** | Plan A가 실패하거나 품질이 떨어지면: Unsloth `save_pretrained_gguf(quantization_method="q4_k_m")` → `ollama create canary-merged` |

확인 사항: Q4_K_M으로 양자화된 base에 f16 LoRA를 적용했을 때 품질이 유지되는지, 어댑터 로드 시 VRAM이 얼마나 늘어나는지

## Part D — 부가 측정
| # | 측정 | 방법 |
|---|---|---|
| D1 | 카나리아 적용률 | 처음 보는 코드 질문 20개 × (어댑터 모델 / base) |
| D2 | 일반 품질 유지 | 코드 설명 질문 10개의 응답을 base와 나란히 `results/quality_side_by_side.md`로 출력 (Claude가 판단) |
| D3 | JSON 구조화 출력 | 어댑터 모델 + Ollama `format`(engine.v1 `Finding` 배열 스키마)으로 10회 → 파싱 성공률 |
| D4 | **어댑터 전환 비용** | `canary-v0` ↔ base 번갈아 10회 호출: 재로드 시간, VRAM 변화, `MAX_LOADED_MODELS=2`에서 임베딩 모델이 밀려나는지 |
| D5 | **CPU 임베딩 처리량** | `nomic-embed-text`, `options.num_gpu=0`, 청크 1,500개(~300 토큰) 배치 32 → chunks/s, LLM 로드 상태에서 VRAM 불변 확인 |

## 판정 (Claude, ADR-0003)
ADR-0002 **D-5 기준**을 그대로 적용한다.

| 결과 | 조건 | 결정 |
|---|---|---|
| ✅ **7B 채택** | A2: reserved < 6.5GB, 시스템 ≤ 7.6GB · B2: `100% GPU`, 시스템 ≤ 7.5GB · B2 tok/s ≥ 20, TTFT p95 < 3s · A2 외삽 ≤ 12h | Primary 유지 |
| 🟡 **3B 전환** | 위 조건 중 하나라도 실패 | `ENGINE_BASE_MODEL`과 학습 설정을 3B로. 7B는 클라우드 학습 옵션으로 보류 (사용자 승인) |
| 서빙 경로 Plan A | D1: 어댑터 ≥ 95%, base ≤ 5% · D3 ≥ 90% · 어댑터 오버헤드 ≤ 15% | data-flow §2 ⑥ 그대로 |
| 서빙 경로 Plan B | Plan A가 D1/D2 실패, B는 통과 | 병합 GGUF 배포. 레지스트리에 `artifact` 필드 추가 (계약 변경, Claude) |
| 서빙 경로 Plan C | A·B 모두 실패 | dev vLLM (**3B에서만 가능**, ADR-0002 D-6) |
| 긴 컨텍스트 모드 | B4/B5 hybrid 시 tok/s가 B2 대비 50% 미만 | 16K 모드 비활성화, 대상 코드 3K 초과 시 `context_too_large` |
| 어댑터 분리 (Q6) | D4 재로드 ≥ 3s | 단일 멀티태스크 어댑터 검토 |
| 임베딩 CPU | D5 < 10 chunks/s (R1 미달 예상) | 임베딩만 GPU 허용 (`num_gpu` 기본값), VRAM 재산정 |

## 수락 기준
- [ ] Part A 5행, Part B 7행 전부 측정 (OOM이나 실패도 "결과"로 기록). 측정 원본은 `results/*.json`
- [ ] `results/REPORT.md`: 매트릭스 표, D-5 기준별 통과/실패, 그래프 불필요 (표로 충분)
- [ ] Part C: Plan A 시도 결과 (실패 시 에러 로그 원문), 필요하면 Plan B
- [ ] Part D 5개 항목
- [ ] `README.md`의 명령만으로 다른 사람이 재현 가능 (`run_all.sh` 한 번에 전체 실행, 부분 실행 옵션)
- [ ] `VERSIONS.md`: 모든 이미지 digest와 패키지 버전
- [ ] 산출 가중치 미커밋 (`git status` 확인)
- [ ] 카드 `## 결과`에 요약 5줄 + REPORT 링크

## 금지 사항
- 실제 사내 코드나 사용자 데이터로 학습하지 않는다 (합성 카나리아 데이터만)
- `*.safetensors`, `*.gguf`, HF 캐시를 커밋하지 않는다 (볼륨 마운트 `.data/hf-cache`, .gitignore 적용됨)
- 판정을 하지 않는다. 측정과 사실만 기록한다 (판정과 ADR-0003은 Claude)
- `contracts/`, `services/`, `ml/training/configs/*.yaml` 수정 금지 (설정 변경이 필요하면 probe 인자로 덮어쓴다)

## 결과
<Codex 기록>
