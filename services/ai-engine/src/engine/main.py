"""AI Engine FastAPI 앱 팩토리 겸 Composition Root.

어댑터 → 서비스 의존성 주입(DI)은 이 파일에서만 수행한다 (import-linter 계약).
"""

from fastapi import FastAPI


def create_app() -> FastAPI:
    app = FastAPI(title="Code AI Platform — AI Engine", version="0.1.0")

    @app.get("/v1/health")
    async def health() -> dict[str, object]:
        # TODO(codex): LLMProvider/VectorStore/Embedder health를 집계해 HealthResponse 반환
        return {"status": "ok", "components": {}}

    # TODO(codex): engine.api.v1.* 라우터 include + 어댑터 조립
    return app


app = create_app()
