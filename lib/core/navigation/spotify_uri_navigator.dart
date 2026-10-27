library;

import 'package:flutter/material.dart';
import 'package:musify_mu/features/playlist/presentation/playlist_screen.dart';

/// Centralized Spotify URI navigation router.
/// Replicates Spotify Android's internal `LinkDispatcher` / `NavigationManager` pattern.
///
/// Dispatches supported URIs (`spotify:playlist:*`) to dedicated screen coordinators
/// while preserving future extensible slots for albums, artists, and shows.
class SpotifyUriNavigator {
  const SpotifyUriNavigator._();

  /// Checks whether a URI corresponds to a Spotify playlist entity.
  static bool isPlaylistUri(String uri) {
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

  /// Opens a Spotify URI within the active nested navigation stack.
  /// Uses [rootNavigator: false] so the screen renders inside the current tab stack,
  /// extending behind the persistent MiniPlayer and bottom navigation bar.
  ///
  /// Returns `true` if the URI was handled by a known route, or `false` otherwise.
  static bool openUri(BuildContext context, String uri) {
    if (uri.isEmpty) return false;

    if (isPlaylistUri(uri)) {
      Navigator.of(context, rootNavigator: false).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistScreen(playlistUri: uri),
        ),
      );
      return true;
    }

    // Other entity types (artists, albums, episodes) are reserved for future screens.
    return false;
  }
}
