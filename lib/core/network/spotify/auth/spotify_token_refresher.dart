import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_totp.dart';

/// Refreshes the Spotify Web Player access token using the `sp_dc` cookie + TOTP.
///
/// Flow:
/// 1. Fetch Spotify's server time to avoid clock skew.
/// 2. Generate TOTP codes (local + server time).
/// 3. Call `GET /api/token` with `Cookie: sp_dc=<raw>` + TOTP params.
/// 4. Persist `accessToken`, real `accessTokenExpirationTimestampMs`, and
///    captured `clientId` into [SpotifyTokenStore].
/// 5. If 401/403 -> cipher was rotated -> refresh cipher -> retry once.
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
        _totp = switch (totp) {
          final providedTotp? => providedTotp,
          null => SpotifyTotp(),
        };

  /// Attempts to refresh the access token.
  /// Returns the new token on success, or `null` on failure.
  Future<String?> refresh() async {
    final storedSpDc = await _tokenStore.getSpDc();
    if (storedSpDc == null || storedSpDc.trim().isEmpty) {
      dev.log('TokenRefresh: No sp_dc cookie stored', name: 'Auth');
      return null;
    }

    final rawSpDc = SpotifyTokenStore.normalizeSpDcValue(storedSpDc);
    // Validate the sp_dc is a real cookie value, not a short placeholder.
    if (rawSpDc.length < 14) {
      final previewLen = storedSpDc.length < 20 ? storedSpDc.length : 20;
      final preview = storedSpDc.substring(0, previewLen);
      dev.log(
        'TokenRefresh: Invalid sp_dc format: $preview...',
        name: 'Auth',
      );
      return null;
    }

    // If legacy storage still held the `sp_dc=` prefix, rewrite the normalized
    // raw value cleanly so native C++ and Dart share a single unprefixed SSOT.
    if (storedSpDc != rawSpDc) {
      await _tokenStore.saveSpDc(rawSpDc);
    }

    final cookieHeader = SpotifyTokenStore.formatSpDcCookieHeader(rawSpDc);

    // Ensure the TOTP cipher is fresh.
    await _totp.ensureFreshCipher();

    // First attempt.
    dev.log('TokenRefresh: Attempting refresh (attempt 1)...', name: 'Auth');
    var result = await _attemptRefresh(cookieHeader);
    if (result != null) {
      dev.log('TokenRefresh: Success on attempt 1', name: 'Auth');
      return result;
    }

    // If failed, cipher may have been rotated -> force refresh + retry.
    dev.log(
      'TokenRefresh: Attempt 1 failed, refreshing cipher...',
      name: 'Auth',
    );
    await _totp.refreshCipher();
    result = await _attemptRefresh(cookieHeader);
    if (result != null) {
      dev.log('TokenRefresh: Success on attempt 2', name: 'Auth');
    } else {
      dev.log('TokenRefresh: Both attempts failed', name: 'Auth');
    }
    return result;
  }

  /// Performs a single token refresh call with a formatted `Cookie: sp_dc=...` header.
  Future<String?> _attemptRefresh(String cookieHeader) async {
    try {
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

      final response = await http.get(
        url,
        headers: {
          'Cookie': cookieHeader,
          'User-Agent': _userAgent,
          'Accept': '*/*',
          'Referer': 'https://open.spotify.com/',
          'Origin': 'https://open.spotify.com',
          'sec-fetch-dest': 'empty',
          'sec-fetch-mode': 'cors',
          'sec-fetch-site': 'same-origin',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        dev.log('TokenRefresh: HTTP ${response.statusCode}', name: 'Auth');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) {
        dev.log('TokenRefresh: Unexpected non-map JSON payload', name: 'Auth');
        return null;
      }

      final accessToken = switch (decoded['accessToken']) {
        final String token => token,
        _ => null,
      };
      final isAnonymous = switch (decoded['isAnonymous']) {
        final bool flag => flag,
        _ => true,
      };

      if (accessToken == null || accessToken.isEmpty || isAnonymous) {
        dev.log('TokenRefresh: Got anonymous token or null', name: 'Auth');
        return null;
      }

      if (decoded['clientId'] case final String rawClientId) {
        final trimmedClientId = rawClientId.trim();
        if (trimmedClientId.isNotEmpty) {
          await _tokenStore.saveActiveClientId(trimmedClientId);
        }
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiresMs = switch (decoded['accessTokenExpirationTimestampMs']) {
        final int value => value,
        final num value => value.toInt(),
        _ => null,
      };
      final lifetimeMs = switch (expiresMs) {
        final int exp when exp > nowMs => exp - nowMs,
        _ => 3600000,
      };

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
    } catch (e) {
      dev.log(
        'TokenRefresh: Server time HEAD failed, using local clock: $e',
        name: 'Auth',
      );
    }

    return DateTime.now().millisecondsSinceEpoch;
  }
}
