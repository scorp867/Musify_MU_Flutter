import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';

/// 1:1 counterpart to `com.spotify.imageloader.localfileimage.LocalFileImageLoader`.
///
/// Resolves `spotify:localfileimage:...`, `spotify:local:...`, and isolated
/// filesystem (`file://...` or `/...`) audio URIs to raw embedded artwork
/// bytes or size-bounded [ImageProvider]s while keeping Android `MediaStore`
/// row IDs and native metadata retrieval encapsulated inside the data layer.
final class LocalFileImageLoader {
  static const int _maxCachedBytes = 120;
  static const int _maxCachedProviders = 180;
  static const int _maxKnownMissing = 500;
  static const int _thumbQueryBucket = 256;
  static const int _fullQueryBucket = 720;
  static const int _bucketThreshold = 320;
  static const String _fileKeyPrefix = 'file:';
  static const MethodChannel _defaultArtworkChannel = MethodChannel(
    'um.musify.mu/local_artwork',
  );

  final LocalTracksStore _store;
  final DeviceMusicDataSource _deviceMusic;
  final MethodChannel _artworkChannel;

  final LinkedHashMap<_ByteCacheKey, Uint8List> _byteCache =
      LinkedHashMap<_ByteCacheKey, Uint8List>();
  final LinkedHashMap<_ProviderCacheKey, ImageProvider> _providerCache =
      LinkedHashMap<_ProviderCacheKey, ImageProvider>();
  final LinkedHashSet<String> _knownMissing = LinkedHashSet<String>();
  final Map<_ByteCacheKey, Future<Uint8List?>> _inFlight =
      <_ByteCacheKey, Future<Uint8List?>>{};

  Map<String, int>? _uriToMediaStoreId;
  Map<String, String>? _uriToDataPath;
  Future<void>? _indexLoadFuture;
  bool _hasLoadedIndex = false;
  bool _didFallbackRefresh = false;
  bool _disposed = false;
  StreamSubscription<List<LocalTrack>>? _watchSub;

  LocalFileImageLoader({
    required LocalTracksStore store,
    required DeviceMusicDataSource deviceMusic,
    MethodChannel? artworkChannel,
  }) : _store = store,
       _deviceMusic = deviceMusic,
       _artworkChannel = artworkChannel ?? _defaultArtworkChannel {
    _watchSub = _store.watchAll().listen(_rebuildIndex);
  }

  void dispose() {
    _disposed = true;
    final sub = _watchSub;
    _watchSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    _byteCache.clear();
    _providerCache.clear();
    _knownMissing.clear();
    _uriToMediaStoreId = null;
    _uriToDataPath = null;
  }

  void _rebuildIndex(
    List<LocalTrack> tracks, {
    bool resetFallbackRefresh = true,
  }) {
    if (_disposed) return;
    final nextIds = <String, int>{};
    final nextPaths = <String, String>{};
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
      nextIds[uri] = track.songId;
      if (track.dataPath.isNotEmpty) {
        nextPaths[uri] = track.dataPath;
      }
    }
    _uriToMediaStoreId = nextIds;
    _uriToDataPath = nextPaths;
    _hasLoadedIndex = true;
    if (resetFallbackRefresh) {
      _didFallbackRefresh = false;
    }
    // Invalidate negative cache when the local media library changes.
    _knownMissing.clear();
  }

  Future<void> _ensureIndexLoaded({required bool forceRefresh}) async {
    final inFlight = _indexLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    if (!forceRefresh && _hasLoadedIndex) {
      return;
    }
    final future = () async {
      try {
        final allTracks = await _store.getAll();
        _rebuildIndex(allTracks, resetFallbackRefresh: !forceRefresh);
      } finally {
        _indexLoadFuture = null;
      }
    }();
    _indexLoadFuture = future;
    return future;
  }

  Future<(int?, String?)> _resolveLocalMediaStoreEntry(
    String canonicalTrackUri,
  ) async {
    if (!_hasLoadedIndex) {
      await _ensureIndexLoaded(forceRefresh: false);
    }
    final id = _uriToMediaStoreId?[canonicalTrackUri];
    final dataPath = _uriToDataPath?[canonicalTrackUri];
    if (id != null || dataPath != null) {
      return (id, dataPath);
    }
    if (!_didFallbackRefresh) {
      _didFallbackRefresh = true;
      await _ensureIndexLoaded(forceRefresh: true);
    }
    return (
      _uriToMediaStoreId?[canonicalTrackUri],
      _uriToDataPath?[canonicalTrackUri],
    );
  }

  int _normalizeQueryBucket(int requestedSize) {
    if (requestedSize > _bucketThreshold) {
      return _fullQueryBucket;
    }
    return _thumbQueryBucket;
  }

  _ByteCacheKey? _toByteCacheKey(String uri, int querySize) {
    final bucket = _normalizeQueryBucket(querySize);
    if (LocalFileUri.isAnyLocalUri(uri)) {
      return _ByteCacheKey(
        canonicalTrackUri: LocalFileUri.toLocalTrackUri(uri),
        querySize: bucket,
      );
    }
    if (LocalFileUri.isFileSystemUri(uri)) {
      final path = LocalFileUri.toFilePath(uri);
      if (path != null && path.isNotEmpty) {
        return _ByteCacheKey(
          canonicalTrackUri: '$_fileKeyPrefix$path',
          querySize: bucket,
        );
      }
    }
    return null;
  }

  _ProviderCacheKey? _toProviderCacheKey(
    String uri,
    int querySize,
    int decodeWidthPx,
    int? decodeHeightPx,
  ) {
    final byteKey = _toByteCacheKey(uri, querySize);
    if (byteKey == null) return null;
    final boundedW = decodeWidthPx > 0 ? decodeWidthPx : _thumbQueryBucket;
    final boundedH = (decodeHeightPx != null && decodeHeightPx > 0)
        ? decodeHeightPx
        : boundedW;
    return _ProviderCacheKey(
      canonicalTrackUri: byteKey.canonicalTrackUri,
      querySize: byteKey.querySize,
      decodeWidthPx: boundedW,
      decodeHeightPx: boundedH,
    );
  }

  Uint8List? _lookupCachedBytes(_ByteCacheKey key) {
    final exact = _byteCache.remove(key);
    if (exact != null) {
      _byteCache[key] = exact;
      return exact;
    }
    // Satisfy smaller thumbnail requests from an already cached full-size entry.
    if (key.querySize < _fullQueryBucket) {
      final fullKey = _ByteCacheKey(
        canonicalTrackUri: key.canonicalTrackUri,
        querySize: _fullQueryBucket,
      );
      final full = _byteCache.remove(fullKey);
      if (full != null) {
        _byteCache[fullKey] = full;
        return full;
      }
    }
    return null;
  }

  void _markKnownMissing(String canonicalTrackUri) {
    _knownMissing.remove(canonicalTrackUri);
    if (_knownMissing.length >= _maxKnownMissing) {
      _knownMissing.remove(_knownMissing.first);
    }
    _knownMissing.add(canonicalTrackUri);
  }

  ImageProvider? getProviderSync(
    String uri, {
    required int querySize,
    required int decodeWidthPx,
    int? decodeHeightPx,
  }) {
    final providerKey = _toProviderCacheKey(
      uri,
      querySize,
      decodeWidthPx,
      decodeHeightPx,
    );
    if (providerKey == null) return null;
    final existing = _providerCache.remove(providerKey);
    if (existing != null) {
      _providerCache[providerKey] = existing;
    }
    return existing;
  }

  bool isKnownMissing(String uri, {required int querySize}) {
    final byteKey = _toByteCacheKey(uri, querySize);
    if (byteKey == null) return false;
    return _knownMissing.contains(byteKey.canonicalTrackUri);
  }

  Future<Uint8List?> loadBytes(String uri, {int querySize = 300}) {
    if (_disposed) {
      return Future<Uint8List?>.value(null);
    }
    final byteKey = _toByteCacheKey(uri, querySize);
    if (byteKey == null) {
      return Future<Uint8List?>.value(null);
    }

    final cachedBytes = _lookupCachedBytes(byteKey);
    if (cachedBytes != null) {
      return Future<Uint8List?>.value(cachedBytes);
    }
    if (_knownMissing.contains(byteKey.canonicalTrackUri)) {
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
    int? decodeHeightPx,
  }) async {
    if (_disposed) return null;
    final syncHit = getProviderSync(
      uri,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
      decodeHeightPx: decodeHeightPx,
    );
    if (syncHit != null) return syncHit;

    final bytes = await loadBytes(uri, querySize: querySize);
    if (_disposed || bytes == null || bytes.isEmpty) return null;

    final providerKey = _toProviderCacheKey(
      uri,
      querySize,
      decodeWidthPx,
      decodeHeightPx,
    );
    if (providerKey == null) return null;

    final recheck = _providerCache.remove(providerKey);
    if (recheck != null) {
      _providerCache[providerKey] = recheck;
      return recheck;
    }

    final provider = ResizeImage(
      MemoryImage(bytes),
      width: providerKey.decodeWidthPx,
      height: providerKey.decodeHeightPx,
      policy: ResizeImagePolicy.fit,
      allowUpscaling: false,
    );
    if (_providerCache.length >= _maxCachedProviders) {
      _providerCache.remove(_providerCache.keys.first);
    }
    _providerCache[providerKey] = provider;
    return provider;
  }

  /// Convenience entrypoint for direct file system audio paths (e.g., vault
  /// isolated `.nomedia` files).
  Future<Uint8List?> loadFileArtworkBytes(
    String filePath, {
    int maxDimension = _fullQueryBucket,
  }) {
    final normalizedUri = LocalFileUri.isFileSystemUri(filePath)
        ? filePath
        : LocalFileUri.toFileUri(filePath);
    return loadBytes(normalizedUri, querySize: maxDimension);
  }

  ImageProvider? getFileProviderSync(
    String filePath, {
    int decodeWidthPx = 200,
    int? decodeHeightPx,
  }) {
    final normalizedUri = LocalFileUri.isFileSystemUri(filePath)
        ? filePath
        : LocalFileUri.toFileUri(filePath);
    return getProviderSync(
      normalizedUri,
      querySize: decodeWidthPx,
      decodeWidthPx: decodeWidthPx,
      decodeHeightPx: decodeHeightPx,
    );
  }

  Future<ImageProvider?> loadFileProvider(
    String filePath, {
    int decodeWidthPx = 200,
    int? decodeHeightPx,
  }) {
    final normalizedUri = LocalFileUri.isFileSystemUri(filePath)
        ? filePath
        : LocalFileUri.toFileUri(filePath);
    return loadProvider(
      normalizedUri,
      querySize: decodeWidthPx,
      decodeWidthPx: decodeWidthPx,
      decodeHeightPx: decodeHeightPx,
    );
  }

  Future<Uint8List?> _extractEmbeddedArtworkFromPath(
    String filePath, {
    required int maxDimension,
  }) async {
    try {
      final bytes = await _artworkChannel.invokeMethod<Uint8List>(
        'extractEmbeddedArtwork',
        <String, Object>{
          'filePath': filePath,
          'maxDimension': maxDimension,
        },
      );
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return bytes;
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      dev.log(
        'LocalFileImageLoader: native extractEmbeddedArtwork failed for $filePath: ${e.message}',
      );
      return null;
    }
  }

  Future<Uint8List?> _fetchBytes(_ByteCacheKey key) async {
    try {
      Uint8List? bytes;
      String? checkedFilePath;
      if (key.canonicalTrackUri.startsWith(_fileKeyPrefix)) {
        final filePath = key.canonicalTrackUri.substring(_fileKeyPrefix.length);
        checkedFilePath = filePath;
        bytes = await _extractEmbeddedArtworkFromPath(
          filePath,
          maxDimension: key.querySize,
        );
      } else {
        final (mediaStoreId, dataPath) = await _resolveLocalMediaStoreEntry(
          key.canonicalTrackUri,
        );
        if (_disposed) return null;
        if (mediaStoreId != null && mediaStoreId > 0) {
          bytes = await _deviceMusic.queryArtwork(
            mediaStoreId,
            size: key.querySize,
          );
        }
        if (!_disposed &&
            (bytes == null || bytes.isEmpty) &&
            dataPath != null &&
            dataPath.isNotEmpty) {
          checkedFilePath = dataPath;
          bytes = await _extractEmbeddedArtworkFromPath(
            dataPath,
            maxDimension: key.querySize,
          );
        }
      }

      if (_disposed) return null;
      if (bytes == null || bytes.isEmpty) {
        _markKnownMissing(key.canonicalTrackUri);
        if (checkedFilePath != null && checkedFilePath.isNotEmpty) {
          _markKnownMissing('$_fileKeyPrefix$checkedFilePath');
        }
        return null;
      }
      if (_byteCache.length >= _maxCachedBytes) {
        _byteCache.remove(_byteCache.keys.first);
      }
      _byteCache[key] = bytes;
      return bytes;
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
  final int decodeHeightPx;

  const _ProviderCacheKey({
    required this.canonicalTrackUri,
    required this.querySize,
    required this.decodeWidthPx,
    required this.decodeHeightPx,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ProviderCacheKey &&
          other.canonicalTrackUri == canonicalTrackUri &&
          other.querySize == querySize &&
          other.decodeWidthPx == decodeWidthPx &&
          other.decodeHeightPx == decodeHeightPx);

  @override
  int get hashCode => Object.hash(
    canonicalTrackUri,
    querySize,
    decodeWidthPx,
    decodeHeightPx,
  );
}
