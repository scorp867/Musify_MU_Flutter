import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Per-playlist disk cache with revision tracking for diff-based updates.
///
/// Stores for each playlist ID:
///   - Raw protobuf bytes (for isolate parsing)
///   - Revision string (for diff endpoint)
///   - Cover image URL (mosaic or custom)
///   - Track URIs (for mosaic generation)
class PlaylistDetailCache {
  static const _maxAge = Duration(hours: 24);

  // In-memory index: playlistId -> PlaylistCacheEntry
  Map<String, PlaylistCacheEntry>? _index;

  Future<Directory> get _cacheDir async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/playlist_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Loads the index from disk if not already loaded.
  Future<void> _ensureIndex() async {
    if (_index != null) return;
    _index = {};

    try {
      final dir = await _cacheDir;
      final indexFile = File('${dir.path}/index.json');
      if (!await indexFile.exists()) return;

      final raw = await indexFile.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;

      for (final e in map.entries) {
        final v = e.value as Map<String, dynamic>;
        final cachedAt = v['t'] as int? ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        if (age > _maxAge.inMilliseconds) continue;

        _index![e.key] = PlaylistCacheEntry(
          revision: v['r'] as String? ?? '',
          coverUrl: v['c'] as String?,
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
    List<String> mosaicImageUrls = const [],
    Uint8List? rawBytes,
  }) async {
    await _ensureIndex();

    _index![playlistId] = PlaylistCacheEntry(
      revision: revision,
      coverUrl: coverUrl,
      mosaicImageUrls: mosaicImageUrls,
      trackUris: trackUris,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Store raw bytes separately (large, no need to hold in memory).
    if (rawBytes != null) {
      final dir = await _cacheDir;
      final file = File('${dir.path}/$playlistId.bin');
      await file.writeAsBytes(rawBytes, flush: true);
    }

    await _persistIndex();
  }

  /// Returns cached raw bytes for a playlist, or null.
  Future<Uint8List?> getRawBytes(String playlistId) async {
    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/$playlistId.bin');
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
      final indexFile = File('${dir.path}/index.json');

      final map = <String, dynamic>{};
      for (final e in _index!.entries) {
        map[e.key] = {
          'r': e.value.revision,
          if (e.value.coverUrl != null) 'c': e.value.coverUrl,
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
  final List<String> mosaicImageUrls;
  final List<String> trackUris;
  final int cachedAt;

  const PlaylistCacheEntry({
    required this.revision,
    this.coverUrl,
    this.mosaicImageUrls = const [],
    required this.trackUris,
    required this.cachedAt,
  });
}
