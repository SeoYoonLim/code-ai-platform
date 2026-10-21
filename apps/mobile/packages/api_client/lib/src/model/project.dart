//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/index_state.dart';
import 'package:api_client/src/model/project_stats.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'project.g.dart';

/// Project
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [repoUrl] 
/// * [defaultBranch] 
/// * [includeGlobs] 
/// * [excludeGlobs] 
/// * [indexState] 
/// * [lastIndexedCommit] 
/// * [lastIndexedAt] 
/// * [stats] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class Project implements Built<Project, ProjectBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'repo_url')
  String get repoUrl;

  @BuiltValueField(wireName: r'default_branch')
  String get defaultBranch;

  @BuiltValueField(wireName: r'include_globs')
  BuiltList<String>? get includeGlobs;

  @BuiltValueField(wireName: r'exclude_globs')
  BuiltList<String>? get excludeGlobs;

  @BuiltValueField(wireName: r'index_state')
  IndexState get indexState;
  // enum indexStateEnum {  not_indexed,  indexing,  ready,  failed,  };

  @BuiltValueField(wireName: r'last_indexed_commit')
  String? get lastIndexedCommit;

  @BuiltValueField(wireName: r'last_indexed_at')
  DateTime? get lastIndexedAt;

  @BuiltValueField(wireName: r'stats')
  ProjectStats? get stats;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  Project._();

  factory Project([void updates(ProjectBuilder b)]) = _$Project;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProjectBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Project> get serializer => _$ProjectSerializer();
}

class _$ProjectSerializer implements PrimitiveSerializer<Project> {
  @override
  final Iterable<Type> types = const [Project, _$Project];

  @override
  final String wireName = r'Project';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Project object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
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
    yield r'default_branch';
    yield serializers.serialize(
      object.defaultBranch,
      specifiedType: const FullType(String),
    );
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
    yield r'index_state';
    yield serializers.serialize(
      object.indexState,
      specifiedType: const FullType(IndexState),
    );
    if (object.lastIndexedCommit != null) {
      yield r'last_indexed_commit';
      yield serializers.serialize(
        object.lastIndexedCommit,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.lastIndexedAt != null) {
      yield r'last_indexed_at';
      yield serializers.serialize(
        object.lastIndexedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.stats != null) {
      yield r'stats';
      yield serializers.serialize(
        object.stats,
        specifiedType: const FullType(ProjectStats),
      );
    }
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Project object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProjectBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
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
        case r'index_state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(IndexState),
          ) as IndexState;
          result.indexState = valueDes;
          break;
        case r'last_indexed_commit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastIndexedCommit = valueDes;
          break;
        case r'last_indexed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastIndexedAt = valueDes;
          break;
        case r'stats':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProjectStats),
          ) as ProjectStats;
          result.stats.replace(valueDes);
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Project deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProjectBuilder();
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

