//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'project_update.g.dart';

/// ProjectUpdate
///
/// Properties:
/// * [name] 
/// * [defaultBranch] 
/// * [includeGlobs] 
/// * [excludeGlobs] 
@BuiltValue()
abstract class ProjectUpdate implements Built<ProjectUpdate, ProjectUpdateBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'default_branch')
  String? get defaultBranch;

  @BuiltValueField(wireName: r'include_globs')
  BuiltList<String>? get includeGlobs;

  @BuiltValueField(wireName: r'exclude_globs')
  BuiltList<String>? get excludeGlobs;

  ProjectUpdate._();

  factory ProjectUpdate([void updates(ProjectUpdateBuilder b)]) = _$ProjectUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProjectUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProjectUpdate> get serializer => _$ProjectUpdateSerializer();
}

class _$ProjectUpdateSerializer implements PrimitiveSerializer<ProjectUpdate> {
  @override
  final Iterable<Type> types = const [ProjectUpdate, _$ProjectUpdate];

  @override
  final String wireName = r'ProjectUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProjectUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
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
    ProjectUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProjectUpdateBuilder result,
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
  ProjectUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProjectUpdateBuilder();
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

