//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_meta_event.g.dart';

/// ChatMetaEvent
///
/// Properties:
/// * [event] 
/// * [streamId] 
/// * [sessionId] 
/// * [messageId] - assistant 메시지 ID (재연결 키)
/// * [model] 
/// * [adapter] 
@BuiltValue()
abstract class ChatMetaEvent implements Built<ChatMetaEvent, ChatMetaEventBuilder> {
  @BuiltValueField(wireName: r'event')
  ChatMetaEventEventEnum get event;
  // enum eventEnum {  meta,  };

  @BuiltValueField(wireName: r'stream_id')
  String get streamId;

  @BuiltValueField(wireName: r'session_id')
  String get sessionId;

  /// assistant 메시지 ID (재연결 키)
  @BuiltValueField(wireName: r'message_id')
  String get messageId;

  @BuiltValueField(wireName: r'model')
  String get model;

  @BuiltValueField(wireName: r'adapter')
  String? get adapter;

  ChatMetaEvent._();

  factory ChatMetaEvent([void updates(ChatMetaEventBuilder b)]) = _$ChatMetaEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatMetaEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatMetaEvent> get serializer => _$ChatMetaEventSerializer();
}

class _$ChatMetaEventSerializer implements PrimitiveSerializer<ChatMetaEvent> {
  @override
  final Iterable<Type> types = const [ChatMetaEvent, _$ChatMetaEvent];

  @override
  final String wireName = r'ChatMetaEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatMetaEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(ChatMetaEventEventEnum),
    );
    yield r'stream_id';
    yield serializers.serialize(
      object.streamId,
      specifiedType: const FullType(String),
    );
    yield r'session_id';
    yield serializers.serialize(
      object.sessionId,
      specifiedType: const FullType(String),
    );
    yield r'message_id';
    yield serializers.serialize(
      object.messageId,
      specifiedType: const FullType(String),
    );
    yield r'model';
    yield serializers.serialize(
      object.model,
      specifiedType: const FullType(String),
    );
    if (object.adapter != null) {
      yield r'adapter';
      yield serializers.serialize(
        object.adapter,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatMetaEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatMetaEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'event':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ChatMetaEventEventEnum),
          ) as ChatMetaEventEventEnum;
          result.event = valueDes;
          break;
        case r'stream_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.streamId = valueDes;
          break;
        case r'session_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sessionId = valueDes;
          break;
        case r'message_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.messageId = valueDes;
          break;
        case r'model':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatMetaEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatMetaEventBuilder();
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

class ChatMetaEventEventEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'meta')
  static const ChatMetaEventEventEnum meta = _$chatMetaEventEventEnum_meta;

  static Serializer<ChatMetaEventEventEnum> get serializer => _$chatMetaEventEventEnumSerializer;

  const ChatMetaEventEventEnum._(String name): super(name);

  static BuiltSet<ChatMetaEventEventEnum> get values => _$chatMetaEventEventEnumValues;
  static ChatMetaEventEventEnum valueOf(String name) => _$chatMetaEventEventEnumValueOf(name);
}

