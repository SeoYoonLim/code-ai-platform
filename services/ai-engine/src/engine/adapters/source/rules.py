"""Globs: basename without /, otherwise full POSIX path; trailing / selects descendants.

fnmatch treats ** like * and both may match /. Exclusions take precedence.
"""

from collections.abc import Callable, Sequence
from fnmatch import fnmatchcase
from hashlib import sha256
from pathlib import PurePosixPath

from engine.core.models import Language, ScanItem, SkippedFile, SourceFile

EXCLUDED = {
    ".git",
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    "dist",
    "build",
    ".next",
    "target",
    ".tox",
    ".mypy_cache",
}


def default_excluded(path: str) -> bool:
    return bool(set(PurePosixPath(path).parts[:-1]) & EXCLUDED)


def matches(path: str, pattern: str) -> bool:
    if pattern.endswith("/"):
        directory = pattern.rstrip("/")
        return any(
            fnmatchcase("/".join(PurePosixPath(path).parts[:i]), directory)
            for i in range(1, len(PurePosixPath(path).parts))
        )
    return fnmatchcase(path if "/" in pattern else PurePosixPath(path).name, pattern)


def classify(
    path: str,
    data: bytes,
    language_for_path: Callable[[str], Language],
    include: Sequence[str],
    exclude: Sequence[str],
    maximum: int,
) -> ScanItem:
    if any(matches(path, p) for p in exclude) or (include and not any(matches(path, p) for p in include)):
        return SkippedFile(path, "excluded")
    language = language_for_path(path)
    if language == Language.UNKNOWN:
        return SkippedFile(path, "unsupported")
    if len(data) > maximum:
        return SkippedFile(path, "too_large")
    try:
        content = data.decode("utf-8")
    except UnicodeDecodeError:
        return SkippedFile(path, "binary")
    if "\0" in content:
        return SkippedFile(path, "binary")
    return SourceFile(path, language, content, sha256(data).hexdigest())
