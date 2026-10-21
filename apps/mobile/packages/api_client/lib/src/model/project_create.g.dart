// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProjectCreate extends ProjectCreate {
  @override
  final String name;
  @override
  final String repoUrl;
  @override
  final String? defaultBranch;
  @override
  final BuiltList<String>? includeGlobs;
  @override
  final BuiltList<String>? excludeGlobs;

  factory _$ProjectCreate([void Function(ProjectCreateBuilder)? updates]) =>
      (new ProjectCreateBuilder()..update(updates))._build();

  _$ProjectCreate._(
      {required this.name,
      required this.repoUrl,
      this.defaultBranch,
      this.includeGlobs,
      this.excludeGlobs})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(name, r'ProjectCreate', 'name');
    BuiltValueNullFieldError.checkNotNull(repoUrl, r'ProjectCreate', 'repoUrl');
  }

  @override
  ProjectCreate rebuild(void Function(ProjectCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProjectCreateBuilder toBuilder() => new ProjectCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProjectCreate &&
        name == other.name &&
        repoUrl == other.repoUrl &&
        defaultBranch == other.defaultBranch &&
        includeGlobs == other.includeGlobs &&
        excludeGlobs == other.excludeGlobs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, repoUrl.hashCode);
    _$hash = $jc(_$hash, defaultBranch.hashCode);
    _$hash = $jc(_$hash, includeGlobs.hashCode);
    _$hash = $jc(_$hash, excludeGlobs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProjectCreate')
          ..add('name', name)
          ..add('repoUrl', repoUrl)
          ..add('defaultBranch', defaultBranch)
          ..add('includeGlobs', includeGlobs)
          ..add('excludeGlobs', excludeGlobs))
        .toString();
  }
}

class ProjectCreateBuilder
    implements Builder<ProjectCreate, ProjectCreateBuilder> {
  _$ProjectCreate? _$v;

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

  ProjectCreateBuilder() {
    ProjectCreate._defaults(this);
  }

  ProjectCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _repoUrl = $v.repoUrl;
      _defaultBranch = $v.defaultBranch;
      _includeGlobs = $v.includeGlobs?.toBuilder();
      _excludeGlobs = $v.excludeGlobs?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProjectCreate other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProjectCreate;
  }

  @override
  void update(void Function(ProjectCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProjectCreate build() => _build();

  _$ProjectCreate _build() {
    _$ProjectCreate _$result;
    try {
      _$result = _$v ??
          new _$ProjectCreate._(
              name: BuiltValueNullFieldError.checkNotNull(
                  name, r'ProjectCreate', 'name'),
              repoUrl: BuiltValueNullFieldError.checkNotNull(
                  repoUrl, r'ProjectCreate', 'repoUrl'),
              defaultBranch: defaultBranch,
              includeGlobs: _includeGlobs?.build(),
              excludeGlobs: _excludeGlobs?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'includeGlobs';
        _includeGlobs?.build();
        _$failedField = 'excludeGlobs';
        _excludeGlobs?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ProjectCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
