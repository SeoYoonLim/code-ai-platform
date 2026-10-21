# api_client.api.JobsApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cancelJob**](JobsApi.md#canceljob) | **POST** /v1/jobs/{job_id}/cancel | 
[**getJob**](JobsApi.md#getjob) | **GET** /v1/jobs/{job_id} | 
[**listJobs**](JobsApi.md#listjobs) | **GET** /v1/jobs | 


# **cancelJob**
> Job cancelJob(jobId)



멱등. 이미 종료된 잡은 현재 상태를 그대로 반환한다.

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getJobsApi();
final String jobId = jobId_example; // String | 

try {
    final response = api.cancelJob(jobId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JobsApi->cancelJob: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **jobId** | **String**|  | 

### Return type

[**Job**](Job.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getJob**
> Job getJob(jobId)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getJobsApi();
final String jobId = jobId_example; // String | 

try {
    final response = api.getJob(jobId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JobsApi->getJob: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **jobId** | **String**|  | 

### Return type

[**Job**](Job.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listJobs**
> JobPage listJobs(projectId, kind, status, cursor, limit)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getJobsApi();
final String projectId = projectId_example; // String | 
final JobKind kind = ; // JobKind | 
final JobStatus status = ; // JobStatus | 
final String cursor = cursor_example; // String | 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효.
final int limit = 56; // int | 

try {
    final response = api.listJobs(projectId, kind, status, cursor, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JobsApi->listJobs: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | [optional] 
 **kind** | [**JobKind**](.md)|  | [optional] 
 **status** | [**JobStatus**](.md)|  | [optional] 
 **cursor** | **String**| 이전 응답의 page.next_cursor (opaque, base64url). 생략 시 첫 페이지. 정렬/필터를 바꾸면 무효. | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**JobPage**](JobPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

