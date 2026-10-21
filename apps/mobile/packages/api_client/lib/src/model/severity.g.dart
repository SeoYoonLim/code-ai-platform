// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'severity.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Severity _$info = const Severity._('info');
const Severity _$minor = const Severity._('minor');
const Severity _$major = const Severity._('major');
const Severity _$critical = const Severity._('critical');

Severity _$valueOf(String name) {
  switch (name) {
    case 'info':
      return _$info;
    case 'minor':
      return _$minor;
    case 'major':
      return _$major;
    case 'critical':
      return _$critical;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<Severity> _$values = new BuiltSet<Severity>(const <Severity>[
  _$info,
  _$minor,
  _$major,
  _$critical,
]);

class _$SeverityMeta {
  const _$SeverityMeta();
  Severity get info => _$info;
  Severity get minor => _$minor;
  Severity get major => _$major;
  Severity get critical => _$critical;
  Severity valueOf(String name) => _$valueOf(name);
  BuiltSet<Severity> get values => _$values;
}

abstract class _$SeverityMixin {
  // ignore: non_constant_identifier_names
  _$SeverityMeta get Severity => const _$SeverityMeta();
}

Serializer<Severity> _$severitySerializer = new _$SeveritySerializer();

class _$SeveritySerializer implements PrimitiveSerializer<Severity> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'info': 'info',
    'minor': 'minor',
    'major': 'major',
    'critical': 'critical',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'info': 'info',
    'minor': 'minor',
    'major': 'major',
    'critical': 'critical',
  };

  @override
  final Iterable<Type> types = const <Type>[Severity];
  @override
  final String wireName = 'Severity';

  @override
  Object serialize(Serializers serializers, Severity object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  Severity deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      Severity.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
