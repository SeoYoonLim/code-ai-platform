//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finding_counts.g.dart';

/// FindingCounts
///
/// Properties:
/// * [info] 
/// * [minor] 
/// * [major] 
/// * [critical] 
@BuiltValue()
abstract class FindingCounts implements Built<FindingCounts, FindingCountsBuilder> {
  @BuiltValueField(wireName: r'info')
  int get info;

  @BuiltValueField(wireName: r'minor')
  int get minor;

  @BuiltValueField(wireName: r'major')
  int get major;

  @BuiltValueField(wireName: r'critical')
  int get critical;

  FindingCounts._();

  factory FindingCounts([void updates(FindingCountsBuilder b)]) = _$FindingCounts;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FindingCountsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FindingCounts> get serializer => _$FindingCountsSerializer();
}

class _$FindingCountsSerializer implements PrimitiveSerializer<FindingCounts> {
  @override
  final Iterable<Type> types = const [FindingCounts, _$FindingCounts];

  @override
  final String wireName = r'FindingCounts';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FindingCounts object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'info';
    yield serializers.serialize(
      object.info,
      specifiedType: const FullType(int),
    );
    yield r'minor';
    yield serializers.serialize(
      object.minor,
      specifiedType: const FullType(int),
    );
    yield r'major';
    yield serializers.serialize(
      object.major,
      specifiedType: const FullType(int),
    );
    yield r'critical';
    yield serializers.serialize(
      object.critical,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FindingCounts object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FindingCountsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'info':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.info = valueDes;
          break;
        case r'minor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.minor = valueDes;
          break;
        case r'major':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.major = valueDes;
          break;
        case r'critical':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.critical = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FindingCounts deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FindingCountsBuilder();
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

