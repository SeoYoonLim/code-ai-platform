"""LoRA 어댑터 레지스트리 도메인 모델. 원본: ml/registry/adapters.json"""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class AdapterStage(StrEnum):
    CANDIDATE = "candidate"
    STAGING = "staging"
    PRODUCTION = "production"
    ARCHIVED = "archived"


class AdapterTask(StrEnum):
    ANALYZE = "analyze"
    REFACTOR = "refactor"
    EXPLAIN = "explain"
    GENERAL = "general"


@dataclass(frozen=True, slots=True)
class AdapterInfo:
    """name: 서빙 엔진에 등록되는 이름 (예: "refactor-v3"). vLLM lora_name / Ollama 모델 태그와 일치."""

    name: str
    version: str
    base_model: str
    task: AdapterTask
    stage: AdapterStage
    dataset_hash: str
    eval_scores: dict[str, float]
    created_at: datetime
