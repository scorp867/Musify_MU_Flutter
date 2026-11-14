library;

import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/navigation/spotify_navigator.dart';
import 'package:musify_mu/core/navigation/spotify_navigator_impl.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

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

  /// Opens a Spotify URI within the active nested navigation stack.
  /// Uses [rootNavigator: false] so the screen renders inside the current tab stack,
  /// extending behind the persistent MiniPlayer and bottom navigation bar.
  ///
  /// Returns `true` if the URI was handled by a known route, or `false` otherwise.
  static bool openUri(BuildContext context, String uri, {ContextTrack? track}) {
    if (getIt.isRegistered<SpotifyNavigator>()) {
      return getIt<SpotifyNavigator>().openUri(context, uri, track: track);
    }
    return SpotifyNavigatorImpl.dispatchNavigateToUri(
      context,
      uri,
      track: track,
    );
  }

  /// Directly plays an entity URI (track, episode, or playlist) without navigating away.
  static Future<bool> playUri(
    BuildContext context,
    String uri, {
    ContextTrack? track,
  }) {
    if (getIt.isRegistered<SpotifyNavigator>()) {
      return getIt<SpotifyNavigator>().playUri(context, uri, track: track);
    }
    return SpotifyNavigatorImpl.dispatchPlayUri(
      context,
      uri,
      track: track,
    );
  }
}
