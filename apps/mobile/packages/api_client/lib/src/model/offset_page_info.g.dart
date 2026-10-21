// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offset_page_info.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OffsetPageInfo extends OffsetPageInfo {
  @override
  final int offset;
  @override
  final int limit;
  @override
  final int total;

  factory _$OffsetPageInfo([void Function(OffsetPageInfoBuilder)? updates]) =>
      (new OffsetPageInfoBuilder()..update(updates))._build();

  _$OffsetPageInfo._(
      {required this.offset, required this.limit, required this.total})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(offset, r'OffsetPageInfo', 'offset');
    BuiltValueNullFieldError.checkNotNull(limit, r'OffsetPageInfo', 'limit');
    BuiltValueNullFieldError.checkNotNull(total, r'OffsetPageInfo', 'total');
  }

  @override
  OffsetPageInfo rebuild(void Function(OffsetPageInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OffsetPageInfoBuilder toBuilder() =>
      new OffsetPageInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OffsetPageInfo &&
        offset == other.offset &&
        limit == other.limit &&
        total == other.total;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offset.hashCode);
    _$hash = $jc(_$hash, limit.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OffsetPageInfo')
          ..add('offset', offset)
          ..add('limit', limit)
          ..add('total', total))
        .toString();
  }
}

class OffsetPageInfoBuilder
    implements Builder<OffsetPageInfo, OffsetPageInfoBuilder> {
  _$OffsetPageInfo? _$v;

  int? _offset;
  int? get offset => _$this._offset;
  set offset(int? offset) => _$this._offset = offset;

  int? _limit;
  int? get limit => _$this._limit;
  set limit(int? limit) => _$this._limit = limit;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  OffsetPageInfoBuilder() {
    OffsetPageInfo._defaults(this);
  }

  OffsetPageInfoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _offset = $v.offset;
      _limit = $v.limit;
      _total = $v.total;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OffsetPageInfo other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OffsetPageInfo;
  }

  @override
  void update(void Function(OffsetPageInfoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OffsetPageInfo build() => _build();

  _$OffsetPageInfo _build() {
    final _$result = _$v ??
        new _$OffsetPageInfo._(
            offset: BuiltValueNullFieldError.checkNotNull(
                offset, r'OffsetPageInfo', 'offset'),
            limit: BuiltValueNullFieldError.checkNotNull(
                limit, r'OffsetPageInfo', 'limit'),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'OffsetPageInfo', 'total'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
