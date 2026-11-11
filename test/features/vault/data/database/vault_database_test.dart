import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';

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
}
