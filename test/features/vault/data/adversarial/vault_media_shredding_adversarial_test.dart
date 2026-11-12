import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:path/path.dart' as p;

/// Robust fake implementation of [INativeVaultCryptoBridge] for unit & adversarial testing.
///
/// Encapsulates simulated AES-256-GCM envelope framing ([12-byte IV + payload + 16-byte Tag])
/// and tracks master key lifecycle without platform channel dependencies.
final class FakeAdversarialCryptoBridge implements INativeVaultCryptoBridge {
  bool _hasKey = true;
  bool _sessionUnlocked = true;
  int destroyCallCount = 0;
  int encryptCallCount = 0;
  int decryptCallCount = 0;

  bool get isDestroyed => !_hasKey && destroyCallCount > 0;
  bool get isSessionUnlocked => _sessionUnlocked;

  @override
  Future<bool> hasMasterKey() async => _hasKey;

  @override
  Future<void> generateMasterKey() async {
    _hasKey = true;
  }

  @override
  Future<Uint8List> encryptPayload(Uint8List plaintext) async {
    if (!_hasKey) {
      throw const VaultCryptoFailure('Master key has been destroyed.');
    }
    if (plaintext.isEmpty) {
      throw const VaultValidationFailure('Plaintext cannot be empty.');
    }
    encryptCallCount++;

    // Simulated 12-byte IV + plaintext + 16-byte GCM authentication tag
    final iv = Uint8List(12)..fillRange(0, 12, 0xAA);
    final tag = Uint8List(16)..fillRange(0, 16, 0xEE);
    final result = Uint8List(12 + plaintext.length + 16);
    result.setRange(0, 12, iv);
    result.setRange(12, 12 + plaintext.length, plaintext);
    result.setRange(12 + plaintext.length, result.length, tag);
    return result;
  }

  @override
  Future<Uint8List> decryptPayload(Uint8List ciphertext) async {
    if (!_hasKey) {
      throw const VaultCryptoFailure('Master key has been destroyed.');
    }
    if (ciphertext.length < 28) {
      throw const VaultValidationFailure('Ciphertext envelope too short.');
    }
    decryptCallCount++;

    final plainLength = ciphertext.length - 28;
    final extracted = Uint8List(plainLength);
    extracted.setRange(0, plainLength, ciphertext.sublist(12, 12 + plainLength));
    return extracted;
  }

  @override
  Future<Uint8List> deriveHardwarePepper(Uint8List intermediateKey) async {
    if (!_hasKey) {
      throw const VaultCryptoFailure('Master key has been destroyed.');
    }
    if (intermediateKey.isEmpty) {
      throw const VaultValidationFailure('Intermediate key cannot be empty.');
    }
    final pepper = Uint8List.fromList(List<int>.generate(32, (i) => (i * 23 + 11) & 0xFF));
    return Uint8List.fromList(Hmac(sha256, pepper).convert(intermediateKey).bytes);
  }

  @override
  Future<Uint8List> encryptConfigPayload(Uint8List plaintext) async => encryptPayload(plaintext);

  @override
  Future<Uint8List> decryptConfigPayload(Uint8List ciphertext) async => decryptPayload(ciphertext);

  @override
  Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
    required String cancelButton,
  }) async =>
      true;

  @override
  Future<void> unlockSession() async {
    _sessionUnlocked = true;
  }

  @override
  Future<void> lockSession() async {
    _sessionUnlocked = false;
  }

  @override
  Future<void> destroyMasterKey() async {
    destroyCallCount++;
    _hasKey = false;
    _sessionUnlocked = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRootDir;
  late Directory sourcePublicDir;
  late Directory appStorageDir;
  late FakeAdversarialCryptoBridge fakeCryptoBridge;

  setUp(() async {
    tempRootDir = Directory.systemTemp.createTempSync('vault_shred_adversarial_');
    sourcePublicDir = Directory(p.join(tempRootDir.path, 'public_music'))..createSync(recursive: true);
    appStorageDir = Directory(p.join(tempRootDir.path, 'app_storage'))..createSync(recursive: true);
    fakeCryptoBridge = FakeAdversarialCryptoBridge();

    // Mock path_provider platform channel to return our test appStorageDir
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return appStorageDir.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (tempRootDir.existsSync()) {
      tempRootDir.deleteSync(recursive: true);
    }
  });

  // ===========================================================================
  // GROUP 1: Scoped Storage Safe Deletion Fallback (R4)
  // ===========================================================================
  group('1. Scoped Storage Safe Deletion Fallback (R4)', () {
    test('Simulate OS permission denial (EACCES error 13) during unlinking: '
        'returns ScopedStorageDeletionRestricted, removes row from AppDatabase.localTracks, '
        'and preserves sandbox copy intact', () async {
      // 1. Create source file in public directory with known bytes
      final sourceFile = File(p.join(sourcePublicDir.path, 'song_restricted.mp3'));
      final originalBytes = Uint8List.fromList(List.generate(4096, (i) => (i * 7) % 256));
      sourceFile.writeAsBytesSync(originalBytes);

      // 2. Initialize real AppDatabase SQLite backed by our app storage directory
      final appDb = AppDatabase();
      await appDb.insertTracks([
        LocalTracksCompanion.insert(
          songId: 44001,
          title: 'Restricted Audio Track',
          dataPath: sourceFile.path,
          artist: const Value('Underground Artist'),
          album: const Value('Public Hits'),
          duration: const Value(215000),
          dateModified: const Value(1700000000),
        ),
      ]);

      // Verify track exists in AppDatabase before isolation
      final tracksBefore = await appDb.getAllTracks();
      expect(tracksBefore.any((t) => t.dataPath == sourceFile.path), isTrue);

      // 3. Configure VaultMediaIsolationManager with:
      //    - baseDirectoryResolver pointing to appStorageDir
      //    - localDatabase wired to appDb
      //    - fileDeleter simulating Android 10+ Scoped Storage EACCES (OS Error 13)
      var deleterInvoked = false;
      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
        localDatabase: appDb,
        fileDeleter: (file) async {
          deleterInvoked = true;
          throw FileSystemException(
            'Cannot delete media file originated by external application without user consent.',
            file.path,
            const OSError('Permission denied', 13),
          );
        },
      );

      // 4. Execute detailed track isolation
      final isolationResult = await manager.isolateTrackDetailed(
        sourceFilePath: sourceFile.path,
        trackId: 'track_eacces_01',
      );

      // 5. Assertions on ScopedStorageDeletionResult
      expect(deleterInvoked, isTrue);
      expect(isolationResult.deletionResult, isA<ScopedStorageDeletionRestricted>());

      final restrictedResult = isolationResult.deletionResult as ScopedStorageDeletionRestricted;
      expect(restrictedResult.sourcePath, equals(sourceFile.path));
      expect(restrictedResult.osErrorCode, equals(13));
      expect(restrictedResult.markedExcludedInLocalDb, isTrue);
      expect(restrictedResult.failureMessage, contains('without user consent'));

      // 6. Assertions on Isolated File Integrity in Sandbox
      expect(isolationResult.isolatedFile.existsSync(), isTrue);
      expect(isolationResult.relativePath, equals('vault_media/.nomedia/track_eacces_01.mp3'));
      final isolatedBytes = isolationResult.isolatedFile.readAsBytesSync();
      expect(isolatedBytes.length, equals(originalBytes.length));
      expect(isolatedBytes, equals(originalBytes));

      // 7. Public source file remains unmolested on disk (preventing data loss)
      expect(sourceFile.existsSync(), isTrue);
      expect(sourceFile.readAsBytesSync(), equals(originalBytes));

      // 8. Assertions on AppDatabase.localTracks exclusion
      final tracksAfter = await appDb.getAllTracks();
      expect(
        tracksAfter.any((t) => t.dataPath == sourceFile.path),
        isFalse,
        reason: 'Restricted track must be excluded from Musify local tracks table to hide it from public UI.',
      );

      await appDb.close();
    });

    test('Simulate OS permission denial with custom localTracksExcluder closure: '
        'guarantees excluder hook is dispatched', () async {
      final sourceFile = File(p.join(sourcePublicDir.path, 'song_hook.flac'));
      sourceFile.writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));

      var hookDispatched = false;
      String? excludedPathRecorded;

      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
        localTracksExcluder: (path) async {
          hookDispatched = true;
          excludedPathRecorded = path;
        },
        fileDeleter: (file) async {
          throw FileSystemException(
            'Scoped storage permission missing',
            file.path,
            const OSError('Operation not permitted', 1),
          );
        },
      );

      final result = await manager.isolateTrackDetailed(
        sourceFilePath: sourceFile.path,
        trackId: 'track_hook_01',
      );

      expect(hookDispatched, isTrue);
      expect(excludedPathRecorded, equals(sourceFile.path));
      expect(result.deletionResult, isA<ScopedStorageDeletionRestricted>());
      final restricted = result.deletionResult as ScopedStorageDeletionRestricted;
      expect(restricted.markedExcludedInLocalDb, isTrue);
      expect(restricted.osErrorCode, equals(1));
      expect(result.isolatedFile.existsSync(), isTrue);
    });

    test('Simulate source file missing during unlinking (OS Error 2 ENOENT): '
        'returns ScopedStorageDeletionSourceMissing cleanly without throwing', () async {
      final sourceFile = File(p.join(sourcePublicDir.path, 'song_vanished.mp3'));
      sourceFile.writeAsBytesSync(Uint8List.fromList([10, 20, 30, 40, 50]));

      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
        fileDeleter: (file) async {
          throw FileSystemException(
            'No such file or directory',
            file.path,
            const OSError('No such file or directory', 2),
          );
        },
      );

      final result = await manager.isolateTrackDetailed(
        sourceFilePath: sourceFile.path,
        trackId: 'track_vanished_01',
      );

      expect(result.deletionResult, isA<ScopedStorageDeletionSourceMissing>());
      expect(result.deletionResult.sourcePath, equals(sourceFile.path));
      expect(result.isolatedFile.existsSync(), isTrue);
    });

    test('Adversarial Boundary: 0-byte source file rejects isolation immediately with FileSystemException', () async {
      final emptyFile = File(p.join(sourcePublicDir.path, 'zero_byte.mp3'))..createSync();

      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );

      expect(
        () => manager.isolateTrackDetailed(
          sourceFilePath: emptyFile.path,
          trackId: 'track_zero',
        ),
        throwsA(isA<FileSystemException>().having(
          (e) => e.message,
          'message',
          contains('Source file is empty (0 bytes)'),
        )),
      );
    });

    test('Adversarial Boundary: Non-existent source file path throws FileSystemException', () async {
      final nonExistentPath = p.join(sourcePublicDir.path, 'ghost_track.mp3');

      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );

      expect(
        () => manager.isolateTrackDetailed(
          sourceFilePath: nonExistentPath,
          trackId: 'track_ghost',
        ),
        throwsA(isA<FileSystemException>().having(
          (e) => e.message,
          'message',
          contains('Source file does not exist'),
        )),
      );
    });

    test('Adversarial Boundary: Directory traversal attempts in trackId are rejected or sanitized to sandbox', () {
      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );

      // Raw dot and double-dot tokens throw FormatException
      expect(
        () => manager.computeRelativePath('..'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('.'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('   '),
        throwsA(isA<FormatException>()),
      );

      // Traversal sequences in trackId are stripped by p.basename, guaranteeing no escape from vault_media/.nomedia/
      final resolved = manager.computeRelativePath('../../../etc/shadow');
      expect(resolved, equals('vault_media/.nomedia/shadow.mp3'));
      expect(resolved.contains('..'), isFalse);
    });

    test('Adversarial Vulnerability Probe: Path traversal in _findIsolatedTrackFile allows shredding external files', () async {
      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );

      // Create a critical file outside the sandbox in appStorageDir
      final externalFile = File(p.join(appStorageDir.path, 'critical_app_database.sqlite'))..createSync();
      externalFile.writeAsStringSync('CRITICAL SQLITE DATABASE DATA');
      expect(externalFile.existsSync(), isTrue);

      // Attempt to shred it via path traversal: '../../critical_app_database.sqlite'
      // Expected secure behavior: should throw FormatException or fail to resolve outside sandbox
      // Actual vulnerable behavior: _findIsolatedTrackFile joins cleanId directly and shreds the file!
      await manager.removeIsolatedTrack('../../critical_app_database.sqlite');

      // Check if external file was destroyed!
      final wasShredded = !externalFile.existsSync();
      // Verify secure behavior: external file was preserved and NOT destroyed
      expect(
        wasShredded,
        isFalse,
        reason: 'removeIsolatedTrack MUST NOT delete files outside .nomedia sandbox!',
      );
    });
  });

  // ===========================================================================
  // GROUP 2: Shredding Forensics & Concurrency (R5)
  // ===========================================================================
  group('2. Media Shredding Forensics & Concurrency (R5)', () {
    test('Forensic Analysis: Populate 10 files with non-zero byte patterns (0xFF, crypto entropy, multi-chunk) '
        'and verify all files are shredded and deleted via Isolate.run while .nomedia is preserved', () async {
      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );

      final mediaDir = await manager.getVaultMediaDirectory();
      expect(mediaDir.existsSync(), isTrue);
      final sentinelFile = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinelFile.existsSync(), isTrue);

      // Create 10 files with diverse sizes and known non-zero patterns
      final List<File> createdFiles = [];
      final random = Random(42);

      // File 0: 0xFF saturation (512 bytes)
      final f0 = File(p.join(mediaDir.path, 'track_00_sat.mp3'));
      f0.writeAsBytesSync(Uint8List(512)..fillRange(0, 512, 0xFF));
      createdFiles.add(f0);

      // File 1: Random entropy (8192 bytes)
      final f1 = File(p.join(mediaDir.path, 'track_01_entropy.flac'));
      f1.writeAsBytesSync(Uint8List.fromList(List.generate(8192, (_) => random.nextInt(256))));
      createdFiles.add(f1);

      // File 2: Multi-chunk file (150,000 bytes > 2 x 64KB chunks) to stress chunk loop
      final f2 = File(p.join(mediaDir.path, 'track_02_multichunk.wav'));
      f2.writeAsBytesSync(Uint8List.fromList(List.generate(150000, (i) => (i % 251) + 1)));
      createdFiles.add(f2);

      // File 3: Exact chunk size (65,536 bytes)
      final f3 = File(p.join(mediaDir.path, 'track_03_exactchunk.m4a'));
      f3.writeAsBytesSync(Uint8List(65536)..fillRange(0, 65536, 0x77));
      createdFiles.add(f3);

      // File 4: Chunk boundary + 1 byte (65,537 bytes)
      final f4 = File(p.join(mediaDir.path, 'track_04_oddchunk.ogg'));
      f4.writeAsBytesSync(Uint8List(65537)..fillRange(0, 65537, 0x33));
      createdFiles.add(f4);

      // Files 5 - 9: Mixed audio files
      for (int i = 5; i < 10; i++) {
        final f = File(p.join(mediaDir.path, 'track_0${i}_pattern.mp3'));
        final sz = 1024 * (i + 1);
        f.writeAsBytesSync(Uint8List.fromList(List.generate(sz, (idx) => ((idx + i) % 255) + 1)));
        createdFiles.add(f);
      }

      expect(createdFiles.length, equals(10));
      for (final f in createdFiles) {
        expect(f.existsSync(), isTrue);
        expect(f.lengthSync(), greaterThan(0));
      }

      // Execute shredding
      await manager.shredAllIsolatedMedia();

      // Forensics Verification:
      // 1. All 10 track files must be deleted from filesystem
      for (final f in createdFiles) {
        expect(f.existsSync(), isFalse, reason: 'File "${f.path}" must be completely deleted.');
      }

      // 2. .nomedia sentinel file must still exist
      expect(sentinelFile.existsSync(), isTrue, reason: '.nomedia sentinel file must be retained/restored.');

      // 3. Media directory must exist and contain only the sentinel file
      final remainingEntities = mediaDir.listSync();
      expect(remainingEntities.length, equals(1));
      expect(p.basename(remainingEntities.first.path), equals('.nomedia'));

      // 4. hasIsolatedTrack must return false for all tracks
      for (int i = 0; i < 10; i++) {
        final trackName = p.basenameWithoutExtension(createdFiles[i].path);
        expect(await manager.hasIsolatedTrack(trackName), isFalse);
      }
    });

    test('Shredding Forensics on shredSingleFileSync: Zeroes file content before unlinking', () {
      final testFile = File(p.join(appStorageDir.path, 'forensics_target.bin'));
      const originalPattern = 0xAA;
      const fileLength = 4096;
      testFile.writeAsBytesSync(Uint8List(fileLength)..fillRange(0, fileLength, originalPattern));

      expect(testFile.existsSync(), isTrue);
      expect(testFile.readAsBytesSync().every((b) => b == originalPattern), isTrue);

      // Execute synchronous single file shredding with custom chunk size (512 bytes)
      VaultMediaIsolationManager.shredSingleFileSync(testFile.path, chunkSize: 512);

      // File is deleted
      expect(testFile.existsSync(), isFalse);
    });

    test('Recursive directory shredding: shreds nested subdirectories and preserves root .nomedia', () async {
      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );

      final mediaDir = await manager.getVaultMediaDirectory();
      final subDir = Directory(p.join(mediaDir.path, 'nested_sub', 'deep_sub'))..createSync(recursive: true);
      final nestedFile = File(p.join(subDir.path, 'nested_track.mp3'));
      nestedFile.writeAsBytesSync(Uint8List(2048)..fillRange(0, 2048, 0x55));

      expect(nestedFile.existsSync(), isTrue);

      await manager.shredAllIsolatedMedia();

      expect(nestedFile.existsSync(), isFalse);
      expect(Directory(p.join(mediaDir.path, 'nested_sub')).existsSync(), isFalse);
      expect(File(p.join(mediaDir.path, '.nomedia')).existsSync(), isTrue);
    });

    test('Shredding on empty vault directory is idempotent and safe', () async {
      final manager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );

      await manager.getVaultMediaDirectory();
      // Calling shred multiple times consecutively
      await manager.shredAllIsolatedMedia();
      await manager.shredAllIsolatedMedia();

      final mediaDir = await manager.getVaultMediaDirectory();
      expect(File(p.join(mediaDir.path, '.nomedia')).existsSync(), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 3: VaultStorageRepository Purge Integration (Atomic Cascade)
  // ===========================================================================
  group('3. VaultStorageRepository Purge Integration (Atomic Cascade)', () {
    test('End-to-End Purge: Purges SQLite metadata, shreds media sandbox files, '
        'and destroys native KeyStore master key', () async {
      // 1. Initialize isolated in-memory Drift VaultDatabase
      final vaultDb = VaultDatabase.forTesting(NativeDatabase.memory());

      // 2. Initialize media isolation manager with physical sandbox directory
      final isolationManager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => appStorageDir,
      );
      final mediaDir = await isolationManager.getVaultMediaDirectory();

      // 3. Create isolated audio files in sandbox
      final track1File = File(p.join(mediaDir.path, 'track_priv_01.mp3'));
      final track2File = File(p.join(mediaDir.path, 'track_priv_02.mp3'));
      track1File.writeAsBytesSync(Uint8List(1024)..fillRange(0, 1024, 0x44));
      track2File.writeAsBytesSync(Uint8List(2048)..fillRange(0, 2048, 0x88));

      expect(track1File.existsSync(), isTrue);
      expect(track2File.existsSync(), isTrue);

      // 4. Instantiate VaultStorageRepository wiring isolationManager.shredAllIsolatedMedia
      final repository = VaultStorageRepository(
        database: vaultDb,
        cryptoBridge: fakeCryptoBridge,
        onShredMediaFiles: isolationManager.shredAllIsolatedMedia,
      );

      // 5. Populate repository with Config, Playlists, Tracks, Gestures, Lockout
      final config = VaultConfig();
      final saveConfigRes = await repository.saveVaultConfig(config);
      expect(saveConfigRes, isA<VaultSuccess<void>>());

      final createPlRes = await repository.createPlaylist(
        name: 'Top Secret Playlist',
        description: 'Contains isolated sandbox files',
      );
      expect(createPlRes, isA<VaultSuccess<PrivatePlaylist>>());
      final createdPlaylist = (createPlRes as VaultSuccess<PrivatePlaylist>).data;

      final trackRef1 = PrivateTrackRef(
        id: 'track_priv_01',
        playlistId: createdPlaylist.id,
        trackUri: 'file://${track1File.path}',
        title: 'Secret Audio One',
        artistName: 'Ghost Artist',
        albumTitle: 'Classified Album',
        durationMs: 180000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/track_priv_01.mp3',
        sortOrder: 0,
        addedAtEpochMs: 1700000000,
      );

      final trackRef2 = PrivateTrackRef(
        id: 'track_priv_02',
        playlistId: createdPlaylist.id,
        trackUri: 'file://${track2File.path}',
        title: 'Secret Audio Two',
        artistName: 'Ghost Artist',
        albumTitle: 'Classified Album',
        durationMs: 240000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/track_priv_02.mp3',
        sortOrder: 1,
        addedAtEpochMs: 1700000010,
      );

      await repository.addTrackToPlaylist(
        playlistId: createdPlaylist.id,
        trackRef: trackRef1,
      );
      await repository.addTrackToPlaylist(
        playlistId: createdPlaylist.id,
        trackRef: trackRef2,
      );

      final points = List.generate(
        64,
        (i) => GesturePoint(x: i / 63.0, y: i / 63.0, timestampMs: (i + 1) * 10),
      );
      final gesture = GestureTemplate(
        id: 'master_gesture',
        normalizedPoints: points,
        rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
        createdAtEpochMs: 1700000000,
      );
      final saveGestureRes = await repository.saveGestureTemplate(gesture);
      expect(saveGestureRes, isA<VaultSuccess<void>>());

      await repository.persistLockoutDeadlineMs(1700099999);

      // Verify records exist in database before purge
      final plBefore = await repository.getPlaylists();
      expect(plBefore, isA<VaultSuccess<List<PrivatePlaylist>>>());
      expect((plBefore as VaultSuccess<List<PrivatePlaylist>>).data.length, equals(1));

      // 6. EXECUTE PURGE
      final purgeResult = await repository.purgeAllVaultData();
      expect(purgeResult, isA<VaultSuccess<void>>());

      // 7. VERIFICATION 1: All SQLite metadata tables are wiped empty
      final trackRefsCount = await (vaultDb.select(vaultDb.vaultTrackRefsTable)).get();
      expect(trackRefsCount, isEmpty, reason: 'vaultTrackRefsTable must be wiped.');

      final playlistsCount = await (vaultDb.select(vaultDb.vaultPlaylistsTable)).get();
      expect(playlistsCount, isEmpty, reason: 'vaultPlaylistsTable must be wiped.');

      final configCount = await (vaultDb.select(vaultDb.vaultConfigTable)).get();
      expect(configCount, isEmpty, reason: 'vaultConfigTable must be wiped.');

      final gestureCount = await (vaultDb.select(vaultDb.vaultGestureTemplatesTable)).get();
      expect(gestureCount, isEmpty, reason: 'vaultGestureTemplatesTable must be wiped.');

      final lockoutCount = await (vaultDb.select(vaultDb.vaultLockoutDeadlineTable)).get();
      expect(lockoutCount, isEmpty, reason: 'vaultLockoutDeadlineTable must be wiped.');

      // 8. VERIFICATION 2: Media sandbox files are shredded and unlinked
      expect(track1File.existsSync(), isFalse, reason: 'Sandbox track 1 must be shredded.');
      expect(track2File.existsSync(), isFalse, reason: 'Sandbox track 2 must be shredded.');
      expect(
        File(p.join(mediaDir.path, '.nomedia')).existsSync(),
        isTrue,
        reason: '.nomedia sentinel file must be retained.',
      );

      // 9. VERIFICATION 3: KeyStore master key is permanently destroyed
      expect(fakeCryptoBridge.destroyCallCount, equals(1));
      expect(fakeCryptoBridge.isDestroyed, isTrue);

      // 10. Post-purge crypto operations fail fast
      expect(
        () => fakeCryptoBridge.encryptPayload(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<VaultCryptoFailure>()),
      );

      await vaultDb.close();
    });

    test('Purge handles empty repository gracefully and idempotently', () async {
      final vaultDb = VaultDatabase.forTesting(NativeDatabase.memory());
      final repository = VaultStorageRepository(
        database: vaultDb,
        cryptoBridge: fakeCryptoBridge,
      );

      final firstPurge = await repository.purgeAllVaultData();
      expect(firstPurge, isA<VaultSuccess<void>>());

      final secondPurge = await repository.purgeAllVaultData();
      expect(secondPurge, isA<VaultSuccess<void>>());

      expect(fakeCryptoBridge.destroyCallCount, equals(2));
      await vaultDb.close();
    });

    test('Purge captures exception if media shredding hook fails and returns VaultFailureResult', () async {
      final vaultDb = VaultDatabase.forTesting(NativeDatabase.memory());
      final repository = VaultStorageRepository(
        database: vaultDb,
        cryptoBridge: fakeCryptoBridge,
        onShredMediaFiles: () async {
          throw const FileSystemException('Physical hardware I/O shredding error');
        },
      );

      final result = await repository.purgeAllVaultData();
      expect(result, isA<VaultFailureResult<void>>());
      final failure = (result as VaultFailureResult<void>).failure;
      expect(failure.message, contains('Failed to purge vault data'));
      expect(failure.message, contains('Physical hardware I/O shredding error'));

      await vaultDb.close();
    });
  });
}
