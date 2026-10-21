//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_source.g.dart';

/// ChatSource
///
/// Properties:
/// * [path] 
/// * [symbol] 
/// * [startLine] 
/// * [endLine] 
/// * [score] 
@BuiltValue()
abstract class ChatSource implements Built<ChatSource, ChatSourceBuilder> {
  @BuiltValueField(wireName: r'path')
  String get path;

  @BuiltValueField(wireName: r'symbol')
  String get symbol;

  @BuiltValueField(wireName: r'start_line')
  int get startLine;

  @BuiltValueField(wireName: r'end_line')
  int get endLine;

  @BuiltValueField(wireName: r'score')
  num get score;

  ChatSource._();

  factory ChatSource([void updates(ChatSourceBuilder b)]) = _$ChatSource;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChatSourceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChatSource> get serializer => _$ChatSourceSerializer();
}

class _$ChatSourceSerializer implements PrimitiveSerializer<ChatSource> {
  @override
  final Iterable<Type> types = const [ChatSource, _$ChatSource];

  @override
  final String wireName = r'ChatSource';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChatSource object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'path';
    yield serializers.serialize(
      object.path,
      specifiedType: const FullType(String),
    );
    yield r'symbol';
    yield serializers.serialize(
      object.symbol,
      specifiedType: const FullType(String),
    );
    yield r'start_line';
    yield serializers.serialize(
      object.startLine,
      specifiedType: const FullType(int),
    );
    yield r'end_line';
    yield serializers.serialize(
      object.endLine,
      specifiedType: const FullType(int),
    );
    yield r'score';
    yield serializers.serialize(
      object.score,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ChatSource object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChatSourceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'path':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.path = valueDes;
          break;
        case r'symbol':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.symbol = valueDes;
          break;
        case r'start_line':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.startLine = valueDes;
          break;
        case r'end_line':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.endLine = valueDes;
          break;
        case r'score':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.score = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ChatSource deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChatSourceBuilder();
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

