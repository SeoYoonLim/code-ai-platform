"""Deterministic source scanner for service tests."""

from collections.abc import AsyncIterator, Callable, Sequence

from engine.adapters.source.rules import classify, default_excluded
from engine.core.models import Language, ScanItem


class InMemoryScanner:
    def __init__(
        self, files: dict[str, str | bytes], *, language_for_path: Callable[[str], Language]
    ) -> None:
        self.files = files
        self._language = language_for_path

    async def scan(
        self,
        root: str,
        *,
        include_globs: Sequence[str] = (),
        exclude_globs: Sequence[str] = (),
        max_file_bytes: int = 524288,
    ) -> AsyncIterator[ScanItem]:
        for path in sorted(self.files):
            if default_excluded(path):
                continue
            value = self.files[path]
            data = value.encode("utf-8") if isinstance(value, str) else value
            yield classify(path, data, self._language, include_globs, exclude_globs, max_file_bytes)
