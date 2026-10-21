//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_message_create.g.dart';

/// ChatMessageCreate
///
/// Properties:
/// * [sessionId] - null이면 새 세션 생성
/// * [content] 
/// * [contextPaths] 
@BuiltValue()
abstract class ChatMessageCreate implements Built<ChatMessageCreate, ChatMessageCreateBuilder> {
  /// null이면 새 세션 생성
  @BuiltValueField(wireName: r'session_id')
  String? get sessionId;

  @BuiltValueField(wireName: r'content')
  String get content;

  @BuiltValueField(wireName: r'context_paths')
  BuiltList<String>? get contextPaths;

  ChatMessageCreate._();

  factory ChatMessageCreate([void updates(ChatMessageCreateBuilder b)]) = _$ChatMessageCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatMessageCreateBuilder b) => b
      ..contextPaths = ListBuilder();

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatMessageCreate> get serializer => _$ChatMessageCreateSerializer();
}

class _$ChatMessageCreateSerializer implements PrimitiveSerializer<ChatMessageCreate> {
  @override
  final Iterable<Type> types = const [ChatMessageCreate, _$ChatMessageCreate];

  @override
  final String wireName = r'ChatMessageCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatMessageCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.sessionId != null) {
      yield r'session_id';
      yield serializers.serialize(
        object.sessionId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'content';
    yield serializers.serialize(
      object.content,
      specifiedType: const FullType(String),
    );
    if (object.contextPaths != null) {
      yield r'context_paths';
      yield serializers.serialize(
        object.contextPaths,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatMessageCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatMessageCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'session_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.sessionId = valueDes;
          break;
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.content = valueDes;
          break;
        case r'context_paths':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.contextPaths.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatMessageCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatMessageCreateBuilder();
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

