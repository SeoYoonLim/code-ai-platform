import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for WebhooksApi
void main() {
  final instance = ApiClient().getWebhooksApi();

  group(WebhooksApi, () {
    // GitHub 웹훅 수신. 페이로드 스키마와 처리 규칙은 contracts/events/github-webhook.v1.schema.json. 1) X-Hub-Signature-256 HMAC 검증 (상수 시간 비교) → 실패 401 2) X-GitHub-Delivery 중복 제거 (24h) → 중복이면 202 duplicate 3) push + 기본 브랜치 + deleted=false 일 때만 증분 색인 잡 → 202 queued, 그 외 202 ignored GitHub 재전송 폭주를 막기 위해 처리 불가 이벤트도 4xx가 아닌 202 ignored로 응답한다. 
    //
    //Future<WebhookAck> githubWebhook(String xGitHubEvent, String xGitHubDelivery, String xHubSignature256, JsonObject body) async
    test('test githubWebhook', () async {
      // TODO
    });

  });
}
