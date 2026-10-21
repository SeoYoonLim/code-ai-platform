"""Validated llama-server wire payloads."""

import httpx
from pydantic import BaseModel, Field

from engine.core.errors import ContextTooLarge, EngineError, ProviderUnavailable
from engine.core.models import FinishReason, GenerationRequest, TokenUsage


class Message(BaseModel):
    content: str | None = None


class Choice(BaseModel):
    message: Message = Field(default_factory=Message)
    delta: Message = Field(default_factory=Message)
    finish_reason: str | None = None


class Usage(BaseModel):
    prompt_tokens: int
    completion_tokens: int


class Timings(BaseModel):
    prompt_n: int
    predicted_n: int


class Reply(BaseModel):
    choices: list[Choice] = Field(default_factory=list)
    usage: Usage | None = None
    timings: Timings | None = None

    def token_usage(self) -> TokenUsage:
        if self.usage is not None:
            return TokenUsage(self.usage.prompt_tokens, self.usage.completion_tokens)
        if self.timings is not None:
            return TokenUsage(self.timings.prompt_n, self.timings.predicted_n)
        raise EngineError("usage not provided")


class Adapter(BaseModel):
    id: int
    path: str


class Props(BaseModel):
    model_alias: str


def structured_format(schema: dict[str, object]) -> dict[str, object]:
    """Standard OpenAI form; build 11783 requires live confirmation."""
    return {"type": "json_schema", "json_schema": {"name": "response", "schema": schema}}


def payload(
    req: GenerationRequest, adapters: dict[str, int], model: str, *, stream: bool
) -> dict[str, object]:
    params = req.params
    body: dict[str, object] = {
        "model": model,
        "messages": [{"role": m.role.value, "content": m.content} for m in req.messages],
        "temperature": params.temperature,
        "top_p": params.top_p,
        "max_tokens": params.max_tokens,
        "stop": list(params.stop),
        "stream": stream,
        "lora": [
            {"id": ident, "scale": 1.0 if name == req.adapter else 0.0}
            for name, ident in sorted(adapters.items(), key=lambda item: item[1])
        ],
    }
    if params.seed is not None:
        body["seed"] = params.seed
    if req.json_schema is not None:
        body["response_format"] = structured_format(req.json_schema)
    if stream:
        body["stream_options"] = {"include_usage": True}
    return body


def finish(value: str | None) -> FinishReason:
    return {"stop": FinishReason.STOP, "length": FinishReason.LENGTH}.get(value or "", FinishReason.ERROR)


def check_status(response: httpx.Response) -> None:
    if response.is_success:
        return
    detail: dict[str, object] = {"status": response.status_code, "body": response.text[:300]}
    if response.status_code == 503:
        raise ProviderUnavailable("loading", detail=detail)
    if response.status_code == 400 and any(
        term in response.text.lower() for term in ("context size", "context length", "context window")
    ):
        raise ContextTooLarge("context too large", detail=detail)
    raise EngineError("llama-server HTTP error", detail=detail)
