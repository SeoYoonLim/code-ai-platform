//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/health_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'health_response.g.dart';

/// HealthResponse
///
/// Properties:
/// * [status] 
/// * [version] 
/// * [engine] 
/// * [database] 
/// * [queue] 
@BuiltValue()
abstract class HealthResponse implements Built<HealthResponse, HealthResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  HealthStatus get status;
  // enum statusEnum {  ok,  degraded,  down,  };

  @BuiltValueField(wireName: r'version')
  String get version;

  @BuiltValueField(wireName: r'engine')
  HealthStatus get engine;
  // enum engineEnum {  ok,  degraded,  down,  };

  @BuiltValueField(wireName: r'database')
  HealthStatus get database;
  // enum databaseEnum {  ok,  degraded,  down,  };

  @BuiltValueField(wireName: r'queue')
  HealthStatus get queue;
  // enum queueEnum {  ok,  degraded,  down,  };

  HealthResponse._();

  factory HealthResponse([void updates(HealthResponseBuilder b)]) = _$HealthResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HealthResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<HealthResponse> get serializer => _$HealthResponseSerializer();
}

class _$HealthResponseSerializer implements PrimitiveSerializer<HealthResponse> {
  @override
  final Iterable<Type> types = const [HealthResponse, _$HealthResponse];

  @override
  final String wireName = r'HealthResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HealthResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(HealthStatus),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(String),
    );
    yield r'engine';
    yield serializers.serialize(
      object.engine,
      specifiedType: const FullType(HealthStatus),
    );
    yield r'database';
    yield serializers.serialize(
      object.database,
      specifiedType: const FullType(HealthStatus),
    );
    yield r'queue';
    yield serializers.serialize(
      object.queue,
      specifiedType: const FullType(HealthStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    HealthResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required HealthResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HealthStatus),
          ) as HealthStatus;
          result.status = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.version = valueDes;
          break;
        case r'engine':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HealthStatus),
          ) as HealthStatus;
          result.engine = valueDes;
          break;
        case r'database':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HealthStatus),
          ) as HealthStatus;
          result.database = valueDes;
          break;
        case r'queue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HealthStatus),
          ) as HealthStatus;
          result.queue = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HealthResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HealthResponseBuilder();
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

