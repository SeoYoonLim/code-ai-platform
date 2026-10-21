"""Hash-derived normalized embeddings."""

import hashlib
import math
from collections.abc import Sequence


class FakeEmbedder:
    def __init__(self, *, dimension: int = 16, model_name: str = "fake-embed") -> None:
        if dimension < 1:
            raise ValueError("dimension must be positive")
        self._dimension = dimension
        self._model_name = model_name
        self.calls: list[list[str]] = []

    @property
    def dimension(self) -> int:
        return self._dimension

    @property
    def model_name(self) -> str:
        return self._model_name

    def _embed(self, text: str) -> list[float]:
        seed = hashlib.sha256(text.encode()).digest()
        values = [
            int.from_bytes(hashlib.sha256(seed + str(i).encode()).digest()[:8], "big") / (2**64 - 1) * 2 - 1
            for i in range(self.dimension)
        ]
        norm = math.sqrt(sum(value * value for value in values))
        return [value / norm for value in values]

    async def embed_documents(self, texts: Sequence[str]) -> list[list[float]]:
        self.calls.append(list(texts))
        return [self._embed(text) for text in texts]

    async def embed_query(self, text: str) -> list[float]:
        self.calls.append([text])
        return self._embed(text)
