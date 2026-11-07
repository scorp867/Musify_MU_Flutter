import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';

/// 1:1 counterpart to `com.spotify.imageloader.localfileimage.LocalFileImageLoader`.
///
/// Resolves `spotify:localfileimage:...` and `spotify:local:...` URIs to raw
/// embedded artwork bytes or size-bounded [ImageProvider]s while keeping
/// Android `MediaStore` row IDs strictly encapsulated inside the data layer.
final class LocalFileImageLoader {
  static const int _maxCachedBytes = 250;
  static const int _maxCachedProviders = 350;

  final LocalTracksStore _store;
  final DeviceMusicDataSource _deviceMusic;

  final LinkedHashMap<_ByteCacheKey, Uint8List> _byteCache =
      LinkedHashMap<_ByteCacheKey, Uint8List>();
  final LinkedHashMap<_ProviderCacheKey, ImageProvider> _providerCache =
      LinkedHashMap<_ProviderCacheKey, ImageProvider>();
  final Set<_ByteCacheKey> _knownMissing = <_ByteCacheKey>{};
  final Map<_ByteCacheKey, Future<Uint8List?>> _inFlight =
      <_ByteCacheKey, Future<Uint8List?>>{};

  Map<String, int>? _uriToMediaStoreId;
  StreamSubscription<List<LocalTrack>>? _watchSub;

  LocalFileImageLoader({
    required LocalTracksStore store,
    required DeviceMusicDataSource deviceMusic,
  }) : _store = store,
       _deviceMusic = deviceMusic {
    _watchSub = _store.watchAll().listen(_rebuildIndex);
  }

  void dispose() {
    final sub = _watchSub;
    _watchSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
  }

  void _rebuildIndex(List<LocalTrack> tracks) {
    final next = <String, int>{};
    for (final track in tracks) {
      final durationSeconds = switch (track.duration) {
        final d? when d > 0 => d ~/ 1000,
        _ => 0,
      };
      final uri = LocalFileUri.fromMetadata(
        artist: switch (track.artist) {
          final a? => a,
          null => '',
        },
        album: switch (track.album) {
          final al? => al,
          null => '',
        },
        title: track.title,
        durationSeconds: durationSeconds,
      );
      next[uri] = track.songId;
    }
    _uriToMediaStoreId = next;
  }

  Future<int?> _resolveMediaStoreId(String canonicalTrackUri) async {
    if (_uriToMediaStoreId case final existing?) {
      if (existing[canonicalTrackUri] case final id?) {
        return id;
      }
    }
    final allTracks = await _store.getAll();
    _rebuildIndex(allTracks);
    return _uriToMediaStoreId?[canonicalTrackUri];
  }

  ImageProvider? getProviderSync(
    String uri, {
    required int querySize,
    required int decodeWidthPx,
  }) {
    if (!LocalFileUri.isAnyLocalUri(uri)) return null;
    final canonical = LocalFileUri.toLocalTrackUri(uri);
    final providerKey = _ProviderCacheKey(
      canonicalTrackUri: canonical,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
    );
    final existing = _providerCache.remove(providerKey);
    if (existing != null) {
      _providerCache[providerKey] = existing;
    }
    return existing;
  }

  bool isKnownMissing(String uri, {required int querySize}) {
    if (!LocalFileUri.isAnyLocalUri(uri)) return false;
    final canonical = LocalFileUri.toLocalTrackUri(uri);
    return _knownMissing.contains(
      _ByteCacheKey(canonicalTrackUri: canonical, querySize: querySize),
    );
  }

  Future<Uint8List?> loadBytes(String uri, {int querySize = 300}) {
    if (!LocalFileUri.isAnyLocalUri(uri)) {
      return Future<Uint8List?>.value(null);
    }
    final canonical = LocalFileUri.toLocalTrackUri(uri);
    final byteKey = _ByteCacheKey(
      canonicalTrackUri: canonical,
      querySize: querySize,
    );

    final cachedBytes = _byteCache.remove(byteKey);
    if (cachedBytes != null) {
      _byteCache[byteKey] = cachedBytes;
      return Future<Uint8List?>.value(cachedBytes);
    }
    if (_knownMissing.contains(byteKey)) {
      return Future<Uint8List?>.value(null);
    }
    if (_inFlight[byteKey] case final active?) {
      return active;
    }

    final future = _fetchBytes(byteKey);
    _inFlight[byteKey] = future;
    return future;
  }

  Future<ImageProvider?> loadProvider(
    String uri, {
    required int querySize,
    required int decodeWidthPx,
  }) async {
    final syncHit = getProviderSync(
      uri,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
    );
    if (syncHit != null) return syncHit;

    final bytes = await loadBytes(uri, querySize: querySize);
    if (bytes == null || bytes.isEmpty) return null;

    final canonical = LocalFileUri.toLocalTrackUri(uri);
    final providerKey = _ProviderCacheKey(
      canonicalTrackUri: canonical,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
    );
    final provider = ResizeImage(
      MemoryImage(bytes),
      width: decodeWidthPx,
      allowUpscaling: false,
    );
    if (_providerCache.length >= _maxCachedProviders) {
      _providerCache.remove(_providerCache.keys.first);
    }
    _providerCache[providerKey] = provider;
    return provider;
  }

  Future<Uint8List?> _fetchBytes(_ByteCacheKey key) async {
    try {
      final mediaStoreId = await _resolveMediaStoreId(key.canonicalTrackUri);
      if (mediaStoreId == null || mediaStoreId <= 0) {
        _knownMissing.add(key);
        return null;
      }
      final bytes = await _deviceMusic.queryArtwork(
        mediaStoreId,
        size: key.querySize,
      );
      if (bytes == null || bytes.isEmpty) {
        _knownMissing.add(key);
        return null;
      }
      if (_byteCache.length >= _maxCachedBytes) {
        _byteCache.remove(_byteCache.keys.first);
      }
      _byteCache[key] = bytes;
      return bytes;
    } on Object {
      _knownMissing.add(key);
      return null;
    } finally {
      _inFlight.remove(key);
    }
  }
}

final class _ByteCacheKey {
  final String canonicalTrackUri;
  final int querySize;

  const _ByteCacheKey({
    required this.canonicalTrackUri,
    required this.querySize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ByteCacheKey &&
          other.canonicalTrackUri == canonicalTrackUri &&
          other.querySize == querySize);

  @override
  int get hashCode => Object.hash(canonicalTrackUri, querySize);
}

final class _ProviderCacheKey {
  final String canonicalTrackUri;
  final int querySize;
  final int decodeWidthPx;

  const _ProviderCacheKey({
    required this.canonicalTrackUri,
    required this.querySize,
    required this.decodeWidthPx,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ProviderCacheKey &&
          other.canonicalTrackUri == canonicalTrackUri &&
          other.querySize == querySize &&
          other.decodeWidthPx == decodeWidthPx);

  @override
  int get hashCode => Object.hash(canonicalTrackUri, querySize, decodeWidthPx);
}
