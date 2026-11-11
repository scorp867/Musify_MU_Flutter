import 'dart:async';

import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

/// Pure abstract interface defining the encrypted persistence repository for the Secure Vault.
///
/// Encapsulates all encrypted CRUD operations for vault configuration, private playlists,
/// track references, golden gesture templates, and persistent brute-force lockout deadlines.
abstract interface class IVaultStorageRepository {
  /// Checks whether a vault has ever been enrolled on this device without requiring
  /// master key unwrapping or ciphertext decryption.
  Future<bool> hasEnrolledVault();

  /// Loads the persisted [VaultConfig] containing active policies and decoy persona values.
  ///
  /// Returns [VaultSuccess] with loaded config or [VaultFailureResult] on storage/decryption error.
  Future<VaultResult<VaultConfig>> loadVaultConfig();

  /// Persists updated [VaultConfig] to encrypted storage.
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config);

  /// Retrieves all encrypted private playlists stored in the vault.
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists();

  /// Retrieves a single private playlist matching [id].
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id);

  /// Creates and persists a new private playlist with the provided [name], [description],
  /// and optional [coverUri].
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  });

  /// Updates an existing [playlist] record in encrypted storage.
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist);

  /// Permanently deletes the private playlist identified by [playlistId].
  Future<VaultResult<void>> deletePlaylist(String playlistId);

  /// Appends or attaches [trackRef] to the private playlist identified by [playlistId].
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  });

  /// Removes the track identified by [trackId] from the playlist identified by [playlistId].
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  /// Reorders tracks within a private playlist according to the sequence specified
  /// in [trackIdsInOrder].
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  });

  /// Loads the golden master [GestureTemplate].
  Future<VaultResult<GestureTemplate>> loadGestureTemplate();

  /// Encrypts and persists the golden master [GestureTemplate].
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template);

  /// Atomically purges all encrypted vault databases, track references, isolated media,
  /// and persistent lockout timestamps, restoring the system to an unprovisioned state.
  Future<VaultResult<void>> purgeAllVaultData();

  /// Retrieves the persisted monotonic lockout deadline timestamp in milliseconds,
  /// or `null` if no active lockout deadline is persisted.
  Future<int?> getPersistedLockoutDeadlineMs();

  /// Persists the active monotonic lockout deadline [deadlineMonotonicMs] to endure
  /// app restarts and process kills.
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs);

  /// Clears any persisted lockout deadline upon successful cooldown completion or reset.
  Future<void> clearPersistedLockoutDeadline();
}
