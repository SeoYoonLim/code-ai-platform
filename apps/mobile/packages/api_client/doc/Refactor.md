# api_client.model.Refactor

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
**target** | [**CodeTarget**](CodeTarget.md) |  | 
**instruction** | **String** |  | 
**analysisId** | **String** |  | [optional] 
**findingId** | **String** |  | [optional] 
**diff** | **String** | unified diff (완료 시) | [optional] 
**explanation** | **String** |  | [optional] 
**validation** | [**PatchValidation**](PatchValidation.md) |  | [optional] 
**model** | **String** |  | [optional] 
**adapter** | **String** |  | [optional] 
**error** | [**Problem**](Problem.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**completedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


