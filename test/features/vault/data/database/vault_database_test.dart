import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:path/path.dart' as p;

void main() {
  late VaultDatabase database;

  setUp(() {
    database = VaultDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('VaultDatabase Schema & Table Operations', () {
    test('inserts and retrieves private playlist record', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final encTitle = Uint8List.fromList([1, 2, 3, 4]);
      final encDesc = Uint8List.fromList([5, 6, 7, 8]);

      await database.into(database.vaultPlaylistsTable).insert(
            VaultPlaylistsTableCompanion(
              id: const Value('playlist-1'),
              encryptedTitle: Value(encTitle),
              encryptedDescription: Value(encDesc),
              encryptedCoverPath: const Value(null),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final playlists = await database.select(database.vaultPlaylistsTable).get();
      expect(playlists.length, equals(1));
      expect(playlists.first.id, equals('playlist-1'));
      expect(playlists.first.encryptedTitle, equals(encTitle));
      expect(playlists.first.encryptedDescription, equals(encDesc));
      expect(playlists.first.encryptedCoverPath, isNull);
    });

    test('enforces foreign key cascade deletion for track references', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final encTitle = Uint8List.fromList([1, 2, 3]);
      final encDesc = Uint8List.fromList([4, 5, 6]);

      await database.into(database.vaultPlaylistsTable).insert(
            VaultPlaylistsTableCompanion(
              id: const Value('playlist-cascade'),
              encryptedTitle: Value(encTitle),
              encryptedDescription: Value(encDesc),
              encryptedCoverPath: const Value(null),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await database.into(database.vaultTrackRefsTable).insert(
            VaultTrackRefsTableCompanion(
              id: const Value('track-1'),
              playlistId: const Value('playlist-cascade'),
              trackIndex: const Value(0),
              encryptedTrackMetadata: Value(Uint8List.fromList([10, 11])),
              isolatedMediaFileName: const Value(null),
              encryptedTitle: Value(Uint8List.fromList([12, 13])),
              encryptedArtist: Value(Uint8List.fromList([14, 15])),
              encryptedAlbum: Value(Uint8List.fromList([16, 17])),
              durationMs: const Value(180000),
            ),
          );

      final tracksBefore = await database.select(database.vaultTrackRefsTable).get();
      expect(tracksBefore.length, equals(1));

      // Delete parent playlist
      await (database.delete(database.vaultPlaylistsTable)
            ..where((tbl) => tbl.id.equals('playlist-cascade')))
          .go();

      // Verify track was cascade-deleted by SQLite foreign key constraint
      final tracksAfter = await database.select(database.vaultTrackRefsTable).get();
      expect(tracksAfter.isEmpty, isTrue);
    });

    test('rejects track insertion with invalid foreign key when foreign_keys PRAGMA is active', () async {
      expect(
        () async => database.into(database.vaultTrackRefsTable).insert(
              VaultTrackRefsTableCompanion(
                id: const Value('track-orphan'),
                playlistId: const Value('non-existent-playlist'),
                trackIndex: const Value(0),
                encryptedTrackMetadata: Value(Uint8List.fromList([1])),
                isolatedMediaFileName: const Value(null),
                encryptedTitle: Value(Uint8List.fromList([2])),
                encryptedArtist: Value(Uint8List.fromList([3])),
                encryptedAlbum: Value(Uint8List.fromList([4])),
                durationMs: const Value(120000),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('upserts and retrieves vault configuration', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final payload1 = Uint8List.fromList([1, 2, 3]);
      final payload2 = Uint8List.fromList([4, 5, 6]);

      await database.into(database.vaultConfigTable).insertOnConflictUpdate(
            VaultConfigTableCompanion(
              id: const Value('vault_config'),
              encryptedPayload: Value(payload1),
              updatedAt: Value(now),
            ),
          );

      var config = await database.select(database.vaultConfigTable).getSingle();
      expect(config.encryptedPayload, equals(payload1));

      // Upsert updated payload
      await database.into(database.vaultConfigTable).insertOnConflictUpdate(
            VaultConfigTableCompanion(
              id: const Value('vault_config'),
              encryptedPayload: Value(payload2),
              updatedAt: Value(now + 1000),
            ),
          );

      config = await database.select(database.vaultConfigTable).getSingle();
      expect(config.encryptedPayload, equals(payload2));
    });

    test('upserts and retrieves golden gesture templates', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final points = Uint8List.fromList([10, 20, 30]);
      final rubine = Uint8List.fromList([40, 50, 60]);

      await database.into(database.vaultGestureTemplatesTable).insertOnConflictUpdate(
            VaultGestureTemplatesTableCompanion(
              id: const Value('master_gesture'),
              encryptedPoints64: Value(points),
              encryptedRubine7d: Value(rubine),
              updatedAt: Value(now),
            ),
          );

      final template =
          await database.select(database.vaultGestureTemplatesTable).getSingle();
      expect(template.id, equals('master_gesture'));
      expect(template.encryptedPoints64, equals(points));
      expect(template.encryptedRubine7d, equals(rubine));
    });

    test('persists, queries, and clears unencrypted lockout deadline', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final deadline = now + 30000;

      await database.into(database.vaultLockoutDeadlineTable).insertOnConflictUpdate(
            VaultLockoutDeadlineTableCompanion(
              id: const Value('lockout_deadline'),
              deadlineMonotonicMs: Value(deadline),
              failedAttempts: const Value(5),
              updatedAt: Value(now),
            ),
          );

      var entry =
          await database.select(database.vaultLockoutDeadlineTable).getSingleOrNull();
      expect(entry, isNotNull);
      if (entry case final validEntry?) {
        expect(validEntry.deadlineMonotonicMs, equals(deadline));
        expect(validEntry.failedAttempts, equals(5));
      }

      // Clear lockout deadline
      await (database.delete(database.vaultLockoutDeadlineTable)
            ..where((tbl) => tbl.id.equals('lockout_deadline')))
          .go();

      entry =
          await database.select(database.vaultLockoutDeadlineTable).getSingleOrNull();
      expect(entry, isNull);
    });
  });

  group('VaultDatabase v1 -> v2 Migration & Indexing', () {
    test('creates v2 columns and idx_vault_track_refs_playlist_order on fresh open', () async {
      expect(database.schemaVersion, equals(2));

      final playlistCols =
          await database.customSelect('PRAGMA table_info(vault_playlists);').get();
      final playlistColNames =
          playlistCols.map((row) => row.read<String>('name')).toSet();
      expect(
        playlistColNames,
        containsAll(<String>['payload_version', 'encrypted_playlist_payload']),
      );

      final trackCols =
          await database.customSelect('PRAGMA table_info(vault_track_refs);').get();
      final trackColNames =
          trackCols.map((row) => row.read<String>('name')).toSet();
      expect(
        trackColNames,
        containsAll(<String>['payload_version', 'encrypted_track_payload']),
      );

      final idxRows = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_vault_track_refs_playlist_order';",
          )
          .get();
      expect(idxRows.length, equals(1));
    });

    test('upgrades a v1 database to v2 preserving rows and stays idempotent on repeat upgrade', () async {
      await database.close();
      final tempDir = Directory.systemTemp.createTempSync('vault_v1_upgrade_');
      addTearDown(() async {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
      final dbFile = File(p.join(tempDir.path, 'legacy_v1.sqlite'));

      final nativeV1 = NativeDatabase(
        dbFile,
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = ON;');
          rawDb.execute(
            'CREATE TABLE vault_playlists ('
            'id TEXT NOT NULL PRIMARY KEY, '
            'encrypted_title BLOB NOT NULL, '
            'encrypted_description BLOB NOT NULL, '
            'encrypted_cover_path BLOB, '
            'created_at INTEGER NOT NULL, '
            'updated_at INTEGER NOT NULL);',
          );
          rawDb.execute(
            'CREATE TABLE vault_track_refs ('
            'id TEXT NOT NULL PRIMARY KEY, '
            'playlist_id TEXT NOT NULL REFERENCES vault_playlists(id) ON DELETE CASCADE, '
            'track_index INTEGER NOT NULL, '
            'encrypted_track_metadata BLOB, '
            'isolated_media_file_name TEXT, '
            'encrypted_title BLOB NOT NULL, '
            'encrypted_artist BLOB NOT NULL, '
            'encrypted_album BLOB NOT NULL, '
            'duration_ms INTEGER NOT NULL);',
          );
          rawDb.execute(
            'CREATE TABLE vault_config ('
            'id TEXT NOT NULL PRIMARY KEY, '
            'encrypted_payload BLOB NOT NULL, '
            'updated_at INTEGER NOT NULL);',
          );
          rawDb.execute(
            'CREATE TABLE vault_gesture_templates ('
            'id TEXT NOT NULL PRIMARY KEY, '
            'encrypted_points_64 BLOB NOT NULL, '
            'encrypted_rubine_7d BLOB NOT NULL, '
            'updated_at INTEGER NOT NULL);',
          );
          rawDb.execute(
            'CREATE TABLE vault_lockout_deadline ('
            'id TEXT NOT NULL PRIMARY KEY, '
            'deadline_monotonic_ms INTEGER NOT NULL, '
            'failed_attempts INTEGER NOT NULL, '
            'updated_at INTEGER NOT NULL);',
          );
          rawDb.execute(
            "INSERT INTO vault_playlists VALUES ('pl_v1', X'0102', X'0304', NULL, 1000, 1000);",
          );
          rawDb.execute(
            "INSERT INTO vault_track_refs VALUES ('tr_v1', 'pl_v1', 0, X'0506', NULL, X'0708', X'090A', X'0B0C', 210000);",
          );
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final upgradedDb = VaultDatabase.forTesting(nativeV1);
      addTearDown(upgradedDb.close);

      final migratedPlaylists =
          await upgradedDb.select(upgradedDb.vaultPlaylistsTable).get();
      expect(migratedPlaylists.length, equals(1));
      expect(migratedPlaylists.first.id, equals('pl_v1'));
      expect(migratedPlaylists.first.payloadVersion, equals(1));
      expect(migratedPlaylists.first.encryptedPlaylistPayload, isNull);

      final migratedTracks =
          await upgradedDb.select(upgradedDb.vaultTrackRefsTable).get();
      expect(migratedTracks.length, equals(1));
      expect(migratedTracks.first.id, equals('tr_v1'));
      expect(migratedTracks.first.payloadVersion, equals(1));
      expect(migratedTracks.first.encryptedTrackPayload, isNull);

      final idxRows = await upgradedDb
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_vault_track_refs_playlist_order';",
          )
          .get();
      expect(idxRows.length, equals(1));

      // Verify idempotency when onUpgrade(1 -> 2) is re-invoked cleanly.
      await upgradedDb.migration.onUpgrade(upgradedDb.createMigrator(), 1, 2);
      final afterReupgrade =
          await upgradedDb.select(upgradedDb.vaultPlaylistsTable).get();
      expect(afterReupgrade.length, equals(1));
    });
  });
}
