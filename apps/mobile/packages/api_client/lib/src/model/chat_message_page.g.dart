// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChatMessagePage extends ChatMessagePage {
  @override
  final BuiltList<ChatMessage> items;
  @override
  final CursorPageInfo page;

  factory _$ChatMessagePage([void Function(ChatMessagePageBuilder)? updates]) =>
      (new ChatMessagePageBuilder()..update(updates))._build();

  _$ChatMessagePage._({required this.items, required this.page}) : super._() {
    BuiltValueNullFieldError.checkNotNull(items, r'ChatMessagePage', 'items');
    BuiltValueNullFieldError.checkNotNull(page, r'ChatMessagePage', 'page');
  }

  @override
  ChatMessagePage rebuild(void Function(ChatMessagePageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatMessagePageBuilder toBuilder() =>
      new ChatMessagePageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatMessagePage &&
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
    return (newBuiltValueToStringHelper(r'ChatMessagePage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class ChatMessagePageBuilder
    implements Builder<ChatMessagePage, ChatMessagePageBuilder> {
  _$ChatMessagePage? _$v;

  ListBuilder<ChatMessage>? _items;
  ListBuilder<ChatMessage> get items =>
      _$this._items ??= new ListBuilder<ChatMessage>();
  set items(ListBuilder<ChatMessage>? items) => _$this._items = items;

  CursorPageInfoBuilder? _page;
  CursorPageInfoBuilder get page =>
      _$this._page ??= new CursorPageInfoBuilder();
  set page(CursorPageInfoBuilder? page) => _$this._page = page;

  ChatMessagePageBuilder() {
    ChatMessagePage._defaults(this);
  }

  ChatMessagePageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatMessagePage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatMessagePage;
  }

  @override
  void update(void Function(ChatMessagePageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatMessagePage build() => _build();

  _$ChatMessagePage _build() {
    _$ChatMessagePage _$result;
    try {
      _$result = _$v ??
          new _$ChatMessagePage._(items: items.build(), page: page.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ChatMessagePage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
