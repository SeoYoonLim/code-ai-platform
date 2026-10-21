//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_error_event.g.dart';

/// ChatErrorEvent
///
/// Properties:
/// * [event] 
/// * [error] 
@BuiltValue()
abstract class ChatErrorEvent implements Built<ChatErrorEvent, ChatErrorEventBuilder> {
  @BuiltValueField(wireName: r'event')
  ChatErrorEventEventEnum get event;
  // enum eventEnum {  error,  };

  @BuiltValueField(wireName: r'error')
  Problem get error;

  ChatErrorEvent._();

  factory ChatErrorEvent([void updates(ChatErrorEventBuilder b)]) = _$ChatErrorEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatErrorEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatErrorEvent> get serializer => _$ChatErrorEventSerializer();
}

class _$ChatErrorEventSerializer implements PrimitiveSerializer<ChatErrorEvent> {
  @override
  final Iterable<Type> types = const [ChatErrorEvent, _$ChatErrorEvent];

  @override
  final String wireName = r'ChatErrorEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatErrorEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(ChatErrorEventEventEnum),
    );
    yield r'error';
    yield serializers.serialize(
      object.error,
      specifiedType: const FullType(Problem),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatErrorEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatErrorEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'event':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ChatErrorEventEventEnum),
          ) as ChatErrorEventEventEnum;
          result.event = valueDes;
          break;
        case r'error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Problem),
          ) as Problem;
          result.error.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatErrorEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatErrorEventBuilder();
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

class ChatErrorEventEventEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'error')
  static const ChatErrorEventEventEnum error = _$chatErrorEventEventEnum_error;

  static Serializer<ChatErrorEventEventEnum> get serializer => _$chatErrorEventEventEnumSerializer;

  const ChatErrorEventEventEnum._(String name): super(name);

  static BuiltSet<ChatErrorEventEventEnum> get values => _$chatErrorEventEventEnumValues;
  static ChatErrorEventEventEnum valueOf(String name) => _$chatErrorEventEventEnumValueOf(name);
}

