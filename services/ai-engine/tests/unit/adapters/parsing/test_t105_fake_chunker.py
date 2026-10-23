"""Preconfigured service fake needs neither grammar loading nor source I/O."""

from collections.abc import Callable

from engine.adapters.parsing.fake import FakeCodeChunker
from engine.core.interfaces import CodeChunker
from engine.core.models import CodeChunk, Language, SourceFile


def test_t105_fake_chunker_configured_and_empty(chunk_factory: Callable[[int], CodeChunk]) -> None:
    chunk = chunk_factory(0)
    fake: CodeChunker = FakeCodeChunker([chunk])
    source = SourceFile(chunk.path, chunk.language, chunk.raw_code, "newhash")
    result = fake.chunk(source, project_id="new", commit_sha="commit")
    assert result[0].raw_code == chunk.raw_code
    assert result[0].search_text == chunk.search_text
    assert result[0].chunk_id == f"new:{chunk.path}::{chunk.symbol}@1-1"
    assert result[0].content_hash == "newhash"
    assert result[0].commit_sha == "commit"
    assert fake.chunk(SourceFile("absent", Language.UNKNOWN, "", "hash"), project_id="new") == []
    assert FakeCodeChunker().chunk(source, project_id="new") == []
    assert fake.supports(Language.PYTHON)
    assert not fake.supports(Language.UNKNOWN)
