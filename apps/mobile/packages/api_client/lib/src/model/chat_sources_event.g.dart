// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_sources_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatSourcesEventEventEnum _$chatSourcesEventEventEnum_sources =
    const ChatSourcesEventEventEnum._('sources');

ChatSourcesEventEventEnum _$chatSourcesEventEventEnumValueOf(String name) {
  switch (name) {
    case 'sources':
      return _$chatSourcesEventEventEnum_sources;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatSourcesEventEventEnum> _$chatSourcesEventEventEnumValues =
    new BuiltSet<ChatSourcesEventEventEnum>(const <ChatSourcesEventEventEnum>[
  _$chatSourcesEventEventEnum_sources,
]);

Serializer<ChatSourcesEventEventEnum> _$chatSourcesEventEventEnumSerializer =
    new _$ChatSourcesEventEventEnumSerializer();

class _$ChatSourcesEventEventEnumSerializer
    implements PrimitiveSerializer<ChatSourcesEventEventEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'sources': 'sources',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'sources': 'sources',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatSourcesEventEventEnum];
  @override
  final String wireName = 'ChatSourcesEventEventEnum';

  @override
  Object serialize(Serializers serializers, ChatSourcesEventEventEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatSourcesEventEventEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatSourcesEventEventEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ChatSourcesEvent extends ChatSourcesEvent {
  @override
  final ChatSourcesEventEventEnum event;
  @override
  final BuiltList<ChatSource> sources;

  factory _$ChatSourcesEvent(
          [void Function(ChatSourcesEventBuilder)? updates]) =>
      (new ChatSourcesEventBuilder()..update(updates))._build();

  _$ChatSourcesEvent._({required this.event, required this.sources})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(event, r'ChatSourcesEvent', 'event');
    BuiltValueNullFieldError.checkNotNull(
        sources, r'ChatSourcesEvent', 'sources');
  }

  @override
  ChatSourcesEvent rebuild(void Function(ChatSourcesEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChatSourcesEventBuilder toBuilder() =>
      new ChatSourcesEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatSourcesEvent &&
        event == other.event &&
        sources == other.sources;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, sources.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChatSourcesEvent')
          ..add('event', event)
          ..add('sources', sources))
        .toString();
  }
}

class ChatSourcesEventBuilder
    implements Builder<ChatSourcesEvent, ChatSourcesEventBuilder> {
  _$ChatSourcesEvent? _$v;

  ChatSourcesEventEventEnum? _event;
  ChatSourcesEventEventEnum? get event => _$this._event;
  set event(ChatSourcesEventEventEnum? event) => _$this._event = event;

  ListBuilder<ChatSource>? _sources;
  ListBuilder<ChatSource> get sources =>
      _$this._sources ??= new ListBuilder<ChatSource>();
  set sources(ListBuilder<ChatSource>? sources) => _$this._sources = sources;

  ChatSourcesEventBuilder() {
    ChatSourcesEvent._defaults(this);
  }

  ChatSourcesEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _event = $v.event;
      _sources = $v.sources.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChatSourcesEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ChatSourcesEvent;
  }

  @override
  void update(void Function(ChatSourcesEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChatSourcesEvent build() => _build();

  _$ChatSourcesEvent _build() {
    _$ChatSourcesEvent _$result;
    try {
      _$result = _$v ??
          new _$ChatSourcesEvent._(
              event: BuiltValueNullFieldError.checkNotNull(
                  event, r'ChatSourcesEvent', 'event'),
              sources: sources.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sources';
        sources.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ChatSourcesEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
