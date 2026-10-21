"""Environment configuration for llama-server."""

from pydantic import AnyHttpUrl, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="ENGINE_", env_file=".env", extra="ignore")
    llamacpp_url: AnyHttpUrl = AnyHttpUrl("http://localhost:8080")
    base_model: str = "qwen2.5-coder-3b-instruct-q4_k_m"
    llamacpp_api_key: SecretStr | None = None
