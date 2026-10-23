"""Supported domain languages and extension-specific grammar selection."""

from pathlib import PurePosixPath

from engine.core.models import Language

GRAMMARS = ("python", "typescript", "tsx", "javascript")
EXTENSIONS = {
    ".py": (Language.PYTHON, "python"),
    ".ts": (Language.TYPESCRIPT, "typescript"),
    ".tsx": (Language.TYPESCRIPT, "tsx"),
    ".js": (Language.JAVASCRIPT, "javascript"),
    ".jsx": (Language.JAVASCRIPT, "javascript"),
    ".mjs": (Language.JAVASCRIPT, "javascript"),
    ".cjs": (Language.JAVASCRIPT, "javascript"),
}


def language_for_path(path: str) -> Language:
    return EXTENSIONS.get(PurePosixPath(path).suffix.lower(), (Language.UNKNOWN, ""))[0]


def grammar_for_path(path: str, language: Language) -> str:
    default = language.value
    mapped = EXTENSIONS.get(PurePosixPath(path).suffix.lower())
    return mapped[1] if mapped and mapped[0] == language else default
