//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/field_error_loc_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'field_error.g.dart';

/// FieldError
///
/// Properties:
/// * [loc] 
/// * [msg] 
/// * [type] 
@BuiltValue()
abstract class FieldError implements Built<FieldError, FieldErrorBuilder> {
  @BuiltValueField(wireName: r'loc')
  BuiltList<FieldErrorLocInner> get loc;

  @BuiltValueField(wireName: r'msg')
  String get msg;

  @BuiltValueField(wireName: r'type')
  String get type;

  FieldError._();

  factory FieldError([void updates(FieldErrorBuilder b)]) = _$FieldError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FieldErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FieldError> get serializer => _$FieldErrorSerializer();
}

class _$FieldErrorSerializer implements PrimitiveSerializer<FieldError> {
  @override
  final Iterable<Type> types = const [FieldError, _$FieldError];

  @override
  final String wireName = r'FieldError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FieldError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'loc';
    yield serializers.serialize(
      object.loc,
      specifiedType: const FullType(BuiltList, [FullType(FieldErrorLocInner)]),
    );
    yield r'msg';
    yield serializers.serialize(
      object.msg,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FieldError object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FieldErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'loc':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FieldErrorLocInner)]),
          ) as BuiltList<FieldErrorLocInner>;
          result.loc.replace(valueDes);
          break;
        case r'msg':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.msg = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FieldError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FieldErrorBuilder();
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

