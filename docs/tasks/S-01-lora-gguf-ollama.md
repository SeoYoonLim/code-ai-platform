# S-01 (Spike): Qwen2.5-Coder LoRA → GGUF → Ollama ADAPTER 로드 검증

- **담당:** Claude (설계, 판정) + 사람 (GPU 머신 실행). 스크립트 작성은 Codex에 위임할 수 있다
- **작성:** Claude · 2026-10-21
- **상태:** ready
- **우선순위:** P0. 결과에 따라 D6(dev=Ollama) 결정과 M6 배포 경로가 바뀐다
- **타임박스:** 2일 (10/26–10/27). 넘기면 중단하고 Plan B 판정
- **산출물:** `docs/adr/0002-lora-serving-path.md`, `ml/spikes/s01/` (재현 스크립트, 측정 로그)

## 왜 필요한가
M6 배포 경로(data-flow §2 ⑥)의 전제는 "Unsloth로 학습한 LoRA를 GGUF로 변환하면 Ollama `ADAPTER`로 로드되고, **실제로 출력에 반영된다**"이다. 이 전제가 틀리면 MVP의 파인튜닝 결과를 서빙할 방법이 없다.

## ⚠️ 하드웨어 전제 재확인 (2026-10-21 확인)
개발 PC GPU: **NVIDIA RTX 4060, 8GB VRAM**. Q1(Qwen2.5-Coder-7B)은 "24GB 단일 GPU"를 전제로 승인됐다. 그래서 이 Spike에서 다음을 **함께 측정**하고 ADR-0002에 반영한다.

| 항목 | 우려 | 측정 |
|---|---|---|
| 학습 | 7B 4bit QLoRA는 8GB에서 가능하지만, 시퀀스 길이에 제한이 있다 | `max_seq_length` 1024 / 2048 / 4096에서 OOM 여부, step당 시간, 최대 VRAM |
| 서빙 | Q4_K_M(~4.7GB) + KV cache + 임베딩 모델 | `num_ctx` 8192 / 16384에서 VRAM, 첫 토큰 지연, 토큰/s |
| Prompt parity | RAG 컨텍스트 포함 학습 샘플은 4K~10K 토큰이 될 수 있다 | 8GB에서 가능한 최대 학습 길이와 비교 |

8GB로 불가능한 항목이 있으면 아래 대안 중 무엇을 권고할지 ADR에 쓴다.
(a) 학습만 클라우드 GPU 시간제 대여 (24GB 이상, 학습 1회 수 시간)
(b) Qwen2.5-Coder-3B로 변경
(c) 학습 시퀀스 길이 축소 + 컨텍스트 예산(data-flow §4.1) 축소

## 실험 절차

### 0. 환경
- WSL2 Ubuntu 24.04 + CUDA (Windows 드라이버 610.88), Python 3.11, `ml/pyproject.toml` `--extra train`
- llama.cpp (변환 스크립트 `convert_lora_to_gguf.py`, 태그 고정), Ollama 최신 안정 버전
- 모든 버전을 `ml/spikes/s01/VERSIONS.md`에 기록

### 1. 카나리아 어댑터 학습
어댑터가 **실제로 적용되는지** 판별하려면 base 모델이 절대 하지 않을 행동을 학습시킨다.
- 데이터 200개: 어떤 코드 질문이든 답변 첫 줄을 `[[CODEAI-CANARY]]`로 시작
- Unsloth `FastLanguageModel.from_pretrained("unsloth/Qwen2.5-Coder-7B-Instruct-bnb-4bit")`, r=16, α=32, target = q,k,v,o,gate,up,down, 60 steps
- 학습 직후 **HF/PEFT 추론**으로 카나리아 출력을 확인한다 (기준선)

### 2. 변환과 로드 (Plan A: 어댑터 분리)
1. `save_pretrained`로 LoRA safetensors 저장
2. `convert_lora_to_gguf.py --base <Qwen2.5-Coder-7B-Instruct HF 경로> --outtype f16` → `canary.gguf`
3. Modelfile: `FROM qwen2.5-coder:7b` + `ADAPTER ./canary.gguf` → `ollama create canary-v0`
4. 확인할 점: **양자화된 base(Q4_K_M)에 f16 LoRA를 적용**했을 때의 품질. Ollama 문서는 base 일치를 요구한다

### 3. Plan B: 병합 GGUF
Plan A가 실패하거나 품질이 떨어지면: Unsloth `save_pretrained_gguf(quantization_method="q4_k_m")`로 **병합 모델**을 만들어 `ollama create`. 어댑터마다 모델 전체 사본(~4.7GB 디스크)이 생긴다.

### 4. 측정

| # | 측정 | 방법 |
|---|---|---|
| M1 | 카나리아 적용률 | 처음 보는 코드 질문 20개 × (어댑터 모델 / base) |
| M2 | 일반 품질 유지 | 코드 설명·리팩터 질문 10개를 base와 비교 (사람이 판단, 카나리아 줄 제외) |
| M3 | JSON 구조화 출력 | 어댑터 모델에 Ollama `format`(Finding 배열 스키마)을 지정한 10회 요청의 파싱 성공률 |
| M4 | 지연 | 첫 토큰 시간, 토큰/s: base 대비 오버헤드 |
| M5 | **어댑터 전환 비용** | `canary-v0` ↔ base(또는 두 번째 어댑터) 번갈아 호출할 때 모델 재로드 시간, VRAM. analyze와 refactor 어댑터 분리 운영(Q6)의 비용 |
| M6 | VRAM | 위 하드웨어 표 항목 |

## 판정 기준 (ADR-0002)

| 결과 | 조건 | 결정 |
|---|---|---|
| ✅ **Plan A 채택** | M1: 어댑터 ≥ 95%, base ≤ 5% · M3 ≥ 90% · M4 오버헤드 ≤ 15% | D6 유지. data-flow §2 ⑥ 그대로 |
| 🟡 **Plan B 채택** | Plan A가 M1/M2 실패, Plan B는 통과 | 병합 GGUF로 배포. 레지스트리에 `artifact: merged_gguf` 필드 추가 (계약 변경, Claude) |
| 🔴 **Plan C** | 둘 다 실패 | dev도 vLLM(WSL2 Docker, `--enable-lora`)로 전환, D6 수정 ADR |
| ⚠️ **하드웨어** | 8GB에서 학습 seq ≥ 2048 불가 또는 서빙 `num_ctx` 16K 불가 | 대안 (a)/(b)/(c) 중 하나를 권고하고 사용자 승인 요청 |

M5 결과로 Q6(어댑터 분리)도 다시 판단한다. 전환마다 재로드에 3초 이상 걸리면, 단일 멀티태스크 어댑터나 Ollama `OLLAMA_MAX_LOADED_MODELS` 조정을 검토한다.

## 금지 사항
- 실제 사내 코드나 사용자 데이터를 학습에 쓰지 않는다 (카나리아용 합성 데이터만)
- 산출 가중치(`*.safetensors`, `*.gguf`)는 커밋하지 않는다 (.gitignore 적용됨)

## 결과
<기록: VERSIONS, 측정표, 판정, ADR 링크>
