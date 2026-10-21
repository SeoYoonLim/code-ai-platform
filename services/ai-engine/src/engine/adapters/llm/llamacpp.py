"""Request-local LoRA overrides over one reusable HTTP client."""

import asyncio
import time
from collections.abc import AsyncIterator
from contextlib import AsyncExitStack
from pathlib import PurePosixPath

import httpx
from pydantic import TypeAdapter, ValidationError

from engine.adapters.llm.llamacpp_wire import Adapter, Props, Reply, check_status, finish, payload
from engine.core.errors import AdapterNotFound, EngineError, GenerationTimeout, ProviderUnavailable
from engine.core.models import GenerationRequest, GenerationResult, ProviderHealth, TokenChunk
from engine.settings import Settings


class LlamaServerProvider:
    def __init__(self, settings: Settings | None = None, *, idle_timeout_s: float = 45.0) -> None:
        config = settings or Settings()
        headers = {}
        if config.llamacpp_api_key is not None:
            headers["Authorization"] = f"Bearer {config.llamacpp_api_key.get_secret_value()}"
        self._client = httpx.AsyncClient(base_url=str(config.llamacpp_url), headers=headers)
        self._model = config.base_model
        self._idle_timeout_s = idle_timeout_s
        self._adapters: dict[str, int] | None = None
        self._in_flight = 0

    @property
    def name(self) -> str:
        return "llamacpp"

    @property
    def in_flight(self) -> int:
        return self._in_flight

    async def aclose(self) -> None:
        await self._client.aclose()

    async def _refresh(self) -> None:
        response = await self._client.get("/lora-adapters", timeout=httpx.Timeout(10, connect=3))
        check_status(response)
        rows = TypeAdapter(list[Adapter]).validate_json(response.content)
        mapping = {PurePosixPath(row.path).stem: row.id for row in rows}
        if len(mapping) != len(rows):
            raise EngineError("duplicate adapter names")
        self._adapters = mapping

    async def _body(self, req: GenerationRequest, *, stream: bool) -> dict[str, object]:
        if self._adapters is None or (req.adapter is not None and req.adapter not in self._adapters):
            await self._refresh()
        adapters = self._adapters or {}
        if req.adapter is not None and req.adapter not in adapters:
            raise AdapterNotFound(f"adapter not loaded: {req.adapter}")
        return payload(req, adapters, self._model, stream=stream)

    async def generate(self, req: GenerationRequest) -> GenerationResult:
        self._in_flight += 1
        started = time.perf_counter()
        try:
            async with asyncio.timeout(req.timeout_s):
                body = await self._body(req, stream=False)
                response = await self._client.post(
                    "/v1/chat/completions", json=body, timeout=httpx.Timeout(req.timeout_s, connect=3)
                )
                check_status(response)
                reply = Reply.model_validate_json(response.content)
                if not reply.choices:
                    raise EngineError("missing completion choice")
                choice = reply.choices[0]
                return GenerationResult(
                    choice.message.content or "",
                    self._model,
                    req.adapter,
                    finish(choice.finish_reason),
                    reply.token_usage(),
                    int((time.perf_counter() - started) * 1000),
                )
        except (TimeoutError, httpx.TimeoutException) as error:
            raise GenerationTimeout("generation timed out") from error
        except httpx.RequestError as error:
            raise ProviderUnavailable("llama-server transport failed") from error
        except (ValidationError, ValueError) as error:
            raise EngineError("invalid llama-server response") from error
        finally:
            self._in_flight -= 1

    async def stream(self, req: GenerationRequest) -> AsyncIterator[TokenChunk]:
        self._in_flight += 1
        active = True
        try:
            remaining = req.timeout_s
            async with AsyncExitStack() as stack:
                started = time.perf_counter()
                async with asyncio.timeout(remaining):
                    body = await self._body(req, stream=True)
                    timeout = httpx.Timeout(req.timeout_s, connect=3, read=self._idle_timeout_s)
                    response = await stack.enter_async_context(
                        self._client.stream("POST", "/v1/chat/completions", json=body, timeout=timeout)
                    )
                    if not response.is_success:
                        await response.aread()
                        check_status(response)
                remaining -= time.perf_counter() - started
                index = 0
                reason = None
                usage = None
                done = False
                lines = response.aiter_lines()
                while True:
                    # Only upstream waits spend the budget; no timeout survives a yield.
                    started = time.perf_counter()
                    try:
                        async with asyncio.timeout(remaining):
                            line = await anext(lines)
                    except StopAsyncIteration:
                        break
                    remaining -= time.perf_counter() - started
                    if not line.startswith("data:"):
                        continue
                    data = line[5:].strip()
                    if data == "[DONE]":
                        done = True
                        break
                    reply = Reply.model_validate_json(data)
                    if reply.usage is not None or reply.timings is not None:
                        usage = reply.token_usage()
                    for choice in reply.choices:
                        if choice.delta.content:
                            yield TokenChunk(choice.delta.content, index)
                            index += 1
                        if choice.finish_reason is not None:
                            reason = finish(choice.finish_reason)
                if not done or reason is None:
                    raise ProviderUnavailable("stream ended before completion")
                if usage is None:
                    raise EngineError("usage not provided")
            self._in_flight -= 1
            active = False
            yield TokenChunk("", index, reason, usage)
        except (TimeoutError, httpx.TimeoutException) as error:
            raise GenerationTimeout("stream timed out") from error
        except httpx.RequestError as error:
            raise ProviderUnavailable("llama-server stream disconnected") from error
        except (ValidationError, ValueError) as error:
            raise EngineError("invalid llama-server stream") from error
        finally:
            if active:
                self._in_flight -= 1

    async def health(self) -> ProviderHealth:
        try:
            response = await self._client.get("/health", timeout=httpx.Timeout(3))
            check_status(response)
            if response.json().get("status") != "ok":
                raise ProviderUnavailable("unhealthy")
            await self._refresh()
            props = await self._client.get("/props", timeout=httpx.Timeout(3))
            check_status(props)
            self._model = Props.model_validate_json(props.content).model_alias
            return ProviderHealth(True, self.name, self._model, tuple(sorted(self._adapters or {})))
        except Exception as error:
            # Health is explicitly non-throwing, including malformed upstream payloads.
            return ProviderHealth(False, self.name, self._model, detail=str(error))
