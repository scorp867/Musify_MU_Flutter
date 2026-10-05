import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Shared retry, logging, and error handling for Spotify transports.
///
/// Subclasses provide platform-specific headers via [buildHeaders].
/// The 401-refresh-retry cycle, timeouts, and structured logging
/// are handled here so implementations stay focused on identity.
abstract class BaseSpotifyTransport implements SpotifyTransport {
  static const _baseUrl = 'https://spclient.wg.spotify.com';

  @protected
  final AuthSessionProvider auth;

  BaseSpotifyTransport({required this.auth});

  /// Subclasses build platform-specific headers (WebPlayer vs Android).
  @protected
  Future<Map<String, String>> buildHeaders(Map<String, String>? extra);

  @override
  Future<Uint8List?> get(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    return _executeWithRetry(() async {
      final headers = await buildHeaders(extraHeaders);
      final url = '$_baseUrl$path';
      return http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
    }, 'GET', path);
  }

  @override
  Future<Uint8List?> post(
    String path,
    Uint8List body, {
    Map<String, String>? extraHeaders,
    String contentType = 'application/x-protobuf',
  }) async {
    return _executeWithRetry(() async {
      final headers = await buildHeaders(extraHeaders);
      headers['Content-Type'] = contentType;
      headers.putIfAbsent('accept', () => 'application/x-protobuf');
      final url = '$_baseUrl$path';
      return http.post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
    }, 'POST', path, bodySize: body.length);
  }

  // ─── Request execution with retry + logging ───────────────────────────

  Future<Uint8List?> _executeWithRetry(
    Future<http.Response> Function() request,
    String method,
    String path, {
    int? bodySize,
  }) async {
    final sw = Stopwatch()..start();
    _logStart(method, path, bodySize: bodySize);

    try {
      var response = await request();

      if (response.statusCode == 401) {
        _logResult(method, path, 401, sw.elapsedMilliseconds, 0,
            note: 'refreshing token');
        final newToken = await auth.refreshAccessToken();
        if (newToken == null) {
          _logResult(method, path, 401, sw.elapsedMilliseconds, 0,
              note: 'refresh failed');
          return null;
        }
        sw.reset();
        response = await request();
      }

      return _handleResponse(response, method, path, sw.elapsedMilliseconds);
    } on TimeoutException {
      _logResult(method, path, 0, sw.elapsedMilliseconds, 0, note: 'TIMEOUT');
      return null;
    } catch (e) {
      _logResult(method, path, 0, sw.elapsedMilliseconds, 0,
          note: e.runtimeType.toString());
      log('SpotifyTransport error ($method $path): $e');
      return null;
    }
  }

  Uint8List? _handleResponse(
      http.Response response, String method, String path, int elapsedMs) {
    if (response.statusCode == 200) {
      var bytes = Uint8List.fromList(response.bodyBytes);
      if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
        try {
          bytes = Uint8List.fromList(gzip.decode(bytes));
        } catch (e) {
          log('Failed to decompress gzip body ($method $path): $e');
        }
      }
      _logResult(method, path, 200, elapsedMs, bytes.length);
      return bytes;
    }

    _logResult(method, path, response.statusCode, elapsedMs,
        response.bodyBytes.length);
    return null;
  }

  // ─── Terminal logging (visible in `flutter run` output) ───────────────
  //
  // Filter with:  flutter run 2>&1 | Select-String "[NET]"
  // ─────────────────────────────────────────────────────────────────────

  void _logStart(String method, String path, {int? bodySize}) {
    final body = bodySize != null ? ' ($bodySize B)' : '';
    debugPrint('[NET] --> $method $path$body');
  }

  void _logResult(String method, String path, int statusCode, int elapsedMs,
      int responseBytes,
      {String? note}) {
    final status = statusCode > 0 ? '$statusCode' : '---';
    final suffix = note != null ? ' ($note)' : '';
    final ok = statusCode == 200 ? 'ok' : 'ERR';
    debugPrint(
        '[NET] <-- $method $path [$ok $status] ${elapsedMs}ms ${responseBytes}B$suffix');
  }
}
