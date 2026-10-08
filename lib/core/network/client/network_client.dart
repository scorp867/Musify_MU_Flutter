import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';

/// Central HTTP Client abstraction for Musify_MU.
///
/// Decouples features and transports from specific HTTP drivers (Dio, Cronet, etc.),
/// exposes priority scheduling, request cancellation, and typed [NetworkResult] returns.
abstract interface class NetworkClient {
  /// Dispatches an HTTP GET request.
  Future<NetworkResult<Uint8List>> get(
    Uri uri, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    Duration? timeout,
  });

  /// Dispatches an HTTP POST request.
  Future<NetworkResult<Uint8List>> post(
    Uri uri,
    Uint8List body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String contentType = 'application/x-protobuf',
    Duration? timeout,
  });

  /// Dispatches an HTTP HEAD request.
  Future<NetworkResult<Map<String, List<String>>>> head(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Closes persistent connections and releases native resources.
  void close({bool force = false});
}
