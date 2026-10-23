# T-106: Engine Registry & Factory Wire-up — `FileAdapterRegistry` + 어댑터 조립(컨테이너)

- **담당:** Codex
- **작성:** Claude · 2026-10-23
- **상태:** ready (T-105 머지 후 착수. 이 카드는 T-105 브랜치 위에서 작성됨)
- **우선순위:** P0 — T-107·T-108·T-109와 E2E CLI 스모크(T-110)가 모두 이 조립 위에서 동작한다
- **브랜치:** `task/T-106-engine-registry`
- **관련 문서:** [ADR-0003 v2](../adr/0003-base-model-and-lora-serving.md), 인터페이스 [adapter_registry.py](../../services/ai-engine/src/engine/core/interfaces/adapter_registry.py), 모델 [registry.py](../../services/ai-engine/src/engine/core/models/registry.py), 현재 Composition Root [main.py](../../services/ai-engine/src/engine/main.py)

## 목표
1. `LoRAAdapterRegistry`를 `ml/registry/adapters.json` 읽기 전용으로 구현한다.
2. 지금까지 만든 어댑터 5종(LLM, Embedder, VectorStore, CodeChunker, Registry)을 `Settings`에서 한 번에 만들고, **소유한 네트워크 자원을 한 곳에서 닫는** 조립 계층(`engine/container.py`)을 만든다. 서비스(T-107~)와 API(T-109)와 CLI(T-110)는 이 컨테이너만 쓴다.

## 설계 결정 (Claude 확정 — 바꾸지 말고 구현한다)

### 레지스트리
- 생성자: `FileAdapterRegistry(path: Path, *, base_model: str)`. **`base_model`은 `Settings.base_model`** 이다.
- `list_adapters(stage=None)`: 파일의 모든 어댑터를 `stage`로만 거른다. **`base_model` 필터는 적용하지 않는다** (운영 도구가 전체를 봐야 한다).
- `get(name)`: 없으면 `AdapterNotFound`.
- `resolve(task)`: **`stage == PRODUCTION` 이고 `base_model`이 설정과 같은** 어댑터만 후보다. 이유: ADR-0003 v2에서 base가 3B → 7B로 바뀌었고 LoRA는 학습한 base 모델에서만 로드된다 (3B용 `canary-3b.gguf`는 7B에 올리면 안 된다). 후보가 0개면 `None`(호출측이 base 모델로 폴백). **후보가 2개 이상이면 `EngineError("...", detail={"reason": "registry_ambiguous", "task": ...})`** — 임의로 하나를 고르지 않는다 (등록 파이프라인이 task당 PRODUCTION 1개를 보장한다).
- 파일 형식 `{"schema_version": 1, "adapters": [...]}`. `schema_version`이 1이 아니거나 필드가 없거나 타입이 틀리면 `EngineError("...", detail={"reason": "registry_invalid"})`, 메시지에 파일 경로·원인(최대 300자). `KeyError`·`ValueError`가 그대로 새면 안 된다.
- 파일이 없으면 **빈 레지스트리**로 취급한다(개발 환경 편의). 단, 경로가 디렉터리이거나 읽기 오류면 `EngineError`.
- **호출할 때마다 파일을 다시 읽는다** (캐시 없음 — 승격 직후 반영, 파일은 작다). 파일 I/O는 `asyncio.to_thread`.
- `created_at`은 ISO-8601 문자열(타임존 포함)로 읽어 `datetime`으로 변환한다. `eval_scores`는 `dict[str, float]`.

### 컨테이너
- 모듈: `services/ai-engine/src/engine/container.py` (Composition Root의 일부. 어댑터를 import해도 되는 모듈은 `main.py`와 이 모듈뿐이다. 서비스/라우터가 어댑터를 import하면 import-linter가 막는다).
- 형태:
  ```python
  @dataclass(frozen=True, slots=True)
  class Container:
      llm: LLMProvider
      embedder: Embedder
      store: VectorStore
      chunker: CodeChunker
      registry: LoRAAdapterRegistry
      settings: Settings

      async def aclose(self) -> None: ...


  async def build_container(settings: Settings | None = None) -> Container: ...
  ```
  `async with` 지원을 위해 `__aenter__/__aexit__`도 둔다(`aclose` 호출).
- **Settings 추가 필드**(`settings.py`, 기본값은 실제 어댑터):
  - `llm_provider: Literal["llamacpp", "fake"] = "llamacpp"` (`.env.example`의 `ENGINE_LLM_PROVIDER`)
  - `embedder_provider: Literal["ollama", "fake"] = "ollama"`
  - `vector_store: Literal["chroma", "memory"] = "chroma"`
  - `registry_path: Path = Path("ml/registry/adapters.json")` (`ENGINE_REGISTRY_PATH`)
  - 기존 기본값 테스트(`test_engine_settings.py`)를 새 필드로 확장한다.
- 조립 규칙:
  - `fake`/`memory`를 고르면 GPU·Docker 없이 전체가 조립된다 (CI·CLI 스모크용). **청커는 항상 실제 `TreeSitterChunker`** (순수 함수, 서버 불필요). 문법 로드 실패는 `ParseError`로 그대로 올린다 — `build_container`가 삼키지 않는다.
  - `OllamaEmbedder`의 `gauge`는 **같은 컨테이너의 LLM이 `ActivityGauge`를 만족하면 그것을 넘긴다** (`LlamaServerProvider.in_flight`). Fake LLM이면 `None`. 정책·유휴/체류 시간·prefix·dimension·batch는 `Settings` 값을 그대로 전달한다.
  - Chroma는 기존 `connect(settings)`를 쓴다.
  - 각 `build_*`는 별도 함수로 나눠 단위 테스트 가능하게 한다.
- **자원 소유권(Codex 감사 지적 반영):**
  - 컨테이너가 만든 `httpx.AsyncClient`(LLM, Embedder)는 `aclose()`가 닫는다. 이미 닫힌 뒤 `aclose()`를 또 호출해도 오류가 없다(멱등).
  - 조립 도중 N번째 어댑터 생성이 실패하면, **이미 만든 앞선 어댑터를 모두 닫고** 원래 예외를 다시 올린다 (누수 금지). 테스트: 두 번째 단계를 강제로 실패시키는 가짜 팩토리로 검증.
  - **Chroma 클라이언트를 닫는 공개 API가 있는지 실제로 조사**(`chromadb-client 1.5.9`의 `AsyncHttpClient`)하고 결과를 결과 절에 적는다. 있으면 `aclose`에 포함하고, 없으면 "닫을 수 없음 + 이유"를 코드 주석과 결과에 남긴다 — 비공개 속성(`_server` 등)을 건드리지 않는다.
  - `ChromaVectorStore`에 필요하다면 `aclose()`를 **어댑터 쪽에** 추가해도 된다(Protocol은 건드리지 않는다).
- `main.py`: `create_app()`이 `lifespan`으로 `build_container`/`aclose`를 수행하고 컨테이너를 `app.state.container`에 둔다. **라우터는 이 카드에서 추가하지 않는다**(T-109). `/v1/health`는 지금처럼 정적 응답을 유지하되, 컨테이너가 조립됐는지는 lifespan 테스트로 확인한다. `llm_provider=fake`·`embedder_provider=fake`·`vector_store=memory`일 때 앱 시작/종료가 외부 서버 없이 성공해야 한다.

## 대상 파일
- 구현: `adapters/registry_file.py`, `container.py`(새 파일, 300줄 이하), `settings.py`, `main.py`; Chroma `aclose`가 필요하면 `adapters/vectorstore/chroma.py`
- 테스트: `tests/unit/adapters/test_registry_file.py`, `tests/unit/test_container.py`, `tests/unit/test_engine_settings.py` 확장, `tests/unit/test_main_lifespan.py`
- 적합성: 레지스트리는 `LoRAAdapterRegistry` 계약(위 docstring)을 검사하는 `tests/conformance/registry_suite.py`를 만들고 `FileAdapterRegistry`가 상속한다 (Fake 레지스트리는 만들지 않는다 — 파일 기반이 이미 순수하다).

## 수락 기준
- [x] `RegistryConformance` 스위트 통과: 빈 파일/없는 파일, stage 필터, `get` 미존재 → `AdapterNotFound`, `resolve` 0개 → `None`, 1개 → 그 어댑터, **base_model 불일치(3B용 PRODUCTION)는 후보에서 제외**, 2개 이상 → `detail["reason"] == "registry_ambiguous"`.
- [x] 잘못된 JSON / `schema_version != 1` / 필드 누락 / 잘못된 `stage` 값 / 잘못된 날짜 → 모두 `detail["reason"] == "registry_invalid"` 인 `EngineError` (원시 `KeyError`·`ValueError` 노출 금지). 경로가 디렉터리면 `EngineError`.
- [x] 파일을 바꾸면 다음 호출에 즉시 반영된다 (캐시 없음 확인 테스트).
- [x] `build_container(Settings(llm_provider="fake", embedder_provider="fake", vector_store="memory"))`가 서버 없이 성공하고, `aclose()`는 멱등이다.
- [x] 기본 설정(실제 어댑터)은 **요청을 보내지 않고도 조립된다** (httpx 클라이언트는 지연 연결). 단위 테스트에서는 respx로 "조립 중 네트워크 호출 0"을 단언한다. Chroma `connect`는 서버가 필요하므로 단위 테스트에서는 주입 가능한 팩토리로 바꿔 끼운다.
- [x] 조립 중간 실패 시 앞서 만든 자원이 모두 닫힌다 (닫힘 횟수 단언).
- [x] 임베더의 `gauge`가 LLM과 같은 객체임을 단언한다 (`llamacpp`일 때), fake LLM이면 `None`.
- [x] 앱 lifespan: fake 설정으로 시작/종료 성공, 종료 시 `aclose` 호출 확인.
- [x] Chroma 클라이언트 닫기 조사 결과가 결과 절에 있다.
- [x] `make check` 통과 (ruff, mypy strict, import-linter 5개, 300줄). **import-linter 계약을 새로 추가·변경하지 않는다** — `container.py`가 계약을 어기면 구조를 고치고, 계약 변경이 필요하다고 판단되면 제안에만 쓴다.

## 하지 않는 것
- 헬스 집계(`/v1/health`가 실제 어댑터 상태를 보고하는 것)와 라우터 — T-109.
- LlamaServer의 LoRA 카탈로그 캐시 갱신, Chroma 호출 타임아웃, 손상 레코드 예외 변환 — 어댑터 하드닝 카드(T-111). 이 카드에서 어댑터 내부 동작을 바꾸지 않는다 (위 `aclose` 추가 제외).
- `ml/registry/adapters.json` 쓰기·승격 로직.

## 금지 사항
- **`.git`에 쓰지 않는다** (`git add/commit/push/checkout/branch/stash/reset` 금지). 파일만 수정하고 `git status --short`로 보고한다. 커밋은 Claude가 리뷰 후 한다.
- `contracts/`, `core/interfaces/`, `core/models/`, `core/errors.py`, 루트 `pyproject.toml`, `uv.lock`, `.gitattributes`, `docker-compose.yml` 수정 금지. **새 예외 클래스와 새 에러 코드를 만들지 않는다.** 에러 코드는 `engine.v1.yaml`의 `EngineErrorCode`와 1:1이라(계약 테스트 `test_error_codes.py`) 추가하면 계약 변경과 클라이언트 재생성이 필요하다. 레지스트리 오류는 서버 설정 문제이므로 코드는 `EngineError`의 기본 `internal_error`로 두고, 구분은 `detail["reason"]`(`registry_invalid`/`registry_ambiguous`)로 한다. 이것으로 부족하다고 판단되면 제안에 쓴다.
- 실제 서버가 필요한 확인(Chroma 실서버, Docker)은 하지 않는다 — live 테스트는 환경변수 없으면 skip. Claude가 실행한다.
- 테스트·함수 이름은 파일 간 고유하게. pytest는 `--basetemp`를 저장소 밖(스크래치) 또는 `.data/` 아래로.

## 결과
### 변경 파일
- `services/ai-engine/src/engine/adapters/registry_file.py`: 매 호출 thread I/O, JSON/타입/타임존 검증, base/task/stage 해석, 기존 예외 사용.
- `services/ai-engine/src/engine/container.py`: build 함수, 설정 기반 조립, gauge 연결, 자원 소유권/실패 정리/멱등 종료.
- `services/ai-engine/src/engine/settings.py`: provider 선택 및 registry_path.
- `services/ai-engine/src/engine/main.py`: lifespan 조립/종료 및 app.state.container.
- `services/ai-engine/tests/conformance/registry_suite.py`: 재사용 RegistryConformance.
- `services/ai-engine/tests/unit/adapters/test_registry_file.py`: 적합성 상속, 잘못된 입력/읽기 실패.
- `services/ai-engine/tests/unit/test_container.py`: 조립/설정/네트워크 0/실패 정리/주입 팩토리 소유권.
- `services/ai-engine/tests/unit/test_engine_settings.py`: 기본값/환경변수/잘못된 provider.
- `services/ai-engine/tests/unit/test_main_lifespan.py`: fake 시작/종료/health 및 body 실패 정리.
- 이 카드 `## 결과`.

### 실행과 실제 출력
모든 Python은 `.venv/Scripts/python.exe` 사용. 다운로드/설치/외부 서버/Docker는 실행하지 않았다. 직접 실행한 git 명령은 최종 `git status --short`뿐이다.
기존 `scripts/tests/test_check_file_lines.py`는 임시 경로에 별도 저장소를 만들며 내부에서 `git init/add`를 실행한다. 작업 저장소의 `.git`은 변경하지 않았다.
`make check`는 Windows용 개별 레시피로 실행했다. Ruff는 요청대로 `services scripts packages`만 검사했다.

| 명령 (Python 접두어 생략) | 종료 코드 | 실제 출력 |
|---|---|---|
| `-m ruff check services scripts packages` | 0 | `All checks passed!` |
| `-m ruff format --check services scripts packages` | 0 | `123 files already formatted` |
| `-m mypy --strict packages/py-common/src services/ai-engine/src services/backend/src` | 0 | `Success: no issues found in 72 source files` |
| `.venv/Scripts/lint-imports.exe` | 0 | `Contracts: 5 kept, 0 broken.` |
| `scripts/check_file_lines.py --max 300` | 0 | 출력 없음 |
| `-m openapi_spec_validator contracts/openapi/engine.v1.yaml` | 0 | `contracts/openapi/engine.v1.yaml: OK` |
| `-m openapi_spec_validator contracts/openapi/backend.v1.yaml` | 0 | `contracts/openapi/backend.v1.yaml: OK` |

신규 파일까지 명시적으로 Python으로 줄 수를 계산했다: container 128, registry_file 99, main 32, settings 29, registry_suite 86, test_registry_file 101, test_container 150, test_main_lifespan 47, test_engine_settings 140줄. 모두 300줄 이하.
초기 대상 테스트는 `47 passed, 6 failed`. 로컬 `.env`의 기존 `ENGINE_LLM_PROVIDER=ollama`가 새 Literal 검증과 충돌했다.
새 조립 테스트는 `_env_file=None`으로 격리했다. 전체 테스트는 프로세스 환경에 `ENGINE_LLM_PROVIDER=llamacpp`를 지정했다. 로컬 `.env`는 수정하지 않았다.
`-m pytest services/ai-engine/tests/unit/adapters/test_registry_file.py services/ai-engine/tests/unit/test_container.py services/ai-engine/tests/unit/test_main_lifespan.py services/ai-engine/tests/unit/test_engine_settings.py --basetemp=.data/pt-t106-run -q`: 종료 0, `54 passed, 2 warnings in 79.69s`.
첫 전체 실행은 `$env:ENGINE_LLM_PROVIDER='llamacpp'` 후 `-m pytest --basetemp=.data/pt-t106-run --cov=engine --cov=backend --cov=py_common --cov-report=term-missing -q`: 종료 1, `1 failed, 512 passed, 37 deselected, 3 warnings in 333.93s`. TOTAL coverage 99%, registry_file/container/main/settings 각 100%.
실패는 기존 `scripts/tests/test_check_file_lines.py::test_traversal_fallback`: `.data` 내부 임시 경로에서 상위 작업 저장소를 발견해 fallback 대신 tracked 파일 검색을 한 환경 문제였다. 허용 범위 밖의 스크립트는 수정하지 않았다.
`$env:GIT_CEILING_DIRECTORIES='C:/project/project1/.data'` 후 해당 테스트만 재실행: 종료 0, `1 passed, 1 warning in 0.99s`. 이 설정의 동작을 실제 실행으로 확인했다.
최종 전체 명령 (PowerShell):
```powershell
$env:ENGINE_LLM_PROVIDER='llamacpp'
$env:GIT_CEILING_DIRECTORIES='C:/project/project1/.data'
.venv/Scripts/python.exe -m pytest --basetemp=.data/pt-t106-run --cov=engine --cov=backend --cov=py_common --cov-report=term-missing -q
```
종료 0. 실제 출력: `513 passed, 37 deselected, 2 warnings in 104.04s (0:01:44)`.
`TOTAL 1884 15 99%`. registry_file/container/main/settings 각각 100%.
수락 기준 1~10 모두 충족했다. 10번의 `make check`는 위 개별 레시피 실행으로 충족했으며 실서버 통합 테스트는 제외했다.

### 수락 기준별 증거
1. RegistryConformance: 없는 파일/빈 adapters, stage 필터, get 미존재, resolve 0/1/복수, 3B 제외 테스트.
2. registry_invalid: JSON/schema/누락 필드/stage/task/날짜/타임존/필드 타입/디렉터리/PermissionError 테스트. 경로와 300자 제한 단언.
3. 파일 변경 즉시 반영: `test_registry_contract_refresh`에서 get/list/resolve 확인.
4. fake/memory 조립 및 멱등: `test_t106_container_fake_context`와 주입 팩토리 종료 횟수 테스트.
5. 실제 HTTP 어댑터 지연 연결: Chroma connect만 AsyncMock 주입, respx 호출 수 0 단언. 실제 HTTP 클라이언트 닫힘 확인.
6. 실패 정리: embedder/store/chunker/registry 실패 및 두 번째 주입 팩토리 실패 시 닫힘 횟수, 원래 예외 동일성 단언.
7. gauge 및 정책/시간/prefix/dimension/batch/model/url 전달: `test_t106_container_real_lazy_and_settings`, fake gauge None 테스트.
8. lifespan: fake 환경 시작/정적 health/종료 호출 확인, body 예외에서도 종료 확인.
9. Chroma 조사: 아래 참조.
10. make check 대응 개별 검사: 위 실행 표 및 최종 테스트 결과 참조. 계약 변경 없음.

### Chroma 종료 조사 (실행 근거)
설치 소스를 `inspect.signature`, `inspect.getsource`, `dir`로 직접 조사했다. 서버에 연결하지 않았다.
성공한 명령: `.venv/Scripts/python.exe -c`에서 chromadb, AsyncClientAPI, AsyncClient, AsyncFastAPI와 inspect, importlib.metadata를 import해 버전/반환 타입/종료 메서드/종료 소스/clear_system_cache 소스를 출력 (종료 0).
실제 출력:
```text
chromadb-client 1.5.9
AsyncHttpClient return: <class 'chromadb.api.async_api.AsyncClientAPI'>
AsyncClientAPI lifecycle: []
AsyncClient lifecycle: []
AsyncFastAPI.__aexit__: await self._cleanup()
AsyncFastAPI._cleanup: self._clients.popitem(); await client.aclose()
clear_system_cache: SharedSystemClient._identifier_to_system = {}; SharedSystemClient._identifier_to_refcount = {}
```
`AsyncHttpClient`는 `await AsyncClientCreator.create(...)`를 반환한다. 반환 클라이언트에는 close/aclose/async context manager 공개 API가 없다.
내부 transport만 `__aexit__`와 비공개 `_cleanup`을 갖는다. `clear_system_cache`는 연결 종료 대안이 아니다.
따라서 현재 공개 API로는 **닫을 수 없음**. `container.build_store` 주석에 이유를 기록했고 `_server` 등 비공개 속성에는 접근하지 않았다.
초기 조사에서 `AsyncFastAPI.close` 소스 요청은 `AttributeError`로 종료 1. 이후 위 존재 메서드 조사로 바로잡았다.

### 미실행/불확실한 항목과 제안
- 미실행: Docker 및 실제 Chroma/llama-server/Ollama 통합 테스트 (사용자 금지). 실제 Chroma 접속/서버 종료 상태는 확인하지 않았다.
- 미실행: 문자 그대로의 `make check`, 루트 `ruff format --check .` (지정된 개별 레시피와 디렉터리 검사로 대체).
- 경고: 설치된 Chroma의 asyncio deprecation, 기존 pytest 캐시 경로 권한 경고. 기존 Backend 테스트가 없어 coverage의 backend 미import 경고도 발생했다.
- 새 스크립트/Dockerfile/compose/CI 파일 없음.
- 제안: 로컬 `.env`의 `ENGINE_LLM_PROVIDER=ollama`를 운영자가 `llamacpp` 또는 `fake`로 이관해야 한다. 자동 수정하지 않았다.
- 제안: Chroma 종료 공개 API가 제공되는 버전 도입을 후속 카드에서 검토. 현재 비공개 API 접근 금지 설계에 동의하며 우회하지 않았다.

### 최종 파일 상태
`GIT_OPTIONAL_LOCKS=0` 환경에서 `git status --short` 실행 (종료 0). 수정 금지 구역 변경 없음.
`.pytest-t104/`는 사용자가 언급한 기존 경로이며 수정하지 않았다.
```text
 M docs/tasks/T-106-engine-registry.md
 M services/ai-engine/src/engine/adapters/registry_file.py
 M services/ai-engine/src/engine/main.py
 M services/ai-engine/src/engine/settings.py
 M services/ai-engine/tests/unit/test_engine_settings.py
?? .pytest-t104/
?? services/ai-engine/src/engine/container.py
?? services/ai-engine/tests/conformance/registry_suite.py
?? services/ai-engine/tests/unit/adapters/test_registry_file.py
?? services/ai-engine/tests/unit/test_container.py
?? services/ai-engine/tests/unit/test_main_lifespan.py
```
