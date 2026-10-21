# api_client.api.ProjectsApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createProject**](ProjectsApi.md#createproject) | **POST** /v1/projects | 
[**deleteProject**](ProjectsApi.md#deleteproject) | **DELETE** /v1/projects/{project_id} | 
[**getProject**](ProjectsApi.md#getproject) | **GET** /v1/projects/{project_id} | 
[**listProjects**](ProjectsApi.md#listprojects) | **GET** /v1/projects | 
[**reindexProject**](ProjectsApi.md#reindexproject) | **POST** /v1/projects/{project_id}/reindex | 
[**updateProject**](ProjectsApi.md#updateproject) | **PATCH** /v1/projects/{project_id} | 


# **createProject**
> ProjectCreated createProject(projectCreate, idempotencyKey)



저장소를 clone하고 최초 full 색인 잡을 큐에 넣는다. 응답의 index_job으로 진행 상황을 추적한다.

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getProjectsApi();
final ProjectCreate projectCreate = ; // ProjectCreate | 
final String idempotencyKey = idempotencyKey_example; // String | 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused.

try {
    final response = api.createProject(projectCreate, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->createProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectCreate** | [**ProjectCreate**](ProjectCreate.md)|  | 
 **idempotencyKey** | **String**| 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused. | [optional] 

### Return type

[**ProjectCreated**](ProjectCreated.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteProject**
> deleteProject(projectId)



프로젝트, 체크아웃, 벡터 컬렉션, 분석 기록을 모두 삭제한다. 실행 중 잡은 취소된다.

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getProjectsApi();
final String projectId = projectId_example; // String | 

try {
    api.deleteProject(projectId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->deleteProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getProject**
> Project getProject(projectId)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getProjectsApi();
final String projectId = projectId_example; // String | 

try {
    final response = api.getProject(projectId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->getProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

[**Project**](Project.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listProjects**
> ProjectPage listProjects(cursor, limit, q, sort)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getProjectsApi();
final String cursor = cursor_example; // String | 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효.
final int limit = 56; // int | 
final String q = q_example; // String | 이름 부분 일치 검색
final String sort = sort_example; // String | 

try {
    final response = api.listProjects(cursor, limit, q, sort);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->listProjects: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**| 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효. | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **q** | **String**| 이름 부분 일치 검색 | [optional] 
 **sort** | **String**|  | [optional] [default to '-created_at']

### Return type

[**ProjectPage**](ProjectPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reindexProject**
> Job reindexProject(projectId, idempotencyKey, reindexRequest)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getProjectsApi();
final String projectId = projectId_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused.
final ReindexRequest reindexRequest = ; // ReindexRequest | 

try {
    final response = api.reindexProject(projectId, idempotencyKey, reindexRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->reindexProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **idempotencyKey** | **String**| 24시간 유효. 같은 키 + 같은 본문 → 최초 응답 재반환. 같은 키 + 다른 본문 → 422 idempotency_key_reused. | [optional] 
 **reindexRequest** | [**ReindexRequest**](ReindexRequest.md)|  | [optional] 

### Return type

[**Job**](Job.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProject**
> Project updateProject(projectId, projectUpdate)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getProjectsApi();
final String projectId = projectId_example; // String | 
final ProjectUpdate projectUpdate = ; // ProjectUpdate | 

try {
    final response = api.updateProject(projectId, projectUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->updateProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **projectUpdate** | [**ProjectUpdate**](ProjectUpdate.md)|  | 

### Return type

[**Project**](Project.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

