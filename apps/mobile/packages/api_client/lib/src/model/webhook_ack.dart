//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'webhook_ack.g.dart';

/// WebhookAck
///
/// Properties:
/// * [deliveryId] 
/// * [result] 
/// * [reason] - ignored 사유 (예 non_default_branch, branch_deleted, unsupported_event, unknown_repository)
/// * [jobId] 
@BuiltValue()
abstract class WebhookAck implements Built<WebhookAck, WebhookAckBuilder> {
  @BuiltValueField(wireName: r'delivery_id')
  String get deliveryId;

  @BuiltValueField(wireName: r'result')
  WebhookAckResultEnum get result;
  // enum resultEnum {  queued,  ignored,  duplicate,  };

  /// ignored 사유 (예 non_default_branch, branch_deleted, unsupported_event, unknown_repository)
  @BuiltValueField(wireName: r'reason')
  String? get reason;

  @BuiltValueField(wireName: r'job_id')
  String? get jobId;

  WebhookAck._();

  factory WebhookAck([void updates(WebhookAckBuilder b)]) = _$WebhookAck;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WebhookAckBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WebhookAck> get serializer => _$WebhookAckSerializer();
}

class _$WebhookAckSerializer implements PrimitiveSerializer<WebhookAck> {
  @override
  final Iterable<Type> types = const [WebhookAck, _$WebhookAck];

  @override
  final String wireName = r'WebhookAck';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WebhookAck object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'delivery_id';
    yield serializers.serialize(
      object.deliveryId,
      specifiedType: const FullType(String),
    );
    yield r'result';
    yield serializers.serialize(
      object.result,
      specifiedType: const FullType(WebhookAckResultEnum),
    );
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jobId != null) {
      yield r'job_id';
      yield serializers.serialize(
        object.jobId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WebhookAck object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WebhookAckBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'delivery_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryId = valueDes;
          break;
        case r'result':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(WebhookAckResultEnum),
          ) as WebhookAckResultEnum;
          result.result = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        case r'job_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jobId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WebhookAck deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WebhookAckBuilder();
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

class WebhookAckResultEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'queued')
  static const WebhookAckResultEnum queued = _$webhookAckResultEnum_queued;
  @BuiltValueEnumConst(wireName: r'ignored')
  static const WebhookAckResultEnum ignored = _$webhookAckResultEnum_ignored;
  @BuiltValueEnumConst(wireName: r'duplicate')
  static const WebhookAckResultEnum duplicate = _$webhookAckResultEnum_duplicate;

  static Serializer<WebhookAckResultEnum> get serializer => _$webhookAckResultEnumSerializer;

  const WebhookAckResultEnum._(String name): super(name);

  static BuiltSet<WebhookAckResultEnum> get values => _$webhookAckResultEnumValues;
  static WebhookAckResultEnum valueOf(String name) => _$webhookAckResultEnumValueOf(name);
}

