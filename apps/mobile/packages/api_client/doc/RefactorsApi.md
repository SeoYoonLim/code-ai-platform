# api_client.api.RefactorsApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createRefactor**](RefactorsApi.md#createrefactor) | **POST** /v1/projects/{project_id}/refactors | 
[**getRefactor**](RefactorsApi.md#getrefactor) | **GET** /v1/refactors/{refactor_id} | 
[**refactorFinding**](RefactorsApi.md#refactorfinding) | **POST** /v1/analyses/{analysis_id}/findings/{finding_id}/refactor | 


# **createRefactor**
> Refactor createRefactor(projectId, refactorCreate, idempotencyKey)



자유 지시 기반 리팩터링 (Finding 없이).

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getRefactorsApi();
final String projectId = projectId_example; // String | 
final RefactorCreate refactorCreate = ; // RefactorCreate | 
final String idempotencyKey = idempotencyKey_example; // String | 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused.

try {
    final response = api.createRefactor(projectId, refactorCreate, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RefactorsApi->createRefactor: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **refactorCreate** | [**RefactorCreate**](RefactorCreate.md)|  | 
 **idempotencyKey** | **String**| 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused. | [optional] 

### Return type

[**Refactor**](Refactor.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRefactor**
> Refactor getRefactor(refactorId)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getRefactorsApi();
final String refactorId = refactorId_example; // String | 

try {
    final response = api.getRefactor(refactorId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RefactorsApi->getRefactor: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refactorId** | **String**|  | 

### Return type

[**Refactor**](Refactor.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refactorFinding**
> Refactor refactorFinding(analysisId, findingId, idempotencyKey, refactorFindingRequest)



Finding을 근거로 리팩터링 패치 생성 잡을 큐에 넣는다.

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getRefactorsApi();
final String analysisId = analysisId_example; // String | 
final String findingId = findingId_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused.
final RefactorFindingRequest refactorFindingRequest = ; // RefactorFindingRequest | 

try {
    final response = api.refactorFinding(analysisId, findingId, idempotencyKey, refactorFindingRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RefactorsApi->refactorFinding: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analysisId** | **String**|  | 
 **findingId** | **String**|  | 
 **idempotencyKey** | **String**| 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused. | [optional] 
 **refactorFindingRequest** | [**RefactorFindingRequest**](RefactorFindingRequest.md)|  | [optional] 

### Return type

[**Refactor**](Refactor.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

