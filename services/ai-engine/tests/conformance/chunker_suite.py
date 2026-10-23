"""Language-independent CodeChunker acceptance rules."""

import pytest

from engine.core.interfaces.chunker import CodeChunker
from engine.core.models import ChunkKind, Language, SourceFile


def t105_source(content: str, language: Language = Language.PYTHON, path: str = "sample.py") -> SourceFile:
    return SourceFile(path, language, content, "hash")


class ChunkerConformance:
    @pytest.fixture
    def chunker(self) -> CodeChunker:
        raise NotImplementedError

    @pytest.mark.parametrize(
        "content", ["", "# comment\r\n", "def f():\n\treturn '\ud55c\uae00\U0001f600'", "x='a\u2028b'\n"]
    )
    def test_t105_conformance_source(self, chunker: CodeChunker, content: str) -> None:
        file = t105_source(content)
        chunks = chunker.chunk(file, project_id="p", commit_sha="abc")
        assert chunks == chunker.chunk(file, project_id="p", commit_sha="abc")
        assert len({c.chunk_id for c in chunks}) == len(chunks)
        lines = content.splitlines(keepends=True) if "\u2028" not in content else [content]
        covered: set[int] = set()
        for c in chunks:
            assert c.raw_code == "".join(lines[c.start_line - 1 : c.end_line])
            assert c.commit_sha == "abc"
            assert c.content_hash == "hash"
            assert c.chunk_id == f"p:{file.path}::{c.symbol}@{c.start_line}-{c.end_line}"
            covered.update(range(c.start_line, c.end_line + 1))
        assert covered == set(range(1, len(lines) + 1))

    def test_t105_conformance_support_and_fallback(self, chunker: CodeChunker) -> None:
        for lang in Language:
            assert chunker.supports(lang) == (
                lang in {Language.PYTHON, Language.TYPESCRIPT, Language.JAVASCRIPT}
            )
        for file in [
            t105_source("def good(): pass\ndef bad(:\n"),
            t105_source("hello\nworld", Language.UNKNOWN),
        ]:
            chunks = chunker.chunk(file, project_id="p")
            assert all(c.kind == ChunkKind.WINDOW for c in chunks)
            assert chunks[0].start_line == 1
            assert chunks[-1].end_line == 2
