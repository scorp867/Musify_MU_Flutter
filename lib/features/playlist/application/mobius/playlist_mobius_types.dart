library;

import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';
import '../../domain/models/playlist_entity.dart';
import '../../domain/models/playlist_item.dart';
import '../../domain/models/playlist_screen_state.dart';
import '../../domain/models/sort_order.dart';

/// Sealed hierarchy of all user intents, system notifications, and player sync events.
@immutable
sealed class PlaylistEvent {
  const PlaylistEvent();
}

final class PlaylistLoadedEvent extends PlaylistEvent {
  final PlaylistEntity playlist;
  const PlaylistLoadedEvent(this.playlist);
}

final class PlaylistErrorEvent extends PlaylistEvent {
  final String message;
  const PlaylistErrorEvent(this.message);
}

final class PlaylistPlayTappedEvent extends PlaylistEvent {
  final String? trackUri;
  const PlaylistPlayTappedEvent({this.trackUri});
}

final class PlaylistShuffleTappedEvent extends PlaylistEvent {
  const PlaylistShuffleTappedEvent();
}

final class PlaylistFollowTappedEvent extends PlaylistEvent {
  const PlaylistFollowTappedEvent();
}

final class PlaylistDownloadTappedEvent extends PlaylistEvent {
  const PlaylistDownloadTappedEvent();
}

final class PlaylistSortChangedEvent extends PlaylistEvent {
  final ProvidedSortOrder sortOrder;
  const PlaylistSortChangedEvent(this.sortOrder);
}

final class PlaylistSearchChangedEvent extends PlaylistEvent {
  final String query;
  const PlaylistSearchChangedEvent(this.query);
}

final class PlaylistHeaderOffsetChangedEvent extends PlaylistEvent {
  final double alpha;
  const PlaylistHeaderOffsetChangedEvent(this.alpha);
}

final class PlaylistTrackPlaybackStateChangedEvent extends PlaylistEvent {
  final String? activeTrackUri;
  final bool isPlaying;
  final bool isShuffleEnabled;

  const PlaylistTrackPlaybackStateChangedEvent({
    this.activeTrackUri,
    this.isPlaying = false,
    this.isShuffleEnabled = false,
  });
}

final class PlaylistAddTracksEvent extends PlaylistEvent {
  final List<String> trackUris;
  const PlaylistAddTracksEvent(this.trackUris);
}

final class PlaylistRemoveTrackEvent extends PlaylistEvent {
  final String trackUri;
  const PlaylistRemoveTrackEvent(this.trackUri);
}

/// Sealed hierarchy of all side effects triggered by Mobius state transitions.
@immutable
sealed class PlaylistEffect {
  const PlaylistEffect();
}

final class SubscribePlaylistEffect extends PlaylistEffect {
  final String playlistUri;
  final ProvidedSortOrder sortOrder;
  const SubscribePlaylistEffect(this.playlistUri, this.sortOrder);
}

final class PlayContextEffect extends PlaylistEffect {
  final String playlistUri;
  final String? trackUri;
  final bool shuffle;
  const PlayContextEffect(this.playlistUri, {this.trackUri, this.shuffle = false});
}

final class ToggleShuffleEffect extends PlaylistEffect {
  final bool enable;
  const ToggleShuffleEffect(this.enable);
}

final class ToggleFollowEffect extends PlaylistEffect {
  final String playlistUri;
  final bool follow;
  const ToggleFollowEffect(this.playlistUri, this.follow);
}

final class ToggleDownloadEffect extends PlaylistEffect {
  final String playlistUri;
  final bool download;
  const ToggleDownloadEffect(this.playlistUri, this.download);
}

final class ModifyTracksEffect extends PlaylistEffect {
  final String playlistUri;
  final List<String> addUris;
  final List<String> removeUris;
  const ModifyTracksEffect(
    this.playlistUri, {
    this.addUris = const [],
    this.removeUris = const [],
  });
}

/// Pure state transition function: `(Model, Event) -> Next<Model, Effect>`.
Next<PlaylistScreenState, PlaylistEffect> playlistMobiusUpdate(
  PlaylistScreenState state,
  PlaylistEvent event,
) {
  switch (event) {
    case PlaylistLoadedEvent(:final playlist):
      final items = _filterItems(playlist.items, '');
      final currentSort = state is PlaylistLoadedState ? state.sortOrder : playlist.sortOrder;
      final currentAlpha = state is PlaylistLoadedState ? state.headerAlpha : 0.0;
      final activeTrack = state is PlaylistLoadedState ? state.activeTrackUri : null;
      final isPlaying = state is PlaylistLoadedState ? state.isPlaying : false;
      final isShuffle = state is PlaylistLoadedState ? state.isShuffleEnabled : false;

      return Next.next(
        PlaylistLoadedState(
          playlist: playlist,
          displayItems: items,
          sortOrder: currentSort,
          headerAlpha: currentAlpha,
          activeTrackUri: activeTrack,
          isPlaying: isPlaying,
          isShuffleEnabled: isShuffle,
        ),
      );

    case PlaylistErrorEvent(:final message):
      final uri = switch (state) {
        PlaylistLoadingState(:final playlistUri) => playlistUri,
        PlaylistLoadedState(:final playlist) => playlist.uri,
        PlaylistErrorState(:final playlistUri) => playlistUri,
      };
      return Next.next(PlaylistErrorState(playlistUri: uri, message: message));

    case PlaylistPlayTappedEvent(:final trackUri):
      if (state is PlaylistLoadedState) {
        return Next.dispatch({
          PlayContextEffect(
            state.playlist.uri,
            trackUri: trackUri,
            shuffle: state.isShuffleEnabled,
          ),
        });
      }
      return Next.noChange();

    case PlaylistShuffleTappedEvent():
      if (state is PlaylistLoadedState) {
        final nextShuffle = !state.isShuffleEnabled;
        return Next.next(
          state.copyWith(isShuffleEnabled: nextShuffle),
          {ToggleShuffleEffect(nextShuffle)},
        );
      }
      return Next.noChange();

    case PlaylistFollowTappedEvent():
      if (state is PlaylistLoadedState) {
        final nextFollow = !state.playlist.isFollowed;
        final updatedMeta = state.playlist.metadata.copyWith(isFollowed: nextFollow);
        final updatedPlaylist = state.playlist.copyWith(metadata: updatedMeta);
        return Next.next(
          state.copyWith(playlist: updatedPlaylist),
          {ToggleFollowEffect(state.playlist.uri, nextFollow)},
        );
      }
      return Next.noChange();

    case PlaylistDownloadTappedEvent():
      if (state is PlaylistLoadedState) {
        final nextDownload = !state.playlist.isDownloaded;
        final updatedPlaylist = state.playlist.copyWith(isDownloaded: nextDownload);
        return Next.next(
          state.copyWith(playlist: updatedPlaylist),
          {ToggleDownloadEffect(state.playlist.uri, nextDownload)},
        );
      }
      return Next.noChange();

    case PlaylistSortChangedEvent(:final sortOrder):
      if (state is PlaylistLoadedState) {
        return Next.next(
          state.copyWith(sortOrder: sortOrder),
          {SubscribePlaylistEffect(state.playlist.uri, sortOrder)},
        );
      }
      return Next.noChange();

    case PlaylistSearchChangedEvent(:final query):
      if (state is PlaylistLoadedState) {
        final filtered = _filterItems(state.playlist.items, query);
        return Next.next(
          state.copyWith(searchQuery: query, displayItems: filtered),
        );
      }
      return Next.noChange();

    case PlaylistHeaderOffsetChangedEvent(:final alpha):
      if (state is PlaylistLoadedState) {
        return Next.next(state.copyWith(headerAlpha: alpha));
      }
      return Next.noChange();

    case PlaylistTrackPlaybackStateChangedEvent(
        :final activeTrackUri,
        :final isPlaying,
        :final isShuffleEnabled,
      ):
      if (state is PlaylistLoadedState) {
        return Next.next(
          state.copyWith(
            activeTrackUri: activeTrackUri,
            isPlaying: isPlaying,
            isShuffleEnabled: isShuffleEnabled,
          ),
        );
      }
      return Next.noChange();

    case PlaylistAddTracksEvent(:final trackUris):
      if (state is PlaylistLoadedState) {
        return Next.dispatch({
          ModifyTracksEffect(state.playlist.uri, addUris: trackUris),
        });
      }
      return Next.noChange();

    case PlaylistRemoveTrackEvent(:final trackUri):
      if (state is PlaylistLoadedState) {
        return Next.dispatch({
          ModifyTracksEffect(state.playlist.uri, removeUris: [trackUri]),
        });
      }
      return Next.noChange();
  }
}

List<PlaylistItem> _filterItems(List<PlaylistItem> items, String query) {
  if (query.isEmpty) return items;
  final lower = query.toLowerCase();
  return items.where((item) {
    return item.title.toLowerCase().contains(lower) ||
        item.subtitle.toLowerCase().contains(lower) ||
        item.albumName.toLowerCase().contains(lower);
  }).toList();
}
