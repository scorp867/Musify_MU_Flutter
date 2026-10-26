library;

import '../models/playlist_entity.dart';
import '../models/sort_order.dart';

/// Domain contract for Spotify Playlist data, synchronization, and modifications.
abstract class PlaylistRepository {
  /// Reactive stream subscribing to updates for [playlistUri].
  Stream<PlaylistEntity> subscribe(
    String playlistUri, {
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  });

  /// Fetches current snapshot for [playlistUri].
  Future<PlaylistEntity> getPlaylist(
    String playlistUri, {
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  });

  /// Modifies playlist by adding or removing items.
  Future<void> modifyPlaylist({
    required String playlistUri,
    List<String> addUris = const [],
    List<String> removeUris = const [],
    int? insertPosition,
  });

  /// Toggles following/favoriting of a playlist.
  Future<void> setFollowed({
    required String playlistUri,
    required bool follow,
  });

  /// Initiates context playback for [playlistUri].
  Future<void> playPlaylist({
    required String playlistUri,
    String? skipToUri,
    bool shuffle = false,
  });
}
