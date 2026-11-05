library;

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../../app/di/injection.dart';
import '../../features/player/application/queue/player_queue_bloc.dart';
import '../../features/player/domain/models/context_track.dart';
import '../../features/player/domain/models/play_origin.dart';
import '../ubi/data/lifecycle/page_instance_id_holder.dart';
import '../ubi/domain/logging/ubi_logger.dart';
import '../ubi/domain/models/interaction_logging_result.dart';
import 'spotify_navigator.dart';
import 'spotify_uri_navigator.dart';
import '../../features/playlist/presentation/playlist_screen.dart';

/// 1:1 replica of Spotify Android `p199p.akl0` (NavigatorImpl).
/// Encapsulates routing resolution and coordinates with the UBI instrumentation subsystem.
class SpotifyNavigatorImpl implements SpotifyNavigator {
  final UbiLogger _ubiLogger;
  final PageInstanceIdHolder _pageInstanceIdHolder;

  static int _lastNavigateTimeMs = 0;
  static String _lastNavigateUri = '';

  SpotifyNavigatorImpl({
    required UbiLogger ubiLogger,
    required PageInstanceIdHolder pageInstanceIdHolder,
  })  : _ubiLogger = ubiLogger,
        _pageInstanceIdHolder = pageInstanceIdHolder;

  @override
  PageInstanceIdHolder get pageInstanceIdHolder => _pageInstanceIdHolder;

  @override
  bool openUri(BuildContext context, String uri) {
    return navigateToUri(context, uri);
  }

  @override
  Future<bool> playUri(BuildContext context, String uri, {ContextTrack? track}) {
    return SpotifyUriNavigator.playUri(context, uri, track: track);
  }

  @override
  bool navigateToUri(
    BuildContext context,
    String uri, {
    InteractionLoggingResult? interactionLoggingResult,
    Map<String, dynamic>? extras,
  }) {
    if (uri.isEmpty) return false;

    // 1:1 Spotify Tap Debouncing (prevents multi-touch double-pushing)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastNavigateUri == uri && (now - _lastNavigateTimeMs) < 600) {
      return false;
    }
    _lastNavigateTimeMs = now;
    _lastNavigateUri = uri;

    // 1:1 Spotify akl0.mo27228a: If an interaction logging result is not explicitly
    // passed, generate an interaction log on the 'link_dispatcher' leaf.
    if (interactionLoggingResult == null) {
      try {
        _ubiLogger.logInteraction(
          UbiInteractionElement(
            elementPath: 'link_dispatcher',
            uri: uri,
            actionName: 'navigate',
          ),
        );
      } catch (e, stack) {
        dev.log(
          'Failed to log interaction for $uri: $e',
          name: 'SpotifyNavigatorImpl',
          error: e,
          stackTrace: stack,
        );
      }
    }

    if (SpotifyUriNavigator.isPlaylistUri(uri)) {
      Navigator.of(context, rootNavigator: false).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistScreen(playlistUri: uri),
        ),
      );
      return true;
    }

    if (uri.startsWith('spotify:track:') || uri.startsWith('spotify:episode:')) {
      if (getIt.isRegistered<PlayerQueueBloc>()) {
        final track = ContextTrack.builder(uri).build();
        final origin = PlayOrigin.builder('navigator')
            .viewUri(uri)
            .referrerIdentifier('navigator')
            .build();
        getIt<PlayerQueueBloc>().add(PlayTrack(track, playOrigin: origin));
        return true;
      }
    }

    return false;
  }

  @override
  bool goBack(BuildContext context) {
    try {
      _ubiLogger.logInteraction(
        const UbiInteractionElement(
          elementPath: 'navigation_bar/back_button',
          actionName: 'navigate_back',
        ),
      );
    } catch (e, stack) {
      dev.log(
        'Failed to log back navigation: $e',
        name: 'SpotifyNavigatorImpl',
        error: e,
        stackTrace: stack,
      );
    }
    Navigator.of(context).maybePop();
    return true;
  }
}
