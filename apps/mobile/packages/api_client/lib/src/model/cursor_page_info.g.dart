// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursor_page_info.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CursorPageInfo extends CursorPageInfo {
  @override
  final String? nextCursor;
  @override
  final bool hasMore;

  factory _$CursorPageInfo([void Function(CursorPageInfoBuilder)? updates]) =>
      (new CursorPageInfoBuilder()..update(updates))._build();

  _$CursorPageInfo._({this.nextCursor, required this.hasMore}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        hasMore, r'CursorPageInfo', 'hasMore');
  }

  @override
  CursorPageInfo rebuild(void Function(CursorPageInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CursorPageInfoBuilder toBuilder() =>
      new CursorPageInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CursorPageInfo &&
        nextCursor == other.nextCursor &&
        hasMore == other.hasMore;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, nextCursor.hashCode);
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CursorPageInfo')
          ..add('nextCursor', nextCursor)
          ..add('hasMore', hasMore))
        .toString();
  }
}

class CursorPageInfoBuilder
    implements Builder<CursorPageInfo, CursorPageInfoBuilder> {
  _$CursorPageInfo? _$v;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  CursorPageInfoBuilder() {
    CursorPageInfo._defaults(this);
  }

  CursorPageInfoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _nextCursor = $v.nextCursor;
      _hasMore = $v.hasMore;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CursorPageInfo other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CursorPageInfo;
  }

  @override
  void update(void Function(CursorPageInfoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CursorPageInfo build() => _build();

  _$CursorPageInfo _build() {
    final _$result = _$v ??
        new _$CursorPageInfo._(
            nextCursor: nextCursor,
            hasMore: BuiltValueNullFieldError.checkNotNull(
                hasMore, r'CursorPageInfo', 'hasMore'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
