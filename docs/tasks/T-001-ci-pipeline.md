# T-001: CI 파이프라인 (GitHub Actions)

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (2026-10-21 해제: 원격 `https://github.com/SeoYoonLim/code-ai-platform` 연결, `main` push 완료)
- **후속 (사람):** CI가 처음 green이 되면 GitHub Settings → Branches에서 `main` 보호 규칙을 설정한다. required checks: `python`, `contracts` / PR 필수 / force push 금지
- **우선순위:** P0. 이후 모든 PR이 이 CI를 통과해야 하므로 가장 먼저 한다
- **관련 문서:** [AGENTS.md §5–6](../../AGENTS.md), [03-api-conventions.md §5](../architecture/03-api-conventions.md), [Makefile](../../Makefile)

## 목표
PR과 `main` push마다 AGENTS.md의 완료 조건(`make check`)과 계약 무결성(`make check-contracts` + 생성물 drift)을 자동으로 검증한다.

## 대상 파일
- 신규: `.github/workflows/ci.yml`
- 신규: `.github/pull_request_template.md`
- 신규: `scripts/check_file_lines.py` (300줄 규칙 검사)
- 신규: `scripts/tests/test_check_file_lines.py`
- 수정: `Makefile`. `lint-size` 타겟을 추가하고 `lint`의 의존 목록에 넣는다. **다른 타겟의 레시피는 바꾸지 않는다**
- 수정: 루트 `pyproject.toml`의 `[tool.pytest.ini_options].testpaths`에 `"scripts/tests"`만 추가한다. 이 구역은 원래 Claude 소유지만 이 카드에서는 허용한다

## 구현 명세

### 1. `.github/workflows/ci.yml`

```yaml
name: ci
on:
  pull_request:
  push:
    branches: [main]
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
permissions:
  contents: read
```

| Job | runs-on | 단계 | 비고 |
|---|---|---|---|
| `python` | ubuntu-24.04 | checkout → setup-uv (uv `0.12.17` 고정, cache 활성) → `uv python install 3.12` → `uv sync --all-packages --frozen` → `make check` | `make check` = validate-contracts + lint(ruff·import-linter·mypy·**lint-size**) + test |
| `contracts` | ubuntu-24.04 | checkout → setup-uv → setup-node 22 → `uv sync --all-packages --frozen` → `make gen-clients` → `make verify-clients` → **drift 검사** | Dart는 Makefile의 Docker 폴백 사용 (러너에 Docker 있음) |

**drift 검사:** 생성물을 다시 만든 결과가 커밋된 파일과 다르면 실패시킨다.
```bash
git diff --exit-code -- \
  packages/py-common/src/py_common/generated \
  apps/web/src/lib/api \
  apps/mobile/packages/api_client \
  || { echo "::error::생성물이 contracts와 불일치합니다. 'make gen-clients' 후 커밋하세요."; exit 1; }
```
`git status --porcelain`으로 **새로 생긴 untracked 파일**(예: 새 Dart 모델)도 같은 방식으로 검사한다.

**액션 버전 고정:** 서드파티 액션(`astral-sh/setup-uv`, `actions/setup-node`)은 **커밋 SHA로 고정**하고, 주석에 태그를 적는다 (`uses: astral-sh/setup-uv@<sha> # v6.x.x`). 공급망 공격을 막기 위해서다. `actions/checkout`도 같다.

### 2. `scripts/check_file_lines.py`
- 사용법: `uv run python scripts/check_file_lines.py [--max 300] [paths...]` (기본 경로는 저장소 루트)
- 대상 확장자: `.py .ts .tsx .dart`
- **제외:** `**/generated/**`, `apps/web/src/lib/api/schema.d.ts`, `apps/mobile/packages/api_client/**`, `.venv`, `node_modules`, `.dart_tool`, `build`, `*.g.dart`
- `git ls-files` 결과를 기준으로 검사한다 (untracked 무시). git이 없으면 디렉터리 순회로 대체한다
- 위반이 있으면 `path:lines` 목록을 출력하고 exit 1, 없으면 exit 0
- 표준 라이브러리만 사용하고 `mypy --strict`를 통과해야 한다. 스크립트 자체도 300줄 이하

### 3. `Makefile`
```make
lint-size: ## 파일당 300줄 규칙 검사 (생성물 제외)
	uv run python scripts/check_file_lines.py --max 300
```
`lint: lint-py lint-imports typecheck lint-size`로 바꾸고 `.PHONY`에 추가한다.

### 4. `.github/pull_request_template.md`
```markdown
## 작업 카드
- docs/tasks/T-XXX-....md

## 변경 요약

## DoD (AGENTS.md §6)
- [ ] 작업 카드 수락 기준 전부 충족
- [ ] `make check` 통과
- [ ] 수정 금지 구역 변경 없음 (contracts/, core/interfaces/, core/models/, core/errors.py, generated/)
- [ ] 파일당 300줄 이하
- [ ] 작업 카드 `## 결과` 기록
```

## 수락 기준
- [ ] `python`, `contracts` 두 job이 PR(`task/T-001-ci-pipeline` → `main`)에서 **green** (Actions 탭 링크를 결과에 기록)
- [ ] 의도적으로 깨뜨린 경우 각각 **red**가 되는지 로컬 또는 PR에서 확인하고 결과에 기록:
  - [ ] `contracts/openapi/backend.v1.yaml`에 schema 필드를 추가하고 재생성 없이 커밋 → `contracts` job 실패 (drift)
  - [ ] 301줄짜리 `.py` 파일 추가 → `python` job 실패 (lint-size)
  - [ ] `engine.core`에서 `import httpx` → `python` job 실패 (import-linter)
- [ ] `check_file_lines.py` 단위 테스트: 기준 이하 통과, 초과 실패, 제외 경로 무시, `--max` 옵션 (최소 4케이스, `tmp_path` 사용)
- [ ] 서드파티 액션이 전부 SHA로 고정되어 있음
- [ ] 두 job 모두 15분 이내 (uv cache, Docker 이미지 pull 포함)
- [ ] `make check` 로컬 통과

## 금지 사항
- `contracts/`, `core/interfaces/`, `core/models/`, `core/errors.py`, `**/generated/**` 수정 금지
- `pyproject.toml`은 `testpaths` 한 줄 추가만 허용한다. ruff·mypy·importlinter 설정은 수정 금지
- CI를 통과시키려고 기존 테스트를 skip하거나 xfail 처리하지 않는다. 실패하면 `BLOCKED`로 보고한다
- secrets를 쓰지 않는다 (이 카드의 job은 비밀값이 필요 없다)

## 참고
- 로컬에 `make`가 없으면 Git Bash에서 `winget install ezwinports.make`로 설치한다
- `uv sync --frozen`: `uv.lock`이 `pyproject.toml`과 맞지 않으면 실패한다. 의도된 동작이다
- Dart 검증은 `dart:3.5` 이미지를 쓰며, 첫 pull에 1~2분이 걸린다

## 결과
<Codex 기록>
