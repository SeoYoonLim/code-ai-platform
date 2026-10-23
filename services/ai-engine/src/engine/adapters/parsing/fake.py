"""Preconfigured pure chunker for service tests without native parsers."""

from collections.abc import Sequence
from dataclasses import replace

from engine.core.models import CodeChunk, Language, SourceFile


class FakeCodeChunker:
    def __init__(self, chunks: Sequence[CodeChunk] = ()) -> None:
        self._chunks = tuple(chunks)

    def supports(self, language: Language) -> bool:
        return language in {Language.PYTHON, Language.TYPESCRIPT, Language.JAVASCRIPT}

    def chunk(self, file: SourceFile, *, project_id: str, commit_sha: str | None = None) -> list[CodeChunk]:
        return [
            replace(
                chunk,
                chunk_id=f"{project_id}:{file.path}::{chunk.symbol}@{chunk.start_line}-{chunk.end_line}",
                project_id=project_id,
                content_hash=file.content_hash,
                commit_sha=commit_sha,
                metadata=dict(chunk.metadata),
            )
            for chunk in self._chunks
            if chunk.path == file.path
        ]
