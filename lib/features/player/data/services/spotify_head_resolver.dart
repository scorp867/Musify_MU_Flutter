import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 1:1 Implementation of Spotify's Head File Resolution and Caching system
/// as reverse-engineered from `liborbit-jni-spotify.so` (core-download module).
///
/// Spotify splits audio files into a variable-size "Head File" containing
/// the container header (OggS Vorbis or MP4/AAC) and initial audio frames (e.g. 128 KB for Vorbis 160,
/// or differing chunk 0 lengths for other formats and bitrates).
/// This allows instantaneous playback start with zero initial buffering lag, while
/// the secondary stream (full CDN stream or DRM track) buffers concurrently.
class SpotifyHeadResolver {
  SpotifyHeadResolver._();

  static final SpotifyHeadResolver instance = SpotifyHeadResolver._();

  /// Sole Spotify CDN host for head files (TLS 1.3 Fastly edge).
  static const String defaultCdnDomain = 'heads-fa-tls13.spotifycdn.com';

  /// No fallback domains as per strict production policy.
  static const List<String> fallbackCdnDomains = [];

  /// Standard head chunk size in bytes for default 160 kbps Vorbis (128 KB).
  /// Note: Actual head file sizes delivered by Spotify CDN vary depending on file format and bitrate.
  static const int defaultHeadFileSizeBytes = 131072;

  /// Backward compatible alias for defaultHeadFileSizeBytes.
  static const int headFileSizeBytes = defaultHeadFileSizeBytes;

  /// Minimum valid header size to guard against empty or truncated cache files.
  static const int minHeadFileSizeBytes = 512;

  Directory? _cachedHeadsDir;

  /// Resolves the canonical Spotify head file URL for a given 40-character hex file ID.
  ///
  /// Example:
  /// `https://heads-fa-tls13.spotifycdn.com/head/d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef`
  String buildHeadUrl(String fileId, {String? cdnDomain}) {
    final cleanId = normalizeFileId(fileId);
    if (cleanId.isEmpty) {
      return '';
    }
    final host = (cdnDomain != null && cdnDomain.isNotEmpty)
        ? cdnDomain
        : defaultCdnDomain;
    final url = 'https://$host/head/$cleanId';
    return url;
  }

  /// Resolves standard 30-second MP3 preview URL (`p199p/jzl1.java` line 2333).
  String buildPreviewUrl(String fileId) {
    final cleanId = normalizeFileId(fileId);
    if (cleanId.isEmpty) {
      return '';
    }
    return 'https://p.scdn.co/mp3-preview/$cleanId';
  }

  /// Normalizes a raw file ID (which may be a 40-char hex string, 20-byte list,
  /// or full Spotify URI) into a lowercase 40-character hex string.
  String normalizeFileId(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) {
      final trimmed = raw.trim().toLowerCase();
      if (trimmed.startsWith('spotify:file:')) {
        return trimmed.substring('spotify:file:'.length);
      }
      if (trimmed.length == 40 && _isHexString(trimmed)) {
        return trimmed;
      }
      return trimmed;
    }
    if (raw is List<int> && raw.length == 20) {
      final buffer = StringBuffer();
      for (final b in raw) {
        buffer.write(b.toRadixString(16).padLeft(2, '0'));
      }
      return buffer.toString().toLowerCase();
    }
    return '';
  }

  static bool _isHexString(String s) {
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i);
      final isDigit = code >= 0x30 && code <= 0x39;
      final isLowerHex = code >= 0x61 && code <= 0x66;
      final isUpperHex = code >= 0x41 && code <= 0x46;
      if (!isDigit && !isLowerHex && !isUpperHex) {
        return false;
      }
    }
    return true;
  }

  /// Returns the local cached head directory `$cache/heads/`.
  Future<Directory> getHeadsCacheDirectory() async {
    final cached = _cachedHeadsDir;
    if (cached != null) {
      return cached;
    }
    final tempDir = await getTemporaryDirectory();
    final headsDir = Directory('${tempDir.path}/heads');
    if (!await headsDir.exists()) {
      await headsDir.create(recursive: true);
    }
    _cachedHeadsDir = headsDir;
    return headsDir;
  }

  /// Returns the parent cache directory containing the `heads/` subfolder.
  Future<String> getCacheParentDirectory() async {
    final headsDir = await getHeadsCacheDirectory();
    return headsDir.parent.path;
  }

  /// Checks if the head file is already cached on disk (Spotify's `cache->lookup`).
  /// Returns the local file path if valid (size >= minHeadFileSizeBytes), or null if not cached or corrupt.
  Future<String?> getCachedHeadFilePath(String fileId) async {
    final cleanId = normalizeFileId(fileId);
    if (cleanId.isEmpty) return null;

    try {
      final dir = await getHeadsCacheDirectory();
      final file = File('${dir.path}/$cleanId.ogg');
      if (await file.exists()) {
        final length = await file.length();
        if (length >= minHeadFileSizeBytes) {
          return file.path;
        } else {
          // Incomplete or truncated file; purge from cache immediately
          await file.delete();
          return null;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Downloads and caches the head file, returning the local file path
  /// for instant zero-latency playback in `MusifyNativeAudioEngine`.
  ///
  /// Verifies Content-Length from the CDN response to ensure complete downloads
  /// across variable head file sizes.
  /// If the network request fails, returns the remote CDN URL as a streaming fallback.
  Future<String> resolveOrPrefetchHead(
    String fileId, {
    String? cdnDomain,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final cleanId = normalizeFileId(fileId);
    if (cleanId.isEmpty) {
      return '';
    }

    final firstFewBytes = cleanId.length >= 8 ? cleanId.substring(0, 8) : cleanId;
    dev.log(
      '[SpotifyHeadResolver] resolveOrPrefetchHead: fileId=$cleanId (firstFewBytes=$firstFewBytes)',
      name: 'Player.Head',
    );

    final localPath = await getCachedHeadFilePath(cleanId);
    if (localPath != null) {
      dev.log(
        '[SpotifyHeadResolver] Cache HIT for fileId=$cleanId: path=$localPath',
        name: 'Player.Head',
      );
      return localPath;
    }

    final hostsToTry = <String>[
      if (cdnDomain case final customDomain? when customDomain.isNotEmpty)
        customDomain
      else
        defaultCdnDomain,
      ...fallbackCdnDomains,
    ];

    final client = http.Client();
    try {
      for (final host in hostsToTry) {
        final remoteUrl = buildHeadUrl(cleanId, cdnDomain: host);
        try {
          dev.log(
            '[SpotifyHeadResolver] Fetching head file from CDN: $remoteUrl',
            name: 'Player.Head',
          );
          final uri = Uri.parse(remoteUrl);
          final response = await client.get(
            uri,
            headers: const {
              'Accept-Encoding': 'identity',
              'User-Agent': 'Spotify/8.9.90 Android/34',
            },
          ).timeout(timeout);

          final contentLengthHeader = response.headers['content-length'];
          final expectedLength = contentLengthHeader != null
              ? int.tryParse(contentLengthHeader)
              : null;
          final bodyLen = response.bodyBytes.length;
          final bool isValid = (expectedLength != null && expectedLength > 0)
              ? bodyLen == expectedLength
              : bodyLen >= minHeadFileSizeBytes;

          if (response.statusCode == 200 && isValid) {
            final dir = await getHeadsCacheDirectory();
            final file = File('${dir.path}/$cleanId.ogg');
            await file.writeAsBytes(response.bodyBytes, flush: true);
            dev.log(
              '[SpotifyHeadResolver] Download complete for $cleanId: '
              'size=$bodyLen bytes, expected=$expectedLength, savedPath=${file.path}',
              name: 'Player.Head',
            );
            return file.path;
          } else {
            dev.log(
              '[SpotifyHeadResolver] Download failed or invalid for $cleanId: '
              'status=${response.statusCode}, size=$bodyLen, expected=$expectedLength',
              name: 'Player.Head',
            );
          }
        } catch (e) {
          dev.log(
            '[SpotifyHeadResolver] Exception fetching head file from $host: $e',
            name: 'Player.Head',
          );
        }
      }
    } finally {
      client.close();
    }

    final fallbackUrl = buildHeadUrl(cleanId, cdnDomain: cdnDomain);
    dev.log(
      '[SpotifyHeadResolver] Falling back to remote CDN stream: $fallbackUrl',
      name: 'Player.Head',
    );
    return fallbackUrl;
  }
}
