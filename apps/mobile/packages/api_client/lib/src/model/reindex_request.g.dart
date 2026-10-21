// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reindex_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReindexRequestModeEnum _$reindexRequestModeEnum_incremental =
    const ReindexRequestModeEnum._('incremental');
const ReindexRequestModeEnum _$reindexRequestModeEnum_full =
    const ReindexRequestModeEnum._('full');

ReindexRequestModeEnum _$reindexRequestModeEnumValueOf(String name) {
  switch (name) {
    case 'incremental':
      return _$reindexRequestModeEnum_incremental;
    case 'full':
      return _$reindexRequestModeEnum_full;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ReindexRequestModeEnum> _$reindexRequestModeEnumValues =
    new BuiltSet<ReindexRequestModeEnum>(const <ReindexRequestModeEnum>[
  _$reindexRequestModeEnum_incremental,
  _$reindexRequestModeEnum_full,
]);

Serializer<ReindexRequestModeEnum> _$reindexRequestModeEnumSerializer =
    new _$ReindexRequestModeEnumSerializer();

class _$ReindexRequestModeEnumSerializer
    implements PrimitiveSerializer<ReindexRequestModeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'incremental': 'incremental',
    'full': 'full',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'incremental': 'incremental',
    'full': 'full',
  };

  @override
  final Iterable<Type> types = const <Type>[ReindexRequestModeEnum];
  @override
  final String wireName = 'ReindexRequestModeEnum';

  @override
  Object serialize(Serializers serializers, ReindexRequestModeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ReindexRequestModeEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ReindexRequestModeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ReindexRequest extends ReindexRequest {
  @override
  final ReindexRequestModeEnum? mode;

  factory _$ReindexRequest([void Function(ReindexRequestBuilder)? updates]) =>
      (new ReindexRequestBuilder()..update(updates))._build();

  _$ReindexRequest._({this.mode}) : super._();

  @override
  ReindexRequest rebuild(void Function(ReindexRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReindexRequestBuilder toBuilder() =>
      new ReindexRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReindexRequest && mode == other.mode;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReindexRequest')..add('mode', mode))
        .toString();
  }
}

class ReindexRequestBuilder
    implements Builder<ReindexRequest, ReindexRequestBuilder> {
  _$ReindexRequest? _$v;

  ReindexRequestModeEnum? _mode;
  ReindexRequestModeEnum? get mode => _$this._mode;
  set mode(ReindexRequestModeEnum? mode) => _$this._mode = mode;

  ReindexRequestBuilder() {
    ReindexRequest._defaults(this);
  }

  ReindexRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mode = $v.mode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReindexRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ReindexRequest;
  }

  @override
  void update(void Function(ReindexRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReindexRequest build() => _build();

  _$ReindexRequest _build() {
    final _$result = _$v ?? new _$ReindexRequest._(mode: mode);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
