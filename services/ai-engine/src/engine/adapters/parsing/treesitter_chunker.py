"""Pure symbol chunking with eagerly loaded tree-sitter parsers."""

from collections.abc import Callable

from tree_sitter import Parser
from tree_sitter_language_pack import downloaded_languages, get_parser

from engine.adapters.parsing.extract import Candidate, extract, source_lines, windows
from engine.adapters.parsing.language_map import GRAMMARS, grammar_for_path
from engine.core.errors import ParseError
from engine.core.models import ChunkKind, CodeChunk, Language, SourceFile


def cached_parser(name: str) -> Parser:
    if name not in downloaded_languages():
        message = f"Grammar {name} absent from default cache; download disabled (run `make fetch-grammars`)"
        raise ParseError(message)
    return get_parser(name)


def spans(selected: tuple[int, ...]) -> str:
    groups: list[str] = []
    start = end = selected[0]
    for line in selected[1:]:
        if line == end + 1:
            end = line
        else:
            groups.append(f"{start}-{end}")
            start = end = line
    groups.append(f"{start}-{end}")
    return ",".join(groups)


class TreeSitterChunker:
    def __init__(
        self,
        *,
        max_chunk_lines: int = 200,
        window_lines: int = 120,
        overlap_lines: int = 20,
        parser_factory: Callable[[str], Parser] | None = None,
    ) -> None:
        if max_chunk_lines < 1 or window_lines < 1 or not 0 <= overlap_lines < window_lines:
            raise ValueError("invalid chunk/window limits")
        self._maximum = max_chunk_lines
        self._size = window_lines
        self._overlap = overlap_lines
        factory = parser_factory or cached_parser
        self._parsers: dict[str, Parser] = {}
        for name in GRAMMARS:
            try:
                self._parsers[name] = factory(name)
            except Exception as exc:
                # Native loader and injectable factories expose different exception classes.
                raise ParseError(f"Cannot load grammar {name}: {exc}") from exc

    def supports(self, language: Language) -> bool:
        return language in {Language.PYTHON, Language.TYPESCRIPT, Language.JAVASCRIPT}

    def chunk(
        self,
        file: SourceFile,
        *,
        project_id: str,
        commit_sha: str | None = None,
    ) -> list[CodeChunk]:
        data = file.content.encode("utf-8")
        if self.supports(file.language):
            parser = self._parsers[grammar_for_path(file.path, file.language)]
            try:
                candidates, _ = extract(data, parser, self._maximum, self._size, self._overlap)
            except Exception as exc:
                # Binding exceptions are adapter failures, distinct from syntax fallback.
                raise ParseError(f"Cannot parse {file.language.value}: {exc}") from exc
        else:
            lines = source_lines(data)
            candidates = windows(lines, 1, len(lines), self._size, self._overlap)
        return [self._chunk(file, candidate, project_id, commit_sha) for candidate in candidates]

    @staticmethod
    def _chunk(file: SourceFile, c: Candidate, project: str, commit: str | None) -> CodeChunk:
        metadata: dict[str, str | int | float | bool] = {}
        if c.kind == "module":
            metadata["spans"] = spans(c.source_lines)
        header = f"# path: {file.path}\n# symbol: {c.symbol} ({c.kind}, {file.language.value})\n"
        return CodeChunk(
            chunk_id=f"{project}:{file.path}::{c.symbol}@{c.start_line}-{c.end_line}",
            project_id=project,
            path=file.path,
            language=file.language,
            kind=ChunkKind(c.kind),
            symbol=c.symbol,
            raw_code=c.source_text,
            search_text=header + c.text,
            start_line=c.start_line,
            end_line=c.end_line,
            content_hash=file.content_hash,
            commit_sha=commit,
            metadata=metadata,
        )
