import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class LocalTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer()(); // ID from on_audio_query
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get dataPath => text()(); // Path to the audio file
  IntColumn get duration => integer().nullable()();
  IntColumn get dateModified =>
      integer().nullable()(); // For syncing metadata changes
}

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

  // Insert a list of tracks
  Future<void> insertTracks(List<LocalTracksCompanion> tracks) async {
    await batch((batch) {
      batch.insertAll(localTracks, tracks, mode: InsertMode.insertOrReplace);
    });
  }

  // Get all tracks (One-time fetch)
  Future<List<LocalTrack>> getAllTracks() => select(localTracks).get();

  // Watch all tracks (Reactive Stream)
  Stream<List<LocalTrack>> watchAllTracks() => select(localTracks).watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'musify_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
