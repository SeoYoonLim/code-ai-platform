import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for SystemApi
void main() {
  final instance = ApiClient().getSystemApi();

  group(SystemApi, () {
    //Future<HealthResponse> getHealth() async
    test('test getHealth', () async {
      // TODO
    });

  });
}
