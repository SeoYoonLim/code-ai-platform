// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const JobStatus _$queued = const JobStatus._('queued');
const JobStatus _$running = const JobStatus._('running');
const JobStatus _$succeeded = const JobStatus._('succeeded');
const JobStatus _$failed = const JobStatus._('failed');
const JobStatus _$canceled = const JobStatus._('canceled');

JobStatus _$valueOf(String name) {
  switch (name) {
    case 'queued':
      return _$queued;
    case 'running':
      return _$running;
    case 'succeeded':
      return _$succeeded;
    case 'failed':
      return _$failed;
    case 'canceled':
      return _$canceled;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<JobStatus> _$values = new BuiltSet<JobStatus>(const <JobStatus>[
  _$queued,
  _$running,
  _$succeeded,
  _$failed,
  _$canceled,
]);

class _$JobStatusMeta {
  const _$JobStatusMeta();
  JobStatus get queued => _$queued;
  JobStatus get running => _$running;
  JobStatus get succeeded => _$succeeded;
  JobStatus get failed => _$failed;
  JobStatus get canceled => _$canceled;
  JobStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<JobStatus> get values => _$values;
}

abstract class _$JobStatusMixin {
  // ignore: non_constant_identifier_names
  _$JobStatusMeta get JobStatus => const _$JobStatusMeta();
}

Serializer<JobStatus> _$jobStatusSerializer = new _$JobStatusSerializer();

class _$JobStatusSerializer implements PrimitiveSerializer<JobStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'queued': 'queued',
    'running': 'running',
    'succeeded': 'succeeded',
    'failed': 'failed',
    'canceled': 'canceled',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'queued': 'queued',
    'running': 'running',
    'succeeded': 'succeeded',
    'failed': 'failed',
    'canceled': 'canceled',
  };

  @override
  final Iterable<Type> types = const <Type>[JobStatus];
  @override
  final String wireName = 'JobStatus';

  @override
  Object serialize(Serializers serializers, JobStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  JobStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      JobStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
