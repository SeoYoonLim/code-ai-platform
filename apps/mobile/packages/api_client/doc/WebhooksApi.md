# api_client.api.WebhooksApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**githubWebhook**](WebhooksApi.md#githubwebhook) | **POST** /v1/webhooks/github | 


# **githubWebhook**
> WebhookAck githubWebhook(xGitHubEvent, xGitHubDelivery, xHubSignature256, body)



GitHub 웹훅 수신. 페이로드 스키마와 처리 규칙은 contracts/events/github-webhook.v1.schema.json. 1) X-Hub-Signature-256 HMAC 검증 (상수 시간 비교) → 실패 401 2) X-GitHub-Delivery 중복 제거 (24h) → 중복이면 202 duplicate 3) push + 기본 브랜치 + deleted=false 일 때만 증분 색인 잡 → 202 queued, 그 외 202 ignored GitHub 재전송 폭주를 막기 위해 처리 불가 이벤트도 4xx가 아닌 202 ignored로 응답한다. 

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getWebhooksApi();
final String xGitHubEvent = xGitHubEvent_example; // String | 
final String xGitHubDelivery = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xHubSignature256 = xHubSignature256_example; // String | 
final JsonObject body = Object; // JsonObject | 

try {
    final response = api.githubWebhook(xGitHubEvent, xGitHubDelivery, xHubSignature256, body);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WebhooksApi->githubWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xGitHubEvent** | **String**|  | 
 **xGitHubDelivery** | **String**|  | 
 **xHubSignature256** | **String**|  | 
 **body** | **JsonObject**|  | 

### Return type

[**WebhookAck**](WebhookAck.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

