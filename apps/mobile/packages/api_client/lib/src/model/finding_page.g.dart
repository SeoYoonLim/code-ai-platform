// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finding_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FindingPage extends FindingPage {
  @override
  final BuiltList<Finding> items;
  @override
  final OffsetPageInfo page;

  factory _$FindingPage([void Function(FindingPageBuilder)? updates]) =>
      (new FindingPageBuilder()..update(updates))._build();

  _$FindingPage._({required this.items, required this.page}) : super._() {
    BuiltValueNullFieldError.checkNotNull(items, r'FindingPage', 'items');
    BuiltValueNullFieldError.checkNotNull(page, r'FindingPage', 'page');
  }

  @override
  FindingPage rebuild(void Function(FindingPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FindingPageBuilder toBuilder() => new FindingPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FindingPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'FindingPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class FindingPageBuilder implements Builder<FindingPage, FindingPageBuilder> {
  _$FindingPage? _$v;

  ListBuilder<Finding>? _items;
  ListBuilder<Finding> get items =>
      _$this._items ??= new ListBuilder<Finding>();
  set items(ListBuilder<Finding>? items) => _$this._items = items;

  OffsetPageInfoBuilder? _page;
  OffsetPageInfoBuilder get page =>
      _$this._page ??= new OffsetPageInfoBuilder();
  set page(OffsetPageInfoBuilder? page) => _$this._page = page;

  FindingPageBuilder() {
    FindingPage._defaults(this);
  }

  FindingPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FindingPage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$FindingPage;
  }

  @override
  void update(void Function(FindingPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FindingPage build() => _build();

  _$FindingPage _build() {
    _$FindingPage _$result;
    try {
      _$result =
          _$v ?? new _$FindingPage._(items: items.build(), page: page.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'FindingPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
