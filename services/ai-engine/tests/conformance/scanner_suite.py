"""Shared scanner contract, using a populated scanner/root fixture."""

from hashlib import sha256

import pytest

from engine.core.interfaces import SourceScanner
from engine.core.models import SkippedFile, SourceFile


class ScannerConformance:
    async def test_scan_sorted_deterministic_and_lossless(self, scanner: SourceScanner, root: str) -> None:
        first = [i async for i in scanner.scan(root)]
        assert first == [i async for i in scanner.scan(root)]
        assert [i.path for i in first] == sorted(i.path for i in first)
        files = {i.path: i for i in first if isinstance(i, SourceFile)}
        assert files["a.py"].content == "def f():\r\n    return 1\r\n"
        assert files["a.py"].content_hash == sha256(files["a.py"].content.encode()).hexdigest()
        assert not any("node_modules" in i.path or ".venv" in i.path for i in first)
        skipped = {i.path: i.reason for i in first if isinstance(i, SkippedFile)}
        assert skipped == {"binary.py": "binary", "unknown.xyz": "unsupported"}

    async def test_scan_size_and_glob_reasons(self, scanner: SourceScanner, root: str) -> None:
        items = [
            i
            async for i in scanner.scan(
                root, include_globs=["*.py"], exclude_globs=["nested/"], max_file_bytes=5
            )
        ]
        reasons = {i.path: i.reason for i in items if isinstance(i, SkippedFile)}
        assert reasons == {
            "a.py": "too_large",
            "binary.py": "binary",
            "nested/b.py": "excluded",
            "unknown.xyz": "excluded",
        }
        selected = [i async for i in scanner.scan(root, include_globs=["nested/**"], exclude_globs=["b.py"])]
        assert all(isinstance(i, SkippedFile) and i.reason == "excluded" for i in selected)

    @pytest.mark.parametrize("pattern", ["nested/*.py", "nested/**", "nested/", "b.py"])
    async def test_scan_glob_selection(self, scanner: SourceScanner, root: str, pattern: str) -> None:
        items = [i async for i in scanner.scan(root, include_globs=[pattern])]
        assert [i.path for i in items if isinstance(i, SourceFile)] == ["nested/b.py"]
