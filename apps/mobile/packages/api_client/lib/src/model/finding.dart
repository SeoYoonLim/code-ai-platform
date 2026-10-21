//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/feedback_verdict.dart';
import 'package:api_client/src/model/finding_category.dart';
import 'package:api_client/src/model/severity.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finding.g.dart';

/// Finding
///
/// Properties:
/// * [id] 
/// * [category] 
/// * [severity] 
/// * [title] 
/// * [message] 
/// * [path] 
/// * [startLine] 
/// * [endLine] 
/// * [suggestion] 
/// * [confidence] 
/// * [feedback] 
@BuiltValue()
abstract class Finding implements Built<Finding, FindingBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'category')
  FindingCategory get category;
  // enum categoryEnum {  bug,  security,  performance,  maintainability,  style,  };

  @BuiltValueField(wireName: r'severity')
  Severity get severity;
  // enum severityEnum {  info,  minor,  major,  critical,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'path')
  String get path;

  @BuiltValueField(wireName: r'start_line')
  int get startLine;

  @BuiltValueField(wireName: r'end_line')
  int get endLine;

  @BuiltValueField(wireName: r'suggestion')
  String? get suggestion;

  @BuiltValueField(wireName: r'confidence')
  num? get confidence;

  @BuiltValueField(wireName: r'feedback')
  FeedbackVerdict? get feedback;
  // enum feedbackEnum {  accepted,  rejected,  edited,  };

  Finding._();

  factory Finding([void updates(FindingBuilder b)]) = _$Finding;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FindingBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Finding> get serializer => _$FindingSerializer();
}

class _$FindingSerializer implements PrimitiveSerializer<Finding> {
  @override
  final Iterable<Type> types = const [Finding, _$Finding];

  @override
  final String wireName = r'Finding';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Finding object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'category';
    yield serializers.serialize(
      object.category,
      specifiedType: const FullType(FindingCategory),
    );
    yield r'severity';
    yield serializers.serialize(
      object.severity,
      specifiedType: const FullType(Severity),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'path';
    yield serializers.serialize(
      object.path,
      specifiedType: const FullType(String),
    );
    yield r'start_line';
    yield serializers.serialize(
      object.startLine,
      specifiedType: const FullType(int),
    );
    yield r'end_line';
    yield serializers.serialize(
      object.endLine,
      specifiedType: const FullType(int),
    );
    if (object.suggestion != null) {
      yield r'suggestion';
      yield serializers.serialize(
        object.suggestion,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.confidence != null) {
      yield r'confidence';
      yield serializers.serialize(
        object.confidence,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.feedback != null) {
      yield r'feedback';
      yield serializers.serialize(
        object.feedback,
        specifiedType: const FullType.nullable(FeedbackVerdict),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Finding object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FindingBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FindingCategory),
          ) as FindingCategory;
          result.category = valueDes;
          break;
        case r'severity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Severity),
          ) as Severity;
          result.severity = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'path':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.path = valueDes;
          break;
        case r'start_line':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.startLine = valueDes;
          break;
        case r'end_line':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.endLine = valueDes;
          break;
        case r'suggestion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.suggestion = valueDes;
          break;
        case r'confidence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.confidence = valueDes;
          break;
        case r'feedback':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(FeedbackVerdict),
          ) as FeedbackVerdict?;
          if (valueDes == null) continue;
          result.feedback = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Finding deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FindingBuilder();
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

