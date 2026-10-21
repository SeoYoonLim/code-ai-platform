import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for RefactorsApi
void main() {
  final instance = ApiClient().getRefactorsApi();

  group(RefactorsApi, () {
    // 자유 지시 기반 리팩터링 (Finding 없이).
    //
    //Future<Refactor> createRefactor(String projectId, RefactorCreate refactorCreate, { String idempotencyKey }) async
    test('test createRefactor', () async {
      // TODO
    });

    //Future<Refactor> getRefactor(String refactorId) async
    test('test getRefactor', () async {
      // TODO
    });

    // Finding을 근거로 리팩터링 패치 생성 잡을 큐에 넣는다.
    //
    //Future<Refactor> refactorFinding(String analysisId, String findingId, { String idempotencyKey, RefactorFindingRequest refactorFindingRequest }) async
    test('test refactorFinding', () async {
      // TODO
    });

  });
}
