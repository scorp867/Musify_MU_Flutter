import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';

void main() {
  late Directory tempBaseDir;
  late Directory externalDir;
  late File externalCanary;
  late Uint8List externalCanaryBytes;
  late VaultMediaIsolationManager manager;

  setUp(() async {
    tempBaseDir = await Directory.systemTemp.createTemp('m3_path_traversal_adversarial_');
    externalDir = await Directory.systemTemp.createTemp('m3_external_leak_dir_');
    externalCanary = File(p.join(tempBaseDir.path, 'canary_host_target.bin'));
    externalCanaryBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE]);
    await externalCanary.writeAsBytes(externalCanaryBytes);

    manager = VaultMediaIsolationManager(
      baseDirectoryResolver: () async => tempBaseDir,
    );
  });

  tearDown(() async {
    if (await tempBaseDir.exists()) {
      await tempBaseDir.delete(recursive: true);
    }
    if (await externalDir.exists()) {
      await externalDir.delete(recursive: true);
    }
  });

  group('Vector 1: Direct .nomedia Sentinel Attack & Integrity', () {
    test('removeIsolatedTrack(".nomedia") must NOT delete or zero the .nomedia sentinel', () async {
      final mediaDir = await manager.getVaultMediaDirectory();
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);

      // Attempt deletion with exact sentinel name
      await manager.removeIsolatedTrack('.nomedia');

      expect(sentinel.existsSync(), isTrue, reason: '.nomedia must remain present');

      // Attempt deletion with padded whitespace
      await manager.removeIsolatedTrack('   .nomedia   ');
      expect(sentinel.existsSync(), isTrue, reason: '.nomedia must survive padded deletion attempt');
    });

    test('exportTrackToPublic with trackId=".nomedia" must throw FileSystemException', () async {
      await manager.getVaultMediaDirectory();
      final exportTargetDir = Directory(p.join(tempBaseDir.path, 'public_exports'));
      await exportTargetDir.create();

      // Exact sentinel export
      expect(
        () async => await manager.exportTrackToPublic(
          trackId: '.nomedia',
          targetDirectoryPath: exportTargetDir.path,
        ),
        throwsA(isA<FileSystemException>()),
        reason: 'Exporting .nomedia sentinel must throw FileSystemException',
      );

      // Whitespace padded sentinel export
      expect(
        () async => await manager.exportTrackToPublic(
          trackId: '  .nomedia  ',
          targetDirectoryPath: exportTargetDir.path,
        ),
        throwsA(isA<FileSystemException>()),
        reason: 'Exporting padded .nomedia sentinel must throw FileSystemException',
      );

      // Verify no leaked sentinel in export target
      final exportedFiles = exportTargetDir.listSync();
      expect(exportedFiles, isEmpty);
    });

    test('hasIsolatedTrack and getIsolatedTrackFile must reject .nomedia sentinel', () async {
      await manager.getVaultMediaDirectory();

      expect(await manager.hasIsolatedTrack('.nomedia'), isFalse);
      expect(await manager.hasIsolatedTrack('   .nomedia   '), isFalse);

      expect(
        () async => await manager.getIsolatedTrackFile('.nomedia'),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        () async => await manager.getIsolatedTrackFile('   .nomedia   '),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('isolateTrackDetailed must reject .nomedia as a target trackId', () async {
      final srcFile = File(p.join(tempBaseDir.path, 'valid_audio.mp3'));
      await srcFile.writeAsBytes([1, 2, 3, 4]);

      expect(
        () async => await manager.isolateTrackDetailed(
          sourceFilePath: srcFile.path,
          trackId: '.nomedia',
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () async => await manager.isolateTrackDetailed(
          sourceFilePath: srcFile.path,
          trackId: '   .nomedia   ',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Vector 2: Advanced Traversal Variants (Slash, Backslash, Double Slashes, Dots)', () {
    const maliciousPaths = <String>[
      '../../canary_host_target.bin',
      r'..\..\canary_host_target.bin',
      '..//..//canary_host_target.bin',
      r'..\\..\\canary_host_target.bin',
      '../..//canary_host_target.bin',
      r'..\../canary_host_target.bin',
      './../../canary_host_target.bin',
      r'.\..\..\canary_host_target.bin',
      'sub/../../canary_host_target.bin',
      r'sub\..\..\canary_host_target.bin',
      '/canary_host_target.bin',
      '///canary_host_target.bin',
      r'\canary_host_target.bin',
      r'\\canary_host_target.bin',
      '....//canary_host_target.bin',
      '..../..../canary_host_target.bin',
      './././../canary_host_target.bin',
      '..',
      '.',
      '../',
      '..\\',
      './',
      '.\\',
      '   ../canary_host_target.bin   ',
      'track/../canary_host_target.bin',
    ];

    test('All traversal variants return false for hasIsolatedTrack', () async {
      await manager.getVaultMediaDirectory();

      for (final maliciousId in maliciousPaths) {
        if (maliciousId.trim().isEmpty) continue;
        final hasTrack = await manager.hasIsolatedTrack(maliciousId);
        expect(
          hasTrack,
          isFalse,
          reason: 'hasIsolatedTrack MUST return false for payload: "$maliciousId"',
        );
      }
    });

    test('All traversal variants throw FileSystemException or FormatException on getIsolatedTrackFile', () async {
      await manager.getVaultMediaDirectory();

      for (final maliciousId in maliciousPaths) {
        expect(
          () async => await manager.getIsolatedTrackFile(maliciousId),
          throwsA(anyOf(isA<FileSystemException>(), isA<FormatException>())),
          reason: 'getIsolatedTrackFile MUST throw exception for payload: "$maliciousId"',
        );
      }
    });

    test('All traversal variants fail to delete or shred external canary via removeIsolatedTrack', () async {
      await manager.getVaultMediaDirectory();

      for (final maliciousId in maliciousPaths) {
        expect(externalCanary.existsSync(), isTrue);

        try {
          await manager.removeIsolatedTrack(maliciousId);
        } catch (_) {
          // Exceptions are permissible, but external file shredding is not
        }

        expect(
          externalCanary.existsSync(),
          isTrue,
          reason: 'External canary unlinked by payload: "$maliciousId"',
        );
        final bytes = await externalCanary.readAsBytes();
        expect(
          bytes,
          equals(externalCanaryBytes),
          reason: 'External canary shredded by payload: "$maliciousId"',
        );
      }
    });

    test('All traversal variants fail to export external canary via exportTrackToPublic', () async {
      await manager.getVaultMediaDirectory();
      final exportTargetDir = Directory(p.join(tempBaseDir.path, 'traversal_exports'));
      await exportTargetDir.create();

      for (final maliciousId in maliciousPaths) {
        expect(
          () async => await manager.exportTrackToPublic(
            trackId: maliciousId,
            targetDirectoryPath: exportTargetDir.path,
          ),
          throwsA(anyOf(isA<FileSystemException>(), isA<FormatException>())),
          reason: 'exportTrackToPublic MUST reject payload: "$maliciousId"',
        );
      }

      final exportedFiles = exportTargetDir.listSync();
      expect(exportedFiles, isEmpty, reason: 'No files may be exported from traversal attacks');
    });
  });

  group('Vector 3: Encoded Traversal and Literal Special Character Resilience', () {
    test('URL-encoded traversal tokens cannot escape sandbox or resolve external files', () async {
      await manager.getVaultMediaDirectory();

      final encodedPayloads = [
        '%2e%2e%2fcanary_host_target.bin',
        '%2e%2e/canary_host_target.bin',
        '..%2fcanary_host_target.bin',
        '%2e%2e%5ccanary_host_target.bin',
        '..%5ccanary_host_target.bin',
        '%252e%252e%252fcanary_host_target.bin',
      ];

      for (final payload in encodedPayloads) {
        // hasIsolatedTrack should not find external canary
        final hasTrack = await manager.hasIsolatedTrack(payload);
        expect(hasTrack, isFalse, reason: 'Encoded payload "$payload" must not resolve to external track');

        // removeIsolatedTrack should not touch canary
        await manager.removeIsolatedTrack(payload);
        expect(externalCanary.existsSync(), isTrue);
        expect(await externalCanary.readAsBytes(), equals(externalCanaryBytes));

        // getIsolatedTrackFile should fail
        expect(
          () async => await manager.getIsolatedTrackFile(payload),
          throwsA(isA<FileSystemException>()),
        );
      }
    });

    test('Isolating a track with encoded tokens confines file strictly within sandbox', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      final src = File(p.join(tempBaseDir.path, 'source_encoded.mp3'));
      await src.writeAsBytes([11, 22, 33, 44]);

      const trickyId = '%2e%2e%2ftricky_name';
      final isolated = await manager.isolateLocalTrack(
        sourceFilePath: src.path,
        trackId: trickyId,
      );

      expect(isolated.existsSync(), isTrue);
      expect(p.canonicalize(isolated.parent.path), equals(p.canonicalize(mediaDir.path)));
      expect(p.isWithin(mediaDir.path, isolated.path), isTrue);

      // Verify external directory was not written to
      expect(File(p.join(tempBaseDir.path, 'tricky_name.mp3')).existsSync(), isFalse);
    });
  });

  group('Vector 4: Concurrent Adversarial Stress & Sentinel Invariance', () {
    test('100 concurrent adversarial operations leave .nomedia sentinel intact and uncorrupted', () async {
      final mediaDir = await manager.getVaultMediaDirectory();
      final sentinel = File(p.join(mediaDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);

      // Populate a few valid tracks in sandbox
      for (var i = 0; i < 5; i++) {
        final dummySrc = File(p.join(tempBaseDir.path, 'valid_$i.mp3'));
        await dummySrc.writeAsBytes(List.generate(256, (idx) => (idx + i) % 256));
        await manager.isolateLocalTrack(
          sourceFilePath: dummySrc.path,
          trackId: 'valid_track_$i',
        );
      }

      final exportDir = Directory(p.join(tempBaseDir.path, 'concurrent_attack_exports'));
      await exportDir.create();

      final rng = Random(999);
      final futures = <Future<void>>[];

      for (var i = 0; i < 100; i++) {
        final choice = rng.nextInt(6);
        switch (choice) {
          case 0:
            futures.add(manager.removeIsolatedTrack('.nomedia'));
            break;
          case 1:
            futures.add(manager.removeIsolatedTrack('../../canary_host_target.bin'));
            break;
          case 2:
            futures.add(() async {
              try {
                await manager.exportTrackToPublic(
                  trackId: '.nomedia',
                  targetDirectoryPath: exportDir.path,
                );
              } catch (_) {}
            }());
            break;
          case 3:
            futures.add(() async {
              try {
                await manager.exportTrackToPublic(
                  trackId: '../../canary_host_target.bin',
                  targetDirectoryPath: exportDir.path,
                );
              } catch (_) {}
            }());
            break;
          case 4:
            futures.add(() async {
              await manager.hasIsolatedTrack('.nomedia');
              await manager.hasIsolatedTrack('../../canary_host_target.bin');
            }());
            break;
          case 5:
            futures.add(() async {
              final trackIndex = rng.nextInt(5);
              final has = await manager.hasIsolatedTrack('valid_track_$trackIndex');
              expect(has, isTrue);
            }());
            break;
        }
      }

      await Future.wait(futures);

      // Post-stress validation: .nomedia must be intact
      expect(sentinel.existsSync(), isTrue, reason: '.nomedia must exist after 100 concurrent attacks');
      expect(sentinel.lengthSync(), 0, reason: '.nomedia must have 0 bytes');

      // External canary must still be completely uncorrupted
      expect(externalCanary.existsSync(), isTrue, reason: 'External canary must not be deleted');
      expect(await externalCanary.readAsBytes(), equals(externalCanaryBytes), reason: 'Canary must not be modified');
    });
  });
}
