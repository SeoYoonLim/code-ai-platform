"""Environment configuration for llama-server."""

from pathlib import Path
from typing import Literal

from pydantic import AnyHttpUrl, Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="ENGINE_", env_file=".env", extra="ignore")
    llm_provider: Literal["llamacpp", "fake"] = "llamacpp"
    embedder_provider: Literal["ollama", "fake"] = "ollama"
    vector_store: Literal["chroma", "memory"] = "chroma"
    registry_path: Path = Path("ml/registry/adapters.json")
    llamacpp_url: AnyHttpUrl = AnyHttpUrl("http://localhost:8080")
    base_model: str = "qwen2.5-coder-7b-instruct-q4_k_m"
    llamacpp_api_key: SecretStr | None = None
    embed_url: AnyHttpUrl = AnyHttpUrl("http://localhost:11434")
    embed_model: str = "nomic-embed-text"
    embed_dimension: int = Field(default=768, gt=0)
    embed_batch_size: int = Field(default=32, gt=0)
    embed_device_policy: Literal["dynamic", "gpu", "cpu"] = "gpu"
    embed_idle_grace_s: float = Field(default=3.0, ge=0)
    embed_min_dwell_s: float = Field(default=10.0, ge=0)
    embed_doc_prefix: str = "search_document: "
    embed_query_prefix: str = "search_query: "

    num_ctx: int = Field(default=16384, gt=0)
    rag_oversample: int = Field(default=2, ge=1)

    index_max_file_bytes: int = Field(default=524288, gt=0)

    chroma_url: AnyHttpUrl = AnyHttpUrl("http://localhost:8001")
