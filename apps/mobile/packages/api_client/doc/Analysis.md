# api_client.model.Analysis

## Load the model package
```dart
import 'package:api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**projectId** | **String** |  | 
**jobId** | **String** |  | 
**status** | [**JobStatus**](JobStatus.md) |  | 
**paths** | **BuiltList&lt;String&gt;** |  | 
**instruction** | **String** |  | [optional] 
**commitSha** | **String** |  | [optional] 
**summary** | **String** |  | [optional] 
**findingCounts** | [**FindingCounts**](FindingCounts.md) |  | [optional] 
**model** | **String** |  | [optional] 
**adapter** | **String** |  | [optional] 
**error** | [**Problem**](Problem.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**completedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


