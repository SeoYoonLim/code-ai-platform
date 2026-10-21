//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/finding_category.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'analysis_create.g.dart';

/// AnalysisCreate
///
/// Properties:
/// * [paths] 
/// * [instruction] 
/// * [categories] 
@BuiltValue()
abstract class AnalysisCreate implements Built<AnalysisCreate, AnalysisCreateBuilder> {
  @BuiltValueField(wireName: r'paths')
  BuiltList<String> get paths;

  @BuiltValueField(wireName: r'instruction')
  String? get instruction;

  @BuiltValueField(wireName: r'categories')
  BuiltList<FindingCategory>? get categories;

  AnalysisCreate._();

  factory AnalysisCreate([void updates(AnalysisCreateBuilder b)]) = _$AnalysisCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnalysisCreateBuilder b) => b
      ..categories = ListBuilder();

  @BuiltValueSerializer(custom: true)
  static Serializer<AnalysisCreate> get serializer => _$AnalysisCreateSerializer();
}

class _$AnalysisCreateSerializer implements PrimitiveSerializer<AnalysisCreate> {
  @override
  final Iterable<Type> types = const [AnalysisCreate, _$AnalysisCreate];

  @override
  final String wireName = r'AnalysisCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnalysisCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'paths';
    yield serializers.serialize(
      object.paths,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    if (object.instruction != null) {
      yield r'instruction';
      yield serializers.serialize(
        object.instruction,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.categories != null) {
      yield r'categories';
      yield serializers.serialize(
        object.categories,
        specifiedType: const FullType(BuiltList, [FullType(FindingCategory)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AnalysisCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AnalysisCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'paths':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.paths.replace(valueDes);
          break;
        case r'instruction':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.instruction = valueDes;
          break;
        case r'categories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FindingCategory)]),
          ) as BuiltList<FindingCategory>;
          result.categories.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AnalysisCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnalysisCreateBuilder();
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

