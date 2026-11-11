import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';

void main() {
  late Directory tempBaseDir;
  late VaultMediaIsolationManager manager;

  setUp(() {
    tempBaseDir = Directory.systemTemp.createTempSync('vault_iso_test_');
    manager = VaultMediaIsolationManager(
      baseDirectoryResolver: () async => tempBaseDir,
    );
  });

  tearDown(() {
    try {
      if (tempBaseDir.existsSync()) {
        tempBaseDir.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Temp directory already cleaned up
    }
  });

  group('VaultMediaIsolationManager Sandbox & Directory Lifecycle', () {
    test('getVaultMediaDirectory creates directory and .nomedia sentinel file', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      expect(await mediaDir.exists(), isTrue);
      expect(
        p.normalize(mediaDir.path),
        equals(p.normalize(p.join(tempBaseDir.path, 'vault_media', '.nomedia'))),
      );

      final sentinelFile = File(p.join(mediaDir.path, '.nomedia'));
      expect(await sentinelFile.exists(), isTrue);
      expect(await sentinelFile.length(), equals(0));
    });

    test('getVaultMediaDirectory is idempotent and preserves existing sentinel', () async {
      final firstDir = await manager.getVaultMediaDirectory();
      final sentinel = File(p.join(firstDir.path, '.nomedia'));
      await sentinel.writeAsString('sentinel_content');

      final secondDir = await manager.getVaultMediaDirectory();
      expect(secondDir.path, equals(firstDir.path));
      expect(await sentinel.exists(), isTrue);
      expect(await sentinel.readAsString(), equals('sentinel_content'));
    });
  });

  group('VaultMediaIsolationManager computeRelativePath', () {
    test('computes POSIX relative path with default .mp3 extension', () {
      final path = manager.computeRelativePath('track_001');
      expect(path, equals('vault_media/.nomedia/track_001.mp3'));
    });

    test('preserves explicit extension when passed', () {
      final flacPath = manager.computeRelativePath('track_002', extension: '.flac');
      expect(flacPath, equals('vault_media/.nomedia/track_002.flac'));

      final m4aPath = manager.computeRelativePath('track_003', extension: 'm4a');
      expect(m4aPath, equals('vault_media/.nomedia/track_003.m4a'));
    });

    test('avoids duplicate extension when trackId already includes extension', () {
      final path = manager.computeRelativePath('track_004.mp3', extension: '.mp3');
      expect(path, equals('vault_media/.nomedia/track_004.mp3'));

      final wavPath = manager.computeRelativePath('track_005.wav');
      expect(wavPath, equals('vault_media/.nomedia/track_005.wav'));
    });

    test('throws FormatException on empty or whitespace trackId', () {
      expect(
        () => manager.computeRelativePath(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on directory traversal trackId', () {
      expect(
        () => manager.computeRelativePath('..'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.computeRelativePath('.'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('VaultMediaIsolationManager Track Isolation & Binary Preservation', () {
    test('isolates local audio track with exact binary parity and unlinks source', () async {
      final sourceDir = Directory(p.join(tempBaseDir.path, 'public_music'));
      await sourceDir.create(recursive: true);

      final sourceFile = File(p.join(sourceDir.path, 'song.mp3'));
      final sampleAudioBytes = Uint8List.fromList(
        List.generate(65536 + 1024, (i) => (i * 7) % 256),
      );
      await sourceFile.writeAsBytes(sampleAudioBytes);

      final result = await manager.isolateTrackDetailed(
        sourceFilePath: sourceFile.path,
        trackId: 'isolated_track_1',
      );

      expect(await result.isolatedFile.exists(), isTrue);
      expect(result.relativePath, equals('vault_media/.nomedia/isolated_track_1.mp3'));
      expect(result.deletionResult, isA<ScopedStorageDeletionSuccess>());

      final isolatedBytes = await result.isolatedFile.readAsBytes();
      expect(isolatedBytes, equals(sampleAudioBytes));

      expect(await sourceFile.exists(), isFalse);
      expect(await manager.hasIsolatedTrack('isolated_track_1'), isTrue);
    });

    test('preserves diverse audio formats during isolation', () async {
      final sourceDir = Directory(p.join(tempBaseDir.path, 'formats'));
      await sourceDir.create(recursive: true);

      final extensions = ['.flac', '.m4a', '.wav', '.ogg'];
      for (final ext in extensions) {
        final src = File(p.join(sourceDir.path, 'audio$ext'));
        await src.writeAsBytes(Uint8List.fromList([1, 2, 3, 4, 5]));

        final isolated = await manager.isolateLocalTrack(
          sourceFilePath: src.path,
          trackId: 'track_$ext',
        );

        expect(isolated.path.endsWith(ext), isTrue);
        expect(await isolated.exists(), isTrue);
      }
    });

    test('throws FormatException when parameters are empty or whitespace', () async {
      expect(
        () => manager.isolateLocalTrack(
          sourceFilePath: '',
          trackId: 'track_1',
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => manager.isolateLocalTrack(
          sourceFilePath: 'some/path',
          trackId: '   ',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FileSystemException when source file does not exist', () async {
      final missingPath = p.join(tempBaseDir.path, 'non_existent.mp3');
      expect(
        () => manager.isolateLocalTrack(
          sourceFilePath: missingPath,
          trackId: 'track_missing',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws FileSystemException when source file is 0 bytes', () async {
      final emptyFile = File(p.join(tempBaseDir.path, 'empty.mp3'));
      await emptyFile.create();

      expect(
        () => manager.isolateLocalTrack(
          sourceFilePath: emptyFile.path,
          trackId: 'track_empty',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('VaultMediaIsolationManager Scoped Storage Safe Deletion Fallback', () {
    test('handles FileSystemException during unlinking and triggers exclusion fallback', () async {
      final sourceDir = Directory(p.join(tempBaseDir.path, 'scoped_public'));
      await sourceDir.create(recursive: true);

      final sourceFile = File(p.join(sourceDir.path, 'scoped_song.mp3'));
      final rawAudioBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      await sourceFile.writeAsBytes(rawAudioBytes);

      var excludedPath = '';
      final scopedManager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => tempBaseDir,
        fileDeleter: (file) async {
          throw const FileSystemException(
            'Scoped Storage restriction: EACCES Permission denied',
            '/sdcard/Music/scoped_song.mp3',
            OSError('Permission denied', 13),
          );
        },
        localTracksExcluder: (path) async {
          excludedPath = path;
        },
      );

      final result = await scopedManager.isolateTrackDetailed(
        sourceFilePath: sourceFile.path,
        trackId: 'scoped_track_1',
      );

      expect(await result.isolatedFile.exists(), isTrue);
      expect(await result.isolatedFile.readAsBytes(), equals(rawAudioBytes));

      expect(result.deletionResult, isA<ScopedStorageDeletionRestricted>());
      final restricted = result.deletionResult as ScopedStorageDeletionRestricted;
      expect(restricted.sourcePath, equals(sourceFile.path));
      expect(restricted.osErrorCode, equals(13));
      expect(restricted.markedExcludedInLocalDb, isTrue);
      expect(restricted.failureMessage, contains('Permission denied'));
      expect(excludedPath, equals(sourceFile.path));
    });

    test('detects source missing when source file disappears before unlinking', () async {
      final sourceDir = Directory(p.join(tempBaseDir.path, 'missing_src'));
      await sourceDir.create(recursive: true);

      final sourceFile = File(p.join(sourceDir.path, 'transient_song.mp3'));
      await sourceFile.writeAsBytes(Uint8List.fromList([1, 2, 3]));

      final missingManager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => tempBaseDir,
        fileDeleter: (file) async {
          throw const FileSystemException(
            'Cannot delete file, path = /path/transient_song.mp3',
            '/path/transient_song.mp3',
            OSError('No such file or directory', 2),
          );
        },
      );

      final result = await missingManager.isolateTrackDetailed(
        sourceFilePath: sourceFile.path,
        trackId: 'transient_track',
      );

      expect(await result.isolatedFile.exists(), isTrue);
      expect(result.deletionResult, isA<ScopedStorageDeletionSourceMissing>());
      expect(result.deletionResult.sourcePath, equals(sourceFile.path));
    });
  });

  group('VaultMediaIsolationManager Track Query & File Access', () {
    test('getIsolatedTrackFile finds file by exact ID, default .mp3, or without extension', () async {
      final srcFile = File(p.join(tempBaseDir.path, 'sample.flac'));
      await srcFile.writeAsBytes(Uint8List.fromList([9, 8, 7, 6]));

      await manager.isolateLocalTrack(
        sourceFilePath: srcFile.path,
        trackId: 'my_song',
      );

      final byId = await manager.getIsolatedTrackFile('my_song');
      expect(await byId.exists(), isTrue);
      expect(byId.path.endsWith('.flac'), isTrue);

      final byFullName = await manager.getIsolatedTrackFile('my_song.flac');
      expect(await byFullName.exists(), isTrue);
      expect(byFullName.path, equals(byId.path));

      expect(await manager.hasIsolatedTrack('my_song'), isTrue);
      expect(await manager.hasIsolatedTrack('my_song.flac'), isTrue);
      expect(await manager.hasIsolatedTrack('unknown_track'), isFalse);
    });

    test('getIsolatedTrackFile throws FileSystemException when track is missing', () async {
      expect(
        () => manager.getIsolatedTrackFile('ghost_track'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('VaultMediaIsolationManager Track Removal & Public Export', () {
    test('removeIsolatedTrack zeroes bytes and unlinks track from sandbox', () async {
      final srcFile = File(p.join(tempBaseDir.path, 'to_remove.mp3'));
      await srcFile.writeAsBytes(Uint8List.fromList(List.filled(1024, 0x55)));

      final isolated = await manager.isolateLocalTrack(
        sourceFilePath: srcFile.path,
        trackId: 'track_to_remove',
      );

      expect(await isolated.exists(), isTrue);
      expect(await manager.hasIsolatedTrack('track_to_remove'), isTrue);

      await manager.removeIsolatedTrack('track_to_remove');

      expect(await manager.hasIsolatedTrack('track_to_remove'), isFalse);
      expect(await isolated.exists(), isFalse);
    });

    test('removeIsolatedTrack completes cleanly on non-existent track', () async {
      await expectLater(
        manager.removeIsolatedTrack('non_existent_track'),
        completes,
      );
    });

    test('exportTrackToPublic exports isolated track back to public directory', () async {
      final srcFile = File(p.join(tempBaseDir.path, 'to_export.mp3'));
      final sampleBytes = Uint8List.fromList([11, 22, 33, 44, 55, 66]);
      await srcFile.writeAsBytes(sampleBytes);

      await manager.isolateLocalTrack(
        sourceFilePath: srcFile.path,
        trackId: 'export_test_track',
      );

      final exportDir = Directory(p.join(tempBaseDir.path, 'exported_public'));
      final exportedFile = await manager.exportTrackToPublic(
        trackId: 'export_test_track',
        targetDirectoryPath: exportDir.path,
      );

      expect(await exportedFile.exists(), isTrue);
      expect(await exportedFile.readAsBytes(), equals(sampleBytes));
      expect(p.basename(exportedFile.path), equals('export_test_track.mp3'));
    });

    test('exportTrackToPublic throws FileSystemException for unknown track', () async {
      final exportDir = Directory(p.join(tempBaseDir.path, 'exported_public'));
      expect(
        () => manager.exportTrackToPublic(
          trackId: 'unknown_track',
          targetDirectoryPath: exportDir.path,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('VaultMediaIsolationManager Media Shredding & Concurrency', () {
    test('shredAllIsolatedMedia zeroes and deletes all audio files while preserving .nomedia', () async {
      final mediaDir = await manager.getVaultMediaDirectory();

      final trackFiles = <File>[];
      for (var i = 0; i < 5; i++) {
        final file = File(p.join(mediaDir.path, 'track_$i.mp3'));
        final content = Uint8List.fromList(List.filled(32768, i + 1));
        await file.writeAsBytes(content);
        trackFiles.add(file);
      }

      for (final file in trackFiles) {
        expect(await file.exists(), isTrue);
      }

      await manager.shredAllIsolatedMedia();

      for (final file in trackFiles) {
        expect(await file.exists(), isFalse);
      }

      final remaining = mediaDir.listSync();
      expect(remaining.length, equals(1));
      expect(p.basename(remaining.first.path), equals('.nomedia'));
    });

    test('shredDirectorySync handles subdirectories and empty directories gracefully', () {
      final nestedDir = Directory(p.join(tempBaseDir.path, 'nested_shred'));
      nestedDir.createSync(recursive: true);

      final subDir = Directory(p.join(nestedDir.path, 'sub'));
      subDir.createSync(recursive: true);

      final subFile = File(p.join(subDir.path, 'sub_track.mp3'));
      subFile.writeAsBytesSync(Uint8List.fromList([1, 2, 3]));

      VaultMediaIsolationManager.shredDirectorySync(nestedDir.path);

      expect(subFile.existsSync(), isFalse);
      final sentinel = File(p.join(nestedDir.path, '.nomedia'));
      expect(sentinel.existsSync(), isTrue);
    });

    test('shredSingleFileSync shreds and deletes a single file', () {
      final targetFile = File(p.join(tempBaseDir.path, 'single_shred.mp3'));
      targetFile.writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4, 5]));

      VaultMediaIsolationManager.shredSingleFileSync(targetFile.path);
      expect(targetFile.existsSync(), isFalse);

      // Calling again on deleted file does not throw
      expect(
        () => VaultMediaIsolationManager.shredSingleFileSync(targetFile.path),
        returnsNormally,
      );
    });
  });

  group('VaultMediaIsolationManager Equatable Value Equality', () {
    test('ScopedStorageDeletionSuccess equality and props', () {
      const res1 = ScopedStorageDeletionSuccess(sourcePath: '/path/a.mp3');
      const res2 = ScopedStorageDeletionSuccess(sourcePath: '/path/a.mp3');
      const res3 = ScopedStorageDeletionSuccess(sourcePath: '/path/b.mp3');

      expect(res1, equals(res2));
      expect(res1, isNot(equals(res3)));
      expect(res1.props, equals(['/path/a.mp3']));
    });

    test('ScopedStorageDeletionRestricted equality and props', () {
      const res1 = ScopedStorageDeletionRestricted(
        sourcePath: '/path/a.mp3',
        failureMessage: 'denied',
        osErrorCode: 13,
        markedExcludedInLocalDb: true,
      );
      const res2 = ScopedStorageDeletionRestricted(
        sourcePath: '/path/a.mp3',
        failureMessage: 'denied',
        osErrorCode: 13,
        markedExcludedInLocalDb: true,
      );
      const res3 = ScopedStorageDeletionRestricted(
        sourcePath: '/path/a.mp3',
        failureMessage: 'denied',
        osErrorCode: null,
        markedExcludedInLocalDb: false,
      );

      expect(res1, equals(res2));
      expect(res1, isNot(equals(res3)));
      expect(res1.props, equals(['/path/a.mp3', 'denied', 13, true]));
    });

    test('ScopedStorageDeletionSourceMissing equality and props', () {
      const res1 = ScopedStorageDeletionSourceMissing(sourcePath: '/path/a.mp3');
      const res2 = ScopedStorageDeletionSourceMissing(sourcePath: '/path/a.mp3');

      expect(res1, equals(res2));
      expect(res1.props, equals(['/path/a.mp3']));
    });

    test('IsolatedTrackResult equality and props', () {
      final file = File('/temp/song.mp3');
      const deletionSuccess = ScopedStorageDeletionSuccess(sourcePath: '/path/song.mp3');

      final result1 = IsolatedTrackResult(
        isolatedFile: file,
        relativePath: 'vault_media/.nomedia/song.mp3',
        deletionResult: deletionSuccess,
      );
      final result2 = IsolatedTrackResult(
        isolatedFile: file,
        relativePath: 'vault_media/.nomedia/song.mp3',
        deletionResult: deletionSuccess,
      );

      expect(result1, equals(result2));
      expect(result1.props, equals([file.path, 'vault_media/.nomedia/song.mp3', deletionSuccess]));
    });
  });
}
