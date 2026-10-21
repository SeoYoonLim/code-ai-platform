// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const HealthStatus _$ok = const HealthStatus._('ok');
const HealthStatus _$degraded = const HealthStatus._('degraded');
const HealthStatus _$down = const HealthStatus._('down');

HealthStatus _$valueOf(String name) {
  switch (name) {
    case 'ok':
      return _$ok;
    case 'degraded':
      return _$degraded;
    case 'down':
      return _$down;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<HealthStatus> _$values =
    new BuiltSet<HealthStatus>(const <HealthStatus>[
  _$ok,
  _$degraded,
  _$down,
]);

class _$HealthStatusMeta {
  const _$HealthStatusMeta();
  HealthStatus get ok => _$ok;
  HealthStatus get degraded => _$degraded;
  HealthStatus get down => _$down;
  HealthStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<HealthStatus> get values => _$values;
}

abstract class _$HealthStatusMixin {
  // ignore: non_constant_identifier_names
  _$HealthStatusMeta get HealthStatus => const _$HealthStatusMeta();
}

Serializer<HealthStatus> _$healthStatusSerializer =
    new _$HealthStatusSerializer();

class _$HealthStatusSerializer implements PrimitiveSerializer<HealthStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ok': 'ok',
    'degraded': 'degraded',
    'down': 'down',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ok': 'ok',
    'degraded': 'degraded',
    'down': 'down',
  };

  @override
  final Iterable<Type> types = const <Type>[HealthStatus];
  @override
  final String wireName = 'HealthStatus';

  @override
  Object serialize(Serializers serializers, HealthStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  HealthStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      HealthStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
