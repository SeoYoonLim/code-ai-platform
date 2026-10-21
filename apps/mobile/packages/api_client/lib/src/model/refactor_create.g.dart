// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refactor_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RefactorCreate extends RefactorCreate {
  @override
  final CodeTarget target;
  @override
  final String instruction;

  factory _$RefactorCreate([void Function(RefactorCreateBuilder)? updates]) =>
      (new RefactorCreateBuilder()..update(updates))._build();

  _$RefactorCreate._({required this.target, required this.instruction})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(target, r'RefactorCreate', 'target');
    BuiltValueNullFieldError.checkNotNull(
        instruction, r'RefactorCreate', 'instruction');
  }

  @override
  RefactorCreate rebuild(void Function(RefactorCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RefactorCreateBuilder toBuilder() =>
      new RefactorCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RefactorCreate &&
        target == other.target &&
        instruction == other.instruction;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jc(_$hash, instruction.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RefactorCreate')
          ..add('target', target)
          ..add('instruction', instruction))
        .toString();
  }
}

class RefactorCreateBuilder
    implements Builder<RefactorCreate, RefactorCreateBuilder> {
  _$RefactorCreate? _$v;

  CodeTargetBuilder? _target;
  CodeTargetBuilder get target => _$this._target ??= new CodeTargetBuilder();
  set target(CodeTargetBuilder? target) => _$this._target = target;

  String? _instruction;
  String? get instruction => _$this._instruction;
  set instruction(String? instruction) => _$this._instruction = instruction;

  RefactorCreateBuilder() {
    RefactorCreate._defaults(this);
  }

  RefactorCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _target = $v.target.toBuilder();
      _instruction = $v.instruction;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RefactorCreate other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$RefactorCreate;
  }

  @override
  void update(void Function(RefactorCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RefactorCreate build() => _build();

  _$RefactorCreate _build() {
    _$RefactorCreate _$result;
    try {
      _$result = _$v ??
          new _$RefactorCreate._(
              target: target.build(),
              instruction: BuiltValueNullFieldError.checkNotNull(
                  instruction, r'RefactorCreate', 'instruction'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'target';
        target.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'RefactorCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
