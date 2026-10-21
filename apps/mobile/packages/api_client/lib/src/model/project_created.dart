//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/job.dart';
import 'package:api_client/src/model/project.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'project_created.g.dart';

/// ProjectCreated
///
/// Properties:
/// * [project] 
/// * [indexJob] 
@BuiltValue()
abstract class ProjectCreated implements Built<ProjectCreated, ProjectCreatedBuilder> {
  @BuiltValueField(wireName: r'project')
  Project get project;

  @BuiltValueField(wireName: r'index_job')
  Job get indexJob;

  ProjectCreated._();

  factory ProjectCreated([void updates(ProjectCreatedBuilder b)]) = _$ProjectCreated;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProjectCreatedBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProjectCreated> get serializer => _$ProjectCreatedSerializer();
}

class _$ProjectCreatedSerializer implements PrimitiveSerializer<ProjectCreated> {
  @override
  final Iterable<Type> types = const [ProjectCreated, _$ProjectCreated];

  @override
  final String wireName = r'ProjectCreated';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProjectCreated object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'project';
    yield serializers.serialize(
      object.project,
      specifiedType: const FullType(Project),
    );
    yield r'index_job';
    yield serializers.serialize(
      object.indexJob,
      specifiedType: const FullType(Job),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProjectCreated object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProjectCreatedBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'project':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Project),
          ) as Project;
          result.project.replace(valueDes);
          break;
        case r'index_job':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Job),
          ) as Job;
          result.indexJob.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProjectCreated deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProjectCreatedBuilder();
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

