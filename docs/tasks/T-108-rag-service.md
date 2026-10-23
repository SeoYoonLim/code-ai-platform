# T-108: `RagService` — 검색 · 컨텍스트 조립 · 근거 기반 채팅 스트림

- **담당:** Codex
- **작성:** Claude · 2026-10-23
- **상태:** todo (**T-107 머지 후 착수** — `container.py`와 `collection_for`가 T-107과 겹친다)
- **우선순위:** P0 — E2E CLI 스모크(T-110)의 "질의 → 출처 포함 답변"이 이 서비스다
- **브랜치:** `task/T-108-rag-service`
- **관련 문서:** [data-flow §4, §4.1](../architecture/02-data-flow.md), [ADR-0003 v2](../adr/0003-base-model-and-lora-serving.md), [ADR-0004](../adr/0004-chunk-text-split-and-id.md), [ADR-0005](../adr/0005-failure-safe-file-replacement.md), 계약 [engine.v1.yaml](../../contracts/openapi/engine.v1.yaml) `ChatStreamRequest`·`SourceRef`·`StreamEvent`·`RetrieveRequest`, 모델 [rag.py](../../services/ai-engine/src/engine/core/models/rag.py), 서비스 시그니처 [rag_service.py](../../services/ai-engine/src/engine/services/rag_service.py)

## 목표
색인된 코드베이스에서 질의에 맞는 청크를 **결정적으로** 찾고, 토큰 예산 안에서 컨텍스트를 조립해, 근거(출처)와 함께 답변을 스트리밍하는 서비스 계층을 만든다. HTTP/SSE 전송은 T-109, Finding 구조화 응답(analyze)과 refactor는 M2의 몫이다. 이 카드는 그것들이 **재사용할 컨텍스트 조립부**(`build_context`)까지 만든다.

## 이미 확정된 것 (Claude가 이 브랜치 첫 커밋에 둠 — 수정 금지)
- 모델: `core/models/rag.py` (`SourceRef`, `ContextBlock`, `ContextBundle`, `ChatRequest`, `SourcesEvent`/`TokenEvent`/`DoneEvent`, `ChatEvent`)
- 서비스 시그니처: `RagService(embedder, store, llm, registry, *, num_ctx, oversample, clock)`, `retrieve`, `build_context`, `chat_stream`, `estimate_tokens`
- data-flow §4.1 갱신: 겹침 제거 규칙, `raw_code`/`search_text` 역할, 결정적 정렬

## 설계 결정 (Claude 확정 — 바꾸지 말고 구현한다)

### 1. 검색과 결정적 정렬 (T-104 동점 문제)
- `retrieve`: `embedder.embed_query(query)` → `store.query(collection_for(project_id), vector, top_k=top_k * oversample, where=where)` → `score < min_score` 제거 → **점수를 소수 6자리로 양자화한 값으로 `(−score, chunk_id)` 정렬** → 앞에서 `top_k`개. 반환하는 `RetrievedChunk.score`는 원래 값을 유지한다(양자화는 정렬 키에만).
- 이유: Chroma는 같은 벡터(동점)의 순서가 재시작 후 바뀔 수 있다(T-104 실측). 정렬을 저장소에 맡기지 않는다. `oversample`(기본 2)은 동점 묶음이 `top_k` 경계에 걸쳐도 같은 청크가 뽑히게 하는 여유다. 동점 묶음이 `top_k*oversample`보다 크면 비결정성이 남는다 — 한계로 문서화하고 테스트에서 그 경계를 명시한다.
- `top_k <= 0`이면 저장소를 호출하지 않고 `[]`. 질의 임베딩은 **마지막 user 메시지**만 쓴다(대화 이력은 검색에 쓰지 않는다 — MVP).
- 컬렉션이 없으면 `CollectionNotFound`가 그대로 올라온다(색인 전). 삼키지 않는다.
- **저장소 내부 상태를 서비스가 알면 안 된다.** 검색은 `VectorStore.query`의 결과만 믿는다(쿼리 필터를 덧붙이지 않는다). 파일 교체 중 짧게 옛 잔여 청크와 새 청크가 함께 보일 수 있다([ADR-0005](../adr/0005-failure-safe-file-replacement.md) 개정 1) — 같은 `path`에서 줄 범위가 겹치므로 아래 3절의 겹침 제거가 자연스럽게 하나만 남긴다. 이 동작은 테스트로 고정한다(같은 path의 옛/새 청크가 겹치면 점수가 높은 쪽만 컨텍스트에 남음). 교체 중 질의의 실서버 검증은 T-110에서 Claude가 한다.

### 2. `search_text`는 검색용, `raw_code`는 프롬프트용
- 프롬프트에는 **`chunk.raw_code`만** 들어간다. 헤더를 포함한 `search_text`는 임베딩 입력이므로 프롬프트에 넣지 않는다 (테스트: 프롬프트에 `# path:` 헤더 줄이 없고, CLASS 청크의 raw_code 전체가 들어간다).
- 토큰 수는 `raw_code`를 기준으로 센다. `estimate_tokens(text) = ceil(len(text) / 3.5)` (빈 문자열 0). 실제 토크나이저로 바꿀 때 이 함수만 바꾼다.
- 출처 표기는 `chunk.path`·`start_line`·`end_line`. MODULE 청크처럼 줄이 흩어진 경우도 `start_line`~`end_line`로 표기한다(정확한 span은 `metadata["spans"]`).

### 3. 컨텍스트 조립 (`build_context`)
- 우선순위: ① 첨부 파일 청크(`attached_paths`) ② 유사 청크. 구조적 컨텍스트(import 대상 심볼)와 module 청크 자동 포함은 analyze용이라 이 카드에서 하지 않는다.
- 첨부 청크: `store.query(..., where=MetadataFilter({"path": tuple(attached_paths)}), top_k=…)`로 **질의와 가장 관련 있는 그 파일들의 청크**를 가져온다 (포트에 "path로 전체 조회"가 없으므로 MVP는 이 방식. 첨부 파일의 모든 청크를 보장하지 않는다는 한계를 문서화). 첨부 `top_k`는 `max(top_k, 8)`.
- **겹침 제거:** 같은 `path`에서 줄 범위가 겹치는 블록은 우선순위 높은 것만 남긴다(첨부 > 유사도 → score 높은 쪽 → chunk_id 작은 쪽). 예: 클래스 청크가 이미 포함되면 그 안의 메서드 청크는 뺀다. `exclude=(path, start, end)`와 겹치는 청크도 뺀다(analyze의 "대상과 겹치는 청크 제외", M2가 사용). 제거 수는 `dropped_overlap`.
- **예산:** 블록을 우선순위 순으로 담다가 예산을 넘는 블록은 **자르지 않고** 건너뛴다(`dropped_over_budget`) — 코드를 중간에서 자르면 의미가 바뀐다. 단, **첨부 블록 하나가 단독으로 예산을 넘으면 조용히 건너뛰지 않고 `ContextTooLarge(detail={"path": …, "tokens": …, "budget": …})`**.
- 블록 순서: 첨부(path, start_line 순) → 유사(정렬 순).

### 4. 채팅 (`chat_stream`)
- 입력 검증: `messages`가 비었거나 마지막이 `role=user`가 아니면 `ValueError`(API가 422로 변환). `context_paths` 20개 초과 등 계약상 한도는 API(T-109)가 검증한다.
- 예산 계산: `budget = num_ctx − max_tokens(요청) − tokens(시스템 프롬프트 골격) − tokens(유지할 대화 이력)`. 대화 이력은 **가장 최근 메시지부터** `(num_ctx − max_tokens) × 0.25` 안에서만 유지한다(오래된 것부터 통째로 버림). **마지막 user 메시지는 항상 유지**하고, 그것만으로 예산을 넘으면 `ContextTooLarge`. 컨텍스트 예산이 0 이하여도 `ContextTooLarge`.
- 프롬프트: `engine/prompts/chat.v1.jinja`(새 파일, **버전 이름 고정**). Jinja2 `StrictUndefined`, 자동 이스케이프 없음. 패키지 리소스(`importlib.resources`)로 읽는다. 내용 요구사항: ① 제공된 코드만 근거로 답하고 모르면 모른다고 말하기 ② 인용은 `[path:start-end]` 형식 ③ 각 블록은 `### path:start-end (symbol)` 제목 뒤에 언어 태그가 붙은 코드 펜스. 템플릿 렌더링 결과를 검사하는 golden 테스트를 둔다(블록 순서, 인용 형식, `search_text` 헤더 부재). 패키지 데이터 포함을 위해 `pyproject.toml` 변경이 필요하면 **직접 고치지 말고 제안**에 적는다.
- 어댑터 선택: `request.adapter`가 있으면 그것(실패 시 `AdapterNotFound` 전파). 없으면 `registry.resolve(AdapterTask.EXPLAIN)`; 결과가 있으면 그 이름을 쓰되 **provider가 첫 토큰 전에 `AdapterNotFound`를 내면 base 모델(None)로 한 번만 재시도**하고 경고 로그를 남긴다. `resolve`가 `None`이면 base.
- 이벤트 순서: `SourcesEvent`(검색이 끝나면 **항상 1회**, 비어 있어도) → `TokenEvent`* (빈 `delta`는 건너뜀, `index`는 서비스가 0부터 증가) → `DoneEvent(finish_reason, usage, latency_ms)`. `latency_ms`는 주입된 `clock`으로 요청 시작부터 마지막 청크까지.
- 공급자가 마지막 청크(`finish_reason`/`usage`)를 주지 않고 끝나면 `EngineError(detail={"reason": "stream_incomplete"})`.
- 오류는 `EngineError`로 그대로 올린다. `error` 이벤트로의 변환과 `meta` 이벤트(stream_id/request_id)는 API 계층(T-109).
- **취소/정리:** 소비자가 제너레이터를 `aclose()`하거나 태스크가 취소되면 provider 스트림을 반드시 `aclose()`한다(`finally`). **`asyncio.timeout`이나 `wait_for`로 `yield`를 감싸지 않는다** (T-102에서 `in_flight` 누수를 낸 전례). 시간 제한은 `GenerationRequest.timeout_s`로 provider에 넘긴다. 테스트: 중간 취소 후 `FakeLLMProvider.in_flight == 0`.
- `GenerationRequest.json_schema`는 쓰지 않는다 (Finding 구조화 출력은 M2 AnalysisService).

### 5. 설정과 테스트 환경 격리
- `Settings`에 `num_ctx: int = 16384`(`ENGINE_NUM_CTX`, 슬롯당 컨텍스트), `rag_oversample: int = 2`(≥1)를 추가한다. 기존 기본값 테스트를 확장한다.
- **테스트는 로컬 `.env`·환경변수에 영향받으면 안 된다.** `tests/conftest.py`에 autouse 픽스처를 추가한다: 모든 `ENGINE_*` 환경변수를 지우고 `Settings.model_config["env_file"]`을 `None`으로 바꿔(`monkeypatch.setitem`) 테스트가 끝나면 복원한다. 새 테스트는 그래도 `Settings(_env_file=None)`을 명시한다. 회귀 테스트: 임시 디렉터리로 `chdir`하고 `ENGINE_LLM_PROVIDER=nonsense`가 든 `.env`를 만든 뒤 `Settings()`가 오류 없이 기본값을 갖는지 확인한다. (이 카드 이전에 로컬 `.env`의 옛 값 때문에 `test_connect` 등이 실패한 전례가 있다.)

### 6. 연결 (T-107 머지 후)
- `collection_for(project_id)`를 **한 곳**으로 합친다: `services/collections.py`로 옮기고 `indexing_service.py`와 `rag_service.py`가 import한다 (서비스끼리 중복 정의 금지).
- `Container`에 `rag: RagService`를 추가하고 `build_container`에서 조립한다(`num_ctx`, `rag_oversample` 전달). 기존 컨테이너 테스트를 확장한다.

## 대상 파일
- 구현: `services/rag_service.py`, `services/collections.py`(새), `prompts/chat.v1.jinja`(새), `settings.py`, `container.py`, `services/indexing_service.py`(import만 변경)
- 테스트: `tests/unit/services/test_rag_service.py`, `tests/unit/services/test_rag_prompt.py`(golden), `tests/unit/test_engine_settings.py` 확장, `tests/conftest.py`(격리), 컨테이너 테스트 확장

## 수락 기준
**★ 표시는 핵심 수락 기준(확정)이다.** 하나라도 빠지면 완료가 아니다.

- [ ] ★ **결정성(점수 소수 6자리 양자화 + `(−score, chunk_id)` 정렬):** 같은 청크 5개가 동점일 때 저장소가 어떤 순서로 돌려줘도(여러 순열을 반환하는 스텁 저장소) `retrieve` 결과가 동일하고 `chunk_id` 오름차순이다. `top_k=2`면 가장 작은 두 `chunk_id`. 점수가 1e-9 차이로 사실상 같은 경우도 같은 규칙. 동점 묶음이 `top_k*oversample`를 넘는 경우의 한계를 명시한 테스트.
- [ ] `min_score`, `top_k<=0`(저장소 미호출), `where` 전달, 컬렉션 없음 → `CollectionNotFound` 전파.
- [ ] ★ **역할 분리(`search_text`=검색용, `raw_code`=LLM 프롬프트용):** 프롬프트에 `raw_code`만 있고 `search_text`의 `# path:` 헤더가 없다. 임베딩 호출 입력(질의)과 프롬프트가 섞이지 않는다. 클래스 청크는 raw_code 전체가 들어간다.
- [ ] ★ **예산 처리(자르지 않고 블록 단위로 건너뜀):** 예산 초과 유사 블록은 통째로 건너뛰고(`dropped_over_budget`) 코드를 중간에서 자르지 않는다. 첨부 블록이 단독으로 예산을 넘으면 조용히 건너뛰지 않고 `ContextTooLarge`(detail 포함). 겹침 제거(클래스⊃메서드, 첨부>유사도, exclude, 교체 중 옛 잔여/새 청크)와 `dropped_overlap` 집계.
- [ ] `estimate_tokens` 경계값(0, 1, 3.5의 배수 근처, 한글/이모지 포함 문자열).
- [ ] 대화 이력 트리밍: 오래된 메시지부터 버리고 마지막 user는 유지, 마지막 user만으로 초과 → `ContextTooLarge`, 예산 0 이하 → `ContextTooLarge`. 마지막이 user가 아니거나 빈 목록 → `ValueError`.
- [ ] ★ **스트림 계약(Sources → Tokens → Done):** `SourcesEvent`가 첫 이벤트(빈 소스 포함) → `TokenEvent` index 0,1,2… 연속 → `DoneEvent`가 마지막이고 `usage`/`finish_reason`이 provider 마지막 청크 값. 빈 delta 생략. 마지막 청크 없이 끝나면 `stream_incomplete`.
- [ ] ★ **취소/정리(`in_flight` 즉시 정제):** 중간에 `aclose()`·태스크 취소 후 `in_flight == 0`, provider 스트림이 닫힌다. `yield`를 감싼 타임아웃이 없다(코드 검토 항목).
- [ ] **어댑터 선택:** 명시 어댑터 → 그대로(미존재 `AdapterNotFound` 전파) / 미지정 + registry PRODUCTION(EXPLAIN) 존재 → 그 이름 사용 / 그 어댑터를 provider가 거부 → base로 1회 재시도 + 경고 로그 / registry가 `None` → base.
- [ ] 프롬프트 golden 테스트(`chat.v1.jinja`): 블록 순서, `### path:start-end (symbol)` 제목, 인용 지침, 언어 태그 펜스.
- [ ] ★ **환경 격리(`Settings(_env_file=None)` + autouse 픽스처):** autouse 픽스처 동작 + `.env` 오염 회귀 테스트가 통과하고, 기존 `test_connect` 류가 로컬 `.env`와 무관하게 통과한다.
- [ ] Container 확장 테스트(`rag`가 조립되고 `num_ctx`가 전달됨). `collection_for` 정의가 한 곳뿐이다(grep 검증).
- [ ] 샘플 저장소를 InMemory 저장소 + Fake 임베더로 색인(T-107 서비스)한 뒤 `chat_stream`이 출처가 실제 `raw_code`와 일치하는 `SourcesEvent`를 내는 통합 성격 테스트 (T-110의 씨앗).
- [ ] `make check` 통과 (ruff 린트·**포맷은 `docs` 포함 저장소 전체**, mypy strict, import-linter 5개 — `services`는 `adapters`를 import하지 않는다 —, 파일당 300줄).

## 하지 않는 것
- HTTP 라우터, SSE 직렬화, `meta`/`error` 이벤트, Idempotency, 인증 — T-109.
- `analyze`(Finding JSON 스키마, 라인 범위 검증, 재시도)·`refactor`(diff 검증) — M2. 구조적 컨텍스트(import 대상 심볼).
- reranker, 하이브리드(BM25) 검색, 인접 청크 병합, 실제 토크나이저.
- 어댑터 내부 변경(Chroma 타임아웃 등) — T-111.

## 금지 사항
- **`.git`에 쓰지 않는다** (`git add/commit/push/checkout/branch/stash/reset` 금지). 파일만 수정하고 `git status --short`로 보고한다. 커밋은 Claude가 리뷰 후 한다.
- `contracts/`, `core/interfaces/`, `core/models/`, `core/errors.py`, 루트 `pyproject.toml`, `uv.lock`, `.gitattributes`, `docker-compose.yml`, `.github/`, `Makefile` 수정 금지. 새 에러 코드/예외 클래스 금지 (구분은 `detail["reason"]`). 새 패키지 설치 금지(`jinja2`는 이미 의존성).
- Docker·외부 서버 금지. 실서버 검증(동점 순서 재시작 후 안정성, 교체 중 질의, 실제 llama-server 스트림)은 Claude가 한다.
- 테스트·함수 이름은 파일 간 고유하게. pytest는 `--basetemp`를 저장소 밖 또는 `.data/` 아래로, `GIT_CEILING_DIRECTORIES=C:/project/project1/.data` 설정.

## 결과
<Codex 기록: 변경 파일, 실행한 명령과 실제 출력, 수락 기준 항목별 충족 여부, 미실행 항목, 제안>
