//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/webhook_ack.dart';
import 'package:built_value/json_object.dart';

class WebhooksApi {

  final Dio _dio;

  final Serializers _serializers;

  const WebhooksApi(this._dio, this._serializers);

  /// githubWebhook
  /// GitHub 웹훅 수신. 페이로드 스키마와 처리 규칙은 contracts/events/github-webhook.v1.schema.json. 1) X-Hub-Signature-256 HMAC 검증 (상수 시간 비교) → 실패 401 2) X-GitHub-Delivery 중복 제거 (24h) → 중복이면 202 duplicate 3) push + 기본 브랜치 + deleted&#x3D;false 일 때만 증분 색인 잡 → 202 queued, 그 외 202 ignored GitHub 재전송 폭주를 막기 위해 처리 불가 이벤트도 4xx가 아닌 202 ignored로 응답한다. 
  ///
  /// Parameters:
  /// * [xGitHubEvent] 
  /// * [xGitHubDelivery] 
  /// * [xHubSignature256] 
  /// * [body] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [WebhookAck] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<WebhookAck>> githubWebhook({ 
    required String xGitHubEvent,
    required String xGitHubDelivery,
    required String xHubSignature256,
    required JsonObject body,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/webhooks/github';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-GitHub-Event': xGitHubEvent,
        r'X-GitHub-Delivery': xGitHubDelivery,
        r'X-Hub-Signature-256': xHubSignature256,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = body;

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    WebhookAck? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(WebhookAck),
      ) as WebhookAck;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<WebhookAck>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
