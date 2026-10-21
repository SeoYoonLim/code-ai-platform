// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_usage.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TokenUsage extends TokenUsage {
  @override
  final int promptTokens;
  @override
  final int completionTokens;

  factory _$TokenUsage([void Function(TokenUsageBuilder)? updates]) =>
      (new TokenUsageBuilder()..update(updates))._build();

  _$TokenUsage._({required this.promptTokens, required this.completionTokens})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        promptTokens, r'TokenUsage', 'promptTokens');
    BuiltValueNullFieldError.checkNotNull(
        completionTokens, r'TokenUsage', 'completionTokens');
  }

  @override
  TokenUsage rebuild(void Function(TokenUsageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenUsageBuilder toBuilder() => new TokenUsageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenUsage &&
        promptTokens == other.promptTokens &&
        completionTokens == other.completionTokens;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, promptTokens.hashCode);
    _$hash = $jc(_$hash, completionTokens.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TokenUsage')
          ..add('promptTokens', promptTokens)
          ..add('completionTokens', completionTokens))
        .toString();
  }
}

class TokenUsageBuilder implements Builder<TokenUsage, TokenUsageBuilder> {
  _$TokenUsage? _$v;

  int? _promptTokens;
  int? get promptTokens => _$this._promptTokens;
  set promptTokens(int? promptTokens) => _$this._promptTokens = promptTokens;

  int? _completionTokens;
  int? get completionTokens => _$this._completionTokens;
  set completionTokens(int? completionTokens) =>
      _$this._completionTokens = completionTokens;

  TokenUsageBuilder() {
    TokenUsage._defaults(this);
  }

  TokenUsageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _promptTokens = $v.promptTokens;
      _completionTokens = $v.completionTokens;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TokenUsage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$TokenUsage;
  }

  @override
  void update(void Function(TokenUsageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TokenUsage build() => _build();

  _$TokenUsage _build() {
    final _$result = _$v ??
        new _$TokenUsage._(
            promptTokens: BuiltValueNullFieldError.checkNotNull(
                promptTokens, r'TokenUsage', 'promptTokens'),
            completionTokens: BuiltValueNullFieldError.checkNotNull(
                completionTokens, r'TokenUsage', 'completionTokens'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
