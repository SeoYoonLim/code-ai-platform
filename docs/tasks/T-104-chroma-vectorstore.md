# T-104: `ChromaVectorStore` (ChromaDB HTTP) — VectorStore 실제 어댑터

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-101 `9056840`, T-102 `5f3e62c`, T-103 `5529bcd` 머지 완료)
- **우선순위:** P0 — T-107(`IndexingService`)과 T-108(`RagService`)이 이 위에서 동작한다
- **관련 문서:** [ADR-0003](../adr/0003-base-model-and-lora-serving.md), [data-flow §3](../architecture/02-data-flow.md), 인터페이스 [vector_store.py](../../services/ai-engine/src/engine/core/interfaces/vector_store.py), 모델 [code.py](../../services/ai-engine/src/engine/core/models/code.py) · [retrieval.py](../../services/ai-engine/src/engine/core/models/retrieval.py), 에러 [errors.py](../../services/ai-engine/src/engine/core/errors.py)

## 목표
`VectorStore` Protocol을 ChromaDB(HTTP 서버)로 구현한다. 컬렉션 = 프로젝트 1개. **Fake(`InMemoryVectorStore`)와 같은 규칙을 지키는 것**이 수락 기준의 첫 줄이다 (T-101 `VectorStoreConformance` 스위트).

## 환경 사실 (2026-10-21 실측 — 다시 조사하지 않는다)

| 항목 | 값 |
|---|---|
| 서버 이미지 | `chromadb/chroma@sha256:1e0b73a187a28757c572acba508c46f48c9e8b0acaf5c20e6d95cdedce1acdf6` (서버 CLI 1.4.4, `/api/v2/version` → `"1.0.0"`). compose는 지금 `chromadb/chroma:latest`(고정 안 됨) — **이 digest로 고정한다** |
| 클라이언트 | `chromadb-client 1.5.9` (HTTP 전용, 이미 의존성). 서버와 **문제없이 통신함** 확인 (패키지 버전과 서버 CLI 버전은 번호 체계가 다르다) |
| 클라이언트 API | `chromadb.AsyncHttpClient(host=…, port=…)` → `await client.get_or_create_collection(...)` |
| compose | `chroma` 서비스: 포트 `8001:8000`, 볼륨 `chroma:/data`, `IS_PERSISTENT=TRUE` |
| 영속성 | 컨테이너 `docker restart` 후 **행 201개와 컬렉션 메타데이터(`dimension`)가 모두 보존됨**, 쿼리 정상 |

## ⚠️ 실측으로 확정한 Chroma 동작 — 어댑터가 반드시 지켜야 한다

### 컬렉션
1. **이름 규칙:** `[a-zA-Z0-9._-]`, 3~512자, **시작과 끝은 영숫자.** 길이 제한은 문제 없다 (`proj_` + 64자 = 69자 통과). **`project_id`가 `-` 또는 `_` 등 비영숫자로 끝나면 `proj_{id}`가 거부된다** (`proj_a-` 거부 확인). API 계약은 `^[a-zA-Z0-9_-]{1,64}$`라 이런 ID가 들어올 수 있다.
   → **어댑터는 컬렉션 이름을 그대로 쓰지 말고 `collection` 인자를 안전한 이름으로 변환한다.** 규칙: 이미 유효하면 그대로, 아니면 끝에 `x`를 붙인다 (`proj_a-` → `proj_a-x`). 변환은 **결정적이고 단사(injective)** 여야 한다 (서로 다른 입력이 같은 이름이 되면 안 된다 — `proj_a-`와 `proj_a-x`가 충돌하지 않게 이미 `x`로 끝나는 이름에도 `x`를 붙이는 식으로 설계하고, 근거를 코드 주석에 적는다). 단위 테스트로 충돌이 없음을 보인다.
2. **없는 컬렉션:** `get_collection`/`delete_collection` 모두 `NotFoundError` → `CollectionNotFound`.
3. **차원은 첫 add에서 정해진다.** Chroma 컬렉션에는 "선언된 차원"이 없다. `ensure_collection(dimension=N)`은 **컬렉션 메타데이터 `{"dimension": N}`에 기록**하고(재시작 후에도 보존됨, 실측), 이미 있으면 기록된 값과 비교해 다르면 `VectorStoreError`. 메타데이터에 `dimension`이 없는 기존 컬렉션이면 `VectorStoreError`(알 수 없는 상태).
4. 차원이 다른 벡터를 upsert/query하면 서버가 `InvalidArgumentError`(`expecting embedding with dimension of 3, got 2`)를 낸다 → `VectorStoreError`로 변환.
5. **거리 공간은 컬렉션 생성 시 지정:** `configuration={"hnsw": {"space": "cosine"}}`. 생성 후 바꿀 수 없다.

### 점수
6. 코사인에서 `distance = 1 - cos_sim`. 같은 방향 `0.0`, 45° `0.2929`, 반대 `2.0` (실측). → **`score = max(0.0, 1.0 - distance)`** (반대 방향은 음수가 되므로 0으로 클램프). 쿼리 크기는 무관하다 (`[2,0]`과 `[1,0]` 동일, 실측).
7. **영벡터 쿼리는 NaN이 아니라 모든 거리가 `1.0`** (실측) → 점수 0. 별도 처리가 필요 없다 (스위트 `test_zero_vector_scores_zero`가 자연히 통과).

### 메타데이터
8. **Chroma 메타데이터는 평평한 `str|int|float|bool`만 저장한다.** `CodeChunk`의 필드를 이렇게 매핑한다 — `text` → Chroma `documents`, `chunk_id` → `ids`, 나머지 → 메타데이터:
   `project_id, path, language, kind, symbol, start_line, end_line, content_hash, commit_sha`. 열거형은 `.value` 문자열로 저장하고 복원 시 다시 열거형으로 만든다.
9. **`None`은 오류 없이 조용히 사라진다** (`commit_sha: None`으로 upsert하면 돌려받는 메타데이터에서 키가 없다, 실측). → 복원 시 `meta.get("commit_sha")`를 쓴다 (`meta["commit_sha"]`는 `KeyError`). **`None`이면 키를 아예 넣지 않는다**(명시적으로 처리). `None`으로 필터링하면 `ValueError`이므로 `where`에서 `None`을 허용하지 않는다.
10. **`CodeChunk.metadata`(자유 형식 사전)는 예약 필드와 키가 충돌한다.** 사용자 사전에 `path`나 `kind`가 있으면 예약 필드를 덮어쓰거나 필터를 오염시킨다. → 사용자 메타데이터는 **접두사 `m_`를 붙여** 저장하고(`m_note`), 복원 시 접두사를 떼서 `metadata`로 되돌린다. 단위 테스트: 키가 `path`/`kind`/`symbol`인 사용자 메타데이터가 예약 필드를 오염시키지 않고 왕복한다.

### 필터
11. **`where` 키가 둘 이상이면 `$and`로 감싸야 한다.** 평평한 `{"path": "x", "k": 1}`은 `ValueError: exactly one operator`로 실패한다 (실측). 키 하나면 그대로, 둘 이상이면 `{"$and": [{k: v}, …]}`.
12. 튜플(IN) 값은 `{"$in": [...]}`. **빈 튜플은 서버가 거부한다** (`non-empty list`) → 어댑터가 빈 튜플을 만나면 **결과가 없음**으로 처리한다 (`where`가 아무것도 만족시키지 못함 — 서버에 보내지 않고 빈 리스트를 반환, 단 컬렉션 존재 확인은 먼저 한다).
13. 허용 필터 키는 `path, language, kind, symbol, commit_sha` (Fake와 동일). 그 외 키는 `ValueError`. `MetadataFilter`의 값에 `None`이 들어오면 `ValueError`.

### 삭제·조회
14. **`collection.delete(where=…)`는 `{'deleted': N}`을 돌려준다** (실측). → `delete_by_paths`의 반환값은 이 `N`을 쓴다 (사전 `count`/`get`을 따로 하지 않는다). 경로 목록은 `{"path": {"$in": paths}}`. **같은 경로가 중복돼도 개수는 실제 삭제 수**다.
15. `get()`을 제한 없이 부르면 700행을 한 번에 돌려준다(실측). `get_file_hashes`는 `include=["metadatas"]`로 가져오되 **`limit/offset` 페이지(1000행 단위)** 로 끝까지 읽는다 — 큰 컬렉션에서 조용히 잘리지 않게 한다. 같은 `path`의 청크는 같은 `content_hash`를 갖는다는 가정(첫 값 사용). 불일치하면 `VectorStoreError`가 아니라 **마지막 값**을 쓰되 로그에 경고(`structlog`)를 남긴다.
16. `n_results`가 컬렉션 크기보다 크면 **있는 만큼만** 돌려준다(실측, 보정 불필요). **`n_results ≤ 0`은 `TypeError`** → 어댑터가 `top_k <= 0`이면 서버를 부르지 않고 `[]`을 반환한다 (컬렉션 존재 확인은 한다).

### ⚠️ 빈 입력과 "컬렉션 없음" — 스위트를 깨뜨리는 가장 자연스러운 최적화
17. **빈 입력은 Chroma가 `ValueError`로 거부한다** (`upsert([])`, `delete(ids=[])`, `delete(where $in [])` 모두, 실측). 그런데 스위트는 **빈 입력이어도 컬렉션이 없으면 `CollectionNotFound`** 를 요구한다 (`upsert("missing", [], [])`, `delete_by_paths("missing", [])`). 따라서:
    - **모든 연산은 "컬렉션 조회 → (없으면 `CollectionNotFound`) → 입력이 비었으면 서버 호출 없이 반환 → 아니면 호출" 순서**로 구현한다.
    - `if not paths: return 0`을 맨 앞에 두는 구현은 스위트의 `test_missing_collection_raises[delete]`를 깬다. 순서를 바꾸지 않는다.
18. **검사 순서는 Fake와 같아야 한다.** `InMemoryVectorStore.upsert`는 **① 길이 불일치(`ValueError`) → ② 컬렉션 조회(`CollectionNotFound`) → ③ 차원 검증 → ④ 쓰기** 순서다 (코드로 확인함). 그래서 "없는 컬렉션 + 길이 불일치" 입력은 `CollectionNotFound`가 아니라 `ValueError`다. 어댑터도 이 순서를 그대로 따른다 — 순서가 다르면 같은 입력에 예외 종류가 달라져 스위트의 `test_length_mismatch_raises`(존재하는 컬렉션)는 통과해도 서비스 계층이 기대하는 동작이 어긋난다. 이 순서를 보호하는 단위 테스트를 둔다.

### 오류 변환
19. 모든 Chroma/`httpx` 예외는 어댑터 경계에서 변환한다. 연결 실패·타임아웃·5xx → `VectorStoreError`(재시도 가능), `NotFoundError` → `CollectionNotFound`, `InvalidArgumentError` → `VectorStoreError`(차원 불일치 포함). 원본 예외는 `__cause__`로 보존, 메시지에 **서버 본문 최대 300자**만.

## T-101 스위트 상속 규약

```python
from tests.conformance.vector_store_suite import VectorStoreConformance


class TestChromaVectorStore(VectorStoreConformance):
    @pytest.fixture
    async def store(self, ...) -> VectorStore:   # fixture 이름은 반드시 store
        ...
```
스위트는 `chunk_factory` fixture(`tests/conftest.py`)와 `store`를 쓴다. 스위트의 `populated`가 `ensure_collection("c", dimension=2)` 후 청크 3개를 넣는다 — 컬렉션 이름 `"c"`는 **3자 미만이라 Chroma가 거부한다** (최소 3자). → 어댑터의 이름 변환(위 1번)이 이 경우도 처리해야 한다: 3자 미만이면 **접두사 `c_`를 붙여** 최소 길이를 만족시킨다 (예: `"c"` → `"c_c"`). 변환은 단사여야 한다. 이 규칙이 없으면 스위트 전체가 `InvalidArgumentError`로 죽는다 (실측: `ab`는 3자 미만으로 거부됨).

**이름 변환은 모든 연산에서 일관되게 적용한다 (실측으로 확인한 함정).** 유효하지 않은 이름은 *만들 때*(`get_or_create_collection`)는 `InvalidArgumentError`로 거부되지만 *조회·삭제할 때*(`get_collection`, `delete_collection`)는 같은 이름에 `NotFoundError`를 낸다 (`'c'`, `'ab'` 확인). 그래서 변환을 `ensure_collection`에만 적용하면
`ensure_collection("c")`는 `c_c`를 만들고 `query("c")`는 `c`를 찾다가 **엉뚱하게 `CollectionNotFound`** 를 낸다 — 오류 메시지만 봐서는 원인을 찾기 어려운 버그다. 변환은 **단 하나의 함수**로 만들고 `ensure_collection / upsert / query / delete_by_paths / get_file_hashes / drop_collection` 전부가 그 함수를 거치게 한다. 단위 테스트: "변환이 필요한 이름으로 ensure → 각 연산이 같은 컬렉션을 본다"를 연산별로 검증.

### 단위 테스트에서 Chroma를 어떻게 다룰까 (설계 결정 — 이대로 한다)
- 이 저장소는 `chromadb-client`(HTTP 전용)를 쓴다. **전체 `chromadb`를 같은 환경에 설치하면 안 된다** — 두 배포판이 같은 `chromadb` 패키지 경로를 공유해서, 함께 설치하면 HTTP 전용 모드가 이겨 인프로세스 엔진이 `http-only client mode`로 죽는다 (실측). 의존성을 추가하지 않는다.
- **단위 테스트는 클라이언트 경계를 가짜로 대체한다.** `ChromaVectorStore`는 생성자에서 `client: AsyncClientAPI`를 주입받고, 테스트는 `get_collection/get_or_create_collection/delete_collection`과 컬렉션의 `upsert/query/get/delete/count/metadata`를 흉내 내는 **`FakeChromaClient`** 를 `tests/unit/adapters/vectorstore/fake_chroma_client.py`에 둔다 (테스트 헬퍼, 300줄 이하).
- ⚠️ 가짜는 위 "실측 동작"(거리 = 1 − 코사인, `None` 메타데이터 손실, `$and` 필요, 빈 입력 `ValueError`, `delete`의 `{'deleted': N}`, 이름 규칙 검증, 차원 검사)을 **정확히** 흉내 내야 한다. 이게 틀리면 단위 테스트가 거짓 안심을 준다.
- **가짜가 진짜와 같은지는 Claude가 같은 스위트를 진짜 서버에 돌려 보증한다** (아래 통합 테스트). 가짜의 동작을 바꿀 땐 이 문서의 실측 항목을 근거로 댄다.

## 대상 파일
| 파일 | 내용 |
|---|---|
| `services/ai-engine/src/engine/adapters/vectorstore/chroma.py` | `ChromaVectorStore` (300줄 초과 시 `chroma_codec.py`로 분리: 이름 변환, `CodeChunk` ↔ 메타데이터, 필터 변환) |
| `services/ai-engine/src/engine/settings.py` | `ENGINE_CHROMA_URL`(기본 `http://localhost:8001`) 추가. 기존 필드 유지 |
| `services/ai-engine/tests/unit/adapters/vectorstore/fake_chroma_client.py` | 위 `FakeChromaClient` (테스트 헬퍼, `test_*.py`가 아님) |
| `services/ai-engine/tests/unit/adapters/vectorstore/test_chroma_store.py` | `VectorStoreConformance` 상속 + 어댑터 고유 규칙(위 1·3·8·9·10·11·12·14·15·16·17 항목) |
| `services/ai-engine/tests/integration/test_chroma_live.py` | 실서버 대상 (`@pytest.mark.integration`, `ENGINE_IT_CHROMA_URL` 없으면 skip) — **작성만** |
| `docker-compose.yml` | **`chroma` 서비스 블록만**: `image`를 위 digest로 고정 (`chromadb/chroma@sha256:1e0b73a1…`). 나머지 서비스는 건드리지 않는다 |
| `.env.example` | `ENGINE_CHROMA_URL` 확인 (이미 있으면 변경 없음) |

테스트 파일 이름은 저장소 전체에서 고유(`test_chroma_store.py`, `test_chroma_live.py`), 새 디렉터리에는 `__init__.py` (필요 없음 — 모두 기존 디렉터리).

## 구현 명세

- 생성자: `ChromaVectorStore(client: AsyncClientAPI)`. 클라이언트 생성은 `async def connect(settings) -> ChromaVectorStore` 팩토리(`chromadb.AsyncHttpClient`)에 둔다. `aclose()`는 제공하지 않아도 된다(클라이언트가 소유하지 않음).
- 컬렉션 핸들은 매 호출마다 조회하되(상태 없음), 이름 변환 결과로 `client.get_collection(name)`을 쓴다. `ensure_collection`만 `get_or_create_collection(configuration={"hnsw": {"space": "cosine"}}, metadata={"dimension": N})`.
- `query`는 `include=["documents","metadatas","distances"]`. 결과 순서는 서버가 거리 오름차순으로 주므로 점수 내림차순이다 — **그래도 정렬을 가정하지 말고** 최종적으로 점수 내림차순을 보장한다(동점은 입력 순서 유지).
- `upsert`는 `ids/embeddings/documents/metadatas`를 한 번에 보낸다. 서버 요청 크기 한계가 있을 수 있으므로 **배치(기본 500)** 로 나눈다 (배치 크기는 생성자 인자, 단위 테스트로 1250개 → 500/500/250 검증).
- 임베딩은 `list[float]`로 넘긴다(numpy 불필요).

## 수락 기준
- [ ] **`VectorStoreConformance`(T-101) 상속 테스트 전부 통과** — `FakeChromaClient` 위의 `ChromaVectorStore`로 `store` fixture 제공 (27개 규칙 전부, `xfail`/`skip` 금지)
- [ ] 위 "실측 동작" 19개 항목 중 단위 테스트가 가능한 것마다 **그 규칙을 검증하는 테스트가 있다** (표로 매핑해서 결과에 적는다). 특히:
  - 이름 변환: 유효한 이름은 그대로, `-` 끝·3자 미만은 변환, **변환이 단사임**(무작위 100개 이상 입력에서 충돌 0)
  - `CodeChunk` 왕복: `commit_sha=None`·값 있음 모두 동일하게 복원, 모든 `Language`/`ChunkKind` 열거형, 예약 키와 겹치는 사용자 `metadata`
  - `where`: 키 1개/2개 이상(`$and`)/튜플(`$in`)/빈 튜플(서버 미호출)/`None` 값(`ValueError`)
  - 빈 입력 순서: 없는 컬렉션에 `upsert([],[])`·`delete_by_paths([])`가 `CollectionNotFound`, 있는 컬렉션에서는 서버를 **호출하지 않고** 정상 반환
  - `top_k <= 0`이면 서버 미호출 `[]`
  - `get_file_hashes` 페이지네이션 (2500행 → 1000/1000/500으로 읽음), `upsert` 배치 분할
  - 오류 변환 표의 모든 행
- [ ] `make check` 통과 (mypy strict, import-linter 포함). 파일당 300줄 이하. `chromadb`를 **`engine.core`가 import하지 않는다** (import-linter가 강제)
- [ ] **작성한 compose 변경과 통합 테스트는 실행하지 못하면 "미실행 (Claude가 실행)"으로 정직하게 적는다.** 실행한 것만 실행했다고 쓴다.

## 통합 테스트 (`test_chroma_live.py`) — 작성만, 실행은 Claude
Claude가 실제 Chroma 서버(위 digest, 영속 볼륨)에서 실행한다. 다음을 포함한다.
1. **같은 `VectorStoreConformance` 스위트를 진짜 서버에 상속해서 돌린다** (`store` fixture만 실서버로 교체). 가짜가 진짜와 어긋나면 여기서 실패한다 — 이 카드의 핵심 보증이다. 테스트마다 고유한 컬렉션 이름을 쓰고 끝나면 지운다(서로 간섭 금지).
2. **영속성:** 컬렉션에 청크를 넣고 → (Claude가) 서버를 재시작 → 같은 컬렉션을 `ensure_collection`으로 다시 열어도 데이터와 `dimension` 메타데이터가 보존되고 `query`가 같은 결과를 낸다. 재시작은 테스트가 할 수 없으므로 두 단계 시나리오(`--phase write` / `--phase read`)로 나누거나, 테스트 안에서 `docker restart`를 `subprocess`로 호출한다 (Claude가 결정, 어느 쪽이든 skip 가능해야 함).
3. **규모:** 1500청크(768차원)를 upsert → `get_file_hashes`가 모든 파일을 돌려주고 → `delete_by_paths`가 정확한 개수를 돌려주고 → `query` 지연이 합리적(p95 < 1s)인지 측정만 한다.
4. 컬렉션 이름 변환: `proj_a-` 같은 `project_id`와 매우 긴 이름이 실서버에서 거부되지 않는다.

## 금지 사항
- `core/**`, `contracts/**` 수정 금지. 인터페이스가 부족하면 `BLOCKED: interface`
- **전체 `chromadb` 패키지를 의존성에 추가하지 않는다** (`chromadb-client`와 충돌, 실측). 새 의존성이 필요하면 사유를 적고 멈춘다
- Chroma에 빈 입력을 보내지 않는다 (항상 서버가 `ValueError`로 거부)
- `adapters/llm`, `adapters/embeddings`, `adapters/parsing` import 금지 (import-linter)
- `project_id`나 컬렉션 이름에서 `proj_` 접두사를 어댑터가 붙이지 않는다 — 호출자(서비스)가 `collection` 문자열을 정한다. 어댑터는 **안전한 이름으로 변환**만 한다
- 서버 응답 본문·예외 메시지 전체를 로그나 `detail`에 싣지 않는다 (최대 300자)

## 커밋 규칙 (중요)
Codex 샌드박스는 `.git`에 쓸 수 없어서 `git add`/`git commit`이 `index.lock` 권한 오류로 실패한다 (T-001·S-01·T-101·T-102·T-103에서 확인). **커밋하지 않는다.** 변경은 작업 트리에 두고 "결과"에 변경 파일과 검증 출력을 남기면 Claude가 리뷰 후 커밋·push한다. **Docker·실서버가 필요한 검증은 Codex 범위가 아니다.**

## 결과
<Codex 기록: 변경 파일, 테스트 수, 실측 항목↔테스트 매핑 표, `make check` 결과, 미실행 목록>
