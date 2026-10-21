import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for AnalysesApi
void main() {
  final instance = ApiClient().getAnalysesApi();

  group(AnalysesApi, () {
    // 분석 잡을 큐에 넣는다. 색인이 끝나지 않은 프로젝트는 409 index_not_ready.
    //
    //Future<Analysis> createAnalysis(AnalysisCreate analysisCreate, { String idempotencyKey }) async
    test('test createAnalysis', () async {
      // TODO
    });

    //Future<Analysis> getAnalysis(String analysisId) async
    test('test getAnalysis', () async {
      // TODO
    });

    //Future<AnalysisPage> listAnalyses({ JobStatus status, String cursor, int limit }) async
    test('test listAnalyses', () async {
      // TODO
    });

    // 완료된 분석의 고정 결과 집합이므로 offset 페이지네이션 (페이지 점프, 총 개수 표시).
    //
    //Future<FindingPage> listFindings(String analysisId, { int offset, int limit, BuiltList<Severity> severity, BuiltList<FindingCategory> category, String path, String sort }) async
    test('test listFindings', () async {
      // TODO
    });

    // 수락/거절/수정 피드백 (사용자당 1개, 덮어쓰기). 파인튜닝 데이터셋으로 재활용된다 (data-flow §5).
    //
    //Future<Finding> submitFindingFeedback(String analysisId, String findingId, FindingFeedback findingFeedback) async
    test('test submitFindingFeedback', () async {
      // TODO
    });

  });
}
