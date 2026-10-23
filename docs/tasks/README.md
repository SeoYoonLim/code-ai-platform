# 작업 카드 보드

저장소: https://github.com/SeoYoonLim/code-ai-platform · 작성 규칙: [TEMPLATE.md](TEMPLATE.md) · Codex 규칙: [AGENTS.md](../../AGENTS.md) · 로드맵: [04-mvp-roadmap.md](../architecture/04-mvp-roadmap.md)

## M0 — Foundation + Spike (W1: 10/26–10/30)

| ID | 제목 | 담당 | 의존 | 상태 | 우선순위 |
|---|---|---|---|---|---|
| [T-001](T-001-ci-pipeline.md) | CI 파이프라인 (GitHub Actions) | Codex | — | **done** | — |
| [T-002](T-002-dockerfiles.md) | Backend / AI Engine Dockerfile | Codex | T-001 | ready | P1 |
| [T-003](T-003-py-common-runtime.md) | py_common 런타임 (설정·로깅·request_id·Problem 핸들러) | Codex | T-001 | ready | P1 |
| [T-004](T-004-web-scaffold.md) | Web 스캐폴딩 (Next.js) | Codex | T-001 | ready | P2 |
| [T-005](T-005-mobile-scaffold.md) | Mobile 스캐폴딩 (Flutter) | Codex | T-001 | ready | P2 |
| [S-01](S-01-lora-gguf-ollama.md) | Spike: 8GB VRAM 학습·서빙 측정 + LoRA 서빙 경로 | Claude (Codex 스크립트 검증·수정·실행) | — | **done** → [ADR-0003](../adr/0003-base-model-and-lora-serving.md) | — |
| [S-02](S-02-treesitter-chunker.md) | Spike: tree-sitter Python/TS 청킹 검증 | Codex | — | ready | P1 |

상태: `todo → ready → in-progress → review → done` (막히면 `blocked`)

**하드웨어 사양:** RTX 5070 Ti 16GB (2026-10-23 교체, [ADR-0003 v2](../adr/0003-base-model-and-lora-serving.md)). M0·S-01 당시는 RTX 4060 8GB([ADR-0002](../adr/0002-gpu-budget-rtx4060-8gb.md))였다.

### 진행 순서
```
T-001 ─┬─ T-002 ─┐
       ├─ T-003 ─┼─→ M0 종료 (10/30): CI green · /v1/health 200 · ADR-0003
       ├─ T-004  │
       └─ T-005  │
S-01 (GPU, Docker) ┤ → ADR-0003: 7B/3B · Plan A/B/C 확정
S-02 (병행) ─────┘ → T-014 (M1 Chunker) 명세 입력
```

### 브랜치 · PR 규칙
- 브랜치: `task/T-001-ci-pipeline` (카드 ID + 슬러그)
- PR 제목: `T-001: CI 파이프라인`, 본문에 카드 링크와 DoD 체크리스트
- 카드 1장 = PR 1개. 리뷰는 Claude가 맡는다

## M1 — Engine Core & Adapters (W2–W3: 11/02–11/13)

로드맵: [04-mvp-roadmap.md M1](../architecture/04-mvp-roadmap.md). 서빙 결정: [ADR-0003](../adr/0003-base-model-and-lora-serving.md).

| ID | 제목 | 담당 | 의존 | 상태 | 우선순위 |
|---|---|---|---|---|---|
| [T-101](T-101-fake-adapters.md) | Fake 어댑터 3종 + Protocol 적합성(conformance) 스위트 | Codex | — | **done** (PR #3, `9056840`) | — |
| [T-102](T-102-llamaserver-provider.md) | `LlamaServerProvider` (llama-server `--lora`) + compose 서비스 | Codex | T-101 | **done** (PR #4, `5f3e62c`) | — |
| [T-103](T-103-ollama-embedder-scheduling.md) | `OllamaEmbedder` + GPU/CPU 동적 스케줄링 | Codex | T-101, T-102 | **done** (PR #5, `5529bcd`) | — |
| [T-104](T-104-chroma-vectorstore.md) | `ChromaVectorStore` (ChromaDB HTTP) | Codex | T-101 | **done** (PR #6, `f5c7219`) | — |
| T-105 ~ T-109 | tree-sitter 청커 · 레지스트리 · IndexingService · RagService · API | Codex | T-104, S-02 | 카드 미작성 | — |

```
T-101 ─┬─ T-102   (LLM)         ─┐
       └─ T-103   (Embedder)    ─┼─→ T-104~T-109 (카드는 결과를 보고 작성)
S-02 (tree-sitter 리포트) ──────┘   (T-105 입력)
```

**적합성 스위트 규약:** T-101이 만드는 `tests/conformance/*_suite.py`를 T-102·T-103·T-104가 그대로 상속한다. 실제 어댑터의 수락 기준 첫 줄은 항상 "스위트 통과"다.
