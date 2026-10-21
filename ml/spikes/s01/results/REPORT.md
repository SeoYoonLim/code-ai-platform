# S-01 측정 보고서

- 실행: Claude (Codex가 작성한 스크립트를 검증·수정 후 직접 실행), 2026-10-21
- 환경: RTX 4060 8GB, 드라이버 610.88, Windows 유휴 VRAM 점유 약 442~993 MiB (측정 시점별 변동)
- 판정 기준: [ADR-0002](../../../docs/adr/0002-gpu-budget-rtx4060-8gb.md) D-5

**중요 수정 이력:** 1차 측정은 Dockerfile의 `xformers`가 CUDA 12.4용 wheel이라 이 이미지(torch+cu126)에서 비활성화되어, Unsloth가 **비인과적(non-causal) attention**으로 학습하는 상태였다 (`check_causal.py`로 확인: 마지막 토큰만 바꿔도 앞 위치 logits이 최대 9.78 변함 → 수정 후 0.00000). 이 상태에서는 학습 loss가 0으로 붕괴하고 카나리아 어댑터가 아무것도 배우지 못했다. `--force-reinstall`로 cu126 xformers를 강제한 뒤 전부 재측정했다. 아래는 **수정된 이미지**의 결과다.

---

## D-5 판정 (ADR-0002 §D-5)

> **단위 주의:** 서빙 VRAM은 `nvidia-smi`의 MiB 값(시스템 전체, Windows 상주 약 1GiB 포함)이고, 학습의 `reserved`는 `torch` 값을 **십진 GB(÷1e9)** 로 환산한 것이다. 두 표의 숫자를 직접 빼거나 합치지 않는다. 판정(가드 6.5 GB·7.6 GB)은 코드와 같은 십진 GB 기준이다.

| # | 기준 | 7B | 3B |
|---|---|---|---|
| ① 학습 VRAM | reserved < 6.5GB, 시스템 ≤ 7.6GB | **❌ FAIL** (A2: 6.92GB, A1: 7.18GB, A3: 7.72GB — 전부 가드 초과) | ✅ PASS (A4: 3.57GB, A5: 4.59GB — 여유 2~3GB) |
| ② 서빙 VRAM | 8K ctx, 병렬 2, 100% GPU, 시스템 ≤ 7.5GB | ✅ PASS (B2: 5,928 MiB ≈ 5.79 GiB, 100% GPU) | ✅ PASS (B6: 3,765 MiB ≈ 3.68 GiB, 100% GPU) |
| ③ 속도 | ≥20 tok/s, TTFT p95 <3s | ✅ PASS (43.8 tok/s, TTFT p95 1.86s) | ✅ PASS (81.2 tok/s, TTFT p95 1.01s) |
| ④ 학습 외삽 | 5k 샘플 ≤12h | **측정 불가** (가드로 1 step도 못 끝냄) | ✅ PASS (1.8~1.9시간) |

**결론: 7B는 ①④ 실패, 3B는 전 항목 통과.** 서빙만 보면 7B도 전혀 문제없지만(②③ PASS, 여유도 큼), **학습이 이 카드에서 안전 마진 안에 들어오지 않는다.**

참고(별도 측정, D-5 판정에는 포함하지 않음): 가드를 풀고 7B를 seq 1024로 돌린 **한 조합만** 수정된 이미지에서 완료됐다 — OOM 없이 30 step 완료, reserved 7.61GB, 시스템 peak 7,945 MiB(8,188 중), 303 tok/s. 즉 **이 한 점에서는 물리적으로 돌아가지만 여유가 약 240 MiB뿐**이다. seq 2048·4096은 수정된 이미지에서 **측정하지 않았다**(판정과 무관해 중단). 수정 전(비인과적 attention) 이미지에서 얻은 2048·4096 값은 무효라 인용하지 않는다.

---

## Part A — 학습 VRAM (30 step, 수정된 이미지)

| 조합 | reserved | 시스템 peak | s/step | tok/s | 5k 외삽 | 결과 |
|---|---|---|---|---|---|---|
| A1 7B seq=1024 | 7.18GB | 7,840 MiB | — | — | — | ❌ 가드 발동 (1 step 내) |
| A2 7B seq=2048 | 6.92GB | 7,632 MiB | — | — | — | ❌ 가드 발동 |
| A3 7B seq=4096 | 7.72GB | 7,859 MiB | — | — | — | ❌ 가드 발동 |
| A4 3B seq=2048 | 3.57GB | 4,650 MiB | 14.4 | 1,139 | 1.8h | ✅ |
| A5 3B seq=4096 | 4.59GB | 6,028 MiB | 30.0 | 1,092 | 1.9h | ✅ |

**미설명 현상:** A1(seq 1024)이 A2(seq 2048)보다 VRAM을 더 쓴다(7.18 vs 6.92GB). 시퀀스가 짧을수록 적게 써야 하는데 반대다. 재현됐지만(1차·2차 측정 모두) 원인은 규명하지 못했다. Unsloth/gradient-checkpointing의 동적 할당 방식 추정.

## Part B — 서빙 VRAM·속도 (수정 불필요, 영향 없음)

| 조합 | 시스템 peak | 100% GPU | avg tok/s | TTFT p50/p95 |
|---|---|---|---|---|
| B1 7B·4K·q8_0·병렬1 | 5,717 MiB | ✅ | 44.2 | 0.03 / 0.83s |
| B2 7B·8K·q8_0·병렬2 (판정 기준) | 5,928 MiB (5.79 GiB) | ✅ | 43.8 | 1.83 / 1.86s |
| B3 7B·8K·f16·병렬2 | 6,549 MiB | ✅ | 43.0 | 1.94 / 2.74s |
| B4 7B·16K·q8_0·병렬1 | 6,197 MiB | ✅ | 44.4 | 1.81 / 1.88s |
| B5 7B·16K·q8_0·병렬2 | 6,664 MiB | ✅ | 43.8 | 1.85 / 1.95s |
| B6 3B·8K·q8_0·병렬2 | 3,765 MiB (3.68 GiB) | ✅ | 81.2 | 0.94 / 1.01s |
| B7 3B·16K·q8_0·병렬2 | 4,075 MiB | ✅ | 81.3 | 0.93 / 1.01s |

- 16K(B4·B5)도 **100% GPU**로 올라간다 — ADR-0002가 우려했던 CPU+GPU hybrid 오프로드는 7B/16K/병렬2까지는 발생하지 않았다. data-flow §4.1의 "긴 컨텍스트 모드 = hybrid 감수"는 재검토 대상.
- KV f16(B3)이 q8_0(B2)보다 621MiB 더 쓰지만 TTFT는 오히려 느림(2.74 vs 1.86s) — q8_0 유지가 맞다.

## Part C — LoRA → GGUF → Ollama (서빙 경로)

| 단계 | 결과 |
|---|---|
| 카나리아 학습 (3B, seq 2048, 60 step) | ✅ reserved 2.58GB, **PEFT 직접 추론 카나리아 적용률 20/20 (100%)** |
| **Plan A: Ollama `ADAPTER` (GGUF/safetensors)** | **❌ 전면 차단.** Ollama 0.40.7: `Error: LoRA adapters are no longer supported`. GGUF·safetensors 두 형식 모두 거절. CLI가 요청을 서버에 보내기 전에 차단한다. 제3자 분석([참고](https://github.com/generative-computing/mellea/issues/1651))으로는 2026-09-15 PR에서 의도적으로 제거됨 — Ollama 공식 릴리스 노트로 직접 확인은 못 했음 |
| **Plan B: LoRA 병합 → 양자화 → Ollama import** | ✅ **동작 확인.** HF+PEFT `merge_and_unload()`(CPU) → `convert_hf_to_gguf.py`(f16, 6.18GB) → `llama-quantize`(Q4_K_M, 1.93GB, 77초) → `ollama create`. 카나리아 20/20 (base 0/20) |
| **대안: `llama-server --lora` 직접 서빙** | ✅ **동작 확인** (계획에 없던 조사, 운영상 더 유리해 추가). 병합 없이 base+어댑터 로드. 카나리아 20/20. 런타임 스케일 전환 **~4ms**, 요청별 어댑터 지정 가능 |

## D1~D5 — 부가 측정

| # | 측정 | 결과 |
|---|---|---|
| D1 카나리아 적용률 | (Plan B 모델 기준) **merged: 20/20, base: 0/20** |
| D2 품질 비교 | 수동 side-by-side 10쌍 (`quality_side_by_side.md`) — 육안 검토 필요, 자동 판정 안 함 |
| D3 구조화 출력 | `adapter_probe.py`의 Ollama ADAPTER 경로가 막혀 미측정. Plan B/대안 경로 기준 재측정 필요 (별도 작업으로 넘김) |
| D4 **어댑터 전환 비용** | Ollama 모델 교체(3B↔3B): **0.19~0.26s** (이미 로드됨). 7B↔3B(모델 교체 유발): **4.1~16.4s** (최초 15.9s, 이후 4~8s). `llama-server --lora` 스케일 전환: **~4ms** |
| D5 **CPU 임베딩 처리량** | **4.79 chunks/s** (1500청크, batch 32, `num_gpu=0`). ⚠️ **ADR-0002 판정 기준(10 chunks/s) 미달** → "임베딩만 GPU 허용" 조건 발동 |

---

## 권고 (ADR-0003 초안 입력)

1. **Base 모델: 3B로 전환.** 7B는 서빙은 전혀 문제없지만 학습이 8GB 안전 마진(6.5GB)을 못 지킨다. 억지로 가능하지만 OOM 위험이 상시적이다.
2. **서빙 경로: Plan B(병합+양자화) 또는 `llama-server --lora`.** Ollama의 `ADAPTER`가 완전히 막혀 Plan A는 폐기해야 한다. Plan B는 기존 Ollama 연동을 그대로 쓸 수 있지만 어댑터마다 전체 모델(3B 기준 1.9GB)이 생기고 교체가 느리다(4~16s, 다만 3B는 상주 가능할 만큼 작음). `llama-server --lora`는 변경 범위가 크지만(`LLMProvider` 구현 추가) 전환이 4ms로 거의 공짜이고 analyze/refactor 어댑터 분리(Q6) 비용이 사실상 없어진다.
3. **임베딩 CPU 처리량 재검토 필요.** 4.79 chunks/s는 로드맵 R1(10k LOC 색인 5분 미만) 목표에 영향을 줄 수 있다. GPU 여유가 있는 시간대(생성 중이 아닐 때)에 임베딩을 GPU로 전환하는 정책이 필요하다.
4. **16K 컨텍스트 모드 재검토.** 7B 기준으로 hybrid 오프로드 없이 100% GPU로 동작했다. 3B로 전환하면 여유가 더 커지므로, data-flow §4.1의 "컨텍스트 조립 긴 모드 = 성능 저하 감수" 전제를 완화할 수 있다.
5. 미해결: A1 VRAM 역전 현상, D3(구조화 출력) 재측정.
