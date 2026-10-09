import 'dart:io';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';

/// Interceptor that measures HTTP request round-trip latency and timeouts
/// to update the NetworkMonitorService in real time.
class NetworkTelemetryInterceptor extends Interceptor {
  final NetworkMonitorService _monitorService;

  NetworkTelemetryInterceptor(this._monitorService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_request_start_epoch'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startEpoch = response.requestOptions.extra['_request_start_epoch'] as int?;
    if (startEpoch != null) {
      final duration = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - startEpoch,
      );
      _monitorService.recordLatency(duration);
    }
    _monitorService.recordSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      _monitorService.recordTimeout();
    } else if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      _monitorService.recordConnectionError();
    }
    handler.next(err);
  }
}
