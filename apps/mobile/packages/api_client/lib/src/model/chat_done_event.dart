//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/token_usage.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_done_event.g.dart';

/// ChatDoneEvent
///
/// Properties:
/// * [event] 
/// * [finishReason] 
/// * [usage] 
@BuiltValue()
abstract class ChatDoneEvent implements Built<ChatDoneEvent, ChatDoneEventBuilder> {
  @BuiltValueField(wireName: r'event')
  ChatDoneEventEventEnum get event;
  // enum eventEnum {  done,  };

  @BuiltValueField(wireName: r'finish_reason')
  ChatDoneEventFinishReasonEnum get finishReason;
  // enum finishReasonEnum {  stop,  length,  error,  canceled,  };

  @BuiltValueField(wireName: r'usage')
  TokenUsage get usage;

  ChatDoneEvent._();

  factory ChatDoneEvent([void updates(ChatDoneEventBuilder b)]) = _$ChatDoneEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatDoneEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatDoneEvent> get serializer => _$ChatDoneEventSerializer();
}

class _$ChatDoneEventSerializer implements PrimitiveSerializer<ChatDoneEvent> {
  @override
  final Iterable<Type> types = const [ChatDoneEvent, _$ChatDoneEvent];

  @override
  final String wireName = r'ChatDoneEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatDoneEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(ChatDoneEventEventEnum),
    );
    yield r'finish_reason';
    yield serializers.serialize(
      object.finishReason,
      specifiedType: const FullType(ChatDoneEventFinishReasonEnum),
    );
    yield r'usage';
    yield serializers.serialize(
      object.usage,
      specifiedType: const FullType(TokenUsage),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatDoneEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatDoneEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'event':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ChatDoneEventEventEnum),
          ) as ChatDoneEventEventEnum;
          result.event = valueDes;
          break;
        case r'finish_reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ChatDoneEventFinishReasonEnum),
          ) as ChatDoneEventFinishReasonEnum;
          result.finishReason = valueDes;
          break;
        case r'usage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TokenUsage),
          ) as TokenUsage;
          result.usage.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatDoneEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatDoneEventBuilder();
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

class ChatDoneEventEventEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'done')
  static const ChatDoneEventEventEnum done = _$chatDoneEventEventEnum_done;

  static Serializer<ChatDoneEventEventEnum> get serializer => _$chatDoneEventEventEnumSerializer;

  const ChatDoneEventEventEnum._(String name): super(name);

  static BuiltSet<ChatDoneEventEventEnum> get values => _$chatDoneEventEventEnumValues;
  static ChatDoneEventEventEnum valueOf(String name) => _$chatDoneEventEventEnumValueOf(name);
}

class ChatDoneEventFinishReasonEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'stop')
  static const ChatDoneEventFinishReasonEnum stop = _$chatDoneEventFinishReasonEnum_stop;
  @BuiltValueEnumConst(wireName: r'length')
  static const ChatDoneEventFinishReasonEnum length = _$chatDoneEventFinishReasonEnum_length;
  @BuiltValueEnumConst(wireName: r'error')
  static const ChatDoneEventFinishReasonEnum error = _$chatDoneEventFinishReasonEnum_error;
  @BuiltValueEnumConst(wireName: r'canceled')
  static const ChatDoneEventFinishReasonEnum canceled = _$chatDoneEventFinishReasonEnum_canceled;

  static Serializer<ChatDoneEventFinishReasonEnum> get serializer => _$chatDoneEventFinishReasonEnumSerializer;

  const ChatDoneEventFinishReasonEnum._(String name): super(name);

  static BuiltSet<ChatDoneEventFinishReasonEnum> get values => _$chatDoneEventFinishReasonEnumValues;
  static ChatDoneEventFinishReasonEnum valueOf(String name) => _$chatDoneEventFinishReasonEnumValueOf(name);
}

