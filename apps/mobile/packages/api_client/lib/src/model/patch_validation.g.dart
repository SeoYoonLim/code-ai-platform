// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_validation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PatchValidation extends PatchValidation {
  @override
  final bool appliesCleanly;
  @override
  final bool syntaxOk;
  @override
  final BuiltList<String>? errors;

  factory _$PatchValidation([void Function(PatchValidationBuilder)? updates]) =>
      (new PatchValidationBuilder()..update(updates))._build();

  _$PatchValidation._(
      {required this.appliesCleanly, required this.syntaxOk, this.errors})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        appliesCleanly, r'PatchValidation', 'appliesCleanly');
    BuiltValueNullFieldError.checkNotNull(
        syntaxOk, r'PatchValidation', 'syntaxOk');
  }

  @override
  PatchValidation rebuild(void Function(PatchValidationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PatchValidationBuilder toBuilder() =>
      new PatchValidationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PatchValidation &&
        appliesCleanly == other.appliesCleanly &&
        syntaxOk == other.syntaxOk &&
        errors == other.errors;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appliesCleanly.hashCode);
    _$hash = $jc(_$hash, syntaxOk.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PatchValidation')
          ..add('appliesCleanly', appliesCleanly)
          ..add('syntaxOk', syntaxOk)
          ..add('errors', errors))
        .toString();
  }
}

class PatchValidationBuilder
    implements Builder<PatchValidation, PatchValidationBuilder> {
  _$PatchValidation? _$v;

  bool? _appliesCleanly;
  bool? get appliesCleanly => _$this._appliesCleanly;
  set appliesCleanly(bool? appliesCleanly) =>
      _$this._appliesCleanly = appliesCleanly;

  bool? _syntaxOk;
  bool? get syntaxOk => _$this._syntaxOk;
  set syntaxOk(bool? syntaxOk) => _$this._syntaxOk = syntaxOk;

  ListBuilder<String>? _errors;
  ListBuilder<String> get errors =>
      _$this._errors ??= new ListBuilder<String>();
  set errors(ListBuilder<String>? errors) => _$this._errors = errors;

  PatchValidationBuilder() {
    PatchValidation._defaults(this);
  }

  PatchValidationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appliesCleanly = $v.appliesCleanly;
      _syntaxOk = $v.syntaxOk;
      _errors = $v.errors?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PatchValidation other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PatchValidation;
  }

  @override
  void update(void Function(PatchValidationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PatchValidation build() => _build();

  _$PatchValidation _build() {
    _$PatchValidation _$result;
    try {
      _$result = _$v ??
          new _$PatchValidation._(
              appliesCleanly: BuiltValueNullFieldError.checkNotNull(
                  appliesCleanly, r'PatchValidation', 'appliesCleanly'),
              syntaxOk: BuiltValueNullFieldError.checkNotNull(
                  syntaxOk, r'PatchValidation', 'syntaxOk'),
              errors: _errors?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'errors';
        _errors?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'PatchValidation', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
