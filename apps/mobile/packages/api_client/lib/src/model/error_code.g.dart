// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_code.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ErrorCode _$validationError = const ErrorCode._('validationError');
const ErrorCode _$unauthorized = const ErrorCode._('unauthorized');
const ErrorCode _$forbidden = const ErrorCode._('forbidden');
const ErrorCode _$notFound = const ErrorCode._('notFound');
const ErrorCode _$conflict = const ErrorCode._('conflict');
const ErrorCode _$jobConflict = const ErrorCode._('jobConflict');
const ErrorCode _$indexNotReady = const ErrorCode._('indexNotReady');
const ErrorCode _$idempotencyKeyReused =
    const ErrorCode._('idempotencyKeyReused');
const ErrorCode _$repoCloneFailed = const ErrorCode._('repoCloneFailed');
const ErrorCode _$contextTooLarge = const ErrorCode._('contextTooLarge');
const ErrorCode _$streamExpired = const ErrorCode._('streamExpired');
const ErrorCode _$rateLimited = const ErrorCode._('rateLimited');
const ErrorCode _$webhookSignatureInvalid =
    const ErrorCode._('webhookSignatureInvalid');
const ErrorCode _$internalError = const ErrorCode._('internalError');
const ErrorCode _$engineError = const ErrorCode._('engineError');
const ErrorCode _$engineUnavailable = const ErrorCode._('engineUnavailable');
const ErrorCode _$engineTimeout = const ErrorCode._('engineTimeout');

ErrorCode _$valueOf(String name) {
  switch (name) {
    case 'validationError':
      return _$validationError;
    case 'unauthorized':
      return _$unauthorized;
    case 'forbidden':
      return _$forbidden;
    case 'notFound':
      return _$notFound;
    case 'conflict':
      return _$conflict;
    case 'jobConflict':
      return _$jobConflict;
    case 'indexNotReady':
      return _$indexNotReady;
    case 'idempotencyKeyReused':
      return _$idempotencyKeyReused;
    case 'repoCloneFailed':
      return _$repoCloneFailed;
    case 'contextTooLarge':
      return _$contextTooLarge;
    case 'streamExpired':
      return _$streamExpired;
    case 'rateLimited':
      return _$rateLimited;
    case 'webhookSignatureInvalid':
      return _$webhookSignatureInvalid;
    case 'internalError':
      return _$internalError;
    case 'engineError':
      return _$engineError;
    case 'engineUnavailable':
      return _$engineUnavailable;
    case 'engineTimeout':
      return _$engineTimeout;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ErrorCode> _$values = new BuiltSet<ErrorCode>(const <ErrorCode>[
  _$validationError,
  _$unauthorized,
  _$forbidden,
  _$notFound,
  _$conflict,
  _$jobConflict,
  _$indexNotReady,
  _$idempotencyKeyReused,
  _$repoCloneFailed,
  _$contextTooLarge,
  _$streamExpired,
  _$rateLimited,
  _$webhookSignatureInvalid,
  _$internalError,
  _$engineError,
  _$engineUnavailable,
  _$engineTimeout,
]);

class _$ErrorCodeMeta {
  const _$ErrorCodeMeta();
  ErrorCode get validationError => _$validationError;
  ErrorCode get unauthorized => _$unauthorized;
  ErrorCode get forbidden => _$forbidden;
  ErrorCode get notFound => _$notFound;
  ErrorCode get conflict => _$conflict;
  ErrorCode get jobConflict => _$jobConflict;
  ErrorCode get indexNotReady => _$indexNotReady;
  ErrorCode get idempotencyKeyReused => _$idempotencyKeyReused;
  ErrorCode get repoCloneFailed => _$repoCloneFailed;
  ErrorCode get contextTooLarge => _$contextTooLarge;
  ErrorCode get streamExpired => _$streamExpired;
  ErrorCode get rateLimited => _$rateLimited;
  ErrorCode get webhookSignatureInvalid => _$webhookSignatureInvalid;
  ErrorCode get internalError => _$internalError;
  ErrorCode get engineError => _$engineError;
  ErrorCode get engineUnavailable => _$engineUnavailable;
  ErrorCode get engineTimeout => _$engineTimeout;
  ErrorCode valueOf(String name) => _$valueOf(name);
  BuiltSet<ErrorCode> get values => _$values;
}

abstract class _$ErrorCodeMixin {
  // ignore: non_constant_identifier_names
  _$ErrorCodeMeta get ErrorCode => const _$ErrorCodeMeta();
}

Serializer<ErrorCode> _$errorCodeSerializer = new _$ErrorCodeSerializer();

class _$ErrorCodeSerializer implements PrimitiveSerializer<ErrorCode> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'validationError': 'validation_error',
    'unauthorized': 'unauthorized',
    'forbidden': 'forbidden',
    'notFound': 'not_found',
    'conflict': 'conflict',
    'jobConflict': 'job_conflict',
    'indexNotReady': 'index_not_ready',
    'idempotencyKeyReused': 'idempotency_key_reused',
    'repoCloneFailed': 'repo_clone_failed',
    'contextTooLarge': 'context_too_large',
    'streamExpired': 'stream_expired',
    'rateLimited': 'rate_limited',
    'webhookSignatureInvalid': 'webhook_signature_invalid',
    'internalError': 'internal_error',
    'engineError': 'engine_error',
    'engineUnavailable': 'engine_unavailable',
    'engineTimeout': 'engine_timeout',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'validation_error': 'validationError',
    'unauthorized': 'unauthorized',
    'forbidden': 'forbidden',
    'not_found': 'notFound',
    'conflict': 'conflict',
    'job_conflict': 'jobConflict',
    'index_not_ready': 'indexNotReady',
    'idempotency_key_reused': 'idempotencyKeyReused',
    'repo_clone_failed': 'repoCloneFailed',
    'context_too_large': 'contextTooLarge',
    'stream_expired': 'streamExpired',
    'rate_limited': 'rateLimited',
    'webhook_signature_invalid': 'webhookSignatureInvalid',
    'internal_error': 'internalError',
    'engine_error': 'engineError',
    'engine_unavailable': 'engineUnavailable',
    'engine_timeout': 'engineTimeout',
  };

  @override
  final Iterable<Type> types = const <Type>[ErrorCode];
  @override
  final String wireName = 'ErrorCode';

  @override
  Object serialize(Serializers serializers, ErrorCode object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ErrorCode deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ErrorCode.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
