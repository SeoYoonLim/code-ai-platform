"""Execute entrypoint argument assembly with a local stand-in for llama-server."""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]


@pytest.mark.parametrize("names", [[], ["b.gguf", "a.gguf"]])
def test_entrypoint_arguments(tmp_path: Path, names: list[str]) -> None:
    bash = shutil.which("bash")
    assert bash is not None
    adapters = tmp_path / "adapters"
    adapters.mkdir()
    for name in names:
        (adapters / name).touch()
    (adapters / "ignored.txt").touch()
    binary = tmp_path / "server"
    binary.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n', encoding="utf-8")
    script = (ROOT / "infra/llama/entrypoint.sh").read_text(encoding="utf-8")
    script = script.replace("/app/llama-server", f"/bin/sh {binary.as_posix()}")
    script = script.replace("/adapters/", f"{adapters.as_posix()}/")
    local = tmp_path / "entrypoint.sh"
    local.write_text(script, encoding="utf-8")
    result = subprocess.run([bash, str(local)], capture_output=True, text=True, check=False)
    assert result.returncode == 0, result.stderr
    args = result.stdout.splitlines()
    assert args[:2] == ["-m", "/models/qwen2.5-coder-7b-instruct-q4_k_m.gguf"]
    assert args[-16:] == [
        "-ngl",
        "99",
        "-c",
        "32768",
        "-np",
        "2",
        "-fa",
        "on",
        "-ctk",
        "q8_0",
        "-ctv",
        "q8_0",
        "--host",
        "0.0.0.0",
        "--port",
        "8080",
    ]
    if names:
        assert args[2:4] == [
            "--lora",
            ",".join(str(adapters / name).replace("\\", "/") for name in sorted(names)),
        ]
    else:
        assert "--lora" not in args
