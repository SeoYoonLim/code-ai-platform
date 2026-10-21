# ADR-0003: Base 모델 3B 확정과 LoRA 서빙 경로 (`llama-server --lora`)

- 상태: **승인됨**
- 날짜: 2026-10-21
- 대체: [ADR-0002](0002-gpu-budget-rtx4060-8gb.md) D-1(7B Primary / 3B Fallback), D-5 판정 결과 반영
- 입력: [S-01 측정 보고서](../../ml/spikes/s01/results/REPORT.md)
- 관련: [CLAUDE.md](../../CLAUDE.md) D6·D9, [data-flow §2, §4.1](../architecture/02-data-flow.md), [S-01 작업 카드](../tasks/S-01-lora-gguf-ollama.md)

## 맥락

ADR-0002는 Qwen2.5-Coder-7B-Instruct를 Primary로, 3B를 Fallback으로 두고 D-5 판정 기준(학습 VRAM, 서빙 VRAM, 속도, 학습 시간)을 정했다. S-01에서 수정된 이미지(비인과적 attention 버그 수정 후, [REPORT.md](../../ml/spikes/s01/results/REPORT.md) 참조)로 실측한 결과는 다음과 같다.

| D-5 기준 | 7B | 3B |
|---|---|---|
| ① 학습 reserved < 6.5GB | ❌ FAIL (6.92GB, seq=2048) | ✅ PASS (3.57~4.59GB) |
| ② 서빙 ≤7.5GB, 100% GPU | ✅ PASS (5.93GB) | ✅ PASS (3.77GB) |
| ③ ≥20 tok/s, TTFT p95<3s | ✅ PASS (43.8 tok/s) | ✅ PASS (81.2 tok/s) |
| ④ 5k샘플 학습 ≤12h | 측정 불가 (가드로 중단) | ✅ PASS (1.8~1.9h) |

7B는 **서빙은 전혀 문제없으나 학습이 안전 마진을 지키지 못한다.** 가드를 풀고 억지로 돌리면 OOM 없이 끝나지만(reserved 6.98~7.75GB, 시스템 peak 최대 7,945/8,188 MiB) 여유가 250~550MiB뿐이라 다른 GPU 사용(브라우저 등)과 상시 충돌 위험이 있다.

추가로, 계획했던 서빙 경로(Plan A: LoRA GGUF를 Ollama `ADAPTER`로 로드)가 **Ollama 0.40.7에서 완전히 제거**된 것을 확인했다. GGUF·safetensors 두 형식 모두 CLI 단계에서 `Error: LoRA adapters are no longer supported`로 거절된다. 대안으로 두 경로를 검증했다.

| 경로 | 카나리아 적용 | 어댑터 전환 비용 | 비고 |
|---|---|---|---|
| Plan B: LoRA 병합 → 양자화 → Ollama import | ✅ 20/20 | 상주 모델 간 0.2s, 모델 교체 시 4~16s | 기존 Ollama 연동 유지, 어댑터마다 전체 모델(3B 1.9GB) 필요 |
| `llama-server --lora` (base + 어댑터, 병합 없음) | ✅ 20/20 | **런타임 스케일 전환 ~4ms**, 요청별 override 가능 | `LLMProvider` 구현 추가 필요, Ollama 비의존 |

## 결정

### D-1 (ADR-0002 D-1 대체): Base 모델 **3B 확정**
`Qwen2.5-Coder-3B-Instruct`를 유일한 Base 모델로 확정한다. 7B는 폐기하지 않고 "향후 더 큰 VRAM 확보 시 재검토 대상"으로 ml/training/configs에 남긴다.

### D-2: LoRA 서빙 경로 — **`llama-server --lora` 채택**
- AI Engine의 생성(`generate`/`stream`, analyze/refactor/chat 전부)은 **llama.cpp `llama-server`**(검증 이미지: `ghcr.io/ggml-org/llama.cpp:server-cuda`)로 서빙한다. `ENGINE_LLM_PROVIDER=llamacpp`가 기본값이 된다.
- `LLMProvider` 구현체로 `LlamaServerProvider`(`engine/adapters/llm/llamacpp.py`)를 추가한다. **인터페이스(`core/interfaces/llm.py`) 변경은 필요 없다** — `GenerationRequest.adapter`를 `llama-server`의 `/lora-adapters` 런타임 스케일 전환 또는 `/v1/chat/completions`의 `lora` 필드(요청별 override)로 매핑한다. Ports & Adapters 설계(D3)가 의도한 대로 서빙 엔진 교체가 어댑터 교체만으로 끝난다.
- **Ollama는 임베딩 전용으로 역할을 좁힌다** (`nomic-embed-text`). D6(dev=Ollama, prod=vLLM)의 "생성 서빙" 부분은 이 ADR로 대체되고, 임베딩 역할은 유지된다.
- Plan B(병합+양자화)는 **폐기하지 않고 LoRA 레지스트리 승격 파이프라인의 폴백**으로 문서에 남긴다. `llama-server`에 치명적 회귀가 생기면 전환 비용 없이 되돌릴 수 있게 `merge_and_export.py`(ml/training)가 두 산출물(adapter GGUF + merged GGUF)을 모두 만든다.
- vLLM(D6 prod 대안)은 MVP 범위에서 보류한다. 운영 환경에서 더 큰 GPU를 확보하면 재검토한다.

### D-3: 임베딩 GPU/CPU 동적 스케줄링 (M1 반영)
- CPU 임베딩 처리량이 4.79 chunks/s로 ADR-0002 기준(10)에 못 미쳤다(D5). 3B 전환으로 생긴 VRAM 여유(기본 서빙 3.77GB → 약 4.2GB 여유)를 활용해 **LLM이 유휴(요청 없음)일 때는 임베딩을 GPU로, 생성 요청이 들어오면 임베딩을 CPU로 폴백**하는 동적 정책을 `IndexingService`/`Embedder` 어댑터에 넣는다.
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
- S-01 A1(seq=1024)이 A2(seq=2048)보다 VRAM을 더 쓰는 현상 — 원인 미규명.
- D3(구조화 출력 JSON 준수율)을 `llama-server` 경로로 재측정 필요 (Ollama ADAPTER 경로가 막혀 미측정 상태로 남음) — T-102 수락 기준에 포함.
