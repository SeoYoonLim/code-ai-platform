// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatMessageRoleEnum _$chatMessageRoleEnum_user =
    const ChatMessageRoleEnum._('user');
const ChatMessageRoleEnum _$chatMessageRoleEnum_assistant =
    const ChatMessageRoleEnum._('assistant');

ChatMessageRoleEnum _$chatMessageRoleEnumValueOf(String name) {
  switch (name) {
    case 'user':
      return _$chatMessageRoleEnum_user;
    case 'assistant':
      return _$chatMessageRoleEnum_assistant;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatMessageRoleEnum> _$chatMessageRoleEnumValues =
    new BuiltSet<ChatMessageRoleEnum>(const <ChatMessageRoleEnum>[
  _$chatMessageRoleEnum_user,
  _$chatMessageRoleEnum_assistant,
]);

Serializer<ChatMessageRoleEnum> _$chatMessageRoleEnumSerializer =
    new _$ChatMessageRoleEnumSerializer();

class _$ChatMessageRoleEnumSerializer
    implements PrimitiveSerializer<ChatMessageRoleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'user': 'user',
    'assistant': 'assistant',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'user': 'user',
    'assistant': 'assistant',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatMessageRoleEnum];
  @override
  final String wireName = 'ChatMessageRoleEnum';

  @override
  Object serialize(Serializers serializers, ChatMessageRoleEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatMessageRoleEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatMessageRoleEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatMessage extends ChatMessage {
  @override
  final String id;
  @override
  final String sessionId;
  @override
  final ChatMessageRoleEnum role;
  @override
  final String content;
  @override
  final ChatMessageStatus status;
  @override
  final BuiltList<ChatSource>? sources;
  @override
  final String? model;
  @override
  final DateTime createdAt;

  factory _$ChatMessage([void Function(ChatMessageBuilder)? updates]) =>
      (new ChatMessageBuilder()..update(updates))._build();

  _$ChatMessage._(
      {required this.id,
      required this.sessionId,
      required this.role,
      required this.content,
      required this.status,
      this.sources,
      this.model,
      required this.createdAt})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'ChatMessage', 'id');
    BuiltValueNullFieldError.checkNotNull(
        sessionId, r'ChatMessage', 'sessionId');
    BuiltValueNullFieldError.checkNotNull(role, r'ChatMessage', 'role');
    BuiltValueNullFieldError.checkNotNull(content, r'ChatMessage', 'content');
    BuiltValueNullFieldError.checkNotNull(status, r'ChatMessage', 'status');
    BuiltValueNullFieldError.checkNotNull(
        createdAt, r'ChatMessage', 'createdAt');
  }

  @override
  ChatMessage rebuild(void Function(ChatMessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatMessageBuilder toBuilder() => new ChatMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatMessage &&
        id == other.id &&
        sessionId == other.sessionId &&
        role == other.role &&
        content == other.content &&
        status == other.status &&
        sources == other.sources &&
        model == other.model &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, sources.hashCode);
    _$hash = $jc(_$hash, model.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatMessage')
          ..add('id', id)
          ..add('sessionId', sessionId)
          ..add('role', role)
          ..add('content', content)
          ..add('status', status)
          ..add('sources', sources)
          ..add('model', model)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class ChatMessageBuilder implements Builder<ChatMessage, ChatMessageBuilder> {
  _$ChatMessage? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  ChatMessageRoleEnum? _role;
  ChatMessageRoleEnum? get role => _$this._role;
  set role(ChatMessageRoleEnum? role) => _$this._role = role;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  ChatMessageStatus? _status;
  ChatMessageStatus? get status => _$this._status;
  set status(ChatMessageStatus? status) => _$this._status = status;

  ListBuilder<ChatSource>? _sources;
  ListBuilder<ChatSource> get sources =>
      _$this._sources ??= new ListBuilder<ChatSource>();
  set sources(ListBuilder<ChatSource>? sources) => _$this._sources = sources;

  String? _model;
  String? get model => _$this._model;
  set model(String? model) => _$this._model = model;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  ChatMessageBuilder() {
    ChatMessage._defaults(this);
  }

  ChatMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _sessionId = $v.sessionId;
      _role = $v.role;
      _content = $v.content;
      _status = $v.status;
      _sources = $v.sources?.toBuilder();
      _model = $v.model;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatMessage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatMessage;
  }

  @override
  void update(void Function(ChatMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatMessage build() => _build();

  _$ChatMessage _build() {
    _$ChatMessage _$result;
    try {
      _$result = _$v ??
          new _$ChatMessage._(
              id: BuiltValueNullFieldError.checkNotNull(
                  id, r'ChatMessage', 'id'),
              sessionId: BuiltValueNullFieldError.checkNotNull(
                  sessionId, r'ChatMessage', 'sessionId'),
              role: BuiltValueNullFieldError.checkNotNull(
                  role, r'ChatMessage', 'role'),
              content: BuiltValueNullFieldError.checkNotNull(
                  content, r'ChatMessage', 'content'),
              status: BuiltValueNullFieldError.checkNotNull(
                  status, r'ChatMessage', 'status'),
              sources: _sources?.build(),
              model: model,
              createdAt: BuiltValueNullFieldError.checkNotNull(
                  createdAt, r'ChatMessage', 'createdAt'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sources';
        _sources?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ChatMessage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
