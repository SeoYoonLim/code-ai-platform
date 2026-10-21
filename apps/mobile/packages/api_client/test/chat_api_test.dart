import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for ChatApi
void main() {
  final instance = ApiClient().getChatApi();

  group(ChatApi, () {
    //Future<ChatMessagePage> listChatMessages(String sessionId, { String cursor, int limit }) async
    test('test listChatMessages', () async {
      // TODO
    });

    //Future<ChatSessionPage> listChatSessions(String projectId, { String cursor, int limit }) async
    test('test listChatSessions', () async {
      // TODO
    });

    // 끊긴 스트림 재개. `Last-Event-ID` 이후 이벤트를 버퍼에서 재전송한 뒤 실시간 스트림을 이어서 보낸다. 이미 완료된 메시지는 버퍼된 나머지 이벤트를 보내고 `done`으로 끝난다. 버퍼(5분)가 만료되면 410 stream_expired (이 경우 GET /v1/chat/sessions/{session_id}/messages 로 최종본 조회). 
    //
    //Future<ChatStreamEvent> resumeChatStream(String messageId, { String lastEventID }) async
    test('test resumeChatStream', () async {
      // TODO
    });

    // RAG 기반 코드 대화. 응답은 SSE. 이벤트 순서: `meta` → `sources` → `token`* → (`done` | `error`). 연결이 끊기면 `meta.message_id`로 `GET /v1/chat/messages/{message_id}/stream`에 재연결한다. 
    //
    //Future<ChatStreamEvent> sendChatMessage(String projectId, ChatMessageCreate chatMessageCreate) async
    test('test sendChatMessage', () async {
      // TODO
    });

  });
}
