// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChatSession extends ChatSession {
  @override
  final String id;
  @override
  final String projectId;
  @override
  final String title;
  @override
  final int? messageCount;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$ChatSession([void Function(ChatSessionBuilder)? updates]) =>
      (new ChatSessionBuilder()..update(updates))._build();

  _$ChatSession._(
      {required this.id,
      required this.projectId,
      required this.title,
      this.messageCount,
      required this.createdAt,
      required this.updatedAt})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'ChatSession', 'id');
    BuiltValueNullFieldError.checkNotNull(
        projectId, r'ChatSession', 'projectId');
    BuiltValueNullFieldError.checkNotNull(title, r'ChatSession', 'title');
    BuiltValueNullFieldError.checkNotNull(
        createdAt, r'ChatSession', 'createdAt');
    BuiltValueNullFieldError.checkNotNull(
        updatedAt, r'ChatSession', 'updatedAt');
  }

  @override
  ChatSession rebuild(void Function(ChatSessionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatSessionBuilder toBuilder() => new ChatSessionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatSession &&
        id == other.id &&
        projectId == other.projectId &&
        title == other.title &&
        messageCount == other.messageCount &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, projectId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, messageCount.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatSession')
          ..add('id', id)
          ..add('projectId', projectId)
          ..add('title', title)
          ..add('messageCount', messageCount)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class ChatSessionBuilder implements Builder<ChatSession, ChatSessionBuilder> {
  _$ChatSession? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _projectId;
  String? get projectId => _$this._projectId;
  set projectId(String? projectId) => _$this._projectId = projectId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  int? _messageCount;
  int? get messageCount => _$this._messageCount;
  set messageCount(int? messageCount) => _$this._messageCount = messageCount;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ChatSessionBuilder() {
    ChatSession._defaults(this);
  }

  ChatSessionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _projectId = $v.projectId;
      _title = $v.title;
      _messageCount = $v.messageCount;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatSession other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatSession;
  }

  @override
  void update(void Function(ChatSessionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatSession build() => _build();

  _$ChatSession _build() {
    final _$result = _$v ??
        new _$ChatSession._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'ChatSession', 'id'),
            projectId: BuiltValueNullFieldError.checkNotNull(
                projectId, r'ChatSession', 'projectId'),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'ChatSession', 'title'),
            messageCount: messageCount,
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'ChatSession', 'createdAt'),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
                updatedAt, r'ChatSession', 'updatedAt'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
