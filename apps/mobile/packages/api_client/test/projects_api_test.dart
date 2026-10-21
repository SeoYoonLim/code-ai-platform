import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for ProjectsApi
void main() {
  final instance = ApiClient().getProjectsApi();

  group(ProjectsApi, () {
    // 저장소를 clone하고 최초 full 색인 잡을 큐에 넣는다. 응답의 index_job으로 진행 상황을 추적한다.
    //
    //Future<ProjectCreated> createProject(ProjectCreate projectCreate, { String idempotencyKey }) async
    test('test createProject', () async {
      // TODO
    });

    // 프로젝트, 체크아웃, 벡터 컬렉션, 분석 기록을 모두 삭제한다. 실행 중 잡은 취소된다.
    //
    //Future deleteProject(String projectId) async
    test('test deleteProject', () async {
      // TODO
    });

    //Future<Project> getProject(String projectId) async
    test('test getProject', () async {
      // TODO
    });

    //Future<ProjectPage> listProjects({ String cursor, int limit, String q, String sort }) async
    test('test listProjects', () async {
      // TODO
    });

    //Future<Job> reindexProject(String projectId, { String idempotencyKey, ReindexRequest reindexRequest }) async
    test('test reindexProject', () async {
      // TODO
    });

    //Future<Project> updateProject(String projectId, ProjectUpdate projectUpdate) async
    test('test updateProject', () async {
      // TODO
    });

  });
}
