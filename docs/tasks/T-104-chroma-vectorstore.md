# T-104: `ChromaVectorStore` (ChromaDB HTTP) — VectorStore 실제 어댑터

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** **done** (2026-10-21, 리뷰·실서버 검증 완료)
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
- [ ] **`VectorStoreConformance`(T-101) 상속 테스트 전부 통과** — `FakeChromaClient` 위의 `ChromaVectorStore`로 `store` fixture 제공 (23개 규칙 전부, `xfail`/`skip` 금지)
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
구현 완료. 변경은 작업 트리에만 남겼다. git add/commit/push, Docker, 실제 서버 접속, 의존성 설치 없음.

| 변경 파일 (services/ai-engine/ 기준) | 줄 수 | 테스트 케이스 |
|---|---:|---:|
| src/engine/adapters/vectorstore/chroma.py | 159 | — |
| src/engine/adapters/vectorstore/chroma_codec.py (신규) | 101 | — |
| src/engine/settings.py | 24 | — |
| tests/unit/adapters/vectorstore/fake_chroma_client.py (신규) | 155 | helper |
| tests/unit/adapters/vectorstore/test_chroma_store.py (신규) | 252 | 193 통과 (상속 suite 23 포함) |
| tests/unit/adapters/vectorstore/test_chroma_boundary.py (신규) | 76 | 2 통과 |
| tests/unit/test_engine_settings.py | 104 | 13 통과 (신규 1) |
| tests/integration/test_chroma_live.py (신규) | 111 | 28 수집, 미실행 |
| /docker-compose.yml | 103 | chroma image 한 줄만 변경 |
| /docs/tasks/T-104-chroma-vectorstore.md | 228 | 본 기록 |

공유 이름 변환, cosine 설정/점수, dimension 메타데이터 검증, 500개 배치,
1000개 페이지, m_ 사용자 메타데이터 격리, None 생략, 오류 cause 보존/300자 제한을 구현했다.
짧은 이름은 c_로 확장하고 기존 c_/e_ 접두사는 e_로 이스케이프한다.
끝의 비영숫자 또는 x에는 x를 추가해 충돌을 막는다. 일반 유효 이름은 유지하며
예약 접두사/끝 x의 변경은 단사성 확보에 필요하다. 6개 연산 모두 같은 변환을 사용한다.
상속 suite 호출을 포함한 저장소 await에는 asyncio.wait_for로 5초 제한을 적용했다.

### 실행한 검증 (실제 출력 요약)

uv 기본 캐시 접근이 거부되어 이후 명령은 UV_CACHE_DIR=C:/project/project1/.uv-cache로 실행했다.
새 스크립트/Dockerfile/CI는 없다. 새 Python 구현/Fake/단위 테스트는 실제 실행했다.

| 명령 | 종료 코드 | 실제 출력 요약 |
|---|---:|---|
| uv run ruff check . | 0 | All checks passed! |
| uv run ruff format --check . | 0 | 212 files already formatted |
| uv run lint-imports | 0 | Analyzed 94 files, 113 dependencies. Contracts: 5 kept, 0 broken. |
| uv run mypy packages/py-common/src services/ai-engine/src services/backend/src | 0 | Success: no issues found in 69 source files |
| uv run python scripts/check_file_lines.py --max 300 | 0 | 출력 없음 |
| uv run pytest -q | 0 | 430 passed, 37 deselected, 2 warnings in 29.19s |
| uv run openapi-spec-validator contracts/openapi/engine.v1.yaml | 0 | contracts/openapi/engine.v1.yaml: OK |
| uv run openapi-spec-validator contracts/openapi/backend.v1.yaml | 0 | contracts/openapi/backend.v1.yaml: OK |
| uv run python -c "import yaml; yaml.safe_load(open('docker-compose.yml', encoding='utf-8'))" | 0 | 출력 없음; YAML 정적 파싱만 |
| uv run mypy (신규 Fake/단위 테스트 2개/통합 테스트, 총 4파일) | 0 | Success: no issues found in 4 source files |
| git diff --check | 0 | 공백 오류 없음 (Windows CRLF 안내만) |

최종 pytest는 --basetemp 없이 성공했다. 앞서 --basetemp=.pytest-t104 실행은
기존 scripts/tests/test_check_file_lines.py::test_traversal_fallback이 부모 Git 저장소를 발견해
1 failed, 429 passed, 37 deselected였다. 기본 temp로 재실행한 위 결과는 전부 통과했다.
경고 2개: chromadb asyncio.iscoroutinefunction deprecation, pytest cache 경로 생성 경고.
줄 수 검사기는 tracked 파일만 보므로 신규 파일도 별도로 세어 모두 300줄 이하임을 확인했다.
금지 구역 변경 없음. .env.example에는 ENGINE_CHROMA_URL이 이미 있어 변경하지 않았다.

### 실측 규칙 → 테스트 매핑

아래 이름은 test_chroma_store.py 기준. suite=VectorStoreConformance,
boundary=test_chroma_boundary.py, live=test_chroma_live.py.

| # | 실측 규칙 | 검증 테스트 |
|---:|---|---|
| 1 | 이름/단사성/모든 연산 | test_name_injectivity (500개 이상), test_mapping_every_operation (30개), boundary::test_fake_measured_wire |
| 2 | 없는 컬렉션 | suite::test_missing_collection_raises, test_error_translation |
| 3 | dimension 메타데이터/첫 add | test_dimension_metadata, suite::test_collection_dimension_mismatch_raises, boundary::test_fake_measured_wire; 재시작 보존은 live::test_live_restart_phases (미실행) |
| 4 | 잘못된 차원 | suite::test_upsert_dimension_mismatch_raises / test_query_dimension_mismatch_raises, test_error_translation, boundary::test_fake_measured_wire |
| 5 | 생성 시 cosine 설정 | test_empty_order_and_filters (실제 호출 configuration 검증) |
| 6 | 1-cos 거리/점수/크기 불변 | boundary::test_fake_measured_wire (0/0.2929/2), suite::test_scores_clamp_negative_cosine |
| 7 | 영벡터 | suite::test_zero_vector_scores_zero, boundary::test_fake_measured_wire |
| 8 | CodeChunk/열거형 복원 | test_chunk_round_trip (모든 Language/ChunkKind) |
| 9 | None 제거/복원 | test_chunk_round_trip (commit None/값), boundary::test_fake_measured_wire, test_empty_order_and_filters |
| 10 | 사용자 메타데이터 충돌 | test_chunk_round_trip (path/kind/symbol/m_x/여러 scalar) |
| 11 | $and | suite::test_where_equals_combines_with_and, test_empty_order_and_filters, boundary::test_fake_measured_wire |
| 12 | $in/빈 tuple | suite::test_where_tuple_uses_in, test_empty_order_and_filters (미호출/존재 확인), boundary::test_fake_measured_wire |
| 13 | 허용 필터/None 금지 | suite::test_unknown_filter_key_raises, test_empty_order_and_filters |
| 14 | delete 실제 삭제 수 | suite::test_delete_by_paths_returns_count, test_mapping_every_operation, boundary::test_fake_measured_wire (중복 path) |
| 15 | 페이지/마지막 hash/경고 | test_pagination_batching_and_last_hash (2500/1000+1000+500, hash 불일치 경고 경로) |
| 16 | top_k 상한/0 이하 | suite::test_query_limits_top_k / test_upsert_is_idempotent, test_empty_order_and_filters, boundary::test_fake_measured_wire |
| 17 | 빈 입력/없는 컬렉션 순서 | test_empty_order_and_filters, suite::test_missing_collection_raises, boundary::test_fake_measured_wire |
| 18 | 길이→조회→전체 차원→저장 | test_empty_order_and_filters, boundary::test_dimension_check_prevents_partial_batch |
| 19 | 오류 변환/cause/300자 | test_error_translation (5종 × 7개 경계), test_connect |

배치는 test_pagination_batching_and_last_hash에서 1250개 → 500/500/250을 두 번 검증했다.

### 미실행 (Claude가 실행)

- live 통합 테스트 실행 (ENGINE_IT_CHROMA_URL 설정 후 -m integration).
- 컨테이너 재시작 전후 영속성: ENGINE_IT_CHROMA_PHASE=write/read 및 동일한 고유
  ENGINE_IT_CHROMA_PERSISTENCE_NAME으로 두 번 실행; Claude가 외부에서 재시작한다.
  read 단계가 데이터/query/dimension 보존을 확인하고 컬렉션을 삭제한다.
- 1500청크 × 768차원 scale 실행, query p95 측정, 전체 hash/삭제 개수 검증.
- 실제 서버의 동일 VectorStoreConformance suite 실행 (테스트별 고유 namespace/종료 후 삭제).
- compose chroma 블록 실행: YAML 파싱만 수행했으며 image 기동/포트 응답은 미검증.

차이/남은 이슈: 카드의 “27개”와 달리 현재 merged suite는 실제 23개 케이스를 수집한다.
전부 그대로 상속했고 skip/xfail은 없다. 300줄 분리를 위해 Fake 직접 검증용
test_chroma_boundary.py를 추가했다. 계약/인터페이스 변경이나 의존성 추가는 없다.
실제 서버와 Fake의 일치 여부, 영속성/성능은 위 미실행 검증에 남아 있다.
테스트 임시 폴더 .pytest-t104/의 재귀 삭제는 자동 승인 검토에서 정책상 거부되어
untracked 상태로 남아 있다. 구현 파일이 아니므로 커밋 대상에서 제외해야 한다.

### 리뷰 · 실서버 검증 (Claude, 2026-10-21)

Codex는 Docker·실서버 접근이 없어 가짜 클라이언트 위의 단위 테스트까지만 검증했다. 아래는 Claude가 실제 Chroma 서버(digest `sha256:1e0b73a1…`, 영속 볼륨)에서 실행한 결과다.

**카드 정정:** 초판은 병합된 스위트가 "27개 규칙"이라고 썼으나 실제는 **23개**다 (27은 인메모리 Fake의 고유 테스트까지 센 값이었다).

**독립 재검증:** ruff · format · import-linter 5/5 · mypy(src 69파일, 새 테스트 strict) · 300줄 · pytest 430 → 431 passed. 금지 구역·새 의존성 없음, compose 변경은 `chroma` 이미지 한 줄(digest 고정)뿐.

**실서버 (`-m integration`, Codex가 쓴 28개 — 처음 실행): 27 passed, 1 skipped** (skip = 재시작 시나리오, 아래에서 직접 수행)
| 항목 | 결과 |
|---|---|
| `VectorStoreConformance` 23개 규칙을 **진짜 서버**에 상속 | ✅ 전부 통과 |
| 이름: `proj_a-`, `proj_b_`, 64자 `project_id` | ✅ 서버가 거부하지 않음 |
| 규모 1500청크 × 768차원 | ✅ 질의 **p95 56 ms** (기준 < 1 s) |
| `connect()` — `http://host:port`, 끝에 `/`, `127.0.0.1` 세 형태 | ✅ 모두 실제 연결·왕복 (단위 테스트가 못 타는 경로) |

**가짜 클라이언트의 충실도 (이 카드의 핵심 보증):** 같은 시나리오 29가지(왕복, `commit_sha` None/값, 예약 키와 겹치는 사용자 메타데이터, `$and`/`$in`/빈 튜플/`None`/잘못된 키 필터, `top_k` 0과 −1, 차원 불일치, 영벡터, 중복 경로 삭제, 빈 입력과 없는 컬렉션의 순서, 드롭 후 조회 등)을 **진짜 서버와 `FakeChromaClient`에 똑같이 실행해 결과를 비교 → 차이 0건.** 한계: 비교 범위는 이 29가지다.

**영속성 (컨테이너 `docker restart` 1.9 s):** 300청크/20파일/`commit_sha` None·값 혼재/사용자 메타데이터 → 재시작 후 `ensure_collection`으로 다시 열어도 파일 해시 20개 동일, 사용자 메타데이터·`commit_sha`(값과 None) 보존, **차원 보호가 재시작 후에도 유지**(다른 차원 거부), 반복 `ensure_collection`이 데이터를 지우거나 차원을 바꾸지 않음.
⚠️ **동점 순서는 재시작 사이에 달라질 수 있다.** 재시작 전후 질의 1위가 바뀐 것을 조사했더니 데이터 손상이 아니라, 쿼리와 벡터가 **완전히 같은 청크 9개**가 모두 점수 1.0으로 동점이었기 때문이다 (재시작 없이 같은 질의를 10번 하면 항상 같은 5개). 근사 탐색(HNSW)의 동점 선택은 인덱스 상태에 따라 달라진다. 복붙된 코드·빈 함수는 임베딩이 같아 **실제로 동점이 생긴다.** 서비스 계층(T-108 `RagService`)이 재현 가능한 결과가 필요하면 동점을 `chunk_id`로 끊어야 한다.

**이름 변환 단사성 전수 검사 (카드의 가장 위험한 요구):** 알파벳 `a c e x - _ . 1`의 **길이 1~6 모든 문자열 299,592개**에서 서로 다른 입력이 같은 이름이 되는 경우 **0건**, 출력이 서버 규칙을 어기는 경우 0건, `proj_abc`·`my.project` 같은 평범한 이름은 그대로. (예: `c`→`c_c`, `proj_a-`→`proj_a-x`, `proj_ax`→`proj_axx`.)

**변이 테스트 (29개 버그를 하나씩 심어 테스트가 잡는지):** 이름 변환 누락 3곳, 빈 경로 조기 반환(스위트를 깨는 최적화), 점수 클램프·반전, 재정렬 제거, `top_k<=0`·빈 `$in` 서버 전송, 삭제 개수, 페이지네이션 2종, 배치, 차원 검증, 검사 순서, 사용자 메타데이터 접두사, `commit_sha` None 처리 2종, `$and`·`$in`·`None`·잘못된 키 필터, 이름 `x` 이스케이프, 짧은 이름 접두사, 차원 메타데이터 검사, 오류 변환·연쇄·300자 절단, 거리 공간(cosine) — 최종 **29/29 검출.** 처음에는 3건을 놓쳤다.

**리뷰에서 찾아 고친 것 3건**
1. **무한 루프가 CI를 멈출 수 있었다 (T-102와 같은 종류).** 페이지 오프셋이 전진하지 않는 버그를 심었더니 테스트가 **60초 상한까지 매달렸다.** `bounded_store`가 모든 연산을 `wait_for(…, 5)`로 감싸지만 `FakeChromaClient`가 `await`로 이벤트 루프에 **한 번도 양보하지 않아서**, 동기적으로 도는 코루틴에는 `wait_for`가 타임아웃을 발동할 수 없었다 — 상한이 있다는 착각이 보호를 대신하고 있었다. 가짜의 `async` 메서드 8개 첫 줄에 `await asyncio.sleep(0)`을 넣어 진짜 네트워크 호출처럼 양보하게 했고, 같은 버그가 **7초 만에 실패**하는 것을 확인했다.
2. **재정렬 생략 버그를 못 잡았다.** 카드는 "서버 정렬을 가정하지 말고 점수 내림차순을 보장하라"고 했지만, 가짜가 항상 거리순으로 돌려줘서 어댑터가 정렬을 지워도 입력이 이미 정렬되어 있었다. 가짜에 `unsorted_results` 옵션(기본값은 기존 동작 그대로)을 추가하고 `test_query_does_not_rely_on_server_ordering`을 더해 해결했다 (원본에서 통과, 변이에서만 실패).
3. 이름 변환 단사성이 코드 읽기로는 확신하기 어려워 **전수 검사**로 증명했다 (위).

**잘못 의심했다가 확인으로 접은 것:** `connect()`가 `host`에 전체 URL을 넘기는 것이 버그일 것으로 의심했으나 실서버에서 세 URL 형태 모두 정상이었다.

**알려진 한계 / 후속**
- 전체 `chromadb`와 `chromadb-client`는 한 환경에 공존할 수 없어(실측) 단위 테스트는 가짜 클라이언트에 의존한다. 가짜의 충실도는 위 29가지 시나리오 비교와 실서버 스위트로만 보증된다. Chroma 업그레이드 시 `latest` 대신 digest 고정을 갱신할 때마다 이 비교를 다시 돌려야 한다.
- 동점 순서의 비결정성은 서비스 계층 몫(위).
- `get_file_hashes`는 같은 경로의 청크들이 다른 `content_hash`를 가지면 마지막 값을 쓰고 경고만 남긴다 (카드 규칙대로).
