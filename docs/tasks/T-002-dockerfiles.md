# T-002: Backend / AI Engine Dockerfile

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-001 머지 후 착수)
- **관련 문서:** [docker-compose.yml](../../docker-compose.yml), [ADR-0001](../adr/0001-monorepo-and-service-split.md)

## 목표
`docker compose --profile app up`으로 backend와 ai-engine 컨테이너를 띄우고, 두 서비스의 `/v1/health`가 200을 반환하게 한다.

## 대상 파일
- 신규: `infra/docker/ai-engine.Dockerfile`, `infra/docker/backend.Dockerfile`
- 신규: `.dockerignore` (루트)
- 수정: `docker-compose.yml`의 `ai-engine`, `backend` 서비스에 `healthcheck`만 추가
- 수정: `.github/workflows/ci.yml`에 `docker` job 추가 (빌드 + 컨테이너 기동 후 health 확인)

## 구현 명세

| 항목 | 규칙 |
|---|---|
| 베이스 | `python:3.12-slim-bookworm` (digest 고정) |
| uv | `COPY --from=ghcr.io/astral-sh/uv:0.12.17 /uv /uvx /bin/` |
| 멀티스테이지 | builder: `uv sync --frozen --no-dev --package <svc> --no-editable` → runtime: `.venv`만 복사 |
| 레이어 캐시 | `pyproject.toml`·`uv.lock`·멤버 pyproject를 먼저 복사하고 `--no-install-workspace`로 의존성을 설치한 뒤 소스 복사 |
| 사용자 | non-root (`uid 10001`) |
| ai-engine 추가 패키지 | `git` (refactor 패치 검증의 `git apply --check`에 필요) |
| 실행 | `uvicorn engine.main:app --host 0.0.0.0 --port 8100` / `backend.main:app --port 8000` |
| HEALTHCHECK | Python 한 줄 스크립트로 `urllib`을 이용해 `/v1/health` 호출 (curl 미설치) |
| `.dockerignore` | `.git`, `.venv`, `**/__pycache__`, `apps/`, `ml/datasets/`, `ml/outputs/`, `.data/`, `**/*.gguf`, `**/*.safetensors`, `.env` |

## 수락 기준
- [ ] `docker compose --profile app up -d --build` 후 60초 안에 두 컨테이너가 `healthy`
- [ ] `curl localhost:8100/v1/health`, `curl localhost:8000/v1/health` → 200
- [ ] 이미지 크기: ai-engine ≤ 600MB, backend ≤ 400MB (`docker image ls`로 측정해 결과에 기록)
- [ ] 컨테이너 안 프로세스가 non-root (`docker compose exec ai-engine id -u` ≠ 0)
- [ ] 소스 1줄만 바꿔 재빌드하면 의존성 레이어가 캐시됨 (빌드 로그에 `CACHED` 확인)
- [ ] CI `docker` job green

## 금지 사항
- 이미지에 `.env`나 비밀값 포함 금지 (`env_file`은 compose에서만)
- `ml/` 의존성(torch 등)을 서비스 이미지에 넣지 않는다
- 서비스 소스 코드 수정 금지 (health 엔드포인트는 이미 있다)

## 결과
<Codex 기록>
