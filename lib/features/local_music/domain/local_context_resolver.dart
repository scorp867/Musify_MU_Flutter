import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/playback_context.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

/// 1:1 with Spotify's Cosmos ContextResolver for local & offline music.
///
/// Chunks device songs into discrete [ContextPage] instances with page URLs
/// and boundary delimiters, unifying offline playback with Spotify's production
/// pagination architecture.
class LocalContextResolver {
  static const int defaultPageSize = 50;
  static final Map<String, PlaybackContext> _activeContexts = {};

  static void registerContext(PlaybackContext context) {
    _activeContexts[context.url] = context;
    _activeContexts[context.uri] = context;
  }

  static ContextPage? resolvePage(String pageUrl) {
    for (final ctx in _activeContexts.values) {
      for (final page in ctx.pages) {
        if (page.pageUrl == pageUrl) return page;
      }
    }
    return null;
  }

  /// Creates a chunked [PlaybackContext] from a collection of local items.
  static PlaybackContext buildContext({
    required List<Map<String, dynamic>> rawTracks,
    String contextUri = 'spotify:context:local-music',
    String contextUrl = 'context://local:all_tracks',
    int pageSize = defaultPageSize,
  }) {
    if (rawTracks.isEmpty) {
      final emptyCtx = PlaybackContext(
        uri: contextUri,
        url: contextUrl,
        pages: const [],
      );
      registerContext(emptyCtx);
      return emptyCtx;
    }


    final pages = <ContextPage>[];
    final totalPages = (rawTracks.length / pageSize).ceil();

    for (int p = 0; p < totalPages; p++) {
      final start = p * pageSize;
      final end = (start + pageSize).clamp(0, rawTracks.length);
      final chunk = rawTracks.sublist(start, end);

      final tracks = chunk.asMap().entries.map((entry) {
        final trackIndex = start + entry.key;
        final data = entry.value;
        final songId = data['songId']?.toString() ?? trackIndex.toString();
        final path = data['dataPath']?.toString() ?? '';

        return ContextTrack(
          uri: 'local:track:$songId',
          uid: 'local_uid_${songId}_$trackIndex',
          provider: 'context',
          isQueued: false,
          metadata: {
            'title': data['title']?.toString() ?? 'Unknown Title',
            'artist_name': data['artist']?.toString() ?? 'Unknown Artist',
            'album_title': data['album']?.toString() ?? 'Unknown Album',
            'duration_ms': (data['duration'] ?? 0).toString(),
            'data_path': path,
            'dataPath': path,
            'songId': songId,
            'is_queued': 'false',
            'page_url': '$contextUrl?page=$p',
            'next_page_url': p + 1 < totalPages ? '$contextUrl?page=${p + 1}' : '',
            'context_url': contextUrl,
            'page_index': p.toString(),
          },
        );
      }).toList();

      final pageUrl = '$contextUrl?page=$p';
      final hasNext = p + 1 < totalPages;
      final nextPageUrl = hasNext ? '$contextUrl?page=${p + 1}' : '';

      pages.add(
        ContextPage(
          pageUrl: pageUrl,
          nextPageUrl: nextPageUrl,
          tracks: tracks,
          metadata: {
            'page_index': p.toString(),
            'total_pages': totalPages.toString(),
          },
        ),
      );
    }

    final context = PlaybackContext(
      uri: contextUri,
      url: contextUrl,
      pages: pages,
    );
    registerContext(context);
    return context;
  }


  /// Creates a chunked [PlaybackContext] from a collection of [DomainTrack] entities.
  static PlaybackContext buildContextFromDomainTracks({
    required List<DomainTrack> tracks,
    String contextUri = 'spotify:context:local-music',
    String contextUrl = 'context://local:all_tracks',
    int pageSize = defaultPageSize,
  }) {
    if (tracks.isEmpty) {
      return PlaybackContext(
        uri: contextUri,
        url: contextUrl,
        pages: const [],
      );
    }

    final pages = <ContextPage>[];
    final totalPages = (tracks.length / pageSize).ceil();

    for (int p = 0; p < totalPages; p++) {
      final start = p * pageSize;
      final end = (start + pageSize).clamp(0, tracks.length);
      final chunk = tracks.sublist(start, end);

      final contextTracks = chunk.asMap().entries.map((entry) {
        final trackIndex = start + entry.key;
        final track = entry.value;
        final songId = track.songId?.toString() ?? track.id;
        final path = track.dataPath ?? '';

        return ContextTrack(
          uri: track.id,
          uid: 'local_uid_${songId}_$trackIndex',
          provider: 'context',
          isQueued: false,
          metadata: {
            'title': track.title.isNotEmpty ? track.title : 'Unknown Title',
            'artist_name': track.artist.isNotEmpty ? track.artist : 'Unknown Artist',
            'album_title': track.album ?? 'Unknown Album',
            'duration_ms': (track.duration ?? 0).toString(),
            'data_path': path,
            'dataPath': path,
            'songId': songId,
            if (track.artUri != null) 'image_url': track.artUri!,
            if (track.dateModified != null)
              'dateModified': track.dateModified!.millisecondsSinceEpoch.toString(),
            'is_queued': 'false',
            'page_url': '$contextUrl?page=$p',
            'next_page_url': p + 1 < totalPages ? '$contextUrl?page=${p + 1}' : '',
            'context_url': contextUrl,
            'page_index': p.toString(),
          },
        );
      }).toList();

      final pageUrl = '$contextUrl?page=$p';
      final hasNext = p + 1 < totalPages;
      final nextPageUrl = hasNext ? '$contextUrl?page=${p + 1}' : '';

      pages.add(
        ContextPage(
          pageUrl: pageUrl,
          nextPageUrl: nextPageUrl,
          tracks: contextTracks,
          metadata: {
            'page_index': p.toString(),
            'total_pages': totalPages.toString(),
          },
        ),
      );
    }

    final context = PlaybackContext(
      uri: contextUri,
      url: contextUrl,
      pages: pages,
    );
    registerContext(context);
    return context;
  }

  /// Builds initial [PlayerQueue] starting at [initialTrackIndex] with boundary delimiter.
  static PlayerQueue createInitialQueue({
    required PlaybackContext context,
    required int initialTrackIndex,
    int pageSize = defaultPageSize,
  }) {
    if (context.pages.isEmpty) {
      return const PlayerQueue(revision: '0');
    }

    final pageIndex = (initialTrackIndex / pageSize).floor().clamp(0, context.pages.length - 1);
    final activePage = context.pages[pageIndex];
    final activeTracks = activePage.tracks ?? const [];
    final offsetInPage = (initialTrackIndex - (pageIndex * pageSize)).clamp(
      0,
      activeTracks.isEmpty ? 0 : activeTracks.length - 1,
    );

    final currentTrack = activeTracks.isNotEmpty ? activeTracks[offsetInPage] : null;
    final upcomingInPage = activeTracks.isNotEmpty && offsetInPage + 1 < activeTracks.length
        ? activeTracks.sublist(offsetInPage + 1)
        : const <ContextTrack>[];

    return PlayerQueue(
      revision: '1',
      track: currentTrack,
      nextTracks: upcomingInPage,
      prevTracks: const [],
    );
  }

  /// Plays a list of [DomainTrack] entities using chunked Cosmos pagination.
  /// Resolves the active 50-track page for [initialTrackIndex], sets up delimiters,
  /// and feeds the active page items to [playback].
  static Future<void> playDomainTracks({
    required PlaybackController playback,
    required List<DomainTrack> tracks,
    required int initialTrackIndex,
    int pageSize = defaultPageSize,
  }) async {
    if (tracks.isEmpty || initialTrackIndex < 0 || initialTrackIndex >= tracks.length) {
      return;
    }

    final playbackContext = buildContextFromDomainTracks(
      tracks: tracks,
      pageSize: pageSize,
    );

    final pageIndex = (initialTrackIndex / pageSize).floor().clamp(0, playbackContext.pages.length - 1);
    final activePage = playbackContext.pages[pageIndex];
    final activeTracks = activePage.tracks ?? const <ContextTrack>[];
    final offsetInPage = (initialTrackIndex - (pageIndex * pageSize)).clamp(
      0,
      activeTracks.isEmpty ? 0 : activeTracks.length - 1,
    );

    final initialMediaItems = activeTracks.map((t) => t.toMediaItem()).toList(growable: false);
    await playback.playQueue(initialMediaItems, offsetInPage);
  }
}
