// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_error_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatErrorEventEventEnum _$chatErrorEventEventEnum_error =
    const ChatErrorEventEventEnum._('error');

ChatErrorEventEventEnum _$chatErrorEventEventEnumValueOf(String name) {
  switch (name) {
    case 'error':
      return _$chatErrorEventEventEnum_error;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatErrorEventEventEnum> _$chatErrorEventEventEnumValues =
    new BuiltSet<ChatErrorEventEventEnum>(const <ChatErrorEventEventEnum>[
  _$chatErrorEventEventEnum_error,
]);

Serializer<ChatErrorEventEventEnum> _$chatErrorEventEventEnumSerializer =
    new _$ChatErrorEventEventEnumSerializer();

class _$ChatErrorEventEventEnumSerializer
    implements PrimitiveSerializer<ChatErrorEventEventEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatErrorEventEventEnum];
  @override
  final String wireName = 'ChatErrorEventEventEnum';

  @override
  Object serialize(Serializers serializers, ChatErrorEventEventEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatErrorEventEventEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatErrorEventEventEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatErrorEvent extends ChatErrorEvent {
  @override
  final ChatErrorEventEventEnum event;
  @override
  final Problem error;

  factory _$ChatErrorEvent([void Function(ChatErrorEventBuilder)? updates]) =>
      (new ChatErrorEventBuilder()..update(updates))._build();

  _$ChatErrorEvent._({required this.event, required this.error}) : super._() {
    BuiltValueNullFieldError.checkNotNull(event, r'ChatErrorEvent', 'event');
    BuiltValueNullFieldError.checkNotNull(error, r'ChatErrorEvent', 'error');
  }

  @override
  ChatErrorEvent rebuild(void Function(ChatErrorEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatErrorEventBuilder toBuilder() =>
      new ChatErrorEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatErrorEvent &&
        event == other.event &&
        error == other.error;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatErrorEvent')
          ..add('event', event)
          ..add('error', error))
        .toString();
  }
}

class ChatErrorEventBuilder
    implements Builder<ChatErrorEvent, ChatErrorEventBuilder> {
  _$ChatErrorEvent? _$v;

  ChatErrorEventEventEnum? _event;
  ChatErrorEventEventEnum? get event => _$this._event;
  set event(ChatErrorEventEventEnum? event) => _$this._event = event;

  ProblemBuilder? _error;
  ProblemBuilder get error => _$this._error ??= new ProblemBuilder();
  set error(ProblemBuilder? error) => _$this._error = error;

  ChatErrorEventBuilder() {
    ChatErrorEvent._defaults(this);
  }

  ChatErrorEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _event = $v.event;
      _error = $v.error.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatErrorEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatErrorEvent;
  }

  @override
  void update(void Function(ChatErrorEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatErrorEvent build() => _build();

  _$ChatErrorEvent _build() {
    _$ChatErrorEvent _$result;
    try {
      _$result = _$v ??
          new _$ChatErrorEvent._(
              event: BuiltValueNullFieldError.checkNotNull(
                  event, r'ChatErrorEvent', 'event'),
              error: error.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'error';
        error.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ChatErrorEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
