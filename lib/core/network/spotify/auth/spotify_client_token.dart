import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';

export 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart'
    show
        AuthClientProfile,
        AuthClientProfileConfig,
        SpotifyTokenStoreClientProfileExtension;

/// Fetches and manages the Spotify Client Token (`#47 §1`).
///
/// Endpoint: `POST https://clienttoken.spotify.com/v1/clienttoken`
/// Request/Response: `application/json`
///
/// Uses the single canonical persistent 40-hex `device_id` from
/// [DeviceIdentityService] and the coherent `activeClientId` from
/// [SpotifyTokenStore]. Never rotates the canonical `device_id` on
/// [forceRefreshClientToken].
class SpotifyClientTokenFetcher {
  static const _url = 'https://clienttoken.spotify.com/v1/clienttoken';
  static const int _defaultExpirySeconds = 86400;

  final SpotifyTokenStore _tokenStore;
  final DeviceIdentityService _deviceIdentityService;

  SpotifyClientTokenFetcher(
    this._tokenStore, {
    DeviceIdentityService? deviceIdentityService,
  }) : _deviceIdentityService = switch (deviceIdentityService) {
          final service? => service,
          null => DeviceIdentityService(),
        };

  /// Canonical [DeviceIdentityService] backing `js_sdk_data.device_id`.
  DeviceIdentityService get deviceIdentityService => _deviceIdentityService;

  /// Returns a valid client token, fetching a new one if missing or expired.
  Future<String?> getClientToken() async {
    final isExpired = await _tokenStore.isClientTokenExpired();
    if (!isExpired) {
      final cached = await _tokenStore.getClientToken();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }
    return fetchClientToken();
  }

  /// Invalidates the cached client token and fetches a fresh one while
  /// preserving the canonical persistent 40-hex `device_id` (`#47 §1`).
  Future<String?> forceRefreshClientToken() async {
    dev.log(
      'ClientToken: Forcing token refresh (preserving canonical device_id)...',
      name: 'Auth',
    );
    await _tokenStore.deleteClientToken();
    return fetchClientToken();
  }

  /// Fetches a fresh client token from Spotify bound to the canonical 40-hex
  /// `device_id` and active [AuthClientProfileConfig].
  Future<String?> fetchClientToken() async {
    try {
      final canonicalDeviceId =
          await _deviceIdentityService.getOrCreateDeviceId();
      final profileConfig = await _tokenStore.getActiveClientProfileConfig();

      final Map<String, Object> jsSdkData = switch (profileConfig.profile) {
        AuthClientProfile.webPlayer => <String, Object>{
            'device_brand': 'unknown',
            'device_model': 'unknown',
            'os': 'windows',
            'os_version': 'NT 10.0',
            'device_id': canonicalDeviceId,
            'device_type': 'computer',
          },
        AuthClientProfile.android => <String, Object>{
            'device_brand': 'Google',
            'device_model': 'Pixel 4 XL',
            'os': 'android',
            'os_version': '10',
            'device_id': canonicalDeviceId,
            'device_type': 'smartphone',
          },
      };

      final requestBody = jsonEncode(<String, Object>{
        'client_data': <String, Object>{
          'client_version': profileConfig.appVersion,
          'client_id': profileConfig.clientId,
          'js_sdk_data': jsSdkData,
        },
      });

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': profileConfig.userAgent,
        'App-Platform': profileConfig.appPlatform,
        'Spotify-App-Version': profileConfig.appVersion,
      };
      if (profileConfig.sendOriginHeaders) {
        headers['Origin'] = 'https://open.spotify.com';
        headers['Referer'] = 'https://open.spotify.com/';
        headers['Sec-Fetch-Dest'] = 'empty';
        headers['Sec-Fetch-Mode'] = 'cors';
        headers['Sec-Fetch-Site'] = 'same-site';
        headers['sec-ch-ua'] =
            '"Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"';
        headers['sec-ch-ua-mobile'] = '?0';
        headers['sec-ch-ua-platform'] = '"Windows"';
        headers['sec-gpc'] = '1';
      }

      final response = await http
          .post(
            Uri.parse(_url),
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        dev.log('ClientToken: HTTP ${response.statusCode}', name: 'Auth');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) {
        dev.log('ClientToken: Non-object JSON response', name: 'Auth');
        return null;
      }

      final responseType = switch (decoded['response_type']) {
        final String type => type,
        _ => null,
      };

      if (responseType == 'RESPONSE_GRANTED_TOKEN_RESPONSE') {
        final grantedToken = decoded['granted_token'];
        if (grantedToken is Map<String, Object?>) {
          final token = switch (grantedToken['token']) {
            final String value => value,
            _ => null,
          };
          final expiresSeconds =
              switch (grantedToken['expires_after_seconds']) {
            final int seconds when seconds > 0 => seconds,
            final num seconds when seconds > 0 => seconds.toInt(),
            _ => _defaultExpirySeconds,
          };

          if (token != null && token.isNotEmpty) {
            final lifetimeMs = expiresSeconds * 1000;
            await _tokenStore.saveClientToken(token, lifetimeMs: lifetimeMs);
            dev.log(
              'ClientToken obtained (${token.length} chars, expires in ${expiresSeconds}s)',
              name: 'Auth',
            );
            return token;
          }
        }
      }

      dev.log(
        'ClientToken: Unexpected response type: $responseType',
        name: 'Auth',
      );
      return null;
    } catch (e) {
      dev.log('ClientToken fetch failed: $e', name: 'Auth');
      return null;
    }
  }
}
