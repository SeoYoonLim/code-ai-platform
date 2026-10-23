# T-107: `IndexingService` + 실패 안전 색인 (`replace_file`, 스캐너)

- **담당:** Codex
- **작성:** Claude · 2026-10-23
- **상태:** todo (**T-106 머지 후 착수** — `container.py`에 스캐너·서비스를 연결해야 한다)
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

## `replace_file` — Chroma 구현 지침 (ADR-0005 §3, 계약만 지키면 전술은 바꿔도 된다)
1. 모든 청크에 메타데이터 `state`를 **항상** 쓴다 (`"live"`|`"staged"`). 쿼리와 `get_file_hashes`는 `state == "live"`만 본다 (`$and`로 기존 필터와 결합; 키 부재 의미론에 기대지 않기 위해 기존 청크도 항상 `state`를 가진다). `state`는 예약 키라 사용자 메타데이터(`m_` 접두사)와 충돌하지 않는다.
2. 순서: ① 새 청크를 `staged`로 `upsert`(배치) → ② 새 청크를 `live`로 올림(`update`/`upsert`) → ③ 이 path의 옛 `live` 청크 중 새 id에 없는 것을 삭제 → ④ (필요하면) staged 잔여 정리.
3. `get_file_hashes`: path별 `live` 청크의 해시가 **모두 같을 때만** 포함한다. 서로 다르면(교체 도중 중단) 그 path를 결과에서 뺀다 → 다음 증분이 다시 처리한다. (기존 `inconsistent_file_hash` 경고 로그는 유지.)
4. chunks가 비면 이 path의 `live`+`staged` 청크를 모두 삭제한다.
5. 모든 chunks의 `path`가 인자와 같아야 한다 (아니면 `ValueError`).
6. 단위 테스트(가짜 Chroma 클라이언트)에서 **단계마다 실패를 주입**해 계약을 검증한다: 각 단계에서 예외가 나도 (a) 교체 전 청크가 쿼리에 나오고 (b) `get_file_hashes`가 옛 해시이거나 path가 빠져 있다. 재호출 후 최종 상태가 정상이다.

## 수락 기준
첫 줄은 항상 적합성 스위트다.
- [ ] `VectorStoreConformance`에 `replace_file` 케이스 추가, 두 구현(InMemory, Chroma 가짜/실서버)이 통과: 옛 id가 새 목록에 없으면 사라짐 / 다른 path는 불변 / 빈 목록 = path 삭제 / 멱등 / 성공 후 `get_file_hashes`가 새 지문 / path 불일치 `ValueError` / 없는 컬렉션 `CollectionNotFound`.
- [ ] `ScannerConformance` 스위트(`tests/conformance/scanner_suite.py`)를 만들고 두 스캐너가 상속: path 오름차순·결정성, CRLF 보존과 해시 = sha256(원문), 크기 초과·바이너리·언어 미지원·glob 제외의 `SkippedFile` 사유, 기본 제외 폴더는 알리지 않음, root 오류, `.gitignore` 존중(FileSystemScanner, `git`이 있는 임시 저장소 — 없으면 skip하지 말고 순회 모드로 대체 검증).
- [ ] **실패 주입 테스트 (이 카드의 핵심):**
  - 2번째 파일의 임베딩이 실패 → 잡 `FAILED`, 1번째 파일은 새 내용으로 교체됨, **2번째 파일의 옛 청크는 그대로 검색되고 해시도 옛 값**, 다시 실행하면 정상 완료하고 최종 상태가 처음부터 정상 색인한 것과 같다.
  - `replace_file`이 실패 → 같은 보장.
  - 저장소가 `delete_by_paths`에서 실패 → 잡 `FAILED`, 교체된 파일들은 일관됨.
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
- 질의(`query`) 쪽 변경: `state == "live"` 필터를 붙이는 것 외에 검색 동작을 바꾸지 않는다.

## 금지 사항
- **`.git`에 쓰지 않는다** (`git add/commit/push/checkout/branch/stash/reset` 금지). 파일만 수정하고 `git status --short`로 보고한다. 커밋은 Claude가 리뷰 후 한다.
- `contracts/`, `core/interfaces/`, `core/models/`, `core/errors.py`, 루트 `pyproject.toml`, `uv.lock`, `.gitattributes`, `docker-compose.yml`, `.github/`, `Makefile` 수정 금지. 새 에러 코드/예외 클래스 금지 (구분은 `detail["reason"]`).
- 새 패키지 설치 금지 (glob은 `fnmatch`, git은 서브프로세스).
- Docker·외부 서버를 쓰지 않는다. Chroma 실서버 확인(`staged`/`$and` 필터 동작, 재시작 후 상태)은 Claude가 한다 — live 테스트는 `ENGINE_IT_CHROMA_URL`이 없으면 skip.
- 테스트·함수 이름은 파일 간 고유하게. pytest는 `--basetemp`를 저장소 밖 또는 `.data/` 아래로.

## 결과
<Codex 기록: 변경 파일, 실행한 명령과 실제 출력, 수락 기준 항목별 충족 여부, 미실행 항목, 제안>
