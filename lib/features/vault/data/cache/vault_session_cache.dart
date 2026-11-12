import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';

/// Lock-cleared in-memory session cache for decrypted Secure Vault data.
///
/// Stores immutable decrypted [PrivatePlaylist] snapshots and sandbox track path
/// resolutions strictly while a vault session is unlocked. Every lock, background
/// grace expiration, purge, or step-up denial invokes [clear], advancing
/// [generation] so in-flight background reads started before lock cannot repopulate RAM.
final class VaultSessionCache {
  final Map<String, PrivatePlaylist> _playlistsById = <String, PrivatePlaylist>{};
  final List<String> _orderedPlaylistIds = <String>[];
  final Map<String, String> _sandboxFilePathsByTrackId = <String, String>{};

  bool _hasAllPlaylistsSnapshot = false;
  int _generation = 0;

  /// Monotonic generation token incremented whenever the cache is cleared.
  int get generation => _generation;

  /// Number of playlists currently retained in unlocked RAM.
  @visibleForTesting
  int get cachedPlaylistCount => _playlistsById.length;

  /// Whether [getPlaylists] has populated a full ordered snapshot for this unlock session.
  @visibleForTesting
  bool get hasAllPlaylistsSnapshot => _hasAllPlaylistsSnapshot;

  /// Returns the cached full ordered playlist list when available, or `null` on miss.
  List<PrivatePlaylist>? getAllPlaylistsSnapshot() {
    if (!_hasAllPlaylistsSnapshot) {
      return null;
    }
    final List<PrivatePlaylist> ordered = <PrivatePlaylist>[];
    for (final id in _orderedPlaylistIds) {
      final playlist = _playlistsById[id];
      if (playlist == null) {
        return null;
      }
      ordered.add(playlist);
    }
    return UnmodifiableListView<PrivatePlaylist>(ordered);
  }

  /// Returns a cached [PrivatePlaylist] by [playlistId], or `null` on miss.
  PrivatePlaylist? getPlaylist(String playlistId) => _playlistsById[playlistId];

  /// Returns a cached isolated sandbox file path for [trackId], or `null`.
  String? getSandboxFilePath(String trackId) =>
      _sandboxFilePathsByTrackId[trackId];

  /// Records verified sandbox file paths in RAM if [expectedGeneration] matches.
  void putSandboxFilePathsIfGeneration(
    int expectedGeneration,
    Map<String, String> pathsByTrackId,
  ) {
    if (_generation != expectedGeneration || pathsByTrackId.isEmpty) {
      return;
    }
    _sandboxFilePathsByTrackId.addAll(pathsByTrackId);
  }

  /// Stores the complete ordered [playlists] snapshot if [expectedGeneration] is current.
  void putAllPlaylistsIfGeneration(
    int expectedGeneration,
    List<PrivatePlaylist> playlists,
  ) {
    if (_generation != expectedGeneration) {
      return;
    }
    _playlistsById.clear();
    _orderedPlaylistIds.clear();
    for (final playlist in playlists) {
      _playlistsById[playlist.id] = playlist;
      _orderedPlaylistIds.add(playlist.id);
    }
    _hasAllPlaylistsSnapshot = true;
  }

  /// Stores or refreshes a single [playlist] entry if [expectedGeneration] is current.
  void putPlaylistIfGeneration(
    int expectedGeneration,
    PrivatePlaylist playlist,
  ) {
    if (_generation != expectedGeneration) {
      return;
    }
    _playlistsById[playlist.id] = playlist;
    if (_hasAllPlaylistsSnapshot && !_orderedPlaylistIds.contains(playlist.id)) {
      _orderedPlaylistIds.insert(0, playlist.id);
    }
  }

  /// Inserts a newly created [playlist] into the unlocked cache without flushing sibling entries.
  void recordPlaylistCreated(int expectedGeneration, PrivatePlaylist playlist) {
    if (_generation != expectedGeneration) {
      return;
    }
    _playlistsById[playlist.id] = playlist;
    if (_hasAllPlaylistsSnapshot && !_orderedPlaylistIds.contains(playlist.id)) {
      _orderedPlaylistIds.insert(0, playlist.id);
    }
  }

  /// Updates an existing playlist in cache while preserving its tracks if unchanged.
  void recordPlaylistUpdated(int expectedGeneration, PrivatePlaylist playlist) {
    if (_generation != expectedGeneration) {
      return;
    }
    _playlistsById[playlist.id] = playlist;
  }

  /// Removes a deleted playlist and its sandbox path entries from RAM cache.
  void recordPlaylistDeleted(String playlistId) {
    final removed = _playlistsById.remove(playlistId);
    _orderedPlaylistIds.remove(playlistId);
    if (removed != null) {
      for (final track in removed.trackRefs) {
        _sandboxFilePathsByTrackId.remove(track.id);
      }
    }
  }

  /// Appends [addedTracks] to an already-cached playlist snapshot, keeping it warm.
  void recordTracksAdded({
    required int expectedGeneration,
    required String playlistId,
    required List<PrivateTrackRef> addedTracks,
    required int updatedAtEpochMs,
  }) {
    if (_generation != expectedGeneration || addedTracks.isEmpty) {
      return;
    }
    final existing = _playlistsById[playlistId];
    if (existing == null) {
      return;
    }
    final updatedTracks = <PrivateTrackRef>[
      ...existing.trackRefs,
      ...addedTracks,
    ];
    final addedDuration = addedTracks.fold<int>(
      0,
      (sum, track) => sum + track.durationMs,
    );
    _playlistsById[playlistId] = existing.copyWith(
      trackRefs: updatedTracks,
      totalDurationMs: existing.totalDurationMs + addedDuration,
      updatedAtEpochMs: updatedAtEpochMs,
    );
  }

  /// Removes [trackId] from an already-cached playlist and re-indexes sort order.
  void recordTrackRemoved({
    required String playlistId,
    required String trackId,
    required int updatedAtEpochMs,
  }) {
    _sandboxFilePathsByTrackId.remove(trackId);
    final existing = _playlistsById[playlistId];
    if (existing == null) {
      return;
    }
    final remaining = <PrivateTrackRef>[];
    int totalDuration = 0;
    for (final track in existing.trackRefs) {
      if (track.id == trackId) {
        continue;
      }
      final nextIndex = remaining.length;
      remaining.add(track.copyWith(sortOrder: nextIndex));
      totalDuration += track.durationMs;
    }
    _playlistsById[playlistId] = existing.copyWith(
      trackRefs: remaining,
      totalDurationMs: totalDuration,
      updatedAtEpochMs: updatedAtEpochMs,
    );
  }

  /// Reorders an already-cached playlist in-place matching [trackIdsInOrder].
  void recordTracksReordered({
    required String playlistId,
    required List<String> trackIdsInOrder,
    required int updatedAtEpochMs,
  }) {
    final existing = _playlistsById[playlistId];
    if (existing == null) {
      return;
    }
    final byId = <String, PrivateTrackRef>{
      for (final track in existing.trackRefs) track.id: track,
    };
    final reordered = <PrivateTrackRef>[];
    final seen = <String>{};
    for (final id in trackIdsInOrder) {
      final track = byId[id];
      if (track != null && seen.add(id)) {
        reordered.add(track.copyWith(sortOrder: reordered.length));
      }
    }
    for (final track in existing.trackRefs) {
      if (seen.add(track.id)) {
        reordered.add(track.copyWith(sortOrder: reordered.length));
      }
    }
    _playlistsById[playlistId] = existing.copyWith(
      trackRefs: reordered,
      updatedAtEpochMs: updatedAtEpochMs,
    );
  }

  /// Synchronously evicts all decrypted vault metadata from RAM and invalidates in-flight fills.
  void clear() {
    _generation++;
    _playlistsById.clear();
    _orderedPlaylistIds.clear();
    _sandboxFilePathsByTrackId.clear();
    _hasAllPlaylistsSnapshot = false;
  }
}
