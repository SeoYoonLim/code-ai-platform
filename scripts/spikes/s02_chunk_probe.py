"""Offline S-02 probe. Refuses automatic grammar downloads."""

import argparse
import json
import math
import random
import sys
from collections import Counter
from importlib.metadata import version
from pathlib import Path
from time import perf_counter

from s02_chunk_core import s02_chunk_ids, s02_extract, s02_source_lines, s02_windows
from tree_sitter import Parser, Query, QueryCursor
from tree_sitter_language_pack import cache_dir, downloaded_languages, get_language

FIXTURES = Path("services/ai-engine/tests/fixtures/chunking")


def s02_load_parser(language: str) -> Parser:
    if language not in downloaded_languages():
        raise RuntimeError(f"Grammar {language!r} absent from {cache_dir()}; download disabled")
    grammar = get_language(language)
    parser = Parser(grammar)
    # Exercise the 0.26 Query API, independently of language-specific node names.
    QueryCursor(Query(grammar, "(_) @node")).captures(parser.parse(b"x").root_node)
    return parser


def s02_fixture_check() -> dict[str, object]:
    checked = []
    for expected_path in sorted(FIXTURES.rglob("*.expected.json")):
        source = Path(str(expected_path).replace(".expected.json", ""))
        language = (
            "tsx" if source.suffix == ".tsx" else ("python" if source.suffix == ".py" else "typescript")
        )
        parser = s02_load_parser(language)
        data = source.read_bytes()
        chunks, _ = s02_extract(data, parser)
        assert [c.summary() for c in chunks] == json.loads(expected_path.read_text("utf-8"))
        assert chunks == s02_extract(data, parser)[0], source
        assert s02_chunk_ids(chunks, source.as_posix()) == s02_chunk_ids(
            s02_extract(data, parser)[0], source.as_posix()
        )
        checked.append(source.as_posix())
    assert len(checked) == 8
    parser = s02_load_parser("python")
    for data in [b"", b"# comment\n", b"def f():\n\treturn 1"]:
        assert s02_extract(data, parser) == s02_extract(data, parser)
    damaged = [
        ("python", b"def good():\n    return 1\ndef broken(:\n    pass\n"),
        ("python", b"class Broken(\n"),
        ("python", b"x = [1,\n"),
        ("typescript", b"function good() { return 1; }\nconst broken = ( => ;"),
        ("typescript", b"class Broken { method( {"),
    ]
    diagnostics = []
    for language, data in damaged:
        active = s02_load_parser(language)
        chunks, error = s02_extract(data, active)
        assert error
        assert all(c.kind == "window" for c in chunks)
        tree = active.parse(data)
        stack = [tree.root_node]
        errors = missing = 0
        while stack:
            node = stack.pop()
            errors += node.is_error
            missing += node.is_missing
            stack.extend(node.children)
        diagnostics.append(
            {
                "language": language,
                "input": data.decode(),
                "ERROR": errors,
                "MISSING": missing,
                "chunks": [c.summary() for c in chunks],
            }
        )
    return {"checked": checked, "damaged_files": len(damaged), "damage_diagnostics": diagnostics}


def s02_boundary_check() -> dict[str, object]:
    # Runnable without a grammar; assertions independently specify window boundaries.
    assert s02_windows([], 1, 0) == []
    lines = [f"line {i}\r\n" for i in range(1, 252)]
    chunks = s02_windows(lines, 1, 251)
    assert [(c.start_line, c.end_line) for c in chunks] == [(1, 120), (101, 220), (201, 251)]
    assert chunks[0].text.splitlines()[-20:] == chunks[1].text.splitlines()[:20]
    assert chunks == s02_windows(lines, 1, 251)
    return {"window_checks": "empty, 251 lines, CRLF, 20 overlap, deterministic: passed"}


def s02_measure(repo: Path, language: str) -> dict[str, object]:
    parser = s02_load_parser(language)
    extensions = {".py"} if language == "python" else {".ts"}
    records = []
    timings = []
    sizes = []
    total_lines = errors = missing = window_count = chunk_count = 0
    nodes: set[str] = set()
    kinds: Counter[str] = Counter()
    error_paths = []
    collisions = 0
    collision_examples = []
    syntax_windows = 0
    audits = []
    for path in sorted(repo.rglob("*")):
        if path.suffix not in extensions or {"node_modules", ".git"} & set(path.parts):
            continue
        data = path.read_bytes()
        active = s02_load_parser("tsx") if path.suffix == ".tsx" else parser
        elapsed_runs = []
        for _ in range(3):
            begin = perf_counter()
            chunks, error = s02_extract(data, active)
            elapsed_runs.append((perf_counter() - begin) * 1000)
        assert chunks == s02_extract(data, active)[0], path
        elapsed = sorted(elapsed_runs)[1]
        lines = s02_source_lines(data)
        timings.append(elapsed / max(len(lines), 1) * 1000)
        total_lines += len(lines)
        errors += error
        if error:
            error_paths.append(path.relative_to(repo).as_posix())
        covered = {i for c in chunks for i in c.source_lines}
        missing += len(set(range(1, len(lines) + 1)) - covered)
        chunk_count += len(chunks)
        window_count += sum(c.kind == "window" for c in chunks)
        if error:
            syntax_windows += len(chunks)
        kinds.update(c.kind for c in chunks)
        ids = s02_chunk_ids(chunks, path.relative_to(repo).as_posix())
        assert ids == s02_chunk_ids(s02_extract(data, active)[0], path.relative_to(repo).as_posix())
        collisions += len(ids) - len(set(ids))
        collision_examples.extend(
            {"id": key, "count": count} for key, count in Counter(ids).items() if count > 1
        )
        for chunk in chunks:
            sizes.append(len(chunk.text.splitlines()))
            records.append((path.relative_to(repo).as_posix(), chunk, lines))
        tree = active.parse(data)
        stack = [tree.root_node]
        while stack:
            node = stack.pop()
            nodes.add(node.type)
            stack.extend(node.named_children)
    sampled = random.Random(20261023).sample(records, min(30, len(records)))
    for path, chunk, lines in sampled:
        assert chunk.source_text == "".join(lines[chunk.start_line - 1 : chunk.end_line])
        if chunk.kind not in {"class", "module"}:
            assert chunk.text == "".join(lines[chunk.start_line - 1 : chunk.end_line])
        audits.append(
            {
                "path": path,
                **chunk.summary(),
                "source_slice_match": True,
                "rendered_slice_match": chunk.text == chunk.source_text,
            }
        )
    assert missing == 0

    def percentile(values: list[float], fraction: float) -> float:
        return sorted(values)[max(0, math.ceil(len(values) * fraction) - 1)] if values else 0

    return {
        "repo": str(repo),
        "files": len(timings),
        "lines": total_lines,
        "chunks": chunk_count,
        "parse_error_files": errors,
        "parse_error_paths": error_paths,
        "missing_lines": missing,
        "range_samples": len(sampled),
        "range_accuracy": 1.0 if sampled else 0.0,
        "coverage": (total_lines - missing) / total_lines if total_lines else 1.0,
        "range_audit": audits,
        "id_collisions": collisions,
        "id_collision_examples": collision_examples,
        "deterministic_files": len(timings),
        "kind_counts": dict(kinds),
        "largest_chunk": max(
            ({"path": p, **c.summary(), "rendered_lines": len(c.text.splitlines())} for p, c, _ in records),
            key=lambda entry: entry["rendered_lines"],
            default=None,
        ),
        "timing_repeats": 3,
        "ms_per_1k_loc_p95": percentile(timings, 0.95),
        "chunk_lines_p50": percentile(sizes, 0.5),
        "chunk_lines_p95": percentile(sizes, 0.95),
        "chunk_lines_max": max(sizes, default=0),
        "window_chunk_ratio": window_count / max(chunk_count, 1),
        "syntax_window_chunks": syntax_windows,
        "oversize_window_chunks": window_count - syntax_windows,
        "node_types": sorted(nodes),
        "previews": [
            f"# path: {p}\n# symbol: {c.symbol} ({c.kind}, {language})\n{c.text}" for p, c, _ in sampled[:5]
        ],
    }


def s02_main() -> int:
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("repo_path", nargs="?", type=Path)
    args.add_argument("--lang", choices=["python", "typescript"])
    args.add_argument("--json", type=Path)
    args.add_argument("--check", action="store_true")
    args.add_argument("--boundaries", action="store_true")
    options = args.parse_args()
    result: dict[str, object] = {
        "versions": {name: version(name) for name in ["tree-sitter", "tree-sitter-language-pack"]}
    }
    try:
        if options.boundaries:
            result.update(s02_boundary_check())
        elif options.check:
            result.update(s02_fixture_check())
        elif options.repo_path and options.lang:
            result.update(s02_measure(options.repo_path, options.lang))
        else:
            for language in ["python", "typescript", "tsx", "javascript"]:
                s02_load_parser(language)
        code = 0
    except RuntimeError as exc:
        result["blocked"] = str(exc)
        code = 2
    output = json.dumps(result, ensure_ascii=True, indent=2)
    sys.stdout.write(output + "\n")
    if options.json:
        # Compact JSON keeps evidence files within the repository's 300-line rule.
        options.json.write_text(json.dumps(result, ensure_ascii=True) + "\n", encoding="utf-8")
    return code


if __name__ == "__main__":
    raise SystemExit(s02_main())
