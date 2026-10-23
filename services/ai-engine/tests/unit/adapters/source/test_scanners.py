"""Both scanners inherit exactly the same behavioral suite."""

import asyncio
import shutil
import subprocess
from pathlib import Path
from unittest.mock import patch

import pytest

from engine.adapters.parsing.language_map import language_for_path
from engine.adapters.source.fake import InMemoryScanner
from engine.adapters.source.git_scanner import FileSystemScanner
from engine.core.errors import EngineError
from engine.core.interfaces import SourceScanner
from engine.core.models import SkippedFile
from tests.conformance.scanner_suite import ScannerConformance

FILES = {
    "a.py": b"def f():\r\n    return 1\r\n",
    "nested/b.py": b"x=1\n",
    "binary.py": b"\xff",
    "unknown.xyz": b"x",
    "node_modules/hidden.py": b"x",
    ".venv/hidden.py": b"x",
}


class TestMemoryScanner(ScannerConformance):
    @pytest.fixture
    def scanner(self) -> SourceScanner:
        return InMemoryScanner(dict(FILES), language_for_path=language_for_path)

    @pytest.fixture
    def root(self) -> str:
        return "memory"


class TestDiskScanner(ScannerConformance):
    @pytest.fixture
    def scanner(self) -> SourceScanner:
        return FileSystemScanner(language_for_path=language_for_path)

    @pytest.fixture
    def root(self, tmp_path: Path) -> str:
        for name, data in FILES.items():
            path = tmp_path / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        return str(tmp_path)


@pytest.mark.parametrize("is_file", [False, True])
async def test_disk_scanner_invalid_root_first_iteration(tmp_path: Path, is_file: bool) -> None:
    root = tmp_path / "invalid"
    if is_file:
        root.write_text("x")
    iterator = FileSystemScanner(language_for_path=language_for_path).scan(str(root))
    with pytest.raises(EngineError) as caught:
        await anext(iterator)
    assert caught.value.detail == {"reason": "source_root_invalid"}


async def test_disk_scanner_unreadable_and_configured_limit(tmp_path: Path) -> None:
    (tmp_path / "a.py").write_bytes(b"123456")
    scanner = FileSystemScanner(language_for_path=language_for_path, max_file_bytes=3)
    assert [i async for i in scanner.scan(str(tmp_path))] == [SkippedFile("a.py", "too_large")]
    with patch.object(scanner, "_read", side_effect=PermissionError("denied")):
        assert [i async for i in scanner.scan(str(tmp_path))] == [SkippedFile("a.py", "unreadable")]


async def test_disk_scanner_gitignore_in_isolated_repo(tmp_path: Path) -> None:
    (tmp_path / "kept.py").write_text("x=1\n")
    (tmp_path / "ignored.py").write_text("x=2\n")
    (tmp_path / ".gitignore").write_text("ignored.py\n")
    if shutil.which("git"):
        # Writes only the test's temporary .git, never the workspace repository.
        await asyncio.to_thread(
            subprocess.run, ["git", "init", str(tmp_path)], check=True, capture_output=True
        )
        expected = [".gitignore", "kept.py"]
    else:
        expected = [".gitignore", "ignored.py", "kept.py"]
    scanner = FileSystemScanner(language_for_path=language_for_path)
    assert [i.path async for i in scanner.scan(str(tmp_path))] == expected
