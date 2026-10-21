//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/chat_message.dart';
import 'package:api_client/src/model/cursor_page_info.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_message_page.g.dart';

/// ChatMessagePage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class ChatMessagePage implements Built<ChatMessagePage, ChatMessagePageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<ChatMessage> get items;

  @BuiltValueField(wireName: r'page')
  CursorPageInfo get page;

  ChatMessagePage._();

  factory ChatMessagePage([void updates(ChatMessagePageBuilder b)]) = _$ChatMessagePage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatMessagePageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatMessagePage> get serializer => _$ChatMessagePageSerializer();
}

class _$ChatMessagePageSerializer implements PrimitiveSerializer<ChatMessagePage> {
  @override
  final Iterable<Type> types = const [ChatMessagePage, _$ChatMessagePage];

  @override
  final String wireName = r'ChatMessagePage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatMessagePage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(ChatMessage)]),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(CursorPageInfo),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatMessagePage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatMessagePageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ChatMessage)]),
          ) as BuiltList<ChatMessage>;
          result.items.replace(valueDes);
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CursorPageInfo),
          ) as CursorPageInfo;
          result.page.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatMessagePage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatMessagePageBuilder();
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

