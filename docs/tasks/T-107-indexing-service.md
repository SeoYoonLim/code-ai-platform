# T-107: `IndexingService` + 실패 안전 색인 (`replace_file`, 스캐너)

- **담당:** Codex
- **작성:** Claude · 2026-10-23
- **상태:** ready — 설계 개정 1 반영, 재위임 대기 (1차 위임은 `BLOCKED: interface`로 중단; T-106 머지 완료 — `container.py`에 스캐너·서비스를 연결해야 한다)
- **우선순위:** P0 — T-108(RAG)·T-109(API)·T-110(E2E 스모크)의 입력이 이 색인이다
- **브랜치:** `task/T-107-indexing-service`
- **관련 문서:** [ADR-0005](../adr/0005-failure-safe-file-replacement.md) (**이 카드의 설계 근거**), [ADR-0004](../adr/0004-chunk-text-split-and-id.md), [data-flow §3](../architecture/02-data-flow.md), 계약 [engine.v1.yaml](../../contracts/openapi/engine.v1.yaml) `IndexRequest`/`IndexJob`/`IndexStats`/`JobProgress`, 포트 [vector_store.py](../../services/ai-engine/src/engine/core/interfaces/vector_store.py) · [source_scanner.py](../../services/ai-engine/src/engine/core/interfaces/source_scanner.py), 모델 [indexing.py](../../services/ai-engine/src/engine/core/models/indexing.py), 서비스 시그니처 [indexing_service.py](../../services/ai-engine/src/engine/services/indexing_service.py)

## 목표
저장소 디렉터리를 읽어 청킹→임베딩→저장하는 색인 유스케이스를 만든다. 핵심은 **어떤 장애가 나도 기존 검색 결과가 사라지지 않는 것**이다 (Codex 감사 2026-10-23이 지적한 "삭제 후 재삽입" 문제의 해결). 포트 변경(`VectorStore.replace_file`, `SourceScanner`)은 Claude가 이 브랜치의 첫 커밋에 확정해 두었다.

## 이미 확정된 것 (수정 금지)
- 모델: `core/models/indexing.py` (`IndexRequest`, `IndexJob`, `IndexStats`, `JobProgress`, `JobError`, `JobStatus`, `IndexMode`, `IndexPhase`, `SkippedFile`, `ScanItem`)
- 포트: `VectorStore.replace_file` + 갱신된 `get_file_hashes`/`ensure_collection`(차원 불일치 신호 `detail["reason"] == "dimension_mismatch"`), 새 포트 `SourceScanner`
- 서비스 시그니처와 `collection_for(project_id)`, `CHUNK_POLICY_VERSION = "chunk-v1"`

## 구현 범위
1. **`services/indexing_service.py`** — 아래 알고리즘. 어댑터를 import하지 않는다(포트만).
2. **`adapters/source/`** — `SourceScanner` 구현 2개
   - `git_scanner.py` (`FileSystemScanner`): `.git`이 있으면 `git ls-files -co --exclude-standard -z`(비동기 서브프로세스)로 목록을 얻고(.gitignore 존중), 없으면 디렉터리 순회. 기본 제외: `.git`, `node_modules`, `.venv`, `venv`, `__pycache__`, `dist`, `build`, `.next`, `target`, `.tox`, `.mypy_cache`. 생성자에 `language_for_path: Callable[[str], Language]`를 주입받는다(어댑터끼리 import 금지 — container가 `adapters.parsing.language_map.language_for_path`를 넘긴다). 언어가 `UNKNOWN`이면 `SkippedFile(path, "unsupported")`. 파일 읽기는 `asyncio.to_thread`. 크기 초과/UTF-8 디코딩 실패/읽기 실패는 각각 `too_large`/`binary`/`unreadable`로 건너뛴다 (예외로 중단하지 않는다).
   - `fake.py` (`InMemoryScanner`): `{path: content}` 딕셔너리를 같은 규칙(정렬, 해시, 스킵)으로 내보낸다. 서비스 테스트·CLI 스모크용.
   - **glob 규칙(문서화하고 테스트한다):** `/`가 없는 패턴은 파일명(basename)에 `fnmatch`; `/`가 있으면 상대 경로 전체에 `fnmatch`이며 `**`는 `/`를 포함한 모든 문자와 일치; `/`로 끝나는 패턴은 그 디렉터리 하위 전체. `include_globs`가 비어 있으면 전부, 있으면 하나라도 맞는 파일만; `exclude_globs`가 우선. 제외된 파일은 `SkippedFile(path, "excluded")`.
   - root가 없거나 디렉터리가 아니면 첫 `__anext__`에서 `EngineError("...", detail={"reason": "source_root_invalid"})`.
3. **`VectorStore.replace_file` 구현 2곳** — `InMemoryVectorStore`(단순), `ChromaVectorStore`(ADR-0005 §3 전술). 및 `ensure_collection`의 `dimension_mismatch` 사유 부여.
4. **Container 연결** (T-106 머지 후): `Container`에 `scanner`(FileSystemScanner 또는 settings가 fake면 InMemoryScanner는 테스트용이므로 빈 것을 쓰지 않는다 — fake 모드에서도 `FileSystemScanner`를 쓴다)와 `indexing: IndexingService`를 추가. 설정: `Settings.index_max_file_bytes: int = 524288`.

## IndexingService 알고리즘 (`run`)
```
job.status = RUNNING; started_at = clock()
collection = collection_for(project_id)
ensure(collection, dimension=embedder.dimension)
    └ VectorStoreError(detail.reason=="dimension_mismatch") 일 때만:
        mode == FULL  -> drop_collection 후 다시 ensure   (ADR-0005 §5: 이 경우에만 검색이 빈다)
        mode == INCREMENTAL -> 그대로 실패 (JobError: 호출측이 mode=full로 재요청해야 함)
stored = {} if (mode==FULL) else await store.get_file_hashes(collection)

# pass 1: 변경 판별 (파일 내용은 보관하지 않는다 — 메모리 O(파일 수))
seen, changed = set(), []
async for item in scanner.scan(root, include/exclude, max_file_bytes=settings):
    SkippedFile -> skipped += 1 ; continue
    fp = fingerprint(item, embedder.model_name, policy_version)
    seen.add(item.path); scanned += 1
    if mode == FULL or stored.get(item.path) != fp: changed.append(item.path)
    progress(SCANNING, current=scanned, total=scanned)
deleted = sorted(set(stored) - seen)          # FULL이어도 stored를 따로 읽어 삭제 대상은 계산한다 (아래 주의)

# pass 2: 변경 파일만 처리 (스캐너를 다시 돌려 changed에 있는 path만 읽는다)
for index, file in enumerate(changed files):
    cancel 확인 (파일 경계)                    -> CANCELED로 종료
    chunks = chunker.chunk(file, project_id, commit_sha)   # ParseError -> skipped(parse_error), continue
    chunks = [replace(c, content_hash=fp(file)) for c in chunks]   # 지문을 저장
    vectors = await embedder.embed_documents([c.search_text for c in chunks])  # 비면 호출하지 않음
    await store.replace_file(collection, file.path, chunks, vectors)
    stats.files_changed += 1 ; stats.chunks_upserted += len(chunks)
    progress(CHUNKING/EMBEDDING/UPSERTING 각 단계, current=index+1, total=len(changed))
if deleted: await store.delete_by_paths(collection, deleted) ; stats.files_deleted = len(deleted)
status = SUCCEEDED ; finished_at = clock()
```
- **주의 (FULL의 삭제 대상):** FULL은 교체 대상 판별에는 `stored`를 무시하지만, 스캔에 없는 path 정리를 위해 `get_file_hashes`는 항상 읽는다. 위 의사코드의 `stored = {}`는 "변경 판별용"이고, 삭제 계산용 `existing`은 따로 읽어라.
- **지문:** `sha256(f"{file.content_hash}\0{embedder.model_name}\0{policy_version}")` hex. 청크의 `content_hash`를 이 값으로 바꿔 저장하므로 비교도 같은 식이다. 파일이 pass 1과 pass 2 사이에 바뀌면 pass 2의 지문이 저장된다(다음 실행이 맞춘다).
- **임베딩이 항상 저장보다 먼저**다. 임베딩 실패는 저장소를 건드리지 않는다.
- **오류 처리:** `ParseError`(파일 단위) → 건너뛰기. 그 밖의 `EngineError` → 잡 `FAILED`, `JobError(code=e.code, message=e.message[:300], retryable=e.retryable)`. 예기치 못한 예외 → `FAILED`(code `internal_error`)로 기록하고 **다시 raise하지 않는다**(`run`은 항상 종료 스냅샷을 돌려준다). 단 `asyncio.CancelledError`는 잡을 `CANCELED`로 기록한 뒤 **다시 raise**한다.
- **취소:** `cancel`은 플래그를 세우고, `run`이 파일 경계에서 확인한다. QUEUED 잡을 취소하면 `run`을 호출해도 실행하지 않고 CANCELED를 유지한다. 종료된 잡에 `cancel`은 그대로 반환(멱등). 없는 job_id는 `None`.
- **동시성:** `start`는 같은 `project_id`의 QUEUED/RUNNING 잡이 있으면 `JobConflict("...", detail={"job_id": 기존 id})`. 검사와 등록 사이에 `await`가 없어야 한다(경쟁 없음). `run`이 이미 RUNNING/종료인 잡이면 아무것도 하지 않고 현재 스냅샷을 반환한다.
- **잡 저장:** 서비스 내부 딕셔너리, `retention`(기본 200) 초과 시 가장 오래된 **종료된** 잡부터 버린다. 잡은 불변 스냅샷으로 교체한다(`dataclasses.replace`).
- 시간과 id는 주입(`clock`, `job_ids`)해서 테스트가 결정적이게 한다. 기본 id는 `uuid4().hex`.

## `replace_file` — Chroma 구현 지침 (ADR-0005 개정 1, 계약만 지키면 전술은 바꿔도 된다)
1차 위임에서 Codex가 원안(`staged`/`live` 승격)의 결함을 증명했다 — 본문만 바뀐 함수는 `chunk_id`가 같아서 덮어써진다. 그래서 **상태 메타데이터와 쿼리 필터 변경은 하지 않는다.** 서버 사실(실측): 한 요청에서 일부 항목이 거부되면 요청 전체가 저장되지 않고, 같은 id의 upsert는 제자리 덮어쓰기이며, 최대 배치는 `await client.get_max_batch_size()`(5461).
1. **새 청크 전체를 한 번의 `upsert` 요청으로** 쓴다. 기존 `upsert`의 `batch_size=500` 분할을 쓰지 않는다 (분할하면 부분 노출이 생긴다). `len(chunks) > get_max_batch_size()`이면 아무것도 쓰지 않고 `VectorStoreError("…", detail={"reason": "replace_too_large"})`.
2. 그 path의 id를 조회(`get(where={"path": path}, include=[])`)해 **새 id 집합에 없는 것을 한 번의 `delete(ids=[…])`** 로 지운다. `chunks`가 비면 `delete(where={"path": path})` 한 번.
3. `get_file_hashes`: path별 해시가 **모두 같을 때만** 그 path를 포함한다. 서로 다르면(1은 성공했고 2가 실패한 잔여 상태) 결과에서 뺀다 → 다음 증분이 다시 처리한다. (기존 `inconsistent_file_hash` 경고 로그는 유지.)
4. 모든 chunks의 `path`가 인자와 같아야 한다 (아니면 `ValueError`). 없는 컬렉션은 `CollectionNotFound`. 예외 변환은 기존 `boundary()`.
5. 단위 테스트(가짜 Chroma 클라이언트)에서 **단계마다 실패를 주입**해 계약을 검증한다:
   - upsert 실패 → (a): 옛 청크가 그대로 쿼리에 나오고 `get_file_hashes`는 옛 해시. 실패한 upsert는 어떤 행도 남기지 않는다(가짜 클라이언트가 이를 모사).
   - 조회 또는 delete 실패 → (b): 새 청크가 **전부** 쿼리에 나오고, `get_file_hashes`에서 그 path가 빠진다. 같은 인자로 재호출하면 잔여가 사라지고 해시가 새 값이다.
   - **본문만 바뀐 함수**(같은 `chunk_id`, 다른 `raw_code`/해시)를 교체하는 케이스를 반드시 포함한다: 어느 단계에서 실패해도 그 함수의 청크가 검색에서 사라지지 않는다 (1차 위임이 찾은 반례).
   - `replace_too_large`는 가짜 클라이언트의 최대 배치를 작게 설정해 검증하고, 호출 후 저장소가 변하지 않았음을 단언한다.

## 수락 기준
첫 줄은 항상 적합성 스위트다.
- [ ] `VectorStoreConformance`에 `replace_file` 케이스 추가, 두 구현(InMemory, Chroma 가짜/실서버)이 통과 (상태 필터 없음 — 쿼리 동작은 변하지 않는다): 옛 id가 새 목록에 없으면 사라짐 / 다른 path는 불변 / 빈 목록 = path 삭제 / 멱등 / 성공 후 `get_file_hashes`가 새 지문 / path 불일치 `ValueError` / 없는 컬렉션 `CollectionNotFound`.
- [ ] `ScannerConformance` 스위트(`tests/conformance/scanner_suite.py`)를 만들고 두 스캐너가 상속: path 오름차순·결정성, CRLF 보존과 해시 = sha256(원문), 크기 초과·바이너리·언어 미지원·glob 제외의 `SkippedFile` 사유, 기본 제외 폴더는 알리지 않음, root 오류, `.gitignore` 존중(FileSystemScanner, `git`이 있는 임시 저장소 — 없으면 skip하지 말고 순회 모드로 대체 검증).
- [ ] **실패 주입 테스트 (이 카드의 핵심, 서비스 수준):**
  - 2번째 파일의 임베딩이 실패 → 잡 `FAILED`, 1번째 파일은 새 내용으로 교체됨, **2번째 파일의 옛 청크는 그대로 검색되고 해시도 옛 값**, 다시 실행하면 정상 완료하고 최종 상태가 처음부터 정상 색인한 것과 같다.
  - `replace_file`이 실패 → 같은 보장.
  - 저장소가 `delete_by_paths`에서 실패 → 잡 `FAILED`, 교체된 파일들은 일관됨.
  - `replace_file`이 `replace_too_large`를 내면 그 파일만 `skipped(too_many_chunks)`로 처리하고 옛 청크는 그대로이며 잡은 계속된다.
  - **본문만 수정한 파일**(같은 심볼·줄 범위)이 임베딩 실패/저장 실패로 중단돼도 그 파일의 검색 결과가 사라지지 않는다.
- [ ] 증분: 두 번째 실행은 `files_changed == 0`이고 **임베딩 호출 0회**. 파일 하나 수정 → 그 파일만 교체. 파일 삭제 → 청크 제거, `files_deleted == 1`. 파일 이름 변경 → 옛 path 삭제 + 새 path 추가.
- [ ] 지문: `embedder.model_name` 또는 `policy_version`이 달라지면 모든 파일이 재처리된다. 같으면 건너뛴다.
- [ ] `mode=full`: 같은 차원 → `drop_collection` 호출 0회, 모든 파일 교체, 스캔에 없는 path 정리. 다른 차원 → `drop_collection` 후 재생성(성공). `mode=incremental` + 다른 차원 → `FAILED`(사유가 `dimension_mismatch`임을 JobError 메시지에 포함). **일반 `VectorStoreError`(차원과 무관)에서는 절대 drop하지 않는다** — 테스트로 단언.
- [ ] 파일 하나의 `ParseError` → 그 파일만 `skipped`(`parse_error`), 잡은 `SUCCEEDED`, 나머지 파일은 정상.
- [ ] 취소: 실행 중 `cancel` → 파일 경계에서 `CANCELED`, 이미 교체된 파일은 일관됨, 이후 `run` 재호출은 아무것도 하지 않음. QUEUED 취소 / 종료 후 취소 멱등 / 없는 id `None`. `asyncio` 태스크 취소 → `CANCELED` 기록 후 `CancelledError` 전파.
- [ ] 충돌: 같은 project의 QUEUED 또는 RUNNING 잡이 있을 때 `start` → `JobConflict`(detail에 기존 job_id). 다른 project는 허용. 종료 후에는 다시 허용.
- [ ] 통계·진행률: `IndexStats` 필드 의미가 위와 같고, `progress.phase` 전이가 SCANNING → (CHUNKING/EMBEDDING/UPSERTING)이며 `current <= total`.
- [ ] 임베딩에는 `search_text`가 들어가고(헤더 포함), 저장된 `raw_code`는 원본이다 (샘플 파일 왕복 단언).
- [ ] 보존: `retention` 초과 시 종료된 오래된 잡부터 제거되고 실행 중인 잡은 제거되지 않는다.
- [ ] 샘플 저장소(`tests/fixtures/sample_repo/` — **직접 작성**한 소형 Python+TS 프로젝트 10개 안팎)를 Fake 임베더·InMemory 저장소로 색인하는 통합 성격 테스트가 통과한다 (T-110 스모크의 씨앗).
- [ ] `make check` 통과 (ruff, mypy strict, import-linter 5개 — `services`가 `adapters`를 import하면 안 된다 — 파일당 300줄).

## 하지 않는 것
- HTTP 라우터·Idempotency-Key·`/v1/collections` — T-109. `RepoSource.local_path` 허용 경로(`/data/repos/…`) 검증도 T-109.
- 어댑터 하드닝(Chroma 타임아웃 등) — T-111. 단, `replace_file`/`ensure_collection` 구현에서 필요한 예외 변환은 기존 `boundary()`를 따른다.
- 잡의 영속화(Backend), 분산 큐, 파일별 병렬 처리(순차 처리로 시작).
- 질의(`query`) 쪽 변경: 검색 동작은 전혀 바꾸지 않는다 (상태 필터 없음).

## 금지 사항
- **`.git`에 쓰지 않는다** (`git add/commit/push/checkout/branch/stash/reset` 금지). 파일만 수정하고 `git status --short`로 보고한다. 커밋은 Claude가 리뷰 후 한다.
- `contracts/`, `core/interfaces/`, `core/models/`, `core/errors.py`, 루트 `pyproject.toml`, `uv.lock`, `.gitattributes`, `docker-compose.yml`, `.github/`, `Makefile` 수정 금지. 새 에러 코드/예외 클래스 금지 (구분은 `detail["reason"]`).
- 새 패키지 설치 금지 (glob은 `fnmatch`, git은 서브프로세스).
- Docker·외부 서버를 쓰지 않는다. Chroma 실서버 확인(원자적 upsert, 재시작 후 상태)은 Claude가 한다 — live 테스트는 `ENGINE_IT_CHROMA_URL`이 없으면 skip.
- 테스트·함수 이름은 파일 간 고유하게. pytest는 `--basetemp`를 저장소 밖 또는 `.data/` 아래로.

## 설계 개정 1 (1차 위임 BLOCKED 이후, Claude)
Codex의 보고가 맞았다: 원안의 `staged`/`live` 전술은 ADR-0004의 `chunk_id`(심볼+줄 범위) 아래서 본문만 바뀐 함수에 대해 계약을 지키지 못했다. [ADR-0005 개정 1](../adr/0005-failure-safe-file-replacement.md)과 `VectorStore.replace_file` 독스트링을 새 계약((a) 교체 전 그대로 / (b) 새 청크 전부 반영 + 옛 잔여 가능)으로 고쳤고, 전술을 "한 번의 원자적 upsert + 잔여 삭제"로 바꿨다. 위 본문은 개정 후 내용이다. 아래 `## 결과`의 BLOCKED 보고는 이력으로 남긴다. 재위임 시 코드는 아직 한 줄도 작성되지 않았다(카드 파일만 변경됨).

## 결과
### BLOCKED: interface (2026-10-23)

제품 구현은 시작하지 않았다. AGENTS.md §2의 "인터페이스가 불충분하다고 판단되면 우회 구현을 하지 말고 멈춘 뒤 보고한다"를 적용한다. 아래 문제는 예외를 잡아 rollback하는 것만으로는 프로세스 중단 시 보장할 수 없다.

1. ADR-0004의 ID는 내용 해시가 아니라 심볼·줄 범위다. `def f():`의 `return 1`을 `return 2`로 바꾸면 두 버전 모두 `p:a.py::f@1-2`이다. ADR-0005의 staged upsert를 같은 ID로 실행하면 옛 live 행이 staged 행으로 바뀐다. 승격 전 중단하면 옛 내용이 검색되지 않는다.
2. 저장용 ID에 버전을 붙여 충돌을 피하더라도 여러 배치로 live 승격 중 중단하면 새 파일의 일부 청크만 노출된다. 포트는 "새 청크가 일부만 보이는 상태로 검색에 노출되지 않는다"고 명시한다. ADR의 혼재 허용과 별개로 이 조건을 만족할 원자적 파일 버전 선택이 필요하다.
3. 옛 청크 삭제를 여러 요청으로 나누면 일부 삭제 후 중단할 수 있다. 삭제가 적용됐지만 응답이 유실된 경우에도 옛 청크 보존을 단순 예외 처리로 보장할 수 없다. 단일 요청의 원자성·내구성은 설치된 HTTP 클라이언트 소스만으로 증명할 수 없다.

현재 카드는 query 변경을 `state == "live"` 필터 추가로 제한한다. 파일별 커밋 버전을 읽어 검색 대상을 선택하는 구현은 이 범위를 넘는다. 계약을 약화하거나 검색 방식 변경을 임의로 도입하지 않았다.

### 실제 확인과 출력

설치된 `.venv/Lib/site-packages/chromadb/api/models/AsyncCollection.py`의 `update`(426행), `upsert`(471행), `CollectionCommon.py`의 요청 검증(360/416행), `api/types.py`의 `validate_where`(1179행)를 읽었다. upsert는 기존 ID를 갱신하는 API이며 update는 독립 `_update` 요청을 보낸다. 클라이언트 소스에서 여러 요청의 트랜잭션 보장을 확인하지 못했다.

`.venv/Scripts/python.exe -`에 PowerShell here-string으로 재현 코드를 전달했다(종료 0). 실제 `TreeSitterChunker`로 두 본문의 ID가 같음을 단언하고, 기존 `FakeCollection`에 old/live → new/staged를 같은 ID로 upsert한 직후 `RuntimeError`를 주입했다. 이후 `where={"state": "live"}` query의 결과가 비었음을 단언했다. 이는 권고 전술의 반례 재현이며 완성된 replace_file의 적합성 테스트가 아니다.

실제 출력:

```text
same_id_after_body_edit: p:a.py::f@1-2
injected: injected stop after staged upsert, before promotion
live_query_ids_after_stop: [[]]
installed_client_where_validation: PASS
scope: existing fake client; real server NOT executed
```

`validate_where({"$and": [{"state": "live"}, {"path": "a.py"}]})`는 설치된 클라이언트에서 실제 실행해 통과했다. 서버의 where 평가, update 적용·원자성·응답 유실, 재시작 후 상태는 **미실행(Claude가 실서버로 검증)**. Docker·외부 서버·새 패키지를 사용하지 않았다. 재현 코드는 Settings를 생성하지 않아 `.env`를 읽지 않는다.

검사 명령과 실제 출력:

| 명령 | 종료 코드 | 실제 출력 요약 |
|---|---|---|
| `.venv/Scripts/python.exe -m ruff check services scripts packages docs` | 0 | `All checks passed!` |
| `.venv/Scripts/python.exe -m ruff format --check services scripts packages docs` | 0 | `153 files already formatted` |
| `.venv/Scripts/python.exe -m mypy --strict packages/py-common/src services/ai-engine/src services/backend/src` | 1 | `Found 2 errors in 1 file (checked 74 source files)`; container.py:92/96의 두 저장소에 replace_file 미구현 |
| `.venv/Scripts/lint-imports.exe` | 0 | `Contracts: 5 kept, 0 broken.` |
| `.venv/Scripts/python.exe -m pytest services/ai-engine/tests/unit/adapters/vectorstore/test_in_memory_store.py --basetemp=.data/pt-t107-run -q` | 1 | `1 failed, 26 passed, 2 warnings`; 기존 runtime Protocol 검사 실패(replace_file 미구현), pytest 캐시 쓰기 권한 경고 2개 |

pytest에는 `GIT_CEILING_DIRECTORIES=C:/project/project1/.data`를 설정했다. 선택한 테스트는 Settings를 생성하지 않는다. 위 검사는 제품 변경 전 상태의 진단이며 T-107 완료 증거가 아니다.

### 수락 기준별 상태

| 카드 항목 | 상태·증거 |
|---|---|
| VectorStoreConformance replace_file | 미충족; 기존 Protocol 검사도 실패(위 pytest 출력) |
| ScannerConformance 및 두 스캐너 | 미구현·미실행 |
| 임베딩/replace_file/delete_by_paths 실패 주입 | 미구현·미실행; staged 직후 중단 반례만 실행 |
| 증분(무변경/수정/삭제/이름 변경) | 미구현·미실행 |
| 모델/정책 지문 변경 | 미구현·미실행 |
| FULL/차원 불일치/일반 오류의 drop 제한 | 미구현·미실행 |
| ParseError 파일별 건너뛰기 | 미구현·미실행 |
| 취소 및 CancelledError 전파 | 미구현·미실행 |
| 프로젝트별 잡 충돌 | 미구현·미실행 |
| 통계·진행률 | 미구현·미실행 |
| search_text 입력/raw_code 왕복 | 서비스 미실행; 반례에서 chunker의 ID 유지·원문 변경만 단언 |
| 잡 retention | 미구현·미실행 |
| 직접 작성한 샘플 저장소 통합 테스트 | 미구현·미실행 |
| make check 및 300줄 | 완료 아님; ruff/import 통과, mypy/선택 pytest 실패. 전체 make check 미실행 |

### 변경 파일과 제안

변경 파일은 이 카드(`docs/tasks/T-107-indexing-service.md`)뿐이며 제품 코드·금지 구역·`.git`은 수정하지 않았다. 새 스크립트·Dockerfile·compose·CI 설정은 작성하지 않았다.

제안: Claude가 파일 버전 커밋 지점, 커밋 이후 정리 실패의 의미, 프로세스 중단 및 응답 유실의 보장 범위를 먼저 확정한다. 강한 계약을 유지하려면 버전별 물리 ID와 내구성 있는 파일별 커밋 선택, 이를 사용하는 검색·해시 조회를 함께 설계하고 query 변경 허용 범위를 조정하는 방향을 검토한다. 단순 staged/live 배치 승격이나 메모리 rollback만으로 현재 계약을 충족했다고 보고해서는 안 된다.
