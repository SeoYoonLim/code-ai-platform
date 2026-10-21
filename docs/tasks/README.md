# 작업 카드 보드

작성 규칙: [TEMPLATE.md](TEMPLATE.md) · Codex 규칙: [AGENTS.md](../../AGENTS.md) · 로드맵: [04-mvp-roadmap.md](../architecture/04-mvp-roadmap.md)

## M0 — Foundation + Spike (W1: 10/26–10/30)

| ID | 제목 | 담당 | 의존 | 상태 | 우선순위 |
|---|---|---|---|---|---|
| [T-001](T-001-ci-pipeline.md) | CI 파이프라인 (GitHub Actions) | Codex | — | **ready** | **P0 — 첫 작업** |
| [T-002](T-002-dockerfiles.md) | Backend / AI Engine Dockerfile | Codex | T-001 | ready | P1 |
| [T-003](T-003-py-common-runtime.md) | py_common 런타임 (설정·로깅·request_id·Problem 핸들러) | Codex | T-001 | ready | P1 |
| [T-004](T-004-web-scaffold.md) | Web 스캐폴딩 (Next.js) | Codex | T-001 | ready | P2 |
| [T-005](T-005-mobile-scaffold.md) | Mobile 스캐폴딩 (Flutter) | Codex | T-001 | ready | P2 |
| [S-01](S-01-lora-gguf-ollama.md) | Spike: Qwen2.5-Coder LoRA → GGUF → Ollama ADAPTER | Claude + 사람(GPU) | — | ready | **P0 — 병행** |
| [S-02](S-02-treesitter-chunker.md) | Spike: tree-sitter Python/TS 청킹 검증 | Codex | — | ready | P1 |

상태: `todo → ready → in-progress → review → done` (막히면 `blocked`)

### 진행 순서
```
T-001 ─┬─ T-002 ─┐
       ├─ T-003 ─┼─→ M0 종료 (10/30): CI green · /v1/health 200 · ADR-0002
       ├─ T-004  │
       └─ T-005  │
S-01 (GPU, 병행) ┤
S-02 (병행) ─────┘ → T-014 (M1 Chunker) 명세 입력
```

### 브랜치 · PR 규칙
- 브랜치: `task/T-001-ci-pipeline` (카드 ID + 슬러그)
- PR 제목: `T-001: CI 파이프라인`, 본문에 카드 링크와 DoD 체크리스트
- 카드 1장 = PR 1개. 리뷰는 Claude가 맡는다
