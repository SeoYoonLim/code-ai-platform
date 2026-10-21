// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_ack.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WebhookAckResultEnum _$webhookAckResultEnum_queued =
    const WebhookAckResultEnum._('queued');
const WebhookAckResultEnum _$webhookAckResultEnum_ignored =
    const WebhookAckResultEnum._('ignored');
const WebhookAckResultEnum _$webhookAckResultEnum_duplicate =
    const WebhookAckResultEnum._('duplicate');

WebhookAckResultEnum _$webhookAckResultEnumValueOf(String name) {
  switch (name) {
    case 'queued':
      return _$webhookAckResultEnum_queued;
    case 'ignored':
      return _$webhookAckResultEnum_ignored;
    case 'duplicate':
      return _$webhookAckResultEnum_duplicate;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<WebhookAckResultEnum> _$webhookAckResultEnumValues =
    new BuiltSet<WebhookAckResultEnum>(const <WebhookAckResultEnum>[
  _$webhookAckResultEnum_queued,
  _$webhookAckResultEnum_ignored,
  _$webhookAckResultEnum_duplicate,
]);

Serializer<WebhookAckResultEnum> _$webhookAckResultEnumSerializer =
    new _$WebhookAckResultEnumSerializer();

class _$WebhookAckResultEnumSerializer
    implements PrimitiveSerializer<WebhookAckResultEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'queued': 'queued',
    'ignored': 'ignored',
    'duplicate': 'duplicate',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'queued': 'queued',
    'ignored': 'ignored',
    'duplicate': 'duplicate',
  };

  @override
  final Iterable<Type> types = const <Type>[WebhookAckResultEnum];
  @override
  final String wireName = 'WebhookAckResultEnum';

  @override
  Object serialize(Serializers serializers, WebhookAckResultEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  WebhookAckResultEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      WebhookAckResultEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$WebhookAck extends WebhookAck {
  @override
  final String deliveryId;
  @override
  final WebhookAckResultEnum result;
  @override
  final String? reason;
  @override
  final String? jobId;

  factory _$WebhookAck([void Function(WebhookAckBuilder)? updates]) =>
      (new WebhookAckBuilder()..update(updates))._build();

  _$WebhookAck._(
      {required this.deliveryId, required this.result, this.reason, this.jobId})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        deliveryId, r'WebhookAck', 'deliveryId');
    BuiltValueNullFieldError.checkNotNull(result, r'WebhookAck', 'result');
  }

  @override
  WebhookAck rebuild(void Function(WebhookAckBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WebhookAckBuilder toBuilder() => new WebhookAckBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WebhookAck &&
        deliveryId == other.deliveryId &&
        result == other.result &&
        reason == other.reason &&
        jobId == other.jobId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deliveryId.hashCode);
    _$hash = $jc(_$hash, result.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, jobId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WebhookAck')
          ..add('deliveryId', deliveryId)
          ..add('result', result)
          ..add('reason', reason)
          ..add('jobId', jobId))
        .toString();
  }
}

class WebhookAckBuilder implements Builder<WebhookAck, WebhookAckBuilder> {
  _$WebhookAck? _$v;

  String? _deliveryId;
  String? get deliveryId => _$this._deliveryId;
  set deliveryId(String? deliveryId) => _$this._deliveryId = deliveryId;

  WebhookAckResultEnum? _result;
  WebhookAckResultEnum? get result => _$this._result;
  set result(WebhookAckResultEnum? result) => _$this._result = result;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  String? _jobId;
  String? get jobId => _$this._jobId;
  set jobId(String? jobId) => _$this._jobId = jobId;

  WebhookAckBuilder() {
    WebhookAck._defaults(this);
  }

  WebhookAckBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deliveryId = $v.deliveryId;
      _result = $v.result;
      _reason = $v.reason;
      _jobId = $v.jobId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WebhookAck other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$WebhookAck;
  }

  @override
  void update(void Function(WebhookAckBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WebhookAck build() => _build();

  _$WebhookAck _build() {
    final _$result = _$v ??
        new _$WebhookAck._(
            deliveryId: BuiltValueNullFieldError.checkNotNull(
                deliveryId, r'WebhookAck', 'deliveryId'),
            result: BuiltValueNullFieldError.checkNotNull(
                result, r'WebhookAck', 'result'),
            reason: reason,
            jobId: jobId);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
