import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/database/dtos/gesture_template_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_config_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_track_metadata_dto.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';

import '../../helpers/mock_native_vault_crypto_bridge.dart';

void main() {
  late VaultDatabase database;
  late MockNativeVaultCryptoBridge cryptoBridge;
  late VaultStorageRepository repository;

  setUp(() {
    database = VaultDatabase.forTesting(NativeDatabase.memory());
    cryptoBridge = MockNativeVaultCryptoBridge(
      hasMasterKey: true,
      isSessionUnlocked: true,
      isBiometricEnrolled: true,
    );
    repository = VaultStorageRepository(
      database: database,
      cryptoBridge: cryptoBridge,
    );
  });

  tearDown(() async {
    await database.close();
  });

  GestureTemplate createTestGestureTemplate({int pointsCount = 64}) {
    final points = List<GesturePoint>.generate(
      pointsCount,
      (index) => GesturePoint(
        x: index / pointsCount.toDouble(),
        y: (pointsCount - index) / pointsCount.toDouble(),
        timestampMs: index * 16,
      ),
    );
    return GestureTemplate(
      id: 'master_gesture',
      normalizedPoints: points,
      rubineFeatureVector: const [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7],
      createdAtEpochMs: 1700000000000,
    );
  }

  PrivateTrackRef createTestTrackRef({
    required String id,
    required String playlistId,
    required int sortOrder,
    int durationMs = 180000,
    TrackSourceTypeEnum sourceType = TrackSourceTypeEnum.spotify,
    String? localRelativePath,
  }) {
    return PrivateTrackRef(
      id: id,
      playlistId: playlistId,
      trackUri: 'spotify:track:$id',
      title: 'Title $id',
      artistName: 'Artist $id',
      albumTitle: 'Album $id',
      durationMs: durationMs,
      sourceType: sourceType,
      localRelativePath: localRelativePath,
      sortOrder: sortOrder,
      addedAtEpochMs: 1700000000000 + sortOrder * 1000,
    );
  }

  // ===========================================================================
  // ATTACK VECTOR 1: Cryptographic Tamper Injection
  // ===========================================================================
  group('Adversarial Vector 1: Cryptographic Tamper Injection', () {
    test('1.1 Direct decryptPayload rejects truncated ciphertext (< 28 bytes) with VaultValidationFailure', () async {
      final truncatedLengths = [0, 1, 11, 12, 16, 27];
      for (final len in truncatedLengths) {
        final truncatedBytes = Uint8List(len);
        expect(
          () => cryptoBridge.decryptPayload(truncatedBytes),
          throwsA(isA<VaultValidationFailure>()),
          reason: 'Ciphertext length $len must trigger VaultValidationFailure',
        );
      }
    });

    test('1.2 Truncated ciphertext injected into SQLite tables returns VaultFailureResult without uncaught crashes', () async {
      // 1.2.1 Config table with truncated encrypted payload
      await database.into(database.vaultConfigTable).insert(
            VaultConfigTableCompanion(
              id: const Value('vault_config'),
              encryptedPayload: Value(Uint8List.fromList([1, 2, 3, 4, 5])), // 5 bytes < 28
              updatedAt: const Value(1700000000000),
            ),
          );

      final configResult = await repository.loadVaultConfig();
      expect(configResult, isA<VaultFailureResult<VaultConfig>>());
      configResult.fold(
        onSuccess: (_) => fail('Expected failure for truncated config'),
        onFailure: (failure) => expect(failure, isA<VaultFailure>()),
      );

      // 1.2.2 Playlist table with truncated encrypted fields
      await database.into(database.vaultPlaylistsTable).insert(
            VaultPlaylistsTableCompanion(
              id: const Value('pl_tamper_1'),
              encryptedTitle: Value(Uint8List(12)), // 12 bytes < 28
              encryptedDescription: Value(Uint8List(20)), // 20 bytes < 28
              encryptedCoverPath: Value(Uint8List(10)), // 10 bytes < 28
              createdAt: const Value(1700000000000),
              updatedAt: const Value(1700000000000),
            ),
          );

      final playlistResult = await repository.getPlaylistById('pl_tamper_1');
      expect(playlistResult, isA<VaultFailureResult<PrivatePlaylist>>());

      final allPlaylistsResult = await repository.getPlaylists();
      expect(allPlaylistsResult, isA<VaultFailureResult<List<PrivatePlaylist>>>());

      // 1.2.3 Track refs table with truncated metadata
      // First create a valid playlist
      final validPl = await repository.createPlaylist(name: 'Valid PL', description: 'Desc');
      final plId = (validPl as VaultSuccess<PrivatePlaylist>).data.id;

      await database.into(database.vaultTrackRefsTable).insert(
            VaultTrackRefsTableCompanion(
              id: const Value('track_tampered_1'),
              playlistId: Value(plId),
              trackIndex: const Value(0),
              encryptedTrackMetadata: Value(Uint8List(27)), // 27 bytes < 28
              encryptedTitle: Value(Uint8List(27)),
              encryptedArtist: Value(Uint8List(27)),
              encryptedAlbum: Value(Uint8List(27)),
              durationMs: const Value(120000),
            ),
          );

      final playlistWithTruncatedTrack = await repository.getPlaylistById(plId);
      expect(playlistWithTruncatedTrack, isA<VaultFailureResult<PrivatePlaylist>>());

      // 1.2.4 Gesture templates with truncated blobs
      await database.into(database.vaultGestureTemplatesTable).insert(
            VaultGestureTemplatesTableCompanion(
              id: const Value('master_gesture'),
              encryptedPoints64: Value(Uint8List(15)),
              encryptedRubine7d: Value(Uint8List(22)),
              updatedAt: const Value(1700000000000),
            ),
          );

      final gestureResult = await repository.loadGestureTemplate();
      expect(gestureResult, isA<VaultFailureResult<GestureTemplate>>());
    });

    test('1.3 Single-bit flipped in IV, ciphertext body, or AEAD tag triggers VaultCryptoFailure and VaultFailureResult', () async {
      // Create a valid encrypted payload
      final originalPlaintext = Uint8List.fromList(utf8.encode('TopSecretVaultDataPayloadToStressTestAESGCMVerification'));
      final validCiphertext = await cryptoBridge.encryptPayload(originalPlaintext);
      expect(validCiphertext.length, greaterThan(28));

      final ivLen = 12;
      final tagLen = 16;
      final bodyLen = validCiphertext.length - ivLen - tagLen;
      expect(bodyLen, greaterThan(0));

      // Test locations:
      // IV: byte 0, byte 6, byte 11
      // Body: byte 12 (start of body), byte 12 + (bodyLen ~/ 2) (middle), byte 12 + bodyLen - 1 (end of body)
      // Tag: byte validCiphertext.length - 16, byte validCiphertext.length - 8, byte validCiphertext.length - 1
      final bitFlipPositions = [
        0, 6, 11, // IV positions
        12, 12 + (bodyLen ~/ 2), 12 + bodyLen - 1, // Body positions
        validCiphertext.length - 16, validCiphertext.length - 8, validCiphertext.length - 1, // Tag positions
      ];

      for (final bytePos in bitFlipPositions) {
        for (int bit = 0; bit < 8; bit++) {
          final tampered = Uint8List.fromList(validCiphertext);
          tampered[bytePos] ^= (1 << bit); // Flip single bit

          // Verify direct crypto bridge rejection
          expect(
            () => cryptoBridge.decryptPayload(tampered),
            throwsA(isA<VaultCryptoFailure>()),
            reason: 'Bit $bit at byte $bytePos must fail AEAD tag verification',
          );
        }
      }

      // Now inject single-bit flipped ciphertext into database config and verify repository handles it gracefully
      final tamperedConfigCiphertext = Uint8List.fromList(validCiphertext);
      tamperedConfigCiphertext[0] ^= 0x01; // flip 1 bit in IV

      await database.into(database.vaultConfigTable).insertOnConflictUpdate(
            VaultConfigTableCompanion(
              id: const Value('vault_config'),
              encryptedPayload: Value(tamperedConfigCiphertext),
              updatedAt: const Value(1700000000000),
            ),
          );

      final loadResult = await repository.loadVaultConfig();
      expect(loadResult, isA<VaultFailureResult<VaultConfig>>());
      loadResult.fold(
        onSuccess: (_) => fail('Expected failure for bit-flipped config'),
        onFailure: (failure) {
          expect(failure, isA<VaultFailure>());
          expect(failure.message, contains('Cryptographic authentication tag verification failed'));
        },
      );
    });

    test('1.4 Locked cryptographic session gracefully returns VaultFailureResult across all repository methods', () async {
      // Save valid data while unlocked
      final template = createTestGestureTemplate();
      final saveGesture = await repository.saveGestureTemplate(template);
      expect(saveGesture, isA<VaultSuccess<void>>());

      final saveConfig = await repository.saveVaultConfig(VaultConfig());
      expect(saveConfig, isA<VaultSuccess<void>>());

      final plResult = await repository.createPlaylist(name: 'Secure List', description: 'Secret');
      expect(plResult, isA<VaultSuccess<PrivatePlaylist>>());
      final plId = (plResult as VaultSuccess<PrivatePlaylist>).data.id;

      // Lock the session
      await cryptoBridge.lockSession();

      // Read operations must return VaultFailureResult gracefully
      final readConfig = await repository.loadVaultConfig();
      expect(readConfig, isA<VaultFailureResult<VaultConfig>>());

      final readGesture = await repository.loadGestureTemplate();
      expect(readGesture, isA<VaultFailureResult<GestureTemplate>>());

      final readPlaylist = await repository.getPlaylistById(plId);
      expect(readPlaylist, isA<VaultFailureResult<PrivatePlaylist>>());

      final readAllPlaylists = await repository.getPlaylists();
      expect(readAllPlaylists, isA<VaultFailureResult<List<PrivatePlaylist>>>());

      // Write operations requiring encryption must return VaultFailureResult
      final writeConfig = await repository.saveVaultConfig(VaultConfig());
      expect(writeConfig, isA<VaultFailureResult<void>>());

      final createPl = await repository.createPlaylist(name: 'New PL', description: 'Desc');
      expect(createPl, isA<VaultFailureResult<PrivatePlaylist>>());

      final addTrack = await repository.addTrackToPlaylist(
        playlistId: plId,
        trackRef: createTestTrackRef(id: 'track_locked_1', playlistId: plId, sortOrder: 0),
      );
      expect(addTrack, isA<VaultFailureResult<void>>());
    });

    test('1.5 Unencrypted Lockout Deadline survives session locking and process restarts', () async {
      // Persist deadline while unlocked
      const testDeadline = 1234567890;
      await repository.persistLockoutDeadlineMs(testDeadline);

      // Lock session
      await cryptoBridge.lockSession();

      // Reading deadline must succeed even when session is locked
      final readDeadline = await repository.getPersistedLockoutDeadlineMs();
      expect(readDeadline, equals(testDeadline));

      // Overwriting and clearing deadline must also succeed when locked
      const updatedDeadline = 9876543210;
      await repository.persistLockoutDeadlineMs(updatedDeadline);
      final readUpdated = await repository.getPersistedLockoutDeadlineMs();
      expect(readUpdated, equals(updatedDeadline));

      await repository.clearPersistedLockoutDeadline();
      final cleared = await repository.getPersistedLockoutDeadlineMs();
      expect(cleared, isNull);
    });
  });

  // ===========================================================================
  // ATTACK VECTOR 2: Contiguous Index & Cascade Integrity
  // ===========================================================================
  group('Adversarial Vector 2: Contiguous Index & Cascade Integrity', () {
    test('2.1 Non-sequential deletions (indices 0, 4, 8) preserve strictly contiguous indices (0..6) with 0 gaps', () async {
      final plRes = await repository.createPlaylist(name: 'Test Playlist 10', description: 'Testing contiguous indices');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      // Add 10 tracks (ids: t0..t9, indices: 0..9)
      for (int i = 0; i < 10; i++) {
        final track = createTestTrackRef(id: 't$i', playlistId: plId, sortOrder: i);
        final addRes = await repository.addTrackToPlaylist(playlistId: plId, trackRef: track);
        expect(addRes, isA<VaultSuccess<void>>());
      }

      // Verify initial state
      final plInitial = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(plInitial.trackRefs.length, equals(10));
      for (int i = 0; i < 10; i++) {
        expect(plInitial.trackRefs[i].id, equals('t$i'));
        expect(plInitial.trackRefs[i].sortOrder, equals(i));
      }

      // Arbitrary order deletion: delete track 4 first, then track 0, then track 8
      final del4 = await repository.removeTrackFromPlaylist(playlistId: plId, trackId: 't4');
      expect(del4, isA<VaultSuccess<void>>());

      // Check after deleting t4: remaining should be 9 tracks, indices 0..8
      final afterDel4 = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(afterDel4.trackRefs.length, equals(9));
      for (int i = 0; i < afterDel4.trackRefs.length; i++) {
        expect(afterDel4.trackRefs[i].sortOrder, equals(i), reason: 'Track at position $i must have sortOrder $i');
      }
      expect(afterDel4.trackRefs.map((t) => t.id).toList(), equals(['t0', 't1', 't2', 't3', 't5', 't6', 't7', 't8', 't9']));

      // Delete track 0 next
      final del0 = await repository.removeTrackFromPlaylist(playlistId: plId, trackId: 't0');
      expect(del0, isA<VaultSuccess<void>>());

      // Check after deleting t0: remaining should be 8 tracks, indices 0..7
      final afterDel0 = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(afterDel0.trackRefs.length, equals(8));
      for (int i = 0; i < afterDel0.trackRefs.length; i++) {
        expect(afterDel0.trackRefs[i].sortOrder, equals(i), reason: 'Track at position $i must have sortOrder $i');
      }
      expect(afterDel0.trackRefs.map((t) => t.id).toList(), equals(['t1', 't2', 't3', 't5', 't6', 't7', 't8', 't9']));

      // Delete track 8 next
      final del8 = await repository.removeTrackFromPlaylist(playlistId: plId, trackId: 't8');
      expect(del8, isA<VaultSuccess<void>>());

      // Final check: exactly 7 tracks remaining, strictly contiguous 0..6 with 0 gaps
      final afterDel8 = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(afterDel8.trackRefs.length, equals(7));
      final expectedIds = ['t1', 't2', 't3', 't5', 't6', 't7', 't9'];
      for (int i = 0; i < 7; i++) {
        expect(afterDel8.trackRefs[i].id, equals(expectedIds[i]));
        expect(afterDel8.trackRefs[i].sortOrder, equals(i));
      }

      // Check SQLite table directly to verify persisted database column integrity
      final dbRows = await (database.select(database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(plId))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
          .get();
      expect(dbRows.length, equals(7));
      for (int i = 0; i < 7; i++) {
        expect(dbRows[i].id, equals(expectedIds[i]));
        expect(dbRows[i].trackIndex, equals(i));
      }
    });

    test('2.2 Repeated head-drain deletions maintain contiguity until playlist is empty', () async {
      final plRes = await repository.createPlaylist(name: 'Head Drain', description: 'Desc');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      for (int i = 0; i < 6; i++) {
        await repository.addTrackToPlaylist(
          playlistId: plId,
          trackRef: createTestTrackRef(id: 'head_$i', playlistId: plId, sortOrder: i),
        );
      }

      // Drain from head (always remove index 0)
      for (int step = 0; step < 6; step++) {
        final currentPl = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
        expect(currentPl.trackRefs.length, equals(6 - step));

        for (int idx = 0; idx < currentPl.trackRefs.length; idx++) {
          expect(currentPl.trackRefs[idx].sortOrder, equals(idx));
        }

        final trackToRemove = currentPl.trackRefs.first.id;
        final removeRes = await repository.removeTrackFromPlaylist(playlistId: plId, trackId: trackToRemove);
        expect(removeRes, isA<VaultSuccess<void>>());
      }

      // Empty playlist check
      final finalPl = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(finalPl.trackRefs, isEmpty);
      expect(finalPl.totalDurationMs, equals(0));
    });

    test('2.3 Deleting non-existent track or non-existent playlist returns VaultFailureResult', () async {
      final plRes = await repository.createPlaylist(name: 'Valid PL', description: 'Desc');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      final res1 = await repository.removeTrackFromPlaylist(playlistId: plId, trackId: 'ghost_track');
      expect(res1, isA<VaultFailureResult<void>>());

      final res2 = await repository.removeTrackFromPlaylist(playlistId: 'ghost_playlist', trackId: 'ghost_track');
      expect(res2, isA<VaultFailureResult<void>>());
    });

    test('2.4 Cascade deletion via repository atomically purges all child track refs', () async {
      final plRes = await repository.createPlaylist(name: 'Parent Playlist', description: 'To be cascade deleted');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      for (int i = 0; i < 5; i++) {
        await repository.addTrackToPlaylist(
          playlistId: plId,
          trackRef: createTestTrackRef(id: 'cascade_track_$i', playlistId: plId, sortOrder: i),
        );
      }

      // Verify rows exist before deletion
      final initialTracks = await (database.select(database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(plId)))
          .get();
      expect(initialTracks.length, equals(5));

      // Delete parent playlist via repository
      final delRes = await repository.deletePlaylist(plId);
      expect(delRes, isA<VaultSuccess<void>>());

      // Verify playlist is gone
      final plInDb = await (database.select(database.vaultPlaylistsTable)
            ..where((tbl) => tbl.id.equals(plId)))
          .getSingleOrNull();
      expect(plInDb, isNull);

      // Verify all child track refs are purged atomically
      final remainingTracks = await (database.select(database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(plId)))
          .get();
      expect(remainingTracks, isEmpty);

      // Attempting to delete non-existent playlist returns VaultFailureResult
      final delGhost = await repository.deletePlaylist('ghost_playlist_id');
      expect(delGhost, isA<VaultFailureResult<void>>());
    });

    test('2.5 Native SQLite PRAGMA foreign_keys = ON enforces cascade deletion at SQL engine level', () async {
      final plRes = await repository.createPlaylist(name: 'Engine Cascade PL', description: 'Desc');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      for (int i = 0; i < 4; i++) {
        await repository.addTrackToPlaylist(
          playlistId: plId,
          trackRef: createTestTrackRef(id: 'engine_track_$i', playlistId: plId, sortOrder: i),
        );
      }

      // Execute RAW SQL DELETE on vault_playlists directly, bypassing repository logic
      await database.customStatement('DELETE FROM vault_playlists WHERE id = ?;', [plId]);

      // Query vault_track_refs: child rows MUST have been purged automatically by SQLite cascade
      final orphanedTracks = await (database.select(database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(plId)))
          .get();
      expect(orphanedTracks, isEmpty, reason: 'SQLite foreign key cascade must eliminate orphaned tracks');
    });

    test('2.6 Foreign key constraint prevents inserting track with orphaned playlistId', () async {
      expect(
        () async {
          await database.into(database.vaultTrackRefsTable).insert(
                VaultTrackRefsTableCompanion(
                  id: const Value('orphaned_track'),
                  playlistId: const Value('non_existent_foreign_key_pl'),
                  trackIndex: const Value(0),
                  encryptedTitle: Value(Uint8List(32)),
                  encryptedArtist: Value(Uint8List(32)),
                  encryptedAlbum: Value(Uint8List(32)),
                  durationMs: const Value(1000),
                ),
              );
        },
        throwsA(isA<SqliteException>()),
      );
    });
  });

  // ===========================================================================
  // ATTACK VECTOR 3: Rapid Concurrency & Volume Stress
  // ===========================================================================
  group('Adversarial Vector 3: Rapid Concurrency & Volume Stress', () {
    test('3.1 Insert 100 tracks in rapid succession with atomic contiguity and accurate cumulative duration', () async {
      final plRes = await repository.createPlaylist(name: 'Volume 100 Tracks', description: 'Stress test 100 inserts');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      const trackCount = 100;
      int expectedTotalDuration = 0;

      for (int i = 0; i < trackCount; i++) {
        final duration = 100000 + (i * 1000);
        expectedTotalDuration += duration;
        final track = createTestTrackRef(
          id: 'vol_track_$i',
          playlistId: plId,
          sortOrder: i,
          durationMs: duration,
        );
        final addRes = await repository.addTrackToPlaylist(playlistId: plId, trackRef: track);
        expect(addRes, isA<VaultSuccess<void>>());
      }

      final fetchedPl = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(fetchedPl.trackRefs.length, equals(trackCount));
      expect(fetchedPl.totalDurationMs, equals(expectedTotalDuration));

      for (int i = 0; i < trackCount; i++) {
        expect(fetchedPl.trackRefs[i].id, equals('vol_track_$i'));
        expect(fetchedPl.trackRefs[i].sortOrder, equals(i));
      }
    });

    test('3.2 Reorder 100 tracks in reverse order executes atomically with zero corruption', () async {
      final plRes = await repository.createPlaylist(name: 'Reorder 100 Tracks', description: 'Stress test 100 reorder');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      const trackCount = 100;
      for (int i = 0; i < trackCount; i++) {
        final track = createTestTrackRef(id: 'reorder_t_$i', playlistId: plId, sortOrder: i);
        await repository.addTrackToPlaylist(playlistId: plId, trackRef: track);
      }

      // Reverse order: reorder_t_99, reorder_t_98, ..., reorder_t_0
      final reversedIds = List<String>.generate(trackCount, (i) => 'reorder_t_${trackCount - 1 - i}');

      final reorderRes = await repository.reorderTracksInPlaylist(
        playlistId: plId,
        trackIdsInOrder: reversedIds,
      );
      expect(reorderRes, isA<VaultSuccess<void>>());

      final fetchedPl = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(fetchedPl.trackRefs.length, equals(trackCount));

      for (int i = 0; i < trackCount; i++) {
        final expectedId = reversedIds[i];
        expect(fetchedPl.trackRefs[i].id, equals(expectedId));
        expect(fetchedPl.trackRefs[i].sortOrder, equals(i));
      }

      // Check DB directly
      final dbRows = await (database.select(database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(plId))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
          .get();
      expect(dbRows.length, equals(trackCount));
      for (int i = 0; i < trackCount; i++) {
        expect(dbRows[i].id, equals(reversedIds[i]));
        expect(dbRows[i].trackIndex, equals(i));
      }
    });

    test('3.3 Interleaved rapid mutations (add, remove, reorder) maintain state consistency', () async {
      final plRes = await repository.createPlaylist(name: 'Interleaved Mutations', description: 'Desc');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      // Add 20 tracks
      for (int i = 0; i < 20; i++) {
        await repository.addTrackToPlaylist(
          playlistId: plId,
          trackRef: createTestTrackRef(id: 'intl_$i', playlistId: plId, sortOrder: i),
        );
      }

      // Delete 5 arbitrary tracks
      final toDelete = ['intl_3', 'intl_7', 'intl_11', 'intl_15', 'intl_19'];
      for (final id in toDelete) {
        final delRes = await repository.removeTrackFromPlaylist(playlistId: plId, trackId: id);
        expect(delRes, isA<VaultSuccess<void>>());
      }

      // 15 tracks remain (indices 0..14)
      final midPl = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(midPl.trackRefs.length, equals(15));
      for (int i = 0; i < 15; i++) {
        expect(midPl.trackRefs[i].sortOrder, equals(i));
      }

      // Add 5 more tracks
      for (int i = 20; i < 25; i++) {
        await repository.addTrackToPlaylist(
          playlistId: plId,
          trackRef: createTestTrackRef(id: 'intl_$i', playlistId: plId, sortOrder: 15 + (i - 20)),
        );
      }

      // 20 tracks exist now
      final afterAdd = (await repository.getPlaylistById(plId) as VaultSuccess<PrivatePlaylist>).data;
      expect(afterAdd.trackRefs.length, equals(20));
      for (int i = 0; i < 20; i++) {
        expect(afterAdd.trackRefs[i].sortOrder, equals(i));
      }
    });

    test('3.4 Purge all vault data atomically purges multi-table volume and invokes shredding callback', () async {
      bool shredCallbackInvoked = false;
      final shreddingRepo = VaultStorageRepository(
        database: database,
        cryptoBridge: cryptoBridge,
        onShredMediaFiles: () async {
          shredCallbackInvoked = true;
        },
      );

      // Populate 3 playlists with 10 tracks each (30 tracks total)
      for (int p = 0; p < 3; p++) {
        final pl = (await shreddingRepo.createPlaylist(name: 'PL $p', description: 'Desc $p') as VaultSuccess<PrivatePlaylist>).data;
        for (int t = 0; t < 10; t++) {
          await shreddingRepo.addTrackToPlaylist(
            playlistId: pl.id,
            trackRef: createTestTrackRef(id: 'purge_t_${p}_$t', playlistId: pl.id, sortOrder: t),
          );
        }
      }

      // Populate config, gesture template, lockout deadline
      await shreddingRepo.saveVaultConfig(VaultConfig());
      await shreddingRepo.saveGestureTemplate(createTestGestureTemplate());
      await shreddingRepo.persistLockoutDeadlineMs(9999999);

      // Verify all tables have rows
      expect((await database.select(database.vaultPlaylistsTable).get()).length, equals(3));
      expect((await database.select(database.vaultTrackRefsTable).get()).length, equals(30));
      expect((await database.select(database.vaultConfigTable).get()).length, equals(1));
      expect((await database.select(database.vaultGestureTemplatesTable).get()).length, equals(1));
      expect((await database.select(database.vaultLockoutDeadlineTable).get()).length, equals(1));
      expect(await cryptoBridge.hasMasterKey(), isTrue);

      // Execute purge
      final purgeRes = await shreddingRepo.purgeAllVaultData();
      expect(purgeRes, isA<VaultSuccess<void>>());

      // Verify all 5 tables are completely empty
      expect((await database.select(database.vaultPlaylistsTable).get()), isEmpty);
      expect((await database.select(database.vaultTrackRefsTable).get()), isEmpty);
      expect((await database.select(database.vaultConfigTable).get()), isEmpty);
      expect((await database.select(database.vaultGestureTemplatesTable).get()), isEmpty);
      expect((await database.select(database.vaultLockoutDeadlineTable).get()), isEmpty);

      // Verify shred hook and KeyStore unbinding
      expect(shredCallbackInvoked, isTrue);
      expect(await cryptoBridge.hasMasterKey(), isFalse);
    });
  });

  // ===========================================================================
  // ATTACK VECTOR 4: Schema & DTO Fuzzing (Fail-Fast Verification)
  // ===========================================================================
  group('Adversarial Vector 4: Schema & DTO Fuzzing', () {
    // -------------------------------------------------------------------------
    // 4.1 VaultConfigDto Fuzzing
    // -------------------------------------------------------------------------
    test('4.1.1 VaultConfigDto.fromJson fails fast on non-Map or empty input', () {
      final nonMaps = [null, '', 123, 45.67, true, false, [1, 2, 3]];
      for (final input in nonMaps) {
        expect(
          () => VaultConfigDto.fromJson(input),
          throwsA(isA<FormatException>()),
          reason: 'Input $input is not a Map and must throw FormatException',
        );
      }

      expect(
        () => VaultConfigDto.fromJson(<String, Object>{}),
        throwsA(isA<FormatException>()),
        reason: 'Empty map must fail validation',
      );
    });

    test('4.1.2 VaultConfigDto.fromJson fails fast when any required field is missing', () {
      final validMap = <String, Object>{
        'themePalette': VaultThemePalettePolicyEnum.warmEspresso.id,
        'biometricAuth': BiometricAuthPolicyEnum.pinOnly.id,
        'activeReauthInterval': ActiveReauthIntervalEnum.every15Minutes.id,
        'backgroundGraceTimeout': BackgroundGraceTimeoutEnum.thirtySeconds.id,
        'screenSecurity': ScreenSecurityPolicyEnum.blockScreenshotsAndRecents.id,
        'metadataVisibility': MetadataVisibilityPolicyEnum.maskWithPlaceholder.id,
        'decoyTitle': 'System Audio',
        'decoyArtist': 'Media Service',
        'decoyAlbum': 'Internal Playback',
        'lockPlaybackBehavior': LockPlaybackBehaviorEnum.continueMaskedInBackground.id,
        'gestureSensitivity': GestureSensitivityTierEnum.balanced84Percent.id,
        'gestureVisibility': GestureVisibilityPolicyEnum.invisibleStealth.id,
        'keypadLayout': KeypadLayoutPolicyEnum.standardOrdered.id,
      };

      for (final key in validMap.keys) {
        final corrupted = Map<String, Object>.from(validMap)..remove(key);
        expect(
          () => VaultConfigDto.fromJson(corrupted),
          throwsA(isA<FormatException>()),
          reason: 'Omitting required key "$key" must trigger FormatException',
        );
      }
    });

    test('4.1.3 VaultConfigDto.fromJson fails fast on empty/whitespace decoy strings or invalid types', () {
      final validMap = <String, Object>{
        'themePalette': VaultThemePalettePolicyEnum.warmEspresso.id,
        'biometricAuth': BiometricAuthPolicyEnum.pinOnly.id,
        'activeReauthInterval': ActiveReauthIntervalEnum.every15Minutes.id,
        'backgroundGraceTimeout': BackgroundGraceTimeoutEnum.thirtySeconds.id,
        'screenSecurity': ScreenSecurityPolicyEnum.blockScreenshotsAndRecents.id,
        'metadataVisibility': MetadataVisibilityPolicyEnum.maskWithPlaceholder.id,
        'decoyTitle': 'System Audio',
        'decoyArtist': 'Media Service',
        'decoyAlbum': 'Internal Playback',
        'lockPlaybackBehavior': LockPlaybackBehaviorEnum.continueMaskedInBackground.id,
        'gestureSensitivity': GestureSensitivityTierEnum.balanced84Percent.id,
        'gestureVisibility': GestureVisibilityPolicyEnum.invisibleStealth.id,
        'keypadLayout': KeypadLayoutPolicyEnum.standardOrdered.id,
      };

      final invalidDecoyValues = ['', '   ', '\t\n', 12345, null, true];
      for (final invalidVal in invalidDecoyValues) {
        final badTitle = Map<String, Object?>.from(validMap)..['decoyTitle'] = invalidVal;
        expect(() => VaultConfigDto.fromJson(badTitle), throwsA(isA<FormatException>()));

        final badArtist = Map<String, Object?>.from(validMap)..['decoyArtist'] = invalidVal;
        expect(() => VaultConfigDto.fromJson(badArtist), throwsA(isA<FormatException>()));

        final badAlbum = Map<String, Object?>.from(validMap)..['decoyAlbum'] = invalidVal;
        expect(() => VaultConfigDto.fromJson(badAlbum), throwsA(isA<FormatException>()));
      }
    });

    test('4.1.4 VaultConfigDto.fromJson fails fast on unrecognized enum policy IDs', () {
      final validMap = <String, Object>{
        'themePalette': VaultThemePalettePolicyEnum.warmEspresso.id,
        'biometricAuth': BiometricAuthPolicyEnum.pinOnly.id,
        'activeReauthInterval': ActiveReauthIntervalEnum.every15Minutes.id,
        'backgroundGraceTimeout': BackgroundGraceTimeoutEnum.thirtySeconds.id,
        'screenSecurity': ScreenSecurityPolicyEnum.blockScreenshotsAndRecents.id,
        'metadataVisibility': MetadataVisibilityPolicyEnum.maskWithPlaceholder.id,
        'decoyTitle': 'System Audio',
        'decoyArtist': 'Media Service',
        'decoyAlbum': 'Internal Playback',
        'lockPlaybackBehavior': LockPlaybackBehaviorEnum.continueMaskedInBackground.id,
        'gestureSensitivity': GestureSensitivityTierEnum.balanced84Percent.id,
        'gestureVisibility': GestureVisibilityPolicyEnum.invisibleStealth.id,
        'keypadLayout': KeypadLayoutPolicyEnum.standardOrdered.id,
      };

      final enumKeys = [
        'themePalette',
        'biometricAuth',
        'activeReauthInterval',
        'backgroundGraceTimeout',
        'screenSecurity',
        'metadataVisibility',
        'lockPlaybackBehavior',
        'gestureSensitivity',
        'gestureVisibility',
        'keypadLayout',
      ];

      for (final key in enumKeys) {
        final corrupted = Map<String, Object>.from(validMap)..[key] = 'CORRUPTED_ENUM_VALUE_XYZ';
        expect(
          () => VaultConfigDto.fromJson(corrupted),
          throwsA(isA<FormatException>()),
          reason: 'Unrecognized enum ID for $key must throw FormatException',
        );
      }
    });

    // -------------------------------------------------------------------------
    // 4.2 VaultTrackMetadataDto Fuzzing
    // -------------------------------------------------------------------------
    test('4.2.1 VaultTrackMetadataDto.fromJson fails fast on missing or corrupted inputs', () {
      // Non-map
      expect(() => VaultTrackMetadataDto.fromJson(null), throwsA(isA<FormatException>()));
      expect(() => VaultTrackMetadataDto.fromJson('not a map'), throwsA(isA<FormatException>()));
      expect(() => VaultTrackMetadataDto.fromJson(123), throwsA(isA<FormatException>()));

      // Empty map
      expect(() => VaultTrackMetadataDto.fromJson(<String, Object>{}), throwsA(isA<FormatException>()));

      // Missing trackUri or whitespace
      expect(
        () => VaultTrackMetadataDto.fromJson({
          'trackUri': '   ',
          'sourceType': 'SPOTIFY',
          'addedAtEpochMs': 1700000000000,
        }),
        throwsA(isA<FormatException>()),
      );

      // Invalid sourceType
      expect(
        () => VaultTrackMetadataDto.fromJson({
          'trackUri': 'spotify:track:123',
          'sourceType': 'UNKNOWN_SOURCE_XYZ',
          'addedAtEpochMs': 1700000000000,
        }),
        throwsA(isA<FormatException>()),
      );

      // Non-positive or non-int addedAtEpochMs
      final invalidTimestamps = [0, -1, -99999, '2026-01-01', 3.14, null];
      for (final ts in invalidTimestamps) {
        expect(
          () => VaultTrackMetadataDto.fromJson({
            'trackUri': 'spotify:track:123',
            'sourceType': 'SPOTIFY',
            'addedAtEpochMs': ts,
          }),
          throwsA(isA<FormatException>()),
          reason: 'Timestamp $ts must fail validation',
        );
      }
    });

    // -------------------------------------------------------------------------
    // 4.3 GestureTemplateDto Fuzzing
    // -------------------------------------------------------------------------
    test('4.3.1 GestureTemplateDto.pointsFromJson fails fast when points count != 64 or coordinates non-finite', () {
      // Non-list
      expect(() => GestureTemplateDto.pointsFromJson(null), throwsA(isA<FormatException>()));
      expect(() => GestureTemplateDto.pointsFromJson({'points': []}), throwsA(isA<FormatException>()));

      // Count != 64 (test 0, 1, 63, 65, 100)
      final badLengths = [0, 1, 63, 65, 100];
      for (final len in badLengths) {
        final list = List.generate(len, (i) => {'x': 0.1, 'y': 0.2, 't': 100});
        expect(
          () => GestureTemplateDto.pointsFromJson(list),
          throwsA(isA<FormatException>()),
          reason: 'Points length $len must trigger FormatException',
        );
      }

      // Point not a map
      final notAMap = List.generate(64, (i) => i == 5 ? 'not a map' : {'x': 0.1, 'y': 0.2, 't': 100});
      expect(() => GestureTemplateDto.pointsFromJson(notAMap), throwsA(isA<FormatException>()));

      // NaN and Infinite coordinates
      final nonFiniteValues = [double.nan, double.infinity, double.negativeInfinity];
      for (final badVal in nonFiniteValues) {
        final badX = List.generate(64, (i) => i == 10 ? {'x': badVal, 'y': 0.5, 't': 100} : {'x': 0.1, 'y': 0.2, 't': 100});
        expect(() => GestureTemplateDto.pointsFromJson(badX), throwsA(isA<FormatException>()));

        final badY = List.generate(64, (i) => i == 10 ? {'x': 0.5, 'y': badVal, 't': 100} : {'x': 0.1, 'y': 0.2, 't': 100});
        expect(() => GestureTemplateDto.pointsFromJson(badY), throwsA(isA<FormatException>()));
      }

      // Negative timestamp
      final badT = List.generate(64, (i) => i == 15 ? {'x': 0.5, 'y': 0.5, 't': -10} : {'x': 0.1, 'y': 0.2, 't': 100});
      expect(() => GestureTemplateDto.pointsFromJson(badT), throwsA(isA<FormatException>()));
    });

    test('4.3.2 GestureTemplateDto.rubineFromJson fails fast when features length != 7 or non-finite', () {
      // Non-list
      expect(() => GestureTemplateDto.rubineFromJson(null), throwsA(isA<FormatException>()));
      expect(() => GestureTemplateDto.rubineFromJson('rubine'), throwsA(isA<FormatException>()));

      // Length != 7 (test 0, 1, 6, 8, 14)
      final badLengths = [0, 1, 6, 8, 14];
      for (final len in badLengths) {
        final list = List.generate(len, (i) => 0.5);
        expect(
          () => GestureTemplateDto.rubineFromJson(list),
          throwsA(isA<FormatException>()),
          reason: 'Rubine length $len must trigger FormatException',
        );
      }

      // Non-finite values
      for (final badVal in [double.nan, double.infinity, double.negativeInfinity]) {
        final badList = [0.1, 0.2, badVal, 0.4, 0.5, 0.6, 0.7];
        expect(() => GestureTemplateDto.rubineFromJson(badList), throwsA(isA<FormatException>()));
      }
    });

    // -------------------------------------------------------------------------
    // 4.4 End-to-End Repository Behavior with Corrupted Decrypted JSON
    // -------------------------------------------------------------------------
    test('4.4.1 Repository returns VaultFailureResult when decrypted JSON fails DTO schema validation', () async {
      // 1. Config: encrypt invalid JSON payload and save directly to table
      final invalidConfigJson = jsonEncode({'themePalette': 'NON_EXISTENT_THEME'});
      final encInvalidConfig = await cryptoBridge.encryptPayload(Uint8List.fromList(utf8.encode(invalidConfigJson)));

      await database.into(database.vaultConfigTable).insertOnConflictUpdate(
            VaultConfigTableCompanion(
              id: const Value('vault_config'),
              encryptedPayload: Value(encInvalidConfig),
              updatedAt: const Value(1700000000000),
            ),
          );

      final configResult = await repository.loadVaultConfig();
      expect(configResult, isA<VaultFailureResult<VaultConfig>>());
      configResult.fold(
        onSuccess: (_) => fail('Expected failure for corrupted config JSON'),
        onFailure: (failure) {
          expect(failure, isA<VaultStorageFailure>());
          expect(failure.cause, isA<FormatException>());
        },
      );

      // 2. Playlist: create valid playlist, then corrupt track ref metadata with invalid JSON
      final plRes = await repository.createPlaylist(name: 'Corrupted Metadata PL', description: 'Desc');
      final plId = (plRes as VaultSuccess<PrivatePlaylist>).data.id;

      final invalidMetaJson = jsonEncode({'trackUri': '', 'sourceType': 'INVALID', 'addedAtEpochMs': -99});
      final encInvalidMeta = await cryptoBridge.encryptPayload(Uint8List.fromList(utf8.encode(invalidMetaJson)));
      final encField = await cryptoBridge.encryptPayload(Uint8List.fromList(utf8.encode('Field')));

      await database.into(database.vaultTrackRefsTable).insert(
            VaultTrackRefsTableCompanion(
              id: const Value('track_corrupted_meta'),
              playlistId: Value(plId),
              trackIndex: const Value(0),
              encryptedTrackMetadata: Value(encInvalidMeta),
              encryptedTitle: Value(encField),
              encryptedArtist: Value(encField),
              encryptedAlbum: Value(encField),
              durationMs: const Value(120000),
            ),
          );

      final getPlResult = await repository.getPlaylistById(plId);
      expect(getPlResult, isA<VaultFailureResult<PrivatePlaylist>>());
      getPlResult.fold(
        onSuccess: (_) => fail('Expected failure for corrupted track metadata JSON'),
        onFailure: (failure) {
          expect(failure, isA<VaultStorageFailure>());
          expect(failure.cause, isA<FormatException>());
        },
      );

      // 3. Track ref with null encryptedTrackMetadata blob in table triggers FormatException -> VaultStorageFailure
      await database.customStatement(
        'UPDATE vault_track_refs SET encrypted_track_metadata = NULL WHERE id = ?;',
        ['track_corrupted_meta'],
      );

      final getPlNullMeta = await repository.getPlaylistById(plId);
      expect(getPlNullMeta, isA<VaultFailureResult<PrivatePlaylist>>());
      getPlNullMeta.fold(
        onSuccess: (_) => fail('Expected failure for null encrypted_track_metadata'),
        onFailure: (failure) {
          expect(failure, isA<VaultStorageFailure>());
          expect(failure.message, contains('missing encryptedTrackMetadata'));
        },
      );
    });
  });
}
