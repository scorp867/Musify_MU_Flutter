library;

import 'dart:async' show unawaited;
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../../app/di/injection.dart';
import '../../features/player/data/esperanto/context_player_play_client.dart';
import '../../features/player/domain/commands/options/play_operation.dart';
import '../../features/player/domain/commands/options/play_options.dart';
import '../../features/player/domain/commands/options/play_trigger.dart';
import '../../features/player/domain/commands/options/prepare_play_options.dart';
import '../../features/player/domain/commands/options/skip_to_track.dart';
import '../../features/player/domain/commands/play_command.dart';
import '../../features/player/domain/models/context.dart';
import '../../features/player/domain/models/context_page.dart';
import '../../features/player/domain/models/context_track.dart';
import '../../features/player/domain/models/play_origin.dart';
import '../../features/player/domain/models/player_response.dart';
import '../../features/playlist/domain/repositories/playlist_repository.dart';
import '../../features/playlist/presentation/playlist_screen.dart';
import '../ubi/data/lifecycle/page_instance_id_holder.dart';
import '../ubi/domain/logging/ubi_logger.dart';
import '../ubi/domain/models/interaction_logging_result.dart';
import 'spotify_navigator.dart';
import 'spotify_uri_navigator.dart';

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
  bool openUri(BuildContext context, String uri, {ContextTrack? track}) {
    return navigateToUri(context, uri, track: track);
  }

  @override
  Future<bool> playUri(
    BuildContext context,
    String uri, {
    ContextTrack? track,
  }) {
    return dispatchPlayUri(
      context,
      uri,
      track: track,
      ubiLogger: _ubiLogger,
    );
  }

  @override
  bool navigateToUri(
    BuildContext context,
    String uri, {
    InteractionLoggingResult? interactionLoggingResult,
    Map<String, dynamic>? extras,
    ContextTrack? track,
  }) {
    return dispatchNavigateToUri(
      context,
      uri,
      interactionLoggingResult: interactionLoggingResult,
      extras: extras,
      track: track,
      ubiLogger: _ubiLogger,
    );
  }

  /// Dispatches a canonical `PlayCommand` via `ContextPlayerPlayClient` (`p.avy`)
  /// for standalone track or episode playback initiated outside the Queue Sheet.
  static Future<bool> _playStandaloneItem(
    String uri, {
    ContextTrack? track,
  }) async {
    if (!getIt.isRegistered<ContextPlayerPlayClient>()) {
      dev.log(
        '[PLAYBACK][CONNECT] ContextPlayerPlayClient not registered; cannot play standalone URI $uri',
        name: 'SpotifyNavigatorImpl',
      );
      return false;
    }
    final effectiveTrack = switch (track) {
      final t? => t.uri.isNotEmpty ? t : t.toBuilder().uri(uri).build(),
      null => ContextTrack.builder(uri).build(),
    };
    final page = ContextPage.builder()
        .tracks(<ContextTrack>[effectiveTrack])
        .build();
    final playbackContext = Context.fromUri(uri)
        .toBuilder()
        .pages(<ContextPage>[page])
        .build();
    final skipToBuilder = SkipToTrack.builder().trackUri(uri);
    if (effectiveTrack.uid.isNotEmpty) {
      skipToBuilder.trackUid(effectiveTrack.uid);
    }
    final options = PreparePlayOptions.builder()
        .skipTo(skipToBuilder.build())
        .initiallyPaused(false)
        .build();
    const playOptions = PlayOptions(
      operation: PlayOperation.replace,
      trigger: PlayTrigger.immediately,
    );
    final command = PlayCommand.builder(
      playbackContext,
      PlayOrigin.create('link_dispatcher'),
    ).options(options).playOptions(playOptions).build();

    final response = await getIt<ContextPlayerPlayClient>().play(command);
    switch (response) {
      case PlayerResponseSuccess():
        return true;
      case PlayerResponseFailure(:final reasons):
        dev.log(
          '[PLAYBACK][CONNECT] Standalone PlayCommand failed for $uri: $reasons',
          name: 'SpotifyNavigatorImpl',
        );
        return false;
    }
  }

  /// Single authoritative implementation for direct URI playback (tracks, episodes, playlists).
  static Future<bool> dispatchPlayUri(
    BuildContext context,
    String uri, {
    ContextTrack? track,
    UbiLogger? ubiLogger,
  }) async {
    if (uri.isEmpty) return false;

    if (uri.startsWith('spotify:track:') ||
        uri.startsWith('spotify:episode:')) {
      return _playStandaloneItem(uri, track: track);
    }

    if (SpotifyUriNavigator.isPlaylistUri(uri)) {
      if (getIt.isRegistered<PlaylistRepository>()) {
        try {
          await getIt<PlaylistRepository>().playPlaylist(playlistUri: uri);
          return true;
        } catch (e, stack) {
          dev.log(
            'Failed to play playlist URI $uri: $e',
            name: 'SpotifyNavigatorImpl',
            error: e,
            stackTrace: stack,
          );
        }
      }
    }

    if (!context.mounted) return false;
    return dispatchNavigateToUri(
      context,
      uri,
      track: track,
      ubiLogger: ubiLogger,
    );
  }

  /// Single authoritative implementation for URI navigation and link dispatching.
  static bool dispatchNavigateToUri(
    BuildContext context,
    String uri, {
    InteractionLoggingResult? interactionLoggingResult,
    Map<String, dynamic>? extras,
    ContextTrack? track,
    UbiLogger? ubiLogger,
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
      final effectiveLogger = switch (ubiLogger) {
        final logger? => logger,
        null => getIt.isRegistered<UbiLogger>() ? getIt<UbiLogger>() : null,
      };
      if (effectiveLogger != null) {
        try {
          effectiveLogger.logInteraction(
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
    }

    if (SpotifyUriNavigator.isPlaylistUri(uri)) {
      Navigator.of(context, rootNavigator: false).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistScreen(playlistUri: uri),
        ),
      );
      return true;
    }

    if (uri.startsWith('spotify:track:') ||
        uri.startsWith('spotify:episode:')) {
      if (getIt.isRegistered<ContextPlayerPlayClient>()) {
        unawaited(
          _playStandaloneItem(uri, track: track).then(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              dev.log(
                '[PLAYBACK][CONNECT] Standalone play threw for $uri: $error',
                name: 'SpotifyNavigatorImpl',
                error: error,
                stackTrace: stackTrace,
              );
            },
          ),
        );
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
