import 'dart:convert';
import 'dart:developer' as dev;

import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Dynamically discovers and caches Widevine audio license server URLs via Spotify's Melody service.
/// Uses the app's unified [SpotifyTransport] with WebPlayer identity and priority queuing.
class SpotifyLicenseResolver {
  static const String baseHost = 'https://gae2-spclient.spotify.com';
  static const String defaultLicensePath = '/widevine-license/v1/audio/license';

  static const String harmonySdkName = 'harmony';
  static const String harmonySdkVersion = '4.81.1';

  final SpotifyTransport _transport;

  String? _cachedLicenseUrl;
  int _cachedExpiryMs = 0;

  SpotifyLicenseResolver({
    required SpotifyTransport transport,
  }) : _transport = transport;

  /// Resolves the Widevine license server URL.
  ///
  /// Checks in-memory cache against the server-provided `expires` timestamp.
  /// If expired or uncached, queries Melody discovery endpoint.
  /// Falls back to `$baseHost$defaultLicensePath` on network/parsing failure.
  Future<String> resolveLicenseUrl() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_cachedLicenseUrl case final cachedUrl? when now < _cachedExpiryMs) {
      return cachedUrl;
    }

    try {
      final path =
          'melody/v1/license_url?keysystem=com.widevine.alpha&mediatype=audio&sdk_name=$harmonySdkName&sdk_version=$harmonySdkVersion';

      dev.log(
        'LicenseResolver: Discovering Melody license URL via SpotifyTransport...',
        name: 'LicenseResolver',
      );

      final bytes = await _transport.get(
        path,
        baseHost: baseHost,
        priority: NetworkPriority.interactive,
        extraHeaders: const {
          'accept': '*/*',
          'cache-control': 'no-cache',
          'pragma': 'no-cache',
        },
        tag: 'melody-license',
      );

      if (bytes != null && bytes.isNotEmpty) {
        final jsonStr = utf8.decode(bytes);
        final body = jsonDecode(jsonStr);
        if (body is Map<String, dynamic>) {
          final uri = body['uri'] as String?;
          final expires = switch (body['expires']) {
            final int exp => exp,
            _ => 0,
          };

          if (uri != null && uri.isNotEmpty) {
            final cleanUri = uri.startsWith('/') ? uri.substring(1) : uri;
            final fullUrl = '$baseHost/$cleanUri';
            _cachedLicenseUrl = fullUrl;
            _cachedExpiryMs = expires > 0 ? expires * 1000 : now + 3600000;

            dev.log(
              'LicenseResolver: Discovered and cached license URL: $fullUrl (expires: $_cachedExpiryMs)',
              name: 'LicenseResolver',
            );
            return fullUrl;
          }
        }
      } else {
        dev.log(
          'LicenseResolver: Melody discovery returned empty or null bytes',
          name: 'LicenseResolver',
        );
      }
    } catch (e, st) {
      dev.log(
        'LicenseResolver: Error discovering license URL: $e',
        name: 'LicenseResolver',
        error: e,
        stackTrace: st,
      );
    }

    // Default fallback path matching SpotifyWidevineManager
    final fallback = '$baseHost$defaultLicensePath';
    return fallback;
  }

  void clearCache() {
    _cachedLicenseUrl = null;
    _cachedExpiryMs = 0;
  }
}
