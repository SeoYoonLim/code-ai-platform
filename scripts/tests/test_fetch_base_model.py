"""Execute the downloader against mocked HTTP, without model data."""

import hashlib
import json
import runpy
from pathlib import Path

import pytest
import respx

MODULE = runpy.run_path(str(Path(__file__).resolve().parents[1] / "fetch_base_model.py"))
fetch = MODULE["fetch"]
MODEL = MODULE["MODEL"]
URL = "https://models.test/base.gguf"


async def test_fetch_first_hash_skip_and_mismatch(tmp_path: Path, respx_mock: respx.MockRouter) -> None:
    lock = tmp_path / "models.lock"
    lock.write_text("{}", encoding="utf-8")
    destination = tmp_path / "models" / MODEL
    route = respx_mock.get(URL).respond(200, content=b"synthetic model bytes")
    await fetch(destination, lock, URL)
    expected = hashlib.sha256(b"synthetic model bytes").hexdigest()
    assert json.loads(lock.read_text())[MODEL] == expected
    assert destination.read_bytes() == b"synthetic model bytes"
    await fetch(destination, lock, URL)
    assert route.call_count == 1
    destination.write_bytes(b"corrupted")
    route.respond(200, content=b"wrong download")
    with pytest.raises(ValueError, match="sha256 mismatch"):
        await fetch(destination, lock, URL)
    assert not destination.with_suffix(".part").exists()
    assert destination.read_bytes() == b"corrupted"


async def test_fetch_invalid_lock(tmp_path: Path) -> None:
    lock = tmp_path / "models.lock"
    lock.write_text("[]", encoding="utf-8")
    with pytest.raises(ValueError, match=r"invalid models\.lock"):
        await fetch(tmp_path / MODEL, lock, URL)
