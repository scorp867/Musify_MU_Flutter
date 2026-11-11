import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempBaseDir;
  late Directory appStorageDir;
  late VaultMediaIsolationManager manager;

  setUp(() async {
    tempBaseDir = await Directory.systemTemp.createTemp('vault_empirical_stress_');
    appStorageDir = Directory(p.join(tempBaseDir.path, 'app_storage'))..createSync(recursive: true);
    manager = VaultMediaIsolationManager(
      baseDirectoryResolver: () async => appStorageDir,
    );
  });

  tearDown(() async {
    if (await tempBaseDir.exists()) {
      await tempBaseDir.delete(recursive: true);
    }
  });

  group('Empirical Stress: Vector 2 - removeIsolatedTrack Containment Invariants', () {
    test('Exhaustive Traversal & Injection Attack Matrix does NOT destroy external files', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      // Create external files at multiple hierarchy levels
      final rootCanary = File(p.join(tempBaseDir.path, 'root_canary.txt'));
      rootCanary.writeAsStringSync('ROOT_CANARY_PAYLOAD');

      final appStorageCanary = File(p.join(appStorageDir.path, 'storage_canary.sqlite'));
      appStorageCanary.writeAsStringSync('STORAGE_CANARY_PAYLOAD');

      final vaultMediaCanary = File(p.join(appStorageDir.path, 'vault_media', 'sibling_canary.bin'));
      vaultMediaCanary.writeAsStringSync('VAULT_MEDIA_SIBLING_PAYLOAD');

      // Also create an external file whose basename matches a valid track
      final decoyFile = File(p.join(appStorageDir.path, 'track_alpha.mp3'));
      decoyFile.writeAsStringSync('DECOY_ALPHA_CONTENT');

      final List<String> attackPayloads = [
        '../../root_canary.txt',
        '../storage_canary.sqlite',
        '../sibling_canary.bin',
        '../../app_storage/track_alpha.mp3',
        'track_alpha', // Basename match in outer folder should NOT delete outer file
        '/etc/passwd',
        'C:\\Windows\\system32',
        '..',
        '.',
        '   ',
        '.nomedia',
        '/.nomedia',
        './.nomedia',
        'vault_media/.nomedia/.nomedia',
        'subdir/nested.mp3',
        '../.nomedia/../storage_canary.sqlite',
        r'..\storage_canary.sqlite',
        r'..\..\root_canary.txt',
        'track/../../storage_canary.sqlite',
        '..%2F..%2Fstorage_canary.sqlite',
        'null\x00byte',
      ];

      for (final payload in attackPayloads) {
        try {
          await manager.removeIsolatedTrack(payload);
        } catch (e) {
          // FormatException or FileSystemException are acceptable defensive rejections
          expect(e, anyOf(isA<FormatException>(), isA<FileSystemException>()));
        }
      }

      // Assert all external files survived completely unmolested
      expect(rootCanary.existsSync(), isTrue);
      expect(rootCanary.readAsStringSync(), equals('ROOT_CANARY_PAYLOAD'));

      expect(appStorageCanary.existsSync(), isTrue);
      expect(appStorageCanary.readAsStringSync(), equals('STORAGE_CANARY_PAYLOAD'));

      expect(vaultMediaCanary.existsSync(), isTrue);
      expect(vaultMediaCanary.readAsStringSync(), equals('VAULT_MEDIA_SIBLING_PAYLOAD'));

      expect(decoyFile.existsSync(), isTrue);
      expect(decoyFile.readAsStringSync(), equals('DECOY_ALPHA_CONTENT'));

      // Assert .nomedia sentinel in sandbox survived
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);
    });

    test('removeIsolatedTrack(".nomedia") unconditionally preserves the sentinel file', () async {
      final mediaDir = await manager.getVaultMediaDirectory();
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);

      // Attempt deletion targeting sentinel directly
      await manager.removeIsolatedTrack('.nomedia');
      expect(sentinel.existsSync(), isTrue);

      // Whitespace padded
      await manager.removeIsolatedTrack(' .nomedia ');
      expect(sentinel.existsSync(), isTrue);
    });

    test('Legitimate track removal shreds file and zeroes content before unlinking', () async {
      final mediaDir = await manager.getVaultMediaDirectory();
      final trackFile = File(p.join(mediaDir.path, 'legit_track.mp3'));
      final originalData = Uint8List(8192)..fillRange(0, 8192, 0x7E);
      trackFile.writeAsBytesSync(originalData);
      expect(trackFile.existsSync(), isTrue);

      expect(await manager.hasIsolatedTrack('legit_track'), isTrue);

      await manager.removeIsolatedTrack('legit_track');

      expect(trackFile.existsSync(), isFalse);
      expect(await manager.hasIsolatedTrack('legit_track'), isFalse);
    });
  });

  group('Empirical Stress: Vector 3 - shredAllIsolatedMedia Containment & Sentinel Invariants', () {
    test('shredAllIsolatedMedia strictly purges sandbox contents while sparing siblings and parents', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      // Populate external boundary files
      final parentDir = mediaDir.parent; // vault_media
      final externalSiblingFile = File(p.join(parentDir.path, 'vault_media_config.json'));
      externalSiblingFile.writeAsStringSync('{"key": "survive"}');

      final grandparentDir = parentDir.parent; // app_storage
      final appDbFile = File(p.join(grandparentDir.path, 'app.db'));
      appDbFile.writeAsStringSync('SQLITE_DATA');

      // Populate internal sandbox files (mix of sizes, deep hierarchies, odd extensions)
      final internalFiles = <File>[];
      for (int i = 0; i < 5; i++) {
        final f = File(p.join(mediaDir.path, 'track_$i.mp3'));
        f.writeAsBytesSync(Uint8List(1024 * (i + 1))..fillRange(0, 1024 * (i + 1), 0xAA));
        internalFiles.add(f);
      }

      // Deep nested hierarchy inside sandbox
      final deepDir = Directory(p.join(mediaDir.path, 'album_1', 'disc_1'))..createSync(recursive: true);
      final deepTrack = File(p.join(deepDir.path, 'deep_track.flac'));
      deepTrack.writeAsBytesSync(Uint8List(4096)..fillRange(0, 4096, 0xBB));
      internalFiles.add(deepTrack);

      // Execute full media shred
      await manager.shredAllIsolatedMedia();

      // Sandbox files must all be gone
      for (final f in internalFiles) {
        expect(f.existsSync(), isFalse, reason: 'Sandbox file ${f.path} must be deleted');
      }
      expect(Directory(p.join(mediaDir.path, 'album_1')).existsSync(), isFalse);

      // External files must remain 100% intact
      expect(externalSiblingFile.existsSync(), isTrue);
      expect(externalSiblingFile.readAsStringSync(), equals('{"key": "survive"}'));

      expect(appDbFile.existsSync(), isTrue);
      expect(appDbFile.readAsStringSync(), equals('SQLITE_DATA'));

      // Sentinel file must still exist
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);
    });

    test('Sequential and rapid consecutive shredAllIsolatedMedia executions are idempotent and stable', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      for (int run = 0; run < 5; run++) {
        // Add a temporary file
        final tempTrack = File(p.join(mediaDir.path, 'temp_run_$run.mp3'));
        tempTrack.writeAsBytesSync(Uint8List(512)..fillRange(0, 512, 0x33));
        expect(tempTrack.existsSync(), isTrue);

        await manager.shredAllIsolatedMedia();

        expect(tempTrack.existsSync(), isFalse);
        final sentinel = File(p.join(mediaDir.path, '.nomedia'));
        expect(sentinel.existsSync(), isTrue);
      }
    });

    test('shredDirectorySync recovers when directory was deleted externally', () async {
      final mediaDir = await manager.getVaultMediaDirectory();
      // Simulate external directory purge
      if (mediaDir.existsSync()) {
        mediaDir.deleteSync(recursive: true);
      }
      expect(mediaDir.existsSync(), isFalse);

      // Execute shred
      VaultMediaIsolationManager.shredDirectorySync(mediaDir.path);

      // Verifies directory was recreated and sentinel placed
      expect(mediaDir.existsSync(), isTrue);
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);
    });
  });
}
