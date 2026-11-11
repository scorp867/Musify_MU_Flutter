import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_memory_wiper.dart';

/// Sealed hierarchy representing the unlinking outcome of a public source audio file
/// following its isolation into the vault media sandbox.
///
/// Encapsulates Android 10+ (API 29+) Scoped Storage access restrictions and deletion
/// status without throwing unhandled exceptions or returning ambiguous boolean flags.
@immutable
sealed class ScopedStorageDeletionResult extends Equatable {
  const ScopedStorageDeletionResult();

  /// The absolute path of the original source file.
  String get sourcePath;
}

/// Indicates that the public source audio file was successfully unlinked from storage.
final class ScopedStorageDeletionSuccess extends ScopedStorageDeletionResult {
  @override
  final String sourcePath;

  const ScopedStorageDeletionSuccess({required this.sourcePath});

  @override
  List<Object?> get props => [sourcePath];
}

/// Indicates that Scoped Storage permissions (Android 10+ / API 29+) restricted unlinking
/// the original source file without an interactive system permission dialog.
///
/// In this scenario, the audio file is securely copied and preserved in the vault sandbox,
/// and the public track record is marked or excluded from Musify's local database
/// (`AppDatabase.localTracks`) without throwing an unhandled [FileSystemException].
final class ScopedStorageDeletionRestricted extends ScopedStorageDeletionResult {
  @override
  final String sourcePath;

  /// Error message reported by the underlying [FileSystemException].
  final String failureMessage;

  /// Native OS error code (e.g. 13 for EACCES / permission denied) if available.
  final int? osErrorCode;

  /// Whether the track record was excluded or removed from the local database.
  final bool markedExcludedInLocalDb;

  const ScopedStorageDeletionRestricted({
    required this.sourcePath,
    required this.failureMessage,
    required this.osErrorCode,
    required this.markedExcludedInLocalDb,
  });

  @override
  List<Object?> get props => [
        sourcePath,
        failureMessage,
        osErrorCode,
        markedExcludedInLocalDb,
      ];
}

/// Indicates that the original source file was missing or no longer existed when unlinking was attempted.
final class ScopedStorageDeletionSourceMissing extends ScopedStorageDeletionResult {
  @override
  final String sourcePath;

  const ScopedStorageDeletionSourceMissing({required this.sourcePath});

  @override
  List<Object?> get props => [sourcePath];
}

/// Comprehensive outcome of isolating a local audio track into the vault sandbox.
@immutable
final class IsolatedTrackResult extends Equatable {
  /// The isolated, unencrypted raw audio file inside the vault media sandbox.
  final File isolatedFile;

  /// Canonical POSIX relative path within the vault media sandbox (`vault_media/.nomedia/<track_id><extension>`).
  final String relativePath;

  /// Scoped Storage unlinking outcome for the public source file.
  final ScopedStorageDeletionResult deletionResult;

  const IsolatedTrackResult({
    required this.isolatedFile,
    required this.relativePath,
    required this.deletionResult,
  });

  @override
  List<Object?> get props => [isolatedFile.path, relativePath, deletionResult];
}

/// Abstract contract for isolating, querying, exporting, and shredding private media files.
abstract interface class IVaultMediaIsolationManager {
  /// Resolves or initializes the vault media directory `<app_storage>/vault_media/.nomedia/`
  /// and guarantees the presence of the `.nomedia` sentinel file.
  Future<Directory> getVaultMediaDirectory();

  /// Relocates a local audio file from [sourceFilePath] into the vault media sandbox.
  ///
  /// Preserves unencrypted raw audio binary format for native decoder seeking.
  /// Handles Scoped Storage unlinking restrictions safely.
  Future<File> isolateLocalTrack({
    required String sourceFilePath,
    required String trackId,
  });

  /// Detailed variant of [isolateLocalTrack] returning the full [IsolatedTrackResult]
  /// containing the [ScopedStorageDeletionResult].
  Future<IsolatedTrackResult> isolateTrackDetailed({
    required String sourceFilePath,
    required String trackId,
  });

  /// Checks if an isolated media file exists for [trackId].
  Future<bool> hasIsolatedTrack(String trackId);

  /// Retrieves the isolated media [File] for [trackId].
  ///
  /// Throws [FileSystemException] if no isolated file exists for [trackId].
  Future<File> getIsolatedTrackFile(String trackId);

  /// Securely overwrites and deletes the isolated media file for [trackId] from the vault sandbox.
  Future<void> removeIsolatedTrack(String trackId);

  /// Exports an isolated track back to public storage at [targetDirectoryPath].
  Future<File> exportTrackToPublic({
    required String trackId,
    required String targetDirectoryPath,
  });

  /// Securely overwrites all isolated media files in chunks with zeroes via background [Isolate.run],
  /// unlinks them, and recreates the `.nomedia` sentinel file.
  Future<void> shredAllIsolatedMedia();

  /// Computes the canonical POSIX relative path for [trackId], optionally preserving or appending [extension].
  String computeRelativePath(String trackId, {String? extension});
}

/// Concrete implementation of [IVaultMediaIsolationManager].
///
/// Features:
/// 1. Direct Raw Binary Storage: Preserves unencrypted audio bitstreams for C++ native decoder random-access seeking.
/// 2. Filesystem Sandbox: Stores files in `<app_storage>/vault_media/.nomedia/` with a `.nomedia` sentinel file.
/// 3. Scoped Storage Safe Deletion Fallback: Gracefully catches [FileSystemException] on Android 10+ and excludes local DB rows.
/// 4. Background Isolate Offload: Overwrites file blocks in 64KB zero chunks inside [Isolate.run] during media shredding.
final class VaultMediaIsolationManager implements IVaultMediaIsolationManager {
  final Future<Directory> Function()? _baseDirectoryResolver;
  final AppDatabase? _localDatabase;
  final Future<void> Function(String sourcePath)? _localTracksExcluder;
  final Future<void> Function(File file)? _fileDeleter;

  /// Default chunk size for zero-overwriting shredding (64 KB).
  static const int defaultShredChunkSize = 65536;

  /// Creates a [VaultMediaIsolationManager] with optional constructor-injected resolvers for testability.
  const VaultMediaIsolationManager({
    Future<Directory> Function()? baseDirectoryResolver,
    AppDatabase? localDatabase,
    Future<void> Function(String sourcePath)? localTracksExcluder,
    Future<void> Function(File file)? fileDeleter,
  })  : _baseDirectoryResolver = baseDirectoryResolver,
        _localDatabase = localDatabase,
        _localTracksExcluder = localTracksExcluder,
        _fileDeleter = fileDeleter;

  Future<Directory> _getBaseDirectory() {
    if (_baseDirectoryResolver case final resolver?) {
      return resolver();
    }
    return getApplicationDocumentsDirectory();
  }

  Future<void> _deleteFile(File file) {
    if (_fileDeleter case final deleter?) {
      return deleter(file);
    }
    return file.delete();
  }

  Future<bool> _excludeFromLocalDatabase(String sourcePath) async {
    var didExclude = false;
    if (_localTracksExcluder case final excluder?) {
      await excluder(sourcePath);
      didExclude = true;
    }
    if (_localDatabase case final db?) {
      await (db.delete(db.localTracks)
            ..where((tbl) => tbl.dataPath.equals(sourcePath)))
          .go();
      didExclude = true;
    }
    return didExclude;
  }

  /// Verifies that [file] resides strictly inside [mediaDirPath] and is not the `.nomedia` sentinel.
  static bool _isContainedSandboxFile(
    File file,
    String canonicalSandbox,
    String mediaDirPath,
  ) {
    final fileName = p.basename(file.path);
    if (fileName == '.nomedia') {
      return false;
    }
    final canonicalFilePath = p.canonicalize(file.path);
    if (!p.isWithin(canonicalSandbox, canonicalFilePath)) {
      return false;
    }
    if (!p.isWithin(mediaDirPath, file.path)) {
      return false;
    }
    return true;
  }

  @override
  Future<Directory> getVaultMediaDirectory() async {
    final baseDir = await _getBaseDirectory();
    final mediaDirPath = p.join(baseDir.path, 'vault_media', '.nomedia');
    final mediaDir = Directory(mediaDirPath);

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final sentinelPath = p.join(mediaDir.path, '.nomedia');
    final sentinelFile = File(sentinelPath);
    if (!await sentinelFile.exists()) {
      await sentinelFile.create();
    }

    return mediaDir;
  }

  @override
  String computeRelativePath(String trackId, {String? extension}) {
    final cleanId = trackId.trim();
    if (cleanId.isEmpty) {
      throw const FormatException('trackId must not be empty or whitespace.');
    }

    final baseName = p.basename(cleanId);
    if (baseName.isEmpty || baseName == '.' || baseName == '..') {
      throw FormatException('Invalid trackId format: "$trackId"');
    }

    String resolvedExt;
    if (extension case final ext?) {
      final trimmedExt = ext.trim();
      if (trimmedExt.isNotEmpty) {
        resolvedExt = trimmedExt.startsWith('.') ? trimmedExt : '.$trimmedExt';
      } else {
        final existingExt = p.extension(baseName);
        resolvedExt = existingExt.isNotEmpty ? existingExt : '.mp3';
      }
    } else {
      final existingExt = p.extension(baseName);
      resolvedExt = existingExt.isNotEmpty ? existingExt : '.mp3';
    }

    final String finalFileName;
    if (baseName.toLowerCase().endsWith(resolvedExt.toLowerCase())) {
      finalFileName = baseName;
    } else {
      finalFileName = '$baseName$resolvedExt';
    }

    return 'vault_media/.nomedia/$finalFileName';
  }

  @override
  Future<File> isolateLocalTrack({
    required String sourceFilePath,
    required String trackId,
  }) async {
    final result = await isolateTrackDetailed(
      sourceFilePath: sourceFilePath,
      trackId: trackId,
    );
    return result.isolatedFile;
  }

  @override
  Future<IsolatedTrackResult> isolateTrackDetailed({
    required String sourceFilePath,
    required String trackId,
  }) async {
    final cleanSourcePath = sourceFilePath.trim();
    final cleanTrackId = trackId.trim();

    if (cleanSourcePath.isEmpty) {
      throw const FormatException('sourceFilePath must not be empty or whitespace.');
    }
    if (cleanTrackId.isEmpty) {
      throw const FormatException('trackId must not be empty or whitespace.');
    }
    if (cleanTrackId == '.nomedia') {
      throw const FormatException('trackId cannot be sentinel file ".nomedia".');
    }

    final sourceFile = File(cleanSourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Source file does not exist: "$cleanSourcePath"',
        cleanSourcePath,
      );
    }

    final sourceLength = await sourceFile.length();
    if (sourceLength <= 0) {
      throw FileSystemException(
        'Source file is empty (0 bytes): "$cleanSourcePath"',
        cleanSourcePath,
      );
    }

    final sourceExt = p.extension(sourceFile.path);
    final relativePath = computeRelativePath(cleanTrackId, extension: sourceExt);
    final mediaDir = await getVaultMediaDirectory();
    final targetFileName = p.basename(relativePath);
    final targetFile = File(p.join(mediaDir.path, targetFileName));

    await sourceFile.copy(targetFile.path);

    final targetLength = await targetFile.length();
    if (targetLength != sourceLength) {
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      throw FileSystemException(
        'Target file size ($targetLength bytes) does not match source file size ($sourceLength bytes).',
        targetFile.path,
      );
    }

    ScopedStorageDeletionResult deletionResult;
    try {
      if (!await sourceFile.exists()) {
        deletionResult = ScopedStorageDeletionSourceMissing(
          sourcePath: cleanSourcePath,
        );
      } else {
        await _deleteFile(sourceFile);
        deletionResult = ScopedStorageDeletionSuccess(
          sourcePath: cleanSourcePath,
        );
      }
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 2) {
        deletionResult = ScopedStorageDeletionSourceMissing(
          sourcePath: cleanSourcePath,
        );
      } else {
        final markedExcluded = await _excludeFromLocalDatabase(cleanSourcePath);
        final osError = e.osError;
        final errorCode = osError?.errorCode;
        deletionResult = ScopedStorageDeletionRestricted(
          sourcePath: cleanSourcePath,
          failureMessage: e.message,
          osErrorCode: errorCode,
          markedExcludedInLocalDb: markedExcluded,
        );
      }
    }

    return IsolatedTrackResult(
      isolatedFile: targetFile,
      relativePath: relativePath,
      deletionResult: deletionResult,
    );
  }

  Future<File?> _findIsolatedTrackFile(String trackId) async {
    final cleanId = trackId.trim();
    if (cleanId.isEmpty) {
      throw const FormatException('trackId must not be empty or whitespace.');
    }

    if (cleanId == '.nomedia' ||
        cleanId == '.' ||
        cleanId.contains('..') ||
        cleanId.contains('/') ||
        cleanId.contains(r'\') ||
        p.basename(cleanId) != cleanId) {
      return null;
    }

    final mediaDir = await getVaultMediaDirectory();
    final canonicalSandbox = p.canonicalize(mediaDir.path);

    final directFile = File(p.join(mediaDir.path, cleanId));
    if (await directFile.exists()) {
      if (_isContainedSandboxFile(directFile, canonicalSandbox, mediaDir.path)) {
        return directFile;
      }
    }

    if (!cleanId.toLowerCase().endsWith('.mp3')) {
      final mp3File = File(p.join(mediaDir.path, '$cleanId.mp3'));
      if (await mp3File.exists()) {
        if (_isContainedSandboxFile(mp3File, canonicalSandbox, mediaDir.path)) {
          return mp3File;
        }
      }
    }

    final idWithoutExt = p.basenameWithoutExtension(cleanId);
    final entities = await mediaDir.list().toList();
    for (final entity in entities) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name == '.nomedia') {
          continue;
        }
        if (p.basenameWithoutExtension(entity.path) == idWithoutExt) {
          if (_isContainedSandboxFile(entity, canonicalSandbox, mediaDir.path)) {
            return entity;
          }
        }
      }
    }

    return null;
  }

  @override
  Future<bool> hasIsolatedTrack(String trackId) async {
    final cleanId = trackId.trim();
    if (cleanId.isEmpty) {
      throw const FormatException('trackId must not be empty or whitespace.');
    }
    if (cleanId == '.nomedia') {
      return false;
    }

    final file = await _findIsolatedTrackFile(cleanId);
    if (file case final foundFile?) {
      final mediaDir = await getVaultMediaDirectory();
      final canonicalSandbox = p.canonicalize(mediaDir.path);
      return _isContainedSandboxFile(foundFile, canonicalSandbox, mediaDir.path);
    }
    return false;
  }

  @override
  Future<File> getIsolatedTrackFile(String trackId) async {
    final cleanId = trackId.trim();
    if (cleanId.isEmpty) {
      throw const FormatException('trackId must not be empty or whitespace.');
    }

    final mediaDir = await getVaultMediaDirectory();
    final canonicalSandbox = p.canonicalize(mediaDir.path);

    final file = await _findIsolatedTrackFile(cleanId);
    if (file case final foundFile?) {
      if (_isContainedSandboxFile(foundFile, canonicalSandbox, mediaDir.path)) {
        return foundFile;
      }
    }

    throw FileSystemException(
      'Isolated track file not found for trackId: "$trackId"',
      p.join(mediaDir.path, cleanId),
    );
  }

  @override
  Future<void> removeIsolatedTrack(String trackId) async {
    final cleanId = trackId.trim();
    if (cleanId.isEmpty) {
      throw const FormatException('trackId must not be empty or whitespace.');
    }
    if (cleanId == '.nomedia') {
      return;
    }

    final file = await _findIsolatedTrackFile(cleanId);
    if (file case final targetFile?) {
      final mediaDir = await getVaultMediaDirectory();
      final canonicalSandbox = p.canonicalize(mediaDir.path);
      if (!_isContainedSandboxFile(targetFile, canonicalSandbox, mediaDir.path)) {
        return;
      }
      final filePath = targetFile.path;
      await Isolate.run<void>(() {
        shredSingleFileSync(filePath);
      });
    }
  }

  @override
  Future<File> exportTrackToPublic({
    required String trackId,
    required String targetDirectoryPath,
  }) async {
    final cleanTrackId = trackId.trim();
    final cleanTargetPath = targetDirectoryPath.trim();

    if (cleanTrackId.isEmpty) {
      throw const FormatException('trackId must not be empty or whitespace.');
    }
    if (cleanTargetPath.isEmpty) {
      throw const FormatException('targetDirectoryPath must not be empty or whitespace.');
    }
    if (cleanTrackId == '.nomedia') {
      throw FileSystemException(
        'Track file not found or invalid track ID: "$cleanTrackId"',
        cleanTrackId,
      );
    }

    final isolatedFile = await getIsolatedTrackFile(cleanTrackId);
    final mediaDir = await getVaultMediaDirectory();
    final canonicalSandbox = p.canonicalize(mediaDir.path);

    if (!_isContainedSandboxFile(isolatedFile, canonicalSandbox, mediaDir.path)) {
      throw FileSystemException(
        'Track file is outside the vault sandbox: "$cleanTrackId"',
        isolatedFile.path,
      );
    }

    final targetDir = Directory(cleanTargetPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetFilePath = p.join(targetDir.path, p.basename(isolatedFile.path));
    final targetFile = File(targetFilePath);

    await isolatedFile.copy(targetFile.path);

    final srcLength = await isolatedFile.length();
    final dstLength = await targetFile.length();
    if (srcLength != dstLength) {
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      throw FileSystemException(
        'Export verification failed: byte length mismatch ($dstLength != $srcLength)',
        targetFile.path,
      );
    }

    return targetFile;
  }

  @override
  Future<void> shredAllIsolatedMedia() async {
    final mediaDir = await getVaultMediaDirectory();
    final dirPath = mediaDir.path;

    await Isolate.run<void>(() {
      shredDirectorySync(dirPath);
    });
  }

  /// Synchronously shreds a single file by overwriting its content in chunks with zeroes,
  /// flushing to disk, closing the handle, wiping the RAM buffer, and unlinking the file.
  static void shredSingleFileSync(
    String filePath, {
    int chunkSize = defaultShredChunkSize,
  }) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return;
    }

    final length = file.lengthSync();
    if (length > 0) {
      final zeroBuffer = Uint8List(chunkSize);
      RandomAccessFile? raf;
      try {
        raf = file.openSync(mode: FileMode.write);
        var remaining = length;
        while (remaining > 0) {
          final toWrite = remaining > chunkSize ? chunkSize : remaining;
          raf.writeFromSync(zeroBuffer, 0, toWrite);
          remaining -= toWrite;
        }
        raf.flushSync();
      } finally {
        raf?.closeSync();
        VaultMemoryWiper.zeroBuffer(zeroBuffer);
      }
    }

    file.deleteSync();
  }

  /// Synchronously traverses [dirPath], shreds all non-sentinel files, recursively shreds subdirectories,
  /// and guarantees that the `.nomedia` sentinel file is restored.
  static void shredDirectorySync(
    String dirPath, {
    int chunkSize = defaultShredChunkSize,
  }) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      final sentinel = File(p.join(dir.path, '.nomedia'));
      sentinel.createSync();
      return;
    }

    final entities = dir.listSync(recursive: false);
    for (final entity in entities) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name == '.nomedia') {
          continue;
        }
        shredSingleFileSync(entity.path, chunkSize: chunkSize);
      } else if (entity is Directory) {
        shredDirectorySync(entity.path, chunkSize: chunkSize);
        if (entity.existsSync()) {
          entity.deleteSync(recursive: true);
        }
      }
    }

    final sentinel = File(p.join(dir.path, '.nomedia'));
    if (!sentinel.existsSync()) {
      sentinel.createSync();
    }
  }
}
