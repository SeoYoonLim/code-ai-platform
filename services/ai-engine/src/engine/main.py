"""AI Engine FastAPI 앱 팩토리 겸 Composition Root.

어댑터 조립은 engine.container에 위임하고 앱 수명에 맞춰 자원을 닫는다.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from engine.container import build_container


def create_app() -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        async with await build_container() as container:
            app.state.container = container
            yield

    app = FastAPI(title="Code AI Platform — AI Engine", version="0.1.0", lifespan=lifespan)

    @app.get("/v1/health")
    async def health() -> dict[str, object]:
        # TODO(codex): LLMProvider/VectorStore/Embedder health를 집계해 HealthResponse 반환
        return {"status": "ok", "components": {}}

    # engine.api.v1 라우터는 T-109에서 추가한다.
    return app


app = create_app()
