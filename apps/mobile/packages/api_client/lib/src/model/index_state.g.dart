// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_state.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const IndexState _$notIndexed = const IndexState._('notIndexed');
const IndexState _$indexing = const IndexState._('indexing');
const IndexState _$ready = const IndexState._('ready');
const IndexState _$failed = const IndexState._('failed');

IndexState _$valueOf(String name) {
  switch (name) {
    case 'notIndexed':
      return _$notIndexed;
    case 'indexing':
      return _$indexing;
    case 'ready':
      return _$ready;
    case 'failed':
      return _$failed;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<IndexState> _$values =
    new BuiltSet<IndexState>(const <IndexState>[
  _$notIndexed,
  _$indexing,
  _$ready,
  _$failed,
]);

class _$IndexStateMeta {
  const _$IndexStateMeta();
  IndexState get notIndexed => _$notIndexed;
  IndexState get indexing => _$indexing;
  IndexState get ready => _$ready;
  IndexState get failed => _$failed;
  IndexState valueOf(String name) => _$valueOf(name);
  BuiltSet<IndexState> get values => _$values;
}

abstract class _$IndexStateMixin {
  // ignore: non_constant_identifier_names
  _$IndexStateMeta get IndexState => const _$IndexStateMeta();
}

Serializer<IndexState> _$indexStateSerializer = new _$IndexStateSerializer();

class _$IndexStateSerializer implements PrimitiveSerializer<IndexState> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'notIndexed': 'not_indexed',
    'indexing': 'indexing',
    'ready': 'ready',
    'failed': 'failed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'not_indexed': 'notIndexed',
    'indexing': 'indexing',
    'ready': 'ready',
    'failed': 'failed',
  };

  @override
  final Iterable<Type> types = const <Type>[IndexState];
  @override
  final String wireName = 'IndexState';

  @override
  Object serialize(Serializers serializers, IndexState object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  IndexState deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      IndexState.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
