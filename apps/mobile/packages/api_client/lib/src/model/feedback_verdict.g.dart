// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_verdict.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FeedbackVerdict _$accepted = const FeedbackVerdict._('accepted');
const FeedbackVerdict _$rejected = const FeedbackVerdict._('rejected');
const FeedbackVerdict _$edited = const FeedbackVerdict._('edited');

FeedbackVerdict _$valueOf(String name) {
  switch (name) {
    case 'accepted':
      return _$accepted;
    case 'rejected':
      return _$rejected;
    case 'edited':
      return _$edited;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<FeedbackVerdict> _$values =
    new BuiltSet<FeedbackVerdict>(const <FeedbackVerdict>[
  _$accepted,
  _$rejected,
  _$edited,
]);

class _$FeedbackVerdictMeta {
  const _$FeedbackVerdictMeta();
  FeedbackVerdict get accepted => _$accepted;
  FeedbackVerdict get rejected => _$rejected;
  FeedbackVerdict get edited => _$edited;
  FeedbackVerdict valueOf(String name) => _$valueOf(name);
  BuiltSet<FeedbackVerdict> get values => _$values;
}

abstract class _$FeedbackVerdictMixin {
  // ignore: non_constant_identifier_names
  _$FeedbackVerdictMeta get FeedbackVerdict => const _$FeedbackVerdictMeta();
}

Serializer<FeedbackVerdict> _$feedbackVerdictSerializer =
    new _$FeedbackVerdictSerializer();

class _$FeedbackVerdictSerializer
    implements PrimitiveSerializer<FeedbackVerdict> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'accepted': 'accepted',
    'rejected': 'rejected',
    'edited': 'edited',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'accepted': 'accepted',
    'rejected': 'rejected',
    'edited': 'edited',
  };

  @override
  final Iterable<Type> types = const <Type>[FeedbackVerdict];
  @override
  final String wireName = 'FeedbackVerdict';

  @override
  Object serialize(Serializers serializers, FeedbackVerdict object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FeedbackVerdict deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FeedbackVerdict.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
