//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:api_client/src/date_serializer.dart';
import 'package:api_client/src/model/date.dart';

import 'package:api_client/src/model/analysis.dart';
import 'package:api_client/src/model/analysis_create.dart';
import 'package:api_client/src/model/analysis_page.dart';
import 'package:api_client/src/model/chat_done_event.dart';
import 'package:api_client/src/model/chat_error_event.dart';
import 'package:api_client/src/model/chat_message.dart';
import 'package:api_client/src/model/chat_message_create.dart';
import 'package:api_client/src/model/chat_message_page.dart';
import 'package:api_client/src/model/chat_message_status.dart';
import 'package:api_client/src/model/chat_meta_event.dart';
import 'package:api_client/src/model/chat_session.dart';
import 'package:api_client/src/model/chat_session_page.dart';
import 'package:api_client/src/model/chat_source.dart';
import 'package:api_client/src/model/chat_sources_event.dart';
import 'package:api_client/src/model/chat_stream_event.dart';
import 'package:api_client/src/model/chat_token_event.dart';
import 'package:api_client/src/model/code_target.dart';
import 'package:api_client/src/model/cursor_page_info.dart';
import 'package:api_client/src/model/device.dart';
import 'package:api_client/src/model/device_register.dart';
import 'package:api_client/src/model/error_code.dart';
import 'package:api_client/src/model/feedback_verdict.dart';
import 'package:api_client/src/model/field_error.dart';
import 'package:api_client/src/model/field_error_loc_inner.dart';
import 'package:api_client/src/model/finding.dart';
import 'package:api_client/src/model/finding_category.dart';
import 'package:api_client/src/model/finding_counts.dart';
import 'package:api_client/src/model/finding_feedback.dart';
import 'package:api_client/src/model/finding_page.dart';
import 'package:api_client/src/model/health_response.dart';
import 'package:api_client/src/model/health_status.dart';
import 'package:api_client/src/model/index_state.dart';
import 'package:api_client/src/model/job.dart';
import 'package:api_client/src/model/job_kind.dart';
import 'package:api_client/src/model/job_page.dart';
import 'package:api_client/src/model/job_progress.dart';
import 'package:api_client/src/model/job_status.dart';
import 'package:api_client/src/model/offset_page_info.dart';
import 'package:api_client/src/model/patch_validation.dart';
import 'package:api_client/src/model/platform.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/project.dart';
import 'package:api_client/src/model/project_create.dart';
import 'package:api_client/src/model/project_created.dart';
import 'package:api_client/src/model/project_page.dart';
import 'package:api_client/src/model/project_stats.dart';
import 'package:api_client/src/model/project_update.dart';
import 'package:api_client/src/model/refactor.dart';
import 'package:api_client/src/model/refactor_create.dart';
import 'package:api_client/src/model/refactor_finding_request.dart';
import 'package:api_client/src/model/reindex_request.dart';
import 'package:api_client/src/model/severity.dart';
import 'package:api_client/src/model/token_usage.dart';
import 'package:api_client/src/model/webhook_ack.dart';

part 'serializers.g.dart';

@SerializersFor([
  Analysis,
  AnalysisCreate,
  AnalysisPage,
  ChatDoneEvent,
  ChatErrorEvent,
  ChatMessage,
  ChatMessageCreate,
  ChatMessagePage,
  ChatMessageStatus,
  ChatMetaEvent,
  ChatSession,
  ChatSessionPage,
  ChatSource,
  ChatSourcesEvent,
  ChatStreamEvent,
  ChatTokenEvent,
  CodeTarget,
  CursorPageInfo,
  Device,
  DeviceRegister,
  ErrorCode,
  FeedbackVerdict,
  FieldError,
  FieldErrorLocInner,
  Finding,
  FindingCategory,
  FindingCounts,
  FindingFeedback,
  FindingPage,
  HealthResponse,
  HealthStatus,
  IndexState,
  Job,
  JobKind,
  JobPage,
  JobProgress,
  JobStatus,
  OffsetPageInfo,
  PatchValidation,
  Platform,
  Problem,
  Project,
  ProjectCreate,
  ProjectCreated,
  ProjectPage,
  ProjectStats,
  ProjectUpdate,
  Refactor,
  RefactorCreate,
  RefactorFindingRequest,
  ReindexRequest,
  Severity,
  TokenUsage,
  WebhookAck,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Severity)]),
        () => ListBuilder<Severity>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(FindingCategory)]),
        () => ListBuilder<FindingCategory>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer()))
    .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
