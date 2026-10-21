"""벡터 검색 도메인 모델."""

from dataclasses import dataclass, field

from engine.core.models.code import CodeChunk

MetadataValue = str | int | float | bool


@dataclass(frozen=True, slots=True)
class MetadataFilter:
    """AND로 결합되는 동등 비교 필터. 값이 tuple이면 IN 조건."""

    equals: dict[str, MetadataValue | tuple[MetadataValue, ...]] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class RetrievedChunk:
    """score: 코사인 유사도 [0, 1], 높을수록 유사."""

    chunk: CodeChunk
    score: float
