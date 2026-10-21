//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/cursor_page_info.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/analysis.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'analysis_page.g.dart';

/// AnalysisPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class AnalysisPage implements Built<AnalysisPage, AnalysisPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Analysis> get items;

  @BuiltValueField(wireName: r'page')
  CursorPageInfo get page;

  AnalysisPage._();

  factory AnalysisPage([void updates(AnalysisPageBuilder b)]) = _$AnalysisPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnalysisPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AnalysisPage> get serializer => _$AnalysisPageSerializer();
}

class _$AnalysisPageSerializer implements PrimitiveSerializer<AnalysisPage> {
  @override
  final Iterable<Type> types = const [AnalysisPage, _$AnalysisPage];

  @override
  final String wireName = r'AnalysisPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnalysisPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Analysis)]),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(CursorPageInfo),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AnalysisPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AnalysisPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Analysis)]),
          ) as BuiltList<Analysis>;
          result.items.replace(valueDes);
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CursorPageInfo),
          ) as CursorPageInfo;
          result.page.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AnalysisPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnalysisPageBuilder();
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

