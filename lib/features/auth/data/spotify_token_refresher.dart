import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musify_mu/features/auth/data/spotify_totp.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';

/// Refreshes the Spotify Web Player access token using the sp_dc cookie + TOTP.
///
/// Flow:
/// 1. Fetch Spotify's server time to avoid clock skew.
/// 2. Generate TOTP codes (local + server time).
/// 3. Call `GET /api/token` with sp_dc cookie + TOTP params.
/// 4. If 401/403 → cipher was rotated → refresh cipher → retry once.
class SpotifyTokenRefresher {
  final SpotifyTokenStore _tokenStore;
  final SpotifyTotp _totp;

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36';

  SpotifyTokenRefresher({
    SpotifyTokenStore? tokenStore,
    SpotifyTotp? totp,
  })  : _tokenStore = tokenStore ?? SpotifyTokenStore(),
        _totp = totp ?? SpotifyTotp();

  /// Attempts to refresh the access token.
  /// Returns the new token on success, or null on failure.
  Future<String?> refresh() async {
    final spDc = await _tokenStore.getSpDc();
    if (spDc == null || spDc.isEmpty) return null;

    // Ensure the TOTP cipher is fresh.
    await _totp.ensureFreshCipher();

    // First attempt.
    var result = await _attemptRefresh(spDc);
    if (result != null) return result;

    // If failed, cipher may have been rotated → force refresh + retry.
    await _totp.refreshCipher();
    return _attemptRefresh(spDc);
  }

  /// Performs a single token refresh call.
  Future<String?> _attemptRefresh(String spDc) async {
    try {
      // Fetch Spotify's server time.
      final serverTimeMs = await _fetchServerTimeMs();
      if (serverTimeMs == null) return null;

      final localTimeMs = DateTime.now().millisecondsSinceEpoch;
      final totpLocal = _totp.generate(localTimeMs);
      final totpServer = _totp.generate(serverTimeMs);
      final version = _totp.version;

      final url = Uri.parse('https://open.spotify.com/api/token').replace(
        queryParameters: {
          'reason': 'init',
          'productType': 'web-player',
          'totp': totpLocal,
          'totpServer': totpServer,
          'totpVer': version.toString(),
          'ts': serverTimeMs.toString(),
        },
      );

      final response = await http.get(url, headers: {
        'Cookie': spDc,
        'User-Agent': _userAgent,
        'Accept': '*/*',
        'Referer': 'https://open.spotify.com/',
        'Origin': 'https://open.spotify.com',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
      });

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = body['accessToken'] as String?;
      final isAnonymous = body['isAnonymous'] as bool? ?? true;

      if (accessToken == null || isAnonymous) return null;

      // Save the fresh token.
      await _tokenStore.saveAccessToken(accessToken);
      return accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Fetches Spotify's server time to avoid clock-skew TOTP failures.
  Future<int?> _fetchServerTimeMs() async {
    try {
      // The /api/token endpoint itself returns serverTime, but we can also
      // use the Date header from any Spotify response.
      final response = await http.head(
        Uri.parse('https://open.spotify.com/'),
        headers: {'User-Agent': _userAgent},
      );

      final dateHeader = response.headers['date'];
      if (dateHeader != null) {
        final serverDate = HttpDate.parse(dateHeader);
        return serverDate.millisecondsSinceEpoch;
      }
    } catch (_) {}

    // Fallback: use local time (may cause skew issues).
    return DateTime.now().millisecondsSinceEpoch;
  }
}
