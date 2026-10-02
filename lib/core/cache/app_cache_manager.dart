import 'dart:developer' as dev;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Centralized cache lifecycle manager.
///
/// Owns the root cache directory tree, enforces user-scoping,
/// handles schema versioning, and provides cleanup/purge operations.
///
/// Directory layout:
///   {appSupportDir}/cache/v{schemaVersion}/{userId}/{namespace}/
///
/// Each feature cache receives its scoped directory via [featureDir]
/// instead of computing its own path. This guarantees:
///   - User A never sees User B's cached data
///   - Schema version bumps auto-invalidate all caches
///   - A single [purgeCurrentUser] call wipes everything for one user
class AppCacheManager {
  /// Bump this when cache format changes. Old versions are deleted on startup.
  static const _schemaVersion = 2;

  /// User directories untouched for this long are deleted on startup.
  static const _staleUserThreshold = Duration(days: 15);

  String? _userId;
  Directory? _userDir;
  int _generation = 0;
  bool _touched = false;

  /// Incremented on every [setUser] call. Feature caches compare this
  /// against their last-loaded generation to detect user switches
  /// and flush stale in-memory state.
  int get generation => _generation;

  /// Whether a user has been set.
  bool get hasUser => _userId != null;

  /// Initializes the manager. Call once at app startup.
  /// Cleans up old schema versions and stale user directories.
  Future<void> init() async {
    await _cleanOldSchemaVersions();
    await _cleanStaleUsers();
  }

  /// Sets the active user. Call after login or session restore.
  Future<void> setUser(String userId) async {
    if (_userId == userId) return;
    _userId = userId;
    _userDir = null;
    _touched = false;
    _generation++;
  }

  /// Returns the root directory for the current user's cache.
  Future<Directory> get userDir async {
    if (_userDir != null) return _userDir!;
    assert(_userId != null, 'Call setUser() before accessing cache directories');
    final schema = await _schemaDir;
    _userDir = Directory('${schema.path}${Platform.pathSeparator}$_userId');
    if (!await _userDir!.exists()) {
      await _userDir!.create(recursive: true);
    }
    return _userDir!;
  }

  /// Returns a directory scoped to the current user and feature namespace.
  /// Creates it if it doesn't exist.
  Future<Directory> featureDir(String namespace) async {
    final root = await userDir;
    final dir = Directory('${root.path}${Platform.pathSeparator}$namespace');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await _touchUserDir();
    return dir;
  }

  /// Deletes all cached data for the current user.
  /// Use for a "Clear Cache" action in settings.
  Future<void> purgeCurrentUser() async {
    if (_userId == null) return;
    try {
      final dir = await userDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      dev.log('AppCacheManager: purge failed: $e');
    }
    _userDir = null;
    _generation++;
  }

  /// Deletes all cached data for all users across all schema versions.
  static Future<void> purgeAll() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final cacheRoot =
          Directory('${appDir.path}${Platform.pathSeparator}cache');
      if (await cacheRoot.exists()) {
        await cacheRoot.delete(recursive: true);
      }
    } catch (e) {
      dev.log('AppCacheManager: purgeAll failed: $e');
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────

  Future<Directory> get _cacheRoot async {
    final appDir = await getApplicationSupportDirectory();
    return Directory('${appDir.path}${Platform.pathSeparator}cache');
  }

  Future<Directory> get _schemaDir async {
    final root = await _cacheRoot;
    return Directory('${root.path}${Platform.pathSeparator}v$_schemaVersion');
  }

  /// Deletes cache directories from previous schema versions.
  Future<void> _cleanOldSchemaVersions() async {
    try {
      final root = await _cacheRoot;
      if (!await root.exists()) return;

      final currentName = 'v$_schemaVersion';
      await for (final entity in root.list()) {
        if (entity is Directory) {
          final name = _dirName(entity);
          if (name.startsWith('v') && name != currentName) {
            dev.log('AppCacheManager: removing old schema dir: $name');
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      dev.log('AppCacheManager: schema cleanup failed: $e');
    }
  }

  /// Deletes user directories that haven't been accessed in 15 days.
  Future<void> _cleanStaleUsers() async {
    try {
      final schema = await _schemaDir;
      if (!await schema.exists()) return;

      final now = DateTime.now();
      await for (final entity in schema.list()) {
        if (entity is Directory) {
          final marker = File(
            '${entity.path}${Platform.pathSeparator}.last_access',
          );
          DateTime lastAccess;
          if (await marker.exists()) {
            lastAccess = await marker.lastModified();
          } else {
            final stat = await entity.stat();
            lastAccess = stat.modified;
          }
          if (now.difference(lastAccess) > _staleUserThreshold) {
            dev.log(
              'AppCacheManager: removing stale user dir: ${_dirName(entity)}',
            );
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      dev.log('AppCacheManager: stale user cleanup failed: $e');
    }
  }

  /// Writes the last-access marker. Called once per session.
  Future<void> _touchUserDir() async {
    if (_touched) return;
    _touched = true;
    try {
      final dir = await userDir;
      final marker = File(
        '${dir.path}${Platform.pathSeparator}.last_access',
      );
      await marker.writeAsString('');
    } catch (_) {}
  }

  static String _dirName(Directory dir) {
    return dir.path.split(Platform.pathSeparator).last;
  }
}
