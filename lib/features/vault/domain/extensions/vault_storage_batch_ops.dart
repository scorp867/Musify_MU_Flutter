import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

/// Non-breaking batch and synchronous-cache extensions for [IVaultStorageRepository].
///
/// Uses [VaultStorageRepository]'s single-transaction batch encryption/SQLite
/// operations when backed by the concrete repository, and gracefully degrades
/// to sequential interface calls for unit test fakes.
extension VaultStorageBatchOps on IVaultStorageRepository {
  /// Inserts [trackRefs] into [playlistId] using a single batch crypto/SQLite
  /// transaction when supported by the backing repository.
  Future<VaultResult<void>> addTracksToPlaylist({
    required String playlistId,
    required List<PrivateTrackRef> trackRefs,
  }) async {
    if (this case final VaultStorageRepository concrete) {
      return concrete.addTracksToPlaylist(
        playlistId: playlistId,
        trackRefs: trackRefs,
      );
    }

    for (final trackRef in trackRefs) {
      final result = await addTrackToPlaylist(
        playlistId: playlistId,
        trackRef: trackRef,
      );
      if (result is VaultFailureResult<void>) {
        return result;
      }
    }
    return const VaultSuccess<void>(null);
  }

  /// Returns the currently unlocked in-memory cached playlist for [playlistId],
  /// or `null` when unavailable or backed by a stateless test double.
  PrivatePlaylist? getCachedPlaylistSync(String playlistId) {
    if (this case final VaultStorageRepository concrete) {
      return concrete.getCachedPlaylistSync(playlistId);
    }
    return null;
  }

  /// Returns the currently unlocked in-memory cached playlists list,
  /// or `null` when unavailable or backed by a stateless test double.
  List<PrivatePlaylist>? getCachedPlaylistsSync() {
    if (this case final VaultStorageRepository concrete) {
      return concrete.getCachedPlaylistsSync();
    }
    return null;
  }
}
