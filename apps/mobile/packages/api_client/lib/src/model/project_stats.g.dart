// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProjectStats extends ProjectStats {
  @override
  final int? fileCount;
  @override
  final int? chunkCount;

  factory _$ProjectStats([void Function(ProjectStatsBuilder)? updates]) =>
      (new ProjectStatsBuilder()..update(updates))._build();

  _$ProjectStats._({this.fileCount, this.chunkCount}) : super._();

  @override
  ProjectStats rebuild(void Function(ProjectStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProjectStatsBuilder toBuilder() => new ProjectStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProjectStats &&
        fileCount == other.fileCount &&
        chunkCount == other.chunkCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fileCount.hashCode);
    _$hash = $jc(_$hash, chunkCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProjectStats')
          ..add('fileCount', fileCount)
          ..add('chunkCount', chunkCount))
        .toString();
  }
}

class ProjectStatsBuilder
    implements Builder<ProjectStats, ProjectStatsBuilder> {
  _$ProjectStats? _$v;

  int? _fileCount;
  int? get fileCount => _$this._fileCount;
  set fileCount(int? fileCount) => _$this._fileCount = fileCount;

  int? _chunkCount;
  int? get chunkCount => _$this._chunkCount;
  set chunkCount(int? chunkCount) => _$this._chunkCount = chunkCount;

  ProjectStatsBuilder() {
    ProjectStats._defaults(this);
  }

  ProjectStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fileCount = $v.fileCount;
      _chunkCount = $v.chunkCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProjectStats other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProjectStats;
  }

  @override
  void update(void Function(ProjectStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProjectStats build() => _build();

  _$ProjectStats _build() {
    final _$result = _$v ??
        new _$ProjectStats._(fileCount: fileCount, chunkCount: chunkCount);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
