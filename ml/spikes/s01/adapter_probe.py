"""D1-D4 raw paired answers, schema validation and model-switch evidence."""

import argparse
import json
from pathlib import Path

from canary_data import MARKER, question
from serve_probe import api, generate
from vram_monitor import Monitor, write_json


def finding_schema(path: str) -> dict:
    """Resolve local references from the read-only engine.v1 contract."""
    import yaml

    schemas = yaml.safe_load(Path(path).read_text(encoding="utf-8"))["components"]["schemas"]

    def resolve(value):
        if isinstance(value, dict):
            if "$ref" in value:
                return resolve(schemas[value["$ref"].split("/")[-1]])
            return {key: resolve(item) for key, item in value.items()}
        if isinstance(value, list):
            return [resolve(item) for item in value]
        return value

    return {"type": "array", "items": resolve(schemas["Finding"])}


def main() -> None:
    """Do not assess subjective quality or choose a deployment plan."""
    import jsonschema

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="canary-v0")
    parser.add_argument("--base", default="qwen2.5-coder:7b-instruct-q4_K_M")
    parser.add_argument("--output", required=True)
    parser.add_argument("--schema", default="contracts/openapi/engine.v1.yaml")
    args = parser.parse_args()
    result = {"D1": {}, "D2": [], "D3": [], "D4": []}
    try:
        for model in (args.base, args.model):
            with Monitor() as model_monitor:
                answers = [generate(model, question(index, True), 8192) for index in range(20)]
            result["D1"][model] = {
                "answers": answers,
                "rate": sum(row["text"].startswith(MARKER) for row in answers) / 20,
                "vram": model_monitor.summary(),
            }
        for index in range(10):
            result["D2"].append(
                {
                    model: generate(model, question(index + 100, True), 8192)
                    for model in (args.base, args.model)
                }
            )
        schema = finding_schema(args.schema)
        for index in range(10):
            row = generate(
                args.model, "Return a Finding array for:\n" + question(index + 200, True), 8192, schema
            )
            try:
                jsonschema.validate(json.loads(row["text"]), schema)
                row["valid"] = True
            except (ValueError, jsonschema.ValidationError) as error:
                row.update(valid=False, validation_error=str(error))
            result["D3"].append(row)
        result["D3_rate"] = sum(row["valid"] for row in result["D3"]) / 10
        for index in range(10):
            model = args.model if index % 2 == 0 else args.base
            before = api("/api/ps")
            with Monitor() as monitor:
                response = generate(model, "Explain integer addition.", 8192)
            result["D4"].append(
                {
                    "model": model,
                    "response": response,
                    "before_ps": before,
                    "after_ps": api("/api/ps"),
                    **monitor.summary(),
                }
            )
        paired = "# D2 raw paired answers (quality assessment deferred to Claude)\n\n"
        for index, pair in enumerate(result["D2"]):
            paired += f"## Question {index + 1}\n\n{question(index + 100, True)}\n\n"
            for model, answer in pair.items():
                answer_html = answer["text"].replace("\n", "<br>")
                paired += f"### {model}\n\n{answer_html}\n\n"
        Path(args.output).with_name("quality_side_by_side.md").write_text(paired, encoding="utf-8")
        result["status"] = "ok"
    except Exception as error:
        result.update(status="failed", error=str(error))
    write_json(args.output, result)


if __name__ == "__main__":
    main()
