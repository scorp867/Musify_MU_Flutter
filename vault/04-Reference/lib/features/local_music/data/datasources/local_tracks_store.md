---
title: "local_tracks_store.dart"
path: "lib/features/local_music/data/datasources/local_tracks_store.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 58
incoming_dependencies: 3
outgoing_dependencies: 1
---

# local_tracks_store.dart

> Source File: `[lib/features/local_music/data/datasources/local_tracks_store.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/data/datasources/local_tracks_store.dart)`
> Layer: `lib/features/local_music/data/datasources`

## Executive Summary
`local_tracks_store.dart` is an essential file in `lib/features/local_music/data/datasources` providing definitions for `LocalTracksStore`, `SongModelData`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_database.dart` | `lib/features/local_music/data/database` | [[04-Reference/lib/features/local_music/data/database/app_database|app_database.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `local_music_repository_impl.dart` | `lib/features/local_music/data/repositories` | [[04-Reference/lib/features/local_music/data/repositories/local_music_repository_impl|local_music_repository_impl.dart]] |
| `local_music_sync_service.dart` | `lib/features/local_music/data/services` | [[04-Reference/lib/features/local_music/data/services/local_music_sync_service|local_music_sync_service.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalTracksStore`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_database` | `AppDatabase` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `getAll` | `Future<List<LocalTrack>>` | `(none)` |
| `watchAll` | `Stream<List<LocalTrack>>` | `(none)` |
| `insertAll` | `Future<void>` | `List<LocalTracksCompanion> tracks` |
| `replace` | `Future<void>` | `LocalTracksCompanion track` |
| `deleteBySongIds` | `Future<void>` | `Set<int> songIds` |
| `where` | `dynamic` | `(track` |
| `companionFor` | `LocalTracksCompanion` | `SongModelData song` |

#### `class SongModelData`
- **Archetype**: Domain Model / Entity

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `songId` | `int` |
| `title` | `String` |
| `artist` | `String?` |
| `album` | `String?` |
| `dataPath` | `String` |
| `duration` | `int?` |
| `dateModified` | `int?` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:drift/drift.dart' as drift;
import 'package:musify_mu/features/local_music/data/database/app_database.dart';

class LocalTracksStore {
  final AppDatabase _database;

  LocalTracksStore(this._database);

  Future<List<LocalTrack>> getAll() => _database.getAllTracks();

  Stream<List<LocalTrack>> watchAll() => _database.watchAllTracks();

  Future<void> insertAll(List<LocalTracksCompanion> tracks) {
    return _database.insertTracks(tracks);
  }

  Future<void> replace(LocalTracksCompanion track) {
    return _database.update(_database.localTracks).replace(track);
  }

  Future<void> deleteBySongIds(Set<int> songIds) {
    return (_database.delete(
      _database.localTracks,
    )..where((track) => track.songId.isIn(songIds))).go();
  }

  LocalTracksCompanion companionFor(SongModelData song) {
    return LocalTracksCompanion.insert(
      songId: song.songId,
      title: song.title,
      artist: drift.Value(song.artist),
      album: drift.Value(song.album),
      dataPath: song.dataPath,
      duration: drift.Value(song.duration),
      dateModified: drift.Value(song.dateModified),
    );
  }
}

class SongModelData {
  final int songId;
  final String title;
  final String? artist;
  final String? album;
  final String dataPath;
// ... [remaining code in source file] ...
```
