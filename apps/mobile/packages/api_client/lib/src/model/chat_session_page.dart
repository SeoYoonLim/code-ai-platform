//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/cursor_page_info.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/chat_session.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_session_page.g.dart';

/// ChatSessionPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class ChatSessionPage implements Built<ChatSessionPage, ChatSessionPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<ChatSession> get items;

  @BuiltValueField(wireName: r'page')
  CursorPageInfo get page;

  ChatSessionPage._();

  factory ChatSessionPage([void updates(ChatSessionPageBuilder b)]) = _$ChatSessionPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatSessionPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatSessionPage> get serializer => _$ChatSessionPageSerializer();
}

class _$ChatSessionPageSerializer implements PrimitiveSerializer<ChatSessionPage> {
  @override
  final Iterable<Type> types = const [ChatSessionPage, _$ChatSessionPage];

  @override
  final String wireName = r'ChatSessionPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatSessionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(ChatSession)]),
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
    ChatSessionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatSessionPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ChatSession)]),
          ) as BuiltList<ChatSession>;
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
  ChatSessionPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatSessionPageBuilder();
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

