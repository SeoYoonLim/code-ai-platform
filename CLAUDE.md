# CLAUDE.md — 아키텍처 컨텍스트

로컬 AI 기반 **코드 분석 및 리팩터링 플랫폼**.
오픈소스 LLM을 자체 데이터셋으로 LoRA 파인튜닝하고, 코드베이스를 RAG로 색인해 분석/리팩터링 결과를 웹·앱에 제공한다.

## 협업 모델

| 역할 | 담당 | 산출물 |
|---|---|---|
| **Claude Code** (아키텍트) | 폴더 구조, 데이터 흐름, API 계약, 모듈 인터페이스, 리팩터링, 리뷰 | `contracts/`, `core/interfaces/`, `core/models/`, `docs/adr/`, `docs/architecture/`, `docs/tasks/` |
| **Codex** (구현자) | 인터페이스에 맞춘 세부 구현, 단위 테스트, 인라인 완성 | `adapters/`, `services/`, `api/`, `tests/`, `apps/*` 기능 코드 |

Codex의 규칙은 [AGENTS.md](AGENTS.md)에 있다. 작업은 **작업 카드**(`docs/tasks/T-xxx.md`, 템플릿: `docs/tasks/TEMPLATE.md`)로 위임한다.

### Claude의 작업 절차
1. 계약/인터페이스를 먼저 확정한다 (contract-first, interface-first).
2. 구현 대상 파일에 시그니처 + `raise NotImplementedError` 스텁을 둔다.
3. 작업 카드에 수락 기준(Protocol docstring 규칙 + 테스트 케이스)을 쓴다.
4. Codex 구현 후 리뷰: 레이어 위반, 인터페이스 의미 위반, 300줄 초과, 중복을 점검하고 리팩터링한다.
5. 계약 변경 시 `make check-contracts` (재생성 + Python/TS/Dart 컴파일 + 계약 테스트) 후 영향받는 구현을 함께 수정한다.

## 시스템 구성

```
[Next.js Web] ─┐                          ┌─ Ollama (dev) / vLLM (prod) + LoRA adapters
               ├─ HTTPS ─ [Backend] ─ HTTP ─ [AI Engine] ─┤
[Flutter App] ─┘   │          │ (internal)                └─ ChromaDB (code vectors)
     ▲             │      Postgres / Redis(arq)
     └── FCM push ─┘
                          [ml/] 오프라인: 데이터셋 → LoRA 학습 → 평가 → registry → 서빙
```

| 컴포넌트 | 경로 | 포트 | 책임 |
|---|---|---|---|
| Backend | `services/backend` | 8000 | 인증, 프로젝트/분석 영속화, 잡 큐, SSE 채팅 중계, GitHub 웹훅, FCM 푸시 |
| AI Engine | `services/ai-engine` | 8100 | LLM 추론, 코드 청킹/임베딩/색인, 검색, 분석·리팩터링 유스케이스 |
| py-common | `packages/py-common` | — | 공용 설정/로깅, **contracts에서 생성된 Pydantic 모델** |
| ML | `ml/` | — | 데이터셋 구축, Unsloth/PEFT LoRA 학습, 평가, 어댑터 레지스트리 (workspace와 분리된 CUDA 환경) |
| Web | `apps/web` | 3000 | 대시보드, Finding 뷰, diff 뷰어, AI 대화 |
| Mobile | `apps/mobile` | — | 빌드/분석 완료 알림, 리포트 열람 |
| Ollama | infra | 11434 | 개발용 서빙 (GGUF base + adapter) |
| ChromaDB | infra | 8001 | 벡터 저장소 (프로젝트별 컬렉션 `proj_{id}`) |

## 핵심 설계 결정

| # | 결정 | 근거 |
|---|---|---|
| D1 | Monorepo + uv workspace | 계약 변경과 클라이언트 재생성을 한 PR로 묶는다 |
| D2 | Backend와 Engine을 별도 서비스로 분리 | GPU 노드 독립 배포/스케일. `backend`↔`engine` import 금지 |
| D3 | Ports & Adapters (`core/interfaces` Protocol) | Ollama↔vLLM, Chroma↔타 VectorDB 교체 가능. GPU 없이 Fake로 테스트 |
| D4 | Contract-first (OpenAPI 3.1 SSOT) | Python/TS/Dart 타입 자동 생성으로 드리프트 차단 |
| D5 | tree-sitter 심볼 단위 청킹 | 줄 단위 분할 대비 검색 정확도 향상, 결과를 심볼에 매핑 가능 |
| D6 | dev=Ollama, prod=vLLM | 로컬 개발 편의성 + 운영 시 멀티 LoRA 동시 서빙. 8GB에서 dev vLLM은 3B만 가능 (ADR-0002 D-6) |
| D9 | **개발 GPU 예산: RTX 4060 8GB** ([ADR-0002](docs/adr/0002-gpu-budget-rtx4060-8gb.md)) | 7B Q4_K_M 서빙(8K ctx, KV q8_0, 2 슬롯 ≈ 5.9GB) / QLoRA 학습 peak < 7GB / 미달 시 3B. 학습과 서빙은 배타적 (`make gpu-train-mode`) |
| D7 | `ml/`은 workspace 제외 | torch/CUDA 버전 충돌을 서비스 환경과 격리 |
| D8 | engine.core는 순수 Python(dataclass) | 프레임워크 비의존. Pydantic은 API 경계(생성 모델)에서만 |

새 결정은 `docs/adr/NNNN-title.md`로 기록한다.

## 모듈별 역할 명세 — AI Engine

| 모듈 | 역할 | 의존 가능 대상 |
|---|---|---|
| `engine/main.py` | 앱 팩토리 + DI 조립 (Composition Root) | 전부 |
| `engine/api/v1/*` | 라우터. 생성 Pydantic 모델 ↔ core 모델 변환 | services, core, py_common |
| `engine/services/indexing_service.py` | 파일 수집 → 증분 판별 → 청킹 → 임베딩 → upsert | core |
| `engine/services/rag_service.py` | 질의 임베딩 → 검색 → 토큰 예산 내 컨텍스트 조립 | core |
| `engine/services/analysis_service.py` | 프롬프트 렌더 → 구조화 생성 → Finding 검증 | core |
| `engine/services/refactor_service.py` | diff 생성 → `git apply --check` + 구문 검증 | core |
| `engine/core/interfaces/` | `LLMProvider`, `Embedder`, `VectorStore`, `CodeChunker`, `LoRAAdapterRegistry` | core.models |
| `engine/core/models/` | 불변 dataclass 도메인 모델 | 표준 라이브러리만 |
| `engine/core/errors.py` | `EngineError` 계층 (`code`, `retryable`) | — |
| `engine/adapters/llm/` | `ollama.py`, `vllm.py`, `fake.py` | core, httpx |
| `engine/adapters/embeddings/` | `ollama_embed.py`, `fake.py` | core, httpx |
| `engine/adapters/vectorstore/` | `chroma.py`, `in_memory.py` | core, chromadb |
| `engine/adapters/parsing/` | `treesitter_chunker.py`, `language_map.py` | core, tree-sitter |
| `engine/adapters/registry_file.py` | `ml/registry/adapters.json` 읽기 | core |
| `engine/prompts/` | 버전 붙은 Jinja 템플릿 (`analyze.v1.jinja`) | — |

## 모듈별 역할 명세 — Backend

| 모듈 | 역할 |
|---|---|
| `api/v1/` | `projects`, `analyses`, `chat`(SSE), `webhooks`(GitHub), `devices`, `system` |
| `domain/` | Project, Analysis, Job 엔티티 + 상태 머신 (`queued → running → succeeded/failed`) |
| `services/` | 유스케이스 (프로젝트 등록, 분석 요청, 피드백 저장) |
| `clients/engine/` | Engine HTTP 클라이언트. 모델은 `py_common.generated.engine_v1` |
| `repositories/` | SQLAlchemy async 저장소 |
| `workers/` | arq 잡 (색인/분석을 Engine에 위임, 완료 시 푸시) |
| `notifications/` | FCM 발송 (`contracts/events/push.v1.schema.json`) |
| `auth/` | JWT 검증 |

## 문서 지도

- 데이터 흐름: [docs/architecture/02-data-flow.md](docs/architecture/02-data-flow.md)
- API 공통 규약 (에러·SSE·페이지네이션·멱등성): [docs/architecture/03-api-conventions.md](docs/architecture/03-api-conventions.md)
- MVP 로드맵: [docs/architecture/04-mvp-roadmap.md](docs/architecture/04-mvp-roadmap.md)
- 이벤트 계약 (FCM·GitHub 웹훅): [contracts/events/README.md](contracts/events/README.md)
- API 계약: [contracts/openapi/](contracts/openapi/)
- ADR: [docs/adr/](docs/adr/)
- 작업 카드: [docs/tasks/](docs/tasks/)
