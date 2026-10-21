//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'error_code.g.dart';

class ErrorCode extends EnumClass {

  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'validation_error')
  static const ErrorCode validationError = _$validationError;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'unauthorized')
  static const ErrorCode unauthorized = _$unauthorized;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'forbidden')
  static const ErrorCode forbidden = _$forbidden;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'not_found')
  static const ErrorCode notFound = _$notFound;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'conflict')
  static const ErrorCode conflict = _$conflict;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'job_conflict')
  static const ErrorCode jobConflict = _$jobConflict;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'index_not_ready')
  static const ErrorCode indexNotReady = _$indexNotReady;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'idempotency_key_reused')
  static const ErrorCode idempotencyKeyReused = _$idempotencyKeyReused;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'repo_clone_failed')
  static const ErrorCode repoCloneFailed = _$repoCloneFailed;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'context_too_large')
  static const ErrorCode contextTooLarge = _$contextTooLarge;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'stream_expired')
  static const ErrorCode streamExpired = _$streamExpired;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'rate_limited')
  static const ErrorCode rateLimited = _$rateLimited;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'webhook_signature_invalid')
  static const ErrorCode webhookSignatureInvalid = _$webhookSignatureInvalid;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'internal_error')
  static const ErrorCode internalError = _$internalError;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'engine_error')
  static const ErrorCode engineError = _$engineError;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'engine_unavailable')
  static const ErrorCode engineUnavailable = _$engineUnavailable;
  /// Backend 공개 에러 코드. Engine 에러는 그대로 노출하지 않고 아래로 매핑한다 (docs/architecture/03-api-conventions.md §1.3 매핑표). 
  @BuiltValueEnumConst(wireName: r'engine_timeout')
  static const ErrorCode engineTimeout = _$engineTimeout;

  static Serializer<ErrorCode> get serializer => _$errorCodeSerializer;

  const ErrorCode._(String name): super(name);

  static BuiltSet<ErrorCode> get values => _$values;
  static ErrorCode valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ErrorCodeMixin = Object with _$ErrorCodeMixin;

