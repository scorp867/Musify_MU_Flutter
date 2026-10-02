import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';

/// Fetches and manages the Spotify Client Token.
///
/// Endpoint: POST https://clienttoken.spotify.com/v1/clienttoken
/// Request/Response: application/json
///
/// Copied from the Kotlin implementation in SpotifyAuthManager.kt:
///   - JSON payload with client_data → js_sdk_data
///   - Browser-mimicking headers (User-Agent, Sec-* headers)
///   - WebPlayer client_id and version
class SpotifyClientTokenFetcher {
  static const _url = 'https://clienttoken.spotify.com/v1/clienttoken';
  static const _clientId = 'd8a5ed958d274c2e8ee717e6a4b0971d';

  final SpotifyTokenStore _tokenStore;
  String? _deviceId;

  SpotifyClientTokenFetcher(this._tokenStore);

  /// Returns a valid client token, fetching a new one if needed.
  Future<String?> getClientToken() async {
    final cached = await _tokenStore.getClientToken();
    if (cached != null) return cached;
    return fetchClientToken();
  }

  /// Fetches a fresh client token from Spotify.
  /// Uses the exact same JSON payload and headers as the Kotlin project.
  Future<String?> fetchClientToken() async {
    try {
      _deviceId ??= _generateDeviceId();
      final profile = DeviceProfile.webPlayer;

      final requestBody = jsonEncode({
        'client_data': {
          'client_version': profile.appVersion,
          'client_id': _clientId,
          'js_sdk_data': {
            'device_brand': 'unknown',
            'device_model': 'unknown',
            'os': 'windows',
            'os_version': 'NT 10.0',
            'device_id': _deviceId,
            'device_type': 'computer',
          },
        },
      });

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': profile.userAgent,
          'App-Platform': profile.appPlatform,
          'Spotify-App-Version': profile.appVersion,
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
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        dev.log('ClientToken: HTTP ${response.statusCode}');
        dev.log('ClientToken body: ${response.body}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final responseType = json['response_type'] as String?;

      if (responseType == 'RESPONSE_GRANTED_TOKEN_RESPONSE') {
        final grantedToken =
            json['granted_token'] as Map<String, dynamic>?;
        final token = grantedToken?['token'] as String?;

        if (token != null && token.isNotEmpty) {
          await _tokenStore.saveClientToken(token);
          dev.log('ClientToken obtained (${token.length} chars)');
          return token;
        }
      }

      dev.log('ClientToken: Unexpected response type: $responseType');
      return null;
    } catch (e) {
      dev.log('ClientToken fetch failed: $e');
      return null;
    }
  }

  String _generateDeviceId() {
    final rng = Random.secure();
    return List.generate(
            16, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
