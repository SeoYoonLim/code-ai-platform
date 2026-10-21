import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for DevicesApi
void main() {
  final instance = ApiClient().getDevicesApi();

  group(DevicesApi, () {
    // Flutter 앱의 FCM 토큰 등록 (fcm_token 기준 upsert).
    //
    //Future<Device> registerDevice(DeviceRegister deviceRegister) async
    test('test registerDevice', () async {
      // TODO
    });

    //Future unregisterDevice(String deviceId) async
    test('test unregisterDevice', () async {
      // TODO
    });

  });
}
