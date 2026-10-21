# api_client.api.AnalysesApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createAnalysis**](AnalysesApi.md#createanalysis) | **POST** /v1/projects/{project_id}/analyses | 
[**getAnalysis**](AnalysesApi.md#getanalysis) | **GET** /v1/analyses/{analysis_id} | 
[**listAnalyses**](AnalysesApi.md#listanalyses) | **GET** /v1/projects/{project_id}/analyses | 
[**listFindings**](AnalysesApi.md#listfindings) | **GET** /v1/analyses/{analysis_id}/findings | 
[**submitFindingFeedback**](AnalysesApi.md#submitfindingfeedback) | **PUT** /v1/analyses/{analysis_id}/findings/{finding_id}/feedback | 


# **createAnalysis**
> Analysis createAnalysis(analysisCreate, idempotencyKey)



분석 잡을 큐에 넣는다. 색인이 끝나지 않은 프로젝트는 409 index_not_ready.

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getAnalysesApi();
final AnalysisCreate analysisCreate = ; // AnalysisCreate | 
final String idempotencyKey = idempotencyKey_example; // String | 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused.

try {
    final response = api.createAnalysis(analysisCreate, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AnalysesApi->createAnalysis: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analysisCreate** | [**AnalysisCreate**](AnalysisCreate.md)|  | 
 **idempotencyKey** | **String**| 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused. | [optional] 

### Return type

[**Analysis**](Analysis.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAnalysis**
> Analysis getAnalysis(analysisId)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getAnalysesApi();
final String analysisId = analysisId_example; // String | 

try {
    final response = api.getAnalysis(analysisId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AnalysesApi->getAnalysis: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analysisId** | **String**|  | 

### Return type

[**Analysis**](Analysis.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAnalyses**
> AnalysisPage listAnalyses(status, cursor, limit)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getAnalysesApi();
final JobStatus status = ; // JobStatus | 
final String cursor = cursor_example; // String | 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효.
final int limit = 56; // int | 

try {
    final response = api.listAnalyses(status, cursor, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AnalysesApi->listAnalyses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | [**JobStatus**](.md)|  | [optional] 
 **cursor** | **String**| 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효. | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**AnalysisPage**](AnalysisPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFindings**
> FindingPage listFindings(analysisId, offset, limit, severity, category, path, sort)



완료된 분석의 고정 결과 집합이므로 offset 페이지네이션 (페이지 점프, 총 개수 표시).

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getAnalysesApi();
final String analysisId = analysisId_example; // String | 
final int offset = 56; // int | 
final int limit = 56; // int | 
final BuiltList<Severity> severity = ; // BuiltList<Severity> | 쉼표 구분 다중 선택 (예 major,critical)
final BuiltList<FindingCategory> category = ; // BuiltList<FindingCategory> | 
final String path = path_example; // String | 경로 prefix 필터
final String sort = sort_example; // String | 

try {
    final response = api.listFindings(analysisId, offset, limit, severity, category, path, sort);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AnalysesApi->listFindings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analysisId** | **String**|  | 
 **offset** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 20]
 **severity** | [**BuiltList&lt;Severity&gt;**](Severity.md)| 쉼표 구분 다중 선택 (예 major,critical) | [optional] 
 **category** | [**BuiltList&lt;FindingCategory&gt;**](FindingCategory.md)|  | [optional] 
 **path** | **String**| 경로 prefix 필터 | [optional] 
 **sort** | **String**|  | [optional] [default to '-severity']

### Return type

[**FindingPage**](FindingPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitFindingFeedback**
> Finding submitFindingFeedback(analysisId, findingId, findingFeedback)



수락/거절/수정 피드백 (사용자당 1개, 덮어쓰기). 파인튜닝 데이터셋으로 재활용된다 (data-flow §5).

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getAnalysesApi();
final String analysisId = analysisId_example; // String | 
final String findingId = findingId_example; // String | 
final FindingFeedback findingFeedback = ; // FindingFeedback | 

try {
    final response = api.submitFindingFeedback(analysisId, findingId, findingFeedback);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AnalysesApi->submitFindingFeedback: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analysisId** | **String**|  | 
 **findingId** | **String**|  | 
 **findingFeedback** | [**FindingFeedback**](FindingFeedback.md)|  | 

### Return type

[**Finding**](Finding.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

