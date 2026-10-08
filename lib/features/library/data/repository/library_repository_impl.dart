import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/core/utils/concurrency_limiter.dart';
import 'package:musify_mu/features/library/data/cache/library_cache.dart';
import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/mappers/library_mapper.dart';
import 'package:musify_mu/features/library/data/mappers/playlist_mapper.dart';
import 'package:musify_mu/features/library/data/repository/library_decorator.dart';
import 'package:musify_mu/features/library/data/sources/library_remote_source.dart';
import 'package:musify_mu/features/library/data/sources/playlist_remote_source.dart';
import 'package:musify_mu/features/library/domain/models/library_view_data.dart';
import 'package:musify_mu/features/library/domain/repositories/library_repository.dart';
import 'package:musify_mu/features/library/domain/services/cover_resolver.dart';
import 'package:musify_mu/features/library/domain/services/playlist_diff_engine.dart';

/// Thin orchestrator. Delegates to sources, mappers, engines, and caches.
/// No proto imports, no parsing logic, no diff math.
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteSource _librarySource;
  final PlaylistRemoteSource _playlistSource;
  final LibraryCache _libraryCache;
  final PlaylistDetailCache _playlistCache;
  final ExtendedMetadataService _metadataService;
  final LibraryDecorator _decorator;
  final String _userId;

  bool _playlistsSynced = false;

  LibraryRepositoryImpl({
    required LibraryRemoteSource librarySource,
    required PlaylistRemoteSource playlistSource,
    required LibraryCache libraryCache,
    required PlaylistDetailCache playlistCache,
    required ExtendedMetadataService metadataService,
    required String userId,
  })  : _librarySource = librarySource,
        _playlistSource = playlistSource,
        _libraryCache = libraryCache,
        _playlistCache = playlistCache,
        _metadataService = metadataService,
        _userId = userId,
        _decorator = LibraryDecorator(
          librarySource: librarySource,
          libraryCache: libraryCache,
          playlistCache: playlistCache,
          metadataService: metadataService,
        );

  @override
  Stream<LibraryViewData> getLibrary() async* {
    await _libraryCache.loadDecorations();

    final cached = await _buildFromCachedBytes();
    if (cached != null) yield cached;

    final fresh = await fetchFresh();
    if (fresh != null) yield fresh;
  }

  @override
  Future<LibraryViewData?> fetchFresh({bool forceSync = false}) async {
    try {
      final results = await Future.wait([
        _fetchAndCacheRootlist(),
        _fetchAndCacheCollection('artist'),
        _fetchAndCacheCollection('show'),
        _fetchAndCacheCollection('ylpin'),
        _fetchAndCacheCollection('collection'),
      ]);

      final playlistItems = results[0];
      final artistItems = results[1];
      final showItems = results[2];
      final pinnedUris = results[3];
      final likedSongs = results[4];

      final playlistIds = playlistItems
          .map((item) {
            final parts = item.uri.split(':');
            return parts.length >= 3 && parts[1] == 'playlist' ? parts[2] : '';
          })
          .where((id) => id.isNotEmpty)
          .toList();

      final rootlistCovers = <String, String>{};
      for (final item in playlistItems) {
        if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
          final parts = item.uri.split(':');
          if (parts.length >= 3 && parts[1] == 'playlist') {
            rootlistCovers[parts[2]] = item.imageUrl!;
          }
        }
      }

      await _syncPlaylistDetails(
        playlistIds,
        rootlistCovers: rootlistCovers,
        forceSync: forceSync,
      );

      return await _assembleViewData(
        playlistItems, artistItems, showItems, pinnedUris, likedSongs,
      );
    } catch (e, st) {
      dev.log('LibraryRepo error: $e',
          name: 'Library', error: e, stackTrace: st);
      return null;
    }
  }

  // ─── Assembly ───────────────────────────────────────────────────────

  Future<LibraryViewData> _assembleViewData(
    List<LibraryItem> playlistItems,
    List<LibraryItem> artistItems,
    List<LibraryItem> showItems,
    List<LibraryItem> pinnedUris,
    List<LibraryItem> likedSongs,
  ) async {
    final pinnedSet = pinnedUris.map((e) => e.uri).toSet();
    final decoratedArtists = await _decorator.decorateArtists(artistItems);
    final decoratedPlaylists =
        await _decorator.decoratePlaylists(playlistItems);

    final allItems = <LibraryItem>[
      if (likedSongs.isNotEmpty)
        LibraryItem(
          uri: 'spotify:collection:tracks',
          type: 'playlist',
          name: 'Liked Songs',
          ownerName: _userId,
          addedAt: DateTime.now(),
          isPinned: pinnedSet.contains('spotify:collection:tracks'),
          trackCount: likedSongs.length,
        ),
      ...decoratedPlaylists
          .map((i) => i.copyWith(isPinned: pinnedSet.contains(i.uri))),
      ...decoratedArtists
          .map((i) => i.copyWith(isPinned: pinnedSet.contains(i.uri))),
      ...showItems
          .map((i) => i.copyWith(isPinned: pinnedSet.contains(i.uri))),
    ];

    return LibraryViewData(items: allItems, pinnedUris: pinnedSet);
  }

  // ─── Cached bytes → LibraryViewData ─────────────────────────────────

  Future<LibraryViewData?> _buildFromCachedBytes() async {
    final rootBytes = await _libraryCache.getStructureBytes('rootlist');
    if (rootBytes == null) return null;

    try {
      final playlistItems =
          await Isolate.run(() => LibraryMapper.parseRootlist(rootBytes));
      final artistItems = await _parseCachedCollection('artist');
      final showItems = await _parseCachedCollection('show');
      final pinnedUris = await _parseCachedCollection('ylpin');
      final likedSongs = await _parseCachedCollection('collection');

      return await _assembleViewData(
        playlistItems, artistItems, showItems, pinnedUris, likedSongs,
      );
    } catch (e, st) {
      dev.log('Cache rebuild error: $e',
          name: 'Library', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<LibraryItem>> _parseCachedCollection(String name) async {
    final bytes = await _libraryCache.getStructureBytes('col_$name');
    if (bytes == null) return [];
    return Isolate.run(() => LibraryMapper.parseCollection(bytes, name));
  }

  // ─── Network: Rootlist & Collections ────────────────────────────────

  Future<List<LibraryItem>> _fetchAndCacheRootlist() async {
    final bytes = await _librarySource.fetchRootlist();
    if (bytes == null || bytes.isEmpty) return [];

    _libraryCache.putStructureBytes('rootlist', bytes);

    try {
      return await Isolate.run(() => LibraryMapper.parseRootlist(bytes));
    } catch (e, st) {
      dev.log('Rootlist parse error: $e',
          name: 'Library', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<LibraryItem>> _fetchAndCacheCollection(String setName) async {
    final bytes = await _librarySource.fetchCollection(setName);
    if (bytes == null || bytes.isEmpty) return [];

    _libraryCache.putStructureBytes('col_$setName', bytes);

    try {
      return await Isolate.run(
          () => LibraryMapper.parseCollection(bytes, setName));
    } catch (e, st) {
      dev.log('Collection/$setName parse error: $e',
          name: 'Library', error: e, stackTrace: st);
      return [];
    }
  }

  // ─── Playlist sync (diff-based) ─────────────────────────────────────

  Future<void> _syncPlaylistDetails(
    List<String> playlistIds, {
    Map<String, String> rootlistCovers = const {},
    bool forceSync = false,
  }) async {
    if (playlistIds.isEmpty) return;

    final List<String> toSync;
    if (!_playlistsSynced || forceSync) {
      toSync = playlistIds;
      _playlistsSynced = true;
    } else {
      final cached = await _playlistCache.cachedIds();
      toSync = playlistIds.where((id) => !cached.contains(id)).toList();
    }
    if (toSync.isEmpty) return;
    await ConcurrencyLimiter.runPooled(
      toSync,
      (id) => _syncSinglePlaylist(
        id,
        rootlistCover: rootlistCovers[id],
      ),
      maxConcurrent: 4,
    );
  }

  Future<void> _syncSinglePlaylist(
    String playlistId, {
    String? rootlistCover,
  }) async {
    try {
      final cachedRevision = await _playlistCache.getRevision(playlistId);

      if (cachedRevision == null) {
        await _fullFetchPlaylist(playlistId, rootlistCover: rootlistCover);
        return;
      }

      final diffBytes =
          await _playlistSource.fetchDiff(playlistId, cachedRevision);
      if (diffBytes == null || diffBytes.isEmpty) {
        await _fullFetchPlaylist(playlistId, rootlistCover: rootlistCover);
        return;
      }

      final diff = PlaylistMapper.parseDiffResponse(diffBytes);

      if (diff.changesRequireResync) {
        await _fullFetchPlaylist(playlistId, rootlistCover: rootlistCover);
        return;
      }

      final newRevision = diff.toRevision;
      if (newRevision == cachedRevision && diff.ops.isEmpty) return;

      final cached = await _playlistCache.get(playlistId);
      if (cached == null) {
        await _fullFetchPlaylist(playlistId, rootlistCover: rootlistCover);
        return;
      }

      final newTrackUris =
          PlaylistDiffEngine.apply(cached.trackUris, diff.ops);

      final newUris =
          newTrackUris.where((u) => !cached.trackUris.contains(u)).toList();
      if (newUris.isNotEmpty) {
        await _metadataService.fetchTracks(newUris);
      }

      // Check if custom cover applies
      final bool wasCustom = cached.isCustomCover ||
          (rootlistCover != null && rootlistCover.isNotEmpty);
      final String? cachedCover =
          cached.isCustomCover ? cached.coverUrl : rootlistCover;

      final bool isCustomNow = diff.coverChange is CoverSet ||
          (diff.coverChange == null && wasCustom);

      final List<String> mosaicUrls;
      if (isCustomNow) {
        mosaicUrls = const [];
      } else {
        mosaicUrls = await _decorator.getMosaicUrls(newTrackUris);
      }

      final cover = CoverResolver.resolve(
        wasCustomCover: wasCustom,
        cachedCoverUrl: cachedCover,
        coverChange: diff.coverChange,
        mosaicUrls: mosaicUrls,
      );

      await _playlistCache.put(
        playlistId: playlistId,
        revision: newRevision,
        trackUris: newTrackUris,
        coverUrl: cover.coverUrl,
        isCustomCover: cover.isCustomCover,
        mosaicImageUrls: cover.mosaicImageUrls,
      );
    } catch (e, st) {
      dev.log('Playlist sync/$playlistId error: $e',
          name: 'Library', error: e, stackTrace: st);
    }
  }

  Future<void> _fullFetchPlaylist(
    String playlistId, {
    String? rootlistCover,
  }) async {
    final bytes = await _playlistSource.fetchFull(playlistId);
    if (bytes == null || bytes.isEmpty) return;

    final snapshot = await Isolate.run(
      () => PlaylistMapper.parseFullResponse(bytes, playlistId),
    );
    if (snapshot == null) return;

    final cached = await _playlistCache.get(playlistId);
    final customCover = snapshot.coverUrl ??
        rootlistCover ??
        (cached?.isCustomCover == true ? cached?.coverUrl : null);
    final hasCustomCover = customCover != null && customCover.isNotEmpty;

    final List<String> mosaicUrls;
    if (hasCustomCover) {
      mosaicUrls = const [];
    } else {
      mosaicUrls = await _decorator.getMosaicUrls(snapshot.trackUris);
    }

    final cover = CoverResolver.resolveFromFull(
      customCoverUrl: customCover,
      mosaicUrls: mosaicUrls,
    );

    await _playlistCache.put(
      playlistId: playlistId,
      revision: snapshot.revision,
      trackUris: snapshot.trackUris,
      coverUrl: cover.coverUrl,
      isCustomCover: cover.isCustomCover,
      mosaicImageUrls: cover.mosaicImageUrls,
      rawBytes: bytes,
    );
  }
}
