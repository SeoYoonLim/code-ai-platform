//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_token_event.g.dart';

/// ChatTokenEvent
///
/// Properties:
/// * [event] 
/// * [index] 
/// * [delta] 
@BuiltValue()
abstract class ChatTokenEvent implements Built<ChatTokenEvent, ChatTokenEventBuilder> {
  @BuiltValueField(wireName: r'event')
  ChatTokenEventEventEnum get event;
  // enum eventEnum {  token,  };

  @BuiltValueField(wireName: r'index')
  int get index;

  @BuiltValueField(wireName: r'delta')
  String get delta;

  ChatTokenEvent._();

  factory ChatTokenEvent([void updates(ChatTokenEventBuilder b)]) = _$ChatTokenEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatTokenEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatTokenEvent> get serializer => _$ChatTokenEventSerializer();
}

class _$ChatTokenEventSerializer implements PrimitiveSerializer<ChatTokenEvent> {
  @override
  final Iterable<Type> types = const [ChatTokenEvent, _$ChatTokenEvent];

  @override
  final String wireName = r'ChatTokenEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatTokenEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(ChatTokenEventEventEnum),
    );
    yield r'index';
    yield serializers.serialize(
      object.index,
      specifiedType: const FullType(int),
    );
    yield r'delta';
    yield serializers.serialize(
      object.delta,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatTokenEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatTokenEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'event':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ChatTokenEventEventEnum),
          ) as ChatTokenEventEventEnum;
          result.event = valueDes;
          break;
        case r'index':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.index = valueDes;
          break;
        case r'delta':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.delta = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatTokenEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatTokenEventBuilder();
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

class ChatTokenEventEventEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'token')
  static const ChatTokenEventEventEnum token = _$chatTokenEventEventEnum_token;

  static Serializer<ChatTokenEventEventEnum> get serializer => _$chatTokenEventEventEnumSerializer;

  const ChatTokenEventEventEnum._(String name): super(name);

  static BuiltSet<ChatTokenEventEventEnum> get values => _$chatTokenEventEventEnumValues;
  static ChatTokenEventEventEnum valueOf(String name) => _$chatTokenEventEventEnumValueOf(name);
}

