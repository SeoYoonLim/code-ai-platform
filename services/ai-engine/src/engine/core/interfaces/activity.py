from typing import Protocol, runtime_checkable


@runtime_checkable
class ActivityGauge(Protocol):
    """현재 진행 중인 생성(LLM) 요청 수를 읽는 읽기 전용 신호.

    용도 (ADR-0003 D-3): 임베딩 어댑터가 "LLM이 유휴이면 GPU, 생성 중이면 CPU"를 고를 때 쓴다.
    어댑터끼리는 서로 import할 수 없으므로(import-linter), `LLMProvider` 구현체가 이 Protocol을
    구조적으로 만족하게 하고 조립(DI)은 `engine/main.py`에서만 한다.

    구현 규칙:
    - `in_flight`는 시작됐지만 아직 끝나지 않은 `generate`/`stream` 호출 수다. 스트림은 마지막 청크를
      소비했거나, 소비자가 중단했거나, 오류가 났을 때 감소해야 한다 (누수되면 임베딩이 영원히 CPU에 갇힌다).
    - 읽기는 락 없이 O(1)이어야 하고 예외를 던지지 않는다.
    """

    @property
    def in_flight(self) -> int: ...
