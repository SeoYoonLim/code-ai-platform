"""T-105 fixture, rendering, and parser lifecycle regression tests."""

import itertools
import json
from pathlib import Path
from unittest.mock import patch

import pytest
from tests.conformance.chunker_suite import ChunkerConformance, t105_source
from tree_sitter_language_pack import get_parser

from engine.adapters.parsing.language_map import language_for_path
from engine.adapters.parsing.treesitter_chunker import TreeSitterChunker
from engine.core.errors import ParseError
from engine.core.models import ChunkKind, Language

FIXTURES = Path(__file__).resolve().parents[3] / "fixtures" / "chunking"


class TestTreeSitterChunker(ChunkerConformance):
    @pytest.fixture
    def chunker(self) -> TreeSitterChunker:
        return TreeSitterChunker()


@pytest.mark.parametrize("expected", sorted(FIXTURES.rglob("*.expected.json")))
def test_t105_spike_fixtures(expected: Path) -> None:
    path = Path(str(expected).removesuffix(".expected.json"))
    file = t105_source(path.read_bytes().decode(), language_for_path(path.name), path.name)
    chunks = TreeSitterChunker().chunk(file, project_id="p")
    assert [
        {"kind": c.kind.value, "symbol": c.symbol, "start_line": c.start_line, "end_line": c.end_line}
        for c in chunks
    ] == json.loads(expected.read_text())
    assert len({c.chunk_id for c in chunks}) == len(chunks)
    lines = file.content.split("\n")
    lines = [line + "\n" for line in lines[:-1]] + ([lines[-1]] if lines[-1] else [])
    covered = set()
    for c in chunks:
        selected = []
        for span in str(c.metadata.get("spans", f"{c.start_line}-{c.end_line}")).split(","):
            a, b = map(int, span.split("-"))
            selected.extend(range(a, b + 1))
        assert c.raw_code == "".join(lines[i - 1] for i in selected)
        covered.update(selected)
    assert covered == set(range(1, len(lines) + 1))


@pytest.mark.parametrize(
    ("size", "ranges"),
    [
        (200, [(1, 200)]),
        (201, [(1, 120), (101, 201)]),
        (220, [(1, 120), (101, 220)]),
        (221, [(1, 120), (101, 220), (201, 221)]),
        (251, [(1, 120), (101, 220), (201, 251)]),
    ],
)
def test_t105_window_boundaries(size: int, ranges: list[tuple[int, int]]) -> None:
    content = "def f():\r\n" + "\tpass # \ud55c\uae00\U0001f600\r\n" * (size - 1)
    chunks = TreeSitterChunker().chunk(t105_source(content), project_id="p")
    assert [(c.start_line, c.end_line) for c in chunks] == ranges
    assert all(c.kind == (ChunkKind.FUNCTION if size == 200 else ChunkKind.WINDOW) for c in chunks)
    lines = content.splitlines(keepends=True)
    for c in chunks:
        assert c.raw_code == "".join(lines[c.start_line - 1 : c.end_line])
    for a, b in itertools.pairwise(chunks):
        assert a.end_line - b.start_line + 1 == 20


@pytest.mark.parametrize(
    ("lang", "content"),
    [
        (Language.PYTHON, "def good():\n    return 1\ndef broken(:\n    pass\n"),
        (Language.PYTHON, "class Broken(\n"),
        (Language.PYTHON, "x = [1,\n"),
        (Language.TYPESCRIPT, "function good() { return 1; }\nconst broken = ( => ;"),
        (Language.TYPESCRIPT, "class Broken { method( {"),
    ],
)
def test_t105_damaged_whole_file(lang: Language, content: str) -> None:
    chunks = TreeSitterChunker().chunk(t105_source(content, lang), project_id="p")
    assert all(c.kind == ChunkKind.WINDOW for c in chunks)
    assert chunks[0].raw_code == content


def test_t105_eager_parsers_and_failures() -> None:
    with patch("engine.adapters.parsing.treesitter_chunker.cached_parser", side_effect=get_parser) as factory:
        chunker = TreeSitterChunker(parser_factory=factory)
        assert factory.call_count == 4
        with patch("builtins.open", side_effect=AssertionError("I/O forbidden")):
            chunker.chunk(t105_source("x=1"), project_id="p")
        assert factory.call_count == 4
    with pytest.raises(ParseError, match="python"):
        TreeSitterChunker(parser_factory=lambda _: (_ for _ in ()).throw(RuntimeError("loader failed")))
    with pytest.raises(ValueError, match="limits"):
        TreeSitterChunker(window_lines=20, overlap_lines=20)


def test_t105_render_module_and_golden() -> None:
    content = (
        "before()\nclass Box:\n    field = 1\n    @deco\n    def run(self):\n        secret()\nafter()\n"
    )
    chunks = TreeSitterChunker().chunk(t105_source(content), project_id="p")
    module, cls, _method = chunks
    assert module.metadata == {"spans": "1-1,7-7"}
    assert module.raw_code == "before()\nafter()\n"
    assert cls.raw_code == "".join(content.splitlines(keepends=True)[1:6])
    assert cls.search_text == (
        "# path: sample.py\n# symbol: Box (class, python)\n"
        "class Box:\n    field = 1\n    @deco\n    def run(self):\n        ...\n"
    )
    golden = json.loads((FIXTURES / "t105-render.golden.json").read_text())
    assert [
        {"chunk_id": c.chunk_id, "raw_code": c.raw_code, "search_text": c.search_text} for c in chunks
    ] == golden


@pytest.mark.parametrize(
    ("name", "lang"), [("t105-collisions.py", Language.PYTHON), ("t105-collisions.ts", Language.TYPESCRIPT)]
)
def test_t105_collision_fixtures(name: str, lang: Language) -> None:
    content = (FIXTURES / name).read_text()
    chunks = TreeSitterChunker().chunk(t105_source(content, lang, name), project_id="p")
    assert len(chunks) > len({c.symbol for c in chunks})
    assert len(chunks) == len({c.chunk_id for c in chunks})


@pytest.mark.parametrize("suffix", ["js", "jsx", "mjs", "cjs"])
def test_t105_javascript_grammars(suffix: str) -> None:
    file = t105_source("export const Foo = () => <div />;", Language.JAVASCRIPT, f"app.{suffix}")
    assert TreeSitterChunker().chunk(file, project_id="p")[0].symbol == "Foo"


def test_t105_cache_absence_never_downloads() -> None:
    with (
        patch("engine.adapters.parsing.treesitter_chunker.downloaded_languages", return_value=[]),
        patch("engine.adapters.parsing.treesitter_chunker.get_parser") as load,
        pytest.raises(ParseError, match=r"python.*download disabled"),
    ):
        TreeSitterChunker()
    load.assert_not_called()


def test_t105_nested_and_typescript_rendering() -> None:
    chunker = TreeSitterChunker()
    nested = "class Outer:\n    class Inner:\n        @deco\n        def run(self):\n            hidden()\n"
    chunks = chunker.chunk(t105_source(nested), project_id="p")
    for c in chunks:
        if c.kind == ChunkKind.CLASS:
            assert "hidden()" not in c.search_text
            assert "@deco" in c.search_text
            assert "..." in c.search_text
            assert "hidden()" in c.raw_code
    content = "export class Box { field = 1; run(x: number) { return x; } }"
    chunks = chunker.chunk(t105_source(content, Language.TYPESCRIPT, "box.ts"), project_id="p")
    assert chunks[0].search_text.endswith("export class Box { field = 1; run(x: number) { ... } }")
    assert chunks[0].raw_code == content
    assert language_for_path("other.txt") == Language.UNKNOWN


def test_t105_parse_binding_failure() -> None:
    parser = patch("engine.adapters.parsing.treesitter_chunker.extract", side_effect=ValueError("binding"))
    chunker = TreeSitterChunker()
    with parser, pytest.raises(ParseError, match=r"python.*binding"):
        chunker.chunk(t105_source("x=1"), project_id="p")
