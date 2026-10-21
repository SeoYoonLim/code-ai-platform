# api_client.api.ChatApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listChatMessages**](ChatApi.md#listchatmessages) | **GET** /v1/chat/sessions/{session_id}/messages | 
[**listChatSessions**](ChatApi.md#listchatsessions) | **GET** /v1/projects/{project_id}/chat/sessions | 
[**resumeChatStream**](ChatApi.md#resumechatstream) | **GET** /v1/chat/messages/{message_id}/stream | 
[**sendChatMessage**](ChatApi.md#sendchatmessage) | **POST** /v1/projects/{project_id}/chat/messages | 


# **listChatMessages**
> ChatMessagePage listChatMessages(sessionId, cursor, limit)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getChatApi();
final String sessionId = sessionId_example; // String | 
final String cursor = cursor_example; // String | 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효.
final int limit = 56; // int | 

try {
    final response = api.listChatMessages(sessionId, cursor, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ChatApi->listChatMessages: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sessionId** | **String**|  | 
 **cursor** | **String**| 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효. | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ChatMessagePage**](ChatMessagePage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listChatSessions**
> ChatSessionPage listChatSessions(projectId, cursor, limit)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getChatApi();
final String projectId = projectId_example; // String | 
final String cursor = cursor_example; // String | 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효.
final int limit = 56; // int | 

try {
    final response = api.listChatSessions(projectId, cursor, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ChatApi->listChatSessions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **cursor** | **String**| 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효. | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ChatSessionPage**](ChatSessionPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resumeChatStream**
> ChatStreamEvent resumeChatStream(messageId, lastEventID)



끊긴 스트림 재개. `Last-Event-ID` 이후 이벤트를 버퍼에서 재전송한 뒤 실시간 스트림을 이어서 보낸다. 이미 완료된 메시지는 버퍼된 나머지 이벤트를 보내고 `done`으로 끝난다. 버퍼(5분)가 만료되면 410 stream_expired (이 경우 GET /v1/chat/sessions/{session_id}/messages 로 최종본 조회). 

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getChatApi();
final String messageId = messageId_example; // String | 
final String lastEventID = lastEventID_example; // String | 마지막으로 받은 이벤트 id ({stream_id}:{seq}). 생략 시 처음부터.

try {
    final response = api.resumeChatStream(messageId, lastEventID);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ChatApi->resumeChatStream: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **String**|  | 
 **lastEventID** | **String**| 마지막으로 받은 이벤트 id ({stream_id}:{seq}). 생략 시 처음부터. | [optional] 

### Return type

[**ChatStreamEvent**](ChatStreamEvent.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/event-stream, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendChatMessage**
> ChatStreamEvent sendChatMessage(projectId, chatMessageCreate)



RAG 기반 코드 대화. 응답은 SSE. 이벤트 순서: `meta` → `sources` → `token`* → (`done` | `error`). 연결이 끊기면 `meta.message_id`로 `GET /v1/chat/messages/{message_id}/stream`에 재연결한다. 

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getChatApi();
final String projectId = projectId_example; // String | 
final ChatMessageCreate chatMessageCreate = ; // ChatMessageCreate | 

try {
    final response = api.sendChatMessage(projectId, chatMessageCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ChatApi->sendChatMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **chatMessageCreate** | [**ChatMessageCreate**](ChatMessageCreate.md)|  | 

### Return type

[**ChatStreamEvent**](ChatStreamEvent.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: text/event-stream, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

