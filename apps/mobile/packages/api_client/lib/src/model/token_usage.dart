//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'token_usage.g.dart';

/// TokenUsage
///
/// Properties:
/// * [promptTokens] 
/// * [completionTokens] 
@BuiltValue()
abstract class TokenUsage implements Built<TokenUsage, TokenUsageBuilder> {
  @BuiltValueField(wireName: r'prompt_tokens')
  int get promptTokens;

  @BuiltValueField(wireName: r'completion_tokens')
  int get completionTokens;

  TokenUsage._();

  factory TokenUsage([void updates(TokenUsageBuilder b)]) = _$TokenUsage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TokenUsageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TokenUsage> get serializer => _$TokenUsageSerializer();
}

class _$TokenUsageSerializer implements PrimitiveSerializer<TokenUsage> {
  @override
  final Iterable<Type> types = const [TokenUsage, _$TokenUsage];

  @override
  final String wireName = r'TokenUsage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TokenUsage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'prompt_tokens';
    yield serializers.serialize(
      object.promptTokens,
      specifiedType: const FullType(int),
    );
    yield r'completion_tokens';
    yield serializers.serialize(
      object.completionTokens,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TokenUsage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TokenUsageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'prompt_tokens':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.promptTokens = valueDes;
          break;
        case r'completion_tokens':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.completionTokens = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TokenUsage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TokenUsageBuilder();
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

