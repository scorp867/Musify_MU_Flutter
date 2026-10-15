---
title: "local_music_repository_impl.dart"
path: "lib/features/local_music/data/repositories/local_music_repository_impl.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 64
incoming_dependencies: 1
outgoing_dependencies: 6
---

# local_music_repository_impl.dart

> Source File: `[lib/features/local_music/data/repositories/local_music_repository_impl.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/data/repositories/local_music_repository_impl.dart)`
> Layer: `lib/features/local_music/data/repositories`

## Executive Summary
`local_music_repository_impl.dart` is an essential file in `lib/features/local_music/data/repositories` providing definitions for `LocalMusicRepositoryImpl`.
**Primary Architecture Role**: Repository Pattern

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_database.dart` | `lib/features/local_music/data/database` | [[04-Reference/lib/features/local_music/data/database/app_database|app_database.dart]] |
| `device_music_data_source.dart` | `lib/features/local_music/data/datasources` | [[04-Reference/lib/features/local_music/data/datasources/device_music_data_source|device_music_data_source.dart]] |
| `local_tracks_store.dart` | `lib/features/local_music/data/datasources` | [[04-Reference/lib/features/local_music/data/datasources/local_tracks_store|local_tracks_store.dart]] |
| `local_music_sync_service.dart` | `lib/features/local_music/data/services` | [[04-Reference/lib/features/local_music/data/services/local_music_sync_service|local_music_sync_service.dart]] |
| `domain_track.dart` | `lib/features/local_music/domain/entities` | [[04-Reference/lib/features/local_music/domain/entities/domain_track|domain_track.dart]] |
| `local_music_repository.dart` | `lib/features/local_music/domain/repositories` | [[04-Reference/lib/features/local_music/domain/repositories/local_music_repository|local_music_repository.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalMusicRepositoryImpl`
- **Archetype**: Repository Pattern
- **Implements**: `LocalMusicRepository`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_deviceMusic` | `DeviceMusicDataSource` |
| `_store` | `LocalTracksStore` |
| `_syncService` | `LocalMusicSyncService` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `listen` | `dynamic` | `(_` |
| `dispose` | `void` | `(none)` |
| `requestPermissions` | `Future<bool>` | `(none)` |
| `getLocalTracks` | `Stream<List<DomainTrack>>` | `(none)` |
| `map` | `dynamic` | `(tracks` |
| `_toDomainTrack` | `DomainTrack` | `LocalTrack track` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';

import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/data/services/local_music_sync_service.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';

class LocalMusicRepositoryImpl implements LocalMusicRepository {
  final DeviceMusicDataSource _deviceMusic;
  final LocalTracksStore _store;
  final LocalMusicSyncService _syncService;
  late final StreamSubscription _changesSub;

  LocalMusicRepositoryImpl({
    required DeviceMusicDataSource deviceMusic,
    required LocalTracksStore store,
    required LocalMusicSyncService syncService,
  }) : _deviceMusic = deviceMusic,
       _store = store,
       _syncService = syncService {
    _changesSub = _deviceMusic.changes.listen((_) => unawaited(_syncService.sync()));
  }

  void dispose() {
    _changesSub.cancel();
  }

  @override
  Future<bool> requestPermissions() async {
    if (await _deviceMusic.hasPermission()) return true;
    return _deviceMusic.requestPermission();
  }

  @override
  Stream<List<DomainTrack>> getLocalTracks() async* {
    if (!await requestPermissions()) {
      yield const [];
      return;
    }

    unawaited(_syncService.sync());
    yield* _store.watchAll().map(
      (tracks) => tracks.map(_toDomainTrack).toList(growable: false),
// ... [remaining code in source file] ...
```
