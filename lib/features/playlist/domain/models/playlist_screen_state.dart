library;

import 'package:flutter/foundation.dart';
import 'playlist_entity.dart';
import 'playlist_item.dart';
import 'sort_order.dart';

/// Exhaustive sealed state hierarchy for the Playlist Screen.
/// 1:1 behavioral representation of Spotify's `h1q.java` screen state.
@immutable
sealed class PlaylistScreenState {
  const PlaylistScreenState();
}

/// Loading state while fetching initial playlist metadata and items.
final class PlaylistLoadingState extends PlaylistScreenState {
  final String playlistUri;

  const PlaylistLoadingState({required this.playlistUri});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistLoadingState &&
          runtimeType == other.runtimeType &&
          playlistUri == other.playlistUri);

  @override
  int get hashCode => playlistUri.hashCode;

  @override
  String toString() => 'PlaylistLoadingState(uri: $playlistUri)';
}

/// Error state when fetching or modifying the playlist fails.
final class PlaylistErrorState extends PlaylistScreenState {
  final String playlistUri;
  final String message;

  const PlaylistErrorState({
    required this.playlistUri,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistErrorState &&
          runtimeType == other.runtimeType &&
          playlistUri == other.playlistUri &&
          message == other.message);

  @override
  int get hashCode => Object.hash(playlistUri, message);

  @override
  String toString() => 'PlaylistErrorState(uri: $playlistUri, message: $message)';
}

/// Active loaded state containing the full playlist model, sectioned items,
/// search filters, and active playback status.
final class PlaylistLoadedState extends PlaylistScreenState {
  final PlaylistEntity playlist;
  final List<PlaylistItem> displayItems;
  final String? activeTrackUri;
  final bool isPlaying;
  final bool isShuffleEnabled;
  final String searchQuery;
  final ProvidedSortOrder sortOrder;
  final double headerAlpha;

  const PlaylistLoadedState({
    required this.playlist,
    required this.displayItems,
    this.activeTrackUri,
    this.isPlaying = false,
    this.isShuffleEnabled = false,
    this.searchQuery = '',
    required this.sortOrder,
    this.headerAlpha = 0.0,
  });

  bool get isEmpty => playlist.items.isEmpty;

  PlaylistLoadedState copyWith({
    PlaylistEntity? playlist,
    List<PlaylistItem>? displayItems,
    String? activeTrackUri,
    bool? isPlaying,
    bool? isShuffleEnabled,
    String? searchQuery,
    ProvidedSortOrder? sortOrder,
    double? headerAlpha,
  }) {
    return PlaylistLoadedState(
      playlist: playlist ?? this.playlist,
      displayItems: displayItems ?? this.displayItems,
      activeTrackUri: activeTrackUri ?? this.activeTrackUri,
      isPlaying: isPlaying ?? this.isPlaying,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
      headerAlpha: headerAlpha ?? this.headerAlpha,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistLoadedState &&
          runtimeType == other.runtimeType &&
          playlist == other.playlist &&
          listEquals(displayItems, other.displayItems) &&
          activeTrackUri == other.activeTrackUri &&
          isPlaying == other.isPlaying &&
          isShuffleEnabled == other.isShuffleEnabled &&
          searchQuery == other.searchQuery &&
          sortOrder == other.sortOrder &&
          headerAlpha == other.headerAlpha);

  @override
  int get hashCode => Object.hash(
        playlist,
        Object.hashAll(displayItems),
        activeTrackUri,
        isPlaying,
        isShuffleEnabled,
        searchQuery,
        sortOrder,
        headerAlpha,
      );

  @override
  String toString() =>
      'PlaylistLoadedState(name: ${playlist.name}, items: ${displayItems.length}, isPlaying: $isPlaying, sort: $sortOrder)';
}
