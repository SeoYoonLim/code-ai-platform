# T-005: Mobile 스캐폴딩 (Flutter)

- **담당:** Codex
- **작성:** Claude · 2026-10-21
- **상태:** ready (T-001 머지 후 착수)
- **관련 문서:** [04-mvp-roadmap.md M5](../architecture/04-mvp-roadmap.md), [contracts/events/README.md](../../contracts/events/README.md)

## 목표
`apps/mobile`에 Flutter 앱 뼈대를 만들고, 생성된 `api_client` 패키지로 Backend health를 호출한다. 딥링크 라우팅(`codeai://`)과 푸시 data 파싱의 골격을 둔다. **실제 FCM 연동(Firebase 프로젝트 설정)은 M5에서 한다.**

## 대상 파일
- `apps/mobile/**` (단, `packages/api_client/**`는 생성물이므로 수정 금지)
- `.github/workflows/ci.yml`에 `mobile` job 추가 (`subosito/flutter-action`, SHA 고정)

## 구현 명세

| 항목 | 규칙 |
|---|---|
| 생성 | `flutter create --org com.codeai --project-name codeai_mobile --platforms android,ios .` (기존 `packages/`는 보존) |
| 의존성 | `api_client: { path: packages/api_client }`, `go_router`, `dio`. 버전 고정 (`pubspec.lock` 커밋) |
| 구조 | `lib/core/{api,push,router}/`, `lib/features/{jobs,reports,health}/` (feature-first) |
| API | `lib/core/api/api.dart`: `ApiClient` 래퍼 (baseUrl은 `--dart-define=API_BASE_URL`). Problem 응답이면 `ApiProblem(code, status, retryable)` 예외 |
| 라우터 | `go_router` 경로: `/projects/:pid`, `/projects/:pid/analyses/:aid`, `/projects/:pid/refactors/:rid`, `/projects/:pid/jobs/:jid`. 아직 placeholder 화면 |
| 딥링크 | `lib/core/router/deep_link.dart`: `codeai://projects/...` → go_router 경로 변환 순수 함수. **push.v1 `deep_link` 패턴과 같은 정규식** 사용 |
| 푸시 파싱 | `lib/core/push/push_data.dart`: `Map<String, String>` → sealed class `PushEvent` (`IndexCompleted`, `AnalysisCompleted`, `RefactorCompleted`, `JobFailed`, `UnknownPush`). 문자열 숫자 파싱, 모르는 `type`/`schema_version`은 `UnknownPush` |
| 화면 | 홈: Backend health 상태 |
| Android/iOS | URL scheme `codeai` 등록 (AndroidManifest intent-filter, Info.plist CFBundleURLTypes) |

## 수락 기준
- [ ] `flutter analyze` 이슈 0, `flutter test` 통과 (`packages/api_client`는 analyze 대상에서 제외)
- [ ] `deep_link` 단위 테스트: 4가지 경로 변환 + 잘못된 링크 → `null`
- [ ] `push_data` 단위 테스트: `contracts/events/examples/push.*.json` 중 **정상 예시 2개를 fixture로 읽어** 올바른 타입으로 파싱. `push.invalid.integer-data-value.json`은 FCM이 문자열만 보내므로 테스트 대상에서 제외. 모르는 type은 `UnknownPush`
- [ ] 에뮬레이터 또는 데스크톱(`flutter run -d windows`)에서 health 화면 표시 (스크린샷을 결과에 첨부)
- [ ] CI `mobile` job green
- [ ] 파일당 300줄 이하

## 금지 사항
- `packages/api_client/**` 수정 금지 (`make gen-dart`로만 생성)
- Firebase 설정 파일(`google-services.json`, `GoogleService-Info.plist`) 커밋 금지
- 상태관리 라이브러리(riverpod, bloc 등) 도입은 M5에서 결정한다. 이 카드에서는 `StatefulWidget`만 쓴다

## 참고
- 이 개발 PC에는 Flutter SDK가 없다. 설치: `winget install Google.Flutter` 또는 공식 가이드. Android SDK도 필요하다

## 결과
<Codex 기록>
