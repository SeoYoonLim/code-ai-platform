//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finding_category.g.dart';

class FindingCategory extends EnumClass {

  @BuiltValueEnumConst(wireName: r'bug')
  static const FindingCategory bug = _$bug;
  @BuiltValueEnumConst(wireName: r'security')
  static const FindingCategory security = _$security;
  @BuiltValueEnumConst(wireName: r'performance')
  static const FindingCategory performance = _$performance;
  @BuiltValueEnumConst(wireName: r'maintainability')
  static const FindingCategory maintainability = _$maintainability;
  @BuiltValueEnumConst(wireName: r'style')
  static const FindingCategory style = _$style;

  static Serializer<FindingCategory> get serializer => _$findingCategorySerializer;

  const FindingCategory._(String name): super(name);

  static BuiltSet<FindingCategory> get values => _$values;
  static FindingCategory valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class FindingCategoryMixin = Object with _$FindingCategoryMixin;

