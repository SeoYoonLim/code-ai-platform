# Code AI Platform — 개발 명령 모음
# Windows: Git Bash에서 실행 (make 설치: `winget install ezwinports.make` 또는 `choco install make`)
SHELL := bash
.DEFAULT_GOAL := help

ENGINE_SPEC  := contracts/openapi/engine.v1.yaml
BACKEND_SPEC := contracts/openapi/backend.v1.yaml
PY_GEN_DIR   := packages/py-common/src/py_common/generated
WEB_GEN      := apps/web/src/lib/api/schema.d.ts
DART_GEN_DIR := apps/mobile/packages/api_client

.PHONY: help install up down logs dev dev-engine dev-backend dev-worker dev-web dev-mobile \
        test test-unit test-integration test-web test-mobile lint lint-py lint-imports lint-size \
        typecheck format validate-contracts gen-clients gen-py gen-ts gen-dart verify-clients check check-contracts clean gpu-status gpu-train-mode gpu-serve-mode

help: ## 사용 가능한 타겟 목록
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- 설치 / 인프라 ------------------------------------------------------------
install: ## Python workspace 의존성 설치 (uv)
	uv sync --all-packages

up: ## 인프라 컨테이너 기동 (ollama, chroma, redis, postgres)
	docker compose up -d ollama chroma redis postgres

down: ## 전체 컨테이너 종료
	docker compose down

logs: ## 컨테이너 로그
	docker compose logs -f --tail=100

# --- GPU 모드 (ADR-0002: 학습과 서빙은 8GB VRAM을 공유할 수 없다) -----------------
gpu-status: ## VRAM 사용량 + Ollama 로드 모델 (PROCESSOR 100% GPU 여부)
	nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv
	-docker compose exec ollama ollama ps

gpu-train-mode: ## 학습 전: Ollama 모델 언로드 + 컨테이너 중지
	-docker compose exec ollama sh -c 'ollama ps | tail -n +2 | cut -d" " -f1 | xargs -r -n1 ollama stop'
	docker compose stop ollama
	@echo "학습 모드: ENGINE_LLM_PROVIDER=fake 로 개발하세요."

gpu-serve-mode: ## 학습 후: Ollama 재기동
	docker compose start ollama

# --- 개발 서버 -----------------------------------------------------------------
dev: up ## 인프라 + engine + backend 동시 실행
	$(MAKE) -j2 dev-engine dev-backend

dev-engine: ## AI Engine (localhost:8100)
	uv run --package ai-engine uvicorn engine.main:app --reload --port 8100

dev-backend: ## Backend (localhost:8000)
	uv run --package backend uvicorn backend.main:app --reload --port 8000

dev-worker: ## Backend arq 워커
	uv run --package backend arq backend.workers.jobs.WorkerSettings

dev-web: ## Next.js 개발 서버
	cd apps/web && npm run dev

dev-mobile: ## Flutter 실행
	cd apps/mobile && flutter run

# --- 테스트 -------------------------------------------------------------------
test: test-unit ## 기본 테스트 (단위 + 계약)

test-unit: ## Python 단위/계약 테스트 (GPU·외부 서비스 불필요)
	uv run pytest --cov=engine --cov=backend --cov=py_common --cov-report=term-missing

test-integration: up ## 실제 Ollama/Chroma 대상 통합 테스트
	uv run pytest -m integration

test-web: ## 웹 테스트
	cd apps/web && npm test

test-mobile: ## Flutter 테스트
	cd apps/mobile && flutter test

# --- 품질 --------------------------------------------------------------------
lint: lint-py lint-imports typecheck lint-size ## 모든 Python 정적 검사

lint-py: ## ruff 린트 + 포맷 검사
	uv run ruff check .
	uv run ruff format --check .

lint-imports: ## 레이어 의존성 계약 검사 (import-linter)
	uv run lint-imports

lint-size: ## 파일당 300줄 규칙 검사 (생성물 제외)
	uv run python scripts/check_file_lines.py --max 300

typecheck: ## mypy --strict
	uv run mypy packages/py-common/src services/ai-engine/src services/backend/src

format: ## 자동 포맷
	uv run ruff check --fix .
	uv run ruff format .

check: validate-contracts lint test ## PR 전 전체 검사 (Codex 완료 조건)

check-contracts: gen-clients verify-clients test ## 계약 변경 시 (Claude): 재생성 + 생성물 컴파일 + 계약 테스트

# --- 계약 / 코드 생성 ----------------------------------------------------------
validate-contracts: ## OpenAPI 스펙 유효성 검사
	uv run openapi-spec-validator $(ENGINE_SPEC)
	uv run openapi-spec-validator $(BACKEND_SPEC)

gen-clients: validate-contracts gen-py gen-ts gen-dart ## contracts → 전 클라이언트 재생성

DMCG := uv run datamodel-codegen --output-model-type pydantic_v2.BaseModel --use-annotated \
	--field-constraints --target-python-version 3.12 --use-union-operator --use-standard-collections \
	--enum-field-as-literal one --formatters ruff-format ruff-check --disable-timestamp

gen-py: ## Pydantic v2 모델 생성 → py_common.generated (API + 이벤트)
	$(DMCG) --input-file-type openapi --input $(ENGINE_SPEC) --output $(PY_GEN_DIR)/engine_v1.py
	$(DMCG) --input-file-type openapi --input $(BACKEND_SPEC) --output $(PY_GEN_DIR)/backend_v1.py
	$(DMCG) --input-file-type jsonschema --input contracts/events/push.v1.schema.json \
		--output $(PY_GEN_DIR)/push_v1.py
	$(DMCG) --input-file-type jsonschema --input contracts/events/github-webhook.v1.schema.json \
		--output $(PY_GEN_DIR)/github_webhook_v1.py

gen-ts: ## TypeScript 타입 생성 → apps/web (openapi-typescript)
	@mkdir -p $(dir $(WEB_GEN))
	npx --yes openapi-typescript@7.4.4 $(BACKEND_SPEC) -o $(WEB_GEN)

OPENAPI_GENERATOR_IMAGE := openapitools/openapi-generator-cli:v7.10.0
gen-dart: ## Dart(dio) 클라이언트 생성 → apps/mobile (Java 없으면 Docker 사용)
	@if command -v java >/dev/null 2>&1; then \
		npx --yes @openapitools/openapi-generator-cli@2.15.3 generate -i $(BACKEND_SPEC) \
			-g dart-dio -o $(DART_GEN_DIR) --additional-properties=pubName=api_client; \
	else \
		MSYS_NO_PATHCONV=1 docker run --rm -v "$(CURDIR):/local" $(OPENAPI_GENERATOR_IMAGE) generate \
			-i /local/$(BACKEND_SPEC) -g dart-dio -o /local/$(DART_GEN_DIR) \
			--additional-properties=pubName=api_client; \
	fi

DART_IMAGE := dart:3.5
verify-clients: ## 생성물 컴파일 검증 (Python import · tsc · dart analyze)
	uv run python -c "import py_common.generated.engine_v1, py_common.generated.backend_v1, \
		py_common.generated.push_v1, py_common.generated.github_webhook_v1"
	npx --yes -p typescript@5.6.3 tsc --noEmit --strict --skipLibCheck false $(WEB_GEN)
	@if command -v dart >/dev/null 2>&1; then \
		cd $(DART_GEN_DIR) && dart pub get && dart run build_runner build -d && dart analyze; \
	else \
		MSYS_NO_PATHCONV=1 docker run --rm -v "$(CURDIR)/$(DART_GEN_DIR):/app" -w /app $(DART_IMAGE) \
			sh -c "dart pub get && dart run build_runner build -d && dart analyze --no-fatal-warnings"; \
	fi

clean: ## 캐시 정리
	find . -type d \( -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache \) -prune -exec rm -rf {} +
