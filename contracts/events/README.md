# contracts/events

| 스키마 | 방향 | 용도 |
|---|---|---|
| [push.v1.schema.json](push.v1.schema.json) | Backend → FCM → Flutter | 잡 완료·실패 푸시 |
| [github-webhook.v1.schema.json](github-webhook.v1.schema.json) | GitHub → Backend | push 시 증분 색인 트리거 |

예시 페이로드는 [examples/](examples/)에 있으며 `packages/py-common/tests/test_contracts.py`가 스키마 적합성을 검증한다.
파일 이름 규칙: `<schema 접두사>.<설명>.json`. `.invalid.` 이 들어간 파일은 **검증에 실패해야 하는** 반례다.

## 푸시 전송 규칙 (`push.v1`)

1. **발송 시점:** 잡이 종료 상태(`succeeded`, `failed`)로 바뀐 직후 1회 보낸다. `canceled`는 보내지 않는다.
2. **수신 대상:** 프로젝트 소유자의 등록된 모든 기기 (`POST /v1/devices`).
3. **우선순위:** `*.failed`는 `high`/`apns-priority: 10`, 나머지는 `normal`/`5`.
4. **collapse:** `collapse_key`와 `apns-collapse-id`에 `job_id`를 넣어, 같은 잡의 알림은 마지막 것만 표시한다.
5. **토큰 정리:** FCM이 `UNREGISTERED`나 `INVALID_ARGUMENT(token)`를 반환하면 해당 device를 삭제한다.
6. **재시도:** FCM 5xx 또는 429 응답이면 최대 3회 지수 백오프(1s, 4s, 16s)로 재시도한다. 그래도 실패하면 로그만 남긴다. 푸시는 best-effort이며 앱은 `GET /v1/jobs`로 상태를 맞춘다.
7. **앱 처리:** `event_id`로 중복 표시를 막고, `deep_link`로 화면을 이동한다. 모르는 `type`이나 `schema_version`은 무시한다 (상위 호환).

| type | 앱 화면 (deep_link) | notification 예 |
|---|---|---|
| `index.completed` | `codeai://projects/{pid}` | "my-app 색인 완료 · 파일 12개 변경" |
| `analysis.completed` | `codeai://projects/{pid}/analyses/{aid}` | "분석 완료 · critical 1, major 3" |
| `refactor.completed` | `codeai://projects/{pid}/refactors/{rid}` | "리팩터링 패치 준비됨" |
| `*.failed` | `codeai://projects/{pid}/jobs/{jid}` | "분석 실패 · engine_unavailable" |

## GitHub 웹훅 처리 규칙 (`github-webhook.v1`)

```
수신 → ① 서명 검증 → ② 중복 제거 → ③ 이벤트 분기 → ④ 프로젝트 매칭 → ⑤ 브랜치 필터 → ⑥ 잡 큐잉 → 202
```

| 단계 | 규칙 | 실패 시 응답 |
|---|---|---|
| ① 서명 | `HMAC-SHA256(secret, raw_body)`와 `X-Hub-Signature-256`을 `hmac.compare_digest`로 비교. **파싱 전 raw body**를 사용 | 401 `webhook_signature_invalid` |
| ② 중복 | `X-GitHub-Delivery`를 Redis `SET NX EX 86400` | 202 `duplicate` |
| ③ 이벤트 | `push`, `ping`만 처리 | 202 `ignored` / `unsupported_event` (`ping` → `ping`) |
| ④ 매칭 | `repository.id`로 프로젝트 조회, 없으면 `clone_url`로 조회 | 202 `ignored` / `unknown_repository` |
| ⑤ 필터 | `refs/tags/*` → `tag_push`, `deleted=true` → `branch_deleted`, 기본 브랜치가 아니면 → `non_default_branch` | 202 `ignored` |
| ⑥ 잡 | `git fetch` 후 `after` SHA로 색인. `forced=true`면 `mode=full`, 아니면 `incremental`. 이미 실행 중인 색인 잡이 있으면 새 잡을 만들지 않고 해당 잡이 끝난 뒤 1회 재실행하도록 표시 | 202 `queued` |

- 처리 불가 이벤트도 4xx 대신 202로 응답한다. GitHub는 실패한 웹훅을 수동 재전송 대상으로 표시하는데, 이를 의도된 무시와 구분하기 위해서다.
- 응답은 10초 안에 해야 한다 (GitHub 타임아웃). clone이나 fetch는 워커에서 수행한다.
