library;

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/navigation/spotify_navigator.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:musify_mu/features/playlist/presentation/playlist_screen.dart';

/// Centralized Spotify URI navigation router.
/// Replicates Spotify Android's internal `LinkDispatcher` / `NavigationManager` pattern.
///
/// 1:1 replica of decompiled Spotify Android classes:
/// - `p199p/d8l1.java#m37036x`: Canonical Liked Songs / Collection URI validator
/// - `p199p/veb0.java#mo57935a`: Entity page route dispatcher
/// - `p199p/gtb0.java#mo27594a`: List entity route binder for `qcb0.COLLECTION_TRACKS`
/// - `p199p/vgm0.java`: Spotify Navigator contract
class SpotifyUriNavigator {
  const SpotifyUriNavigator._();

  /// 1:1 replica of Spotify Android `d8l1.m37036x`.
  /// Checks whether a URI corresponds to the Liked Songs / Collection tracks entity.
  static bool isLikedSongsUri(String uri) {
    if (uri == 'spotify:playlist:37i9dQZF1F5p3rmiWPIYgZ' ||
        uri == 'spotify:collection:tracks' ||
        uri == 'spotify:internal:collection:tracks') {
      return true;
    }
    if (uri.startsWith('spotify:user:') && uri.endsWith(':collection')) {
      return true;
    }
    return false;
  }

  /// Checks whether a URI corresponds to a Spotify playlist entity or list entity.
  /// 1:1 replica of Spotify Android `veb0.mo57935a` and `gtb0.mo27594a`.
  static bool isPlaylistUri(String uri) {
    if (isLikedSongsUri(uri)) {
      return true;
    }
    if (uri.startsWith('spotify:playlist:')) {
      return true;
    }
    if (uri.startsWith('spotify:user:') && uri.contains(':playlist:')) {
      return true;
    }
    final parsed = Uri.tryParse(uri);
    if (parsed != null && parsed.pathSegments.contains('playlist')) {
      return true;
    }
    return false;
  }

  static int _lastNavigateTimeMs = 0;
  static String _lastNavigateUri = '';

  /// Opens a Spotify URI within the active nested navigation stack.
  /// Uses [rootNavigator: false] so the screen renders inside the current tab stack,
  /// extending behind the persistent MiniPlayer and bottom navigation bar.
  ///
  /// Returns `true` if the URI was handled by a known route, or `false` otherwise.
  static bool openUri(BuildContext context, String uri, {ContextTrack? track}) {
    if (getIt.isRegistered<SpotifyNavigator>()) {
      return getIt<SpotifyNavigator>().openUri(context, uri);
    }

    if (uri.isEmpty) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastNavigateUri == uri && (now - _lastNavigateTimeMs) < 600) {
      return false;
    }
    _lastNavigateTimeMs = now;
    _lastNavigateUri = uri;

    if (isPlaylistUri(uri)) {
      try {
        if (getIt.isRegistered<UbiLogger>()) {
          final ubiLogger = getIt<UbiLogger>();
          ubiLogger.logInteraction(
            UbiInteractionElement(
              elementPath: 'link_dispatcher',
              uri: uri,
              actionName: 'navigate',
            ),
          );
        }
      } catch (e, stack) {
        dev.log(
          'Failed to log navigation interaction for $uri: $e',
          name: 'SpotifyUriNavigator',
          error: e,
          stackTrace: stack,
        );
      }

      Navigator.of(context, rootNavigator: false).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistScreen(playlistUri: uri),
        ),
      );
      return true;
    }

    if (uri.startsWith('spotify:track:') || uri.startsWith('spotify:episode:')) {
      if (getIt.isRegistered<PlayerQueueMobiusController>()) {
        final effectiveTrack = switch (track) {
          final t? => t,
          null => ContextTrack.builder(uri).build(),
        };
        getIt<PlayerQueueMobiusController>().dispatch(TrackTappedEvent(effectiveTrack));
        return true;
      }
    }

    // Other entity types (artists, albums, episodes) are reserved for future screens.
    return false;
  }

  /// Directly plays an entity URI (track, episode, or playlist) without navigating away.
  static Future<bool> playUri(BuildContext context, String uri, {ContextTrack? track}) async {
    if (getIt.isRegistered<SpotifyNavigator>()) {
      return getIt<SpotifyNavigator>().playUri(context, uri, track: track);
    }

    if (uri.isEmpty) return false;

    if (uri.startsWith('spotify:track:') || uri.startsWith('spotify:episode:')) {
      if (getIt.isRegistered<PlayerQueueMobiusController>()) {
        final effectiveTrack = switch (track) {
          final t? => t,
          null => ContextTrack.builder(uri).build(),
        };
        getIt<PlayerQueueMobiusController>().dispatch(TrackTappedEvent(effectiveTrack));
        return true;
      }
    }

    if (isPlaylistUri(uri)) {
      if (getIt.isRegistered<PlaylistRepository>()) {
        try {
          await getIt<PlaylistRepository>().playPlaylist(playlistUri: uri);
          return true;
        } catch (e, stack) {
          dev.log(
            'Failed to play playlist URI $uri: $e',
            name: 'SpotifyUriNavigator',
            error: e,
            stackTrace: stack,
          );
        }
      }
    }

    if (!context.mounted) return false;
    return openUri(context, uri, track: track);
  }
}
