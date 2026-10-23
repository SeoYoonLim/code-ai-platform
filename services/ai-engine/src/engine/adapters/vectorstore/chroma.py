"""Chroma HTTP adapter; no client ownership or cached collection handles."""

from collections.abc import AsyncIterator, Sequence
from contextlib import asynccontextmanager
from typing import Literal

import chromadb
import httpx
import structlog
from chromadb.api import AsyncClientAPI
from chromadb.api.models.AsyncCollection import AsyncCollection
from chromadb.api.types import Where
from chromadb.errors import ChromaError, NotFoundError

from engine.adapters.vectorstore.chroma_codec import (
    collection_name,
    decode,
    encode,
    filters,
    validate_dimension,
)
from engine.core.errors import CollectionNotFound, VectorStoreError
from engine.core.models import CodeChunk, MetadataFilter, RetrievedChunk
from engine.settings import Settings

log = structlog.get_logger()


@asynccontextmanager
async def boundary() -> AsyncIterator[None]:
    try:
        yield
    except NotFoundError as error:
        raise CollectionNotFound(str(error)[:300]) from error
    except (ChromaError, httpx.HTTPError, ValueError, TypeError) as error:
        raise VectorStoreError(str(error)[:300]) from error


class ChromaVectorStore:
    def __init__(self, client: AsyncClientAPI, *, batch_size: int = 500) -> None:
        if batch_size <= 0:
            raise ValueError("batch_size must be positive")
        self._client = client
        self._batch_size = batch_size

    async def _get(self, name: str) -> AsyncCollection:
        async with boundary():
            return await self._client.get_collection(collection_name(name), embedding_function=None)

    async def ensure_collection(self, collection: str, *, dimension: int) -> None:
        if dimension < 1:
            raise VectorStoreError("dimension must be positive")
        async with boundary():
            handle = await self._client.get_or_create_collection(
                collection_name(collection),
                metadata={"dimension": dimension},
                configuration={"hnsw": {"space": "cosine"}},
                embedding_function=None,
            )
        validate_dimension(handle.metadata, [[0.0] * dimension])

    async def upsert(
        self, collection: str, chunks: Sequence[CodeChunk], embeddings: Sequence[Sequence[float]]
    ) -> None:
        if len(chunks) != len(embeddings):
            raise ValueError("chunks and embeddings must have equal lengths")
        handle = await self._get(collection)
        validate_dimension(handle.metadata, embeddings)
        for start in range(0, len(chunks), self._batch_size):
            batch = chunks[start : start + self._batch_size]
            vectors: list[Sequence[float] | Sequence[int]] = [
                list(v) for v in embeddings[start : start + self._batch_size]
            ]
            async with boundary():
                await handle.upsert(
                    ids=[chunk.chunk_id for chunk in batch],
                    embeddings=vectors,
                    documents=[chunk.search_text for chunk in batch],
                    metadatas=[encode(chunk) for chunk in batch],
                )

    async def query(
        self,
        collection: str,
        embedding: Sequence[float],
        *,
        top_k: int = 8,
        where: MetadataFilter | None = None,
    ) -> list[RetrievedChunk]:
        handle = await self._get(collection)
        validate_dimension(handle.metadata, [embedding])
        predicate, empty = filters(where)
        if top_k <= 0 or empty:
            return []
        vectors: list[Sequence[float] | Sequence[int]] = [list(embedding)]
        async with boundary():
            reply = await handle.query(
                query_embeddings=vectors,
                n_results=top_k,
                where=predicate,
                include=["documents", "metadatas", "distances"],
            )
            documents, metadatas, distances = reply["documents"], reply["metadatas"], reply["distances"]
            if documents is None or metadatas is None or distances is None:
                raise VectorStoreError("incomplete Chroma query result")
            results = []
            for ident, text, meta, distance in zip(
                reply["ids"][0], documents[0], metadatas[0], distances[0], strict=True
            ):
                if text is None or meta is None:
                    raise VectorStoreError("missing chunk payload")
                results.append(RetrievedChunk(decode(ident, text, meta), max(0.0, 1.0 - distance)))
            return sorted(results, key=lambda row: row.score, reverse=True)

    async def delete_by_paths(self, collection: str, paths: Sequence[str]) -> int:
        handle = await self._get(collection)
        if not paths:
            return 0
        choices: list[str | int | float | bool] = list(paths)
        operand: dict[Literal["$in", "$nin"], list[str | int | float | bool]] = {"$in": choices}
        predicate: Where = {"path": operand}
        async with boundary():
            result = await handle.delete(where=predicate)
            return result["deleted"]

    async def get_file_hashes(self, collection: str) -> dict[str, str]:
        handle = await self._get(collection)
        result: dict[str, str] = {}
        offset = 0
        while True:
            async with boundary():
                page = await handle.get(include=["metadatas"], limit=1000, offset=offset)
            for meta in page["metadatas"] or []:
                if meta is None:
                    raise VectorStoreError("missing chunk metadata")
                path, digest = meta["path"], meta["content_hash"]
                if not isinstance(path, str) or not isinstance(digest, str):
                    raise VectorStoreError("invalid file hash metadata")
                if path in result and result[path] != digest:
                    log.warning("inconsistent_file_hash", path=path)
                result[path] = digest
            if len(page["ids"]) < 1000:
                return result
            offset += 1000

    async def drop_collection(self, collection: str) -> None:
        async with boundary():
            await self._client.delete_collection(collection_name(collection))


async def connect(settings: Settings) -> ChromaVectorStore:
    async with boundary():
        url = settings.chroma_url
        client = await chromadb.AsyncHttpClient(
            host=str(url).rstrip("/"),
            port=url.port or (443 if url.scheme == "https" else 80),
            ssl=url.scheme == "https",
        )
        return ChromaVectorStore(client)
