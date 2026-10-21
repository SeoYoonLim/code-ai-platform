// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_done_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatDoneEventEventEnum _$chatDoneEventEventEnum_done =
    const ChatDoneEventEventEnum._('done');

ChatDoneEventEventEnum _$chatDoneEventEventEnumValueOf(String name) {
  switch (name) {
    case 'done':
      return _$chatDoneEventEventEnum_done;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatDoneEventEventEnum> _$chatDoneEventEventEnumValues =
    new BuiltSet<ChatDoneEventEventEnum>(const <ChatDoneEventEventEnum>[
  _$chatDoneEventEventEnum_done,
]);

const ChatDoneEventFinishReasonEnum _$chatDoneEventFinishReasonEnum_stop =
    const ChatDoneEventFinishReasonEnum._('stop');
const ChatDoneEventFinishReasonEnum _$chatDoneEventFinishReasonEnum_length =
    const ChatDoneEventFinishReasonEnum._('length');
const ChatDoneEventFinishReasonEnum _$chatDoneEventFinishReasonEnum_error =
    const ChatDoneEventFinishReasonEnum._('error');
const ChatDoneEventFinishReasonEnum _$chatDoneEventFinishReasonEnum_canceled =
    const ChatDoneEventFinishReasonEnum._('canceled');

ChatDoneEventFinishReasonEnum _$chatDoneEventFinishReasonEnumValueOf(
    String name) {
  switch (name) {
    case 'stop':
      return _$chatDoneEventFinishReasonEnum_stop;
    case 'length':
      return _$chatDoneEventFinishReasonEnum_length;
    case 'error':
      return _$chatDoneEventFinishReasonEnum_error;
    case 'canceled':
      return _$chatDoneEventFinishReasonEnum_canceled;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatDoneEventFinishReasonEnum>
    _$chatDoneEventFinishReasonEnumValues = new BuiltSet<
        ChatDoneEventFinishReasonEnum>(const <ChatDoneEventFinishReasonEnum>[
  _$chatDoneEventFinishReasonEnum_stop,
  _$chatDoneEventFinishReasonEnum_length,
  _$chatDoneEventFinishReasonEnum_error,
  _$chatDoneEventFinishReasonEnum_canceled,
]);

Serializer<ChatDoneEventEventEnum> _$chatDoneEventEventEnumSerializer =
    new _$ChatDoneEventEventEnumSerializer();
Serializer<ChatDoneEventFinishReasonEnum>
    _$chatDoneEventFinishReasonEnumSerializer =
    new _$ChatDoneEventFinishReasonEnumSerializer();

class _$ChatDoneEventEventEnumSerializer
    implements PrimitiveSerializer<ChatDoneEventEventEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'done': 'done',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'done': 'done',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatDoneEventEventEnum];
  @override
  final String wireName = 'ChatDoneEventEventEnum';

  @override
  Object serialize(Serializers serializers, ChatDoneEventEventEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatDoneEventEventEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatDoneEventEventEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatDoneEventFinishReasonEnumSerializer
    implements PrimitiveSerializer<ChatDoneEventFinishReasonEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'stop': 'stop',
    'length': 'length',
    'error': 'error',
    'canceled': 'canceled',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'stop': 'stop',
    'length': 'length',
    'error': 'error',
    'canceled': 'canceled',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatDoneEventFinishReasonEnum];
  @override
  final String wireName = 'ChatDoneEventFinishReasonEnum';

  @override
  Object serialize(
          Serializers serializers, ChatDoneEventFinishReasonEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatDoneEventFinishReasonEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatDoneEventFinishReasonEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatDoneEvent extends ChatDoneEvent {
  @override
  final ChatDoneEventEventEnum event;
  @override
  final ChatDoneEventFinishReasonEnum finishReason;
  @override
  final TokenUsage usage;

  factory _$ChatDoneEvent([void Function(ChatDoneEventBuilder)? updates]) =>
      (new ChatDoneEventBuilder()..update(updates))._build();

  _$ChatDoneEvent._(
      {required this.event, required this.finishReason, required this.usage})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(event, r'ChatDoneEvent', 'event');
    BuiltValueNullFieldError.checkNotNull(
        finishReason, r'ChatDoneEvent', 'finishReason');
    BuiltValueNullFieldError.checkNotNull(usage, r'ChatDoneEvent', 'usage');
  }

  @override
  ChatDoneEvent rebuild(void Function(ChatDoneEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatDoneEventBuilder toBuilder() => new ChatDoneEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatDoneEvent &&
        event == other.event &&
        finishReason == other.finishReason &&
        usage == other.usage;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, finishReason.hashCode);
    _$hash = $jc(_$hash, usage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatDoneEvent')
          ..add('event', event)
          ..add('finishReason', finishReason)
          ..add('usage', usage))
        .toString();
  }
}

class ChatDoneEventBuilder
    implements Builder<ChatDoneEvent, ChatDoneEventBuilder> {
  _$ChatDoneEvent? _$v;

  ChatDoneEventEventEnum? _event;
  ChatDoneEventEventEnum? get event => _$this._event;
  set event(ChatDoneEventEventEnum? event) => _$this._event = event;

  ChatDoneEventFinishReasonEnum? _finishReason;
  ChatDoneEventFinishReasonEnum? get finishReason => _$this._finishReason;
  set finishReason(ChatDoneEventFinishReasonEnum? finishReason) =>
      _$this._finishReason = finishReason;

  TokenUsageBuilder? _usage;
  TokenUsageBuilder get usage => _$this._usage ??= new TokenUsageBuilder();
  set usage(TokenUsageBuilder? usage) => _$this._usage = usage;

  ChatDoneEventBuilder() {
    ChatDoneEvent._defaults(this);
  }

  ChatDoneEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _event = $v.event;
      _finishReason = $v.finishReason;
      _usage = $v.usage.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatDoneEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatDoneEvent;
  }

  @override
  void update(void Function(ChatDoneEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatDoneEvent build() => _build();

  _$ChatDoneEvent _build() {
    _$ChatDoneEvent _$result;
    try {
      _$result = _$v ??
          new _$ChatDoneEvent._(
              event: BuiltValueNullFieldError.checkNotNull(
                  event, r'ChatDoneEvent', 'event'),
              finishReason: BuiltValueNullFieldError.checkNotNull(
                  finishReason, r'ChatDoneEvent', 'finishReason'),
              usage: usage.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'usage';
        usage.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ChatDoneEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
