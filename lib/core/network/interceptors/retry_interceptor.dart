import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Transparent exponential backoff retry for idempotent HTTP requests.
///
/// Only retries GET/HEAD requests when encountering transient connection
/// resets, timeouts, or 503/504 gateway errors.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 250),
  });

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final method = requestOptions.method.toUpperCase();

    // Only retry idempotent methods.
    if (method != 'GET' && method != 'HEAD') {
      return handler.next(err);
    }

    // Do not retry if request was explicitly cancelled.
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    final currentAttempt =
        (requestOptions.extra['retry_attempt'] as int?) ?? 0;
    if (currentAttempt >= maxRetries) {
      return handler.next(err);
    }

    final shouldRetry = _isTransientError(err);
    if (!shouldRetry) {
      return handler.next(err);
    }

    final nextAttempt = currentAttempt + 1;
    final delay = _calculateBackoff(nextAttempt);

    debugPrint(
      '[NET] Retrying ${requestOptions.method} ${requestOptions.uri.path} '
      '(attempt $nextAttempt/$maxRetries in ${delay.inMilliseconds}ms)...',
    );

    await Future.delayed(delay);

    try {
      requestOptions.extra['retry_attempt'] = nextAttempt;
      final response = await dio.fetch(requestOptions);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _isTransientError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return true;
    }

    if (err.error is SocketException) {
      return true;
    }

    return false;
  }

  Duration _calculateBackoff(int attempt) {
    final jitter = Random().nextInt(100);
    final delayMs =
        (baseDelay.inMilliseconds * pow(2, attempt - 1)) + jitter;
    return Duration(milliseconds: delayMs.toInt());
  }
}
