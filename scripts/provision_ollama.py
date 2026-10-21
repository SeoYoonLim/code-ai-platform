"""Idempotently install the embedding model through Ollama HTTP."""

import argparse
import asyncio

import httpx
import structlog
from pydantic import BaseModel

MODEL = "nomic-embed-text"


class Model(BaseModel):
    name: str


class Tags(BaseModel):
    models: list[Model]


async def provision(client: httpx.AsyncClient) -> bool:
    response = await client.get("/api/tags", timeout=10)
    response.raise_for_status()
    if any(
        row.name in (MODEL, MODEL + ":latest") for row in Tags.model_validate_json(response.content).models
    ):
        return False
    response = await client.post("/api/pull", json={"model": MODEL, "stream": False}, timeout=600)
    response.raise_for_status()
    if response.json().get("status") != "success":
        raise RuntimeError("Ollama pull did not succeed")
    response = await client.get("/api/tags", timeout=10)
    response.raise_for_status()
    if not any(
        row.name in (MODEL, MODEL + ":latest") for row in Tags.model_validate_json(response.content).models
    ):
        raise RuntimeError("model missing after pull")
    return True


async def main(base_url: str) -> None:
    async with httpx.AsyncClient(base_url=base_url) as client:
        pulled = await provision(client)
        structlog.get_logger().info("embedding_model_ready", pulled=pulled, model=MODEL)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default="http://localhost:11434")
    asyncio.run(main(parser.parse_args().base_url))
