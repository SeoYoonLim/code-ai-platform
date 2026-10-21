"""Reusable Ollama client with explicit device options."""

import time
from collections.abc import Callable, Sequence

import httpx

from engine.adapters.embeddings.device_policy import DevicePolicy, Policy
from engine.adapters.embeddings.ollama_wire import vectors
from engine.core.errors import EmbeddingError
from engine.core.interfaces.activity import ActivityGauge


class OllamaEmbedder:
    def __init__(
        self,
        *,
        base_url: str,
        model: str = "nomic-embed-text",
        dimension: int = 768,
        batch_size: int = 32,
        gauge: ActivityGauge | None = None,
        policy: Policy = "dynamic",
        idle_grace_s: float = 3.0,
        min_dwell_s: float = 10.0,
        clock: Callable[[], float] = time.monotonic,
        client: httpx.AsyncClient | None = None,
        doc_prefix: str = "search_document: ",
        query_prefix: str = "search_query: ",
    ) -> None:
        if dimension <= 0 or batch_size <= 0:
            raise ValueError("dimension and batch_size must be positive")
        self._policy = DevicePolicy(gauge, policy, idle_grace_s, min_dwell_s, clock)
        self._client = client if client is not None else httpx.AsyncClient()
        self._url = base_url.rstrip("/") + "/api/embed"
        self._model = model
        self._dimension = dimension
        self._batch_size = batch_size
        self._doc_prefix = doc_prefix
        self._query_prefix = query_prefix

    @property
    def model_name(self) -> str:
        return self._model

    @property
    def dimension(self) -> int:
        return self._dimension

    async def aclose(self) -> None:
        await self._client.aclose()

    async def embed_documents(self, texts: Sequence[str]) -> list[list[float]]:
        result: list[list[float]] = []
        for start in range(0, len(texts), self._batch_size):
            batch = [self._doc_prefix + text for text in texts[start : start + self._batch_size]]
            self._policy.decide()
            result.extend(await self._request(batch))
        return result

    async def embed_query(self, text: str) -> list[float]:
        return (await self._request([self._query_prefix + text]))[0]

    async def _request(self, texts: list[str]) -> list[list[float]]:
        body = {
            "model": self._model,
            "input": texts,
            "options": {"num_gpu": self._policy.mode.value},
            "keep_alive": "30m",
            "truncate": True,
        }
        try:
            response = await self._client.post(self._url, json=body, timeout=httpx.Timeout(60, connect=3))
        except httpx.RequestError as error:
            raise EmbeddingError("Ollama transport failed") from error
        return vectors(response, len(texts), self._dimension)
