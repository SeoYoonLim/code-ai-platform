// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_target.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CodeTarget extends CodeTarget {
  @override
  final String path;
  @override
  final int? startLine;
  @override
  final int? endLine;

  factory _$CodeTarget([void Function(CodeTargetBuilder)? updates]) =>
      (new CodeTargetBuilder()..update(updates))._build();

  _$CodeTarget._({required this.path, this.startLine, this.endLine})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(path, r'CodeTarget', 'path');
  }

  @override
  CodeTarget rebuild(void Function(CodeTargetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CodeTargetBuilder toBuilder() => new CodeTargetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CodeTarget &&
        path == other.path &&
        startLine == other.startLine &&
        endLine == other.endLine;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, path.hashCode);
    _$hash = $jc(_$hash, startLine.hashCode);
    _$hash = $jc(_$hash, endLine.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CodeTarget')
          ..add('path', path)
          ..add('startLine', startLine)
          ..add('endLine', endLine))
        .toString();
  }
}

class CodeTargetBuilder implements Builder<CodeTarget, CodeTargetBuilder> {
  _$CodeTarget? _$v;

  String? _path;
  String? get path => _$this._path;
  set path(String? path) => _$this._path = path;

  int? _startLine;
  int? get startLine => _$this._startLine;
  set startLine(int? startLine) => _$this._startLine = startLine;

  int? _endLine;
  int? get endLine => _$this._endLine;
  set endLine(int? endLine) => _$this._endLine = endLine;

  CodeTargetBuilder() {
    CodeTarget._defaults(this);
  }

  CodeTargetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _path = $v.path;
      _startLine = $v.startLine;
      _endLine = $v.endLine;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CodeTarget other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CodeTarget;
  }

  @override
  void update(void Function(CodeTargetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CodeTarget build() => _build();

  _$CodeTarget _build() {
    final _$result = _$v ??
        new _$CodeTarget._(
            path: BuiltValueNullFieldError.checkNotNull(
                path, r'CodeTarget', 'path'),
            startLine: startLine,
            endLine: endLine);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
