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
      headers['Accept'] = 'application/x-protobuf';
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
  Future<Map<String, String>> _buildHeaders(
      Map<String, String>? extra) async {
    final accessToken = await _tokenStore.getAccessToken();
    final clientToken = await _clientTokenFetcher.getClientToken();

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (clientToken != null) 'client-token': clientToken,
      'app-platform': 'WebPlayer',
      'spotify-app-version': '1.2.52.442',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'Origin': 'https://open.spotify.com',
      'Referer': 'https://open.spotify.com/',
    };

    if (extra != null) headers.addAll(extra);
    return headers;
  }

  /// Handles HTTP response — returns body bytes on success, null on failure.
  Uint8List? _handleResponse(http.Response response, String label) {
    if (response.statusCode == 200) {
      final bytes = Uint8List.fromList(response.bodyBytes);
      print('✅ SpotifyClient $label → ${bytes.length} bytes');
      return bytes;
    }

    print('❌ SpotifyClient $label → HTTP ${response.statusCode}');
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
