//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'patch_validation.g.dart';

/// PatchValidation
///
/// Properties:
/// * [appliesCleanly] 
/// * [syntaxOk] 
/// * [errors] 
@BuiltValue()
abstract class PatchValidation implements Built<PatchValidation, PatchValidationBuilder> {
  @BuiltValueField(wireName: r'applies_cleanly')
  bool get appliesCleanly;

  @BuiltValueField(wireName: r'syntax_ok')
  bool get syntaxOk;

  @BuiltValueField(wireName: r'errors')
  BuiltList<String>? get errors;

  PatchValidation._();

  factory PatchValidation([void updates(PatchValidationBuilder b)]) = _$PatchValidation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PatchValidationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PatchValidation> get serializer => _$PatchValidationSerializer();
}

class _$PatchValidationSerializer implements PrimitiveSerializer<PatchValidation> {
  @override
  final Iterable<Type> types = const [PatchValidation, _$PatchValidation];

  @override
  final String wireName = r'PatchValidation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PatchValidation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'applies_cleanly';
    yield serializers.serialize(
      object.appliesCleanly,
      specifiedType: const FullType(bool),
    );
    yield r'syntax_ok';
    yield serializers.serialize(
      object.syntaxOk,
      specifiedType: const FullType(bool),
    );
    if (object.errors != null) {
      yield r'errors';
      yield serializers.serialize(
        object.errors,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PatchValidation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PatchValidationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'applies_cleanly':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.appliesCleanly = valueDes;
          break;
        case r'syntax_ok':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.syntaxOk = valueDes;
          break;
        case r'errors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.errors.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PatchValidation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PatchValidationBuilder();
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

