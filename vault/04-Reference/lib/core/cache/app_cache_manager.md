---
title: "app_cache_manager.dart"
path: "lib/core/cache/app_cache_manager.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, cache]
lines: 190
incoming_dependencies: 12
outgoing_dependencies: 0
---

# app_cache_manager.dart

> Source File: `[lib/core/cache/app_cache_manager.dart](file:///c:/Users/Admin/Musify_MU/lib/core/cache/app_cache_manager.dart)`
> Layer: `lib/core/cache`

## Executive Summary
`app_cache_manager.dart` is an essential file in `lib/core/cache` providing definitions for `AppCacheManager`.
**Primary Architecture Role**: Service / Controller

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_cache.dart` | `lib/features/library/data/cache` | [[04-Reference/lib/features/library/data/cache/library_cache|library_cache.dart]] |
| `playlist_detail_cache.dart` | `lib/features/library/data/cache` | [[04-Reference/lib/features/library/data/cache/playlist_detail_cache|playlist_detail_cache.dart]] |
| `home_feed_cache.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_feed_cache|home_feed_cache.dart]] |
| `home_repository.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_repository|home_repository.dart]] |
| `browse_cache.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_cache|browse_cache.dart]] |
| `browse_repository.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_repository|browse_repository.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `color_cache.dart` | `lib/core/color` | [[04-Reference/lib/core/color/color_cache|color_cache.dart]] |
| `extended_metadata_service.dart` | `lib/core/media` | [[04-Reference/lib/core/media/extended_metadata_service|extended_metadata_service.dart]] |
| `kodiak_disk_cache.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/kodiak_disk_cache|kodiak_disk_cache.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AppCacheManager`
- **Archetype**: Service / Controller

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_userId` | `String?` |
| `_userDir` | `Directory?` |
| `_generation` | `int` |
| `_touched` | `bool` |
| `schema` | `final` |
| `root` | `final` |
| `dir` | `final` |
| `dir` | `return` |
| `dir` | `final` |
| `appDir` | `final` |
| `cacheRoot` | `final` |
| `appDir` | `final` |
| `root` | `final` |
| `root` | `final` |
| `currentName` | `final` |
| `name` | `final` |
| `schema` | `final` |
| `now` | `final` |
| `marker` | `final` |
| `lastAccess` | `DateTime` |
| `stat` | `final` |
| `dir` | `final` |
| `marker` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `init` | `Future<void>` | `(none)` |
| `setUser` | `Future<void>` | `String userId` |
| `featureDir` | `Future<Directory>` | `String namespace` |
| `purgeCurrentUser` | `Future<void>` | `(none)` |
| `purgeAll` | `Future<void>` | `(none)` |
| `_cleanOldSchemaVersions` | `Future<void>` | `(none)` |
| `_cleanStaleUsers` | `Future<void>` | `(none)` |
| `_touchUserDir` | `Future<void>` | `(none)` |
| `_dirName` | `String` | `Directory dir` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
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

// ... [remaining code in source file] ...
```
