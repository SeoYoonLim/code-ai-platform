// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refactor.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Refactor extends Refactor {
  @override
  final String id;
  @override
  final String projectId;
  @override
  final String jobId;
  @override
  final JobStatus status;
  @override
  final CodeTarget target;
  @override
  final String instruction;
  @override
  final String? analysisId;
  @override
  final String? findingId;
  @override
  final String? diff;
  @override
  final String? explanation;
  @override
  final PatchValidation? validation;
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

  factory _$Refactor([void Function(RefactorBuilder)? updates]) =>
      (new RefactorBuilder()..update(updates))._build();

  _$Refactor._(
      {required this.id,
      required this.projectId,
      required this.jobId,
      required this.status,
      required this.target,
      required this.instruction,
      this.analysisId,
      this.findingId,
      this.diff,
      this.explanation,
      this.validation,
      this.model,
      this.adapter,
      this.error,
      required this.createdAt,
      this.completedAt})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'Refactor', 'id');
    BuiltValueNullFieldError.checkNotNull(projectId, r'Refactor', 'projectId');
    BuiltValueNullFieldError.checkNotNull(jobId, r'Refactor', 'jobId');
    BuiltValueNullFieldError.checkNotNull(status, r'Refactor', 'status');
    BuiltValueNullFieldError.checkNotNull(target, r'Refactor', 'target');
    BuiltValueNullFieldError.checkNotNull(
        instruction, r'Refactor', 'instruction');
    BuiltValueNullFieldError.checkNotNull(createdAt, r'Refactor', 'createdAt');
  }

  @override
  Refactor rebuild(void Function(RefactorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RefactorBuilder toBuilder() => new RefactorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Refactor &&
        id == other.id &&
        projectId == other.projectId &&
        jobId == other.jobId &&
        status == other.status &&
        target == other.target &&
        instruction == other.instruction &&
        analysisId == other.analysisId &&
        findingId == other.findingId &&
        diff == other.diff &&
        explanation == other.explanation &&
        validation == other.validation &&
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
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jc(_$hash, instruction.hashCode);
    _$hash = $jc(_$hash, analysisId.hashCode);
    _$hash = $jc(_$hash, findingId.hashCode);
    _$hash = $jc(_$hash, diff.hashCode);
    _$hash = $jc(_$hash, explanation.hashCode);
    _$hash = $jc(_$hash, validation.hashCode);
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
    return (newBuiltValueToStringHelper(r'Refactor')
          ..add('id', id)
          ..add('projectId', projectId)
          ..add('jobId', jobId)
          ..add('status', status)
          ..add('target', target)
          ..add('instruction', instruction)
          ..add('analysisId', analysisId)
          ..add('findingId', findingId)
          ..add('diff', diff)
          ..add('explanation', explanation)
          ..add('validation', validation)
          ..add('model', model)
          ..add('adapter', adapter)
          ..add('error', error)
          ..add('createdAt', createdAt)
          ..add('completedAt', completedAt))
        .toString();
  }
}

class RefactorBuilder implements Builder<Refactor, RefactorBuilder> {
  _$Refactor? _$v;

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

  CodeTargetBuilder? _target;
  CodeTargetBuilder get target => _$this._target ??= new CodeTargetBuilder();
  set target(CodeTargetBuilder? target) => _$this._target = target;

  String? _instruction;
  String? get instruction => _$this._instruction;
  set instruction(String? instruction) => _$this._instruction = instruction;

  String? _analysisId;
  String? get analysisId => _$this._analysisId;
  set analysisId(String? analysisId) => _$this._analysisId = analysisId;

  String? _findingId;
  String? get findingId => _$this._findingId;
  set findingId(String? findingId) => _$this._findingId = findingId;

  String? _diff;
  String? get diff => _$this._diff;
  set diff(String? diff) => _$this._diff = diff;

  String? _explanation;
  String? get explanation => _$this._explanation;
  set explanation(String? explanation) => _$this._explanation = explanation;

  PatchValidationBuilder? _validation;
  PatchValidationBuilder get validation =>
      _$this._validation ??= new PatchValidationBuilder();
  set validation(PatchValidationBuilder? validation) =>
      _$this._validation = validation;

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

  RefactorBuilder() {
    Refactor._defaults(this);
  }

  RefactorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _projectId = $v.projectId;
      _jobId = $v.jobId;
      _status = $v.status;
      _target = $v.target.toBuilder();
      _instruction = $v.instruction;
      _analysisId = $v.analysisId;
      _findingId = $v.findingId;
      _diff = $v.diff;
      _explanation = $v.explanation;
      _validation = $v.validation?.toBuilder();
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
  void replace(Refactor other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Refactor;
  }

  @override
  void update(void Function(RefactorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Refactor build() => _build();

  _$Refactor _build() {
    _$Refactor _$result;
    try {
      _$result = _$v ??
          new _$Refactor._(
              id: BuiltValueNullFieldError.checkNotNull(id, r'Refactor', 'id'),
              projectId: BuiltValueNullFieldError.checkNotNull(
                  projectId, r'Refactor', 'projectId'),
              jobId: BuiltValueNullFieldError.checkNotNull(
                  jobId, r'Refactor', 'jobId'),
              status: BuiltValueNullFieldError.checkNotNull(
                  status, r'Refactor', 'status'),
              target: target.build(),
              instruction: BuiltValueNullFieldError.checkNotNull(
                  instruction, r'Refactor', 'instruction'),
              analysisId: analysisId,
              findingId: findingId,
              diff: diff,
              explanation: explanation,
              validation: _validation?.build(),
              model: model,
              adapter: adapter,
              error: _error?.build(),
              createdAt: BuiltValueNullFieldError.checkNotNull(
                  createdAt, r'Refactor', 'createdAt'),
              completedAt: completedAt);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'target';
        target.build();

        _$failedField = 'validation';
        _validation?.build();

        _$failedField = 'error';
        _error?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Refactor', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
