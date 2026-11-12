import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late VaultDatabase database;
  late MockNativeVaultCryptoBridge cryptoBridge;
  late VaultStorageRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    database = VaultDatabase.forTesting(NativeDatabase.memory());
    cryptoBridge = MockNativeVaultCryptoBridge(
      hasMasterKey: true,
      isSessionUnlocked: true,
    );
    repository = VaultStorageRepository(
      database: database,
      cryptoBridge: cryptoBridge,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('VaultStorageRepository - VaultConfig CRUD', () {
    test('saves and loads VaultConfig with deep policy equality', () async {
      final config = VaultConfig(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
        activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes,
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.oneMinute,
        screenSecurity: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Decoy Title',
        decoyArtist: 'Decoy Artist',
        decoyAlbum: 'Decoy Album',
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
        gestureSensitivity: GestureSensitivityTierEnum.strict92Percent,
        gestureVisibility: GestureVisibilityPolicyEnum.faintDissipatingHairline,
        keypadLayout: KeypadLayoutPolicyEnum.randomizedPerAttempt,
      );

      final saveResult = await repository.saveVaultConfig(config);
      expect(saveResult, isA<VaultSuccess<void>>());

      final loadResult = await repository.loadVaultConfig();
      expect(loadResult, isA<VaultSuccess<VaultConfig>>());

      if (loadResult case VaultSuccess(:final data)) {
        expect(data.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
        expect(data.biometricAuth, equals(BiometricAuthPolicyEnum.pinAndBiometricStrong));
        expect(data.activeReauthInterval, equals(ActiveReauthIntervalEnum.every5Minutes));
        expect(data.backgroundGraceTimeout, equals(BackgroundGraceTimeoutEnum.oneMinute));
        expect(data.decoyTitle, equals('Decoy Title'));
        expect(data.decoyArtist, equals('Decoy Artist'));
        expect(data.decoyAlbum, equals('Decoy Album'));
        expect(data.lockPlaybackBehavior, equals(LockPlaybackBehaviorEnum.stopImmediately));
        expect(data.gestureSensitivity, equals(GestureSensitivityTierEnum.strict92Percent));
        expect(data.gestureVisibility, equals(GestureVisibilityPolicyEnum.faintDissipatingHairline));
        expect(data.keypadLayout, equals(KeypadLayoutPolicyEnum.randomizedPerAttempt));
        expect(data, equals(config));
      }
    });

    test('returns VaultStorageFailure when VaultConfig does not exist', () async {
      final loadResult = await repository.loadVaultConfig();
      expect(loadResult, isA<VaultFailureResult<VaultConfig>>());

      if (loadResult case VaultFailureResult(:final failure)) {
        expect(failure, isA<VaultStorageFailure>());
        expect(failure.message, contains('not found'));
      }
    });
  });

  group('VaultStorageRepository - Private Playlists CRUD', () {
    test('creates and retrieves private playlist with encrypted fields', () async {
      final createResult = await repository.createPlaylist(
        name: 'Top Secret Beats',
        description: 'Classified listening list',
        coverUri: 'file:///vault/covers/secret.png',
      );

      expect(createResult, isA<VaultSuccess<PrivatePlaylist>>());

      final String createdId;
      if (createResult case VaultSuccess(:final data)) {
        expect(data.name, equals('Top Secret Beats'));
        expect(data.description, equals('Classified listening list'));
        expect(data.coverUri, equals('file:///vault/covers/secret.png'));
        expect(data.totalDurationMs, equals(0));
        expect(data.trackRefs.isEmpty, isTrue);
        createdId = data.id;
      } else {
        fail('Failed to create playlist');
      }

      // Verify direct database storage has ciphertext, not plaintext
      final rawRow = await (database.select(database.vaultPlaylistsTable)
            ..where((tbl) => tbl.id.equals(createdId)))
          .getSingle();
      expect(rawRow.encryptedTitle, isNot(equals('Top Secret Beats'.codeUnits)));

      // Fetch playlist by ID through repository
      final fetchResult = await repository.getPlaylistById(createdId);
      expect(fetchResult, isA<VaultSuccess<PrivatePlaylist>>());
      if (fetchResult case VaultSuccess(:final data)) {
        expect(data.id, equals(createdId));
        expect(data.name, equals('Top Secret Beats'));
        expect(data.description, equals('Classified listening list'));
        expect(data.coverUri, equals('file:///vault/covers/secret.png'));
      }
    });

    test('rejects playlist creation with empty name', () async {
      final createResult = await repository.createPlaylist(
        name: '   ',
        description: 'Invalid blank name',
      );

      expect(createResult, isA<VaultFailureResult<PrivatePlaylist>>());
      if (createResult case VaultFailureResult(:final failure)) {
        expect(failure, isA<VaultValidationFailure>());
      }
    });

    test('updates existing playlist record', () async {
      final createResult = await repository.createPlaylist(
        name: 'Original Title',
        description: 'Original Description',
      );

      final PrivatePlaylist originalPlaylist;
      if (createResult case VaultSuccess(:final data)) {
        originalPlaylist = data;
      } else {
        fail('Playlist creation failed');
      }

      final updatedPlaylist = originalPlaylist.copyWith(
        name: 'Renamed Secret Title',
        description: 'Updated Description',
        updatedAtEpochMs: originalPlaylist.updatedAtEpochMs + 5000,
      );

      final updateResult = await repository.updatePlaylist(updatedPlaylist);
      expect(updateResult, isA<VaultSuccess<void>>());

      final fetchResult = await repository.getPlaylistById(originalPlaylist.id);
      if (fetchResult case VaultSuccess(:final data)) {
        expect(data.name, equals('Renamed Secret Title'));
        expect(data.description, equals('Updated Description'));
        expect(data.updatedAtEpochMs, equals(originalPlaylist.updatedAtEpochMs + 5000));
      }
    });

    test('deletes playlist and cascades deletion to tracks', () async {
      final createResult = await repository.createPlaylist(
        name: 'To Be Deleted',
        description: 'Temporary',
      );

      final String playlistId;
      if (createResult case VaultSuccess(:final data)) {
        playlistId = data.id;
      } else {
        fail('Playlist creation failed');
      }

      final track = PrivateTrackRef(
        id: 'track-to-delete',
        playlistId: playlistId,
        trackUri: 'spotify:track:xyz123',
        title: 'Ephemeral Track',
        artistName: 'Ephemeral Artist',
        albumTitle: 'Ephemeral Album',
        durationMs: 200000,
        sourceType: TrackSourceTypeEnum.spotify,
        sortOrder: 0,
        addedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      await repository.addTrackToPlaylist(playlistId: playlistId, trackRef: track);

      // Delete playlist
      final deleteResult = await repository.deletePlaylist(playlistId);
      expect(deleteResult, isA<VaultSuccess<void>>());

      // Verify playlist is gone
      final fetchResult = await repository.getPlaylistById(playlistId);
      expect(fetchResult, isA<VaultFailureResult<PrivatePlaylist>>());

      // Verify track references are also gone
      final rawTracks = await (database.select(database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(playlistId)))
          .get();
      expect(rawTracks.isEmpty, isTrue);
    });
  });

  group('VaultStorageRepository - Track Reference Management', () {
    test('adds tracks, recalculates cumulative duration, and respects sort order', () async {
      final createResult = await repository.createPlaylist(
        name: 'Audio Vault',
        description: 'Multi-track test',
      );

      final String playlistId;
      if (createResult case VaultSuccess(:final data)) {
        playlistId = data.id;
      } else {
        fail('Playlist creation failed');
      }

      final track1 = PrivateTrackRef(
        id: 'track-spotify-1',
        playlistId: playlistId,
        trackUri: 'spotify:track:111',
        title: 'Track One',
        artistName: 'Artist One',
        albumTitle: 'Album One',
        durationMs: 150000,
        sourceType: TrackSourceTypeEnum.spotify,
        sortOrder: 0,
        addedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      final track2 = PrivateTrackRef(
        id: 'track-local-2',
        playlistId: playlistId,
        trackUri: 'file:///vault_media/.nomedia/local_2.mp3',
        title: 'Local Track Two',
        artistName: 'Artist Two',
        albumTitle: 'Album Two',
        durationMs: 210000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/local_2.mp3',
        sortOrder: 1,
        addedAtEpochMs: DateTime.now().millisecondsSinceEpoch + 10,
      );

      final addResult1 = await repository.addTrackToPlaylist(
        playlistId: playlistId,
        trackRef: track1,
      );
      expect(addResult1, isA<VaultSuccess<void>>());

      final addResult2 = await repository.addTrackToPlaylist(
        playlistId: playlistId,
        trackRef: track2,
      );
      expect(addResult2, isA<VaultSuccess<void>>());

      final playlistResult = await repository.getPlaylistById(playlistId);
      if (playlistResult case VaultSuccess(:final data)) {
        expect(data.trackCount, equals(2));
        expect(data.totalDurationMs, equals(360000));
        expect(data.trackRefs[0].id, equals('track-spotify-1'));
        expect(data.trackRefs[0].title, equals('Track One'));
        expect(data.trackRefs[0].sourceType, equals(TrackSourceTypeEnum.spotify));
        expect(data.trackRefs[0].localRelativePath, isNull);

        expect(data.trackRefs[1].id, equals('track-local-2'));
        expect(data.trackRefs[1].title, equals('Local Track Two'));
        expect(data.trackRefs[1].sourceType, equals(TrackSourceTypeEnum.localSandbox));
        expect(data.trackRefs[1].localRelativePath, equals('vault_media/.nomedia/local_2.mp3'));
      }
    });

    test('removes track and re-indexes remaining tracks contiguously', () async {
      final createResult = await repository.createPlaylist(
        name: 'Removal Test',
        description: 'Test removal indexing',
      );

      final String playlistId;
      if (createResult case VaultSuccess(:final data)) {
        playlistId = data.id;
      } else {
        fail('Playlist creation failed');
      }

      for (int i = 0; i < 3; i++) {
        final track = PrivateTrackRef(
          id: 'track-$i',
          playlistId: playlistId,
          trackUri: 'spotify:track:$i',
          title: 'Track $i',
          artistName: 'Artist',
          albumTitle: 'Album',
          durationMs: 60000,
          sourceType: TrackSourceTypeEnum.spotify,
          sortOrder: i,
          addedAtEpochMs: DateTime.now().millisecondsSinceEpoch + i,
        );
        await repository.addTrackToPlaylist(playlistId: playlistId, trackRef: track);
      }

      // Remove middle track (track-1)
      final removeResult = await repository.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: 'track-1',
      );
      expect(removeResult, isA<VaultSuccess<void>>());

      final playlistResult = await repository.getPlaylistById(playlistId);
      if (playlistResult case VaultSuccess(:final data)) {
        expect(data.trackCount, equals(2));
        expect(data.trackRefs[0].id, equals('track-0'));
        expect(data.trackRefs[0].sortOrder, equals(0));
        expect(data.trackRefs[1].id, equals('track-2'));
        expect(data.trackRefs[1].sortOrder, equals(1));
      }
    });

    test('reorders tracks in playlist according to specified ID sequence', () async {
      final createResult = await repository.createPlaylist(
        name: 'Reorder Test',
        description: 'Test reordering sequence',
      );

      final String playlistId;
      if (createResult case VaultSuccess(:final data)) {
        playlistId = data.id;
      } else {
        fail('Playlist creation failed');
      }

      for (int i = 0; i < 3; i++) {
        final track = PrivateTrackRef(
          id: 'track-$i',
          playlistId: playlistId,
          trackUri: 'spotify:track:$i',
          title: 'Track $i',
          artistName: 'Artist',
          albumTitle: 'Album',
          durationMs: 60000,
          sourceType: TrackSourceTypeEnum.spotify,
          sortOrder: i,
          addedAtEpochMs: DateTime.now().millisecondsSinceEpoch + i,
        );
        await repository.addTrackToPlaylist(playlistId: playlistId, trackRef: track);
      }

      // Reorder to: track-2, track-0, track-1
      final reorderResult = await repository.reorderTracksInPlaylist(
        playlistId: playlistId,
        trackIdsInOrder: ['track-2', 'track-0', 'track-1'],
      );
      expect(reorderResult, isA<VaultSuccess<void>>());

      final playlistResult = await repository.getPlaylistById(playlistId);
      if (playlistResult case VaultSuccess(:final data)) {
        expect(data.trackRefs[0].id, equals('track-2'));
        expect(data.trackRefs[0].sortOrder, equals(0));
        expect(data.trackRefs[1].id, equals('track-0'));
        expect(data.trackRefs[1].sortOrder, equals(1));
        expect(data.trackRefs[2].id, equals('track-1'));
        expect(data.trackRefs[2].sortOrder, equals(2));
      }
    });
  });

  group('VaultStorageRepository - Gesture Template CRUD', () {
    test('saves and loads golden master gesture template', () async {
      final points = List.generate(
        64,
        (i) => GesturePoint(
          x: i * 2.5,
          y: i * 3.5,
          timestampMs: i * 16,
        ),
      );
      final rubine = <double>[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];
      final template = GestureTemplate(
        id: 'master_gesture',
        normalizedPoints: points,
        rubineFeatureVector: rubine,
        createdAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      final saveResult = await repository.saveGestureTemplate(template);
      expect(saveResult, isA<VaultSuccess<void>>());

      final loadResult = await repository.loadGestureTemplate();
      expect(loadResult, isA<VaultSuccess<GestureTemplate>>());

      if (loadResult case VaultSuccess(:final data)) {
        expect(data.id, equals('master_gesture'));
        expect(data.normalizedPoints.length, equals(64));
        expect(data.rubineFeatureVector.length, equals(7));
        expect(data.normalizedPoints.first.x, equals(0.0));
        expect(data.rubineFeatureVector[0], closeTo(0.1, 0.0001));
      }
    });

    test('returns VaultStorageFailure when no gesture template exists', () async {
      final loadResult = await repository.loadGestureTemplate();
      expect(loadResult, isA<VaultFailureResult<GestureTemplate>>());
    });
  });

  group('VaultStorageRepository - Monotonic Lockout Deadline & Restart Invariance', () {
    test('persists and retrieves lockout deadline unencrypted across simulated restarts', () async {
      const deadline = 184592000;
      await repository.persistLockoutDeadlineMs(deadline);

      // Verify deadline can be read directly
      final readDeadline = await repository.getPersistedLockoutDeadlineMs();
      expect(readDeadline, equals(deadline));

      // Simulate app restart with a fresh repository and locked session
      final lockedCrypto = MockNativeVaultCryptoBridge(
        hasMasterKey: true,
        isSessionUnlocked: false, // LOCKED
      );
      final restartRepository = VaultStorageRepository(
        database: database,
        cryptoBridge: lockedCrypto,
      );

      // Verify deadline is readable EVEN WHEN SESSION IS LOCKED
      final deadlineAfterRestart = await restartRepository.getPersistedLockoutDeadlineMs();
      expect(deadlineAfterRestart, equals(deadline));

      // Clear lockout deadline
      await restartRepository.clearPersistedLockoutDeadline();
      final deadlineCleared = await restartRepository.getPersistedLockoutDeadlineMs();
      expect(deadlineCleared, isNull);
    });
  });

  group('VaultStorageRepository - Tamper Detection & Hardware Security Invariants', () {
    test('fails gracefully when session is locked during sensitive media operations, while config rehydrates at rest', () async {
      final config = VaultConfig();
      await repository.saveVaultConfig(config);
      await repository.createPlaylist(name: 'Secret Playlist', description: 'Classified');

      // Lock session
      cryptoBridge.setSessionUnlocked(false);

      // Config rehydrates successfully at rest without session unlock (Dual-Tier KeyStore Invariant)
      final loadResult = await repository.loadVaultConfig();
      expect(loadResult, isA<VaultSuccess<VaultConfig>>());

      // Sensitive media operations strictly fail when session is locked
      final playlistResult = await repository.getPlaylists();
      expect(playlistResult, isA<VaultFailureResult<List<PrivatePlaylist>>>());
      if (playlistResult case VaultFailureResult(:final failure)) {
        expect(failure, isA<VaultCryptoFailure>());
        expect(failure.message, contains('locked'));
      }
    });

    test('fails gracefully with VaultCryptoFailure when ciphertext is tampered with', () async {
      final config = VaultConfig();
      await repository.saveVaultConfig(config);

      // Corrupt the encrypted payload in the database
      final row = await database.select(database.vaultConfigTable).getSingle();
      final corrupted = Uint8List.fromList(row.encryptedPayload);
      // Flip a bit in the ciphertext body
      corrupted[15] ^= 0xFF;

      await (database.update(database.vaultConfigTable)
            ..where((tbl) => tbl.id.equals('vault_config')))
          .write(
        VaultConfigTableCompanion(
          encryptedPayload: Value(corrupted),
        ),
      );

      final loadResult = await repository.loadVaultConfig();
      expect(loadResult, isA<VaultFailureResult<VaultConfig>>());
      if (loadResult case VaultFailureResult(:final failure)) {
        expect(failure, isA<VaultCryptoFailure>());
        expect(failure.message, contains('tampered'));
      }
    });
  });

  group('VaultStorageRepository - Atomic Purge Routine', () {
    test('atomically shreds all tables, invokes media hook, and destroys master key', () async {
      // Setup data across all tables
      await repository.saveVaultConfig(VaultConfig());
      final playlist = await repository.createPlaylist(name: 'To Purge', description: 'Desc');
      if (playlist case VaultSuccess(:final data)) {
        await repository.addTrackToPlaylist(
          playlistId: data.id,
          trackRef: PrivateTrackRef(
            id: 'purge-track',
            playlistId: data.id,
            trackUri: 'spotify:track:1',
            title: 'Track',
            artistName: 'Artist',
            albumTitle: 'Album',
            durationMs: 1000,
            sourceType: TrackSourceTypeEnum.spotify,
            sortOrder: 0,
            addedAtEpochMs: 100,
          ),
        );
      }
      await repository.persistLockoutDeadlineMs(999999);

      var mediaHookCalled = false;
      final purgeRepo = VaultStorageRepository(
        database: database,
        cryptoBridge: cryptoBridge,
        onShredMediaFiles: () async {
          mediaHookCalled = true;
        },
      );

      final purgeResult = await purgeRepo.purgeAllVaultData();
      expect(purgeResult, isA<VaultSuccess<void>>());
      expect(mediaHookCalled, isTrue);

      // Verify all tables are shredded
      final playlists = await database.select(database.vaultPlaylistsTable).get();
      expect(playlists.isEmpty, isTrue);

      final tracks = await database.select(database.vaultTrackRefsTable).get();
      expect(tracks.isEmpty, isTrue);

      final configs = await database.select(database.vaultConfigTable).get();
      expect(configs.isEmpty, isTrue);

      final templates = await database.select(database.vaultGestureTemplatesTable).get();
      expect(templates.isEmpty, isTrue);

      final deadlines = await database.select(database.vaultLockoutDeadlineTable).get();
      expect(deadlines.isEmpty, isTrue);

      // Verify master key is destroyed in crypto bridge
      final hasKey = await cryptoBridge.hasMasterKey();
      expect(hasKey, isFalse);
    });
  });
}
