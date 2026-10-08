import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:musify_mu/core/network/auth/token_refresh_mutex.dart';
import 'package:musify_mu/core/network/client/network_client.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Shared retry, multi-host, mutex token refresh, and error handling for Spotify transports.
///
/// Subclasses provide platform-specific headers via [buildHeaders].
abstract class BaseSpotifyTransport implements SpotifyTransport {
  static const defaultBaseUrl = 'https://spclient.wg.spotify.com';

  @protected
  final AuthSessionProvider auth;

  @protected
  final NetworkClient client;

  @protected
  final TokenRefreshMutex refreshMutex;

  BaseSpotifyTransport({
    required this.auth,
    required this.client,
    TokenRefreshMutex? refreshMutex,
  }) : refreshMutex = refreshMutex ?? TokenRefreshMutex();

  /// Subclasses build platform-specific headers (WebPlayer vs Android).
  @protected
  Future<Map<String, String>> buildHeaders(Map<String, String>? extra);

  @override
  Future<Uint8List?> get(
    String path, {
    Map<String, String>? extraHeaders,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
  }) async {
    final result = await getResult(
      path,
      extraHeaders: extraHeaders,
      cancelToken: cancelToken,
      priority: priority,
      baseHost: baseHost,
    );
    return result.dataOrNull;
  }

  @override
  Future<Uint8List?> post(
    String path,
    Uint8List body, {
    Map<String, String>? extraHeaders,
    String contentType = 'application/x-protobuf',
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
  }) async {
    final result = await postResult(
      path,
      body,
      extraHeaders: extraHeaders,
      contentType: contentType,
      cancelToken: cancelToken,
      priority: priority,
      baseHost: baseHost,
    );
    return result.dataOrNull;
  }

  @override
  Future<NetworkResult<Uint8List>> getResult(
    String path, {
    Map<String, String>? extraHeaders,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
  }) async {
    final host = baseHost ?? defaultBaseUrl;
    final uri = Uri.parse('$host$path');

    return _executeWithRefresh(
      (headers) => client.get(
        uri,
        headers: headers,
        cancelToken: cancelToken,
        priority: priority,
      ),
      extraHeaders,
      'GET',
      path,
    );
  }

  @override
  Future<NetworkResult<Uint8List>> postResult(
    String path,
    Uint8List body, {
    Map<String, String>? extraHeaders,
    String contentType = 'application/x-protobuf',
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String? baseHost,
  }) async {
    final host = baseHost ?? defaultBaseUrl;
    final uri = Uri.parse('$host$path');

    return _executeWithRefresh(
      (headers) => client.post(
        uri,
        body,
        headers: headers,
        contentType: contentType,
        cancelToken: cancelToken,
        priority: priority,
      ),
      extraHeaders,
      'POST',
      path,
    );
  }

  // ─── Mutex Token Refresh Cycle ──────────────────────────────────────────

  Future<NetworkResult<Uint8List>> _executeWithRefresh(
    Future<NetworkResult<Uint8List>> Function(Map<String, String> headers)
        execute,
    Map<String, String>? extraHeaders,
    String method,
    String path,
  ) async {
    var headers = await buildHeaders(extraHeaders);
    var result = await execute(headers);

    // If 401 Unauthorized, run token refresh under the mutex lock
    if (result is NetworkFailure<Uint8List> &&
        result.error.reason == NetworkFailureReason.unauthorized) {
      dev.log(
        'BaseSpotifyTransport ($method $path): Received 401, locking refresh...',
        name: 'Transport',
      );

      final newToken = await refreshMutex.lock(() => auth.refreshAccessToken());
      if (newToken != null && newToken.isNotEmpty) {
        dev.log(
          'BaseSpotifyTransport: Token refreshed, retrying $method $path',
          name: 'Transport',
        );
        // Rebuild headers with the freshly stored access token
        headers = await buildHeaders(extraHeaders);
        result = await execute(headers);
      } else {
        dev.log(
          'BaseSpotifyTransport: Token refresh failed for $method $path',
          name: 'Transport',
        );
      }
    }

    return result;
  }
}
