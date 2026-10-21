//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/code_target.dart';
import 'package:api_client/src/model/job_status.dart';
import 'package:api_client/src/model/patch_validation.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'refactor.g.dart';

/// Refactor
///
/// Properties:
/// * [id] 
/// * [projectId] 
/// * [jobId] 
/// * [status] 
/// * [target] 
/// * [instruction] 
/// * [analysisId] 
/// * [findingId] 
/// * [diff] - unified diff (완료 시)
/// * [explanation] 
/// * [validation] 
/// * [model] 
/// * [adapter] 
/// * [error] 
/// * [createdAt] 
/// * [completedAt] 
@BuiltValue()
abstract class Refactor implements Built<Refactor, RefactorBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'project_id')
  String get projectId;

  @BuiltValueField(wireName: r'job_id')
  String get jobId;

  @BuiltValueField(wireName: r'status')
  JobStatus get status;
  // enum statusEnum {  queued,  running,  succeeded,  failed,  canceled,  };

  @BuiltValueField(wireName: r'target')
  CodeTarget get target;

  @BuiltValueField(wireName: r'instruction')
  String get instruction;

  @BuiltValueField(wireName: r'analysis_id')
  String? get analysisId;

  @BuiltValueField(wireName: r'finding_id')
  String? get findingId;

  /// unified diff (완료 시)
  @BuiltValueField(wireName: r'diff')
  String? get diff;

  @BuiltValueField(wireName: r'explanation')
  String? get explanation;

  @BuiltValueField(wireName: r'validation')
  PatchValidation? get validation;

  @BuiltValueField(wireName: r'model')
  String? get model;

  @BuiltValueField(wireName: r'adapter')
  String? get adapter;

  @BuiltValueField(wireName: r'error')
  Problem? get error;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'completed_at')
  DateTime? get completedAt;

  Refactor._();

  factory Refactor([void updates(RefactorBuilder b)]) = _$Refactor;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RefactorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Refactor> get serializer => _$RefactorSerializer();
}

class _$RefactorSerializer implements PrimitiveSerializer<Refactor> {
  @override
  final Iterable<Type> types = const [Refactor, _$Refactor];

  @override
  final String wireName = r'Refactor';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Refactor object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'project_id';
    yield serializers.serialize(
      object.projectId,
      specifiedType: const FullType(String),
    );
    yield r'job_id';
    yield serializers.serialize(
      object.jobId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(JobStatus),
    );
    yield r'target';
    yield serializers.serialize(
      object.target,
      specifiedType: const FullType(CodeTarget),
    );
    yield r'instruction';
    yield serializers.serialize(
      object.instruction,
      specifiedType: const FullType(String),
    );
    if (object.analysisId != null) {
      yield r'analysis_id';
      yield serializers.serialize(
        object.analysisId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.findingId != null) {
      yield r'finding_id';
      yield serializers.serialize(
        object.findingId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.diff != null) {
      yield r'diff';
      yield serializers.serialize(
        object.diff,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.explanation != null) {
      yield r'explanation';
      yield serializers.serialize(
        object.explanation,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.validation != null) {
      yield r'validation';
      yield serializers.serialize(
        object.validation,
        specifiedType: const FullType.nullable(PatchValidation),
      );
    }
    if (object.model != null) {
      yield r'model';
      yield serializers.serialize(
        object.model,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.adapter != null) {
      yield r'adapter';
      yield serializers.serialize(
        object.adapter,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.error != null) {
      yield r'error';
      yield serializers.serialize(
        object.error,
        specifiedType: const FullType.nullable(Problem),
      );
    }
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.completedAt != null) {
      yield r'completed_at';
      yield serializers.serialize(
        object.completedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Refactor object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RefactorBuilder result,
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
        case r'project_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.projectId = valueDes;
          break;
        case r'job_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.jobId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JobStatus),
          ) as JobStatus;
          result.status = valueDes;
          break;
        case r'target':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CodeTarget),
          ) as CodeTarget;
          result.target.replace(valueDes);
          break;
        case r'instruction':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.instruction = valueDes;
          break;
        case r'analysis_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.analysisId = valueDes;
          break;
        case r'finding_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.findingId = valueDes;
          break;
        case r'diff':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.diff = valueDes;
          break;
        case r'explanation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.explanation = valueDes;
          break;
        case r'validation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(PatchValidation),
          ) as PatchValidation?;
          if (valueDes == null) continue;
          result.validation.replace(valueDes);
          break;
        case r'model':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.model = valueDes;
          break;
        case r'adapter':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.adapter = valueDes;
          break;
        case r'error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Problem),
          ) as Problem?;
          if (valueDes == null) continue;
          result.error.replace(valueDes);
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'completed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.completedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Refactor deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RefactorBuilder();
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

