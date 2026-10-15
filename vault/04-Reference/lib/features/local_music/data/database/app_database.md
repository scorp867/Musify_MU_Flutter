---
title: "app_database.dart"
path: "lib/features/local_music/data/database/app_database.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local-music, drift, sqlite, database]
lines: 67
incoming_dependencies: 3
outgoing_dependencies: 0
---

# app_database.dart

> Source File: `[lib/features/local_music/data/database/app_database.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/data/database/app_database.dart)`
> Layer: `lib/features/local_music/data/database` (Drift SQLite Engine)

## Executive Summary
`app_database.dart` defines the local SQLite persistence layer using Drift (`drift: ^2.34.4`). It specifies the `LocalTracks` table schema with unique constraints on MediaStore `songId`, implements schema version 2 migration adding `dateModified`, and opens the SQLite database in an isolated background thread via `NativeDatabase.createInBackground`.

**Primary Architecture Role**: Background SQLite Database Engine & Drift Schema Definition

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- `package:drift/drift.dart`: Drift ORM annotations and columns.
- `package:drift/native.dart`: Native C bindings for SQLite.
- `package:path_provider/path_provider.dart`: Documents directory locator.
- Part file: `app_database.g.dart` (compiled via `build_runner`).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `local_tracks_store.dart` | `lib/features/local_music/data/datasources` | [[04-Reference/lib/features/local_music/data/datasources/local_tracks_store|local_tracks_store.dart]] |
| `local_music_repository_impl.dart` | `lib/features/local_music/data/repositories` | [[04-Reference/lib/features/local_music/data/repositories/local_music_repository_impl|local_music_repository_impl.dart]] |

## Declarations & API Breakdown

### Table Definition
#### `class LocalTracks extends Table`
- `IntColumn get id => integer().autoIncrement()()`
- `IntColumn get songId => integer()()`: Unique foreign ID from Android MediaStore / iOS library.
- `TextColumn get title => text()()`
- `TextColumn get artist => text().nullable()()`
- `TextColumn get album => text().nullable()()`
- `TextColumn get dataPath => text()()`: Absolute local filesystem path to audio file.
- `IntColumn get duration => integer().nullable()()`: Duration in milliseconds.
- `IntColumn get dateModified => integer().nullable()()`: Epoch timestamp used to detect metadata revisions.
- `List<Set<Column>> get uniqueKeys => [{songId}]`: Ensures upserting overwrites existing tracks rather than duplicating rows.

### Database Engine
#### `class AppDatabase extends _$AppDatabase`
- `int get schemaVersion => 2`: Schema version.
- `MigrationStrategy get migration`:
  - `onCreate`: Invokes `m.createAll()`.
  - `onUpgrade`: If `from < 2`, executes `m.addColumn(localTracks, localTracks.dateModified)`.
- `Future<void> insertTracks(List<LocalTracksCompanion> tracks)`: Batch insertion using `InsertMode.insertOrReplace`.
- `Future<List<LocalTrack>> getAllTracks()`: One-time asynchronous query.
- `Stream<List<LocalTrack>> watchAllTracks()`: Reactive stream emitting updated lists on table mutations.

## State & Data Flow Analysis
- **Background Execution (`createInBackground`)**:
  ```dart
  LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'musify_db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
  ```
  SQLite queries and disk writes run in a dedicated native background thread, preventing UI frame drops during large initial library scans of 5,000+ audio files.

## Implementation Highlight
```dart
@DriftDatabase(tables: [LocalTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(localTracks, localTracks.dateModified);
        }
      },
    );
  }

  Future<void> insertTracks(List<LocalTracksCompanion> tracks) async {
    await batch((batch) {
      batch.insertAll(localTracks, tracks, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<LocalTrack>> getAllTracks() => select(localTracks).get();
  Stream<List<LocalTrack>> watchAllTracks() => select(localTracks).watch();
}
```
