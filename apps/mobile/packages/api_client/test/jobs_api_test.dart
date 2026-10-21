import 'package:test/test.dart';
import 'package:api_client/api_client.dart';


/// tests for JobsApi
void main() {
  final instance = ApiClient().getJobsApi();

  group(JobsApi, () {
    // 멱등. 이미 종료된 잡은 현재 상태를 그대로 반환한다.
    //
    //Future<Job> cancelJob(String jobId) async
    test('test cancelJob', () async {
      // TODO
    });

    //Future<Job> getJob(String jobId) async
    test('test getJob', () async {
      // TODO
    });

    //Future<JobPage> listJobs({ String projectId, JobKind kind, JobStatus status, String cursor, int limit }) async
    test('test listJobs', () async {
      // TODO
    });

  });
}
