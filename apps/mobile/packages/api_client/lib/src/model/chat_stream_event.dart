//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/chat_done_event.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/chat_sources_event.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/token_usage.dart';
import 'package:api_client/src/model/chat_token_event.dart';
import 'package:api_client/src/model/chat_meta_event.dart';
import 'package:api_client/src/model/chat_error_event.dart';
import 'package:api_client/src/model/chat_source.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'chat_stream_event.g.dart';

/// SSE data 필드의 JSON. wire 형식:   id: {stream_id}:{seq}   event: {event}   data: {ChatStreamEvent JSON} 
///
/// Properties:
/// * [event] 
/// * [streamId] 
/// * [sessionId] 
/// * [messageId] - assistant 메시지 ID (재연결 키)
/// * [model] 
/// * [adapter] 
/// * [sources] 
/// * [index] 
/// * [delta] 
/// * [finishReason] 
/// * [usage] 
/// * [error] 
@BuiltValue()
abstract class ChatStreamEvent implements Built<ChatStreamEvent, ChatStreamEventBuilder> {
  /// One Of [ChatDoneEvent], [ChatErrorEvent], [ChatMetaEvent], [ChatSourcesEvent], [ChatTokenEvent]
  OneOf get oneOf;

  static const String discriminatorFieldName = r'event';

  static const Map<String, Type> discriminatorMapping = {
    r'done': ChatDoneEvent,
    r'error': ChatErrorEvent,
    r'meta': ChatMetaEvent,
    r'sources': ChatSourcesEvent,
    r'token': ChatTokenEvent,
  };

  ChatStreamEvent._();

  factory ChatStreamEvent([void updates(ChatStreamEventBuilder b)]) = _$ChatStreamEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatStreamEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatStreamEvent> get serializer => _$ChatStreamEventSerializer();
}

extension ChatStreamEventDiscriminatorExt on ChatStreamEvent {
    String? get discriminatorValue {
        if (this is ChatDoneEvent) {
            return r'done';
        }
        if (this is ChatErrorEvent) {
            return r'error';
        }
        if (this is ChatMetaEvent) {
            return r'meta';
        }
        if (this is ChatSourcesEvent) {
            return r'sources';
        }
        if (this is ChatTokenEvent) {
            return r'token';
        }
        return null;
    }
}
extension ChatStreamEventBuilderDiscriminatorExt on ChatStreamEventBuilder {
    String? get discriminatorValue {
        if (this is ChatDoneEventBuilder) {
            return r'done';
        }
        if (this is ChatErrorEventBuilder) {
            return r'error';
        }
        if (this is ChatMetaEventBuilder) {
            return r'meta';
        }
        if (this is ChatSourcesEventBuilder) {
            return r'sources';
        }
        if (this is ChatTokenEventBuilder) {
            return r'token';
        }
        return null;
    }
}

class _$ChatStreamEventSerializer implements PrimitiveSerializer<ChatStreamEvent> {
  @override
  final Iterable<Type> types = const [ChatStreamEvent, _$ChatStreamEvent];

  @override
  final String wireName = r'ChatStreamEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatStreamEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatStreamEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(oneOf.value, specifiedType: FullType(oneOf.valueType))!;
  }

  @override
  ChatStreamEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatStreamEventBuilder();
    Object? oneOfDataSrc;
    final serializedList = (serialized as Iterable<Object?>).toList();
    final discIndex = serializedList.indexOf(ChatStreamEvent.discriminatorFieldName) + 1;
    final discValue = serializers.deserialize(serializedList[discIndex], specifiedType: FullType(String)) as String;
    oneOfDataSrc = serialized;
    final oneOfTypes = [ChatDoneEvent, ChatErrorEvent, ChatMetaEvent, ChatSourcesEvent, ChatTokenEvent, ];
    Object oneOfResult;
    Type oneOfType;
    switch (discValue) {
      case r'done':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ChatDoneEvent),
        ) as ChatDoneEvent;
        oneOfType = ChatDoneEvent;
        break;
      case r'error':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ChatErrorEvent),
        ) as ChatErrorEvent;
        oneOfType = ChatErrorEvent;
        break;
      case r'meta':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ChatMetaEvent),
        ) as ChatMetaEvent;
        oneOfType = ChatMetaEvent;
        break;
      case r'sources':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ChatSourcesEvent),
        ) as ChatSourcesEvent;
        oneOfType = ChatSourcesEvent;
        break;
      case r'token':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ChatTokenEvent),
        ) as ChatTokenEvent;
        oneOfType = ChatTokenEvent;
        break;
      default:
        throw UnsupportedError("Couldn't deserialize oneOf for the discriminator value: ${discValue}");
    }
    result.oneOf = OneOfDynamic(typeIndex: oneOfTypes.indexOf(oneOfType), types: oneOfTypes, value: oneOfResult);
    return result.build();
  }
}

class ChatStreamEventEventEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'error')
  static const ChatStreamEventEventEnum error = _$chatStreamEventEventEnum_error;

  static Serializer<ChatStreamEventEventEnum> get serializer => _$chatStreamEventEventEnumSerializer;

  const ChatStreamEventEventEnum._(String name): super(name);

  static BuiltSet<ChatStreamEventEventEnum> get values => _$chatStreamEventEventEnumValues;
  static ChatStreamEventEventEnum valueOf(String name) => _$chatStreamEventEventEnumValueOf(name);
}

class ChatStreamEventFinishReasonEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'stop')
  static const ChatStreamEventFinishReasonEnum stop = _$chatStreamEventFinishReasonEnum_stop;
  @BuiltValueEnumConst(wireName: r'length')
  static const ChatStreamEventFinishReasonEnum length = _$chatStreamEventFinishReasonEnum_length;
  @BuiltValueEnumConst(wireName: r'error')
  static const ChatStreamEventFinishReasonEnum error = _$chatStreamEventFinishReasonEnum_error;
  @BuiltValueEnumConst(wireName: r'canceled')
  static const ChatStreamEventFinishReasonEnum canceled = _$chatStreamEventFinishReasonEnum_canceled;

  static Serializer<ChatStreamEventFinishReasonEnum> get serializer => _$chatStreamEventFinishReasonEnumSerializer;

  const ChatStreamEventFinishReasonEnum._(String name): super(name);

  static BuiltSet<ChatStreamEventFinishReasonEnum> get values => _$chatStreamEventFinishReasonEnumValues;
  static ChatStreamEventFinishReasonEnum valueOf(String name) => _$chatStreamEventFinishReasonEnumValueOf(name);
}

