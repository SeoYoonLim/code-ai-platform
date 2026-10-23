"""Read-only T-105 repository measurement; run from the workspace root."""

import json
import math
import statistics
import sys
from pathlib import Path
from time import perf_counter

from engine.adapters.parsing.extract import source_lines
from engine.adapters.parsing.treesitter_chunker import TreeSitterChunker
from engine.core.models import CodeChunk, Language, SourceFile


def t105_selected(chunk: CodeChunk) -> list[int]:
    selected: list[int] = []
    for span in str(chunk.metadata.get("spans", f"{chunk.start_line}-{chunk.end_line}")).split(","):
        start, end = map(int, span.split("-"))
        selected.extend(range(start, end + 1))
    return selected


def t105_measure_repo(
    chunker: TreeSitterChunker, name: str, language: Language, extension: str
) -> dict[str, object]:
    root = Path(".data/spike-repos") / name
    if not root.is_dir():
        raise RuntimeError(f"Missing read-only checkout: {root}")
    times: list[float] = []
    collisions = loc = total = missing = errors = maximum = 0
    for path in sorted(root.rglob("*")):
        if path.suffix != extension or {".git", "node_modules"} & set(path.parts):
            continue
        content = path.read_bytes().decode("utf-8")
        lines = source_lines(content.encode())
        file = SourceFile(path.relative_to(root).as_posix(), language, content, "measurement")
        elapsed: list[float] = []
        for _ in range(3):
            start = perf_counter()
            chunks = chunker.chunk(file, project_id="t105")
            elapsed.append((perf_counter() - start) * 1000)
        assert chunks == chunker.chunk(file, project_id="t105")
        times.append(statistics.median(elapsed) / max(len(lines), 1) * 1000)
        ids = [c.chunk_id for c in chunks]
        collisions += len(ids) - len(set(ids))
        covered: set[int] = set()
        for chunk in chunks:
            selected = t105_selected(chunk)
            assert chunk.raw_code == "".join(lines[i - 1] for i in selected), (path, chunk.symbol)
            covered.update(selected)
            if chunk.kind.value == "module":
                maximum = max(maximum, len(selected))
        missing += len(set(range(1, len(lines) + 1)) - covered)
        errors += int(bool(chunks) and all(c.kind.value == "window" for c in chunks))
        total += len(chunks)
        loc += len(lines)
    if not times:
        raise RuntimeError(f"No {extension} sources in {root}")
    return {
        "repo": name,
        "files": len(times),
        "loc": loc,
        "chunks": total,
        "id_collisions": collisions,
        "missing_lines": missing,
        "p95_ms_1k_loc": sorted(times)[math.ceil(len(times) * 0.95) - 1],
        "whole_window_files": errors,
        "max_module_lines": maximum,
    }


def t105_measure_main() -> None:
    chunker = TreeSitterChunker()
    for name, language, extension in [("httpx", Language.PYTHON, ".py"), ("zod", Language.TYPESCRIPT, ".ts")]:
        result = t105_measure_repo(chunker, name, language, extension)
        sys.stdout.write(json.dumps(result) + "\n")
        assert result["id_collisions"] == 0
        assert result["missing_lines"] == 0
        assert float(str(result["p95_ms_1k_loc"])) < 50


if __name__ == "__main__":
    t105_measure_main()
