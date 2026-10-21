//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/code_target.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'refactor_create.g.dart';

/// RefactorCreate
///
/// Properties:
/// * [target] 
/// * [instruction] 
@BuiltValue()
abstract class RefactorCreate implements Built<RefactorCreate, RefactorCreateBuilder> {
  @BuiltValueField(wireName: r'target')
  CodeTarget get target;

  @BuiltValueField(wireName: r'instruction')
  String get instruction;

  RefactorCreate._();

  factory RefactorCreate([void updates(RefactorCreateBuilder b)]) = _$RefactorCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RefactorCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RefactorCreate> get serializer => _$RefactorCreateSerializer();
}

class _$RefactorCreateSerializer implements PrimitiveSerializer<RefactorCreate> {
  @override
  final Iterable<Type> types = const [RefactorCreate, _$RefactorCreate];

  @override
  final String wireName = r'RefactorCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RefactorCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'target';
    yield serializers.serialize(
      object.target,
      specifiedType: const FullType(CodeTarget),
    );
    yield r'instruction';
    yield serializers.serialize(
      object.instruction,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RefactorCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RefactorCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'target':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CodeTarget),
          ) as CodeTarget;
          result.target.replace(valueDes);
          break;
        case r'instruction':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.instruction = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RefactorCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RefactorCreateBuilder();
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

