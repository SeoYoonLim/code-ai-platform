"""Engine 포트(Protocol) 정의. ★ Claude 소유 — Codex는 수정하지 않는다 (AGENTS.md 참조)."""

from engine.core.interfaces.activity import ActivityGauge
from engine.core.interfaces.adapter_registry import LoRAAdapterRegistry
from engine.core.interfaces.chunker import CodeChunker
from engine.core.interfaces.embedder import Embedder
from engine.core.interfaces.llm import LLMProvider
from engine.core.interfaces.source_scanner import SourceScanner
from engine.core.interfaces.vector_store import VectorStore

__all__ = [
    "ActivityGauge",
    "CodeChunker",
    "Embedder",
    "LLMProvider",
    "LoRAAdapterRegistry",
    "SourceScanner",
    "VectorStore",
]
