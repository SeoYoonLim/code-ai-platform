# api_client.model.Job

## Load the model package
```dart
import 'package:api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**kind** | [**JobKind**](JobKind.md) |  | 
**status** | [**JobStatus**](JobStatus.md) |  | 
**projectId** | **String** |  | 
**resourceId** | **String** | kind=analysis → analysis_id, kind=refactor → refactor_id, kind=index → null | [optional] 
**trigger** | **String** |  | [optional] [default to 'manual']
**progress** | [**JobProgress**](JobProgress.md) |  | [optional] 
**error** | [**Problem**](Problem.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**startedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**finishedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


