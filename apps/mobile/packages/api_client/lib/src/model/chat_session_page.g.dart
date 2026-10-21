// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChatSessionPage extends ChatSessionPage {
  @override
  final BuiltList<ChatSession> items;
  @override
  final CursorPageInfo page;

  factory _$ChatSessionPage([void Function(ChatSessionPageBuilder)? updates]) =>
      (new ChatSessionPageBuilder()..update(updates))._build();

  _$ChatSessionPage._({required this.items, required this.page}) : super._() {
    BuiltValueNullFieldError.checkNotNull(items, r'ChatSessionPage', 'items');
    BuiltValueNullFieldError.checkNotNull(page, r'ChatSessionPage', 'page');
  }

  @override
  ChatSessionPage rebuild(void Function(ChatSessionPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatSessionPageBuilder toBuilder() =>
      new ChatSessionPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatSessionPage &&
        items == other.items &&
        page == other.page;
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
    return (newBuiltValueToStringHelper(r'ChatSessionPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class ChatSessionPageBuilder
    implements Builder<ChatSessionPage, ChatSessionPageBuilder> {
  _$ChatSessionPage? _$v;

  ListBuilder<ChatSession>? _items;
  ListBuilder<ChatSession> get items =>
      _$this._items ??= new ListBuilder<ChatSession>();
  set items(ListBuilder<ChatSession>? items) => _$this._items = items;

  CursorPageInfoBuilder? _page;
  CursorPageInfoBuilder get page =>
      _$this._page ??= new CursorPageInfoBuilder();
  set page(CursorPageInfoBuilder? page) => _$this._page = page;

  ChatSessionPageBuilder() {
    ChatSessionPage._defaults(this);
  }

  ChatSessionPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatSessionPage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatSessionPage;
  }

  @override
  void update(void Function(ChatSessionPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatSessionPage build() => _build();

  _$ChatSessionPage _build() {
    _$ChatSessionPage _$result;
    try {
      _$result = _$v ??
          new _$ChatSessionPage._(items: items.build(), page: page.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ChatSessionPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
