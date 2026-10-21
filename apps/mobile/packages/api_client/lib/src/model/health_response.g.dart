// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$HealthResponse extends HealthResponse {
  @override
  final HealthStatus status;
  @override
  final String version;
  @override
  final HealthStatus engine;
  @override
  final HealthStatus database;
  @override
  final HealthStatus queue;

  factory _$HealthResponse([void Function(HealthResponseBuilder)? updates]) =>
      (new HealthResponseBuilder()..update(updates))._build();

  _$HealthResponse._(
      {required this.status,
      required this.version,
      required this.engine,
      required this.database,
      required this.queue})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(status, r'HealthResponse', 'status');
    BuiltValueNullFieldError.checkNotNull(
        version, r'HealthResponse', 'version');
    BuiltValueNullFieldError.checkNotNull(engine, r'HealthResponse', 'engine');
    BuiltValueNullFieldError.checkNotNull(
        database, r'HealthResponse', 'database');
    BuiltValueNullFieldError.checkNotNull(queue, r'HealthResponse', 'queue');
  }

  @override
  HealthResponse rebuild(void Function(HealthResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HealthResponseBuilder toBuilder() =>
      new HealthResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HealthResponse &&
        status == other.status &&
        version == other.version &&
        engine == other.engine &&
        database == other.database &&
        queue == other.queue;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, engine.hashCode);
    _$hash = $jc(_$hash, database.hashCode);
    _$hash = $jc(_$hash, queue.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'HealthResponse')
          ..add('status', status)
          ..add('version', version)
          ..add('engine', engine)
          ..add('database', database)
          ..add('queue', queue))
        .toString();
  }
}

class HealthResponseBuilder
    implements Builder<HealthResponse, HealthResponseBuilder> {
  _$HealthResponse? _$v;

  HealthStatus? _status;
  HealthStatus? get status => _$this._status;
  set status(HealthStatus? status) => _$this._status = status;

  String? _version;
  String? get version => _$this._version;
  set version(String? version) => _$this._version = version;

  HealthStatus? _engine;
  HealthStatus? get engine => _$this._engine;
  set engine(HealthStatus? engine) => _$this._engine = engine;

  HealthStatus? _database;
  HealthStatus? get database => _$this._database;
  set database(HealthStatus? database) => _$this._database = database;

  HealthStatus? _queue;
  HealthStatus? get queue => _$this._queue;
  set queue(HealthStatus? queue) => _$this._queue = queue;

  HealthResponseBuilder() {
    HealthResponse._defaults(this);
  }

  HealthResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _version = $v.version;
      _engine = $v.engine;
      _database = $v.database;
      _queue = $v.queue;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HealthResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$HealthResponse;
  }

  @override
  void update(void Function(HealthResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  HealthResponse build() => _build();

  _$HealthResponse _build() {
    final _$result = _$v ??
        new _$HealthResponse._(
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'HealthResponse', 'status'),
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'HealthResponse', 'version'),
            engine: BuiltValueNullFieldError.checkNotNull(
                engine, r'HealthResponse', 'engine'),
            database: BuiltValueNullFieldError.checkNotNull(
                database, r'HealthResponse', 'database'),
            queue: BuiltValueNullFieldError.checkNotNull(
                queue, r'HealthResponse', 'queue'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
