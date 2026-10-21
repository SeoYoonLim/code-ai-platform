//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/cursor_page_info.dart';
import 'package:api_client/src/model/job.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_page.g.dart';

/// JobPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class JobPage implements Built<JobPage, JobPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Job> get items;

  @BuiltValueField(wireName: r'page')
  CursorPageInfo get page;

  JobPage._();

  factory JobPage([void updates(JobPageBuilder b)]) = _$JobPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobPage> get serializer => _$JobPageSerializer();
}

class _$JobPageSerializer implements PrimitiveSerializer<JobPage> {
  @override
  final Iterable<Type> types = const [JobPage, _$JobPage];

  @override
  final String wireName = r'JobPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Job)]),
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
    JobPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Job)]),
          ) as BuiltList<Job>;
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
  JobPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobPageBuilder();
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

