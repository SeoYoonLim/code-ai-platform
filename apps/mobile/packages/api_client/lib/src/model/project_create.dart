//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'project_create.g.dart';

/// ProjectCreate
///
/// Properties:
/// * [name] 
/// * [repoUrl] - https:// git clone URL 또는 개발용 file:// 로컬 경로
/// * [defaultBranch] 
/// * [includeGlobs] 
/// * [excludeGlobs] 
@BuiltValue()
abstract class ProjectCreate implements Built<ProjectCreate, ProjectCreateBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  /// https:// git clone URL 또는 개발용 file:// 로컬 경로
  @BuiltValueField(wireName: r'repo_url')
  String get repoUrl;

  @BuiltValueField(wireName: r'default_branch')
  String? get defaultBranch;

  @BuiltValueField(wireName: r'include_globs')
  BuiltList<String>? get includeGlobs;

  @BuiltValueField(wireName: r'exclude_globs')
  BuiltList<String>? get excludeGlobs;

  ProjectCreate._();

  factory ProjectCreate([void updates(ProjectCreateBuilder b)]) = _$ProjectCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProjectCreateBuilder b) => b
      ..defaultBranch = 'main'
      ..includeGlobs = ListBuilder()
      ..excludeGlobs = ListBuilder();

  @BuiltValueSerializer(custom: true)
  static Serializer<ProjectCreate> get serializer => _$ProjectCreateSerializer();
}

class _$ProjectCreateSerializer implements PrimitiveSerializer<ProjectCreate> {
  @override
  final Iterable<Type> types = const [ProjectCreate, _$ProjectCreate];

  @override
  final String wireName = r'ProjectCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProjectCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'repo_url';
    yield serializers.serialize(
      object.repoUrl,
      specifiedType: const FullType(String),
    );
    if (object.defaultBranch != null) {
      yield r'default_branch';
      yield serializers.serialize(
        object.defaultBranch,
        specifiedType: const FullType(String),
      );
    }
    if (object.includeGlobs != null) {
      yield r'include_globs';
      yield serializers.serialize(
        object.includeGlobs,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
    if (object.excludeGlobs != null) {
      yield r'exclude_globs';
      yield serializers.serialize(
        object.excludeGlobs,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProjectCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProjectCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'repo_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.repoUrl = valueDes;
          break;
        case r'default_branch':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.defaultBranch = valueDes;
          break;
        case r'include_globs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.includeGlobs.replace(valueDes);
          break;
        case r'exclude_globs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.excludeGlobs.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProjectCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProjectCreateBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

