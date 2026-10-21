"""AI Engine 에러 계층.

모든 어댑터/서비스는 외부 라이브러리 예외를 그대로 노출하지 않고 아래 타입으로 변환한다.
API 레이어는 `code`를 RFC 9457 Problem 응답의 `code` 필드로, HTTP status는
engine.v1.yaml `EngineErrorCode.x-error-catalog`에 따라 매핑한다.
`code` 값은 반드시 EngineErrorCode enum에 존재해야 한다 (tests/contract/test_error_codes.py가 검증).
"""


class EngineError(Exception):
    """AI Engine 최상위 예외."""

    code: str = "internal_error"
    retryable: bool = False

    def __init__(self, message: str, *, detail: dict[str, object] | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.detail = detail or {}


# --- LLM ---------------------------------------------------------------------
class ProviderUnavailable(EngineError):
    """서빙 엔진(Ollama/vLLM)에 연결할 수 없음."""

    code = "provider_unavailable"
    retryable = True


class AdapterNotFound(EngineError):
    """요청한 LoRA 어댑터가 레지스트리 또는 서빙 엔진에 없음."""

    code = "adapter_not_found"


class GenerationTimeout(EngineError):
    """생성이 제한 시간 내에 끝나지 않음."""

    code = "generation_timeout"
    retryable = True


class StructuredOutputError(EngineError):
    """모델 출력이 요구된 JSON 스키마를 만족하지 않음. 샘플링이 비결정적이므로 재시도 가능."""

    code = "structured_output_invalid"
    retryable = True


class ContextTooLarge(EngineError):
    """대상 코드가 컨텍스트 예산을 초과함 (data-flow §4.1). 대상을 줄여 재요청해야 한다."""

    code = "context_too_large"


# --- Jobs --------------------------------------------------------------------
class JobConflict(EngineError):
    """같은 project_id의 색인 잡이 이미 실행 중."""

    code = "job_conflict"


# --- Embedding / Vector store -----------------------------------------------
class EmbeddingError(EngineError):
    code = "embedding_failed"
    retryable = True


class VectorStoreError(EngineError):
    code = "vector_store_error"
    retryable = True


class CollectionNotFound(EngineError):
    code = "collection_not_found"


# --- Parsing -----------------------------------------------------------------
class UnsupportedLanguage(EngineError):
    """tree-sitter 문법이 없는 언어. 호출측은 윈도우 청킹으로 폴백해야 한다."""

    code = "unsupported_language"


class ParseError(EngineError):
    code = "parse_error"
