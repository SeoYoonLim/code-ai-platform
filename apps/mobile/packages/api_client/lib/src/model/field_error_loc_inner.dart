//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'dart:core';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'field_error_loc_inner.g.dart';

/// FieldErrorLocInner
@BuiltValue()
abstract class FieldErrorLocInner implements Built<FieldErrorLocInner, FieldErrorLocInnerBuilder> {
  /// One Of [String], [int]
  OneOf get oneOf;

  FieldErrorLocInner._();

  factory FieldErrorLocInner([void updates(FieldErrorLocInnerBuilder b)]) = _$FieldErrorLocInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FieldErrorLocInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FieldErrorLocInner> get serializer => _$FieldErrorLocInnerSerializer();
}

class _$FieldErrorLocInnerSerializer implements PrimitiveSerializer<FieldErrorLocInner> {
  @override
  final Iterable<Type> types = const [FieldErrorLocInner, _$FieldErrorLocInner];

  @override
  final String wireName = r'FieldErrorLocInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FieldErrorLocInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
  }

  @override
  Object serialize(
    Serializers serializers,
    FieldErrorLocInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(oneOf.value, specifiedType: FullType(oneOf.valueType))!;
  }

  @override
  FieldErrorLocInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FieldErrorLocInnerBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [FullType(String), FullType(int), ]);
    oneOfDataSrc = serialized;
    result.oneOf = serializers.deserialize(oneOfDataSrc, specifiedType: targetType) as OneOf;
    return result.build();
  }
}

