// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatStreamEventEventEnum _$chatStreamEventEventEnum_error =
    const ChatStreamEventEventEnum._('error');

ChatStreamEventEventEnum _$chatStreamEventEventEnumValueOf(String name) {
  switch (name) {
    case 'error':
      return _$chatStreamEventEventEnum_error;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatStreamEventEventEnum> _$chatStreamEventEventEnumValues =
    new BuiltSet<ChatStreamEventEventEnum>(const <ChatStreamEventEventEnum>[
  _$chatStreamEventEventEnum_error,
]);

const ChatStreamEventFinishReasonEnum _$chatStreamEventFinishReasonEnum_stop =
    const ChatStreamEventFinishReasonEnum._('stop');
const ChatStreamEventFinishReasonEnum _$chatStreamEventFinishReasonEnum_length =
    const ChatStreamEventFinishReasonEnum._('length');
const ChatStreamEventFinishReasonEnum _$chatStreamEventFinishReasonEnum_error =
    const ChatStreamEventFinishReasonEnum._('error');
const ChatStreamEventFinishReasonEnum
    _$chatStreamEventFinishReasonEnum_canceled =
    const ChatStreamEventFinishReasonEnum._('canceled');

ChatStreamEventFinishReasonEnum _$chatStreamEventFinishReasonEnumValueOf(
    String name) {
  switch (name) {
    case 'stop':
      return _$chatStreamEventFinishReasonEnum_stop;
    case 'length':
      return _$chatStreamEventFinishReasonEnum_length;
    case 'error':
      return _$chatStreamEventFinishReasonEnum_error;
    case 'canceled':
      return _$chatStreamEventFinishReasonEnum_canceled;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatStreamEventFinishReasonEnum>
    _$chatStreamEventFinishReasonEnumValues = new BuiltSet<
        ChatStreamEventFinishReasonEnum>(const <ChatStreamEventFinishReasonEnum>[
  _$chatStreamEventFinishReasonEnum_stop,
  _$chatStreamEventFinishReasonEnum_length,
  _$chatStreamEventFinishReasonEnum_error,
  _$chatStreamEventFinishReasonEnum_canceled,
]);

Serializer<ChatStreamEventEventEnum> _$chatStreamEventEventEnumSerializer =
    new _$ChatStreamEventEventEnumSerializer();
Serializer<ChatStreamEventFinishReasonEnum>
    _$chatStreamEventFinishReasonEnumSerializer =
    new _$ChatStreamEventFinishReasonEnumSerializer();

class _$ChatStreamEventEventEnumSerializer
    implements PrimitiveSerializer<ChatStreamEventEventEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatStreamEventEventEnum];
  @override
  final String wireName = 'ChatStreamEventEventEnum';

  @override
  Object serialize(Serializers serializers, ChatStreamEventEventEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatStreamEventEventEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatStreamEventEventEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatStreamEventFinishReasonEnumSerializer
    implements PrimitiveSerializer<ChatStreamEventFinishReasonEnum> {
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
  final Iterable<Type> types = const <Type>[ChatStreamEventFinishReasonEnum];
  @override
  final String wireName = 'ChatStreamEventFinishReasonEnum';

  @override
  Object serialize(
          Serializers serializers, ChatStreamEventFinishReasonEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatStreamEventFinishReasonEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatStreamEventFinishReasonEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatStreamEvent extends ChatStreamEvent {
  @override
  final OneOf oneOf;

  factory _$ChatStreamEvent([void Function(ChatStreamEventBuilder)? updates]) =>
      (new ChatStreamEventBuilder()..update(updates))._build();

  _$ChatStreamEvent._({required this.oneOf}) : super._() {
    BuiltValueNullFieldError.checkNotNull(oneOf, r'ChatStreamEvent', 'oneOf');
  }

  @override
  ChatStreamEvent rebuild(void Function(ChatStreamEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatStreamEventBuilder toBuilder() =>
      new ChatStreamEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatStreamEvent && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatStreamEvent')
          ..add('oneOf', oneOf))
        .toString();
  }
}

class ChatStreamEventBuilder
    implements Builder<ChatStreamEvent, ChatStreamEventBuilder> {
  _$ChatStreamEvent? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  ChatStreamEventBuilder() {
    ChatStreamEvent._defaults(this);
  }

  ChatStreamEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatStreamEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatStreamEvent;
  }

  @override
  void update(void Function(ChatStreamEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatStreamEvent build() => _build();

  _$ChatStreamEvent _build() {
    final _$result = _$v ??
        new _$ChatStreamEvent._(
            oneOf: BuiltValueNullFieldError.checkNotNull(
                oneOf, r'ChatStreamEvent', 'oneOf'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
