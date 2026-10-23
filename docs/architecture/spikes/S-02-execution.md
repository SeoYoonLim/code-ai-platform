# S-02 실제 실행 기록 (2026-10-23 재개)

모든 Python 명령은 저장소 루트의 `.venv/Scripts/python.exe`로 실행했다.
JSON 파일은 실제 stdout JSON을 줄 수 제한에 맞춰 동일 값으로 압축 저장한 것이다.
아래 긴 출력의 일부는 핵심 필드 발췌이며 전체 값은 링크한 JSON에 있다.

## 1. 캐시 및 API 시험

실행(종료 0):

```powershell
.venv/Scripts/python.exe -c "import tree_sitter_language_pack as p; help(p.init); help(p.PackConfig); print('downloaded',p.downloaded_languages()); print('cache',p.cache_dir()); print(p.get_parser('python').parse(b'def f():\n return 1').root_node)"
```

실제 출력 발췌:

```text
init(config: PackConfig | None = None) -> None
    Initialize the language pack with the given configuration.
PackConfig(cache_dir: str | None = None, languages: list[str] | None = None, groups: list[str] | None = None)
downloaded ['javascript', 'python', 'tsx', 'typescript']
cache C:\Users\seoyo\AppData\Local\tree-sitter-language-pack\v1.22.1\libs
(module (function_definition name: (identifier) parameters: (parameters) body: (block (return_statement (integer)))))
```

뒤이어 수행한 대체 캐시 시험에 문제가 있었다. 실행한 Python 코드의 해당 부분:

```text
p.init(p.PackConfig(cache_dir=str(Path('.data/tsl-cache').resolve())))
print('local cache:', p.cache_dir(), p.downloaded_languages())
for lang in ['python', 'typescript', 'tsx', 'javascript']:
    print(lang, p.get_parser(lang).parse(b'x').root_node)
```

실제 출력(종료 0):

```text
local cache: C:\project\project1\.data\tsl-cache\tree-sitter-language-pack\v1.22.1\libs []
python (module (identifier))
typescript (program (expression_statement (identifier)))
tsx (program (expression_statement (identifier)))
javascript (program (expression_statement (identifier)))
```

주의: `cache_dir`는 실제 libs 경로가 아니라 그 위의 base로 해석됐다.
Claude가 복사한 `.data/tsl-cache/v1.22.1/`와 다른
`.data/tsl-cache/tree-sitter-language-pack/v1.22.1/` 아래에 DLL 4개, bundle, manifest,
lock 파일이 새로 생겼다. 캐시 목록 `[]`를 확인하고도 로더를 호출한 것이 실수였다.
명시적 download 함수나 설치 명령은 쓰지 않았지만 **자동 다운로드 가능 경로를 호출했고,
새 캐시가 생성됐으므로 다운로드 금지 준수를 주장할 수 없다.** 실제 네트워크 전송은 계측하지 않았다.
이 시험은 기본 캐시가 이미 성공했으므로 불필요했다. 이후에는 기본 캐시의 존재 확인 후에만
파서를 로드했으며 대체 캐시 호출을 probe 코드에 넣지 않았다. 생성된 캐시는 삭제/이동하지 않았다.

## 2. 실제 AST와 native crash 발견

최초 `--check` 종료 1: `exports_arrows.ts`의 익명 default가 MODULE이었다.
실제 AST는 `export_statement value: (function_expression ...)`였다.
추출기에 function_expression을 추가했고 수동 expected 파일은 바꾸지 않았다.

최초 실제 저장소 probe와 faulthandler 실행:

```powershell
.venv/Scripts/python.exe -X faulthandler scripts/spikes/s02_chunk_probe.py .data/spike-repos/httpx --lang python
```

실제 출력 발췌:

```text
Windows fatal exception: access violation
File "C:\project\project1\scripts\spikes\s02_chunk_core.py", line 37 in s02_node_text
probe-exit=-1073741819
```

메모리 손상 뒤에 보고되는 Python 위치는 실행마다 달랐다. Tree 변수를 명시적으로 보존해도 실패했다.
원인을 좁히기 위해 아래 입력 순회를 두 번 실행했다(독립 stdin Python 코드):

```text
p = get_parser('python')
for repeat in range(3):
    for f in sorted(Path('.data/spike-repos/httpx').rglob('*.py')):
        t = p.parse(f.read_bytes()); stack = [t.root_node]
        while stack:
            n = stack.pop()
            a = n.start_point.row; b = n.end_point.row; c = n.end_point.column
            start = n.start_byte; end = n.end_byte
            name = n.child_by_field_name('name')
            stack.extend(n.named_children)
```

Point 포함 순회 실제 출력: `Windows fatal exception: access violation`.
Point 행을 제거한 byte-only 순회 실제 출력(종료 0):

```text
repeat 0
done
repeat 1
done
repeat 2
done
```

이 차이에 근거해 byte offsets/LF 테이블로 계산하도록 수정했다.
binding 소스의 정확한 결함 위치는 조사하지 않았으므로 추정하지 않는다.

## 3. fixture·경계·저장소 최종 실행

실행 명령(모두 종료 0):

```powershell
.venv/Scripts/python.exe scripts/spikes/s02_chunk_probe.py --check --json docs/architecture/spikes/S-02-fixture-check.json
.venv/Scripts/python.exe scripts/spikes/s02_ast_evidence.py docs/architecture/spikes/S-02-ast-evidence.json
.venv/Scripts/python.exe scripts/spikes/s02_chunk_probe.py .data/spike-repos/httpx --lang python --json docs/architecture/spikes/S-02-httpx.json
.venv/Scripts/python.exe scripts/spikes/s02_chunk_probe.py .data/spike-repos/zod --lang typescript --json docs/architecture/spikes/S-02-zod.json
```

[fixture 실제 출력](S-02-fixture-check.json)은 8개 원본 경로 `checked`와 `damaged_files: 5`,
5개 손상 입력별 ERROR/MISSING 수와 WINDOW 경계를 기록한다.
첫 Python 오류는 ERROR=0/MISSING=1, 나머지 4개는 ERROR=1/MISSING=0.
[AST 실제 출력](S-02-ast-evidence.json)에는 네 파서의 Query names=`["f"]`, 실제 AST,
unicode_offsets=`8–20, 44–56`(각 12bytes/5chars), crlf_lf_equal=true,
200/201/220/221/251의 경계 배열과 독립 경계 단언 결과가 있다.

실제 httpx 출력 발췌:

```text
files=60, lines=17751, chunks=1234, parse_error_files=0
range_samples=30, range_accuracy=1.0, coverage=1.0, missing_lines=0
ms_per_1k_loc_p95=4.57825159883563, timing_repeats=3
chunk_lines_p50=10, chunk_lines_p95=62, chunk_lines_max=203
window_chunk_ratio=0.027552674230145867
syntax_window_chunks=0, oversize_window_chunks=34, id_collisions=12
```

실제 zod 출력 발췌:

```text
files=477, lines=100043, chunks=1939, parse_error_files=4
range_samples=30, range_accuracy=1.0, coverage=1.0, missing_lines=0
ms_per_1k_loc_p95=6.570270277341085, timing_repeats=3
chunk_lines_p50=11, chunk_lines_p95=174, chunk_lines_max=4692
window_chunk_ratio=0.07581227436823104
syntax_window_chunks=117, oversize_window_chunks=30, id_collisions=1
```

각 30개 range_audit에 path/kind/symbol/start/end와 원본·렌더링 일치 여부를 저장했다.
원본 일치는 60/60, 렌더링 일치는 httpx 27/30과 zod 26/30이었다.

## 4. 임베딩 헤더 5개 실제 출력

아래는 `s02_ast_evidence.py`의 실제 `embedding_previews` 값을 개행 그대로 펼친 것이다.
TSX 문법은 tsx지만 헤더의 도메인 language 표기는 typescript로 정규화한다.

```text
# path: python/basic.py
# symbol: square (function, python)
def square(x):
    return x * x

# path: python/decorators_nested.py
# symbol: outer (function, python)
@cache
def outer():
    def inner():
        return 1
    return inner()

# path: typescript/basic.ts
# symbol: Box (class, typescript)
class Box {
  size = 1;
  area() { ... }
}

# path: typescript/exports_arrows.ts
# symbol: add (function, typescript)
export const add = (x: number) => x + 1;

# path: typescript/component.tsx
# symbol: Foo (function, typescript)
export const Foo = () => <div title="한글😀"/>;
```

## 5. 품질 검사

명령 접두사 `.venv/Scripts/python.exe`로 아래를 실행했다.

| 명령 | 종료 | 실제 핵심 출력 |
|---|---:|---|
| -m ruff check scripts/spikes | 0 | All checks passed! |
| -m ruff format --check scripts/spikes | 0 | 3 files already formatted |
| -m openapi_spec_validator contracts/openapi/engine.v1.yaml | 0 | contracts/openapi/engine.v1.yaml: OK |
| -m openapi_spec_validator contracts/openapi/backend.v1.yaml | 0 | contracts/openapi/backend.v1.yaml: OK |
| -m mypy --cache-dir=nul packages/py-common/src services/ai-engine/src services/backend/src | 0 | Success: no issues found in 69 source files |
| .venv/Scripts/lint-imports.exe --no-cache --no-logo (별도 exe) | 0 | Contracts: 5 kept, 0 broken. |
| -m ruff check . --no-cache --output-format concise | 1 | Found 609 errors. |
| -m ruff format --check . --no-cache | 2 | syntax_error.py invalid-syntax; 3 files would be reformatted, 224 files already formatted |

Ruff 609건은 기존 `.pytest-t104/`의 602건과 fixture 7건이다.
문법 오류·탭·끝 개행 없음은 의도한 입력이며 수정하면 검증 대상이 달라진다.
fixture 제외 및 `.gitattributes`의 unicode_crlf.py `-text`는 제안만 한다.
보고서의 설명용 Python 코드 블록 때문에 생긴 추가 format 지적은 text fence로 바꿨다.

pytest 실행(종료 0):

```powershell
$env:COVERAGE_FILE='.data/s02-coverage'
.venv/Scripts/python.exe -m pytest --basetemp=.data/pytest-s02-resumed -p no:cacheprovider --ignore=scripts/tests/test_check_file_lines.py --cov=engine --cov=backend --cov=py_common --cov-report=term-missing
```

실제 출력:

```text
collected 453 items / 37 deselected / 416 selected
TOTAL 1567 22 99%
416 passed, 37 deselected, 1 warning in 12.34s
```

기존 test_check_file_lines.py는 `git init`, `git add`를 실행하므로 재실행하지 않았다.
표준 파일 길이 검사도 내부에서 허용되지 않은 `git ls-files`를 실행하므로 이번에는 쓰지 않았다.
대신 pathlib로 새 파일·카드 전체 줄 수를 세어 ≤300을 단언했다.
실제 출력(이 기록 추가 전): `line_limit_passed: 26 files; max_lines= 236`, 종료 0.
따라서 **전체 make check는 미충족**이며 범위 밖 테스트/설정을 수정하지 않았다.

## 6. git 및 파일 상태

허용된 읽기 명령만 직접 실행했다. 최종 `git status --short`:

```text
 M docs/tasks/S-02-treesitter-chunker.md
?? .pytest-t104/
?? docs/architecture/spikes/
?? scripts/spikes/
?? services/ai-engine/tests/fixtures/chunking/
```

`.pytest-t104/`는 작업 전부터 있었다. untracked 산출물은 `git diff --stat`에 표시되지 않는다.
보호 구역 및 측정 저장소는 수정하지 않았다. 커밋/checkout/staging은 하지 않았다.

`git diff --stat` 실제 출력:

```text
 docs/tasks/S-02-treesitter-chunker.md | 40 ++++++++++++++++++++++++++++++++++-
 1 file changed, 39 insertions(+), 1 deletion(-)
```
