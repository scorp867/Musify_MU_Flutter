import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:musify_mu/features/auth/data/spotify_client_token.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';
import 'package:musify_mu/features/auth/data/spotify_token_refresher.dart';

/// Centralized HTTP client for all Spotify spclient endpoints.
///
/// Every repository uses this — handles auth headers, token refresh, retries.
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
  /// Automatically handles auth headers and 401 retry.
  Future<Uint8List?> get(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    return _executeWithRetry(() async {
      final headers = await _buildHeaders(extraHeaders);
      final url = '$_baseUrl$path';

      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response, 'GET $path');
    });
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
      // Only set Accept if not already overridden by extraHeaders.
      headers.putIfAbsent('accept', () => 'application/x-protobuf');
      final url = '$_baseUrl$path';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      return _handleResponse(response, 'POST $path');
    });
  }

  /// Builds auth headers for every spclient request.
  /// Matches SpotifyIdentity.applyStandardHeaders() from the Kotlin project.
  Future<Map<String, String>> _buildHeaders(
      Map<String, String>? extra) async {
    final accessToken = await _tokenStore.getAccessToken();
    final clientToken = await _clientTokenFetcher.getClientToken();

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (clientToken != null) 'client-token': clientToken,
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
    // Remove any headers explicitly set to empty (used to strip defaults).
    headers.removeWhere((_, v) => v.isEmpty);
    return headers;
  }

  /// Builds Android identity headers for endpoints that reject WebPlayer.
  Future<Map<String, String>> _buildAndroidHeaders(
      Map<String, String>? extra) async {
    final accessToken = await _tokenStore.getAccessToken();
    final clientToken = await _clientTokenFetcher.getClientToken();

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (clientToken != null) 'client-token': clientToken,
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

  /// GET request using Android identity (for endpoints that reject WebPlayer).
  Future<Uint8List?> getAndroid(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    return _executeWithRetry(() async {
      final headers = await _buildAndroidHeaders(extraHeaders);
      final url = '$_baseUrl$path';

      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response, 'GET $path');
    });
  }

  /// Handles HTTP response — returns body bytes on success, null on failure.
  Uint8List? _handleResponse(http.Response response, String label) {
    if (response.statusCode == 200) {
      final bytes = Uint8List.fromList(response.bodyBytes);
      print('\u2705 SpotifyClient $label \u2192 ${bytes.length} bytes');
      return bytes;
    }

    // Log error details for debugging.
    final bodyBytes = response.bodyBytes;
    final ct = response.headers['content-type'] ?? 'unknown';
    final bodyStr = response.body;
    final bodyHex = bodyBytes.length <= 100
        ? bodyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()
        : '${bodyBytes.length} bytes';
    print(
      '\u274C SpotifyClient $label \u2192 HTTP ${response.statusCode} '
      '[ct=$ct] body=$bodyStr hex=$bodyHex',
    );
    return null;
  }

  /// Executes a request, retrying once on 401 after refreshing tokens.
  Future<Uint8List?> _executeWithRetry(
      Future<Uint8List?> Function() request) async {
    var result = await request();
    if (result != null) return result;

    // Token may be expired — try refreshing and retrying once.
    print('🔄 SpotifyClient: Retrying after token refresh...');
    final newToken = await _tokenRefresher.refresh();
    if (newToken == null) return null;

    return request();
  }
}
