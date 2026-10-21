"""engine.core.errors ↔ engine.v1.yaml EngineErrorCode 1:1 대응 검증."""

from pathlib import Path
from typing import Any

import yaml

from engine.core import errors

SPEC = Path(__file__).resolve().parents[4] / "contracts" / "openapi" / "engine.v1.yaml"


def _catalog() -> dict[str, dict[str, Any]]:
    spec = yaml.safe_load(SPEC.read_text(encoding="utf-8"))
    catalog: dict[str, dict[str, Any]] = spec["components"]["schemas"]["EngineErrorCode"]["x-error-catalog"]
    return catalog


def _core_error_classes() -> list[type[errors.EngineError]]:
    return [
        obj for obj in vars(errors).values() if isinstance(obj, type) and issubclass(obj, errors.EngineError)
    ]


def test_core_codes_match_spec_core_codes() -> None:
    core_codes = {cls.code for cls in _core_error_classes()}
    spec_core = {code for code, entry in _catalog().items() if entry["source"] == "core"}
    assert core_codes == spec_core


def test_core_codes_are_unique() -> None:
    classes = _core_error_classes()
    assert len({cls.code for cls in classes}) == len(classes)


def test_retryable_matches_spec() -> None:
    catalog = _catalog()
    for cls in _core_error_classes():
        assert cls.retryable is catalog[cls.code]["retryable"], cls.__name__
