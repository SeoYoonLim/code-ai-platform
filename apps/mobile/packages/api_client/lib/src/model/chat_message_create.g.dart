// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChatMessageCreate extends ChatMessageCreate {
  @override
  final String? sessionId;
  @override
  final String content;
  @override
  final BuiltList<String>? contextPaths;

  factory _$ChatMessageCreate(
          [void Function(ChatMessageCreateBuilder)? updates]) =>
      (new ChatMessageCreateBuilder()..update(updates))._build();

  _$ChatMessageCreate._(
      {this.sessionId, required this.content, this.contextPaths})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        content, r'ChatMessageCreate', 'content');
  }

  @override
  ChatMessageCreate rebuild(void Function(ChatMessageCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatMessageCreateBuilder toBuilder() =>
      new ChatMessageCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatMessageCreate &&
        sessionId == other.sessionId &&
        content == other.content &&
        contextPaths == other.contextPaths;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, contextPaths.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatMessageCreate')
          ..add('sessionId', sessionId)
          ..add('content', content)
          ..add('contextPaths', contextPaths))
        .toString();
  }
}

class ChatMessageCreateBuilder
    implements Builder<ChatMessageCreate, ChatMessageCreateBuilder> {
  _$ChatMessageCreate? _$v;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  ListBuilder<String>? _contextPaths;
  ListBuilder<String> get contextPaths =>
      _$this._contextPaths ??= new ListBuilder<String>();
  set contextPaths(ListBuilder<String>? contextPaths) =>
      _$this._contextPaths = contextPaths;

  ChatMessageCreateBuilder() {
    ChatMessageCreate._defaults(this);
  }

  ChatMessageCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _sessionId = $v.sessionId;
      _content = $v.content;
      _contextPaths = $v.contextPaths?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatMessageCreate other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatMessageCreate;
  }

  @override
  void update(void Function(ChatMessageCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatMessageCreate build() => _build();

  _$ChatMessageCreate _build() {
    _$ChatMessageCreate _$result;
    try {
      _$result = _$v ??
          new _$ChatMessageCreate._(
              sessionId: sessionId,
              content: BuiltValueNullFieldError.checkNotNull(
                  content, r'ChatMessageCreate', 'content'),
              contextPaths: _contextPaths?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'contextPaths';
        _contextPaths?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ChatMessageCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
