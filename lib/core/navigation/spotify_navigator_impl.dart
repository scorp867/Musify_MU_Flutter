library;

import 'package:flutter/material.dart';
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
      } catch (_) {}
    }

    if (SpotifyUriNavigator.isPlaylistUri(uri)) {
      Navigator.of(context, rootNavigator: false).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistScreen(playlistUri: uri),
        ),
      );
      return true;
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
    } catch (_) {}
    Navigator.of(context).maybePop();
    return true;
  }
}
