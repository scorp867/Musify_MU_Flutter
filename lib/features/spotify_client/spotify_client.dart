import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musify_mu/features/auth/data/spotify_client_token.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';
import 'package:musify_mu/features/auth/data/spotify_token_refresher.dart';

/// Centralized HTTP client for all Spotify spclient endpoints.
///
/// Every repository uses this -- handles auth headers, token refresh, retries.
/// Base URL: https://spclient.wg.spotify.com
class SpotifyClient {
  static const _baseUrl = 'https://spclient.wg.spotify.com';

  final SpotifyTokenStore _tokenStore;
  final SpotifyTokenRefresher _tokenRefresher;
  final SpotifyClientTokenFetcher _clientTokenFetcher;

  SpotifyClient({
    required SpotifyTokenStore tokenStore,
    required SpotifyTokenRefresher tokenRefresher,
    required SpotifyClientTokenFetcher clientTokenFetcher,
  })  : _tokenStore = tokenStore,
        _tokenRefresher = tokenRefresher,
        _clientTokenFetcher = clientTokenFetcher;

  /// GET request to spclient, returns raw bytes.
  Future<Uint8List?> get(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    return _executeWithRetry(() async {
      final headers = await _buildHeaders(extraHeaders);
      final url = '$_baseUrl$path';
      return http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
    }, 'GET', path);
  }

  /// POST request to spclient, returns raw bytes.
  Future<Uint8List?> post(
    String path,
    Uint8List body, {
    Map<String, String>? extraHeaders,
    String contentType = 'application/x-protobuf',
  }) async {
    return _executeWithRetry(() async {
      final headers = await _buildHeaders(extraHeaders);
      headers['Content-Type'] = contentType;
      headers.putIfAbsent('accept', () => 'application/x-protobuf');
      final url = '$_baseUrl$path';
      return http.post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
    }, 'POST', path, bodySize: body.length);
  }

  /// GET request using Android identity (for endpoints that reject WebPlayer).
  Future<Uint8List?> getAndroid(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    return _executeWithRetry(() async {
      final headers = await _buildAndroidHeaders(extraHeaders);
      final url = '$_baseUrl$path';
      return http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
    }, 'GET(android)', path);
  }

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _buildHeaders(Map<String, String>? extra) async {
    final accessToken = await _tokenStore.getAccessToken();
    final clientToken = await _clientTokenFetcher.getClientToken();

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'client-token': ?clientToken,
      'accept': 'application/x-protobuf, application/json',
      'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'app-platform': 'WebPlayer',
      'spotify-app-version': '1.2.87.215.g6e7e7fc2',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
      'Origin': 'https://open.spotify.com',
      'Referer': 'https://open.spotify.com/',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-site',
      'sec-ch-ua':
          '"Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'sec-gpc': '1',
    };

    if (extra != null) headers.addAll(extra);
    headers.removeWhere((_, v) => v.isEmpty);
    return headers;
  }

  Future<Map<String, String>> _buildAndroidHeaders(
      Map<String, String>? extra) async {
    final accessToken = await _tokenStore.getAccessToken();
    final clientToken = await _clientTokenFetcher.getClientToken();

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'client-token': ?clientToken,
      'accept-language': 'en-US',
      'accept-encoding': 'gzip',
      'app-platform': 'Android',
      'spotify-app-version': '9.1.76.2045',
      'User-Agent': 'Spotify/9.1.76.2045 Android/29 (Pixel 4 XL)',
      'cache-control': 'no-cache, no-store',
    };

    if (extra != null) headers.addAll(extra);
    return headers;
  }

  // ---------------------------------------------------------------------------
  // Request execution with retry + logging
  // ---------------------------------------------------------------------------

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
        final newToken = await _tokenRefresher.refresh();
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
      log('SpotifyClient error ($method $path): $e');
      return null;
    }
  }

  Uint8List? _handleResponse(
      http.Response response, String method, String path, int elapsedMs) {
    if (response.statusCode == 200) {
      final bytes = Uint8List.fromList(response.bodyBytes);
      _logResult(method, path, 200, elapsedMs, bytes.length);
      return bytes;
    }

    _logResult(method, path, response.statusCode, elapsedMs,
        response.bodyBytes.length);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Terminal logging (visible in `flutter run` output)
  //
  // Filter with:  flutter run 2>&1 | Select-String "[NET]"
  // ---------------------------------------------------------------------------

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
