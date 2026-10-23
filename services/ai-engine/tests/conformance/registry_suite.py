"""Reusable registry contract; implementations supply registry and write_registry fixtures."""

from collections.abc import Callable

import pytest

from engine.core.errors import AdapterNotFound, EngineError
from engine.core.interfaces import LoRAAdapterRegistry
from engine.core.models import AdapterStage, AdapterTask


def registry_row(name: str = "one", **changes: object) -> dict[str, object]:
    return {
        "name": name,
        "version": "v1",
        "base_model": "7b",
        "task": "analyze",
        "stage": "production",
        "dataset_hash": "hash",
        "eval_scores": {"score": 0.8},
        "created_at": "2026-10-23T12:00:00+09:00",
        **changes,
    }


class RegistryConformance:
    async def test_registry_contract_empty(self, registry: LoRAAdapterRegistry) -> None:
        assert isinstance(registry, LoRAAdapterRegistry)
        assert await registry.list_adapters() == []
        assert await registry.resolve(AdapterTask.ANALYZE) is None
        with pytest.raises(AdapterNotFound):
            await registry.get("missing")

    async def test_registry_contract_selection(
        self,
        registry: LoRAAdapterRegistry,
        write_registry: Callable[[list[dict[str, object]]], None],
    ) -> None:
        write_registry(
            [
                registry_row(),
                registry_row("old", base_model="3b"),
                registry_row("staged", stage="staging"),
                registry_row("other", task="explain"),
            ]
        )
        assert len(await registry.list_adapters()) == 4
        assert len(await registry.list_adapters(stage=AdapterStage.PRODUCTION)) == 3
        selected = await registry.resolve(AdapterTask.ANALYZE)
        assert selected == await registry.get("one")
        assert selected is not None
        assert selected.created_at.utcoffset() is not None
        assert selected.eval_scores == {"score": 0.8}
        assert await registry.resolve(AdapterTask.REFACTOR) is None

    async def test_registry_contract_base_mismatch(
        self,
        registry: LoRAAdapterRegistry,
        write_registry: Callable[[list[dict[str, object]]], None],
    ) -> None:
        write_registry([registry_row(base_model="3b")])
        assert await registry.resolve(AdapterTask.ANALYZE) is None
        assert len(await registry.list_adapters()) == 1

    async def test_registry_contract_ambiguity(
        self,
        registry: LoRAAdapterRegistry,
        write_registry: Callable[[list[dict[str, object]]], None],
    ) -> None:
        write_registry([registry_row(), registry_row("two")])
        with pytest.raises(EngineError) as caught:
            await registry.resolve(AdapterTask.ANALYZE)
        assert caught.value.detail == {"reason": "registry_ambiguous", "task": "analyze"}

    async def test_registry_contract_refresh(
        self,
        registry: LoRAAdapterRegistry,
        write_registry: Callable[[list[dict[str, object]]], None],
    ) -> None:
        write_registry([registry_row()])
        assert (await registry.get("one")).name == "one"
        write_registry([])
        assert await registry.list_adapters() == []
        assert await registry.resolve(AdapterTask.ANALYZE) is None
        with pytest.raises(AdapterNotFound):
            await registry.get("one")
