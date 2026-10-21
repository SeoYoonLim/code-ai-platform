// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChatSource extends ChatSource {
  @override
  final String path;
  @override
  final String symbol;
  @override
  final int startLine;
  @override
  final int endLine;
  @override
  final num score;

  factory _$ChatSource([void Function(ChatSourceBuilder)? updates]) =>
      (new ChatSourceBuilder()..update(updates))._build();

  _$ChatSource._(
      {required this.path,
      required this.symbol,
      required this.startLine,
      required this.endLine,
      required this.score})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(path, r'ChatSource', 'path');
    BuiltValueNullFieldError.checkNotNull(symbol, r'ChatSource', 'symbol');
    BuiltValueNullFieldError.checkNotNull(
        startLine, r'ChatSource', 'startLine');
    BuiltValueNullFieldError.checkNotNull(endLine, r'ChatSource', 'endLine');
    BuiltValueNullFieldError.checkNotNull(score, r'ChatSource', 'score');
  }

  @override
  ChatSource rebuild(void Function(ChatSourceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatSourceBuilder toBuilder() => new ChatSourceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatSource &&
        path == other.path &&
        symbol == other.symbol &&
        startLine == other.startLine &&
        endLine == other.endLine &&
        score == other.score;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, path.hashCode);
    _$hash = $jc(_$hash, symbol.hashCode);
    _$hash = $jc(_$hash, startLine.hashCode);
    _$hash = $jc(_$hash, endLine.hashCode);
    _$hash = $jc(_$hash, score.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatSource')
          ..add('path', path)
          ..add('symbol', symbol)
          ..add('startLine', startLine)
          ..add('endLine', endLine)
          ..add('score', score))
        .toString();
  }
}

class ChatSourceBuilder implements Builder<ChatSource, ChatSourceBuilder> {
  _$ChatSource? _$v;

  String? _path;
  String? get path => _$this._path;
  set path(String? path) => _$this._path = path;

  String? _symbol;
  String? get symbol => _$this._symbol;
  set symbol(String? symbol) => _$this._symbol = symbol;

  int? _startLine;
  int? get startLine => _$this._startLine;
  set startLine(int? startLine) => _$this._startLine = startLine;

  int? _endLine;
  int? get endLine => _$this._endLine;
  set endLine(int? endLine) => _$this._endLine = endLine;

  num? _score;
  num? get score => _$this._score;
  set score(num? score) => _$this._score = score;

  ChatSourceBuilder() {
    ChatSource._defaults(this);
  }

  ChatSourceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _path = $v.path;
      _symbol = $v.symbol;
      _startLine = $v.startLine;
      _endLine = $v.endLine;
      _score = $v.score;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatSource other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatSource;
  }

  @override
  void update(void Function(ChatSourceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatSource build() => _build();

  _$ChatSource _build() {
    final _$result = _$v ??
        new _$ChatSource._(
            path: BuiltValueNullFieldError.checkNotNull(
                path, r'ChatSource', 'path'),
            symbol: BuiltValueNullFieldError.checkNotNull(
                symbol, r'ChatSource', 'symbol'),
            startLine: BuiltValueNullFieldError.checkNotNull(
                startLine, r'ChatSource', 'startLine'),
            endLine: BuiltValueNullFieldError.checkNotNull(
                endLine, r'ChatSource', 'endLine'),
            score: BuiltValueNullFieldError.checkNotNull(
                score, r'ChatSource', 'score'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
