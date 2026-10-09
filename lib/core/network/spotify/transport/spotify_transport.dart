import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';

/// Abstract HTTP transport for Spotify endpoints.
///
/// Consumers depend on this interface and never interact with auth tokens,
/// refresh mechanics, or platform identity headers. Implementations handle
/// all of that transparently.
abstract class SpotifyTransport {
  /// GET request, returns raw response bytes or null on failure.
  Future<Uint8List?> get(
    String path, {
    Map<String, String>? extraHeaders,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
    String? tag,
    Duration? ttl,
  });

  /// POST request, returns raw response bytes or null on failure.
  Future<Uint8List?> post(
    String path,
    Uint8List body, {
    Map<String, String>? extraHeaders,
    String contentType = 'application/x-protobuf',
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
    String? tag,
    Duration? ttl,
    bool bufferIfOffline = false,
  });

  /// Typed GET request returning full [NetworkResult] with status codes and explicit errors.
  Future<NetworkResult<Uint8List>> getResult(
    String path, {
    Map<String, String>? extraHeaders,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
    String? tag,
    Duration? ttl,
  });

  /// Typed POST request returning full [NetworkResult] with status codes and explicit errors.
  Future<NetworkResult<Uint8List>> postResult(
    String path,
    Uint8List body, {
    Map<String, String>? extraHeaders,
    String contentType = 'application/x-protobuf',
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
    String? tag,
    Duration? ttl,
    bool bufferIfOffline = false,
  });
}
