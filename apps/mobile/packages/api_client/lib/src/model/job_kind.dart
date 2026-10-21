//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_kind.g.dart';

class JobKind extends EnumClass {

  @BuiltValueEnumConst(wireName: r'index')
  static const JobKind index = _$index;
  @BuiltValueEnumConst(wireName: r'analysis')
  static const JobKind analysis = _$analysis;
  @BuiltValueEnumConst(wireName: r'refactor')
  static const JobKind refactor = _$refactor;

  static Serializer<JobKind> get serializer => _$jobKindSerializer;

  const JobKind._(String name): super(name);

  static BuiltSet<JobKind> get values => _$values;
  static JobKind valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class JobKindMixin = Object with _$JobKindMixin;

