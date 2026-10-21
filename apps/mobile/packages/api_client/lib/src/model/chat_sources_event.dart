//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/chat_source.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_sources_event.g.dart';

/// ChatSourcesEvent
///
/// Properties:
/// * [event] 
/// * [sources] 
@BuiltValue()
abstract class ChatSourcesEvent implements Built<ChatSourcesEvent, ChatSourcesEventBuilder> {
  @BuiltValueField(wireName: r'event')
  ChatSourcesEventEventEnum get event;
  // enum eventEnum {  sources,  };

  @BuiltValueField(wireName: r'sources')
  BuiltList<ChatSource> get sources;

  ChatSourcesEvent._();

  factory ChatSourcesEvent([void updates(ChatSourcesEventBuilder b)]) = _$ChatSourcesEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatSourcesEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatSourcesEvent> get serializer => _$ChatSourcesEventSerializer();
}

class _$ChatSourcesEventSerializer implements PrimitiveSerializer<ChatSourcesEvent> {
  @override
  final Iterable<Type> types = const [ChatSourcesEvent, _$ChatSourcesEvent];

  @override
  final String wireName = r'ChatSourcesEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatSourcesEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(ChatSourcesEventEventEnum),
    );
    yield r'sources';
    yield serializers.serialize(
      object.sources,
      specifiedType: const FullType(BuiltList, [FullType(ChatSource)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatSourcesEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatSourcesEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'event':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ChatSourcesEventEventEnum),
          ) as ChatSourcesEventEventEnum;
          result.event = valueDes;
          break;
        case r'sources':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ChatSource)]),
          ) as BuiltList<ChatSource>;
          result.sources.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatSourcesEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatSourcesEventBuilder();
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

class ChatSourcesEventEventEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'sources')
  static const ChatSourcesEventEventEnum sources = _$chatSourcesEventEventEnum_sources;

  static Serializer<ChatSourcesEventEventEnum> get serializer => _$chatSourcesEventEventEnumSerializer;

  const ChatSourcesEventEventEnum._(String name): super(name);

  static BuiltSet<ChatSourcesEventEventEnum> get values => _$chatSourcesEventEventEnumValues;
  static ChatSourcesEventEventEnum valueOf(String name) => _$chatSourcesEventEventEnumValueOf(name);
}

