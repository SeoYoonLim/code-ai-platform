"""Provisioning is mocked; no daemon or download is used."""

import asyncio
import runpy
from collections.abc import Awaitable, Callable
from pathlib import Path

import httpx
import pytest
import respx

# runpy permits the standalone script to stay outside application packages.
module = runpy.run_path(str(Path(__file__).resolve().parents[1] / "provision_ollama.py"))


@pytest.mark.parametrize("present", [True, False])
async def test_provision_idempotence(present: bool, respx_mock: respx.MockRouter) -> None:
    tags = {"models": [{"name": "nomic-embed-text:latest"}]}
    route = respx_mock.get("http://ollama/api/tags")
    route.side_effect = [
        httpx.Response(200, json=tags if present else {"models": []}),
        httpx.Response(200, json=tags),
    ]
    pull = respx_mock.post("http://ollama/api/pull").respond(200, json={"status": "success"})
    operation: Callable[[httpx.AsyncClient], Awaitable[bool]] = module["provision"]
    async with httpx.AsyncClient(base_url="http://ollama") as client:
        assert await asyncio.wait_for(operation(client), 5) is not present
    assert pull.call_count == (0 if present else 1)
    if not present:
        import json

        assert json.loads(pull.calls[0].request.content) == {"model": "nomic-embed-text", "stream": False}


async def test_provision_failure(respx_mock: respx.MockRouter) -> None:
    respx_mock.get("http://ollama/api/tags").respond(500)
    operation: Callable[[httpx.AsyncClient], Awaitable[bool]] = module["provision"]
    async with httpx.AsyncClient(base_url="http://ollama") as client:
        with pytest.raises(httpx.HTTPStatusError):
            await asyncio.wait_for(operation(client), 5)


@pytest.mark.parametrize("failure", ["pull", "missing"])
async def test_incomplete_pull(failure: str, respx_mock: respx.MockRouter) -> None:
    respx_mock.get("http://ollama/api/tags").respond(200, json={"models": []})
    respx_mock.post("http://ollama/api/pull").respond(
        200,
        json={"status": "failed" if failure == "pull" else "success"},
    )
    operation: Callable[[httpx.AsyncClient], Awaitable[bool]] = module["provision"]
    async with httpx.AsyncClient(base_url="http://ollama") as client:
        with pytest.raises(RuntimeError, match=r"did not succeed|missing after pull"):
            await asyncio.wait_for(operation(client), 5)


async def test_main_mocked(respx_mock: respx.MockRouter) -> None:
    respx_mock.get("http://ollama/api/tags").respond(
        200,
        json={"models": [{"name": "nomic-embed-text"}]},
    )
    operation: Callable[[str], Awaitable[None]] = module["main"]
    await asyncio.wait_for(operation("http://ollama"), 5)
