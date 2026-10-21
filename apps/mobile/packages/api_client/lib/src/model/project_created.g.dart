// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_created.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProjectCreated extends ProjectCreated {
  @override
  final Project project;
  @override
  final Job indexJob;

  factory _$ProjectCreated([void Function(ProjectCreatedBuilder)? updates]) =>
      (new ProjectCreatedBuilder()..update(updates))._build();

  _$ProjectCreated._({required this.project, required this.indexJob})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        project, r'ProjectCreated', 'project');
    BuiltValueNullFieldError.checkNotNull(
        indexJob, r'ProjectCreated', 'indexJob');
  }

  @override
  ProjectCreated rebuild(void Function(ProjectCreatedBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProjectCreatedBuilder toBuilder() =>
      new ProjectCreatedBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProjectCreated &&
        project == other.project &&
        indexJob == other.indexJob;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, project.hashCode);
    _$hash = $jc(_$hash, indexJob.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProjectCreated')
          ..add('project', project)
          ..add('indexJob', indexJob))
        .toString();
  }
}

class ProjectCreatedBuilder
    implements Builder<ProjectCreated, ProjectCreatedBuilder> {
  _$ProjectCreated? _$v;

  ProjectBuilder? _project;
  ProjectBuilder get project => _$this._project ??= new ProjectBuilder();
  set project(ProjectBuilder? project) => _$this._project = project;

  JobBuilder? _indexJob;
  JobBuilder get indexJob => _$this._indexJob ??= new JobBuilder();
  set indexJob(JobBuilder? indexJob) => _$this._indexJob = indexJob;

  ProjectCreatedBuilder() {
    ProjectCreated._defaults(this);
  }

  ProjectCreatedBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _project = $v.project.toBuilder();
      _indexJob = $v.indexJob.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProjectCreated other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProjectCreated;
  }

  @override
  void update(void Function(ProjectCreatedBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProjectCreated build() => _build();

  _$ProjectCreated _build() {
    _$ProjectCreated _$result;
    try {
      _$result = _$v ??
          new _$ProjectCreated._(
              project: project.build(), indexJob: indexJob.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'project';
        project.build();
        _$failedField = 'indexJob';
        indexJob.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ProjectCreated', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
