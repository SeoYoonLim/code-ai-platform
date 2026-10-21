//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'index_state.g.dart';

class IndexState extends EnumClass {

  @BuiltValueEnumConst(wireName: r'not_indexed')
  static const IndexState notIndexed = _$notIndexed;
  @BuiltValueEnumConst(wireName: r'indexing')
  static const IndexState indexing = _$indexing;
  @BuiltValueEnumConst(wireName: r'ready')
  static const IndexState ready = _$ready;
  @BuiltValueEnumConst(wireName: r'failed')
  static const IndexState failed = _$failed;

  static Serializer<IndexState> get serializer => _$indexStateSerializer;

  const IndexState._(String name): super(name);

  static BuiltSet<IndexState> get values => _$values;
  static IndexState valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class IndexStateMixin = Object with _$IndexStateMixin;

