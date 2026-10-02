import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';

/// Per-playlist disk cache with revision tracking for diff-based updates.
///
/// Stores for each playlist ID:
///   - Raw protobuf bytes (for isolate parsing)
///   - Revision string (for diff endpoint)
///   - Cover image URL (mosaic or custom)
///   - Track URIs (for mosaic generation)
class PlaylistDetailCache {
  static const _policy = CachePolicy.standard;

  final AppCacheManager _cacheManager;

  // In-memory index: playlistId -> PlaylistCacheEntry
  Map<String, PlaylistCacheEntry>? _index;
  int _loadedGeneration = -1;

  PlaylistDetailCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('playlists');

  /// Loads the index from disk if not already loaded.
  Future<void> _ensureIndex() async {
    if (_index != null && _loadedGeneration == _cacheManager.generation) {
      return;
    }
    _index = {};
    _loadedGeneration = _cacheManager.generation;

    try {
      final dir = await _cacheDir;
      final indexFile = File(
        '${dir.path}${Platform.pathSeparator}index.json',
      );
      if (!await indexFile.exists()) return;

      final raw = await indexFile.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;

      for (final e in map.entries) {
        final v = e.value as Map<String, dynamic>;
        final cachedAt = v['t'] as int? ?? 0;
        if (_policy.isExpired(cachedAt)) continue;

        _index![e.key] = PlaylistCacheEntry(
          revision: v['r'] as String? ?? '',
          coverUrl: v['c'] as String?,
          isCustomCover: v['cc'] as bool? ?? false,
          mosaicImageUrls: (v['m'] as List?)?.cast<String>() ?? [],
          trackUris: (v['u'] as List?)?.cast<String>() ?? [],
          cachedAt: cachedAt,
        );
      }
    } catch (e) {
      dev.log('Ensure index failed: $e');
    }
  }

  /// Returns cached entry for a playlist, or null if missing/expired.
  Future<PlaylistCacheEntry?> get(String playlistId) async {
    await _ensureIndex();
    return _index![playlistId];
  }

  /// Returns the cached revision for diff requests, or null if not cached.
  Future<String?> getRevision(String playlistId) async {
    final entry = await get(playlistId);
    return entry?.revision;
  }

  /// Returns cached cover URL for a playlist, or null.
  Future<String?> getCoverUrl(String playlistId) async {
    final entry = await get(playlistId);
    return entry?.coverUrl;
  }

  /// Stores parsed playlist data and raw bytes.
  Future<void> put({
    required String playlistId,
    required String revision,
    required List<String> trackUris,
    String? coverUrl,
    bool isCustomCover = false,
    List<String> mosaicImageUrls = const [],
    Uint8List? rawBytes,
  }) async {
    await _ensureIndex();

    _index![playlistId] = PlaylistCacheEntry(
      revision: revision,
      coverUrl: coverUrl,
      isCustomCover: isCustomCover,
      mosaicImageUrls: mosaicImageUrls,
      trackUris: trackUris,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Store raw bytes separately (large, no need to hold in memory).
    if (rawBytes != null) {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}$playlistId.bin',
      );
      await file.writeAsBytes(rawBytes, flush: true);
    }

    await _persistIndex();
  }

  /// Returns cached raw bytes for a playlist, or null.
  Future<Uint8List?> getRawBytes(String playlistId) async {
    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}$playlistId.bin',
      );
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (e) {
      dev.log('Get raw bytes failed: $e');
      return null;
    }
  }

  /// Returns all playlist IDs that have cached data.
  Future<Set<String>> cachedIds() async {
    await _ensureIndex();
    return _index!.keys.toSet();
  }

  Future<void> _persistIndex() async {
    try {
      final dir = await _cacheDir;
      final indexFile = File(
        '${dir.path}${Platform.pathSeparator}index.json',
      );

      final map = <String, dynamic>{};
      for (final e in _index!.entries) {
        map[e.key] = {
          'r': e.value.revision,
          if (e.value.coverUrl != null) 'c': e.value.coverUrl,
          if (e.value.isCustomCover) 'cc': true,
          if (e.value.mosaicImageUrls.isNotEmpty) 'm': e.value.mosaicImageUrls,
          'u': e.value.trackUris,
          't': e.value.cachedAt,
        };
      }

      await indexFile.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      dev.log('Persist index failed: $e');
    }
  }
}

class PlaylistCacheEntry {
  final String revision;
  final String? coverUrl;

  /// True when coverUrl is a user-set custom image (from ListAttributes.picture),
  /// false when it's a track album art fallback or null.
  final bool isCustomCover;
  final List<String> mosaicImageUrls;
  final List<String> trackUris;
  final int cachedAt;

  const PlaylistCacheEntry({
    required this.revision,
    this.coverUrl,
    this.isCustomCover = false,
    this.mosaicImageUrls = const [],
    required this.trackUris,
    required this.cachedAt,
  });
}
