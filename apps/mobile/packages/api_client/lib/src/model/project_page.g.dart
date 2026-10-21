// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProjectPage extends ProjectPage {
  @override
  final BuiltList<Project> items;
  @override
  final CursorPageInfo page;

  factory _$ProjectPage([void Function(ProjectPageBuilder)? updates]) =>
      (new ProjectPageBuilder()..update(updates))._build();

  _$ProjectPage._({required this.items, required this.page}) : super._() {
    BuiltValueNullFieldError.checkNotNull(items, r'ProjectPage', 'items');
    BuiltValueNullFieldError.checkNotNull(page, r'ProjectPage', 'page');
  }

  @override
  ProjectPage rebuild(void Function(ProjectPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProjectPageBuilder toBuilder() => new ProjectPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProjectPage && items == other.items && page == other.page;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProjectPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class ProjectPageBuilder implements Builder<ProjectPage, ProjectPageBuilder> {
  _$ProjectPage? _$v;

  ListBuilder<Project>? _items;
  ListBuilder<Project> get items =>
      _$this._items ??= new ListBuilder<Project>();
  set items(ListBuilder<Project>? items) => _$this._items = items;

  CursorPageInfoBuilder? _page;
  CursorPageInfoBuilder get page =>
      _$this._page ??= new CursorPageInfoBuilder();
  set page(CursorPageInfoBuilder? page) => _$this._page = page;

  ProjectPageBuilder() {
    ProjectPage._defaults(this);
  }

  ProjectPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProjectPage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProjectPage;
  }

  @override
  void update(void Function(ProjectPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProjectPage build() => _build();

  _$ProjectPage _build() {
    _$ProjectPage _$result;
    try {
      _$result =
          _$v ?? new _$ProjectPage._(items: items.build(), page: page.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ProjectPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
