"""생성된 Pydantic 모델(py_common.generated)이 계약 예시를 올바르게 파싱하는지 검증.

`make gen-py` 후 실행된다. 생성기 옵션 변경으로 discriminator/상속이 깨지는 것을 잡는다.
"""

import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from py_common.generated import backend_v1, engine_v1, github_webhook_v1, push_v1

EXAMPLES = Path(__file__).resolve().parents[3] / "contracts" / "events" / "examples"


def _example(name: str) -> dict[str, object]:
    data: dict[str, object] = json.loads((EXAMPLES / name).read_text(encoding="utf-8"))
    return data


@pytest.mark.parametrize(
    ("payload", "expected"),
    [
        ({"event": "meta", "stream_id": "s1", "request_id": "r1", "model": "m"}, engine_v1.StreamMetaEvent),
        ({"event": "token", "index": 0, "delta": "def"}, engine_v1.StreamTokenEvent),
        (
            {
                "event": "done",
                "finish_reason": "stop",
                "usage": {"prompt_tokens": 10, "completion_tokens": 3},
                "latency_ms": 120,
            },
            engine_v1.StreamDoneEvent,
        ),
    ],
)
def test_engine_stream_event_discriminates(payload: dict[str, object], expected: type) -> None:
    assert isinstance(engine_v1.StreamEvent.model_validate(payload).root, expected)


def test_engine_stream_error_event_carries_problem() -> None:
    event = engine_v1.StreamEvent.model_validate(
        {
            "event": "error",
            "error": {
                "type": "/problems/generation_timeout",
                "title": "Generation timed out",
                "status": 504,
                "code": "generation_timeout",
                "retryable": True,
            },
        }
    ).root
    assert isinstance(event, engine_v1.StreamErrorEvent)
    assert event.error.code == "generation_timeout"


def test_unknown_error_code_rejected() -> None:
    with pytest.raises(ValidationError):
        backend_v1.Problem.model_validate(
            {"type": "/problems/x", "title": "x", "status": 500, "code": "nope", "retryable": False}
        )


def test_backend_chat_stream_meta_has_message_id() -> None:
    event = backend_v1.ChatStreamEvent.model_validate(
        {"event": "meta", "stream_id": "s", "session_id": "cs1", "message_id": "m1", "model": "qwen"}
    ).root
    assert isinstance(event, backend_v1.ChatMetaEvent)
    assert event.message_id == "m1"


def test_backend_pages() -> None:
    page = backend_v1.FindingPage.model_validate(
        {"items": [], "page": {"offset": 0, "limit": 20, "total": 0}}
    )
    assert page.page.total == 0
    cursor = backend_v1.JobPage.model_validate({"items": [], "page": {"has_more": False}})
    assert cursor.page.next_cursor is None


def test_engine_metadata_filter() -> None:
    req = engine_v1.RetrieveRequest.model_validate(
        {"project_id": "p", "query": "q", "where": {"language": "python", "kind": ["function", "method"]}}
    )
    assert req.where is not None


@pytest.mark.parametrize("name", ["push.analysis-completed.json", "push.index-failed.json"])
def test_push_examples_parse(name: str) -> None:
    push_v1.PushMessage.model_validate(_example(name))


def test_push_rejects_non_string_data_value() -> None:
    with pytest.raises(ValidationError):
        push_v1.PushMessage.model_validate(_example("push.invalid.integer-data-value.json"))


def test_github_push_payload_parses() -> None:
    delivery = github_webhook_v1.GitHubWebhookDelivery.model_validate(_example("github-webhook.push.json"))
    push = github_webhook_v1.PushPayload.model_validate(delivery.payload)
    assert push.repository.id == 1296269
    assert push.ref == "refs/heads/main"
