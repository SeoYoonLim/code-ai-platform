"""Lossless chunk encoding and shared injective collection names."""

import re
from collections.abc import Sequence
from typing import Literal

from chromadb.api.types import Metadata, Where

from engine.core.errors import VectorStoreError
from engine.core.models import ChunkKind, CodeChunk, Language, MetadataFilter


def collection_name(value: str) -> str:
    # Escape both reserved prefixes: short names and their prefixed counterparts
    # cannot collide. Escaping every trailing x makes the suffix map injective.
    if len(value) < 3 or value.startswith(("c_", "e_")):
        value = "c_" + value if len(value) < 3 else "e_" + value
    if value.endswith(("-", "_", ".", "x")):
        value += "x"
    if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9._-]{1,510}[a-zA-Z0-9]", value):
        raise VectorStoreError("unsupported collection name")
    return value


def encode(chunk: CodeChunk) -> Metadata:
    meta: dict[str, str | int | float | bool] = {
        "project_id": chunk.project_id,
        "path": chunk.path,
        "language": chunk.language.value,
        "kind": chunk.kind.value,
        "symbol": chunk.symbol,
        "start_line": chunk.start_line,
        "end_line": chunk.end_line,
        "content_hash": chunk.content_hash,
    }
    if chunk.commit_sha is not None:
        meta["commit_sha"] = chunk.commit_sha
    meta.update({"m_" + key: value for key, value in chunk.metadata.items()})
    return meta


def decode(ident: str, text: str, meta: Metadata) -> CodeChunk:
    # Metadata is Chroma's scalar union; validate the stored shape before decoding.
    def string(key: str) -> str:
        value = meta[key]
        if not isinstance(value, str):
            raise VectorStoreError("invalid chunk metadata")
        return value

    start, end = meta["start_line"], meta["end_line"]
    if not isinstance(start, int) or not isinstance(end, int):
        raise VectorStoreError("invalid chunk lines")
    commit = meta.get("commit_sha")
    if commit is not None and not isinstance(commit, str):
        raise VectorStoreError("invalid commit sha")
    user = {
        key[2:]: value
        for key, value in meta.items()
        if key.startswith("m_") and isinstance(value, (str, int, float, bool))
    }
    return CodeChunk(
        ident,
        string("project_id"),
        string("path"),
        Language(string("language")),
        ChunkKind(string("kind")),
        string("symbol"),
        text,
        start,
        end,
        string("content_hash"),
        commit,
        user,
    )


def filters(where: MetadataFilter | None) -> tuple[Where | None, bool]:
    values = where.equals if where else {}
    if values.keys() - {"path", "language", "kind", "symbol", "commit_sha"}:
        raise ValueError("unsupported metadata filter")
    clauses: list[Where] = []
    empty = False
    for key, value in values.items():
        if value is None or (isinstance(value, tuple) and any(item is None for item in value)):
            raise ValueError("None metadata filter")
        if isinstance(value, tuple):
            empty |= not value
            choices: list[str | int | float | bool] = list(value)
            operand: dict[Literal["$in", "$nin"], list[str | int | float | bool]] = {"$in": choices}
            clauses.append({key: operand})
        else:
            clauses.append({key: value})
    return (None if not clauses else clauses[0] if len(clauses) == 1 else {"$and": clauses}), empty


def validate_dimension(metadata: Metadata | None, vectors: Sequence[Sequence[float]]) -> None:
    dimension = (metadata or {}).get("dimension")
    if not isinstance(dimension, int) or dimension < 1:
        raise VectorStoreError("collection dimension metadata missing or invalid")
    if any(len(vector) != dimension for vector in vectors):
        raise VectorStoreError("vector dimension mismatch")
