// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_progress.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JobProgress extends JobProgress {
  @override
  final int current;
  @override
  final int total;
  @override
  final String? phase;

  factory _$JobProgress([void Function(JobProgressBuilder)? updates]) =>
      (new JobProgressBuilder()..update(updates))._build();

  _$JobProgress._({required this.current, required this.total, this.phase})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(current, r'JobProgress', 'current');
    BuiltValueNullFieldError.checkNotNull(total, r'JobProgress', 'total');
  }

  @override
  JobProgress rebuild(void Function(JobProgressBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobProgressBuilder toBuilder() => new JobProgressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobProgress &&
        current == other.current &&
        total == other.total &&
        phase == other.phase;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, current.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, phase.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobProgress')
          ..add('current', current)
          ..add('total', total)
          ..add('phase', phase))
        .toString();
  }
}

class JobProgressBuilder implements Builder<JobProgress, JobProgressBuilder> {
  _$JobProgress? _$v;

  int? _current;
  int? get current => _$this._current;
  set current(int? current) => _$this._current = current;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  String? _phase;
  String? get phase => _$this._phase;
  set phase(String? phase) => _$this._phase = phase;

  JobProgressBuilder() {
    JobProgress._defaults(this);
  }

  JobProgressBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _current = $v.current;
      _total = $v.total;
      _phase = $v.phase;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobProgress other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$JobProgress;
  }

  @override
  void update(void Function(JobProgressBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobProgress build() => _build();

  _$JobProgress _build() {
    final _$result = _$v ??
        new _$JobProgress._(
            current: BuiltValueNullFieldError.checkNotNull(
                current, r'JobProgress', 'current'),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'JobProgress', 'total'),
            phase: phase);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
