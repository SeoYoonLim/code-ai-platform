"""File registry conformance and malformed input boundaries."""

import asyncio
import json
from collections.abc import Callable
from pathlib import Path
from unittest.mock import patch

import pytest

from engine.adapters.registry_file import FileAdapterRegistry
from engine.core.errors import EngineError
from engine.core.models import AdapterTask
from tests.conformance.registry_suite import RegistryConformance, registry_row


@pytest.fixture
def registry_path(tmp_path: Path) -> Path:
    return tmp_path / "t106-registry.json"


@pytest.fixture
def registry(registry_path: Path) -> FileAdapterRegistry:
    return FileAdapterRegistry(registry_path, base_model="7b")


@pytest.fixture
def write_registry(registry_path: Path) -> Callable[[list[dict[str, object]]], None]:
    def write(rows: list[dict[str, object]]) -> None:
        registry_path.write_text(json.dumps({"schema_version": 1, "adapters": rows}), encoding="utf-8")

    return write


class TestFileRegistry(RegistryConformance):
    pass


@pytest.mark.parametrize(
    "content",
    [
        "",
        "{",
        "[]",
        "null",
        "{}",
        '{"schema_version":2,"adapters":[]}',
        '{"schema_version":true,"adapters":[]}',
        '{"schema_version":1.0,"adapters":[]}',
        '{"schema_version":1,"adapters":{}}',
        *[
            json.dumps({"schema_version": 1, "adapters": [row]})
            for row in [
                {},
                registry_row(stage="bad"),
                registry_row(task="bad"),
                registry_row(created_at="bad"),
                registry_row(created_at="2026-10-23T12:00:00"),
                registry_row(name=5),
                registry_row(eval_scores={"x": "bad"}),
                registry_row(eval_scores={"x": True}),
            ]
        ],
    ],
)
async def test_t106_registry_invalid_documents(
    registry: FileAdapterRegistry,
    registry_path: Path,
    content: str,
) -> None:
    await asyncio.to_thread(registry_path.write_text, content, encoding="utf-8")
    for call in (registry.list_adapters(), registry.get("one"), registry.resolve(AdapterTask.ANALYZE)):
        with pytest.raises(EngineError) as caught:
            await call
        assert caught.value.detail["reason"] == "registry_invalid"
        assert str(registry_path) in str(caught.value)
        assert len(str(caught.value)) <= 300


async def test_t106_registry_empty_document(
    registry: FileAdapterRegistry,
    write_registry: Callable[[list[dict[str, object]]], None],
) -> None:
    write_registry([])
    assert await registry.list_adapters() == []


async def test_t106_registry_directory(registry: FileAdapterRegistry, registry_path: Path) -> None:
    await asyncio.to_thread(registry_path.mkdir)
    with pytest.raises(EngineError, match="t106-registry") as caught:
        await registry.list_adapters()
    assert caught.value.detail["reason"] == "registry_invalid"


async def test_t106_registry_read_failure(registry: FileAdapterRegistry) -> None:
    with (
        patch.object(Path, "read_text", side_effect=PermissionError("denied")),
        pytest.raises(EngineError) as caught,
    ):
        await registry.list_adapters()
    assert caught.value.detail["reason"] == "registry_invalid"
