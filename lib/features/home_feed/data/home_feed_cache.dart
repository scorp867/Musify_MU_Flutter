import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Binary Protobuf disk cache for the home feed response.
///
/// Format (`home_feed_<facet>.bin`):
/// `[8-byte big-endian int64 cachedAtMs][4-byte big-endian uint32 casitaLen][casitaBytes][4-byte big-endian uint32 recentsLen][recentsBytes]`
class HomeFeedCache {
  static const _policy = CachePolicy.standard;

  final AppCacheManager _cacheManager;

  HomeFeedCache({required AppCacheManager cacheManager})
    : _cacheManager = cacheManager;

  Future<File> _getCacheFile(HomeFacet facet) async {
    final dir = await _cacheManager.featureDir('home');
    return File(
      '${dir.path}${Platform.pathSeparator}home_feed_${facet.name}.bin',
    );
  }

  Future<void> _deleteLegacyJsonIfPresent(HomeFacet facet) async {
    try {
      final dir = await _cacheManager.featureDir('home');
      final legacy = File(
        '${dir.path}${Platform.pathSeparator}home_feed_${facet.name}.json',
      );
      if (await legacy.exists()) {
        await legacy.delete();
      }
    } catch (e) {
      dev.log('HomeFeedCache: failed to delete legacy json: $e');
    }
  }

  /// Persists the raw binary Casita and Recents protobuf payloads to disk.
  Future<void> saveRaw({
    required Uint8List casitaBytes,
    Uint8List? recentsBytes,
    HomeFacet facet = HomeFacet.all,
  }) async {
    if (casitaBytes.isEmpty) return;
    try {
      final file = await _getCacheFile(facet);
      final recentsLen = recentsBytes?.length ?? 0;
      final totalLen = 8 + 4 + casitaBytes.length + 4 + recentsLen;
      final out = Uint8List(totalLen);
      final header = ByteData.sublistView(out);

      int offset = 0;
      header.setInt64(
        offset,
        DateTime.now().millisecondsSinceEpoch,
        Endian.big,
      );
      offset += 8;

      header.setUint32(offset, casitaBytes.length, Endian.big);
      offset += 4;
      out.setRange(offset, offset + casitaBytes.length, casitaBytes);
      offset += casitaBytes.length;

      header.setUint32(offset, recentsLen, Endian.big);
      offset += 4;
      if (recentsBytes != null && recentsLen > 0) {
        out.setRange(offset, offset + recentsLen, recentsBytes);
      }

      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsBytes(out, flush: true);
      await tmpFile.rename(file.path);
    } catch (e) {
      dev.log('HomeFeedCache: write failed: $e');
    }
  }

  /// Loads cached raw Casita and Recents protobuf bytes from disk.
  /// Returns `null` if missing, corrupted, or expired.
  Future<({Uint8List casitaBytes, Uint8List? recentsBytes})?> loadRaw({
    HomeFacet facet = HomeFacet.all,
  }) async {
    await _deleteLegacyJsonIfPresent(facet);
    try {
      final file = await _getCacheFile(facet);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.length < 16) {
        await file.delete();
        return null;
      }

      final view = ByteData.sublistView(bytes);
      final cachedAt = view.getInt64(0, Endian.big);
      if (_policy.isExpired(cachedAt)) {
        await file.delete();
        return null;
      }

      final casitaLen = view.getUint32(8, Endian.big);
      if (casitaLen == 0 || 12 + casitaLen + 4 > bytes.length) {
        await file.delete();
        return null;
      }

      final casitaBytes = Uint8List.fromList(
        Uint8List.sublistView(bytes, 12, 12 + casitaLen),
      );
      final recentsOffset = 12 + casitaLen;
      final recentsLen = view.getUint32(recentsOffset, Endian.big);
      if (recentsOffset + 4 + recentsLen > bytes.length) {
        await file.delete();
        return null;
      }

      Uint8List? recentsBytes;
      if (recentsLen > 0) {
        recentsBytes = Uint8List.fromList(
          Uint8List.sublistView(
            bytes,
            recentsOffset + 4,
            recentsOffset + 4 + recentsLen,
          ),
        );
      }

      return (casitaBytes: casitaBytes, recentsBytes: recentsBytes);
    } catch (e) {
      dev.log('HomeFeedCache: read failed: $e');
      return null;
    }
  }
}
