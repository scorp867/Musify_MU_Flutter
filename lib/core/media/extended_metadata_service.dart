import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/spotify_client/spotify_client.dart';

/// Resolved metadata for a single track or episode.
///
/// Shared across the whole app: library mosaic, playlist detail,
/// now playing, queue, playback, etc.
class TrackMeta {
  final String uri;
  final String title;
  final String subtitle; // artist names joined
  final String albumName;

  /// Image URLs by size. Keys: 'small' (~64px), 'medium' (~300px), 'large' (~640px).
  final Map<String, String> imageUrls;

  /// Best cover URL (largest available).
  String get imageUrl =>
      imageUrls['large'] ??
      imageUrls['medium'] ??
      imageUrls['small'] ??
      '';

  /// Raw hex image ID of the largest cover (for mosaic URL construction).
  final String? largeImageHex;

  final int durationMs;

  const TrackMeta({
    required this.uri,
    this.title = '',
    this.subtitle = '',
    this.albumName = '',
    this.imageUrls = const {},
    this.largeImageHex,
    this.durationMs = 0,
  });
}

const _imageCdnPrefix = 'https://i.scdn.co/image/';

/// App-wide centralized service for fetching and caching entity metadata
/// via the extended-metadata endpoint.
///
/// Uses TRACK_V4 (10) for tracks and EPISODE_V4 (12) for episodes.
/// Two-layer cache: in-memory LRU (hot path) + disk (persistence).
///
/// Consumers:
///   - Library: playlist mosaic covers (first 4 track images)
///   - Playlist detail: full track list with metadata
///   - Now Playing / Queue: track info display
///   - Playback: duration, title, artist
class ExtendedMetadataService {
  final SpotifyClient _client;

  // Layer 1: In-memory LRU for zero-cost reads.
  final _memCache = _LruCache<String, TrackMeta>(2000);

  // Layer 2: Disk persistence.
  final _diskCache = _TrackMetaDiskCache();

  bool _diskLoaded = false;

  ExtendedMetadataService({required SpotifyClient client}) : _client = client;

  /// Loads disk cache into memory (called once lazily).
  Future<void> _ensureDiskLoaded() async {
    if (_diskLoaded) return;
    _diskLoaded = true;

    final entries = await _diskCache.loadAll();
    for (final entry in entries.entries) {
      _memCache.put(entry.key, entry.value);
    }
    if (entries.isNotEmpty) {
      dev.log(
        'ExtMetadataService: loaded ${entries.length} entries from disk',
        name: 'Metadata',
      );
    }
  }

  /// Returns cached metadata for a URI, or null if not cached.
  TrackMeta? getCached(String uri) => _memCache.get(uri);

  /// Fetches metadata for the given URIs.
  /// Returns only URIs that were successfully resolved.
  /// Cached results are returned immediately; only uncached URIs hit the network.
  Future<Map<String, TrackMeta>> fetchTracks(List<String> uris) async {
    if (uris.isEmpty) return {};

    await _ensureDiskLoaded();

    final results = <String, TrackMeta>{};
    final uncached = <String>[];

    for (final uri in uris) {
      final cached = _memCache.get(uri);
      if (cached != null) {
        results[uri] = cached;
      } else {
        uncached.add(uri);
      }
    }

    if (uncached.isEmpty) return results;

    // Fetch in batches of 50 (extended-metadata limit).
    const batchSize = 50;
    final newEntries = <String, TrackMeta>{};

    for (var i = 0; i < uncached.length; i += batchSize) {
      final batch = uncached.skip(i).take(batchSize).toList();
      final fetched = await _fetchBatch(batch);
      for (final entry in fetched.entries) {
        _memCache.put(entry.key, entry.value);
        results[entry.key] = entry.value;
        newEntries[entry.key] = entry.value;
      }
    }

    // Persist new entries to disk (fire-and-forget).
    if (newEntries.isNotEmpty) {
      _diskCache.putAll(newEntries);
    }

    dev.log(
      'ExtMetadataService: ${results.length} resolved '
      '(${uncached.length} fetched, ${uris.length - uncached.length} cached)',
      name: 'Metadata',
    );

    return results;
  }

  /// Convenience: fetch metadata for up to N unique track URIs from a list.
  /// Useful for mosaic cover generation where only first 4 are needed.
  Future<List<TrackMeta>> fetchFirst(List<String> uris, int count) async {
    // Deduplicate while preserving order.
    final unique = <String>[];
    final seen = <String>{};
    for (final uri in uris) {
      if (uri.startsWith('spotify:track:') && seen.add(uri)) {
        unique.add(uri);
        if (unique.length >= count) break;
      }
    }

    if (unique.isEmpty) return [];

    final map = await fetchTracks(unique);
    return unique.map((u) => map[u]).whereType<TrackMeta>().toList();
  }

  // ─── Network ──────────────────────────────────────────────────────

  Future<Map<String, TrackMeta>> _fetchBatch(List<String> uris) async {
    try {
      final payload = _buildRequest(uris);
      final response = await _client.post(
        '/extended-metadata/v0/extended-metadata',
        Uint8List.fromList(payload),
      );
      if (response == null) return {};

      return await Isolate.run(() => _parseResponse(response));
    } catch (e, st) {
      dev.log(
        'ExtMetadataService batch error: $e',
        name: 'Metadata',
        error: e,
        stackTrace: st,
      );
      return {};
    }
  }

  List<int> _buildRequest(List<String> uris) {
    final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        // TODO: Derive from user profile or device locale
        ..country = 'IN'
        // TODO: Derive from user profile or device locale
        ..catalogue = 'free'
        ..taskId = taskId);

    for (final uri in uris) {
      final entityReq = EntityRequest()..entityUri = uri;

      // Ask for TRACK_V4 for tracks, EPISODE_V4 for episodes.
      if (uri.startsWith('spotify:track:')) {
        entityReq.query.add(
          ExtensionQuery()..extensionKind = ExtensionKind.TRACK_V4,
        );
      } else if (uri.startsWith('spotify:episode:')) {
        entityReq.query.add(
          ExtensionQuery()..extensionKind = ExtensionKind.EPISODE_V4,
        );
      } else {
        // Fallback: request TRACK_V4 (works for most entities).
        entityReq.query.add(
          ExtensionQuery()..extensionKind = ExtensionKind.TRACK_V4,
        );
      }

      request.entityRequest.add(entityReq);
    }

    return request.writeToBuffer();
  }

  // ─── Parsing (static, runs in isolate) ────────────────────────────

  static Map<String, TrackMeta> _parseResponse(Uint8List data) {
    final results = <String, TrackMeta>{};
    final response = BatchedExtensionResponse.fromBuffer(data);

    for (final array in response.extendedMetadata) {
      final kindValue = array.extensionKind.value;

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final payload = extData.extensionData.value;
        if (payload.isEmpty) continue;

        try {
          TrackMeta? meta;
          if (kindValue == 10) {
            // TRACK_V4
            meta = _parseTrackV4(uri, payload);
          } else if (kindValue == 12) {
            // EPISODE_V4
            meta = _parseEpisodeV4(uri, payload);
          }
          if (meta != null) {
            results[uri] = meta;
          }
        } catch (e) {
          dev.log('Parse metadata payload failed: $e');
        }
      }
    }

    return results;
  }

  static TrackMeta? _parseTrackV4(String uri, List<int> payload) {
    final track = meta_pb.Track.fromBuffer(payload);

    final title = track.name;
    final artists = track.artist.map((a) => a.name).where((n) => n.isNotEmpty);
    final albumName = track.hasAlbum() ? track.album.name : '';
    final duration = track.hasDuration() ? track.duration : 0;

    final imageUrls = <String, String>{};
    String? largeImageHex;

    if (track.hasAlbum() && track.album.hasCoverGroup()) {
      for (final image in track.album.coverGroup.image) {
        if (!image.hasFileId() || image.fileId.isEmpty) continue;

        final hex = image.fileId
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final url = '$_imageCdnPrefix$hex';

        switch (image.size) {
          case meta_pb.Image_Size.SMALL:
            imageUrls['small'] = url;
            break;
          case meta_pb.Image_Size.LARGE:
            imageUrls['medium'] = url; // LARGE = ~300px = medium slot
            largeImageHex ??= hex; // Use for mosaic if no bigger available
            break;
          case meta_pb.Image_Size.XLARGE:
            imageUrls['large'] = url;
            largeImageHex = hex; // Prefer XLARGE hex for mosaic
            break;
          default:
            imageUrls.putIfAbsent('medium', () => url);
            largeImageHex ??= hex;
        }
      }
    }

    return TrackMeta(
      uri: uri,
      title: title,
      subtitle: artists.join(', '),
      albumName: albumName,
      imageUrls: imageUrls,
      largeImageHex: largeImageHex,
      durationMs: duration,
    );
  }

  static TrackMeta? _parseEpisodeV4(String uri, List<int> payload) {
    final episode = meta_pb.Episode.fromBuffer(payload);

    final title = episode.name;
    final showName =
        (episode.hasShow() && episode.show.hasName()) ? episode.show.name : '';
    final duration = episode.hasDuration() ? episode.duration : 0;

    final imageUrls = <String, String>{};
    String? largeImageHex;

    if (episode.hasCoverImage()) {
      for (final image in episode.coverImage.image) {
        if (!image.hasFileId() || image.fileId.isEmpty) continue;

        final hex = image.fileId
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final url = '$_imageCdnPrefix$hex';

        switch (image.size) {
          case meta_pb.Image_Size.SMALL:
            imageUrls['small'] = url;
            break;
          case meta_pb.Image_Size.LARGE:
            imageUrls['large'] = url;
            largeImageHex = hex;
            break;
          case meta_pb.Image_Size.XLARGE:
            imageUrls['large'] = url;
            largeImageHex = hex;
            break;
          default:
            imageUrls.putIfAbsent('medium', () => url);
        }
      }
    }

    return TrackMeta(
      uri: uri,
      title: title,
      subtitle: showName,
      durationMs: duration,
      imageUrls: imageUrls,
      largeImageHex: largeImageHex,
    );
  }
}

/// Disk persistence for TrackMeta.
///
/// Uses a single JSONL file (one JSON object per line) for fast append-only writes.
/// Format: {"u":"spotify:track:xxx","t":"Title","s":"Artist","a":"Album","i":{"small":"url","medium":"url","large":"url"},"h":"hexId","d":12345}
class _TrackMetaDiskCache {
  static const _maxAge = Duration(days: 7);
  static const _fileName = 'track_meta_cache.jsonl';

  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/$_fileName');
    return _file!;
  }

  /// Loads all entries from disk, deduplicating by URI.
  Future<Map<String, TrackMeta>> loadAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return {};

      final content = await file.readAsString();
      if (content.isEmpty) return {};

      final now = DateTime.now().millisecondsSinceEpoch;
      final results = <String, TrackMeta>{};

      for (final line in content.split('\n')) {
        if (line.isEmpty) continue;
        try {
          final j = jsonDecode(line) as Map<String, dynamic>;

          // Check expiry.
          final ts = j['ts'] as int? ?? 0;
          if (now - ts > _maxAge.inMilliseconds) continue;

          final meta = _fromJson(j);
          if (meta != null) {
            results[meta.uri] = meta;
          }
        } catch (e) {
          dev.log('Parse disk cache line failed: $e');
        }
      }

      return results;
    } catch (e) {
      dev.log('Load disk cache failed: $e');
      return {};
    }
  }

  /// Appends new entries to disk (fire-and-forget).
  Future<void> putAll(Map<String, TrackMeta> entries) async {
    try {
      final file = await _getFile();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sb = StringBuffer();

      for (final entry in entries.entries) {
        sb.writeln(jsonEncode(_toJson(entry.value, ts)));
      }

      await file.writeAsString(
        sb.toString(),
        mode: FileMode.append,
        flush: true,
      );
      await _compactIfNeeded();
    } catch (e) {
      dev.log('Write to disk cache failed: $e');
    }
  }

  Future<void> _compactIfNeeded() async {
    try {
      if (_file == null) return;
      final lines = await _file!.readAsLines();
      if (lines.length < 5000) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final valid = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          final ts = map['ts'] as int? ?? 0;
          if (now - ts <= _maxAge.inMilliseconds) valid.add(line);
        } catch (e) {
          dev.log('Compact cache check line failed: $e');
        }
      }
      await _file!.writeAsString(valid.isNotEmpty ? '${valid.join('\n')}\n' : '');
    } catch (e) {
      dev.log('Compact cache file rewrite failed: $e');
    }
  }

  static Map<String, dynamic> _toJson(TrackMeta meta, int ts) => {
        'u': meta.uri,
        't': meta.title,
        's': meta.subtitle,
        'a': meta.albumName,
        'i': meta.imageUrls,
        if (meta.largeImageHex != null) 'h': meta.largeImageHex,
        'd': meta.durationMs,
        'ts': ts,
      };

  static TrackMeta? _fromJson(Map<String, dynamic> j) {
    final uri = j['u'] as String?;
    if (uri == null || uri.isEmpty) return null;

    return TrackMeta(
      uri: uri,
      title: j['t'] as String? ?? '',
      subtitle: j['s'] as String? ?? '',
      albumName: j['a'] as String? ?? '',
      imageUrls: (j['i'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      largeImageHex: j['h'] as String?,
      durationMs: j['d'] as int? ?? 0,
    );
  }
}

/// Simple bounded LRU cache.
class _LruCache<K, V> {
  _LruCache(this._maxSize);
  final int _maxSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > _maxSize) {
      _map.remove(_map.keys.first);
    }
  }

  Map<K, V> get entries => _map;
}
