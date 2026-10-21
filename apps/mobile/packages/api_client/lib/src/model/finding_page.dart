//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/finding.dart';
import 'package:api_client/src/model/offset_page_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finding_page.g.dart';

/// FindingPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class FindingPage implements Built<FindingPage, FindingPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Finding> get items;

  @BuiltValueField(wireName: r'page')
  OffsetPageInfo get page;

  FindingPage._();

  factory FindingPage([void updates(FindingPageBuilder b)]) = _$FindingPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FindingPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FindingPage> get serializer => _$FindingPageSerializer();
}

class _$FindingPageSerializer implements PrimitiveSerializer<FindingPage> {
  @override
  final Iterable<Type> types = const [FindingPage, _$FindingPage];

  @override
  final String wireName = r'FindingPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FindingPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Finding)]),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(OffsetPageInfo),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FindingPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FindingPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Finding)]),
          ) as BuiltList<Finding>;
          result.items.replace(valueDes);
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OffsetPageInfo),
          ) as OffsetPageInfo;
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
  FindingPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FindingPageBuilder();
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

