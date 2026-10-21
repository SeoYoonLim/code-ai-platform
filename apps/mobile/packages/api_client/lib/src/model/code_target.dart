//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'code_target.g.dart';

/// CodeTarget
///
/// Properties:
/// * [path] 
/// * [startLine] 
/// * [endLine] 
@BuiltValue()
abstract class CodeTarget implements Built<CodeTarget, CodeTargetBuilder> {
  @BuiltValueField(wireName: r'path')
  String get path;

  @BuiltValueField(wireName: r'start_line')
  int? get startLine;

  @BuiltValueField(wireName: r'end_line')
  int? get endLine;

  CodeTarget._();

  factory CodeTarget([void updates(CodeTargetBuilder b)]) = _$CodeTarget;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CodeTargetBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CodeTarget> get serializer => _$CodeTargetSerializer();
}

class _$CodeTargetSerializer implements PrimitiveSerializer<CodeTarget> {
  @override
  final Iterable<Type> types = const [CodeTarget, _$CodeTarget];

  @override
  final String wireName = r'CodeTarget';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CodeTarget object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'path';
    yield serializers.serialize(
      object.path,
      specifiedType: const FullType(String),
    );
    if (object.startLine != null) {
      yield r'start_line';
      yield serializers.serialize(
        object.startLine,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.endLine != null) {
      yield r'end_line';
      yield serializers.serialize(
        object.endLine,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CodeTarget object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CodeTargetBuilder result,
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
        case r'start_line':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.startLine = valueDes;
          break;
        case r'end_line':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.endLine = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CodeTarget deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CodeTargetBuilder();
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

