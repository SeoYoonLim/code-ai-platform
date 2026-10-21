# api_client.api.DevicesApi

## Load the API package
```dart
import 'package:api_client/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**registerDevice**](DevicesApi.md#registerdevice) | **POST** /v1/devices | 
[**unregisterDevice**](DevicesApi.md#unregisterdevice) | **DELETE** /v1/devices/{device_id} | 


# **registerDevice**
> Device registerDevice(deviceRegister)



Flutter 앱의 FCM 토큰 등록 (fcm_token 기준 upsert).

### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getDevicesApi();
final DeviceRegister deviceRegister = ; // DeviceRegister | 

try {
    final response = api.registerDevice(deviceRegister);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->registerDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceRegister** | [**DeviceRegister**](DeviceRegister.md)|  | 

### Return type

[**Device**](Device.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unregisterDevice**
> unregisterDevice(deviceId)



### Example
```dart
import 'package:api_client/api.dart';

final api = ApiClient().getDevicesApi();
final String deviceId = deviceId_example; // String | 

try {
    api.unregisterDevice(deviceId);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->unregisterDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

