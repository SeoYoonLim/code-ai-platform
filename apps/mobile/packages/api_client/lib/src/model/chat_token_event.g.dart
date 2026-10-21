// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_token_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatTokenEventEventEnum _$chatTokenEventEventEnum_token =
    const ChatTokenEventEventEnum._('token');

ChatTokenEventEventEnum _$chatTokenEventEventEnumValueOf(String name) {
  switch (name) {
    case 'token':
      return _$chatTokenEventEventEnum_token;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatTokenEventEventEnum> _$chatTokenEventEventEnumValues =
    new BuiltSet<ChatTokenEventEventEnum>(const <ChatTokenEventEventEnum>[
  _$chatTokenEventEventEnum_token,
]);

Serializer<ChatTokenEventEventEnum> _$chatTokenEventEventEnumSerializer =
    new _$ChatTokenEventEventEnumSerializer();

class _$ChatTokenEventEventEnumSerializer
    implements PrimitiveSerializer<ChatTokenEventEventEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'token': 'token',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'token': 'token',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatTokenEventEventEnum];
  @override
  final String wireName = 'ChatTokenEventEventEnum';

  @override
  Object serialize(Serializers serializers, ChatTokenEventEventEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatTokenEventEventEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatTokenEventEventEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatTokenEvent extends ChatTokenEvent {
  @override
  final ChatTokenEventEventEnum event;
  @override
  final int index;
  @override
  final String delta;

  factory _$ChatTokenEvent([void Function(ChatTokenEventBuilder)? updates]) =>
      (new ChatTokenEventBuilder()..update(updates))._build();

  _$ChatTokenEvent._(
      {required this.event, required this.index, required this.delta})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(event, r'ChatTokenEvent', 'event');
    BuiltValueNullFieldError.checkNotNull(index, r'ChatTokenEvent', 'index');
    BuiltValueNullFieldError.checkNotNull(delta, r'ChatTokenEvent', 'delta');
  }

  @override
  ChatTokenEvent rebuild(void Function(ChatTokenEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatTokenEventBuilder toBuilder() =>
      new ChatTokenEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatTokenEvent &&
        event == other.event &&
        index == other.index &&
        delta == other.delta;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, index.hashCode);
    _$hash = $jc(_$hash, delta.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatTokenEvent')
          ..add('event', event)
          ..add('index', index)
          ..add('delta', delta))
        .toString();
  }
}

class ChatTokenEventBuilder
    implements Builder<ChatTokenEvent, ChatTokenEventBuilder> {
  _$ChatTokenEvent? _$v;

  ChatTokenEventEventEnum? _event;
  ChatTokenEventEventEnum? get event => _$this._event;
  set event(ChatTokenEventEventEnum? event) => _$this._event = event;

  int? _index;
  int? get index => _$this._index;
  set index(int? index) => _$this._index = index;

  String? _delta;
  String? get delta => _$this._delta;
  set delta(String? delta) => _$this._delta = delta;

  ChatTokenEventBuilder() {
    ChatTokenEvent._defaults(this);
  }

  ChatTokenEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _event = $v.event;
      _index = $v.index;
      _delta = $v.delta;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatTokenEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatTokenEvent;
  }

  @override
  void update(void Function(ChatTokenEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatTokenEvent build() => _build();

  _$ChatTokenEvent _build() {
    final _$result = _$v ??
        new _$ChatTokenEvent._(
            event: BuiltValueNullFieldError.checkNotNull(
                event, r'ChatTokenEvent', 'event'),
            index: BuiltValueNullFieldError.checkNotNull(
                index, r'ChatTokenEvent', 'index'),
            delta: BuiltValueNullFieldError.checkNotNull(
                delta, r'ChatTokenEvent', 'delta'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
