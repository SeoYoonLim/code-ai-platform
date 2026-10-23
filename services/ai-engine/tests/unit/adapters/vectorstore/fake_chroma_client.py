"""Measured HTTP boundary semantics, without a Chroma engine or network."""

import asyncio
import math
import re
from unittest.mock import AsyncMock, create_autospec

from chromadb.api import AsyncClientAPI
from chromadb.api.models.AsyncCollection import AsyncCollection
from chromadb.errors import InvalidArgumentError, NotFoundError

Scalar = str | int | float | bool


def matches(meta: dict[str, Scalar], where: dict[str, object] | None) -> bool:
    if where is None:
        return True
    if len(where) != 1:
        raise ValueError("exactly one operator")
    key, value = next(iter(where.items()))
    if key == "$and":
        if not isinstance(value, list) or len(value) < 2:
            raise ValueError("invalid and")
        return all(matches(meta, item) for item in value)
    if isinstance(value, dict):
        choices = value.get("$in")
        if not isinstance(choices, list) or not choices:
            raise ValueError("non-empty list required")
        return meta.get(key) in choices
    if value is None:
        raise ValueError("None filter")
    return meta.get(key) == value


class FakeCollection:
    # A real server returns nearest-first. Setting this deliberately reverses that order so tests can
    # prove the adapter does not rely on server ordering (the card says: do not assume sorting).
    unsorted_results = False

    def __init__(self, metadata: dict[str, Scalar] | None) -> None:
        self.metadata = metadata
        self.dimension: int | None = None
        self.rows: dict[str, tuple[list[float], str, dict[str, Scalar]]] = {}
        # Autospec preserves the real async client signature and records boundary calls.
        self.handle: AsyncCollection = create_autospec(AsyncCollection, instance=True)
        self.handle.metadata = metadata
        for name in ("upsert", "query", "get", "delete", "count"):
            setattr(self.handle, name, AsyncMock(side_effect=getattr(self, name)))

    def validate(self, vectors: list[list[float]]) -> None:
        expected = self.dimension if self.dimension is not None else len(vectors[0])
        if any(len(vector) != expected for vector in vectors):
            raise InvalidArgumentError("dimension mismatch")

    async def upsert(
        self,
        *,
        ids: list[str],
        embeddings: list[list[float]],
        documents: list[str],
        metadatas: list[dict[str, Scalar | None]],
    ) -> None:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        if not ids:
            raise ValueError("empty upsert")
        self.validate(embeddings)
        self.dimension = len(embeddings[0])
        for ident, vector, text, meta in zip(ids, embeddings, documents, metadatas, strict=True):
            self.rows[ident] = (list(vector), text, {k: v for k, v in meta.items() if v is not None})

    async def query(
        self,
        *,
        query_embeddings: list[list[float]],
        n_results: int,
        where: dict[str, object] | None = None,
        include: list[str] | None = None,
    ) -> dict[str, object]:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        if n_results <= 0:
            raise TypeError("n_results must be positive")
        self.validate(query_embeddings)
        query = query_embeddings[0]
        # Validate even when the collection is empty.
        matches({}, where)
        found = []
        for ident, (vector, text, meta) in self.rows.items():
            if matches(meta, where):
                norm = math.hypot(*query) * math.hypot(*vector)
                cosine = sum(a * b for a, b in zip(query, vector, strict=True)) / norm if norm else 0.0
                found.append((1.0 - cosine, ident, text, meta))
        found.sort(key=lambda row: row[0])
        found = found[:n_results]
        if self.unsorted_results:
            found.reverse()
        return {
            "ids": [[r[1] for r in found]],
            "documents": [[r[2] for r in found]],
            "metadatas": [[r[3] for r in found]],
            "distances": [[r[0] for r in found]],
        }

    async def get(
        self,
        *,
        include: list[str] | None = None,
        limit: int | None = None,
        offset: int = 0,
        where: dict[str, object] | None = None,
    ) -> dict[str, object]:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        selected = [(k, v) for k, v in self.rows.items() if matches(v[2], where)]
        rows = selected[offset : offset + limit if limit is not None else None]
        return {"ids": [r[0] for r in rows], "metadatas": [r[1][2] for r in rows]}

    async def delete(
        self,
        *,
        where: dict[str, object] | None = None,
        ids: list[str] | None = None,
    ) -> dict[str, int]:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        if ids == []:
            raise ValueError("empty ids")
        matches({}, where)
        removed = [
            ident
            for ident, (_, _, meta) in self.rows.items()
            if (ids is None or ident in ids) and matches(meta, where)
        ]
        for ident in removed:
            del self.rows[ident]
        return {"deleted": len(removed)}

    async def count(self) -> int:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        return len(self.rows)


class FakeChromaClient:
    def __init__(self) -> None:
        self.collections: dict[str, FakeCollection] = {}
        # Autospec is the typed injection surface; behavior lives in this fake.
        self.client: AsyncClientAPI = create_autospec(AsyncClientAPI, instance=True)
        self.client.get_max_batch_size = AsyncMock(return_value=5461)
        for name in ("get_collection", "get_or_create_collection", "delete_collection"):
            setattr(self.client, name, AsyncMock(side_effect=getattr(self, name)))

    async def get_collection(self, name: str, *, embedding_function: object = None) -> AsyncCollection:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        if name not in self.collections:
            raise NotFoundError(name)
        return self.collections[name].handle

    async def get_or_create_collection(
        self,
        name: str,
        *,
        metadata: dict[str, Scalar] | None = None,
        configuration: dict[str, object] | None = None,
        embedding_function: object = None,
    ) -> AsyncCollection:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9._-]{1,510}[a-zA-Z0-9]", name):
            raise InvalidArgumentError("invalid name")
        self.collections.setdefault(name, FakeCollection(metadata))
        return self.collections[name].handle

    async def delete_collection(self, name: str) -> None:
        await asyncio.sleep(0)  # yield like a real network call so asyncio.wait_for can actually fire
        if name not in self.collections:
            raise NotFoundError(name)
        del self.collections[name]
