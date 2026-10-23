"""Read-only, uncached LoRA registry validated at the file boundary."""

import asyncio
from datetime import datetime
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, ConfigDict, ValidationError, field_validator

from engine.core.errors import AdapterNotFound, EngineError
from engine.core.models import AdapterInfo, AdapterStage, AdapterTask


class _Entry(BaseModel):
    model_config = ConfigDict(strict=True)
    name: str
    version: str
    base_model: str
    task: AdapterTask
    stage: AdapterStage
    dataset_hash: str
    eval_scores: dict[str, float]
    created_at: datetime

    @field_validator("created_at")
    @classmethod
    def timezone_required(cls, value: datetime) -> datetime:
        if value.utcoffset() is None:
            raise ValueError("created_at must include timezone")
        return value

    def info(self) -> AdapterInfo:
        return AdapterInfo(
            self.name,
            self.version,
            self.base_model,
            self.task,
            self.stage,
            self.dataset_hash,
            self.eval_scores,
            self.created_at,
        )


class _Document(BaseModel):
    model_config = ConfigDict(strict=True)
    schema_version: Literal[1]
    adapters: list[_Entry]

    @field_validator("schema_version", mode="before")
    @classmethod
    def integer_version(cls, value: object) -> object:
        if type(value) is not int:
            raise ValueError("schema_version must be integer 1")
        return value


class FileAdapterRegistry:
    def __init__(self, path: Path, *, base_model: str) -> None:
        self._path = path
        self._base_model = base_model

    def _read(self) -> list[AdapterInfo]:
        try:
            content = self._path.read_text(encoding="utf-8")
        except FileNotFoundError:
            return []
        except (OSError, UnicodeError) as error:
            raise self._invalid(error) from error
        try:
            return [entry.info() for entry in _Document.model_validate_json(content).adapters]
        except (ValidationError, ValueError) as error:
            raise self._invalid(error) from error

    def _invalid(self, error: Exception) -> EngineError:
        return EngineError(f"{self._path}: {error}"[:300], detail={"reason": "registry_invalid"})

    async def list_adapters(self, *, stage: AdapterStage | None = None) -> list[AdapterInfo]:
        entries = await asyncio.to_thread(self._read)
        return [entry for entry in entries if stage is None or entry.stage == stage]

    async def get(self, name: str) -> AdapterInfo:
        for entry in await self.list_adapters():
            if entry.name == name:
                return entry
        raise AdapterNotFound(f"adapter not found: {name}")

    async def resolve(self, task: AdapterTask) -> AdapterInfo | None:
        candidates = [
            entry
            for entry in await self.list_adapters(stage=AdapterStage.PRODUCTION)
            if entry.task == task and entry.base_model == self._base_model
        ]
        if len(candidates) > 1:
            raise EngineError(
                f"ambiguous registry task: {task}",
                detail={"reason": "registry_ambiguous", "task": task.value},
            )
        return candidates[0] if candidates else None
