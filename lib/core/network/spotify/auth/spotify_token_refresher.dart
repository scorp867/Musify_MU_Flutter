import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musify_mu/core/network/spotify/auth/spotify_totp.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';

/// Refreshes the Spotify Web Player access token using the sp_dc cookie + TOTP.
///
/// Flow:
/// 1. Fetch Spotify's server time to avoid clock skew.
/// 2. Generate TOTP codes (local + server time).
/// 3. Call `GET /api/token` with sp_dc cookie + TOTP params.
/// 4. If 401/403 -> cipher was rotated -> refresh cipher -> retry once.
class SpotifyTokenRefresher {
  final SpotifyTokenStore _tokenStore;
  final SpotifyTotp _totp;

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36';

  SpotifyTokenRefresher({
    required SpotifyTokenStore tokenStore,
    SpotifyTotp? totp,
  })  : _tokenStore = tokenStore,
        _totp = totp ?? SpotifyTotp();

  /// Attempts to refresh the access token.
  /// Returns the new token on success, or null on failure.
  Future<String?> refresh() async {
    final spDc = await _tokenStore.getSpDc();
    if (spDc == null || spDc.isEmpty) {
      dev.log('TokenRefresh: No sp_dc cookie stored', name: 'Auth');
      return null;
    }

    // Validate the sp_dc is a real cookie value, not a placeholder.
    if (!spDc.startsWith('sp_dc=') || spDc.length < 20) {
      dev.log(
        'TokenRefresh: Invalid sp_dc format: '
        '${spDc.substring(0, spDc.length.clamp(0, 20))}...',
        name: 'Auth',
      );
      return null;
    }

    // Ensure the TOTP cipher is fresh.
    await _totp.ensureFreshCipher();

    // First attempt.
    dev.log('TokenRefresh: Attempting refresh (attempt 1)...', name: 'Auth');
    var result = await _attemptRefresh(spDc);
    if (result != null) {
      dev.log('TokenRefresh: Success on attempt 1', name: 'Auth');
      return result;
    }

    // If failed, cipher may have been rotated -> force refresh + retry.
    dev.log('TokenRefresh: Attempt 1 failed, refreshing cipher...', name: 'Auth');
    await _totp.refreshCipher();
    result = await _attemptRefresh(spDc);
    if (result != null) {
      dev.log('TokenRefresh: Success on attempt 2', name: 'Auth');
    } else {
      dev.log('TokenRefresh: Both attempts failed', name: 'Auth');
    }
    return result;
  }

  /// Performs a single token refresh call.
  Future<String?> _attemptRefresh(String spDc) async {
    try {
      // Fetch Spotify's server time.
      final serverTimeMs = await _fetchServerTimeMs();
      if (serverTimeMs == null) {
        dev.log('TokenRefresh: Failed to fetch server time', name: 'Auth');
        return null;
      }

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
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        dev.log('TokenRefresh: HTTP ${response.statusCode}', name: 'Auth');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = body['accessToken'] as String?;
      final isAnonymous = body['isAnonymous'] as bool? ?? true;

      if (accessToken == null || isAnonymous) {
        dev.log('TokenRefresh: Got anonymous token or null', name: 'Auth');
        return null;
      }

      // Use the real expiry from the response instead of assuming 1 hour.
      final expiresMs = body['accessTokenExpirationTimestampMs'] as int?;
      final lifetimeMs = expiresMs != null
          ? expiresMs - DateTime.now().millisecondsSinceEpoch
          : 3600000;

      // Save the fresh token with its actual remaining lifetime.
      await _tokenStore.saveAccessToken(accessToken, lifetimeMs: lifetimeMs);
      dev.log(
        'TokenRefresh: Token saved, expires in ${lifetimeMs ~/ 60000} min',
        name: 'Auth',
      );
      return accessToken;
    } catch (e) {
      dev.log('TokenRefresh: Exception: $e', name: 'Auth');
      return null;
    }
  }

  /// Fetches Spotify's server time to avoid clock-skew TOTP failures.
  Future<int?> _fetchServerTimeMs() async {
    try {
      final response = await http.head(
        Uri.parse('https://open.spotify.com/'),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 15));

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
