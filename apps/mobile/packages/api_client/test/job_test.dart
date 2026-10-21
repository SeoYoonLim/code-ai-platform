import 'package:test/test.dart';
import 'package:api_client/api_client.dart';

// tests for Job
void main() {
  final instance = JobBuilder();
  // TODO add properties to the builder and call build()

  group(Job, () {
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // JobKind kind
    test('to test the property `kind`', () async {
      // TODO
    });

    // JobStatus status
    test('to test the property `status`', () async {
      // TODO
    });

    // String projectId
    test('to test the property `projectId`', () async {
      // TODO
    });

    // kind=analysis → analysis_id, kind=refactor → refactor_id, kind=index → null
    // String resourceId
    test('to test the property `resourceId`', () async {
      // TODO
    });

    // String trigger (default value: 'manual')
    test('to test the property `trigger`', () async {
      // TODO
    });

    // JobProgress progress
    test('to test the property `progress`', () async {
      // TODO
    });

    // Problem error
    test('to test the property `error`', () async {
      // TODO
    });

    // DateTime createdAt
    test('to test the property `createdAt`', () async {
      // TODO
    });

    // DateTime startedAt
    test('to test the property `startedAt`', () async {
      // TODO
    });

    // DateTime finishedAt
    test('to test the property `finishedAt`', () async {
      // TODO
    });

  });
}
