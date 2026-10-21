// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Project extends Project {
  @override
  final String id;
  @override
  final String name;
  @override
  final String repoUrl;
  @override
  final String defaultBranch;
  @override
  final BuiltList<String>? includeGlobs;
  @override
  final BuiltList<String>? excludeGlobs;
  @override
  final IndexState indexState;
  @override
  final String? lastIndexedCommit;
  @override
  final DateTime? lastIndexedAt;
  @override
  final ProjectStats? stats;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$Project([void Function(ProjectBuilder)? updates]) =>
      (new ProjectBuilder()..update(updates))._build();

  _$Project._(
      {required this.id,
      required this.name,
      required this.repoUrl,
      required this.defaultBranch,
      this.includeGlobs,
      this.excludeGlobs,
      required this.indexState,
      this.lastIndexedCommit,
      this.lastIndexedAt,
      this.stats,
      required this.createdAt,
      required this.updatedAt})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'Project', 'id');
    BuiltValueNullFieldError.checkNotNull(name, r'Project', 'name');
    BuiltValueNullFieldError.checkNotNull(repoUrl, r'Project', 'repoUrl');
    BuiltValueNullFieldError.checkNotNull(
        defaultBranch, r'Project', 'defaultBranch');
    BuiltValueNullFieldError.checkNotNull(indexState, r'Project', 'indexState');
    BuiltValueNullFieldError.checkNotNull(createdAt, r'Project', 'createdAt');
    BuiltValueNullFieldError.checkNotNull(updatedAt, r'Project', 'updatedAt');
  }

  @override
  Project rebuild(void Function(ProjectBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProjectBuilder toBuilder() => new ProjectBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Project &&
        id == other.id &&
        name == other.name &&
        repoUrl == other.repoUrl &&
        defaultBranch == other.defaultBranch &&
        includeGlobs == other.includeGlobs &&
        excludeGlobs == other.excludeGlobs &&
        indexState == other.indexState &&
        lastIndexedCommit == other.lastIndexedCommit &&
        lastIndexedAt == other.lastIndexedAt &&
        stats == other.stats &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, repoUrl.hashCode);
    _$hash = $jc(_$hash, defaultBranch.hashCode);
    _$hash = $jc(_$hash, includeGlobs.hashCode);
    _$hash = $jc(_$hash, excludeGlobs.hashCode);
    _$hash = $jc(_$hash, indexState.hashCode);
    _$hash = $jc(_$hash, lastIndexedCommit.hashCode);
    _$hash = $jc(_$hash, lastIndexedAt.hashCode);
    _$hash = $jc(_$hash, stats.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Project')
          ..add('id', id)
          ..add('name', name)
          ..add('repoUrl', repoUrl)
          ..add('defaultBranch', defaultBranch)
          ..add('includeGlobs', includeGlobs)
          ..add('excludeGlobs', excludeGlobs)
          ..add('indexState', indexState)
          ..add('lastIndexedCommit', lastIndexedCommit)
          ..add('lastIndexedAt', lastIndexedAt)
          ..add('stats', stats)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class ProjectBuilder implements Builder<Project, ProjectBuilder> {
  _$Project? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _repoUrl;
  String? get repoUrl => _$this._repoUrl;
  set repoUrl(String? repoUrl) => _$this._repoUrl = repoUrl;

  String? _defaultBranch;
  String? get defaultBranch => _$this._defaultBranch;
  set defaultBranch(String? defaultBranch) =>
      _$this._defaultBranch = defaultBranch;

  ListBuilder<String>? _includeGlobs;
  ListBuilder<String> get includeGlobs =>
      _$this._includeGlobs ??= new ListBuilder<String>();
  set includeGlobs(ListBuilder<String>? includeGlobs) =>
      _$this._includeGlobs = includeGlobs;

  ListBuilder<String>? _excludeGlobs;
  ListBuilder<String> get excludeGlobs =>
      _$this._excludeGlobs ??= new ListBuilder<String>();
  set excludeGlobs(ListBuilder<String>? excludeGlobs) =>
      _$this._excludeGlobs = excludeGlobs;

  IndexState? _indexState;
  IndexState? get indexState => _$this._indexState;
  set indexState(IndexState? indexState) => _$this._indexState = indexState;

  String? _lastIndexedCommit;
  String? get lastIndexedCommit => _$this._lastIndexedCommit;
  set lastIndexedCommit(String? lastIndexedCommit) =>
      _$this._lastIndexedCommit = lastIndexedCommit;

  DateTime? _lastIndexedAt;
  DateTime? get lastIndexedAt => _$this._lastIndexedAt;
  set lastIndexedAt(DateTime? lastIndexedAt) =>
      _$this._lastIndexedAt = lastIndexedAt;

  ProjectStatsBuilder? _stats;
  ProjectStatsBuilder get stats => _$this._stats ??= new ProjectStatsBuilder();
  set stats(ProjectStatsBuilder? stats) => _$this._stats = stats;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ProjectBuilder() {
    Project._defaults(this);
  }

  ProjectBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _repoUrl = $v.repoUrl;
      _defaultBranch = $v.defaultBranch;
      _includeGlobs = $v.includeGlobs?.toBuilder();
      _excludeGlobs = $v.excludeGlobs?.toBuilder();
      _indexState = $v.indexState;
      _lastIndexedCommit = $v.lastIndexedCommit;
      _lastIndexedAt = $v.lastIndexedAt;
      _stats = $v.stats?.toBuilder();
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Project other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Project;
  }

  @override
  void update(void Function(ProjectBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Project build() => _build();

  _$Project _build() {
    _$Project _$result;
    try {
      _$result = _$v ??
          new _$Project._(
              id: BuiltValueNullFieldError.checkNotNull(id, r'Project', 'id'),
              name: BuiltValueNullFieldError.checkNotNull(
                  name, r'Project', 'name'),
              repoUrl: BuiltValueNullFieldError.checkNotNull(
                  repoUrl, r'Project', 'repoUrl'),
              defaultBranch: BuiltValueNullFieldError.checkNotNull(
                  defaultBranch, r'Project', 'defaultBranch'),
              includeGlobs: _includeGlobs?.build(),
              excludeGlobs: _excludeGlobs?.build(),
              indexState: BuiltValueNullFieldError.checkNotNull(
                  indexState, r'Project', 'indexState'),
              lastIndexedCommit: lastIndexedCommit,
              lastIndexedAt: lastIndexedAt,
              stats: _stats?.build(),
              createdAt: BuiltValueNullFieldError.checkNotNull(
                  createdAt, r'Project', 'createdAt'),
              updatedAt: BuiltValueNullFieldError.checkNotNull(
                  updatedAt, r'Project', 'updatedAt'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'includeGlobs';
        _includeGlobs?.build();
        _$failedField = 'excludeGlobs';
        _excludeGlobs?.build();

        _$failedField = 'stats';
        _stats?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Project', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
