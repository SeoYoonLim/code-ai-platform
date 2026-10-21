// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AnalysisPage extends AnalysisPage {
  @override
  final BuiltList<Analysis> items;
  @override
  final CursorPageInfo page;

  factory _$AnalysisPage([void Function(AnalysisPageBuilder)? updates]) =>
      (new AnalysisPageBuilder()..update(updates))._build();

  _$AnalysisPage._({required this.items, required this.page}) : super._() {
    BuiltValueNullFieldError.checkNotNull(items, r'AnalysisPage', 'items');
    BuiltValueNullFieldError.checkNotNull(page, r'AnalysisPage', 'page');
  }

  @override
  AnalysisPage rebuild(void Function(AnalysisPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AnalysisPageBuilder toBuilder() => new AnalysisPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AnalysisPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'AnalysisPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class AnalysisPageBuilder
    implements Builder<AnalysisPage, AnalysisPageBuilder> {
  _$AnalysisPage? _$v;

  ListBuilder<Analysis>? _items;
  ListBuilder<Analysis> get items =>
      _$this._items ??= new ListBuilder<Analysis>();
  set items(ListBuilder<Analysis>? items) => _$this._items = items;

  CursorPageInfoBuilder? _page;
  CursorPageInfoBuilder get page =>
      _$this._page ??= new CursorPageInfoBuilder();
  set page(CursorPageInfoBuilder? page) => _$this._page = page;

  AnalysisPageBuilder() {
    AnalysisPage._defaults(this);
  }

  AnalysisPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AnalysisPage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AnalysisPage;
  }

  @override
  void update(void Function(AnalysisPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AnalysisPage build() => _build();

  _$AnalysisPage _build() {
    _$AnalysisPage _$result;
    try {
      _$result =
          _$v ?? new _$AnalysisPage._(items: items.build(), page: page.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'AnalysisPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
