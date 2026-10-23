# ADR-0005: 파일 단위 실패 안전 교체 (`replace_file`)와 색인 지문

- 상태: **승인됨** (아키텍트 결정 2026-10-23, 사용자 검토 대기)
- 입력: Codex 감사 2026-10-23 (§2-7, §3-4, §4-2), [S-02 보고서](../architecture/spikes/S-02-report.md) §7
- 대체: [data-flow §3.3](../architecture/02-data-flow.md) "변경된 파일은 기존 청크를 전부 삭제한 뒤 재삽입한다"
- 관련: [ADR-0004](0004-chunk-text-split-and-id.md), [T-107](../tasks/T-107-indexing-service.md)

## 맥락
기존 설계는 변경 파일의 청크를 먼저 `delete_by_paths`로 지운 뒤 청킹→임베딩→upsert 한다. 임베딩(Ollama)이나 Chroma가 중간에 실패하면 그 파일은 **검색 가능한 내용이 사라진 채로** 남는다. S-02에서 zod의 정상 파일 4개가 문법 지원 차이만으로 통째로 WINDOW가 되는 것을 보았고, ADR-0004로 chunk_id에 줄 번호가 들어가 파일을 고치면 거의 모든 ID가 바뀌므로 "같은 ID를 upsert로 덮어쓴다"는 가정도 더는 성립하지 않는다.
또 임베딩 모델이나 청킹 정책이 바뀌어도 파일 내용 해시가 같으면 증분 색인이 그 파일을 건너뛴다(차원이 같은 다른 모델이면 오류도 없다).

## 결정
1. **`VectorStore.replace_file(collection, path, chunks, embeddings)`를 포트에 추가**하고, 변경·신규 파일은 항상 이것으로 갱신한다. 계약(실패 안전성): 어느 시점에 실패해도 교체 전 청크는 계속 검색되고, `get_file_hashes`는 그 path에 대해 교체 전 해시를 주거나 path를 빼며, 새 해시는 교체가 완전히 끝난 뒤에만 보인다. 재호출은 멱등. `delete_by_paths`는 삭제된 파일 정리에만 쓴다.
2. **임베딩을 먼저, 저장소 변경은 나중에.** 서비스는 파일의 모든 청크 임베딩이 끝난 뒤에만 `replace_file`을 호출한다. 임베딩 실패는 저장소를 건드리지 않는다.
3. **Chroma 구현 전술(권고, 계약만 지키면 바뀌어도 된다):** 새 청크를 `state="staged"` 메타데이터로 먼저 쓰고(검색·`get_file_hashes`가 제외), 새 청크를 `live`로 올린 뒤 옛 `live` 청크 중 새 id에 없는 것을 지운다. 중간에 죽으면 staged 잔여물은 보이지 않고 해시가 옛 값(또는 혼재 → path 제외)이라 다음 실행이 재처리한다. 일시적으로 옛·새 청크가 함께 보일 수 있는 짧은 구간은 허용한다(빈 구간보다 낫다).
4. **색인 지문(fingerprint):** 서비스는 청크의 `content_hash`를 `sha256(file.content_hash + "\0" + embedder.model_name + "\0" + policy_version)`로 바꿔 저장하고, 증분 비교도 같은 식으로 한다. 임베딩 모델이나 청킹 정책(`CHUNK_POLICY_VERSION`)이 바뀌면 모든 파일이 자연스럽게 재색인 대상이 된다. 정책을 바꾼 PR은 이 상수를 올려야 한다.
5. **`mode=full`:** 같은 차원이면 컬렉션을 유지한 채 모든 파일을 `replace_file`로 교체하고 스캔에 없는 path를 `delete_by_paths`로 정리한다(검색 중단 없음). 차원이 다르면 같은 컬렉션에 공존할 수 없으므로 `drop_collection` 후 재생성한다 — 이 경우에만 색인 완료 전까지 검색이 비는 것을 허용한다.

## 결과
**(+)** 임베딩/저장소 장애가 있어도 기존 검색 결과가 사라지지 않는다. 재시도는 안전하다. 모델·정책 변경이 조용히 무시되지 않는다.
**(−)** 포트가 하나 늘고(`replace_file`) 어댑터(Chroma, 인메모리)가 구현해야 한다. staged 메타데이터 때문에 Chroma 쿼리 필터에 조건이 하나 붙는다. 교체 중 짧게 옛·새 청크가 함께 노출될 수 있다.
**미해결:** 파일이 많이 바뀌는 `full` 재색인 중 동시 질의의 일관성(혼재 가능), 분석 결과가 저장한 `context_chunk_ids`의 재현성(ADR-0004의 `raw_code`+`commit_sha` 저장으로 보완), 영구 심볼 identity.
