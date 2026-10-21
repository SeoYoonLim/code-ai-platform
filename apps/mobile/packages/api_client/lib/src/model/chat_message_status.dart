//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'chat_message_status.g.dart';

class ChatMessageStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'streaming')
  static const ChatMessageStatus streaming = _$streaming;
  @BuiltValueEnumConst(wireName: r'completed')
  static const ChatMessageStatus completed = _$completed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const ChatMessageStatus failed = _$failed;
  @BuiltValueEnumConst(wireName: r'canceled')
  static const ChatMessageStatus canceled = _$canceled;

  static Serializer<ChatMessageStatus> get serializer => _$chatMessageStatusSerializer;

  const ChatMessageStatus._(String name): super(name);

  static BuiltSet<ChatMessageStatus> get values => _$values;
  static ChatMessageStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ChatMessageStatusMixin = Object with _$ChatMessageStatusMixin;

