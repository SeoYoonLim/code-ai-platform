// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Analysis extends Analysis {
  @override
  final String id;
  @override
  final String projectId;
  @override
  final String jobId;
  @override
  final JobStatus status;
  @override
  final BuiltList<String> paths;
  @override
  final String? instruction;
  @override
  final String? commitSha;
  @override
  final String? summary;
  @override
  final FindingCounts? findingCounts;
  @override
  final String? model;
  @override
  final String? adapter;
  @override
  final Problem? error;
  @override
  final DateTime createdAt;
  @override
  final DateTime? completedAt;

  factory _$Analysis([void Function(AnalysisBuilder)? updates]) =>
      (new AnalysisBuilder()..update(updates))._build();

  _$Analysis._(
      {required this.id,
      required this.projectId,
      required this.jobId,
      required this.status,
      required this.paths,
      this.instruction,
      this.commitSha,
      this.summary,
      this.findingCounts,
      this.model,
      this.adapter,
      this.error,
      required this.createdAt,
      this.completedAt})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'Analysis', 'id');
    BuiltValueNullFieldError.checkNotNull(projectId, r'Analysis', 'projectId');
    BuiltValueNullFieldError.checkNotNull(jobId, r'Analysis', 'jobId');
    BuiltValueNullFieldError.checkNotNull(status, r'Analysis', 'status');
    BuiltValueNullFieldError.checkNotNull(paths, r'Analysis', 'paths');
    BuiltValueNullFieldError.checkNotNull(createdAt, r'Analysis', 'createdAt');
  }

  @override
  Analysis rebuild(void Function(AnalysisBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AnalysisBuilder toBuilder() => new AnalysisBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Analysis &&
        id == other.id &&
        projectId == other.projectId &&
        jobId == other.jobId &&
        status == other.status &&
        paths == other.paths &&
        instruction == other.instruction &&
        commitSha == other.commitSha &&
        summary == other.summary &&
        findingCounts == other.findingCounts &&
        model == other.model &&
        adapter == other.adapter &&
        error == other.error &&
        createdAt == other.createdAt &&
        completedAt == other.completedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, projectId.hashCode);
    _$hash = $jc(_$hash, jobId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, paths.hashCode);
    _$hash = $jc(_$hash, instruction.hashCode);
    _$hash = $jc(_$hash, commitSha.hashCode);
    _$hash = $jc(_$hash, summary.hashCode);
    _$hash = $jc(_$hash, findingCounts.hashCode);
    _$hash = $jc(_$hash, model.hashCode);
    _$hash = $jc(_$hash, adapter.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, completedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Analysis')
          ..add('id', id)
          ..add('projectId', projectId)
          ..add('jobId', jobId)
          ..add('status', status)
          ..add('paths', paths)
          ..add('instruction', instruction)
          ..add('commitSha', commitSha)
          ..add('summary', summary)
          ..add('findingCounts', findingCounts)
          ..add('model', model)
          ..add('adapter', adapter)
          ..add('error', error)
          ..add('createdAt', createdAt)
          ..add('completedAt', completedAt))
        .toString();
  }
}

class AnalysisBuilder implements Builder<Analysis, AnalysisBuilder> {
  _$Analysis? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _projectId;
  String? get projectId => _$this._projectId;
  set projectId(String? projectId) => _$this._projectId = projectId;

  String? _jobId;
  String? get jobId => _$this._jobId;
  set jobId(String? jobId) => _$this._jobId = jobId;

  JobStatus? _status;
  JobStatus? get status => _$this._status;
  set status(JobStatus? status) => _$this._status = status;

  ListBuilder<String>? _paths;
  ListBuilder<String> get paths => _$this._paths ??= new ListBuilder<String>();
  set paths(ListBuilder<String>? paths) => _$this._paths = paths;

  String? _instruction;
  String? get instruction => _$this._instruction;
  set instruction(String? instruction) => _$this._instruction = instruction;

  String? _commitSha;
  String? get commitSha => _$this._commitSha;
  set commitSha(String? commitSha) => _$this._commitSha = commitSha;

  String? _summary;
  String? get summary => _$this._summary;
  set summary(String? summary) => _$this._summary = summary;

  FindingCountsBuilder? _findingCounts;
  FindingCountsBuilder get findingCounts =>
      _$this._findingCounts ??= new FindingCountsBuilder();
  set findingCounts(FindingCountsBuilder? findingCounts) =>
      _$this._findingCounts = findingCounts;

  String? _model;
  String? get model => _$this._model;
  set model(String? model) => _$this._model = model;

  String? _adapter;
  String? get adapter => _$this._adapter;
  set adapter(String? adapter) => _$this._adapter = adapter;

  ProblemBuilder? _error;
  ProblemBuilder get error => _$this._error ??= new ProblemBuilder();
  set error(ProblemBuilder? error) => _$this._error = error;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _completedAt;
  DateTime? get completedAt => _$this._completedAt;
  set completedAt(DateTime? completedAt) => _$this._completedAt = completedAt;

  AnalysisBuilder() {
    Analysis._defaults(this);
  }

  AnalysisBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _projectId = $v.projectId;
      _jobId = $v.jobId;
      _status = $v.status;
      _paths = $v.paths.toBuilder();
      _instruction = $v.instruction;
      _commitSha = $v.commitSha;
      _summary = $v.summary;
      _findingCounts = $v.findingCounts?.toBuilder();
      _model = $v.model;
      _adapter = $v.adapter;
      _error = $v.error?.toBuilder();
      _createdAt = $v.createdAt;
      _completedAt = $v.completedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Analysis other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Analysis;
  }

  @override
  void update(void Function(AnalysisBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Analysis build() => _build();

  _$Analysis _build() {
    _$Analysis _$result;
    try {
      _$result = _$v ??
          new _$Analysis._(
              id: BuiltValueNullFieldError.checkNotNull(id, r'Analysis', 'id'),
              projectId: BuiltValueNullFieldError.checkNotNull(
                  projectId, r'Analysis', 'projectId'),
              jobId: BuiltValueNullFieldError.checkNotNull(
                  jobId, r'Analysis', 'jobId'),
              status: BuiltValueNullFieldError.checkNotNull(
                  status, r'Analysis', 'status'),
              paths: paths.build(),
              instruction: instruction,
              commitSha: commitSha,
              summary: summary,
              findingCounts: _findingCounts?.build(),
              model: model,
              adapter: adapter,
              error: _error?.build(),
              createdAt: BuiltValueNullFieldError.checkNotNull(
                  createdAt, r'Analysis', 'createdAt'),
              completedAt: completedAt);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'paths';
        paths.build();

        _$failedField = 'findingCounts';
        _findingCounts?.build();

        _$failedField = 'error';
        _error?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Analysis', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
