// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Problem extends Problem {
  @override
  final String type;
  @override
  final String title;
  @override
  final int status;
  @override
  final String? detail;
  @override
  final String? instance;
  @override
  final ErrorCode code;
  @override
  final bool retryable;
  @override
  final int? retryAfterS;
  @override
  final String? requestId;
  @override
  final BuiltList<FieldError>? errors;

  factory _$Problem([void Function(ProblemBuilder)? updates]) =>
      (new ProblemBuilder()..update(updates))._build();

  _$Problem._(
      {required this.type,
      required this.title,
      required this.status,
      this.detail,
      this.instance,
      required this.code,
      required this.retryable,
      this.retryAfterS,
      this.requestId,
      this.errors})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(type, r'Problem', 'type');
    BuiltValueNullFieldError.checkNotNull(title, r'Problem', 'title');
    BuiltValueNullFieldError.checkNotNull(status, r'Problem', 'status');
    BuiltValueNullFieldError.checkNotNull(code, r'Problem', 'code');
    BuiltValueNullFieldError.checkNotNull(retryable, r'Problem', 'retryable');
  }

  @override
  Problem rebuild(void Function(ProblemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProblemBuilder toBuilder() => new ProblemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Problem &&
        type == other.type &&
        title == other.title &&
        status == other.status &&
        detail == other.detail &&
        instance == other.instance &&
        code == other.code &&
        retryable == other.retryable &&
        retryAfterS == other.retryAfterS &&
        requestId == other.requestId &&
        errors == other.errors;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, detail.hashCode);
    _$hash = $jc(_$hash, instance.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, retryable.hashCode);
    _$hash = $jc(_$hash, retryAfterS.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Problem')
          ..add('type', type)
          ..add('title', title)
          ..add('status', status)
          ..add('detail', detail)
          ..add('instance', instance)
          ..add('code', code)
          ..add('retryable', retryable)
          ..add('retryAfterS', retryAfterS)
          ..add('requestId', requestId)
          ..add('errors', errors))
        .toString();
  }
}

class ProblemBuilder implements Builder<Problem, ProblemBuilder> {
  _$Problem? _$v;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  int? _status;
  int? get status => _$this._status;
  set status(int? status) => _$this._status = status;

  String? _detail;
  String? get detail => _$this._detail;
  set detail(String? detail) => _$this._detail = detail;

  String? _instance;
  String? get instance => _$this._instance;
  set instance(String? instance) => _$this._instance = instance;

  ErrorCode? _code;
  ErrorCode? get code => _$this._code;
  set code(ErrorCode? code) => _$this._code = code;

  bool? _retryable;
  bool? get retryable => _$this._retryable;
  set retryable(bool? retryable) => _$this._retryable = retryable;

  int? _retryAfterS;
  int? get retryAfterS => _$this._retryAfterS;
  set retryAfterS(int? retryAfterS) => _$this._retryAfterS = retryAfterS;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  ListBuilder<FieldError>? _errors;
  ListBuilder<FieldError> get errors =>
      _$this._errors ??= new ListBuilder<FieldError>();
  set errors(ListBuilder<FieldError>? errors) => _$this._errors = errors;

  ProblemBuilder() {
    Problem._defaults(this);
  }

  ProblemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _title = $v.title;
      _status = $v.status;
      _detail = $v.detail;
      _instance = $v.instance;
      _code = $v.code;
      _retryable = $v.retryable;
      _retryAfterS = $v.retryAfterS;
      _requestId = $v.requestId;
      _errors = $v.errors?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Problem other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Problem;
  }

  @override
  void update(void Function(ProblemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Problem build() => _build();

  _$Problem _build() {
    _$Problem _$result;
    try {
      _$result = _$v ??
          new _$Problem._(
              type: BuiltValueNullFieldError.checkNotNull(
                  type, r'Problem', 'type'),
              title: BuiltValueNullFieldError.checkNotNull(
                  title, r'Problem', 'title'),
              status: BuiltValueNullFieldError.checkNotNull(
                  status, r'Problem', 'status'),
              detail: detail,
              instance: instance,
              code: BuiltValueNullFieldError.checkNotNull(
                  code, r'Problem', 'code'),
              retryable: BuiltValueNullFieldError.checkNotNull(
                  retryable, r'Problem', 'retryable'),
              retryAfterS: retryAfterS,
              requestId: requestId,
              errors: _errors?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'errors';
        _errors?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Problem', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
