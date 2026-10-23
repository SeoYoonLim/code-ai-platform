# S-03: Spike — RTX 5070 Ti(Blackwell) 학습 재기준선

- 상태: **todo** (담당: Claude 설계·검증 + Codex 스크립트, 실행은 Docker 가능한 쪽)
- 배경: [ADR-0003 v2](../adr/0003-base-model-and-lora-serving.md). 서빙은 5070 Ti에서 정상이나, 학습 이미지(torch 2.6.0+cu126)는 sm_120 커널이 없어 `no kernel image is available`로 실패한다.

## 목표
1. cu128 이상 torch/xformers/Unsloth로 학습 이미지를 재빌드한다 (`ml/spikes/s01/Dockerfile` 기반, 버전 고정).
2. **`check_causal.py`(비인과 attention 검사)를 통과**시킨다. 통과 전 학습 결과는 모두 무효로 본다 (S-01 전례).
3. 7B QLoRA 학습의 VRAM(reserved/시스템 peak)·tok/s·5k샘플 소요 시간을 seq 1024/2048/4096에서 측정한다. 가능하면 14B도 측정한다.
4. `ml/training/configs/*-8gb.yaml` 가드를 16GB 기준으로 재설정한 `*-16gb.yaml`을 만든다.
5. 7B용 카나리아 어댑터를 만들어 `llama-server --lora`로 로드·전환·격리(20/20)를 검증하고, 어댑터 상주 VRAM을 실측해 ADR-0003 v2의 "멀티 LoRA 상주 마진" 가정치(≤1.5 GiB)를 확정한다.

## 수락 기준
- 위 1~5의 실측값이 보고서(`ml/spikes/s03/results/REPORT.md`)에 있고, ADR-0003의 가정치가 실측치로 교체된다.
- 측정하지 않은 항목은 "미측정"으로 명시한다.
