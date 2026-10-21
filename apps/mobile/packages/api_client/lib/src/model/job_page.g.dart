// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JobPage extends JobPage {
  @override
  final BuiltList<Job> items;
  @override
  final CursorPageInfo page;

  factory _$JobPage([void Function(JobPageBuilder)? updates]) =>
      (new JobPageBuilder()..update(updates))._build();

  _$JobPage._({required this.items, required this.page}) : super._() {
    BuiltValueNullFieldError.checkNotNull(items, r'JobPage', 'items');
    BuiltValueNullFieldError.checkNotNull(page, r'JobPage', 'page');
  }

  @override
  JobPage rebuild(void Function(JobPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobPageBuilder toBuilder() => new JobPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'JobPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class JobPageBuilder implements Builder<JobPage, JobPageBuilder> {
  _$JobPage? _$v;

  ListBuilder<Job>? _items;
  ListBuilder<Job> get items => _$this._items ??= new ListBuilder<Job>();
  set items(ListBuilder<Job>? items) => _$this._items = items;

  CursorPageInfoBuilder? _page;
  CursorPageInfoBuilder get page =>
      _$this._page ??= new CursorPageInfoBuilder();
  set page(CursorPageInfoBuilder? page) => _$this._page = page;

  JobPageBuilder() {
    JobPage._defaults(this);
  }

  JobPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobPage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$JobPage;
  }

  @override
  void update(void Function(JobPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobPage build() => _build();

  _$JobPage _build() {
    _$JobPage _$result;
    try {
      _$result =
          _$v ?? new _$JobPage._(items: items.build(), page: page.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'JobPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
