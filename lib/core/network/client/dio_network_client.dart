import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/client/network_client.dart';
import 'package:musify_mu/core/network/client/platform_adapter.dart';
import 'package:musify_mu/core/network/interceptors/retry_interceptor.dart';
import 'package:musify_mu/core/network/interceptors/sanitized_logging_interceptor.dart';
import 'package:musify_mu/core/network/interceptors/network_telemetry_interceptor.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';

/// Production-ready Dio-backed implementation of [NetworkClient].
///
/// Configures platform-native network drivers (Cronet HTTP/3 on Android,
/// NSURLSession on iOS, pooled Keep-Alive sockets on Desktop).
class DioNetworkClient implements NetworkClient {
  final Dio _dio;

  DioNetworkClient({Dio? dio, NetworkMonitorService? monitorService})
      : _dio = dio ?? _createDefaultDio(monitorService: monitorService);

  static Dio _createDefaultDio({NetworkMonitorService? monitorService}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.bytes,
      ),
    );

    dio.httpClientAdapter = createPlatformAdapter();

    dio.interceptors.addAll([
      if (monitorService != null) NetworkTelemetryInterceptor(monitorService),
      SanitizedLoggingInterceptor(),
      RetryInterceptor(dio: dio),
    ]);

    return dio;
  }

  Dio get dio => _dio;

  @override
  Future<NetworkResult<Uint8List>> get(
    Uri uri, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    Duration? timeout,
  }) async {
    try {
      final options = Options(
        method: 'GET',
        headers: headers,
        responseType: ResponseType.bytes,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        extra: {'priority': priority.value},
      );

      final response = await _dio.getUri<List<int>>(
        uri,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleBinaryResponse(response);
    } on DioException catch (e) {
      return _mapDioException(e);
    } catch (e) {
      return NetworkResult.failure(
        NetworkException(
          message: e.toString(),
          reason: NetworkFailureReason.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<NetworkResult<Uint8List>> post(
    Uri uri,
    Uint8List body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String contentType = 'application/x-protobuf',
    Duration? timeout,
  }) async {
    try {
      final reqHeaders = Map<String, String>.from(headers ?? const {});
      reqHeaders.putIfAbsent('Content-Type', () => contentType);

      final options = Options(
        method: 'POST',
        headers: reqHeaders,
        responseType: ResponseType.bytes,
        contentType: contentType,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        extra: {'priority': priority.value},
      );

      final response = await _dio.postUri<List<int>>(
        uri,
        data: body,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleBinaryResponse(response);
    } on DioException catch (e) {
      return _mapDioException(e);
    } catch (e) {
      return NetworkResult.failure(
        NetworkException(
          message: e.toString(),
          reason: NetworkFailureReason.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<NetworkResult<Map<String, List<String>>>> head(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final options = Options(
        method: 'HEAD',
        headers: headers,
        receiveTimeout: timeout,
        sendTimeout: timeout,
      );

      final response = await _dio.headUri(uri, options: options);
      final headerMap = <String, List<String>>{};
      response.headers.forEach((name, values) {
        headerMap[name] = values;
      });

      return NetworkResult.success(
        headerMap,
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _mapDioException(e);
    } catch (e) {
      return NetworkResult.failure(
        NetworkException(
          message: e.toString(),
          reason: NetworkFailureReason.unknown,
          cause: e,
        ),
      );
    }
  }

  NetworkResult<Uint8List> _handleBinaryResponse(Response<List<int>> response) {
    final rawList = response.data;
    if (rawList == null) {
      return NetworkResult.success(
        Uint8List(0),
        statusCode: response.statusCode ?? 200,
      );
    }

    var bytes = Uint8List.fromList(rawList);

    // Transparent gzip decompression if response is compressed.
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      try {
        bytes = Uint8List.fromList(gzip.decode(bytes));
      } catch (_) {
        // Fall back to original bytes if decompression fails.
      }
    }

    return NetworkResult.success(
      bytes,
      statusCode: response.statusCode ?? 200,
    );
  }

  NetworkResult<T> _mapDioException<T>(DioException e) {
    final statusCode = e.response?.statusCode;
    final reason = _mapReason(e, statusCode);

    final message = e.response?.statusMessage ??
        e.message ??
        'HTTP request failed (${reason.name})';

    return NetworkResult.failure(
      NetworkException(
        message: message,
        reason: reason,
        statusCode: statusCode,
        cause: e.error ?? e,
      ),
      statusCode: statusCode,
    );
  }

  NetworkFailureReason _mapReason(DioException e, int? statusCode) {
    if (e.type == DioExceptionType.cancel) {
      return NetworkFailureReason.cancelled;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkFailureReason.timeout;
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailureReason.offline;
    }

    if (statusCode != null) {
      if (statusCode == 401) return NetworkFailureReason.unauthorized;
      if (statusCode == 403) return NetworkFailureReason.forbidden;
      if (statusCode == 404) return NetworkFailureReason.notFound;
      if (statusCode == 429) return NetworkFailureReason.rateLimited;
      if (statusCode >= 400 && statusCode < 500) {
        return NetworkFailureReason.badRequest;
      }
      if (statusCode >= 500) return NetworkFailureReason.serverError;
    }

    return NetworkFailureReason.unknown;
  }

  @override
  void close({bool force = false}) {
    _dio.close(force: force);
  }
}
