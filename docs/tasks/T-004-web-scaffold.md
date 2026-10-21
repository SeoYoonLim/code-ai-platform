# T-004: Web 스캐폴딩 (Next.js)

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-001 머지 후 착수)
- **관련 문서:** [04-mvp-roadmap.md M4](../architecture/04-mvp-roadmap.md), [backend.v1.yaml](../../contracts/openapi/backend.v1.yaml)

## 목표
`apps/web`에 Next.js(App Router, TypeScript strict) 앱을 만들고, **생성된 `schema.d.ts` 기반의 타입 안전 API 클라이언트**로 Backend `/v1/health`를 호출하는 화면까지 연결한다.

## 대상 파일
- `apps/web/**` (단, `src/lib/api/schema.d.ts`는 생성물이므로 수정 금지)
- `.github/workflows/ci.yml`에 `web` job 추가
- `Makefile`: `dev-web`, `test-web`은 이미 있다. `lint-web`을 추가하고 `check`에 넣지는 않는다 (Python 환경과 분리)

## 구현 명세

| 항목 | 규칙 |
|---|---|
| 생성 | `create-next-app` 최신 안정 버전 (`--ts --app --src-dir --eslint --no-tailwind --import-alias "@/*"`). 디렉터리가 비어 있지 않으므로 임시 폴더에 생성한 뒤 옮기고, **기존 `src/lib/api/schema.d.ts`는 보존**한다 |
| 버전 | `package.json`의 의존성은 **exact 버전** (`^` 금지), `package-lock.json` 커밋, `engines.node >= 22` |
| tsconfig | `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes` |
| API 클라이언트 | `openapi-fetch` + `schema.d.ts` → `src/lib/api/client.ts` (baseUrl = `NEXT_PUBLIC_API_BASE_URL`) |
| 에러 처리 | `src/lib/api/problem.ts`: 응답이 `application/problem+json`이면 `ApiProblem` 에러(`code`, `status`, `retryable`, `requestId`)를 던진다. `isProblem(code)` 타입 가드 제공 |
| i18n 메시지 | `src/lib/api/error-messages.ts`: `components["schemas"]["ErrorCode"]` 전 코드 → 한국어 문구. **`Record<ErrorCode, string>`으로 타입을 강제**해서 코드가 추가되면 컴파일 에러가 나게 한다 |
| 화면 | `/` 페이지: Backend health 상태 카드 (`ok`/`degraded`/`down`, engine 상태 포함) |
| 테스트 | Vitest + Testing Library: problem 파싱, error-messages 완전성, health 카드 렌더 |
| 디렉터리 | `src/app/`, `src/features/`, `src/components/ui/`, `src/lib/` (CLAUDE.md 구조) |

## 수락 기준
- [ ] `npm ci && npm run lint && npm run typecheck && npm test && npm run build` 전부 통과 (`typecheck` = `tsc --noEmit`)
- [ ] `make dev-backend` + `npm run dev` 상태에서 `/`에 health 상태 표시. Backend를 끄면 에러 상태 표시
- [ ] ErrorCode에 임의 코드를 추가하고 `make gen-ts`를 실행하면 `error-messages.ts`에서 타입 에러가 남 (확인 후 되돌리고 결과에 기록)
- [ ] `any` 사용 0 (`@typescript-eslint/no-explicit-any: error`)
- [ ] CI `web` job green (Node 22, npm cache)
- [ ] 파일당 300줄 이하

## 금지 사항
- `src/lib/api/schema.d.ts` 수정 금지 (`make gen-ts`로만 생성)
- API 타입을 직접 선언하지 않는다. 모든 요청/응답 타입은 `schema.d.ts`에서 가져온다
- UI 라이브러리를 대량으로 도입하지 않는다 (디자인 시스템은 M4에서 결정)

## 결과
<Codex 기록>
