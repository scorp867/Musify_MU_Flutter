import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:path/path.dart' as p;

/// Adversarial mock of [INativeVaultCryptoBridge] for empirical stress-testing.
///
/// Simulates native Android KeyStore TEE / StrongBox lifecycle:
/// - Generates 28-byte cryptographic envelopes: [12-byte IV + Ciphertext + 16-byte Tag].
/// - Enforces session locking and master key presence constraints.
/// - Validates AEAD authentication tag integrity.
class AdversarialMockCryptoBridge implements INativeVaultCryptoBridge {
  bool _hasMasterKey;
  bool _isSessionUnlocked;

  int destroyMasterKeyCallCount = 0;
  int lockSessionCallCount = 0;
  int unlockSessionCallCount = 0;
  int encryptCallCount = 0;
  int decryptCallCount = 0;

  AdversarialMockCryptoBridge({
    bool hasMasterKey = true,
    bool isSessionUnlocked = true,
  })  : _hasMasterKey = hasMasterKey,
        _isSessionUnlocked = isSessionUnlocked;

  bool get isSessionUnlocked => _isSessionUnlocked;

  @override
  Future<bool> hasMasterKey() async => _hasMasterKey;

  @override
  Future<void> generateMasterKey() async {
    _hasMasterKey = true;
  }

  @override
  Future<void> unlockSession() async {
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key not provisioned in Android KeyStore.');
    }
    _isSessionUnlocked = true;
    unlockSessionCallCount++;
  }

  @override
  Future<void> lockSession() async {
    _isSessionUnlocked = false;
    lockSessionCallCount++;
  }

  @override
  Future<void> destroyMasterKey() async {
    _hasMasterKey = false;
    _isSessionUnlocked = false;
    destroyMasterKeyCallCount++;
  }

  @override
  Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
    required String cancelButton,
  }) async {
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key not provisioned in Android KeyStore.');
    }
    return true;
  }

  @override
  Future<Uint8List> encryptPayload(Uint8List plaintext) async {
    encryptCallCount++;
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key is not provisioned in Android KeyStore.');
    }
    if (!_isSessionUnlocked) {
      throw const VaultCryptoFailure(
        'Vault session is locked. Complete PIN or biometric authentication first.',
      );
    }
    if (plaintext.isEmpty) {
      throw const VaultValidationFailure('Plaintext payload must not be empty.');
    }

    // 28-byte envelope: [12-byte IV (0xAA) + (plaintext ^ 0x5A) + 16-byte Tag (0xBB)]
    final iv = Uint8List(12)..fillRange(0, 12, 0xAA);
    final tag = Uint8List(16)..fillRange(0, 16, 0xBB);
    final ciphertext = Uint8List(plaintext.length);
    for (int i = 0; i < plaintext.length; i++) {
      ciphertext[i] = plaintext[i] ^ 0x5A;
    }

    final envelope = Uint8List(12 + ciphertext.length + 16);
    envelope.setRange(0, 12, iv);
    envelope.setRange(12, 12 + ciphertext.length, ciphertext);
    envelope.setRange(12 + ciphertext.length, envelope.length, tag);
    return envelope;
  }

  @override
  Future<Uint8List> decryptPayload(Uint8List ciphertext) async {
    decryptCallCount++;
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key is not provisioned in Android KeyStore.');
    }
    if (!_isSessionUnlocked) {
      throw const VaultCryptoFailure(
        'Vault session is locked. Complete PIN or biometric authentication first.',
      );
    }
    if (ciphertext.length < 28) {
      throw const VaultValidationFailure('Ciphertext envelope smaller than 28 bytes.');
    }

    // Validate 16-byte AEAD tag (must match 0xBB)
    final tagOffset = ciphertext.length - 16;
    for (int i = tagOffset; i < ciphertext.length; i++) {
      if (ciphertext[i] != 0xBB) {
        throw const VaultCryptoFailure(
          'Decryption authentication failed: corrupted ciphertext or tampered authentication tag.',
        );
      }
    }

    final cipherLen = ciphertext.length - 28;
    final plaintext = Uint8List(cipherLen);
    for (int i = 0; i < cipherLen; i++) {
      plaintext[i] = ciphertext[12 + i] ^ 0x5A;
    }
    return plaintext;
  }
}

/// Helper generating a deterministic golden master [GestureTemplate] with 64 points & 7 features.
GestureTemplate createTestGestureTemplate() {
  final points = List<GesturePoint>.generate(
    64,
    (index) => GesturePoint(
      x: (index * 2.5) % 100.0,
      y: (index * 3.7) % 100.0,
      timestampMs: 1000 + (index * 16),
    ),
  );
  final rubine = <double>[1.2, 0.85, 3.14, 0.42, 2.71, 0.99, 1.41];
  return GestureTemplate(
    id: 'master_gesture',
    normalizedPoints: points,
    rubineFeatureVector: rubine,
    createdAtEpochMs: 1731180000000,
  );
}

void main() {
  group('Adversarial Scenario 1: Lockout Persistence & Simulated Process Restart', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vault_adv_restart_');
      dbFile = File(p.join(tempDir.path, 'vault_metadata.sqlite'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'EMPIRICAL-1.1: Lockout deadline survives full database teardown, simulated process restart, '
      'and queries cleanly while crypto session is completely locked and unprovisioned',
      () async {
        final mockCrypto1 = AdversarialMockCryptoBridge(
          hasMasterKey: true,
          isSessionUnlocked: true,
        );
        final db1 = VaultDatabase.forTesting(NativeDatabase(dbFile));
        final repo1 = VaultStorageRepository(
          database: db1,
          cryptoBridge: mockCrypto1,
        );

        const targetDeadline = 1731189999000;

        // Step 1: Persist lockout deadline
        await repo1.persistLockoutDeadlineMs(targetDeadline);

        // Step 2: Immediate query validation
        final immediateDeadline = await repo1.getPersistedLockoutDeadlineMs();
        expect(immediateDeadline, equals(targetDeadline));

        // Step 3: Simulate abrupt process kill and database connection closing
        await db1.close();

        // Step 4: Re-initialize fresh environment (simulating process boot)
        // Master key is NOT provisioned and session is locked
        final mockCrypto2 = AdversarialMockCryptoBridge(
          hasMasterKey: false,
          isSessionUnlocked: false,
        );
        expect(await mockCrypto2.hasMasterKey(), isFalse);
        expect(mockCrypto2.isSessionUnlocked, isFalse);

        final db2 = VaultDatabase.forTesting(NativeDatabase(dbFile));
        final repo2 = VaultStorageRepository(
          database: db2,
          cryptoBridge: mockCrypto2,
        );

        // Step 5: Query persisted deadline WITHOUT unlocking session or master key
        final recoveredDeadline = await repo2.getPersistedLockoutDeadlineMs();
        expect(
          recoveredDeadline,
          equals(targetDeadline),
          reason: 'Lockout deadline must be readable before crypto session is unlocked.',
        );

        // Step 6: Overwrite deadline to a new cooldown period
        const updatedDeadline = 1731195555000;
        await repo2.persistLockoutDeadlineMs(updatedDeadline);

        final readUpdated = await repo2.getPersistedLockoutDeadlineMs();
        expect(readUpdated, equals(updatedDeadline));

        // Step 7: Clear persisted deadline
        await repo2.clearPersistedLockoutDeadline();
        final clearedDeadline = await repo2.getPersistedLockoutDeadlineMs();
        expect(clearedDeadline, isNull);

        // Step 8: Simulate second process restart and verify null persistence
        await db2.close();

        final mockCrypto3 = AdversarialMockCryptoBridge(
          hasMasterKey: false,
          isSessionUnlocked: false,
        );
        final db3 = VaultDatabase.forTesting(NativeDatabase(dbFile));
        final repo3 = VaultStorageRepository(
          database: db3,
          cryptoBridge: mockCrypto3,
        );

        final postRestartCleared = await repo3.getPersistedLockoutDeadlineMs();
        expect(
          postRestartCleared,
          isNull,
          reason: 'Cleared lockout deadline must remain null across process restarts.',
        );

        await db3.close();
      },
    );
  });

  group('Adversarial Scenario 2: Atomic Purge Under Adverse Conditions', () {
    late VaultDatabase db;
    late AdversarialMockCryptoBridge mockCrypto;
    late int shredHookCallCount;
    late VaultStorageRepository repo;

    setUp(() async {
      db = VaultDatabase.forTesting(NativeDatabase.memory());
      mockCrypto = AdversarialMockCryptoBridge(
        hasMasterKey: true,
        isSessionUnlocked: true,
      );
      shredHookCallCount = 0;
      repo = VaultStorageRepository(
        database: db,
        cryptoBridge: mockCrypto,
        onShredMediaFiles: () async {
          shredHookCallCount++;
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'EMPIRICAL-2.1: Atomic purge wipes all 5 tables, executes media shredding hook, destroys KeyStore master key, '
      'and leaves repository returning typed failures/empty lists with zero unhandled exceptions',
      () async {
        // Step 1: Populate all 5 tables
        // 1.1 Playlists
        final p1Result = await repo.createPlaylist(
          name: 'Top Secret Playlist 1',
          description: 'Classified track list',
          coverUri: 'file:///vault_data/covers/c1.jpg',
        );
        expect(p1Result, isA<VaultSuccess<PrivatePlaylist>>());
        final p1 = (p1Result as VaultSuccess<PrivatePlaylist>).data;

        final p2Result = await repo.createPlaylist(
          name: 'Top Secret Playlist 2',
          description: 'Classified track list 2',
        );
        expect(p2Result, isA<VaultSuccess<PrivatePlaylist>>());
        final p2 = (p2Result as VaultSuccess<PrivatePlaylist>).data;

        // 1.2 Track references
        await repo.addTrackToPlaylist(
          playlistId: p1.id,
          trackRef: PrivateTrackRef(
            id: 'track-p1-1',
            playlistId: p1.id,
            trackUri: 'spotify:track:p1t1',
            title: 'Operation Omega',
            artistName: 'Agent Zero',
            albumTitle: 'Redacted',
            durationMs: 240000,
            sourceType: TrackSourceTypeEnum.spotify,
            sortOrder: 0,
            addedAtEpochMs: 1731180001000,
          ),
        );
        await repo.addTrackToPlaylist(
          playlistId: p1.id,
          trackRef: PrivateTrackRef(
            id: 'track-p1-2',
            playlistId: p1.id,
            trackUri: 'file:///media/t2.mp3',
            title: 'Black Box',
            artistName: 'Shadow',
            albumTitle: 'Redacted 2',
            durationMs: 180000,
            sourceType: TrackSourceTypeEnum.localSandbox,
            localRelativePath: 'vault_media/.nomedia/track-p1-2.mp3',
            sortOrder: 1,
            addedAtEpochMs: 1731180002000,
          ),
        );
        await repo.addTrackToPlaylist(
          playlistId: p2.id,
          trackRef: PrivateTrackRef(
            id: 'track-p2-1',
            playlistId: p2.id,
            trackUri: 'spotify:track:p2t1',
            title: 'Silent Signal',
            artistName: 'Cipher',
            albumTitle: 'Stealth',
            durationMs: 210000,
            sourceType: TrackSourceTypeEnum.spotify,
            sortOrder: 0,
            addedAtEpochMs: 1731180003000,
          ),
        );

        // 1.3 Config
        final config = VaultConfig(
          decoyTitle: 'System Decoy Title',
          decoyArtist: 'Decoy Artist',
          decoyAlbum: 'Decoy Album',
        );
        await repo.saveVaultConfig(config);

        // 1.4 Golden gesture template
        final gestureTemplate = createTestGestureTemplate();
        await repo.saveGestureTemplate(gestureTemplate);

        // 1.5 Lockout deadline
        await repo.persistLockoutDeadlineMs(1731199999000);

        // Verify pre-purge table row counts
        expect((await db.select(db.vaultPlaylistsTable).get()).length, equals(2));
        expect((await db.select(db.vaultTrackRefsTable).get()).length, equals(3));
        expect((await db.select(db.vaultConfigTable).get()).length, equals(1));
        expect((await db.select(db.vaultGestureTemplatesTable).get()).length, equals(1));
        expect((await db.select(db.vaultLockoutDeadlineTable).get()).length, equals(1));
        expect(await mockCrypto.hasMasterKey(), isTrue);
        expect(mockCrypto.isSessionUnlocked, isTrue);

        // Step 2: Trigger Atomic Purge
        final purgeResult = await repo.purgeAllVaultData();
        expect(purgeResult, isA<VaultSuccess<void>>());

        // Step 3: Verify all 5 tables are strictly empty
        expect(
          await db.select(db.vaultPlaylistsTable).get(),
          isEmpty,
          reason: 'vault_playlists table must be completely empty after purge.',
        );
        expect(
          await db.select(db.vaultTrackRefsTable).get(),
          isEmpty,
          reason: 'vault_track_refs table must be completely empty after purge.',
        );
        expect(
          await db.select(db.vaultConfigTable).get(),
          isEmpty,
          reason: 'vault_config table must be completely empty after purge.',
        );
        expect(
          await db.select(db.vaultGestureTemplatesTable).get(),
          isEmpty,
          reason: 'vault_gesture_templates table must be completely empty after purge.',
        );
        expect(
          await db.select(db.vaultLockoutDeadlineTable).get(),
          isEmpty,
          reason: 'vault_lockout_deadline table must be completely empty after purge.',
        );

        // Step 4: Verify crypto bridge and hook side-effects
        expect(await mockCrypto.hasMasterKey(), isFalse);
        expect(mockCrypto.isSessionUnlocked, isFalse);
        expect(mockCrypto.destroyMasterKeyCallCount, equals(1));
        expect(shredHookCallCount, equals(1));

        // Step 5: Verify post-purge read operations return typed failures or empty lists without unhandled exceptions
        final postConfig = await repo.loadVaultConfig();
        expect(postConfig, isA<VaultFailureResult<VaultConfig>>());
        expect((postConfig as VaultFailureResult<VaultConfig>).failure, isA<VaultStorageFailure>());

        final postGesture = await repo.loadGestureTemplate();
        expect(postGesture, isA<VaultFailureResult<GestureTemplate>>());
        expect((postGesture as VaultFailureResult<GestureTemplate>).failure, isA<VaultStorageFailure>());

        final postPlaylist = await repo.getPlaylistById(p1.id);
        expect(postPlaylist, isA<VaultFailureResult<PrivatePlaylist>>());
        expect((postPlaylist as VaultFailureResult<PrivatePlaylist>).failure, isA<VaultStorageFailure>());

        final postPlaylists = await repo.getPlaylists();
        expect(postPlaylists, isA<VaultSuccess<List<PrivatePlaylist>>>());
        expect((postPlaylists as VaultSuccess<List<PrivatePlaylist>>).data, isEmpty);

        final postDeadline = await repo.getPersistedLockoutDeadlineMs();
        expect(postDeadline, isNull);
      },
    );

    test('EMPIRICAL-2.2: Purge is idempotent when executed on an already empty database', () async {
      // First purge
      final purge1 = await repo.purgeAllVaultData();
      expect(purge1, isA<VaultSuccess<void>>());

      // Second purge
      final purge2 = await repo.purgeAllVaultData();
      expect(purge2, isA<VaultSuccess<void>>());
      expect(shredHookCallCount, equals(2));
      expect(mockCrypto.destroyMasterKeyCallCount, equals(2));
    });

    test(
      'EMPIRICAL-2.3: Adverse condition — media shredding hook failure is cleanly captured and returned as VaultStorageFailure',
      () async {
        final failingRepo = VaultStorageRepository(
          database: db,
          cryptoBridge: mockCrypto,
          onShredMediaFiles: () async {
            throw const FileSystemException('Access denied while shredding isolated media');
          },
        );

        final purgeResult = await failingRepo.purgeAllVaultData();
        expect(purgeResult, isA<VaultFailureResult<void>>());
        final failure = (purgeResult as VaultFailureResult<void>).failure;
        expect(failure, isA<VaultStorageFailure>());
        expect(failure.message, contains('Failed to purge vault data'));
      },
    );
  });

  group('Adversarial Scenario 3: Locked Session Protection & Data Leakage Defense', () {
    late VaultDatabase db;
    late AdversarialMockCryptoBridge mockCrypto;
    late VaultStorageRepository repo;
    late String createdPlaylistId;

    setUp(() async {
      db = VaultDatabase.forTesting(NativeDatabase.memory());
      mockCrypto = AdversarialMockCryptoBridge(
        hasMasterKey: true,
        isSessionUnlocked: true,
      );
      repo = VaultStorageRepository(
        database: db,
        cryptoBridge: mockCrypto,
      );

      // Populate initial data while unlocked
      final pResult = await repo.createPlaylist(
        name: 'Top Secret Playlist Alpha',
        description: 'Contains highly sensitive recordings',
      );
      expect(pResult, isA<VaultSuccess<PrivatePlaylist>>());
      createdPlaylistId = (pResult as VaultSuccess<PrivatePlaylist>).data.id;

      await repo.addTrackToPlaylist(
        playlistId: createdPlaylistId,
        trackRef: PrivateTrackRef(
          id: 'track-alpha-1',
          playlistId: createdPlaylistId,
          trackUri: 'spotify:track:alpha',
          title: 'Covert Track Alpha',
          artistName: 'Secret Agent 007',
          albumTitle: 'Redacted Mission',
          durationMs: 300000,
          sourceType: TrackSourceTypeEnum.spotify,
          sortOrder: 0,
          addedAtEpochMs: 1731180005000,
        ),
      );

      await repo.saveVaultConfig(VaultConfig());
      await repo.saveGestureTemplate(createTestGestureTemplate());
      await repo.persistLockoutDeadlineMs(1731198888000);

      // NOW LOCK SESSION
      await mockCrypto.lockSession();
      expect(mockCrypto.isSessionUnlocked, isFalse);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'EMPIRICAL-3.1: getPlaylists() under locked session fails safely without unhandled exceptions or plaintext leakage',
      () async {
        final result = await repo.getPlaylists();
        expect(
          result,
          isA<VaultFailureResult<List<PrivatePlaylist>>>(),
          reason: 'Decryption must fail when session is locked.',
        );
        final failure = (result as VaultFailureResult<List<PrivatePlaylist>>).failure;
        expect(failure, anyOf(isA<VaultCryptoFailure>(), isA<VaultStorageFailure>()));

        // Verify zero sensitive data is leaked into error message
        expect(failure.message, isNot(contains('Top Secret Playlist Alpha')));
        expect(failure.message, isNot(contains('Covert Track Alpha')));
      },
    );

    test(
      'EMPIRICAL-3.2: createPlaylist() under locked session fails safely and writes nothing to storage',
      () async {
        final preCount = (await db.select(db.vaultPlaylistsTable).get()).length;

        final result = await repo.createPlaylist(
          name: 'Intruder Playlist Attempt',
          description: 'Should fail encryption',
        );

        expect(
          result,
          isA<VaultFailureResult<PrivatePlaylist>>(),
          reason: 'Encryption must fail when session is locked.',
        );
        final failure = (result as VaultFailureResult<PrivatePlaylist>).failure;
        expect(failure, anyOf(isA<VaultCryptoFailure>(), isA<VaultStorageFailure>()));

        final postCount = (await db.select(db.vaultPlaylistsTable).get()).length;
        expect(postCount, equals(preCount), reason: 'No rows should be inserted on encryption failure.');
      },
    );

    test(
      'EMPIRICAL-3.3: loadVaultConfig() under locked session fails safely without crashing',
      () async {
        final result = await repo.loadVaultConfig();
        expect(result, isA<VaultFailureResult<VaultConfig>>());
        final failure = (result as VaultFailureResult<VaultConfig>).failure;
        expect(failure, anyOf(isA<VaultCryptoFailure>(), isA<VaultStorageFailure>()));
      },
    );

    test(
      'EMPIRICAL-3.4: getPlaylistById() under locked session fails safely without leaking track metadata',
      () async {
        final result = await repo.getPlaylistById(createdPlaylistId);
        expect(result, isA<VaultFailureResult<PrivatePlaylist>>());
        final failure = (result as VaultFailureResult<PrivatePlaylist>).failure;
        expect(failure, anyOf(isA<VaultCryptoFailure>(), isA<VaultStorageFailure>()));
        expect(failure.message, isNot(contains('Covert Track Alpha')));
      },
    );

    test(
      'EMPIRICAL-3.5: loadGestureTemplate() under locked session fails safely without leaking template coordinates',
      () async {
        final result = await repo.loadGestureTemplate();
        expect(result, isA<VaultFailureResult<GestureTemplate>>());
        final failure = (result as VaultFailureResult<GestureTemplate>).failure;
        expect(failure, anyOf(isA<VaultCryptoFailure>(), isA<VaultStorageFailure>()));
      },
    );

    test(
      'EMPIRICAL-3.6: saveVaultConfig() and saveGestureTemplate() under locked session reject modifications cleanly',
      () async {
        final saveConfigResult = await repo.saveVaultConfig(
          VaultConfig(decoyTitle: 'Malicious Update'),
        );
        expect(saveConfigResult, isA<VaultFailureResult<void>>());

        final saveGestureResult = await repo.saveGestureTemplate(createTestGestureTemplate());
        expect(saveGestureResult, isA<VaultFailureResult<void>>());
      },
    );

    test(
      'EMPIRICAL-3.7: addTrackToPlaylist() and updatePlaylist() under locked session reject mutations cleanly',
      () async {
        final addTrackResult = await repo.addTrackToPlaylist(
          playlistId: createdPlaylistId,
          trackRef: PrivateTrackRef(
            id: 'unauthorized-track',
            playlistId: createdPlaylistId,
            trackUri: 'spotify:track:unauth',
            title: 'Unauthorized',
            artistName: 'Intruder',
            albumTitle: 'Exploit',
            durationMs: 120000,
            sourceType: TrackSourceTypeEnum.spotify,
            sortOrder: 1,
            addedAtEpochMs: 1731180009000,
          ),
        );
        expect(addTrackResult, isA<VaultFailureResult<void>>());

        final updatePlaylistResult = await repo.updatePlaylist(
          PrivatePlaylist(
            id: createdPlaylistId,
            name: 'Tampered Name',
            description: 'Tampered Desc',
            totalDurationMs: 300000,
            createdAtEpochMs: 1731180000000,
            updatedAtEpochMs: 1731180010000,
            trackRefs: const [],
          ),
        );
        expect(updatePlaylistResult, isA<VaultFailureResult<void>>());
      },
    );

    test(
      'EMPIRICAL-3.8: Lockout deadline query remains accessible while session is locked, proving unencrypted architectural partition',
      () async {
        final deadline = await repo.getPersistedLockoutDeadlineMs();
        expect(
          deadline,
          equals(1731198888000),
          reason: 'Lockout deadline must be readable even when session is locked.',
        );
      },
    );
  });

  group('Adversarial Scenario 4: Tamper Detection & Corrupted Envelope Hardening', () {
    late VaultDatabase db;
    late AdversarialMockCryptoBridge mockCrypto;
    late VaultStorageRepository repo;

    setUp(() {
      db = VaultDatabase.forTesting(NativeDatabase.memory());
      mockCrypto = AdversarialMockCryptoBridge(
        hasMasterKey: true,
        isSessionUnlocked: true,
      );
      repo = VaultStorageRepository(
        database: db,
        cryptoBridge: mockCrypto,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'EMPIRICAL-4.1: Tampered AEAD authentication tag in playlist table triggers AEAD verification failure cleanly',
      () async {
        // Create valid playlist
        final pResult = await repo.createPlaylist(name: 'Valid Name', description: 'Valid Desc');
        expect(pResult, isA<VaultSuccess<PrivatePlaylist>>());
        final p = (pResult as VaultSuccess<PrivatePlaylist>).data;

        // Directly mutate database with tampered AEAD tag (corrupt the last 16 bytes of encryptedTitle)
        final entry = await (db.select(db.vaultPlaylistsTable)..where((tbl) => tbl.id.equals(p.id))).getSingle();
        final corruptedPayload = Uint8List.fromList(entry.encryptedTitle);
        // Flip byte in tag region
        corruptedPayload[corruptedPayload.length - 1] ^= 0xFF;

        await (db.update(db.vaultPlaylistsTable)..where((tbl) => tbl.id.equals(p.id))).write(
          VaultPlaylistsTableCompanion(
            encryptedTitle: Value(corruptedPayload),
          ),
        );

        // Attempt retrieval
        final readResult = await repo.getPlaylistById(p.id);
        expect(readResult, isA<VaultFailureResult<PrivatePlaylist>>());
        final failure = (readResult as VaultFailureResult<PrivatePlaylist>).failure;
        expect(failure, anyOf(isA<VaultCryptoFailure>(), isA<VaultStorageFailure>()));
        expect(failure.message, contains('corrupted'));
      },
    );

    test(
      'EMPIRICAL-4.2: Truncated ciphertext (< 28 bytes envelope) in vault_config triggers validation failure cleanly',
      () async {
        // Insert truncated 10-byte blob directly into vault_config
        await db.into(db.vaultConfigTable).insert(
          VaultConfigTableCompanion(
            id: const Value('vault_config'),
            encryptedPayload: Value(Uint8List(10)),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

        final result = await repo.loadVaultConfig();
        expect(result, isA<VaultFailureResult<VaultConfig>>());
        final failure = (result as VaultFailureResult<VaultConfig>).failure;
        expect(failure, anyOf(isA<VaultValidationFailure>(), isA<VaultStorageFailure>()));
      },
    );

    test(
      'EMPIRICAL-4.3: Malformed JSON within valid ciphertext envelope fails DTO boundary check cleanly',
      () async {
        // Encrypt invalid JSON string
        final invalidJsonPayload = await mockCrypto.encryptPayload(
          Uint8List.fromList(utf8.encode('NOT_JSON_OBJECT')),
        );

        await db.into(db.vaultConfigTable).insert(
          VaultConfigTableCompanion(
            id: const Value('vault_config'),
            encryptedPayload: Value(invalidJsonPayload),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

        final result = await repo.loadVaultConfig();
        expect(result, isA<VaultFailureResult<VaultConfig>>());
        final failure = (result as VaultFailureResult<VaultConfig>).failure;
        expect(failure, isA<VaultStorageFailure>());
        expect(failure.message, contains('FormatException'));
      },
    );
  });
}
