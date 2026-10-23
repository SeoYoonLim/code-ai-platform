"""Filesystem scan, using git's ignore rules when a .git entry exists."""

import asyncio
import os
from collections.abc import AsyncIterator, Callable, Sequence
from pathlib import Path

from engine.adapters.source.rules import EXCLUDED, classify, default_excluded
from engine.core.errors import EngineError
from engine.core.models import Language, ScanItem, SkippedFile


def walk_paths(root: Path) -> list[str]:
    paths: list[str] = []
    for directory, folders, files in os.walk(root):
        folders[:] = [name for name in folders if name not in EXCLUDED]
        paths.extend((Path(directory) / name).relative_to(root).as_posix() for name in files)
    return sorted(paths)


class FileSystemScanner:
    def __init__(self, *, language_for_path: Callable[[str], Language], max_file_bytes: int = 524288) -> None:
        self._language = language_for_path
        self._maximum = max_file_bytes

    async def _paths(self, root: Path) -> list[str]:
        if not await asyncio.to_thread(root.is_dir):
            raise EngineError("invalid source root", detail={"reason": "source_root_invalid"})
        if await asyncio.to_thread((root / ".git").exists):
            try:
                process = await asyncio.create_subprocess_exec(
                    "git",
                    "ls-files",
                    "-co",
                    "--exclude-standard",
                    "-z",
                    cwd=root,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE,
                )
            except FileNotFoundError:
                return await asyncio.to_thread(walk_paths, root)
            output, error = await process.communicate()
            if process.returncode:
                raise EngineError("git scan failed: " + error.decode("utf-8", errors="replace")[:200])
            return sorted({os.fsdecode(p) for p in output.split(b"\0") if p})
        return await asyncio.to_thread(walk_paths, root)

    async def scan(
        self,
        root: str,
        *,
        include_globs: Sequence[str] = (),
        exclude_globs: Sequence[str] = (),
        max_file_bytes: int | None = None,
    ) -> AsyncIterator[ScanItem]:
        max_file_bytes = self._maximum if max_file_bytes is None else max_file_bytes
        directory = Path(root)
        for path in await self._paths(directory):
            if default_excluded(path):
                continue
            try:
                data = await asyncio.to_thread(self._read, directory / path, max_file_bytes)
            except OSError:
                yield SkippedFile(path, "unreadable")
                continue
            yield classify(path, data, self._language, include_globs, exclude_globs, max_file_bytes)

    @staticmethod
    def _read(path: Path, maximum: int) -> bytes:
        with path.open("rb") as stream:
            return stream.read(maximum + 1)
