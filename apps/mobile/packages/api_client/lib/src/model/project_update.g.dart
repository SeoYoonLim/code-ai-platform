// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProjectUpdate extends ProjectUpdate {
  @override
  final String? name;
  @override
  final String? defaultBranch;
  @override
  final BuiltList<String>? includeGlobs;
  @override
  final BuiltList<String>? excludeGlobs;

  factory _$ProjectUpdate([void Function(ProjectUpdateBuilder)? updates]) =>
      (new ProjectUpdateBuilder()..update(updates))._build();

  _$ProjectUpdate._(
      {this.name, this.defaultBranch, this.includeGlobs, this.excludeGlobs})
      : super._();

  @override
  ProjectUpdate rebuild(void Function(ProjectUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProjectUpdateBuilder toBuilder() => new ProjectUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProjectUpdate &&
        name == other.name &&
        defaultBranch == other.defaultBranch &&
        includeGlobs == other.includeGlobs &&
        excludeGlobs == other.excludeGlobs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, defaultBranch.hashCode);
    _$hash = $jc(_$hash, includeGlobs.hashCode);
    _$hash = $jc(_$hash, excludeGlobs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProjectUpdate')
          ..add('name', name)
          ..add('defaultBranch', defaultBranch)
          ..add('includeGlobs', includeGlobs)
          ..add('excludeGlobs', excludeGlobs))
        .toString();
  }
}

class ProjectUpdateBuilder
    implements Builder<ProjectUpdate, ProjectUpdateBuilder> {
  _$ProjectUpdate? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

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

  ProjectUpdateBuilder() {
    ProjectUpdate._defaults(this);
  }

  ProjectUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _defaultBranch = $v.defaultBranch;
      _includeGlobs = $v.includeGlobs?.toBuilder();
      _excludeGlobs = $v.excludeGlobs?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProjectUpdate other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProjectUpdate;
  }

  @override
  void update(void Function(ProjectUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProjectUpdate build() => _build();

  _$ProjectUpdate _build() {
    _$ProjectUpdate _$result;
    try {
      _$result = _$v ??
          new _$ProjectUpdate._(
              name: name,
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
            r'ProjectUpdate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
