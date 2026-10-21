"""Fetch official GGUF; first verified download records its hash in models.lock."""

import argparse
import asyncio
import hashlib
import json
from pathlib import Path

import httpx
import structlog

ROOT = Path(__file__).resolve().parents[1]
MODEL = "qwen2.5-coder-3b-instruct-q4_k_m.gguf"
URL = f"https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/{MODEL}"
LOCK = ROOT / "scripts/models.lock"
log = structlog.get_logger()


def checksum(path: Path) -> str:
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


async def fetch(destination: Path, lock: Path = LOCK, url: str = URL) -> None:
    """Trust on first download, then require the recorded checksum on every run."""
    raw: object = json.loads(await asyncio.to_thread(lock.read_text, encoding="utf-8"))
    if not isinstance(raw, dict) or any(not isinstance(v, str) for v in raw.values()):
        raise ValueError("invalid models.lock")
    expected = raw.get(MODEL)
    if (
        expected is not None
        and await asyncio.to_thread(destination.exists)
        and await asyncio.to_thread(checksum, destination) == expected
    ):
        log.info("model_verified", path=str(destination), sha256=expected)
        return
    await asyncio.to_thread(destination.parent.mkdir, parents=True, exist_ok=True)
    partial = destination.with_suffix(".part")
    try:
        async with (
            httpx.AsyncClient(follow_redirects=True, timeout=120) as client,
            client.stream("GET", url) as response,
        ):
            response.raise_for_status()
            output = await asyncio.to_thread(partial.open, "wb")
            try:
                async for chunk in response.aiter_bytes():
                    await asyncio.to_thread(output.write, chunk)
            finally:
                await asyncio.to_thread(output.close)
        actual = await asyncio.to_thread(checksum, partial)
        if expected is not None and actual != expected:
            raise ValueError("model sha256 mismatch")
        if expected is None:
            raw[MODEL] = actual
            await asyncio.to_thread(lock.write_text, json.dumps(raw, indent=2) + "\n", encoding="utf-8")
            log.info("first_download_hash_recorded", sha256=actual)
        await asyncio.to_thread(partial.replace, destination)
        log.info("model_verified", path=str(destination), sha256=actual)
    finally:
        await asyncio.to_thread(partial.unlink, missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, default=ROOT / ".data/models" / MODEL)
    args = parser.parse_args()
    asyncio.run(fetch(args.destination))


if __name__ == "__main__":
    main()
