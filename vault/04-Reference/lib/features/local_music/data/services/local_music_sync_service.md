---
title: "local_music_sync_service.dart"
path: "lib/features/local_music/data/services/local_music_sync_service.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 82
incoming_dependencies: 2
outgoing_dependencies: 3
---

# local_music_sync_service.dart

> Source File: `[lib/features/local_music/data/services/local_music_sync_service.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/data/services/local_music_sync_service.dart)`
> Layer: `lib/features/local_music/data/services`

## Executive Summary
`local_music_sync_service.dart` is an essential file in `lib/features/local_music/data/services` providing definitions for `LocalMusicSyncService`.
**Primary Architecture Role**: Service / Controller

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_database.dart` | `lib/features/local_music/data/database` | [[04-Reference/lib/features/local_music/data/database/app_database|app_database.dart]] |
| `device_music_data_source.dart` | `lib/features/local_music/data/datasources` | [[04-Reference/lib/features/local_music/data/datasources/device_music_data_source|device_music_data_source.dart]] |
| `local_tracks_store.dart` | `lib/features/local_music/data/datasources` | [[04-Reference/lib/features/local_music/data/datasources/local_tracks_store|local_tracks_store.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `local_music_repository_impl.dart` | `lib/features/local_music/data/repositories` | [[04-Reference/lib/features/local_music/data/repositories/local_music_repository_impl|local_music_repository_impl.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalMusicSyncService`
- **Archetype**: Service / Controller

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_deviceMusic` | `DeviceMusicDataSource` |
| `_store` | `LocalTracksStore` |
| `_isSyncing` | `bool` |
| `cachedTracks` | `final` |
| `deviceTracks` | `final` |
| `cachedBySongId` | `final` |
| `deviceBySongId` | `final` |
| `removedSongIds` | `final` |
| `tracksToInsert` | `final` |
| `tracksToUpdate` | `final` |
| `cachedTrack` | `final` |
| `companion` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `sync` | `Future<void>` | `(none)` |
| `_hasMetadataChanged` | `bool` | `LocalTrack cachedTrack, SongModel deviceTrack` |
| `_toData` | `SongModelData` | `SongModel song` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:drift/drift.dart' as drift;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';

class LocalMusicSyncService {
  final DeviceMusicDataSource _deviceMusic;
  final LocalTracksStore _store;

  LocalMusicSyncService({
    required DeviceMusicDataSource deviceMusic,
    required LocalTracksStore store,
  }) : _deviceMusic = deviceMusic,
       _store = store;

  bool _isSyncing = false;

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final cachedTracks = await _store.getAll();
      final deviceTracks = await _deviceMusic.querySongs();

      final cachedBySongId = {
        for (final track in cachedTracks) track.songId: track,
      };
      final deviceBySongId = {for (final track in deviceTracks) track.id: track};
      final removedSongIds = cachedBySongId.keys.toSet().difference(
        deviceBySongId.keys.toSet(),
      );

      final tracksToInsert = <LocalTracksCompanion>[];
      final tracksToUpdate = <LocalTracksCompanion>[];

      for (final deviceTrack in deviceTracks) {
        final cachedTrack = cachedBySongId[deviceTrack.id];
        final companion = _store.companionFor(_toData(deviceTrack));

        if (cachedTrack == null) {
          tracksToInsert.add(companion);
        } else if (_hasMetadataChanged(cachedTrack, deviceTrack)) {
          tracksToUpdate.add(companion.copyWith(id: drift.Value(cachedTrack.id)));
        }
// ... [remaining code in source file] ...
```
