//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reindex_request.g.dart';

/// ReindexRequest
///
/// Properties:
/// * [mode] 
@BuiltValue()
abstract class ReindexRequest implements Built<ReindexRequest, ReindexRequestBuilder> {
  @BuiltValueField(wireName: r'mode')
  ReindexRequestModeEnum? get mode;
  // enum modeEnum {  incremental,  full,  };

  ReindexRequest._();

  factory ReindexRequest([void updates(ReindexRequestBuilder b)]) = _$ReindexRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReindexRequestBuilder b) => b
      ..mode = const ReindexRequestModeEnum._('incremental');

  @BuiltValueSerializer(custom: true)
  static Serializer<ReindexRequest> get serializer => _$ReindexRequestSerializer();
}

class _$ReindexRequestSerializer implements PrimitiveSerializer<ReindexRequest> {
  @override
  final Iterable<Type> types = const [ReindexRequest, _$ReindexRequest];

  @override
  final String wireName = r'ReindexRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReindexRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.mode != null) {
      yield r'mode';
      yield serializers.serialize(
        object.mode,
        specifiedType: const FullType(ReindexRequestModeEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ReindexRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReindexRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReindexRequestModeEnum),
          ) as ReindexRequestModeEnum;
          result.mode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReindexRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReindexRequestBuilder();
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

class ReindexRequestModeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'incremental')
  static const ReindexRequestModeEnum incremental = _$reindexRequestModeEnum_incremental;
  @BuiltValueEnumConst(wireName: r'full')
  static const ReindexRequestModeEnum full = _$reindexRequestModeEnum_full;

  static Serializer<ReindexRequestModeEnum> get serializer => _$reindexRequestModeEnumSerializer;

  const ReindexRequestModeEnum._(String name): super(name);

  static BuiltSet<ReindexRequestModeEnum> get values => _$reindexRequestModeEnumValues;
  static ReindexRequestModeEnum valueOf(String name) => _$reindexRequestModeEnumValueOf(name);
}

