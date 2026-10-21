"""In-memory cosine search with dimension validation."""

import math
from collections.abc import Sequence

from engine.core.errors import CollectionNotFound, VectorStoreError
from engine.core.models import CodeChunk, MetadataFilter, RetrievedChunk


class InMemoryVectorStore:
    def __init__(self) -> None:
        self._collections: dict[str, dict[str, tuple[CodeChunk, tuple[float, ...]]]] = {}
        self._dimensions: dict[str, int] = {}

    def _get(self, collection: str) -> dict[str, tuple[CodeChunk, tuple[float, ...]]]:
        if collection not in self._collections:
            raise CollectionNotFound(collection)
        return self._collections[collection]

    def _validate(self, collection: str, vector: Sequence[float]) -> None:
        if len(vector) != self._dimensions[collection]:
            raise VectorStoreError("vector dimension mismatch")

    async def ensure_collection(self, collection: str, *, dimension: int) -> None:
        if dimension < 1:
            raise VectorStoreError("dimension must be positive")
        if collection in self._dimensions and self._dimensions[collection] != dimension:
            raise VectorStoreError("collection dimension mismatch")
        self._dimensions[collection] = dimension
        self._collections.setdefault(collection, {})

    async def upsert(
        self, collection: str, chunks: Sequence[CodeChunk], embeddings: Sequence[Sequence[float]]
    ) -> None:
        if len(chunks) != len(embeddings):
            raise ValueError("chunks and embeddings must have equal lengths")
        entries = self._get(collection)
        for vector in embeddings:
            self._validate(collection, vector)
        entries.update(
            (chunk.chunk_id, (chunk, tuple(vector))) for chunk, vector in zip(chunks, embeddings, strict=True)
        )

    async def query(
        self,
        collection: str,
        embedding: Sequence[float],
        *,
        top_k: int = 8,
        where: MetadataFilter | None = None,
    ) -> list[RetrievedChunk]:
        entries = list(self._get(collection).values())
        self._validate(collection, embedding)
        filters = where.equals if where else {}
        if filters.keys() - {"path", "language", "kind", "symbol", "commit_sha"}:
            raise ValueError("unsupported metadata filter")
        results = []
        for chunk, vector in entries:
            if not all(
                getattr(chunk, key) in value if isinstance(value, tuple) else getattr(chunk, key) == value
                for key, value in filters.items()
            ):
                continue
            norm = math.sqrt(sum(x * x for x in embedding)) * math.sqrt(sum(x * x for x in vector))
            cosine = sum(a * b for a, b in zip(embedding, vector, strict=True)) / norm if norm else 0.0
            results.append(RetrievedChunk(chunk, min(1.0, max(0.0, cosine))))
        return sorted(results, key=lambda result: result.score, reverse=True)[: max(0, top_k)]

    async def delete_by_paths(self, collection: str, paths: Sequence[str]) -> int:
        entries = self._get(collection)
        wanted = set(paths)
        removed = [key for key, (chunk, _) in entries.items() if chunk.path in wanted]
        for key in removed:
            del entries[key]
        return len(removed)

    async def get_file_hashes(self, collection: str) -> dict[str, str]:
        return {chunk.path: chunk.content_hash for chunk, _ in self._get(collection).values()}

    async def drop_collection(self, collection: str) -> None:
        self._get(collection)
        del self._collections[collection]
        del self._dimensions[collection]
