// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_error_loc_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FieldErrorLocInner extends FieldErrorLocInner {
  @override
  final OneOf oneOf;

  factory _$FieldErrorLocInner(
          [void Function(FieldErrorLocInnerBuilder)? updates]) =>
      (new FieldErrorLocInnerBuilder()..update(updates))._build();

  _$FieldErrorLocInner._({required this.oneOf}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        oneOf, r'FieldErrorLocInner', 'oneOf');
  }

  @override
  FieldErrorLocInner rebuild(
          void Function(FieldErrorLocInnerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FieldErrorLocInnerBuilder toBuilder() =>
      new FieldErrorLocInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FieldErrorLocInner && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FieldErrorLocInner')
          ..add('oneOf', oneOf))
        .toString();
  }
}

class FieldErrorLocInnerBuilder
    implements Builder<FieldErrorLocInner, FieldErrorLocInnerBuilder> {
  _$FieldErrorLocInner? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  FieldErrorLocInnerBuilder() {
    FieldErrorLocInner._defaults(this);
  }

  FieldErrorLocInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FieldErrorLocInner other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$FieldErrorLocInner;
  }

  @override
  void update(void Function(FieldErrorLocInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FieldErrorLocInner build() => _build();

  _$FieldErrorLocInner _build() {
    final _$result = _$v ??
        new _$FieldErrorLocInner._(
            oneOf: BuiltValueNullFieldError.checkNotNull(
                oneOf, r'FieldErrorLocInner', 'oneOf'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
