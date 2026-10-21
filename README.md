# Code AI Platform

로컬 오픈소스 LLM(LoRA 파인튜닝) + RAG 기반 코드 분석·리팩터링 플랫폼.

- 아키텍처: [CLAUDE.md](CLAUDE.md) · Codex 규칙: [AGENTS.md](AGENTS.md)
- 데이터 흐름: [docs/architecture/02-data-flow.md](docs/architecture/02-data-flow.md)
- API 계약: [contracts/openapi/](contracts/openapi/)

## 빠른 시작
```bash
cp .env.example .env
make install        # uv sync --all-packages
make up             # ollama, chroma, redis, postgres
make dev            # engine :8100, backend :8000
make check          # 계약 검증 + lint + 타입 + 테스트
```
