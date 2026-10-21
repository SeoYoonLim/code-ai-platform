"""Validate and normalize embedding responses."""

import math

import httpx
from pydantic import BaseModel, ValidationError

from engine.core.errors import EmbeddingError


class Reply(BaseModel):
    embeddings: list[list[float]]


def vectors(response: httpx.Response, count: int, dimension: int) -> list[list[float]]:
    if not response.is_success:
        detail: dict[str, object] = {"status": response.status_code, "body": response.text[:300]}
        if response.status_code == 404:
            detail["hint"] = "run scripts/provision_ollama.py"
        raise EmbeddingError("Ollama HTTP error", detail=detail)
    try:
        rows = Reply.model_validate_json(response.content).embeddings
    except ValidationError as error:
        raise EmbeddingError("invalid Ollama response") from error
    if len(rows) != count:
        raise EmbeddingError("embedding count mismatch")
    result = []
    for row in rows:
        if len(row) != dimension:
            raise EmbeddingError("embedding dimension mismatch")
        norm = math.hypot(*row)
        if not math.isfinite(norm) or norm == 0:
            raise EmbeddingError("invalid embedding norm")
        result.append([value / norm for value in row])
    return result
