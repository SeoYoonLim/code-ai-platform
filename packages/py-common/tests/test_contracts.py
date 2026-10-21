"""contracts/ 구조 규칙 검증 (docs/architecture/03-api-conventions.md).

스펙 자체의 문법 검증 외에, 사람이 놓치기 쉬운 규약 위반을 잡는다:
에러 카탈로그 누락, Problem이 아닌 에러 응답, 페이지 스키마 형태, SSE 정책 누락, 이벤트 예시 불일치.
"""

import json
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import pytest
import yaml
from jsonschema import Draft202012Validator
from openapi_spec_validator import validate

ROOT = Path(__file__).resolve().parents[3]
OPENAPI_DIR = ROOT / "contracts" / "openapi"
EVENTS_DIR = ROOT / "contracts" / "events"
SPEC_FILES = sorted(OPENAPI_DIR.glob("*.v1.yaml"))
HTTP_METHODS = {"get", "post", "put", "patch", "delete"}

Spec = dict[str, Any]


def _load(path: Path) -> Spec:
    data: Spec = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data


def _resolve(spec: Spec, node: Spec) -> Spec:
    while "$ref" in node:
        parts = node["$ref"].removeprefix("#/").split("/")
        target: Any = spec
        for part in parts:
            target = target[part]
        node = target
    return node


def _operations(spec: Spec) -> Iterator[tuple[str, str, Spec]]:
    for path, item in spec["paths"].items():
        for method, op in item.items():
            if method in HTTP_METHODS:
                yield path, method, op


@pytest.fixture(params=SPEC_FILES, ids=lambda p: p.name)
def spec(request: pytest.FixtureRequest) -> Spec:
    path: Path = request.param
    return _load(path)


def test_specs_exist() -> None:
    assert {p.name for p in SPEC_FILES} == {"backend.v1.yaml", "engine.v1.yaml"}


def test_openapi_valid(spec: Spec) -> None:
    validate(spec)


def test_error_catalog_matches_enum(spec: Spec) -> None:
    schemas = spec["components"]["schemas"]
    code_schema = schemas[next(n for n in schemas if n.endswith("ErrorCode"))]
    catalog = code_schema["x-error-catalog"]
    assert set(code_schema["enum"]) == set(catalog)
    for code, entry in catalog.items():
        assert 400 <= entry["status"] <= 599, code
        assert isinstance(entry["retryable"], bool), code


def test_operation_ids_unique(spec: Spec) -> None:
    ids = [op["operationId"] for _, _, op in _operations(spec)]
    assert len(ids) == len(set(ids))


def test_every_operation_has_default_error(spec: Spec) -> None:
    for path, method, op in _operations(spec):
        if path.endswith("/health"):
            continue
        assert "default" in op["responses"], f"{method.upper()} {path}"


def test_error_responses_use_problem(spec: Spec) -> None:
    for path, method, op in _operations(spec):
        for status, resp in op["responses"].items():
            if status != "default" and int(status) < 400:
                continue
            content = _resolve(spec, resp)["content"]
            assert list(content) == ["application/problem+json"], f"{method.upper()} {path} {status}"
            schema_ref = content["application/problem+json"]["schema"]["$ref"]
            assert schema_ref == "#/components/schemas/Problem"


def test_page_schemas_shape(spec: Spec) -> None:
    schemas = spec["components"]["schemas"]
    page_infos = {"#/components/schemas/CursorPageInfo", "#/components/schemas/OffsetPageInfo"}
    for name, schema in schemas.items():
        if not name.endswith("Page"):
            continue
        assert set(schema["required"]) == {"items", "page"}, name
        assert schema["properties"]["page"]["$ref"] in page_infos, name


def test_paginated_operations_return_page(spec: Spec) -> None:
    for path, method, op in _operations(spec):
        params = {_resolve(spec, p)["name"] for p in op.get("parameters", [])}
        if not params & {"cursor", "offset"}:
            continue
        ok = op["responses"]["200"]["content"]["application/json"]["schema"]["$ref"]
        expected = "CursorPageInfo" if "cursor" in params else "OffsetPageInfo"
        page_ref = _resolve(spec, {"$ref": ok})["properties"]["page"]["$ref"]
        assert page_ref.endswith(expected), f"{method.upper()} {path}"


def test_sse_operations_declare_policy(spec: Spec) -> None:
    for path, method, op in _operations(spec):
        content = op["responses"].get("200", {}).get("content", {})
        if "text/event-stream" not in content:
            continue
        policy_ref = op["x-sse"]["policy"]
        policy = spec["components"][policy_ref.removeprefix("#/components/")]
        for key in ("retry_ms", "keepalive_interval_s", "idle_timeout_s", "resumable"):
            assert key in policy, f"{method.upper()} {path}: {key}"
        assert policy["keepalive_interval_s"] < policy["idle_timeout_s"]


# --- events -------------------------------------------------------------------
EVENT_SCHEMAS = {p.name.removesuffix(".v1.schema.json"): p for p in EVENTS_DIR.glob("*.v1.schema.json")}
EXAMPLES = sorted((EVENTS_DIR / "examples").glob("*.json"))


def _validator(prefix: str) -> Draft202012Validator:
    schema = json.loads(EVENT_SCHEMAS[prefix].read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def test_event_schemas_present() -> None:
    assert set(EVENT_SCHEMAS) == {"push", "github-webhook"}


@pytest.mark.parametrize("example", EXAMPLES, ids=lambda p: p.name)
def test_event_examples(example: Path) -> None:
    prefix = example.name.split(".")[0]
    errors = list(_validator(prefix).iter_errors(json.loads(example.read_text(encoding="utf-8"))))
    if ".invalid." in example.name:
        assert errors, f"{example.name} 은(는) 검증에 실패해야 한다"
    else:
        assert not errors, [e.message for e in errors]


def test_push_error_codes_exist_in_backend_spec() -> None:
    backend = _load(OPENAPI_DIR / "backend.v1.yaml")
    codes = set(backend["components"]["schemas"]["ErrorCode"]["enum"])
    for example in EXAMPLES:
        if example.name.startswith("push.") and ".invalid." not in example.name:
            data = json.loads(example.read_text(encoding="utf-8"))["data"]
            if "error_code" in data:
                assert data["error_code"] in codes
