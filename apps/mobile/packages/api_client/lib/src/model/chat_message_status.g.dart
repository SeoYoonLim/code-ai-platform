// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChatMessageStatus _$streaming = const ChatMessageStatus._('streaming');
const ChatMessageStatus _$completed = const ChatMessageStatus._('completed');
const ChatMessageStatus _$failed = const ChatMessageStatus._('failed');
const ChatMessageStatus _$canceled = const ChatMessageStatus._('canceled');

ChatMessageStatus _$valueOf(String name) {
  switch (name) {
    case 'streaming':
      return _$streaming;
    case 'completed':
      return _$completed;
    case 'failed':
      return _$failed;
    case 'canceled':
      return _$canceled;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ChatMessageStatus> _$values =
    new BuiltSet<ChatMessageStatus>(const <ChatMessageStatus>[
  _$streaming,
  _$completed,
  _$failed,
  _$canceled,
]);

class _$ChatMessageStatusMeta {
  const _$ChatMessageStatusMeta();
  ChatMessageStatus get streaming => _$streaming;
  ChatMessageStatus get completed => _$completed;
  ChatMessageStatus get failed => _$failed;
  ChatMessageStatus get canceled => _$canceled;
  ChatMessageStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<ChatMessageStatus> get values => _$values;
}

abstract class _$ChatMessageStatusMixin {
  // ignore: non_constant_identifier_names
  _$ChatMessageStatusMeta get ChatMessageStatus =>
      const _$ChatMessageStatusMeta();
}

Serializer<ChatMessageStatus> _$chatMessageStatusSerializer =
    new _$ChatMessageStatusSerializer();

class _$ChatMessageStatusSerializer
    implements PrimitiveSerializer<ChatMessageStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'streaming': 'streaming',
    'completed': 'completed',
    'failed': 'failed',
    'canceled': 'canceled',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'streaming': 'streaming',
    'completed': 'completed',
    'failed': 'failed',
    'canceled': 'canceled',
  };

  @override
  final Iterable<Type> types = const <Type>[ChatMessageStatus];
  @override
  final String wireName = 'ChatMessageStatus';

  @override
  Object serialize(Serializers serializers, ChatMessageStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ChatMessageStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ChatMessageStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
