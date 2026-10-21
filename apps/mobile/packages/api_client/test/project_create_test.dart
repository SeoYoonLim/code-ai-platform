import 'package:test/test.dart';
import 'package:api_client/api_client.dart';

// tests for ProjectCreate
void main() {
  final instance = ProjectCreateBuilder();
  // TODO add properties to the builder and call build()

  group(ProjectCreate, () {
    // String name
    test('to test the property `name`', () async {
      // TODO
    });

    // https:// git clone URL 또는 개발용 file:// 로컬 경로
    // String repoUrl
    test('to test the property `repoUrl`', () async {
      // TODO
    });

    // String defaultBranch (default value: 'main')
    test('to test the property `defaultBranch`', () async {
      // TODO
    });

    // BuiltList<String> includeGlobs (default value: ListBuilder())
    test('to test the property `includeGlobs`', () async {
      // TODO
    });

    // BuiltList<String> excludeGlobs (default value: ListBuilder())
    test('to test the property `excludeGlobs`', () async {
      // TODO
    });

  });
}
