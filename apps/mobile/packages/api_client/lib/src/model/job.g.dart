// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const JobTriggerEnum _$jobTriggerEnum_manual = const JobTriggerEnum._('manual');
const JobTriggerEnum _$jobTriggerEnum_webhook =
    const JobTriggerEnum._('webhook');
const JobTriggerEnum _$jobTriggerEnum_projectCreated =
    const JobTriggerEnum._('projectCreated');

JobTriggerEnum _$jobTriggerEnumValueOf(String name) {
  switch (name) {
    case 'manual':
      return _$jobTriggerEnum_manual;
    case 'webhook':
      return _$jobTriggerEnum_webhook;
    case 'projectCreated':
      return _$jobTriggerEnum_projectCreated;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<JobTriggerEnum> _$jobTriggerEnumValues =
    new BuiltSet<JobTriggerEnum>(const <JobTriggerEnum>[
  _$jobTriggerEnum_manual,
  _$jobTriggerEnum_webhook,
  _$jobTriggerEnum_projectCreated,
]);

Serializer<JobTriggerEnum> _$jobTriggerEnumSerializer =
    new _$JobTriggerEnumSerializer();

class _$JobTriggerEnumSerializer
    implements PrimitiveSerializer<JobTriggerEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'manual': 'manual',
    'webhook': 'webhook',
    'projectCreated': 'project_created',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'manual': 'manual',
    'webhook': 'webhook',
    'project_created': 'projectCreated',
  };

  @override
  final Iterable<Type> types = const <Type>[JobTriggerEnum];
  @override
  final String wireName = 'JobTriggerEnum';

  @override
  Object serialize(Serializers serializers, JobTriggerEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  JobTriggerEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      JobTriggerEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$Job extends Job {
  @override
  final String id;
  @override
  final JobKind kind;
  @override
  final JobStatus status;
  @override
  final String projectId;
  @override
  final String? resourceId;
  @override
  final JobTriggerEnum? trigger;
  @override
  final JobProgress? progress;
  @override
  final Problem? error;
  @override
  final DateTime createdAt;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? finishedAt;

  factory _$Job([void Function(JobBuilder)? updates]) =>
      (new JobBuilder()..update(updates))._build();

  _$Job._(
      {required this.id,
      required this.kind,
      required this.status,
      required this.projectId,
      this.resourceId,
      this.trigger,
      this.progress,
      this.error,
      required this.createdAt,
      this.startedAt,
      this.finishedAt})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'Job', 'id');
    BuiltValueNullFieldError.checkNotNull(kind, r'Job', 'kind');
    BuiltValueNullFieldError.checkNotNull(status, r'Job', 'status');
    BuiltValueNullFieldError.checkNotNull(projectId, r'Job', 'projectId');
    BuiltValueNullFieldError.checkNotNull(createdAt, r'Job', 'createdAt');
  }

  @override
  Job rebuild(void Function(JobBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobBuilder toBuilder() => new JobBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Job &&
        id == other.id &&
        kind == other.kind &&
        status == other.status &&
        projectId == other.projectId &&
        resourceId == other.resourceId &&
        trigger == other.trigger &&
        progress == other.progress &&
        error == other.error &&
        createdAt == other.createdAt &&
        startedAt == other.startedAt &&
        finishedAt == other.finishedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, projectId.hashCode);
    _$hash = $jc(_$hash, resourceId.hashCode);
    _$hash = $jc(_$hash, trigger.hashCode);
    _$hash = $jc(_$hash, progress.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, startedAt.hashCode);
    _$hash = $jc(_$hash, finishedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Job')
          ..add('id', id)
          ..add('kind', kind)
          ..add('status', status)
          ..add('projectId', projectId)
          ..add('resourceId', resourceId)
          ..add('trigger', trigger)
          ..add('progress', progress)
          ..add('error', error)
          ..add('createdAt', createdAt)
          ..add('startedAt', startedAt)
          ..add('finishedAt', finishedAt))
        .toString();
  }
}

class JobBuilder implements Builder<Job, JobBuilder> {
  _$Job? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  JobKind? _kind;
  JobKind? get kind => _$this._kind;
  set kind(JobKind? kind) => _$this._kind = kind;

  JobStatus? _status;
  JobStatus? get status => _$this._status;
  set status(JobStatus? status) => _$this._status = status;

  String? _projectId;
  String? get projectId => _$this._projectId;
  set projectId(String? projectId) => _$this._projectId = projectId;

  String? _resourceId;
  String? get resourceId => _$this._resourceId;
  set resourceId(String? resourceId) => _$this._resourceId = resourceId;

  JobTriggerEnum? _trigger;
  JobTriggerEnum? get trigger => _$this._trigger;
  set trigger(JobTriggerEnum? trigger) => _$this._trigger = trigger;

  JobProgressBuilder? _progress;
  JobProgressBuilder get progress =>
      _$this._progress ??= new JobProgressBuilder();
  set progress(JobProgressBuilder? progress) => _$this._progress = progress;

  ProblemBuilder? _error;
  ProblemBuilder get error => _$this._error ??= new ProblemBuilder();
  set error(ProblemBuilder? error) => _$this._error = error;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _startedAt;
  DateTime? get startedAt => _$this._startedAt;
  set startedAt(DateTime? startedAt) => _$this._startedAt = startedAt;

  DateTime? _finishedAt;
  DateTime? get finishedAt => _$this._finishedAt;
  set finishedAt(DateTime? finishedAt) => _$this._finishedAt = finishedAt;

  JobBuilder() {
    Job._defaults(this);
  }

  JobBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _kind = $v.kind;
      _status = $v.status;
      _projectId = $v.projectId;
      _resourceId = $v.resourceId;
      _trigger = $v.trigger;
      _progress = $v.progress?.toBuilder();
      _error = $v.error?.toBuilder();
      _createdAt = $v.createdAt;
      _startedAt = $v.startedAt;
      _finishedAt = $v.finishedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Job other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Job;
  }

  @override
  void update(void Function(JobBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Job build() => _build();

  _$Job _build() {
    _$Job _$result;
    try {
      _$result = _$v ??
          new _$Job._(
              id: BuiltValueNullFieldError.checkNotNull(id, r'Job', 'id'),
              kind: BuiltValueNullFieldError.checkNotNull(kind, r'Job', 'kind'),
              status: BuiltValueNullFieldError.checkNotNull(
                  status, r'Job', 'status'),
              projectId: BuiltValueNullFieldError.checkNotNull(
                  projectId, r'Job', 'projectId'),
              resourceId: resourceId,
              trigger: trigger,
              progress: _progress?.build(),
              error: _error?.build(),
              createdAt: BuiltValueNullFieldError.checkNotNull(
                  createdAt, r'Job', 'createdAt'),
              startedAt: startedAt,
              finishedAt: finishedAt);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'progress';
        _progress?.build();
        _$failedField = 'error';
        _error?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Job', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
