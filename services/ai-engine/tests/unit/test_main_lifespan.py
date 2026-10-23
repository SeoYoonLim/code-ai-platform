"""App lifecycle uses the same owned container."""

from unittest.mock import AsyncMock

import httpx
import pytest

from engine import main
from engine.container import Container, build_container
from engine.settings import Settings


async def test_t106_main_fake_lifespan(monkeypatch: pytest.MonkeyPatch) -> None:
    for key, value in {"LLM_PROVIDER": "fake", "EMBEDDER_PROVIDER": "fake", "VECTOR_STORE": "memory"}.items():
        monkeypatch.setenv("ENGINE_" + key, value)
    original = Container.aclose
    calls = []

    async def tracked_close(self: Container) -> None:
        calls.append(self)
        await original(self)

    monkeypatch.setattr(Container, "aclose", tracked_close)
    app = main.create_app()
    async with app.router.lifespan_context(app):
        assert app.state.container.llm.name == "fake"
        assert calls == []
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/v1/health")
        assert response.json() == {"status": "ok", "components": {}}
    assert calls == [app.state.container]


async def test_t106_main_lifespan_body_failure(monkeypatch: pytest.MonkeyPatch) -> None:
    built = await build_container(
        Settings(llm_provider="fake", embedder_provider="fake", vector_store="memory")
    )
    monkeypatch.setattr(main, "build_container", AsyncMock(return_value=built))
    close = AsyncMock()
    monkeypatch.setattr(Container, "aclose", close)
    app = main.create_app()
    with pytest.raises(RuntimeError, match="t106 body"):
        async with app.router.lifespan_context(app):
            raise RuntimeError("t106 body")
    close.assert_awaited_once()
