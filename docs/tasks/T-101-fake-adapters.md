# T-101: Fake 어댑터 3종 + 재사용 가능한 Protocol 적합성(conformance) 테스트

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready
- **우선순위:** P0 — M1의 모든 서비스 테스트가 이 Fake 위에서 돈다. 가장 먼저 한다 (GPU·네트워크 불필요)
- **관련 문서:** [AGENTS.md](../../AGENTS.md), [CLAUDE.md](../../CLAUDE.md), 인터페이스 [llm.py](../../services/ai-engine/src/engine/core/interfaces/llm.py) · [embedder.py](../../services/ai-engine/src/engine/core/interfaces/embedder.py) · [vector_store.py](../../services/ai-engine/src/engine/core/interfaces/vector_store.py) · [activity.py](../../services/ai-engine/src/engine/core/interfaces/activity.py)

## 목표
1. `LLMProvider`, `Embedder`, `VectorStore`의 **결정적(deterministic) Fake 구현**을 만든다. 서비스 단위 테스트(T-107, T-108 등)가 GPU 없이 돌아가게 하는 기반이다.
2. 각 Protocol의 docstring "구현 규칙"을 **테스트로 옮긴 적합성 스위트**를 만든다. 지금은 Fake가 통과시키지만, 이후 실제 어댑터(T-102 `LlamaServerProvider`, T-103 임베더, T-104 Chroma)가 **같은 스위트를 그대로 재사용**해서 "Fake와 동일하게 동작"을 보장한다.

## 대상 파일
| 파일 | 내용 |
|---|---|
| `services/ai-engine/src/engine/adapters/llm/fake.py` | `FakeLLMProvider` |
| `services/ai-engine/src/engine/adapters/embeddings/fake.py` | `FakeEmbedder` |
| `services/ai-engine/src/engine/adapters/vectorstore/in_memory.py` | `InMemoryVectorStore` |
| `services/ai-engine/tests/conformance/__init__.py` | (비어 있음) |
| `services/ai-engine/tests/conformance/llm_suite.py` | `LLMProviderConformance` (테스트 믹스인 클래스) |
| `services/ai-engine/tests/conformance/embedder_suite.py` | `EmbedderConformance` |
| `services/ai-engine/tests/conformance/vector_store_suite.py` | `VectorStoreConformance` |
| `services/ai-engine/tests/unit/adapters/llm/test_fake.py` 외 2개 | 각 Fake가 스위트를 상속해 통과 |
| `services/ai-engine/tests/conftest.py` | 공용 fixture (`fake_llm`, `fake_embedder`, `in_memory_store`, 샘플 `CodeChunk` 팩토리) |

> 스위트 파일 이름은 `*_suite.py`다 (`test_*.py`가 아니므로 pytest가 단독 수집하지 않는다). 사용 방법은 아래 "스위트 사용 규약" 참조.

## 구현 명세

### `FakeLLMProvider`
- 생성자: `FakeLLMProvider(*, replies: Sequence[str] | Callable[[GenerationRequest], str] = ("ok",), adapters: Collection[str] = (), model: str = "fake-llm", latency_s: float = 0.0, tokens_per_chunk: int = 1)`
- `generate`: `replies`를 **순서대로 순환**하거나 콜러블을 호출해 본문 생성. `req.adapter`가 `None`이 아니고 `adapters`에 없으면 `AdapterNotFound`. 결과의 `adapter` 필드는 요청값 그대로.
- `stream`: 본문을 공백 기준 토큰으로 쪼개 `tokens_per_chunk`개씩 `TokenChunk`로 내보낸다. `index`는 0부터 1씩 증가. **마지막 청크만** `finish_reason`과 `usage`를 가진다.
- `req.json_schema`가 있으면 `replies`를 그대로 쓰되, 실제 스키마 검증은 하지 않는다 (검증은 서비스 책임).
- `health()`: `ProviderHealth(ok=True, provider="fake", base_model=model, loaded_adapters=tuple(sorted(adapters)))`
- **오류 주입:** `fail_next(exc: EngineError)` 메서드 — 다음 호출 1회에서 해당 예외를 던진다 (`ProviderUnavailable`, `GenerationTimeout` 시뮬레이션용).
- `ActivityGauge` 만족: `in_flight` 프로퍼티. `generate` 시작 시 +1, 종료(정상·예외)에서 −1. `stream`은 시작 시 +1, **소비 완료·소비자 중단(`aclose`)·예외 중 어느 경우에도** −1 (`try/finally`). 누수 금지.
- `latency_s > 0`이면 `asyncio.sleep`으로 지연을 흉내 낸다 (타임아웃·동시성 테스트용).

### `FakeEmbedder`
- 생성자: `FakeEmbedder(*, dimension: int = 16, model_name: str = "fake-embed")`
- 벡터: 입력 텍스트의 `sha256`을 시드로 `dimension`개 float를 만들고 **L2 정규화**한다. 같은 텍스트 → 항상 같은 벡터, 다른 텍스트 → (사실상) 다른 벡터.
- `embed_documents`와 `embed_query`는 **같은 텍스트에 대해 같은 벡터**를 반환한다 (Fake는 prefix를 쓰지 않는다).
- 빈 입력 리스트 → 빈 리스트. 출력 순서 = 입력 순서, 길이 동일.
- 호출 기록: `calls: list[list[str]]` 공개 속성 (배치 분할 검증용).

### `InMemoryVectorStore`
- 컬렉션 `dict[str, dict[chunk_id, (CodeChunk, vector)]]`. 코사인 유사도는 정규화된 벡터의 내적으로 계산하되, **정규화되지 않은 입력도 안전하게 처리**한다 (norm 0이면 score 0).
- `VectorStore` Protocol docstring의 **모든 규칙**을 따른다:
  - `upsert`는 `chunk_id` 기준 멱등. `len(chunks) != len(embeddings)` → `ValueError`.
  - `ensure_collection(dimension=...)`: 없으면 생성, 있는데 dimension이 다르면 `VectorStoreError`. upsert/query의 벡터 길이가 컬렉션 dimension과 다르면 `VectorStoreError`.
  - 없는 컬렉션의 `query`/`delete_by_paths`/`get_file_hashes`/`drop_collection` → `CollectionNotFound`.
  - `query`: score 내림차순, 최대 `top_k`. `where`는 `MetadataFilter.equals`를 AND로 평가, 값이 `tuple`이면 IN. 필터 가능 키는 `path`, `language`, `kind`, `symbol`, `commit_sha` (그 외 키는 `ValueError`). score는 [0, 1]로 클램프한다 (`(cos + 1) / 2`가 아니라 **음수는 0으로 자르는 방식**: `max(0.0, cos)`).
  - `delete_by_paths`는 삭제 개수를 반환. `get_file_hashes`는 `{path: content_hash}` — 같은 파일의 청크들은 같은 `content_hash`를 가진다는 가정.
- 동시성: 단일 이벤트 루프 가정, 락 불필요. 단 `query` 도중 `upsert`로 딕셔너리가 바뀌어도 터지지 않게 스냅샷 위에서 순회한다.

### 스위트 사용 규약 (중요)
각 스위트는 **`pytest` 수집 대상이 아닌 믹스인**이다. 구현 테스트가 이렇게 상속한다:

```python
# tests/unit/adapters/vectorstore/test_in_memory.py
class TestInMemoryVectorStore(VectorStoreConformance):
    @pytest.fixture
    def store(self) -> VectorStore:  # 스위트가 요구하는 fixture 이름
        return InMemoryVectorStore()
```
- 스위트는 필요한 fixture 이름을 모듈 docstring에 명시한다 (`llm_provider`, `embedder`, `store`). 실제 어댑터(T-102~T-104)의 테스트도 **같은 fixture 이름**만 제공하면 스위트 전체가 그대로 돈다.
- 스위트의 각 테스트 이름은 Protocol docstring 규칙과 1:1로 대응하게 짓는다 (예: `test_upsert_is_idempotent`, `test_query_orders_by_score_desc`, `test_dimension_mismatch_raises`).
- 실제 어댑터가 정당한 이유로 어떤 규칙을 못 지키면 스위트를 고치지 말고 **카드에 `BLOCKED: interface`로 보고**한다.

## 수락 기준
- [ ] Fake 3종이 해당 Protocol을 만족한다 (`isinstance(x, LLMProvider)` 등 `runtime_checkable` 확인 테스트 포함). `FakeLLMProvider`는 `ActivityGauge`도 만족.
- [ ] 적합성 스위트 3개가 존재하고, Fake 3종이 전부 통과한다. 스위트 테스트 수: LLM ≥ 10, Embedder ≥ 7, VectorStore ≥ 14.
- [ ] 스위트가 포함하는 규칙 (최소):
  - LLM: adapter 없음→base / 모르는 adapter→`AdapterNotFound` / stream 마지막 청크만 finish_reason·usage / index 연속 증가 / 소비자 중단 후 `in_flight` 복귀 / 예외 후 `in_flight` 복귀 / `health()`는 예외를 던지지 않음
  - Embedder: L2 정규화(‖v‖≈1, 허용오차 1e-6) / 순서·길이 보존 / 빈 입력 / 결정성 / `dimension`·`model_name` 일치
  - VectorStore: 멱등 upsert / 길이 불일치 `ValueError` / 차원 불일치 `VectorStoreError` / 없는 컬렉션 `CollectionNotFound` / top_k·정렬 / `where` AND·IN / `delete_by_paths` 개수 / `get_file_hashes` / `drop_collection` 후 재조회 `CollectionNotFound`
- [ ] 생성한 Fake를 쓰는 **통합 smoke 테스트 1개**: `FakeEmbedder`로 청크 5개를 임베딩해 `InMemoryVectorStore`에 넣고 질의 → 가장 유사한 청크가 1위.
- [ ] `make check` 통과 (mypy strict 포함). 파일당 300줄 이하 — 스위트가 길어지면 규칙별로 파일을 나눈다.
- [ ] **작성한 테스트를 실제로 실행**해서 결과(통과 수)를 아래 "결과"에 적는다.

## 금지 사항
- `core/interfaces/**`, `core/models/**`, `core/errors.py`, `contracts/**` 수정 금지
- Fake에서 `random`·시간·네트워크 의존 금지 (완전 결정적이어야 한다). 지연은 `latency_s`로만.
- `chromadb`·`httpx`·`langchain` import 금지 (`engine.adapters.*`는 서로 import 금지, core 외 외부 의존 최소화)
- Fake가 프로덕션 코드 경로에서 기본값으로 쓰이지 않게 한다 (`main.py` 조립은 이 카드 범위 밖)

## 참고
- 도메인 모델: `engine.core.models` (`CodeChunk`, `GenerationRequest`, `GenerationResult`, `TokenChunk`, `TokenUsage`, `ProviderHealth`, `MetadataFilter`, `RetrievedChunk`)
- `pytest-asyncio`는 `asyncio_mode = "auto"` — `async def test_...`를 그대로 쓴다.
- 이 카드 이후 T-102/T-103/T-104는 "스위트를 상속해 통과시키기"가 수락 기준의 첫 줄이 된다.

## 결과
<Codex 기록: 변경 파일, 스위트별 테스트 수, `make check` 결과>
