//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'project_stats.g.dart';

/// ProjectStats
///
/// Properties:
/// * [fileCount] 
/// * [chunkCount] 
@BuiltValue()
abstract class ProjectStats implements Built<ProjectStats, ProjectStatsBuilder> {
  @BuiltValueField(wireName: r'file_count')
  int? get fileCount;

  @BuiltValueField(wireName: r'chunk_count')
  int? get chunkCount;

  ProjectStats._();

  factory ProjectStats([void updates(ProjectStatsBuilder b)]) = _$ProjectStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProjectStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProjectStats> get serializer => _$ProjectStatsSerializer();
}

class _$ProjectStatsSerializer implements PrimitiveSerializer<ProjectStats> {
  @override
  final Iterable<Type> types = const [ProjectStats, _$ProjectStats];

  @override
  final String wireName = r'ProjectStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProjectStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.fileCount != null) {
      yield r'file_count';
      yield serializers.serialize(
        object.fileCount,
        specifiedType: const FullType(int),
      );
    }
    if (object.chunkCount != null) {
      yield r'chunk_count';
      yield serializers.serialize(
        object.chunkCount,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProjectStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProjectStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'file_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fileCount = valueDes;
          break;
        case r'chunk_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.chunkCount = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProjectStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProjectStatsBuilder();
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

