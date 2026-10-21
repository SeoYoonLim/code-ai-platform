// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refactor_finding_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RefactorFindingRequest extends RefactorFindingRequest {
  @override
  final String? instruction;

  factory _$RefactorFindingRequest(
          [void Function(RefactorFindingRequestBuilder)? updates]) =>
      (new RefactorFindingRequestBuilder()..update(updates))._build();

  _$RefactorFindingRequest._({this.instruction}) : super._();

  @override
  RefactorFindingRequest rebuild(
          void Function(RefactorFindingRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RefactorFindingRequestBuilder toBuilder() =>
      new RefactorFindingRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RefactorFindingRequest && instruction == other.instruction;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, instruction.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RefactorFindingRequest')
          ..add('instruction', instruction))
        .toString();
  }
}

class RefactorFindingRequestBuilder
    implements Builder<RefactorFindingRequest, RefactorFindingRequestBuilder> {
  _$RefactorFindingRequest? _$v;

  String? _instruction;
  String? get instruction => _$this._instruction;
  set instruction(String? instruction) => _$this._instruction = instruction;

  RefactorFindingRequestBuilder() {
    RefactorFindingRequest._defaults(this);
  }

  RefactorFindingRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _instruction = $v.instruction;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RefactorFindingRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$RefactorFindingRequest;
  }

  @override
  void update(void Function(RefactorFindingRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RefactorFindingRequest build() => _build();

  _$RefactorFindingRequest _build() {
    final _$result =
        _$v ?? new _$RefactorFindingRequest._(instruction: instruction);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
