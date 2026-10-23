# S-02 tree-sitter 청킹 실측 보고서

2026-10-23. 문법 캐시 확보 후 스파이크를 재개해 AST 매핑, fixture, 두 저장소 측정을 수행했다.
프로덕션 구현이나 보호된 계약 변경은 하지 않았다. **T-105에 넘길 정책상 충돌과 목표 초과를 발견했다.**
실행 명령·종료 코드·실제 출력은 [실행 기록](S-02-execution.md), 전체 출력은 아래 JSON에 있다.

## 1. 환경과 재현

- Python 3.14.7, tree-sitter 0.26.0, tree-sitter-language-pack 1.22.1.
- 기본 캐시 `C:\Users\seoyo\AppData\Local\tree-sitter-language-pack\v1.22.1\libs`에서
  Python/TypeScript/TSX/JavaScript 모두 로드 성공. `Parser(language)`, `Query`, `QueryCursor.captures` 실측 성공.
- `init`/`PackConfig`는 실제 `help()`로 확인했다. 대체 캐시 시험 중 새 하위 캐시가 생성되는
  자동 획득 경로를 호출한 실수가 있었다. 다운로드 금지 준수를 주장할 수 없는 이 경위는 실행 기록 §1에 명시했다.
  이후 모든 probe는 `downloaded_languages()`로 존재를 확인한 기본 캐시만 사용한다.
  패키지 설치·clone은 하지 않았다.
- 이전 차단 보고의 문법 부재는 해결됐다. 그러나 Point 속성 반복 접근은 이 환경에서 native crash를 냈다.
  `start_point.row/end_point.row/column` 순회를 포함한 저장소 실행은 `-1073741819`였다.
  같은 입력에서 byte offset 접근만 남긴 3회 순회는 종료 0이었다.
  probe는 byte offset과 LF 시작 위치 테이블의 bisect로 범위를 계산한다. 패키지 패치는 하지 않았다.
  **[Claude 검증 2026-10-23] 원인은 `tree-sitter` 0.26.0 바인딩이다.** CPython 3.12.14(CI와 동일)와 3.14.7 모두에서 재현됐고, language-pack 없이 `tree-sitter-python` 단독으로도 재현됐다(Windows). `tree-sitter==0.25.2`에서는 같은 순회가 정상(language-pack 1.22.1 호환 확인)이며 httpx 재측정 결과(청크 1,234개, ID 충돌 12건)도 동일하다. 따라서 `services/ai-engine/pyproject.toml`을 `tree-sitter>=0.25,<0.26`으로 고정했다. Linux(CI)에서의 재현 여부는 미확인이므로 T-105 수락 기준 1번(네 파서 순회가 크래시 없이 완료)을 CI에서 계속 검증한다.

산출물:

- [AST·오프셋·헤더 증거](S-02-ast-evidence.json), [fixture 검증](S-02-fixture-check.json)
- [httpx 전체 출력](S-02-httpx.json), [zod 전체 출력](S-02-zod.json)
- `scripts/spikes/s02_chunk_probe.py`: CLI·측정·fixture 비교
- `scripts/spikes/s02_chunk_core.py`: 순수 추출·렌더링·WINDOW·기존 ID 식
- `scripts/spikes/s02_ast_evidence.py`: 독립 경계 단언·Query·AST 관측

## 2. 노드 매핑 확정안

다음 타입은 fixture 또는 저장소 AST에서 직접 관측했다. kind 배정은 이 스파이크의 권고 정책이다.

| kind | Python | TypeScript / TSX | 정책 |
|---|---|---|---|
| function | function_definition; decorated_definition → definition | function_declaration, generator_function_declaration | async도 같은 Python 노드이며 함수 내부 함수는 부모에 포함 |
| function | 해당 없음 | lexical_declaration / variable_declaration → variable_declarator → arrow_function / function_expression | 변수 이름 사용, 단일 declarator 대상 |
| function | 해당 없음 | export_statement → value:function_expression | **익명 default function은 function_declaration이 아니었음**; 이름 default |
| class | class_definition | class_declaration, abstract_class_declaration | 필드와 메서드 서명 보존 |
| method | 클래스 본문의 function_definition / decorated_definition | method_definition, public_field_definition → arrow_function | 필드 함수도 독립 method |
| module | import/상수/최상위 if·호출·나머지 줄 | import_statement, interface_declaration, type_alias_declaration, enum_declaration, 재수출, 최상위 호출 | 타입 3종을 CLASS로 억지 매핑하지 않음 |
| window | root.has_error | root.has_error | ERROR뿐 아니라 MISSING도 전체 파일 폴백 |

TS 추상 메서드는 실제 `abstract_method_signature`였다. 본문이 없어 별도 METHOD로 추출하지 않고
클래스 서명에 남긴다. 저장소에서는 TS `function_signature`, `generator_function`도 관측했다.
`function_signature`는 MODULE, generator 표현식은 기본 함수 후보로 인식한다.
JS도 실제 파서·Query와 arrow 경로를 확인했지만 대규모 JS 저장소 평가는 수행하지 않았다.

일곱 결정과 근거:

1. **decorator 포함.** Python outer는 1–5줄, Outer.Inner.run은 decorator부터 8–10줄이었다.
   decorator 인자는 동작에 영향을 주므로 시작 범위에서 제거하면 안 된다.
2. **export 래퍼 포함, 내부 이름 사용.** add/named는 변수 이름, 익명 default function은 `default`.
   export 줄을 함께 넣어 공개 여부를 보존한다. `export { x }`는 MODULE.
3. **interface/type/enum은 MODULE.** 실제 세 노드 타입을 모두 확인했다. CLASS의 메서드 본문 제거
   의미와 맞지 않는다. 타입 선언을 검색 가능한 별도 단위로 만들 TYPE kind는 후속 제안이다.
4. **중첩 함수는 부모에 포함.** outer.inner는 별도 청크가 없고 outer의 원문에 보존된다.
   closure 문맥을 잃거나 같은 본문을 중복 임베딩하는 것을 막는다.
5. **클래스는 메서드 본문만 생략.** 중첩 클래스 내부 메서드까지 제거하고 decorator/필드/서명을 남긴다.
   TS 표현은 `area() { ... }`, Python은 아래와 같다. 이는 임베딩 표현이지 실행할 소스가 아니다.

   ```text
   class Box:
       size = 1
       def area(self): ...
   ```

6. **중첩 클래스 경로는 Outer.Inner.run, 익명 default는 default.** 중첩 함수까지 경로를 확장하지 않는다.
   동명 getter/setter 충돌은 별도 역할 구분이 필요하다(§7). 현재 계약 식을 조용히 바꾸지 않았다.
7. **TSX Foo arrow는 FUNCTION.** 실제 `jsx_self_closing_element`를 갖는 arrow_function으로 관측했다.
   도메인 언어는 TYPESCRIPT, 문법 선택은 `.tsx` 확장자를 사용하는 정책을 권고한다.

## 3. 실제 저장소 측정

SHA는 카드의 고정 체크아웃 식별자다. git 명령 제한에 따라 HEAD의 독립 SHA 검증은 미실행이다.
파일과 소스는 읽기만 했다. TypeScript 지표는 카드와 맞춰 `.ts`만 사용하며 TSX는 fixture에서 검증한다.
초기 511개(.ts+.tsx) 탐색 실행은 최종 표에서 제외했다.

| 항목 | httpx | zod |
|---|---:|---:|
| 태그 | 0.28.1 | v4.6.7 |
| 카드 SHA | 26d48e0634e6ee9cdc0533996db289ce4b430177 | b500a2ee95134f81d74da7911d7378dd2853d042 |
| 파일 / LOC | 60 / 17,751 | 477 / 100,043 |
| 청크 수 | 1,234 | 1,939 |
| 파일별 median 시간의 p95(ms/1k LOC) | 4.58 | 6.57 |
| 청크 줄 수 p50 / p95 / max | 10 / 62 / 203 | 11 / 174 / 4,692 |
| WINDOW 청크 / 비율 | 34 / 2.76% | 147 / 7.58% |
| syntax / oversize WINDOW 청크 | 0 / 34 | 117 / 30 |
| 문법 오류 파일 | 0 | 4 |
| 원본 범위 표본 정확도 | 30/30, 100% | 30/30, 100% |
| 원본 범위 커버리지 / 누락 줄 | 100% / 0 | 100% / 0 |
| 반복 출력 및 ID 목록 동일 | 60/60 파일 | 477/477 파일 |
| 현재 ID 식의 충돌 수 | 12 | 1 |

파일별 parse+chunk를 3회 측정한 median을 1k LOC로 정규화하고 nearest-rank p95를 계산했다.
파서 로드·파일 읽기·ID/커버리지 감사·두 번째 AST 순회·헤더 출력은 타이머 밖이다.
OS cache를 비우지 않았으므로 cold-start 성능으로 해석하지 않는다.
줄 수 분포는 렌더링 text의 줄 수, WINDOW 분모는 전체 생성 청크다.

**속도 목표 <50ms/1k LOC는 충족했다. zod p95≤120 및 WINDOW<5%는 충족하지 못했다.**
따라서 200줄 기준을 두 언어에 공통 적용해도 좋다는 결론을 내리지 않는다.
zod 최대 MODULE은 `packages/zod/src/v4/classic/tests/to-json-schema.test.ts`이며
원본 범위 1–4733줄, 렌더링 4692줄이다. 최상위 test 호출의 callback들이 MODULE에 남기 때문이다.
httpx 최대 MODULE도 203줄이다. 파일당 MODULE 1개에는 심볼용 200줄 제한이 적용되지 않는 허점이 있다.
수치를 낮추려고 MODULE을 WINDOW로 바꾸면 계약 의미와 폴백 비율 분모가 달라져 이번 실측에서는 바꾸지 않았다.

zod에서 파서가 has_error를 반환한 실제 파일:

- `packages/zod/src/v4/classic/schemas.ts`
- `packages/zod/src/v4/core/checks.ts`
- `packages/zod/src/v4/core/schemas.ts`
- `packages/zod/src/v4/mini/schemas.ts`

이 파일들은 실제 TypeScript 컴파일 오류라고 단정할 수 없다. 설치된 문법의 지원 범위와의 차이일 수 있다.
정상 심볼을 부분 추출하지 않고 Protocol대로 전체 WINDOW로 전환했다.

## 4. fixture와 경계 검증

8개 원본과 각 `.expected.json`은 이전 직접 작성본을 유지했다. 기대값을 출력에 맞춰 자동 재생성하지 않았다.
첫 검증에서 익명 default 함수를 MODULE로 잘못 보낸 것을 고친 뒤 **8/8 일치**했다.

| fixture | 검증한 범위 |
|---|---|
| python/basic.py | MODULE 1–2, square 3–4, Box 5–8, Box.area 7–8 |
| python/decorators_nested.py | outer 1–5, Outer 6–10, Outer.Inner 7–10, Outer.Inner.run 8–10 |
| python/syntax_error.py | WINDOW L1-4 |
| python/unicode_crlf.py | MODULE 1, greet 2–3; CRLF/탭/끝 개행 없음 |
| typescript/basic.ts | MODULE 1–4, Box 5–8, Box.area 7, square 9 |
| typescript/exports_arrows.ts | add 1, named 2, default 3, Base 4–8, Base.field 6, Base.items 7, values 9 |
| typescript/component.tsx | Foo 1 |
| typescript/syntax_error.ts | WINDOW L1-2 |

실제 UTF-8 문자열 `"한글😀"`은 start_byte=8, end_byte=20, **12 bytes / 5 Unicode 문자**였다.
두 번째 `"안녕🌳"`은 44–56 bytes였다. byte slice decode와 원문 일치를 확인했다.
CRLF→LF 변환 시 kind/symbol/줄 범위가 같고 text는 개행만 달랐다.
빈 파일 0개, 주석만 파일 MODULE 1개, 끝 개행 없는 text 보존을 독립 단언했다.
LF만 행 경계로 사용해 문자열 내 U+2028을 가짜 줄로 세지 않는 것도 검사했다.

200줄 함수는 FUNCTION, 201줄은 L1-120/L101-201,
220줄은 L1-120/L101-220, 221줄은 여기에 L201-221을 추가했다.
251줄도 L1-120/L101-220/L201-251이고 overlap은 정확히 20줄이었다.
미지원 입력의 WINDOW helper도 검사했다. 프로덕션 supports(Language) 구현은 이 스파이크 범위 밖이다.

손상 입력 5개: Python 3개/TS 2개 모두 전체 WINDOW. 첫 Python fixture는 ERROR=0이지만
MISSING=1이었다. 나머지 4개는 ERROR=1이었다. `ERROR` 타입만 찾으면 오류를 놓친다.
정상 good 함수가 앞에 있어도 별도 FUNCTION을 보존하지 않는 결과를 확인했다.

## 5. 범위 정확도 해석과 인터페이스 변경 제안

각 저장소 Random(20261023) 표본 30개에 대해 `source_text == lines[start-1:end]`는 100%다.
전체 청크의 source_lines union으로 원본 줄 100%를 덮는다. `range_audit`에 60개 개별 결과가 있다.
이 커버리지는 **원본 span 커버리지**다. 모든 코드가 별도 의미 단위로 검색된다는 보장은 아니다.

반면 임베딩용 `text`와 원본 slice의 문자 그대로의 일치는 **httpx 27/30, zod 26/30**이었다.
클래스는 본문을 지우고 MODULE은 흩어진 줄을 조립하므로 예상된 차이다.
카드의 범위 100%를 렌더링 text의 문자 동일성으로 해석하면 **그 수락 기준은 미충족**이다.
이를 슬쩍 원본 매핑 검증으로 바꿔 모두 통과했다고 보고하지 않는다.

T-105 계약에는 원본 source span/text와 rendered embedding text를 분리하고,
MODULE의 복수 span 및 렌더링 후 line map을 명시할 것을 제안한다.
단일 start/end로 MODULE을 인용하면 가운데 함수 본문까지 인용 범위에 들어간다.
보호된 인터페이스/모델은 수정하지 않았다. 이 스파이크의 추가 필드는 계약 우회 구현이 아니라 측정용 provenance다.

## 6. 검사 및 남은 한계

- `ruff check scripts/spikes`, `ruff format --check scripts/spikes` 통과.
- 모든 신규 소스/문서/JSON 및 카드가 300줄 이하. JSON은 전체 출력을 압축해서 1줄로 보존했다.
- OpenAPI 2개, mypy 69개 소스, import 계약 5개 통과.
- git을 실행하는 `scripts/tests/test_check_file_lines.py`는 이번 재실행에서 제외하고 pytest **416 passed**.
  기존 전체 pytest의 1건 실패는 이전 기록이며 이번에 전체 suite를 통과했다고 주장하지 않는다.
- 전체 Ruff는 기존 `.pytest-t104/` 및 의도적 문법 오류/탭 fixture 때문에 실패한다.
  전체 format도 fixture 때문에 실패한다. 보호된 pyproject.toml 제외 설정은 변경하지 않았다.
- 5개 실제 임베딩 입력은 실행 기록 §4 및 AST evidence JSON에 있다. 외부 코드를 fixture로 복사하지 않았다.
- 미실행: 다른 Python/binding 조합, 전체 git 사용 테스트, SHA 독립 재검증, 실제 임베딩/GPU 및 검색 품질 평가.
  후자의 항목은 스파이크에서 성능/범위 측정과 혼동하지 않는다.

## 7. 추가 제안과 놓친 점

**ID가 안정적이면 멱등이라는 설계 설명에 동의하지 않는다.** 실제 httpx getter/setter
`BaseClient.timeout`, `HTTPError.request`, `Response.encoding` 등 **12개 ID가 각 2회** 나온다.
zod도 `JSONSchemaGenerator.counter`가 2회였다. 현재 `project:path::symbol`로 upsert하면 한쪽을 덮어쓴다.
역할(get/set/overload/구현체)과 동명 occurrence를 구분하고, 모든 색인 전 충돌 검사를 해야 한다.
결정적 ID 목록과 고유한 ID 목록은 다른 조건이다. 순번은 선언 삽입 시 바뀌므로 영구 identity는 별도 설계가 필요하다.
WINDOW의 L범위 ID도 줄 삽입에 불안정하다. 이번에는 충돌을 숨길 suffix를 임의 추가하지 않았다.

**해시와 세대 관리가 청커 계약에 부족하다.** 파일 raw-byte hash, 청크 source-span hash,
실제 embedding-input hash를 구분해야 한다. 메서드 본문만 바뀌면 class 렌더링은 같을 수 있다.
file hash를 임베딩 캐시 키로 쓰면 같은 class를 다시 임베딩한다. 반대로 같은 파일 hash라도
문법·chunker·renderer·헤더 정책이나 embedding 모델이 바뀌면 재색인이 필요하다.
동일 dimension인 다른 임베딩 모델도 있으므로 dimension 검사만으로 세대 호환성을 보장할 수 없다.

**삭제 후 재삽입에 동의하지 않는다.** 이번 zod 4개 파일처럼 문법 지원 차이만으로 정상 심볼이
117개 WINDOW로 바뀐다. 청킹 성공/빈 파일/미지원/parse error/파서 장애를 구분하고,
새 세대 준비→전체 임베딩 검증→활성 세대 전환→구세대 정리로 바꾸자.
중간 batch 실패·취소·동시 commit 작업이 기존 검색 내용을 없애지 않도록 해야 한다.
chunk_id만 저장한 학습/피드백 기록도 세대가 없으면 과거 입력을 재구성하지 못한다.

**200줄만으로 충분하다는 전제에 동의하지 않는다.** 실제 MODULE 최대가 4692줄이다.
byte/token 예산을 추가하고 MODULE 다중 span 분할, test callback 추출, 타입 별도 청크를 비교하자.
threshold만 낮추면 WINDOW 비율이 더 커질 수 있다. zod 7.58% 중 117/147은 syntax 폴백이므로
200을 조절하는 것보다 문법 호환성과 부분 오류 정책을 먼저 확인해야 한다.
큰 클래스 WINDOW와 메서드 독립 청크가 본문을 중복하는 문제도 있다. 원본 커버리지 외에
실제 payload의 중복 byte/token 비율을 측정해야 한다.

혼합 `const a=1, f=()=>2`는 현재 MODULE로 보낸다. object method/namespace/함수 대입/
anonymous class/overload 선언 그룹/조건부 정의의 승격 정책도 아직 없다.
JavaScript는 파서 로드 성공이 지원 완료를 뜻하지 않으며 JSX/CommonJS 정책이 따로 필요하다.
Go/Java 확장에는 receiver/constructor/overload/package 경로의 새 fixture가 필요하다.

Point native crash는 문법 오류처럼 폴백할 수 있는 Python 예외가 아니다.
문법 아티팩트 체크섬·패키지/CPython 조합 smoke test·startup readiness를 고정하자.
`init(cache_dir=...)`가 기대한 libs 경로를 그대로 쓰지 않은 것도 배포용 사전 검증에 포함해야 한다.
프로덕션 요청 경로에서 자동 다운로드를 허용하면 순수 청커 I/O 금지와 재현성을 깨뜨린다.
문법 로드는 composition root에서 끝내고, 바인딩 crash 격리가 필요하면 작업 프로세스 경계도 검토하자.

AST 청킹이 검색 정확도를 높인다는 D5는 아직 품질 가설이다. 실제 질의/정답 심볼을 작성해
단순 WINDOW 대비 recall@k, 중복, 토큰 비용을 평가해야 한다. 이번 속도/줄 범위 수치만으로
검색 품질이 좋다거나 TYPE=MODULE 결정을 검증했다고 해석하면 안 된다.

### T-105 수락 기준 초안

1. 승인된 문법/CPython 조합에서 네 파서·Query smoke 및 실제 저장소 순회가 native crash 없이 완료된다.
2. fixture 8/8, 손상 입력 5/5, UTF-8·CRLF·탭·빈/주석/끝 개행 없음·200/201/220/221/251 경계를 통과한다.
3. 이 보고서의 7개 정책 및 source/rendered text·복수 span 계약을 먼저 승인한다.
4. 원본 span 표본 30개/저장소 100%, 전체 source-map 누락 0; rendered text는 별도 golden으로 검증한다.
5. ID 결정성뿐 아니라 충돌 0. getter/setter/overload/WINDOW 중복을 실제 fixture로 재현한다.
6. 파일별 median의 p95<50ms/1k LOC를 고정 체크아웃에서 측정한다. cold/load 시간은 별도 지표다.
7. MODULE과 타입/callback 분할 정책을 정한 후 p95≤120 및 WINDOW<5%를 재평가한다.
   현재 zod 기준으로 이 두 수치를 통과 조건으로 확정하지 않는다. oversize/syntax를 분리해 보고한다.
8. file/source/embedding hash와 정책 버전을 manifest에 기록하고 부분 실패 시 이전 세대를 보존한다.
9. 실제 embedding 입력 5개 및 byte/token 상한을 검증하고, fixture 제외 정책 정리 후 전체 check를 통과한다.
