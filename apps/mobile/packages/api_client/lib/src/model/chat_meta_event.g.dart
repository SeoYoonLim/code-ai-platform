// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_meta_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatMetaEventEventEnum _$chatMetaEventEventEnum_meta =
    const ChatMetaEventEventEnum._('meta');

ChatMetaEventEventEnum _$chatMetaEventEventEnumValueOf(String name) {
  switch (name) {
    case 'meta':
      return _$chatMetaEventEventEnum_meta;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatMetaEventEventEnum> _$chatMetaEventEventEnumValues =
    new BuiltSet<ChatMetaEventEventEnum>(const <ChatMetaEventEventEnum>[
  _$chatMetaEventEventEnum_meta,
]);

Serializer<ChatMetaEventEventEnum> _$chatMetaEventEventEnumSerializer =
    new _$ChatMetaEventEventEnumSerializer();

class _$ChatMetaEventEventEnumSerializer
    implements PrimitiveSerializer<ChatMetaEventEventEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'meta': 'meta',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'meta': 'meta',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatMetaEventEventEnum];
  @override
  final String wireName = 'ChatMetaEventEventEnum';

  @override
  Object serialize(Serializers serializers, ChatMetaEventEventEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatMetaEventEventEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatMetaEventEventEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatMetaEvent extends ChatMetaEvent {
  @override
  final ChatMetaEventEventEnum event;
  @override
  final String streamId;
  @override
  final String sessionId;
  @override
  final String messageId;
  @override
  final String model;
  @override
  final String? adapter;

  factory _$ChatMetaEvent([void Function(ChatMetaEventBuilder)? updates]) =>
      (new ChatMetaEventBuilder()..update(updates))._build();

  _$ChatMetaEvent._(
      {required this.event,
      required this.streamId,
      required this.sessionId,
      required this.messageId,
      required this.model,
      this.adapter})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(event, r'ChatMetaEvent', 'event');
    BuiltValueNullFieldError.checkNotNull(
        streamId, r'ChatMetaEvent', 'streamId');
    BuiltValueNullFieldError.checkNotNull(
        sessionId, r'ChatMetaEvent', 'sessionId');
    BuiltValueNullFieldError.checkNotNull(
        messageId, r'ChatMetaEvent', 'messageId');
    BuiltValueNullFieldError.checkNotNull(model, r'ChatMetaEvent', 'model');
  }

  @override
  ChatMetaEvent rebuild(void Function(ChatMetaEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatMetaEventBuilder toBuilder() => new ChatMetaEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatMetaEvent &&
        event == other.event &&
        streamId == other.streamId &&
        sessionId == other.sessionId &&
        messageId == other.messageId &&
        model == other.model &&
        adapter == other.adapter;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, streamId.hashCode);
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jc(_$hash, model.hashCode);
    _$hash = $jc(_$hash, adapter.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatMetaEvent')
          ..add('event', event)
          ..add('streamId', streamId)
          ..add('sessionId', sessionId)
          ..add('messageId', messageId)
          ..add('model', model)
          ..add('adapter', adapter))
        .toString();
  }
}

class ChatMetaEventBuilder
    implements Builder<ChatMetaEvent, ChatMetaEventBuilder> {
  _$ChatMetaEvent? _$v;

  ChatMetaEventEventEnum? _event;
  ChatMetaEventEventEnum? get event => _$this._event;
  set event(ChatMetaEventEventEnum? event) => _$this._event = event;

  String? _streamId;
  String? get streamId => _$this._streamId;
  set streamId(String? streamId) => _$this._streamId = streamId;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  String? _messageId;
  String? get messageId => _$this._messageId;
  set messageId(String? messageId) => _$this._messageId = messageId;

  String? _model;
  String? get model => _$this._model;
  set model(String? model) => _$this._model = model;

  String? _adapter;
  String? get adapter => _$this._adapter;
  set adapter(String? adapter) => _$this._adapter = adapter;

  ChatMetaEventBuilder() {
    ChatMetaEvent._defaults(this);
  }

  ChatMetaEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _event = $v.event;
      _streamId = $v.streamId;
      _sessionId = $v.sessionId;
      _messageId = $v.messageId;
      _model = $v.model;
      _adapter = $v.adapter;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatMetaEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatMetaEvent;
  }

  @override
  void update(void Function(ChatMetaEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatMetaEvent build() => _build();

  _$ChatMetaEvent _build() {
    final _$result = _$v ??
        new _$ChatMetaEvent._(
            event: BuiltValueNullFieldError.checkNotNull(
                event, r'ChatMetaEvent', 'event'),
            streamId: BuiltValueNullFieldError.checkNotNull(
                streamId, r'ChatMetaEvent', 'streamId'),
            sessionId: BuiltValueNullFieldError.checkNotNull(
                sessionId, r'ChatMetaEvent', 'sessionId'),
            messageId: BuiltValueNullFieldError.checkNotNull(
                messageId, r'ChatMetaEvent', 'messageId'),
            model: BuiltValueNullFieldError.checkNotNull(
                model, r'ChatMetaEvent', 'model'),
            adapter: adapter);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
