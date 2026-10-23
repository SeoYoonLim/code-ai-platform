# ADR-0004: CodeChunk의 raw_code / search_text 분리와 chunk_id 규칙

- 상태: **승인됨** (사용자 결정, 2026-10-23)
- 입력: [S-02 보고서](../architecture/spikes/S-02-report.md) §5, §7
- 대체: data-flow §3.2의 `chunk_id = {project_id}:{path}::{symbol}`
- 관련: [T-105](../tasks/T-105-ast-chunker.md)

## 맥락
S-02 실측(httpx 0.28.1, zod v4.6.7)에서 두 가지가 확인됐다.
1. 임베딩용 `text`와 원본 줄 slice가 같지 않다(httpx 27/30, zod 26/30). CLASS는 메서드 본문을 지우고 MODULE은 흩어진 줄을 조립하기 때문이다. 한 필드가 "인용용 원문"과 "임베딩 입력"을 겸하면 줄 범위 100% 정확도를 약속할 수 없다.
2. 기존 ID 식에서 동명 심볼이 충돌한다 (httpx 12건: getter/setter 등, zod 1건). upsert가 한쪽을 덮어쓴다.

## 결정
- `CodeChunk.text`를 **`raw_code`**(원본 그대로)와 **`search_text`**(헤더 + 렌더링 코드)로 나눈다.
  - 단일 span 청크의 `raw_code`는 파일의 `lines[start_line-1:end_line]`와 문자 그대로 같다.
  - MODULE은 span이 여러 개일 수 있다. `raw_code`는 그 span들의 줄만 잇고, `metadata["spans"]`(예: `"1-5,300-310"`)에 목록을 남긴다. 이렇게 하면 최상위 호출 사이의 함수 본문이 MODULE 인용에 끼어들지 않는다.
- `chunk_id = "{project_id}:{path}::{symbol}@{start_line}-{end_line}"`.

## 결과
**(+)** 동명 심볼 충돌이 사라진다(같은 심볼이면서 줄 범위까지 같을 수는 없다). 인용은 `raw_code`로 정확해진다.
**(−)** 파일 위쪽에 줄이 추가되면 아래 심볼의 ID가 모두 바뀐다. "내용이 바뀌어도 ID 유지 → upsert 멱등"이라는 성질이 사라지므로, **변경된 파일의 청크는 항상 `delete_by_paths` 후 재삽입**해야 한다(IndexingService가 이미 이 정책이다). 분석 결과가 저장한 `context_chunk_ids`와 피드백의 chunk_id는 재색인 후 더 이상 존재하지 않을 수 있으므로, 재현에는 `raw_code`와 `commit_sha`를 함께 저장한다(T-107/백엔드에서 반영). 영구 identity(재색인에도 유지되는 ID)가 필요해지면 별도 ADR로 다룬다.
**API 계약:** `engine.v1.yaml`의 `CodeChunk.text`는 그대로 두고 API 계층(T-109)에서 `raw_code`를 매핑한다. 계약 재생성은 필요 없다.
**영속화(Chroma):** 문서는 `search_text`, 메타데이터에 `raw_code`를 저장한다. 실서버에서 메타데이터 값 5 MB까지 왕복이 정상임을 확인했다(2026-10-23).
**미해결(T-105에서 측정만 하고 정책은 별도 결정):** MODULE이 200줄을 넘는 문제(zod 최대 4,692줄), zod 문법 오류 4개 파일의 WINDOW 폴백, TS interface/type/enum을 MODULE에 둘지 여부.
