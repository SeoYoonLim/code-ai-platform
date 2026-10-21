# ADR-0001: Monorepo 구조와 Backend/Engine 서비스 분리

- 상태: 승인됨
- 날짜: 2026-10-21

## 맥락
웹(Next.js), 앱(Flutter), 백엔드(FastAPI), AI 엔진(FastAPI + Ollama/vLLM), 파인튜닝 파이프라인이 공존한다.
Claude Code는 계약과 인터페이스를, Codex는 구현을 맡으므로 모듈 경계가 명확해야 한다.

## 결정
1. 단일 Monorepo, Python은 uv workspace(`py-common`, `backend`, `ai-engine`)로 관리한다. `ml/`은 CUDA 의존성 때문에 별도 환경으로 둔다.
2. Backend(공개 API)와 AI Engine(내부 API)을 별도 프로세스로 분리하고 `contracts/openapi/*.yaml`로만 통신한다.
3. Engine 내부는 Ports & Adapters 구조로 하고, import-linter로 의존성 방향을 강제한다.
4. 서빙 엔진은 개발 환경에서 Ollama, 운영 환경에서 vLLM을 쓰고 `LLMProvider`로 추상화한다.

## 결과
- (+) GPU 노드 독립 배포, 서빙 엔진 교체 용이, GPU 없는 단위 테스트
- (+) 작업 카드 단위로 Codex에 위임 가능한 파일 경계
- (−) 서비스 간 HTTP 오버헤드, 계약 변경 시 코드 재생성 절차 필요
