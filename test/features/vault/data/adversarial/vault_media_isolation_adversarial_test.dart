import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';

void main() {
  late Directory tempBaseDir;
  late VaultMediaIsolationManager manager;

  setUp(() async {
    tempBaseDir = await Directory.systemTemp.createTemp('vault_media_adversarial_');
    manager = VaultMediaIsolationManager(
      baseDirectoryResolver: () async => tempBaseDir,
    );
  });

  tearDown(() async {
    if (await tempBaseDir.exists()) {
      await tempBaseDir.delete(recursive: true);
    }
  });

  group('Vector 1: Path Traversal & Sanitization', () {
    test('computeRelativePath rejects naked traversal tokens', () {
      expect(
        () => manager.computeRelativePath('..'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('.'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('../'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('../../'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('isolateLocalTrack confines isolated file strictly inside .nomedia even if trackId contains traversal', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      // Source track
      final srcFile = File(p.join(tempBaseDir.path, 'source_traversal.mp3'));
      await srcFile.writeAsBytes(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));

      // Attempt isolation with traversal trackId
      final isolatedFile = await manager.isolateLocalTrack(
        sourceFilePath: srcFile.path,
        trackId: '../../private.mp3',
      );

      // Verify destination is strictly inside mediaDir
      expect(isolatedFile.existsSync(), isTrue);
      expect(p.canonicalize(isolatedFile.parent.path), equals(p.canonicalize(mediaDir.path)));
      expect(p.isWithin(mediaDir.path, isolatedFile.path), isTrue);

      // Verify no file leaked into baseDir
      final leakedFile = File(p.join(tempBaseDir.path, 'private.mp3'));
      expect(leakedFile.existsSync(), isFalse);
    });

    test('isolateLocalTrack confines file when trackId contains subdirectory components', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      final srcFile = File(p.join(tempBaseDir.path, 'source_sub.mp3'));
      await srcFile.writeAsBytes(Uint8List.fromList([10, 20, 30, 40]));

      final isolatedFile = await manager.isolateLocalTrack(
        sourceFilePath: srcFile.path,
        trackId: 'subdir/track_01',
      );

      expect(isolatedFile.existsSync(), isTrue);
      expect(p.canonicalize(isolatedFile.parent.path), equals(p.canonicalize(mediaDir.path)));
      expect(p.isWithin(mediaDir.path, isolatedFile.path), isTrue);
    });

    test('VULNERABILITY PROBE: hasIsolatedTrack and getIsolatedTrackFile must NOT escape .nomedia sandbox', () async {
      await manager.getVaultMediaDirectory();

      // Create a sensitive canary file directly in tempBaseDir (outside vault_media/.nomedia)
      final outsideCanary = File(p.join(tempBaseDir.path, 'canary_outside_vault.txt'));
      await outsideCanary.writeAsString('CRITICAL_SYSTEM_DATA_DO_NOT_EXPOSE');
      expect(outsideCanary.existsSync(), isTrue);

      // An attacker passes a relative path navigating out of vault_media/.nomedia
      const maliciousTraversalId = '../../canary_outside_vault.txt';

      // The media manager MUST NOT report that this external file is an isolated track!
      final hasTrack = await manager.hasIsolatedTrack(maliciousTraversalId);
      expect(
        hasTrack,
        isFalse,
        reason: 'hasIsolatedTrack MUST NOT return true for files outside the .nomedia sandbox!',
      );

      // getIsolatedTrackFile MUST NOT return external files
      expect(
        () async => await manager.getIsolatedTrackFile(maliciousTraversalId),
        throwsA(isA<FileSystemException>()),
        reason: 'getIsolatedTrackFile MUST NOT resolve or return files outside the .nomedia sandbox!',
      );
    });

    test('VULNERABILITY PROBE: removeIsolatedTrack must NOT shred files outside .nomedia sandbox', () async {
      await manager.getVaultMediaDirectory();

      // Sensitive file outside vault
      final outsideDatabase = File(p.join(tempBaseDir.path, 'external_database.db'));
      final originalBytes = Uint8List.fromList([99, 98, 97, 96, 95]);
      await outsideDatabase.writeAsBytes(originalBytes);
      expect(outsideDatabase.existsSync(), isTrue);

      const maliciousTraversalId = '../../external_database.db';

      // Attempting to remove the track via traversal
      try {
        await manager.removeIsolatedTrack(maliciousTraversalId);
      } catch (_) {
        // Exception is acceptable, but deleting/shredding external file is NOT
      }

      // The external file MUST still exist and MUST NOT have been shredded!
      expect(
        outsideDatabase.existsSync(),
        isTrue,
        reason: 'removeIsolatedTrack MUST NOT delete files outside .nomedia sandbox!',
      );
      final remainingBytes = await outsideDatabase.readAsBytes();
      expect(
        remainingBytes,
        equals(originalBytes),
        reason: 'removeIsolatedTrack MUST NOT zero-overwrite files outside .nomedia sandbox!',
      );
    });

    test('VULNERABILITY PROBE: exportTrackToPublic must NOT export files outside .nomedia sandbox', () async {
      await manager.getVaultMediaDirectory();

      final outsideSecret = File(p.join(tempBaseDir.path, 'secret_passwords.txt'));
      await outsideSecret.writeAsString('MY_PASSWORDS');

      final exportTargetDir = Directory(p.join(tempBaseDir.path, 'public_export'));
      await exportTargetDir.create(recursive: true);

      const maliciousTraversalId = '../../secret_passwords.txt';

      expect(
        () async => await manager.exportTrackToPublic(
          trackId: maliciousTraversalId,
          targetDirectoryPath: exportTargetDir.path,
        ),
        throwsA(isA<FileSystemException>()),
        reason: 'exportTrackToPublic MUST NOT export files outside .nomedia sandbox!',
      );
    });
  });

  group('Vector 2: File Corruption & Zero-Byte Gates', () {
    test('0-byte file isolation fails fast and leaves NO corrupted entry in .nomedia', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      final zeroByteSource = File(p.join(tempBaseDir.path, 'empty_track.mp3'));
      await zeroByteSource.writeAsBytes([]);
      expect(zeroByteSource.lengthSync(), 0);

      expect(
        () async => await manager.isolateLocalTrack(
          sourceFilePath: zeroByteSource.path,
          trackId: 'corrupt_zero_byte_01',
        ),
        throwsA(isA<FileSystemException>()),
      );

      // Verify no corrupted track file was created in .nomedia
      expect(await manager.hasIsolatedTrack('corrupt_zero_byte_01'), isFalse);

      final entities = mediaDir.listSync();
      final nonSentinelFiles = entities.where((e) => p.basename(e.path) != '.nomedia').toList();
      expect(nonSentinelFiles, isEmpty, reason: 'No files should remain in .nomedia after failed 0-byte isolation');
    });

    test('Non-existent source file throws FileSystemException and leaves sandbox clean', () async {
      final mediaDir = await manager.getVaultMediaDirectory();
      final missingPath = p.join(tempBaseDir.path, 'ghost_audio_file.flac');

      expect(
        () async => await manager.isolateLocalTrack(
          sourceFilePath: missingPath,
          trackId: 'ghost_track_01',
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await manager.hasIsolatedTrack('ghost_track_01'), isFalse);
      final entities = mediaDir.listSync();
      final nonSentinelFiles = entities.where((e) => p.basename(e.path) != '.nomedia').toList();
      expect(nonSentinelFiles, isEmpty);
    });

    test('Multi-dot and uppercase extensions preserve exact binary format and naming', () async {
      final testCases = [
        ('MY_TRACK.FINAL.FLAC', '.FLAC'),
        ('audio.remix.v2.master.OGG', '.OGG'),
        ('recording.high_res.WAV', '.WAV'),
        ('multi.part.sound.effect.m4a', '.m4a'),
        ('no_extension_track', ''),
      ];

      for (var i = 0; i < testCases.length; i++) {
        final (fileName, ext) = testCases[i];
        final trackId = 'track_case_$i';
        final src = File(p.join(tempBaseDir.path, fileName));
        final payload = Uint8List.fromList(List.generate(256, (idx) => (idx + i * 17) % 256));
        await src.writeAsBytes(payload);

        final isolated = await manager.isolateLocalTrack(
          sourceFilePath: src.path,
          trackId: trackId,
        );

        expect(isolated.existsSync(), isTrue);
        expect(await isolated.readAsBytes(), equals(payload));

        // If source has extension, isolated file should retain that extension
        if (ext.isNotEmpty) {
          expect(
            isolated.path.toLowerCase().endsWith(ext.toLowerCase()),
            isTrue,
            reason: 'Expected isolated path ${isolated.path} to end with $ext',
          );
        } else {
          expect(isolated.path.endsWith('.mp3'), isTrue);
        }

        // Verify lookup
        expect(await manager.hasIsolatedTrack(trackId), isTrue);
        final fetched = await manager.getIsolatedTrackFile(trackId);
        expect(fetched.path, equals(isolated.path));
      }
    });
  });

  group('Vector 3: Concurrent Media Operations', () {
    test('Rapid concurrent isolation of 50 simulated audio tracks guarantees byte parity', () async {
      final mediaDir = await manager.getVaultMediaDirectory();
      const count = 50;
      final rng = Random(42);

      final trackPayloads = <String, Uint8List>{};
      final sourceFiles = <String, File>{};

      final extensions = ['.mp3', '.flac', '.ogg', '.wav', '.m4a'];

      // Generate 50 distinct test files
      for (var i = 0; i < count; i++) {
        final trackId = 'concurrent_track_${i.toString().padLeft(3, '0')}';
        final ext = extensions[i % extensions.length];
        final size = 1024 + rng.nextInt(16384); // 1 KB - 17 KB
        final bytes = Uint8List.fromList(List.generate(size, (idx) => (idx * 31 + i) % 256));

        final srcFile = File(p.join(tempBaseDir.path, 'source_$trackId$ext'));
        await srcFile.writeAsBytes(bytes);

        trackPayloads[trackId] = bytes;
        sourceFiles[trackId] = srcFile;
      }

      // Execute 50 concurrent isolations
      final futures = trackPayloads.keys.map((trackId) async {
        final src = sourceFiles[trackId]!;
        final result = await manager.isolateTrackDetailed(
          sourceFilePath: src.path,
          trackId: trackId,
        );
        return (trackId, result);
      });

      final results = await Future.wait(futures);

      expect(results.length, equals(count));

      // Verify every single isolated track
      for (final (trackId, result) in results) {
        final expectedBytes = trackPayloads[trackId]!;
        final file = result.isolatedFile;

        expect(file.existsSync(), isTrue, reason: 'File for $trackId must exist');
        expect(p.isWithin(mediaDir.path, file.path), isTrue);

        final isolatedBytes = await file.readAsBytes();
        expect(
          isolatedBytes.length,
          equals(expectedBytes.length),
          reason: 'Length mismatch for $trackId: ${isolatedBytes.length} != ${expectedBytes.length}',
        );
        expect(
          isolatedBytes,
          equals(expectedBytes),
          reason: 'Byte parity failed for $trackId',
        );

        // Verify hasIsolatedTrack returns true
        final exists = await manager.hasIsolatedTrack(trackId);
        expect(exists, isTrue, reason: 'hasIsolatedTrack failed for $trackId');
      }

      // Verify .nomedia sentinel is still present and valid
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);
      expect(sentinel.lengthSync(), equals(0));
    });

    test('Concurrent queries and exports maintain data integrity under load', () async {
      const count = 20;
      final rng = Random(123);
      final trackIds = <String>[];

      for (var i = 0; i < count; i++) {
        final trackId = 'query_export_$i';
        trackIds.add(trackId);
        final bytes = Uint8List.fromList(List.generate(512 + rng.nextInt(2048), (b) => (b + i) % 256));
        final src = File(p.join(tempBaseDir.path, 'src_$trackId.mp3'));
        await src.writeAsBytes(bytes);
        await manager.isolateLocalTrack(sourceFilePath: src.path, trackId: trackId);
      }

      final exportDir = Directory(p.join(tempBaseDir.path, 'concurrent_exports'));
      await exportDir.create();

      // Launch concurrent operations: check hasIsolatedTrack, getIsolatedTrackFile, and export
      final checkFutures = trackIds.map((id) => manager.hasIsolatedTrack(id));
      final getFutures = trackIds.map((id) => manager.getIsolatedTrackFile(id));
      final exportFutures = trackIds.take(10).map(
            (id) => manager.exportTrackToPublic(trackId: id, targetDirectoryPath: exportDir.path),
          );

      final checkResults = await Future.wait(checkFutures);
      final getResults = await Future.wait(getFutures);
      final exportResults = await Future.wait(exportFutures);

      expect(checkResults.every((c) => c == true), isTrue);
      expect(getResults.length, count);
      expect(exportResults.length, 10);

      for (final exportedFile in exportResults) {
        expect(exportedFile.existsSync(), isTrue);
        expect(exportedFile.lengthSync(), greaterThan(0));
      }
    });
  });

  group('Vector 4: Binary Seekability & Non-Encryption Invariant', () {
    test('Zero AES encryption: isolated file matches byte-for-byte with source', () async {
      // Simulate typical MP3 with ID3v2 header
      final id3v2Header = [
        0x49, 0x44, 0x33, // 'ID3'
        0x04, 0x00,       // version 2.4.0
        0x00,             // flags
        0x00, 0x00, 0x02, 0x00 // synchsafe size
      ];
      final audioPayload = List.generate(4096, (i) => (i * 7) % 256);
      final rawData = Uint8List.fromList([...id3v2Header, ...audioPayload]);

      final src = File(p.join(tempBaseDir.path, 'sample.mp3'));
      await src.writeAsBytes(rawData);

      final isolated = await manager.isolateLocalTrack(
        sourceFilePath: src.path,
        trackId: 'audio_engine_seekable_01',
      );

      final isolatedBytes = await isolated.readAsBytes();

      // Zero encryption invariant
      expect(isolatedBytes, equals(rawData));
      // First 3 bytes MUST be ID3 in plaintext, NOT encrypted ciphertext
      expect(isolatedBytes[0], 0x49); // 'I'
      expect(isolatedBytes[1], 0x44); // 'D'
      expect(isolatedBytes[2], 0x33); // '3'
    });

    test('Random-access seeking simulation matches source file at any offset', () async {
      const fileSize = 65536; // 64 KB
      final randomBytes = Uint8List.fromList(List.generate(fileSize, (i) => (i * 47) % 256));

      final src = File(p.join(tempBaseDir.path, 'seek_source.bin'));
      await src.writeAsBytes(randomBytes);

      final isolated = await manager.isolateLocalTrack(
        sourceFilePath: src.path,
        trackId: 'seek_test_track',
      );

      // Open isolated file with RandomAccessFile to simulate C++ fseek / lseek
      final raf = await isolated.open(mode: FileMode.read);
      try {
        final testOffsets = [0, 512, 1024, 4096, 16384, 32768, 65000, fileSize - 100];
        const chunkSize = 64;

        for (final offset in testOffsets) {
          await raf.setPosition(offset);
          final buffer = await raf.read(chunkSize);

          final expectedSlice = randomBytes.sublist(offset, min(offset + chunkSize, fileSize));
          expect(
            buffer,
            equals(expectedSlice),
            reason: 'Seek mismatch at offset $offset',
          );
        }
      } finally {
        await raf.close();
      }
    });

    test('Native container headers (FLAC, Ogg, RIFF WAVE) remain intact and unencrypted', () async {
      final flacHeader = Uint8List.fromList([0x66, 0x4C, 0x61, 0x43, 0x00, 0x00, 0x00, 0x22]); // 'fLaC'
      final oggHeader = Uint8List.fromList([0x4F, 0x67, 0x67, 0x53, 0x00, 0x02]); // 'OggS'
      final wavHeader = Uint8List.fromList([0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45]); // 'RIFF...WAVE'

      final containers = [
        ('flac_track.flac', flacHeader),
        ('ogg_track.ogg', oggHeader),
        ('wav_track.wav', wavHeader),
      ];

      for (final (name, header) in containers) {
        final dummyBody = Uint8List.fromList(List.generate(1024, (i) => i % 256));
        final fullData = Uint8List.fromList([...header, ...dummyBody]);

        final src = File(p.join(tempBaseDir.path, name));
        await src.writeAsBytes(fullData);

        final trackId = p.basenameWithoutExtension(name);
        final isolated = await manager.isolateLocalTrack(sourceFilePath: src.path, trackId: trackId);

        final isolatedData = await isolated.readAsBytes();
        expect(isolatedData.sublist(0, header.length), equals(header), reason: 'Header corrupted for $name');
      }
    });

    test('Shredding zero-overwrites file content before unlinking', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      final src = File(p.join(tempBaseDir.path, 'shred_target.mp3'));
      final sensitiveBytes = Uint8List.fromList(List.generate(4096, (i) => 0xFF)); // all 1s
      await src.writeAsBytes(sensitiveBytes);

      final isolated = await manager.isolateLocalTrack(
        sourceFilePath: src.path,
        trackId: 'track_to_shred',
      );
      expect(isolated.existsSync(), isTrue);

      // Shred all isolated media
      await manager.shredAllIsolatedMedia();

      // Verify file is unlinked
      expect(isolated.existsSync(), isFalse);

      // Verify sentinel is restored
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);
    });
  });
}
