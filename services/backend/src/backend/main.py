"""Backend FastAPI 앱 팩토리."""

from fastapi import FastAPI


def create_app() -> FastAPI:
    app = FastAPI(title="Code AI Platform — Backend", version="0.1.0")

    @app.get("/v1/health")
    async def health() -> dict[str, str]:
        # TODO(codex): Engine /v1/health 조회 결과를 engine 필드로 포함
        return {"status": "ok"}

    # TODO(codex): backend.api.v1.* 라우터 include
    return app


app = create_app()
