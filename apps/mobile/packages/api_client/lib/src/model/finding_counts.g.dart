// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finding_counts.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FindingCounts extends FindingCounts {
  @override
  final int info;
  @override
  final int minor;
  @override
  final int major;
  @override
  final int critical;

  factory _$FindingCounts([void Function(FindingCountsBuilder)? updates]) =>
      (new FindingCountsBuilder()..update(updates))._build();

  _$FindingCounts._(
      {required this.info,
      required this.minor,
      required this.major,
      required this.critical})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(info, r'FindingCounts', 'info');
    BuiltValueNullFieldError.checkNotNull(minor, r'FindingCounts', 'minor');
    BuiltValueNullFieldError.checkNotNull(major, r'FindingCounts', 'major');
    BuiltValueNullFieldError.checkNotNull(
        critical, r'FindingCounts', 'critical');
  }

  @override
  FindingCounts rebuild(void Function(FindingCountsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FindingCountsBuilder toBuilder() => new FindingCountsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FindingCounts &&
        info == other.info &&
        minor == other.minor &&
        major == other.major &&
        critical == other.critical;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, info.hashCode);
    _$hash = $jc(_$hash, minor.hashCode);
    _$hash = $jc(_$hash, major.hashCode);
    _$hash = $jc(_$hash, critical.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FindingCounts')
          ..add('info', info)
          ..add('minor', minor)
          ..add('major', major)
          ..add('critical', critical))
        .toString();
  }
}

class FindingCountsBuilder
    implements Builder<FindingCounts, FindingCountsBuilder> {
  _$FindingCounts? _$v;

  int? _info;
  int? get info => _$this._info;
  set info(int? info) => _$this._info = info;

  int? _minor;
  int? get minor => _$this._minor;
  set minor(int? minor) => _$this._minor = minor;

  int? _major;
  int? get major => _$this._major;
  set major(int? major) => _$this._major = major;

  int? _critical;
  int? get critical => _$this._critical;
  set critical(int? critical) => _$this._critical = critical;

  FindingCountsBuilder() {
    FindingCounts._defaults(this);
  }

  FindingCountsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _info = $v.info;
      _minor = $v.minor;
      _major = $v.major;
      _critical = $v.critical;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FindingCounts other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$FindingCounts;
  }

  @override
  void update(void Function(FindingCountsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FindingCounts build() => _build();

  _$FindingCounts _build() {
    final _$result = _$v ??
        new _$FindingCounts._(
            info: BuiltValueNullFieldError.checkNotNull(
                info, r'FindingCounts', 'info'),
            minor: BuiltValueNullFieldError.checkNotNull(
                minor, r'FindingCounts', 'minor'),
            major: BuiltValueNullFieldError.checkNotNull(
                major, r'FindingCounts', 'major'),
            critical: BuiltValueNullFieldError.checkNotNull(
                critical, r'FindingCounts', 'critical'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
