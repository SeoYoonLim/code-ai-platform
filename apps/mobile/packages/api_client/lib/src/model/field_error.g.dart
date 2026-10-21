// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FieldError extends FieldError {
  @override
  final BuiltList<FieldErrorLocInner> loc;
  @override
  final String msg;
  @override
  final String type;

  factory _$FieldError([void Function(FieldErrorBuilder)? updates]) =>
      (new FieldErrorBuilder()..update(updates))._build();

  _$FieldError._({required this.loc, required this.msg, required this.type})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(loc, r'FieldError', 'loc');
    BuiltValueNullFieldError.checkNotNull(msg, r'FieldError', 'msg');
    BuiltValueNullFieldError.checkNotNull(type, r'FieldError', 'type');
  }

  @override
  FieldError rebuild(void Function(FieldErrorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FieldErrorBuilder toBuilder() => new FieldErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FieldError &&
        loc == other.loc &&
        msg == other.msg &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, loc.hashCode);
    _$hash = $jc(_$hash, msg.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FieldError')
          ..add('loc', loc)
          ..add('msg', msg)
          ..add('type', type))
        .toString();
  }
}

class FieldErrorBuilder implements Builder<FieldError, FieldErrorBuilder> {
  _$FieldError? _$v;

  ListBuilder<FieldErrorLocInner>? _loc;
  ListBuilder<FieldErrorLocInner> get loc =>
      _$this._loc ??= new ListBuilder<FieldErrorLocInner>();
  set loc(ListBuilder<FieldErrorLocInner>? loc) => _$this._loc = loc;

  String? _msg;
  String? get msg => _$this._msg;
  set msg(String? msg) => _$this._msg = msg;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  FieldErrorBuilder() {
    FieldError._defaults(this);
  }

  FieldErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _loc = $v.loc.toBuilder();
      _msg = $v.msg;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FieldError other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$FieldError;
  }

  @override
  void update(void Function(FieldErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FieldError build() => _build();

  _$FieldError _build() {
    _$FieldError _$result;
    try {
      _$result = _$v ??
          new _$FieldError._(
              loc: loc.build(),
              msg: BuiltValueNullFieldError.checkNotNull(
                  msg, r'FieldError', 'msg'),
              type: BuiltValueNullFieldError.checkNotNull(
                  type, r'FieldError', 'type'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'loc';
        loc.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'FieldError', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
