"""Exercise the line checker through its CLI in isolated repositories."""

import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "check_file_lines.py"


def run_check(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    """Run the CLI with an isolated repository root."""
    code = (
        "import runpy, sys; from pathlib import Path; "
        "module = runpy.run_path(sys.argv[1]); "
        "sys.exit(module['main'](sys.argv[3:], root=Path(sys.argv[2])))"
    )
    return subprocess.run(
        [sys.executable, "-c", code, str(SCRIPT), str(root), *args],
        capture_output=True,
        text=True,
        check=False,
    )


def track(root: Path) -> None:
    """Stage fixture files so Git discovery includes them."""
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    subprocess.run(["git", "-C", str(root), "add", "."], check=True)


@pytest.mark.parametrize(("lines", "status"), [(0, 0), (300, 0), (301, 1)])
def test_default_limit(tmp_path: Path, lines: int, status: int) -> None:
    (tmp_path / "sample.py").write_text("# line\n" * lines)
    track(tmp_path)
    result = run_check(tmp_path)
    assert result.returncode == status
    assert result.stdout == ("sample.py:301\n" if status else "")


@pytest.mark.parametrize(
    "name",
    [
        "pkg/generated/model.py",
        "apps/web/src/lib/api/schema.d.ts",
        "apps/mobile/packages/api_client/model.dart",
        ".venv/test.py",
        "node_modules/test.ts",
        ".dart_tool/test.dart",
        "build/test.tsx",
        "model.g.dart",
        "notes.md",
    ],
)
def test_exclusions(tmp_path: Path, name: str) -> None:
    file = tmp_path / name
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text("line\n" * 301)
    track(tmp_path)
    assert run_check(tmp_path).returncode == 0


def test_custom_limit_and_paths(tmp_path: Path) -> None:
    file = tmp_path / "sample.tsx"
    file.write_text("line\n" * 3)
    track(tmp_path)
    assert run_check(tmp_path, "--max", "3", str(file)).returncode == 0
    result = run_check(tmp_path, "--max", "2", str(file))
    assert result.returncode == 1
    assert result.stdout == "sample.tsx:3\n"


def test_untracked_ignored(tmp_path: Path) -> None:
    track(tmp_path)
    (tmp_path / "untracked.py").write_text("line\n" * 301)
    assert run_check(tmp_path).returncode == 0


def test_traversal_fallback(tmp_path: Path) -> None:
    (tmp_path / "sample.dart").write_text("line\n" * 301)
    assert run_check(tmp_path).returncode == 1
