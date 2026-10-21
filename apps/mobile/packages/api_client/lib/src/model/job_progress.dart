//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_progress.g.dart';

/// JobProgress
///
/// Properties:
/// * [current] 
/// * [total] 
/// * [phase] 
@BuiltValue()
abstract class JobProgress implements Built<JobProgress, JobProgressBuilder> {
  @BuiltValueField(wireName: r'current')
  int get current;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'phase')
  String? get phase;

  JobProgress._();

  factory JobProgress([void updates(JobProgressBuilder b)]) = _$JobProgress;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobProgressBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobProgress> get serializer => _$JobProgressSerializer();
}

class _$JobProgressSerializer implements PrimitiveSerializer<JobProgress> {
  @override
  final Iterable<Type> types = const [JobProgress, _$JobProgress];

  @override
  final String wireName = r'JobProgress';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobProgress object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'current';
    yield serializers.serialize(
      object.current,
      specifiedType: const FullType(int),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    if (object.phase != null) {
      yield r'phase';
      yield serializers.serialize(
        object.phase,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobProgress object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobProgressBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'current':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.current = valueDes;
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'phase':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.phase = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobProgress deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobProgressBuilder();
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

