"""Opt-in GPU checks; run with -m integration and ENGINE_IT_LLAMACPP_URL."""

import asyncio
import json
import os
import time
from collections.abc import AsyncIterator
from pathlib import Path

import httpx
import jsonschema
import pytest
import structlog
import yaml

from engine.adapters.llm.llamacpp import LlamaServerProvider
from engine.core.models import ChatMessage, GenerationParams, GenerationRequest, Role
from engine.settings import Settings

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not os.getenv("ENGINE_IT_LLAMACPP_URL"), reason="ENGINE_IT_LLAMACPP_URL not set"),
]
MARKER = "[[CODEAI-CANARY]]"
ROOT = Path(__file__).resolve().parents[4]


@pytest.fixture
async def live() -> AsyncIterator[LlamaServerProvider]:
    settings = Settings(llamacpp_url=os.environ["ENGINE_IT_LLAMACPP_URL"])
    provider = LlamaServerProvider(settings)
    assert (await provider.health()).ok
    yield provider
    await provider.aclose()


def request(index: int = 0, adapter: str | None = None, *, tokens: int = 128) -> GenerationRequest:
    return GenerationRequest(
        messages=(
            ChatMessage(Role.SYSTEM, "You are a code analysis assistant."),
            ChatMessage(
                Role.USER,
                f"Explain this Python function and identify one boundary case:\n"
                f"def unseen_{index}(values):\n"
                f"    return [value + {index + 1} for value in values if value is not None]\n",
            ),
        ),
        adapter=adapter,
        params=GenerationParams(temperature=0, max_tokens=tokens),
    )


def canary_adapter() -> str:
    return Path(os.getenv("ENGINE_IT_ADAPTER_GGUF", ".data/s01-artifacts/canary-3b.gguf")).stem


async def test_live_base_usage(live: LlamaServerProvider) -> None:
    result = await live.generate(request())
    assert result.text
    assert result.usage.prompt_tokens > 0
    assert result.usage.completion_tokens > 0


async def test_live_canary_twenty(live: LlamaServerProvider) -> None:
    adapted = [await live.generate(request(i, canary_adapter())) for i in range(20)]
    base = [await live.generate(request(i)) for i in range(20)]
    assert sum(row.text.startswith(MARKER) for row in adapted) == 20
    assert sum(row.text.startswith(MARKER) for row in base) == 0


async def test_live_concurrent_isolation(live: LlamaServerProvider) -> None:
    for index in range(8):
        adapted, base = await asyncio.gather(
            live.generate(request(index, canary_adapter())), live.generate(request(index))
        )
        assert adapted.text.startswith(MARKER)
        assert not base.text.startswith(MARKER)


async def test_live_abort_releases_slot(live: LlamaServerProvider) -> None:
    stream = live.stream(request(tokens=2048))
    await anext(stream)
    # The provider exposes a real async generator with aclose().
    await stream.aclose()
    assert live.in_flight == 0
    headers = {}
    key = os.getenv("ENGINE_LLAMACPP_API_KEY")
    if key:
        headers["Authorization"] = f"Bearer {key}"
    async with httpx.AsyncClient(base_url=os.environ["ENGINE_IT_LLAMACPP_URL"], headers=headers) as client:
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            response = await client.get("/slots")
            response.raise_for_status()
            if all(not slot["is_processing"] for slot in response.json()):
                return
            await asyncio.sleep(0.1)
    pytest.fail("server slot still processing after abort")


async def test_live_finding_schema_rate(live: LlamaServerProvider, record_property) -> None:
    spec = yaml.safe_load((ROOT / "contracts/openapi/engine.v1.yaml").read_text(encoding="utf-8"))
    schemas = spec["components"]["schemas"]
    finding = json.loads(json.dumps(schemas["Finding"]))
    for value in finding["properties"].values():
        if "$ref" in value:
            value.update(schemas[value.pop("$ref").rsplit("/", 1)[-1]])
    schema = {"type": "array", "items": finding}
    valid = 0
    for _ in range(10):
        req = GenerationRequest(
            messages=(
                ChatMessage(
                    Role.USER, "Analyze `def divide(x): return 1 / x`. Return one Finding in a JSON array."
                ),
            ),
            json_schema=schema,
            params=GenerationParams(temperature=0, max_tokens=1024),
        )
        result = await live.generate(req)
        try:
            jsonschema.validate(json.loads(result.text), schema)
            valid += 1
        except (ValueError, jsonschema.ValidationError):
            continue
    record_property("finding_schema_valid", f"{valid}/10")
    # Report the observed rate even below 90%; this is a measurement, not a quality gate.
    structlog.get_logger().info("finding_schema_rate", valid=valid, total=10)
