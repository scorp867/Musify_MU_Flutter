import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/core/protocol/generated/spotify/playlist/playlist_detail.pb.dart'
    as detail_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import 'package:musify_mu/features/library/data/playlist_detail_cache.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Fetched playlist data ready for consumption.
class PlaylistDetail {
  final String playlistId;
  final String revision;
  final String name;
  final String? description;
  final String ownerUsername;
  final int trackCount;
  final List<String> trackUris;
  final String? coverUrl;

  /// First 4 unique album art URLs for client-side mosaic rendering.
  /// Empty if the playlist has a custom cover.
  final List<String> mosaicImageUrls;

  final bool canEditItems;
  final bool canEditMetadata;

  const PlaylistDetail({
    required this.playlistId,
    required this.revision,
    required this.name,
    this.description,
    required this.ownerUsername,
    required this.trackCount,
    required this.trackUris,
    this.coverUrl,
    this.mosaicImageUrls = const [],
    this.canEditItems = false,
    this.canEditMetadata = false,
  });
}

/// Fetches individual playlist data with revision-based diff support.
///
/// Flow:
///   1. First fetch: GET /playlist/v2/playlist/{id} -> full snapshot
///      -> parse track URIs, cover, revision -> cache all + build mosaic
///   2. Subsequent: GET /playlist/v2/playlist/{id}/diff?revision={rev}
///      a. Revision unchanged -> skip (cache is valid)
///      b. Revision changed   -> apply diff ops (ADD/REM/MOV) to cached
///         track list -> rotate revision in cache -> rebuild mosaic
///      c. changesRequireResync -> full re-fetch as (1)
///   3. Decorate first 4 unique track arts via [ExtendedMetadataService]
///      for client-side mosaic rendering
class PlaylistDetailFetcher {
  final SpotifyTransport _client;
  final PlaylistDetailCache _cache;
  final ExtendedMetadataService _metadataService;

  PlaylistDetailFetcher({
    required SpotifyTransport client,
    required ExtendedMetadataService metadataService,
    required AppCacheManager cacheManager,
    PlaylistDetailCache? cache,
  })  : _client = client,
        _metadataService = metadataService,
        _cache = cache ??
            PlaylistDetailCache(cacheManager: cacheManager);

  PlaylistDetailCache get cache => _cache;

  /// Fetches playlist data, using diff if a revision is cached.
  ///
  /// Returns null only on network/parse failure.
  Future<PlaylistDetail?> fetch(String playlistId) async {
    try {
      final cachedRevision = await _cache.getRevision(playlistId);
      final hasCachedRevision =
          cachedRevision != null && cachedRevision.isNotEmpty;

      // ── First fetch: no cached revision, get full snapshot. ──
      if (!hasCachedRevision) {
        return await _fetchFullAndProcess(playlistId);
      }

      // ── Subsequent fetch: query diff endpoint for changes. ──
      final diffBytes = await _fetchDiff(playlistId, cachedRevision);
      if (diffBytes == null || diffBytes.isEmpty) return null;

      // Diff payloads are small (ops only), safe to parse on main thread.
      final diffResponse = detail_pb.PlaylistResponse.fromBuffer(diffBytes);
      final newRevision = _revisionToString(diffResponse.revision);

      // Log the full parsed response for debugging.
      _logParsedDiffResponse(playlistId, diffResponse, cachedRevision, newRevision);

      // Server says diff is too complex -- full re-sync required.
      if (diffResponse.changesRequireResync) {
        debugPrint(
          '[Library] PlaylistFetch/$playlistId: DECISION -> server requires resync, full fetch',
        );
        return await _fetchFullAndProcess(playlistId);
      }

      // ── Revision unchanged: playlist hasn't been modified. ──
      if (newRevision == cachedRevision) {
        final cached = await _cache.get(playlistId);
        final cacheHealthy = cached != null &&
            (cached.coverUrl != null || cached.mosaicImageUrls.isNotEmpty) &&
            cached.trackUris.isNotEmpty;

        if (cacheHealthy) {
          debugPrint(
            '[Library] PlaylistFetch/$playlistId: DECISION -> unchanged, cache healthy, skip',
          );
          return null;
        }

        debugPrint(
          '[Library] PlaylistFetch/$playlistId: DECISION -> unchanged but cache corrupted, full fetch to repair',
        );
        return await _fetchFullAndProcess(playlistId);
      }

      // ── Revision changed: apply diff ops to cached track list. ──
      final cached = await _cache.get(playlistId);
      if (cached == null || cached.trackUris.isEmpty) {
        debugPrint(
          '[Library] PlaylistFetch/$playlistId: DECISION -> revision changed but no cached track list, full fetch',
        );
        return await _fetchFullAndProcess(playlistId);
      }

      debugPrint(
        '[Library] PlaylistFetch/$playlistId: DECISION -> revision changed '
        '(${_truncateRev(cachedRevision)} -> ${_truncateRev(newRevision)}), '
        'applying ${diffResponse.diff.ops.length} ops to ${cached.trackUris.length} cached tracks',
      );

      return await _applyDiffAndProcess(
        playlistId,
        diffResponse,
        newRevision,
        cachedRevision,
        cached,
      );
    } catch (e, st) {
      debugPrint(
        '[Library] PlaylistFetch/$playlistId ERROR: $e\n$st',
      );
      return null;
    }
  }

  // ─── Full fetch path ──────────────────────────────────────────────

  /// Fetches the complete playlist snapshot and processes it.
  Future<PlaylistDetail?> _fetchFullAndProcess(String playlistId) async {
    final bytes = await _fetchFull(playlistId);
    if (bytes == null || bytes.isEmpty) return null;

    final detail = await Isolate.run(
      () => _parsePlaylistBytes(bytes, playlistId),
    );
    if (detail == null) return null;

    return await _processAndCache(playlistId, detail, bytes);
  }

  // ─── Diff application path ────────────────────────────────────────

  /// Applies diff operations to cached data, rebuilds mosaic, rotates
  /// revision, and persists updated cache entry.
  Future<PlaylistDetail?> _applyDiffAndProcess(
    String playlistId,
    detail_pb.PlaylistResponse diffResponse,
    String newRevision,
    String oldRevision,
    PlaylistCacheEntry cached,
  ) async {
    debugPrint(
      '[Library] PlaylistFetch/$playlistId: ── APPLYING DIFF ──\n'
      '  cached tracks (${cached.trackUris.length}): '
      '${cached.trackUris.take(6).join(", ")}${cached.trackUris.length > 6 ? "..." : ""}',
    );

    // Apply ADD / REM / MOV ops to produce the complete new track list.
    final newTrackUris = _applyDiffOps(
      cached.trackUris,
      diffResponse.diff.ops,
    );

    debugPrint(
      '[Library] PlaylistFetch/$playlistId: after ops applied:\n'
      '  tracks (${newTrackUris.length}): '
      '${newTrackUris.take(6).join(", ")}${newTrackUris.length > 6 ? "..." : ""}',
    );

    // Fetch metadata for tracks (service caches internally, only
    // fetches URIs not already in its cache).
    if (newTrackUris.isNotEmpty) {
      await _metadataService.fetchTracks(newTrackUris);
    }

    // ── Cover & mosaic resolution ──
    // The cache tracks whether the cover is user-set (custom) or derived
    // from track album art. After diff ops change the track list, we MUST
    // regenerate the mosaic unless the playlist has a custom cover.

    // 1. Check if the diff changed the cover (set or removed).
    String? customCoverFromDiff;
    bool coverWasRemoved = false;

    for (final op in diffResponse.diff.ops) {
      if (op.kind == detail_pb.OpKind.UPDATE_LIST_ATTRIBUTES &&
          op.hasUpdateListAttributes()) {
        final ula = op.updateListAttributes;

        // Check if picture was explicitly cleared via no_value.
        if (ula.hasNewAttributes()) {
          for (final cleared in ula.newAttributes.noValue) {
            if (cleared == detail_pb.ListAttributeKind.LIST_PICTURE) {
              coverWasRemoved = true;
              break;
            }
          }
        }

        // Check if a new picture was set.
        if (!coverWasRemoved &&
            ula.hasNewAttributes() &&
            ula.newAttributes.hasValues()) {
          final newCover = _extractCoverUrl(ula.newAttributes.values);
          if (newCover != null) {
            customCoverFromDiff = newCover;
          } else if (ula.newAttributes.values.picture.isEmpty &&
              cached.isCustomCover) {
            // Picture field present but empty -> cover removed.
            coverWasRemoved = true;
          }
        }
      }
    }

    String? coverUrl;
    List<String> mosaicUrls = const [];
    bool isCustomCover = cached.isCustomCover;

    if (customCoverFromDiff != null) {
      // Diff explicitly set a new custom cover.
      coverUrl = customCoverFromDiff;
      isCustomCover = true;
    } else if (coverWasRemoved) {
      // Cover was explicitly removed. Regenerate mosaic.
      isCustomCover = false;
      mosaicUrls = _getMosaicUrlsFromCache(newTrackUris);
      coverUrl = mosaicUrls.isNotEmpty ? mosaicUrls.first : null;
    } else if (cached.isCustomCover) {
      // Playlist has a user-set custom cover. Keep it.
      coverUrl = cached.coverUrl;
    } else {
      // No custom cover. Regenerate mosaic from the new track list.
      mosaicUrls = _getMosaicUrlsFromCache(newTrackUris);
      coverUrl = mosaicUrls.isNotEmpty ? mosaicUrls.first : null;
    }

    final mosaicList = mosaicUrls.length >= 4 ? mosaicUrls : const <String>[];

    debugPrint(
      '[Library] PlaylistFetch/$playlistId: cover & mosaic resolution:\n'
      '  cached.isCustomCover: ${cached.isCustomCover}\n'
      '  customCoverFromDiff: ${customCoverFromDiff ?? "none"}\n'
      '  coverWasRemoved: $coverWasRemoved\n'
      '  regenerated mosaicUrls: ${mosaicUrls.length}\n'
      '  final isCustomCover: $isCustomCover\n'
      '  final coverUrl: ${coverUrl ?? "null"}\n'
      '  final mosaicList: ${mosaicList.length}',
    );

    // Persist with ROTATED revision.
    await _cache.put(
      playlistId: playlistId,
      revision: newRevision,
      trackUris: newTrackUris,
      coverUrl: coverUrl,
      isCustomCover: isCustomCover,
      mosaicImageUrls: mosaicList,
    );

    debugPrint(
      '[Library] PlaylistFetch/$playlistId: ── DIFF COMPLETE ──\n'
      '  revision rotated: ${_truncateRev(oldRevision)} -> ${_truncateRev(newRevision)}\n'
      '  tracks: ${cached.trackUris.length} -> ${newTrackUris.length}\n'
      '  cover: ${coverUrl != null ? "yes" : "no"}, mosaic: ${mosaicList.length}\n'
      '  cache persisted',
    );

    // Extract name from UPDATE_LIST_ATTRIBUTES if changed, otherwise
    // diff responses don't include top-level attributes.
    String name = '';
    for (final op in diffResponse.diff.ops) {
      if (op.kind == detail_pb.OpKind.UPDATE_LIST_ATTRIBUTES &&
          op.hasUpdateListAttributes() &&
          op.updateListAttributes.hasNewAttributes() &&
          op.updateListAttributes.newAttributes.hasValues()) {
        final newName = op.updateListAttributes.newAttributes.values.name;
        if (newName.isNotEmpty) name = newName;
        break;
      }
    }

    return PlaylistDetail(
      playlistId: playlistId,
      revision: newRevision,
      name: name,
      ownerUsername: diffResponse.ownerUsername,
      trackCount: newTrackUris.length,
      trackUris: newTrackUris,
      coverUrl: coverUrl,
      mosaicImageUrls: mosaicList,
    );
  }

  /// Applies diff operations sequentially to transform a track list.
  ///
  /// Each op's indices are relative to the state AFTER all previous
  /// ops have been applied (Spotify's diff protocol is sequential).
  ///
  /// Op structure (from decompiled Playlist4ApiProto.java):
  ///   Op { kind, Add add, Rem rem, Mov mov, ... }
  ///   Add { from_index, repeated Item items, add_last, add_first, ... }
  ///   Rem { from_index, length, repeated Item items, ... }
  ///   Mov { from_index, length, to_index, ... }
  static List<String> _applyDiffOps(
    List<String> cachedTracks,
    List<detail_pb.Op> ops,
  ) {
    final tracks = List<String>.from(cachedTracks);

    for (final op in ops) {
      if (op.kind == detail_pb.OpKind.ADD && op.hasAdd()) {
        final addOp = op.add;
        final newUris = <String>[];
        for (final item in addOp.items) {
          if (item.uri.isNotEmpty) newUris.add(item.uri);
        }
        if (newUris.isEmpty) continue;

        if (addOp.addLast) {
          tracks.addAll(newUris);
        } else if (addOp.addFirst) {
          tracks.insertAll(0, newUris);
        } else {
          final insertAt = addOp.fromIndex.clamp(0, tracks.length);
          tracks.insertAll(insertAt, newUris);
        }
      } else if (op.kind == detail_pb.OpKind.REM && op.hasRem()) {
        final remOp = op.rem;
        final start = remOp.fromIndex.clamp(0, tracks.length);
        final removeCount = remOp.length.clamp(0, tracks.length - start);
        if (removeCount > 0) {
          tracks.removeRange(start, start + removeCount);
        }
      } else if (op.kind == detail_pb.OpKind.MOV && op.hasMov()) {
        final movOp = op.mov;
        final start = movOp.fromIndex.clamp(0, tracks.length);
        final moveCount = movOp.length.clamp(0, tracks.length - start);
        if (moveCount > 0) {
          final moved = tracks.sublist(start, start + moveCount);
          tracks.removeRange(start, start + moveCount);

          // Spotify's toIndex refers to the position in the ORIGINAL array
          // (before removal). When fromIndex < toIndex, removing items
          // before toIndex shifts everything left by `moveCount`, so we
          // must adjust the insertion point.
          int target;
          if (start < movOp.toIndex) {
            target = (movOp.toIndex - moveCount).clamp(0, tracks.length);
          } else {
            target = movOp.toIndex.clamp(0, tracks.length);
          }
          tracks.insertAll(target, moved);
        }
      }
      // UPDATE_ITEM_ATTRIBUTES / UPDATE_LIST_ATTRIBUTES / UPDATE_ITEM_URIS
      // don't affect the track URI list.
    }

    return tracks;
  }

  /// Logs the full parsed diff response for terminal debugging.
  static void _logParsedDiffResponse(
    String playlistId,
    detail_pb.PlaylistResponse resp,
    String cachedRevision,
    String newRevision,
  ) {
    final buf = StringBuffer();
    buf.writeln('[Library] PlaylistFetch/$playlistId: ── PARSED DIFF RESPONSE ──');
    buf.writeln('  cachedRevision:     ${_truncateRev(cachedRevision)}');
    buf.writeln('  response.revision:  ${_truncateRev(newRevision)}');

    if (resp.hasDiff()) {
      final diff = resp.diff;
      final from = _revisionToString(diff.fromRevision);
      final to = _revisionToString(diff.toRevision);
      buf.writeln('  diff.fromRevision:  ${_truncateRev(from)}');
      buf.writeln('  diff.toRevision:    ${_truncateRev(to)}');
      buf.writeln('  diff.ops.length:    ${diff.ops.length}');

      for (var i = 0; i < diff.ops.length; i++) {
        final op = diff.ops[i];
        buf.writeln('  ── Op[$i] kind=${op.kind.name} ──');

        if (op.hasAdd()) {
          final a = op.add;
          buf.writeln('    ADD: fromIndex=${a.fromIndex}, '
              'addFirst=${a.addFirst}, addLast=${a.addLast}, '
              'items=${a.items.length}');
          for (final item in a.items) {
            buf.writeln('      + ${item.uri}');
          }
        }
        if (op.hasRem()) {
          final r = op.rem;
          buf.writeln('    REM: fromIndex=${r.fromIndex}, '
              'length=${r.length}, items=${r.items.length}');
          for (final item in r.items) {
            buf.writeln('      - ${item.uri}');
          }
        }
        if (op.hasMov()) {
          final m = op.mov;
          buf.writeln('    MOV: fromIndex=${m.fromIndex}, '
              'toIndex=${m.toIndex}, length=${m.length}');
        }
        if (op.hasUpdateListAttributes()) {
          final ula = op.updateListAttributes;
          if (ula.hasNewAttributes() && ula.newAttributes.hasValues()) {
            final v = ula.newAttributes.values;
            buf.writeln('    UPDATE_LIST_ATTRS new: '
                'name="${v.name}", picture="${v.picture}"');
          }
          if (ula.hasOldAttributes() && ula.oldAttributes.hasValues()) {
            final v = ula.oldAttributes.values;
            buf.writeln('    UPDATE_LIST_ATTRS old: '
                'name="${v.name}", picture="${v.picture}"');
          }
        }
        if (op.hasUpdateItemAttributes()) {
          final uia = op.updateItemAttributes;
          buf.writeln('    UPDATE_ITEM_ATTRS: index=${uia.index}');
        }
        if (op.hasUpdateItemUris()) {
          final uiu = op.updateItemUris;
          buf.writeln('    UPDATE_ITEM_URIS: '
              '${uiu.uriReplacements.length} replacements');
        }
      }
    } else {
      buf.writeln('  hasDiff: false (full snapshot response)');
    }

    buf.writeln('  changesRequireResync: ${resp.changesRequireResync}');
    buf.writeln('  upToDate: ${resp.upToDate}');
    buf.write('  ── END PARSED DIFF RESPONSE ──');

    debugPrint(buf.toString());
  }

  static String _truncateRev(String rev) =>
      rev.length > 8 ? '${rev.substring(0, 8)}..' : rev;

  // ─── Full-fetch processing (shared by first-fetch + repair) ───────

  /// Fetches track metadata, builds mosaic, and persists to cache.
  Future<PlaylistDetail> _processAndCache(
    String playlistId,
    PlaylistDetail detail,
    Uint8List rawBytes,
  ) async {
    // Fetch ALL track metadata into the centralized cache.
    if (detail.trackUris.isNotEmpty) {
      await _metadataService.fetchTracks(detail.trackUris);
    }

    // If no custom cover, gather mosaic URLs from the now-cached track data.
    var finalDetail = detail;
    final hasCustomCover = detail.coverUrl != null && detail.coverUrl!.isNotEmpty;

    if (!hasCustomCover) {
      final mosaicUrls = _getMosaicUrlsFromCache(detail.trackUris);
      finalDetail = PlaylistDetail(
        playlistId: detail.playlistId,
        revision: detail.revision,
        name: detail.name,
        description: detail.description,
        ownerUsername: detail.ownerUsername,
        trackCount: detail.trackCount,
        trackUris: detail.trackUris,
        coverUrl: mosaicUrls.isNotEmpty ? mosaicUrls.first : null,
        mosaicImageUrls: mosaicUrls.length >= 4 ? mosaicUrls : const [],
        canEditItems: detail.canEditItems,
        canEditMetadata: detail.canEditMetadata,
      );
    }

    // Persist to cache.
    await _cache.put(
      playlistId: playlistId,
      revision: finalDetail.revision,
      trackUris: finalDetail.trackUris,
      coverUrl: finalDetail.coverUrl,
      isCustomCover: hasCustomCover,
      mosaicImageUrls: finalDetail.mosaicImageUrls,
      rawBytes: rawBytes,
    );

    dev.log(
      'PlaylistFetch/$playlistId: ${finalDetail.trackUris.length} tracks, '
      'cover=${finalDetail.coverUrl != null ? "yes" : "no"}, '
      'mosaic=${finalDetail.mosaicImageUrls.length}, '
      'rev=${_truncateRev(finalDetail.revision)}',
      name: 'Library',
    );

    return finalDetail;
  }

  /// Fetches multiple playlists in parallel, returns a map of id → detail.
  Future<Map<String, PlaylistDetail>> fetchBatch(
    List<String> playlistIds,
  ) async {
    final results = <String, PlaylistDetail>{};

    // Fetch in batches of 5 to avoid overwhelming the network.
    const batchSize = 5;
    for (var i = 0; i < playlistIds.length; i += batchSize) {
      final batch = playlistIds.skip(i).take(batchSize).toList();
      final futures = batch.map((id) => fetch(id));
      final batchResults = await Future.wait(futures);

      for (var j = 0; j < batch.length; j++) {
        if (batchResults[j] != null) {
          results[batch[j]] = batchResults[j]!;
        }
      }
    }

    return results;
  }

  // ─── Mosaic ───────────────────────────────────────────────────────

  /// Returns first 4 unique album art URLs from cached track metadata.
  /// Used for client-side mosaic rendering (2x2 grid).
  List<String> _getMosaicUrlsFromCache(List<String> trackUris) {
    final urls = <String>[];
    final seen = <String>{};

    for (final uri in trackUris) {
      if (!uri.startsWith('spotify:track:')) continue;

      final meta = _metadataService.getCached(uri);
      if (meta == null) continue;

      final url = meta.imageUrl;
      if (url.isNotEmpty && seen.add(url)) {
        urls.add(url);
        if (urls.length >= 4) break;
      }
    }

    return urls;
  }

  // ─── Network ──────────────────────────────────────────────────────

  Future<Uint8List?> _fetchFull(String playlistId) async {
    return _client.get('/playlist/v2/playlist/$playlistId');
  }

  Future<Uint8List?> _fetchDiff(
    String playlistId,
    String revision,
  ) async {
    final encodedRev = Uri.encodeComponent(revision);
    return _client.get(
      '/playlist/v2/playlist/$playlistId/diff'
      '?revision=$encodedRev'
      '&handlesContent=',
    );
  }

  // ─── Parsing (static, runs in isolate) ────────────────────────────

  static PlaylistDetail? _parsePlaylistBytes(
    Uint8List bytes,
    String playlistId,
  ) {
    // Try PlaylistResponse first (has diff + capabilities).
    try {
      final response = detail_pb.PlaylistResponse.fromBuffer(bytes);

      final revision = _revisionToString(response.revision);
      final name = response.attributes.name;
      final description = response.attributes.description;
      final owner = response.ownerUsername;
      final trackCount = response.length;

      final trackUris = <String>[];
      for (final item in response.contents.items) {
        if (item.uri.isNotEmpty) {
          trackUris.add(item.uri);
        }
      }

      String? coverUrl = _extractCoverUrl(response.attributes);

      final canEditItems =
          response.hasCapabilities() && response.capabilities.canEditItems;
      final canEditMetadata =
          response.hasCapabilities() && response.capabilities.canEditMetadata;

      return PlaylistDetail(
        playlistId: playlistId,
        revision: revision,
        name: name,
        description: description.isNotEmpty ? description : null,
        ownerUsername: owner,
        trackCount: trackCount,
        trackUris: trackUris,
        coverUrl: coverUrl,
        canEditItems: canEditItems,
        canEditMetadata: canEditMetadata,
      );
    } catch (e) {
      // Fallback: try parsing as SelectedListContent.
      try {
        final response = rootlist_pb.SelectedListContent.fromBuffer(bytes);
        final revision = _revisionToString(response.revision);
        final trackUris = <String>[];
        for (final item in response.contents.items) {
          if (item.uri.isNotEmpty) {
            trackUris.add(item.uri);
          }
        }

        String? coverUrl = _extractCoverUrl(response.attributes);

        return PlaylistDetail(
          playlistId: playlistId,
          revision: revision,
          name: response.attributes.name,
          ownerUsername: response.ownerUsername,
          trackCount: response.length,
          trackUris: trackUris,
          coverUrl: coverUrl,
        );
      } catch (e) {
        dev.log('Parse playlist fallback failed: $e');
        return null;
      }
    }
  }

  /// Converts protobuf revision bytes to the string format used by
  /// the diff endpoint: "{counter},{sha1hex}".
  static String _revisionToString(List<int> revisionBytes) {
    if (revisionBytes.length < 24) {
      return revisionBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    final counter = (revisionBytes[0] << 24) |
        (revisionBytes[1] << 16) |
        (revisionBytes[2] << 8) |
        revisionBytes[3];

    final hash = revisionBytes
        .sublist(4)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '$counter,$hash';
  }

  /// Extracts cover image URL from ListAttributes.
  static String? _extractCoverUrl(rootlist_pb.ListAttributes attrs) {
    // Try picture_size first (pre-built URLs).
    if (attrs.pictureSize.isNotEmpty) {
      return attrs.pictureSize.first.url;
    }

    // Try formatAttributes 'picture' key.
    for (final attr in attrs.formatAttributes) {
      if (attr.key == 'picture') {
        final val = attr.value;
        if (val.startsWith('spotify:image:')) {
          return 'https://i.scdn.co/image/${val.split(':').last}';
        } else if (val.startsWith('http')) {
          return val;
        } else if (val.isNotEmpty) {
          return 'https://i.scdn.co/image/$val';
        }
      }
    }

    // Try raw picture bytes (20-byte hash).
    if (attrs.picture.isNotEmpty && attrs.picture.length == 20) {
      final hex = attrs.picture
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      return 'https://i.scdn.co/image/$hex';
    }

    return null;
  }
}
