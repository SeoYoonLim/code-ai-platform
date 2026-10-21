// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finding_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FindingCategory _$bug = const FindingCategory._('bug');
const FindingCategory _$security = const FindingCategory._('security');
const FindingCategory _$performance = const FindingCategory._('performance');
const FindingCategory _$maintainability =
    const FindingCategory._('maintainability');
const FindingCategory _$style = const FindingCategory._('style');

FindingCategory _$valueOf(String name) {
  switch (name) {
    case 'bug':
      return _$bug;
    case 'security':
      return _$security;
    case 'performance':
      return _$performance;
    case 'maintainability':
      return _$maintainability;
    case 'style':
      return _$style;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<FindingCategory> _$values =
    new BuiltSet<FindingCategory>(const <FindingCategory>[
  _$bug,
  _$security,
  _$performance,
  _$maintainability,
  _$style,
]);

class _$FindingCategoryMeta {
  const _$FindingCategoryMeta();
  FindingCategory get bug => _$bug;
  FindingCategory get security => _$security;
  FindingCategory get performance => _$performance;
  FindingCategory get maintainability => _$maintainability;
  FindingCategory get style => _$style;
  FindingCategory valueOf(String name) => _$valueOf(name);
  BuiltSet<FindingCategory> get values => _$values;
}

abstract class _$FindingCategoryMixin {
  // ignore: non_constant_identifier_names
  _$FindingCategoryMeta get FindingCategory => const _$FindingCategoryMeta();
}

Serializer<FindingCategory> _$findingCategorySerializer =
    new _$FindingCategorySerializer();

class _$FindingCategorySerializer
    implements PrimitiveSerializer<FindingCategory> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'bug': 'bug',
    'security': 'security',
    'performance': 'performance',
    'maintainability': 'maintainability',
    'style': 'style',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'bug': 'bug',
    'security': 'security',
    'performance': 'performance',
    'maintainability': 'maintainability',
    'style': 'style',
  };

  @override
  final Iterable<Type> types = const <Type>[FindingCategory];
  @override
  final String wireName = 'FindingCategory';

  @override
  Object serialize(Serializers serializers, FindingCategory object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FindingCategory deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FindingCategory.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
