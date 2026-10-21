# api_client.model.ChatStreamEvent

## Load the model package
```dart
import 'package:api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**event** | **String** |  | 
**streamId** | **String** |  | 
**sessionId** | **String** |  | 
**messageId** | **String** | assistant 메시지 ID (재연결 키) | 
**model** | **String** |  | 
**adapter** | **String** |  | [optional] 
**sources** | [**BuiltList&lt;ChatSource&gt;**](ChatSource.md) |  | 
**index** | **int** |  | 
**delta** | **String** |  | 
**finishReason** | **String** |  | 
**usage** | [**TokenUsage**](TokenUsage.md) |  | 
**error** | [**Problem**](Problem.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


