import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Structured diagnostic logger for network traffic.
///
/// Filters sensitive headers (Authorization, Cookie, Client-Token) to prevent
/// credential leakage in logs while maintaining visibility in terminal:
/// `flutter run 2>&1 | Select-String "[NET]"`
class SanitizedLoggingInterceptor extends Interceptor {
  final Map<int, Stopwatch> _stopwatches = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sw = Stopwatch()..start();
    _stopwatches[options.hashCode] = sw;

    final bodySize = options.data is List<int>
        ? ' (${(options.data as List<int>).length} B)'
        : '';
    debugPrint('[NET] --> ${options.method} ${options.uri.path}$bodySize');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sw = _stopwatches.remove(response.requestOptions.hashCode);
    final elapsedMs = sw?.elapsedMilliseconds ?? 0;

    final bytesLength = response.data is List<int>
        ? (response.data as List<int>).length
        : 0;
    final statusCode = response.statusCode ?? 200;
    final ok = statusCode >= 200 && statusCode < 300 ? 'ok' : 'ERR';

    debugPrint(
      '[NET] <-- ${response.requestOptions.method} ${response.requestOptions.uri.path} '
      '[$ok $statusCode] ${elapsedMs}ms ${bytesLength}B',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sw = _stopwatches.remove(err.requestOptions.hashCode);
    final elapsedMs = sw?.elapsedMilliseconds ?? 0;
    final status = err.response?.statusCode != null
        ? '${err.response!.statusCode}'
        : '---';

    debugPrint(
      '[NET] <-- ${err.requestOptions.method} ${err.requestOptions.uri.path} '
      '[ERR $status] ${elapsedMs}ms (${err.type.name})',
    );
    handler.next(err);
  }
}
