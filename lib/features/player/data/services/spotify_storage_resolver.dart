import 'dart:convert';
import 'dart:developer' as dev;

import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Resolves audio CDN stream URLs from Spotify's storage-resolve endpoint (v2).
/// Uses the app's unified [SpotifyTransport] with WebPlayer identity and priority queuing.
class SpotifyStorageResolver {
  static const String baseHost = 'https://gae2-spclient.spotify.com';

  final SpotifyTransport _transport;
  final SpotifyTokenStore _tokenStore;
  final Map<String, String> _cache = <String, String>{};

  SpotifyStorageResolver({
    required SpotifyTransport transport,
    required SpotifyTokenStore tokenStore,
  })  : _transport = transport,
        _tokenStore = tokenStore;

  /// Resolves the signed full-track CDN URL for a given [fileIdHex] and optional [formatNumber].
  ///
  /// Defaults to format 10 (MP4_128 AAC).
  /// Returns null on failure or error. Per project invariant, does not blindly retry.
  Future<String?> resolveCdnUrl(
    String fileIdHex, {
    int formatNumber = 10,
  }) async {
    final cleanFileId = fileIdHex.trim().toLowerCase();
    if (cleanFileId.isEmpty || cleanFileId.length != 40) {
      return null;
    }

    final cacheKey = '$formatNumber:$cleanFileId';
    if (_cache[cacheKey] case final cached? when cached.isNotEmpty) {
      return cached;
    }

    try {
      final spDc = await _tokenStore.getSpDc();
      final extraHeaders = <String, String>{
        'accept': 'application/json, text/plain, */*',
      };
      if (spDc != null && spDc.isNotEmpty) {
        extraHeaders['Cookie'] = spDc.startsWith('sp_dc=') ? spDc : 'sp_dc=$spDc';
      }

      final path =
          'storage-resolve/v2/files/audio/interactive/$formatNumber/$cleanFileId?version=10000000&product=9&platform=39&alt=json';

      dev.log(
        'StorageResolver: Requesting storage-resolve for format $formatNumber, fileId $cleanFileId',
        name: 'StorageResolver',
      );

      final bytes = await _transport.get(
        path,
        baseHost: baseHost,
        priority: NetworkPriority.interactive,
        extraHeaders: extraHeaders,
        tag: 'storage-resolve',
      );

      if (bytes == null || bytes.isEmpty) {
        dev.log(
          'StorageResolver: storage-resolve returned null for $cleanFileId',
          name: 'StorageResolver',
        );
        return null;
      }

      final jsonStr = utf8.decode(bytes);
      final body = jsonDecode(jsonStr);
      if (body is Map<String, dynamic>) {
        final cdnUrls = body['cdnurl'];
        if (cdnUrls is List && cdnUrls.isNotEmpty) {
          final firstUrl = cdnUrls.first;
          if (firstUrl is String && firstUrl.isNotEmpty) {
            dev.log(
              'StorageResolver: Resolved CDN URL for $cleanFileId: ${firstUrl.substring(0, firstUrl.length.clamp(0, 60))}...',
              name: 'StorageResolver',
            );
            _cache[cacheKey] = firstUrl;
            return firstUrl;
          }
        }
      }

      dev.log(
        'StorageResolver: Missing cdnurl in storage-resolve response',
        name: 'StorageResolver',
      );
      return null;
    } catch (e, st) {
      dev.log(
        'StorageResolver: Error resolving CDN URL for $cleanFileId: $e',
        name: 'StorageResolver',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  void clearCache() => _cache.clear();
}
