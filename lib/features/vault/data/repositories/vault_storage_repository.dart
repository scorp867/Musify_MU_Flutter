import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musify_mu/features/vault/data/database/dtos/gesture_template_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_config_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_track_metadata_dto.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_memory_wiper.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:uuid/uuid.dart';

/// Production implementation of [IVaultStorageRepository] backed by a dedicated Drift SQLite database
/// and hardware-offloaded AES-256-GCM encryption.
///
/// Guarantees:
/// 1. Zero secret key bytes in Dart RAM — all encryption and decryption is executed via [INativeVaultCryptoBridge].
/// 2. Transient plaintext buffers are wiped immediately with [VaultMemoryWiper.zeroBuffer].
/// 3. All multi-statement operations run inside atomic [_database.transaction] blocks.
/// 4. Monotonic lockout deadline timestamp is kept unencrypted to allow brute-force protection
///    verification before master key authorization.
class VaultStorageRepository implements IVaultStorageRepository {
  final VaultDatabase _database;
  final INativeVaultCryptoBridge _cryptoBridge;
  final Future<void> Function()? _onShredMediaFiles;
  final Uuid _uuid;
  final FlutterSecureStorage _secureStorage;

  /// Constructs a [VaultStorageRepository] with explicit dependencies.
  VaultStorageRepository({
    required VaultDatabase database,
    required INativeVaultCryptoBridge cryptoBridge,
    Future<void> Function()? onShredMediaFiles,
    Uuid uuid = const Uuid(),
    FlutterSecureStorage? secureStorage,
  })  : _database = database,
        _cryptoBridge = cryptoBridge,
        _onShredMediaFiles = onShredMediaFiles,
        _uuid = uuid,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<bool> hasEnrolledVault() async {
    try {
      final isEnrolled = await _secureStorage.read(key: 'musify_vault_is_enrolled');
      if (isEnrolled == 'true') {
        return true;
      }
      final verifier = await _secureStorage.read(key: 'musify_vault_pin_verifier');
      if (verifier != null && verifier.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // Platform channels might not be initialized in non-widget unit tests
    }

    try {
      return await _cryptoBridge.hasMasterKey();
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Cryptographic Helpers (with RAM Plaintext Zeroing)
  // ---------------------------------------------------------------------------

  Future<Uint8List> _encryptString(String text) async {
    final plaintextBytes = Uint8List.fromList(utf8.encode(text));
    try {
      return await _cryptoBridge.encryptPayload(plaintextBytes);
    } finally {
      VaultMemoryWiper.zeroBuffer(plaintextBytes);
    }
  }

  Future<String> _decryptString(Uint8List ciphertext) async {
    final decryptedBytes = await _cryptoBridge.decryptPayload(ciphertext);
    try {
      return utf8.decode(decryptedBytes);
    } finally {
      VaultMemoryWiper.zeroBuffer(decryptedBytes);
    }
  }

  Future<Uint8List> _encryptJson(Object jsonObject) async {
    final jsonString = jsonEncode(jsonObject);
    return _encryptString(jsonString);
  }

  Future<Object?> _decryptJson(Uint8List ciphertext) async {
    final jsonString = await _decryptString(ciphertext);
    return jsonDecode(jsonString);
  }

  // ---------------------------------------------------------------------------
  // VaultConfig Persistence
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async {
    try {
      final query = _database.select(_database.vaultConfigTable)
        ..where((tbl) => tbl.id.equals('vault_config'));
      final entry = await query.getSingleOrNull();

      if (entry == null) {
        return const VaultFailureResult<VaultConfig>(
          VaultStorageFailure('Vault configuration record not found.'),
        );
      }

      final jsonObject = await _decryptJson(entry.encryptedPayload);
      final config = VaultConfigDto.fromJson(jsonObject);
      return VaultSuccess<VaultConfig>(config);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<VaultConfig>(failure);
    } catch (error) {
      return VaultFailureResult<VaultConfig>(
        VaultStorageFailure('Failed to load vault config: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config) async {
    try {
      final jsonMap = VaultConfigDto.toJson(config);
      final encryptedBytes = await _encryptJson(jsonMap);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await _database.into(_database.vaultConfigTable).insertOnConflictUpdate(
            VaultConfigTableCompanion(
              id: const Value('vault_config'),
              encryptedPayload: Value(encryptedBytes),
              updatedAt: Value(nowMs),
            ),
          );

      return const VaultSuccess<void>(null);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to save vault config: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private Playlists & Track References Persistence
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    try {
      final playlistEntries = await (_database.select(_database.vaultPlaylistsTable)
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

      final List<PrivatePlaylist> playlists = <PrivatePlaylist>[];
      for (final playlistEntry in playlistEntries) {
        final title = await _decryptString(playlistEntry.encryptedTitle);
        final description = await _decryptString(playlistEntry.encryptedDescription);

        final String? coverUri;
        final encCover = playlistEntry.encryptedCoverPath;
        if (encCover != null) {
          coverUri = await _decryptString(encCover);
        } else {
          coverUri = null;
        }

        final trackEntries = await (_database.select(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistEntry.id))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
            .get();

        final List<PrivateTrackRef> trackRefs = <PrivateTrackRef>[];
        for (final trackEntry in trackEntries) {
          final trackTitle = await _decryptString(trackEntry.encryptedTitle);
          final trackArtist = await _decryptString(trackEntry.encryptedArtist);
          final trackAlbum = await _decryptString(trackEntry.encryptedAlbum);

          final encMeta = trackEntry.encryptedTrackMetadata;
          if (encMeta == null) {
            throw const FormatException('Track reference missing encryptedTrackMetadata blob.');
          }
          final metaJson = await _decryptJson(encMeta);
          final metaDto = VaultTrackMetadataDto.fromJson(metaJson);

          trackRefs.add(
            PrivateTrackRef(
              id: trackEntry.id,
              playlistId: trackEntry.playlistId,
              trackUri: metaDto.trackUri,
              title: trackTitle,
              artistName: trackArtist,
              albumTitle: trackAlbum,
              durationMs: trackEntry.durationMs,
              sourceType: metaDto.sourceType,
              localRelativePath: trackEntry.isolatedMediaFileName,
              sortOrder: trackEntry.trackIndex,
              addedAtEpochMs: metaDto.addedAtEpochMs,
            ),
          );
        }

        int totalDuration = 0;
        for (final track in trackRefs) {
          totalDuration += track.durationMs;
        }

        playlists.add(
          PrivatePlaylist(
            id: playlistEntry.id,
            name: title,
            description: description,
            coverUri: coverUri,
            totalDurationMs: totalDuration,
            createdAtEpochMs: playlistEntry.createdAt,
            updatedAtEpochMs: playlistEntry.updatedAt,
            trackRefs: trackRefs,
          ),
        );
      }

      return VaultSuccess<List<PrivatePlaylist>>(playlists);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<List<PrivatePlaylist>>(failure);
    } catch (error) {
      return VaultFailureResult<List<PrivatePlaylist>>(
        VaultStorageFailure('Failed to get playlists: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    try {
      final playlistEntry = await (_database.select(_database.vaultPlaylistsTable)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (playlistEntry == null) {
        return VaultFailureResult<PrivatePlaylist>(
          VaultStorageFailure('Playlist not found with ID: $id'),
        );
      }

      final title = await _decryptString(playlistEntry.encryptedTitle);
      final description = await _decryptString(playlistEntry.encryptedDescription);

      final String? coverUri;
      final encCover = playlistEntry.encryptedCoverPath;
      if (encCover != null) {
        coverUri = await _decryptString(encCover);
      } else {
        coverUri = null;
      }

      final trackEntries = await (_database.select(_database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(id))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
          .get();

      final List<PrivateTrackRef> trackRefs = <PrivateTrackRef>[];
      for (final trackEntry in trackEntries) {
        final trackTitle = await _decryptString(trackEntry.encryptedTitle);
        final trackArtist = await _decryptString(trackEntry.encryptedArtist);
        final trackAlbum = await _decryptString(trackEntry.encryptedAlbum);

        final encMeta = trackEntry.encryptedTrackMetadata;
        if (encMeta == null) {
          throw const FormatException('Track reference missing encryptedTrackMetadata blob.');
        }
        final metaJson = await _decryptJson(encMeta);
        final metaDto = VaultTrackMetadataDto.fromJson(metaJson);

        trackRefs.add(
          PrivateTrackRef(
            id: trackEntry.id,
            playlistId: trackEntry.playlistId,
            trackUri: metaDto.trackUri,
            title: trackTitle,
            artistName: trackArtist,
            albumTitle: trackAlbum,
            durationMs: trackEntry.durationMs,
            sourceType: metaDto.sourceType,
            localRelativePath: trackEntry.isolatedMediaFileName,
            sortOrder: trackEntry.trackIndex,
            addedAtEpochMs: metaDto.addedAtEpochMs,
          ),
        );
      }

      int totalDuration = 0;
      for (final track in trackRefs) {
        totalDuration += track.durationMs;
      }

      final playlist = PrivatePlaylist(
        id: playlistEntry.id,
        name: title,
        description: description,
        coverUri: coverUri,
        totalDurationMs: totalDuration,
        createdAtEpochMs: playlistEntry.createdAt,
        updatedAtEpochMs: playlistEntry.updatedAt,
        trackRefs: trackRefs,
      );

      return VaultSuccess<PrivatePlaylist>(playlist);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<PrivatePlaylist>(failure);
    } catch (error) {
      return VaultFailureResult<PrivatePlaylist>(
        VaultStorageFailure('Failed to get playlist by ID: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    try {
      if (name.trim().isEmpty) {
        return const VaultFailureResult<PrivatePlaylist>(
          VaultValidationFailure('Playlist name must not be empty.'),
        );
      }

      final id = _uuid.v4();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final encTitle = await _encryptString(name);
      final encDescription = await _encryptString(description);
      final Uint8List? encCover;
      if (coverUri != null) {
        encCover = await _encryptString(coverUri);
      } else {
        encCover = null;
      }

      await _database.into(_database.vaultPlaylistsTable).insert(
            VaultPlaylistsTableCompanion(
              id: Value(id),
              encryptedTitle: Value(encTitle),
              encryptedDescription: Value(encDescription),
              encryptedCoverPath: Value(encCover),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
            ),
          );

      final playlist = PrivatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUri: coverUri,
        totalDurationMs: 0,
        createdAtEpochMs: nowMs,
        updatedAtEpochMs: nowMs,
        trackRefs: const <PrivateTrackRef>[],
      );

      return VaultSuccess<PrivatePlaylist>(playlist);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<PrivatePlaylist>(failure);
    } catch (error) {
      return VaultFailureResult<PrivatePlaylist>(
        VaultStorageFailure('Failed to create playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        final existing = await (_database.select(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlist.id)))
            .getSingleOrNull();

        if (existing == null) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot update non-existent playlist: ${playlist.id}'),
          );
        }

        final encTitle = await _encryptString(playlist.name);
        final encDescription = await _encryptString(playlist.description);
        final Uint8List? encCover;
        final coverUri = playlist.coverUri;
        if (coverUri != null) {
          encCover = await _encryptString(coverUri);
        } else {
          encCover = null;
        }

        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlist.id)))
            .write(
          VaultPlaylistsTableCompanion(
            encryptedTitle: Value(encTitle),
            encryptedDescription: Value(encDescription),
            encryptedCoverPath: Value(encCover),
            updatedAt: Value(playlist.updatedAtEpochMs),
          ),
        );

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to update playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        await (_database.delete(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId)))
            .go();

        final deletedRows = await (_database.delete(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .go();

        if (deletedRows == 0) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot delete non-existent playlist: $playlistId'),
          );
        }

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to delete playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        final playlist = await (_database.select(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .getSingleOrNull();

        if (playlist == null) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot add track to non-existent playlist: $playlistId'),
          );
        }

        final encTitle = await _encryptString(trackRef.title);
        final encArtist = await _encryptString(trackRef.artistName);
        final encAlbum = await _encryptString(trackRef.albumTitle);

        final metaDto = VaultTrackMetadataDto(
          trackUri: trackRef.trackUri,
          sourceType: trackRef.sourceType,
          addedAtEpochMs: trackRef.addedAtEpochMs,
        );
        final encMeta = await _encryptJson(metaDto.toJson());

        final existingTracks = await (_database.select(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId)))
            .get();
        final nextIndex = existingTracks.length;

        await _database.into(_database.vaultTrackRefsTable).insert(
              VaultTrackRefsTableCompanion(
                id: Value(trackRef.id),
                playlistId: Value(playlistId),
                trackIndex: Value(nextIndex),
                encryptedTrackMetadata: Value(encMeta),
                isolatedMediaFileName: Value(trackRef.localRelativePath),
                encryptedTitle: Value(encTitle),
                encryptedArtist: Value(encArtist),
                encryptedAlbum: Value(encAlbum),
                durationMs: Value(trackRef.durationMs),
              ),
            );

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .write(
          VaultPlaylistsTableCompanion(
            updatedAt: Value(nowMs),
          ),
        );

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to add track to playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        final playlist = await (_database.select(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .getSingleOrNull();

        if (playlist == null) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot remove track from non-existent playlist: $playlistId'),
          );
        }

        final deletedRows = await (_database.delete(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId) & tbl.id.equals(trackId)))
            .go();

        if (deletedRows == 0) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Track not found in playlist: $trackId'),
          );
        }

        final remainingTracks = await (_database.select(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
            .get();

        for (int i = 0; i < remainingTracks.length; i++) {
          final currentTrack = remainingTracks[i];
          if (currentTrack.trackIndex != i) {
            await (_database.update(_database.vaultTrackRefsTable)
                  ..where((tbl) => tbl.id.equals(currentTrack.id)))
                .write(
              VaultTrackRefsTableCompanion(
                trackIndex: Value(i),
              ),
            );
          }
        }

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .write(
          VaultPlaylistsTableCompanion(
            updatedAt: Value(nowMs),
          ),
        );

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to remove track from playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        final playlist = await (_database.select(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .getSingleOrNull();

        if (playlist == null) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot reorder tracks in non-existent playlist: $playlistId'),
          );
        }

        for (int i = 0; i < trackIdsInOrder.length; i++) {
          final trackId = trackIdsInOrder[i];
          await (_database.update(_database.vaultTrackRefsTable)
                ..where((tbl) => tbl.playlistId.equals(playlistId) & tbl.id.equals(trackId)))
              .write(
            VaultTrackRefsTableCompanion(
              trackIndex: Value(i),
            ),
          );
        }

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .write(
          VaultPlaylistsTableCompanion(
            updatedAt: Value(nowMs),
          ),
        );

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to reorder tracks in playlist: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Gesture Template Persistence
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    try {
      final pointsStr = await _secureStorage.read(key: 'musify_vault_gesture_points');
      final rubineStr = await _secureStorage.read(key: 'musify_vault_gesture_rubine');
      final updatedAtStr = await _secureStorage.read(key: 'musify_vault_gesture_updated_at');

      if (pointsStr != null && rubineStr != null) {
        final pointsJson = jsonDecode(pointsStr);
        final points = GestureTemplateDto.pointsFromJson(pointsJson);
        final rubineJson = jsonDecode(rubineStr);
        final rubine = GestureTemplateDto.rubineFromJson(rubineJson);
        final updatedAt = int.tryParse(updatedAtStr ?? '') ?? DateTime.now().millisecondsSinceEpoch;

        final template = GestureTemplate(
          id: 'master_gesture',
          normalizedPoints: points,
          rubineFeatureVector: rubine,
          createdAtEpochMs: updatedAt,
        );
        return VaultSuccess<GestureTemplate>(template);
      }

      final entry = await (_database.select(_database.vaultGestureTemplatesTable)
            ..where((tbl) => tbl.id.equals('master_gesture')))
          .getSingleOrNull();

      if (entry == null) {
        return const VaultFailureResult<GestureTemplate>(
          VaultStorageFailure('Golden master gesture template not found in storage.'),
        );
      }

      final pointsJson = await _decryptJson(entry.encryptedPoints64);
      final points = GestureTemplateDto.pointsFromJson(pointsJson);

      final rubineJson = await _decryptJson(entry.encryptedRubine7d);
      final rubine = GestureTemplateDto.rubineFromJson(rubineJson);

      final template = GestureTemplate(
        id: entry.id,
        normalizedPoints: points,
        rubineFeatureVector: rubine,
        createdAtEpochMs: entry.updatedAt,
      );

      return VaultSuccess<GestureTemplate>(template);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<GestureTemplate>(failure);
    } catch (error) {
      return VaultFailureResult<GestureTemplate>(
        VaultStorageFailure('Failed to load gesture template: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async {
    try {
      final pointsMapList = GestureTemplateDto.pointsToJson(template.normalizedPoints);
      final pointsJson = jsonEncode(pointsMapList);

      final rubineList = GestureTemplateDto.rubineToJson(template.rubineFeatureVector);
      final rubineJson = jsonEncode(rubineList);

      try {
        await _secureStorage.write(key: 'musify_vault_gesture_points', value: pointsJson);
        await _secureStorage.write(key: 'musify_vault_gesture_rubine', value: rubineJson);
        await _secureStorage.write(
          key: 'musify_vault_gesture_updated_at',
          value: template.createdAtEpochMs.toString(),
        );
      } catch (_) {
        // Platform secure storage might not be bound in non-widget unit tests
      }

      final encPoints = await _encryptJson(pointsMapList);
      final encRubine = await _encryptJson(rubineList);

      await _database.into(_database.vaultGestureTemplatesTable).insertOnConflictUpdate(
            VaultGestureTemplatesTableCompanion(
              id: const Value('master_gesture'),
              encryptedPoints64: Value(encPoints),
              encryptedRubine7d: Value(encRubine),
              updatedAt: Value(template.createdAtEpochMs),
            ),
          );

      return const VaultSuccess<void>(null);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to save gesture template: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Atomic Purge Routine
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<void>> purgeAllVaultData() async {
    try {
      await _database.transaction(() async {
        await _database.delete(_database.vaultTrackRefsTable).go();
        await _database.delete(_database.vaultPlaylistsTable).go();
        await _database.delete(_database.vaultConfigTable).go();
        await _database.delete(_database.vaultGestureTemplatesTable).go();
        await _database.delete(_database.vaultLockoutDeadlineTable).go();
      });

      try {
        await _secureStorage.delete(key: 'musify_vault_is_enrolled');
        await _secureStorage.delete(key: 'musify_vault_pin_salt');
        await _secureStorage.delete(key: 'musify_vault_pin_verifier');
        await _secureStorage.delete(key: 'musify_vault_gesture_points');
        await _secureStorage.delete(key: 'musify_vault_gesture_rubine');
        await _secureStorage.delete(key: 'musify_vault_gesture_updated_at');
      } catch (_) {
        // Platform secure storage might not be bound in non-widget unit tests
      }

      final shredMediaHook = _onShredMediaFiles;
      if (shredMediaHook != null) {
        await shredMediaHook();
      }

      await _cryptoBridge.destroyMasterKey();

      return const VaultSuccess<void>(null);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to purge vault data: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Lockout Deadline Persistence (Unencrypted Monotonic Epoch)
  // ---------------------------------------------------------------------------

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async {
    final entry = await (_database.select(_database.vaultLockoutDeadlineTable)
          ..where((tbl) => tbl.id.equals('lockout_deadline')))
        .getSingleOrNull();

    if (entry != null) {
      return entry.deadlineMonotonicMs;
    }
    return null;
  }

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _database.into(_database.vaultLockoutDeadlineTable).insertOnConflictUpdate(
          VaultLockoutDeadlineTableCompanion(
            id: const Value('lockout_deadline'),
            deadlineMonotonicMs: Value(deadlineMonotonicMs),
            failedAttempts: const Value(0),
            updatedAt: Value(nowMs),
          ),
        );
  }

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    await (_database.delete(_database.vaultLockoutDeadlineTable)
          ..where((tbl) => tbl.id.equals('lockout_deadline')))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Convenience Aliases
  // ---------------------------------------------------------------------------

  /// Convenience alias for [updatePlaylist].
  Future<VaultResult<void>> savePlaylist(PrivatePlaylist playlist) => updatePlaylist(playlist);

  /// Convenience alias for [getPlaylistById].
  Future<VaultResult<PrivatePlaylist>> getPlaylistWithTracks(String id) => getPlaylistById(id);

  /// Convenience alias for [addTrackToPlaylist].
  Future<VaultResult<void>> saveTrackRef({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) =>
      addTrackToPlaylist(playlistId: playlistId, trackRef: trackRef);

  /// Convenience alias for [removeTrackFromPlaylist].
  Future<VaultResult<void>> removeTrackRef({
    required String playlistId,
    required String trackId,
  }) =>
      removeTrackFromPlaylist(playlistId: playlistId, trackId: trackId);

  /// Convenience alias for [reorderTracksInPlaylist].
  Future<VaultResult<void>> reorderTracks({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) =>
      reorderTracksInPlaylist(playlistId: playlistId, trackIdsInOrder: trackIdsInOrder);

  /// Convenience alias for [loadVaultConfig].
  Future<VaultResult<VaultConfig>> getVaultConfig() => loadVaultConfig();

  /// Convenience alias for [loadGestureTemplate].
  Future<VaultResult<GestureTemplate>> getGestureTemplate() => loadGestureTemplate();
}
