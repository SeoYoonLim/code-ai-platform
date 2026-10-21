//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'feedback_verdict.g.dart';

class FeedbackVerdict extends EnumClass {

  @BuiltValueEnumConst(wireName: r'accepted')
  static const FeedbackVerdict accepted = _$accepted;
  @BuiltValueEnumConst(wireName: r'rejected')
  static const FeedbackVerdict rejected = _$rejected;
  @BuiltValueEnumConst(wireName: r'edited')
  static const FeedbackVerdict edited = _$edited;

  static Serializer<FeedbackVerdict> get serializer => _$feedbackVerdictSerializer;

  const FeedbackVerdict._(String name): super(name);

  static BuiltSet<FeedbackVerdict> get values => _$values;
  static FeedbackVerdict valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class FeedbackVerdictMixin = Object with _$FeedbackVerdictMixin;

