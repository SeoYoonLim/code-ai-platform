"""Check tracked source files against the repository's line limit."""

import argparse
import os
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path

EXTENSIONS = {".py", ".ts", ".tsx", ".dart"}
EXCLUDED_DIRS = {"generated", ".venv", "node_modules", ".dart_tool", "build", ".git"}
ROOT = Path(__file__).resolve().parents[1]


def excluded(path: Path) -> bool:
    """Return whether a relative path is generated or outside source scope."""
    return (
        bool(EXCLUDED_DIRS.intersection(path.parts))
        or path.as_posix() == "apps/web/src/lib/api/schema.d.ts"
        or path.parts[:4] == ("apps", "mobile", "packages", "api_client")
        or path.name.endswith(".g.dart")
        or path.suffix not in EXTENSIONS
    )


def source_files(root: Path, paths: Sequence[Path]) -> list[Path]:
    """Find tracked files, falling back to traversal when Git is unavailable."""
    try:
        result = subprocess.run(["git", "ls-files", "-z"], cwd=root, check=True, capture_output=True)
        candidates = [root / os.fsdecode(name) for name in result.stdout.split(b"\0") if name]
    except (FileNotFoundError, subprocess.CalledProcessError):
        candidates = []
        for directory, dirs, names in os.walk(root):
            dirs[:] = [name for name in dirs if name not in EXCLUDED_DIRS]
            candidates.extend(Path(directory) / name for name in names)
    selected = [path.resolve() for path in paths] or [root]
    return sorted(
        path
        for path in candidates
        if path.is_file()
        and not excluded(path.relative_to(root))
        and any(path == target or target in path.parents for target in selected)
    )


def main(argv: Sequence[str] | None = None, *, root: Path = ROOT) -> int:
    """Print path:lines for violations and return a process exit status."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max", type=int, default=300, dest="limit")
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args(argv)
    if args.limit < 1:
        parser.error("--max must be positive")
    failed = False
    for path in source_files(root, args.paths):
        with path.open("rb") as source:
            lines = sum(1 for _ in source)
        if lines > args.limit:
            sys.stdout.write(f"{path.relative_to(root).as_posix()}:{lines}\n")
            failed = True
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
