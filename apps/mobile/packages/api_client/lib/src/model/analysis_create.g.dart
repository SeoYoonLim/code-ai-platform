// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AnalysisCreate extends AnalysisCreate {
  @override
  final BuiltList<String> paths;
  @override
  final String? instruction;
  @override
  final BuiltList<FindingCategory>? categories;

  factory _$AnalysisCreate([void Function(AnalysisCreateBuilder)? updates]) =>
      (new AnalysisCreateBuilder()..update(updates))._build();

  _$AnalysisCreate._({required this.paths, this.instruction, this.categories})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(paths, r'AnalysisCreate', 'paths');
  }

  @override
  AnalysisCreate rebuild(void Function(AnalysisCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AnalysisCreateBuilder toBuilder() =>
      new AnalysisCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AnalysisCreate &&
        paths == other.paths &&
        instruction == other.instruction &&
        categories == other.categories;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, paths.hashCode);
    _$hash = $jc(_$hash, instruction.hashCode);
    _$hash = $jc(_$hash, categories.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AnalysisCreate')
          ..add('paths', paths)
          ..add('instruction', instruction)
          ..add('categories', categories))
        .toString();
  }
}

class AnalysisCreateBuilder
    implements Builder<AnalysisCreate, AnalysisCreateBuilder> {
  _$AnalysisCreate? _$v;

  ListBuilder<String>? _paths;
  ListBuilder<String> get paths => _$this._paths ??= new ListBuilder<String>();
  set paths(ListBuilder<String>? paths) => _$this._paths = paths;

  String? _instruction;
  String? get instruction => _$this._instruction;
  set instruction(String? instruction) => _$this._instruction = instruction;

  ListBuilder<FindingCategory>? _categories;
  ListBuilder<FindingCategory> get categories =>
      _$this._categories ??= new ListBuilder<FindingCategory>();
  set categories(ListBuilder<FindingCategory>? categories) =>
      _$this._categories = categories;

  AnalysisCreateBuilder() {
    AnalysisCreate._defaults(this);
  }

  AnalysisCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _paths = $v.paths.toBuilder();
      _instruction = $v.instruction;
      _categories = $v.categories?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AnalysisCreate other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AnalysisCreate;
  }

  @override
  void update(void Function(AnalysisCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AnalysisCreate build() => _build();

  _$AnalysisCreate _build() {
    _$AnalysisCreate _$result;
    try {
      _$result = _$v ??
          new _$AnalysisCreate._(
              paths: paths.build(),
              instruction: instruction,
              categories: _categories?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'paths';
        paths.build();

        _$failedField = 'categories';
        _categories?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'AnalysisCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
