import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:musify_mu/features/vault/data/database/tables/vault_config_table.dart';
import 'package:musify_mu/features/vault/data/database/tables/vault_gesture_templates_table.dart';
import 'package:musify_mu/features/vault/data/database/tables/vault_lockout_deadline_table.dart';
import 'package:musify_mu/features/vault/data/database/tables/vault_playlists_table.dart';
import 'package:musify_mu/features/vault/data/database/tables/vault_track_refs_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'vault_database.g.dart';

/// Dedicated Drift SQLite database for encrypted Musify Secure Vault metadata.
///
/// Fully isolated from public music metadata (`musify_db.sqlite`) to guarantee
/// strict cryptographic boundaries, zero plaintext leakage, and atomic shredding.
@DriftDatabase(tables: [
  VaultPlaylistsTable,
  VaultTrackRefsTable,
  VaultConfigTable,
  VaultGestureTemplatesTable,
  VaultLockoutDeadlineTable,
])
class VaultDatabase extends _$VaultDatabase {
  /// Production constructor opening persistent SQLite database in app internal storage.
  VaultDatabase() : super(_openConnection());

  /// Testing constructor accepting custom or in-memory [QueryExecutor].
  VaultDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_vault_track_refs_playlist_order '
            'ON vault_track_refs (playlist_id, track_index);',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await _ensureColumnExists(
              tableName: 'vault_playlists',
              columnName: 'payload_version',
              alterSql:
                  'ALTER TABLE vault_playlists ADD COLUMN payload_version INTEGER NOT NULL DEFAULT 1;',
            );
            await _ensureColumnExists(
              tableName: 'vault_playlists',
              columnName: 'encrypted_playlist_payload',
              alterSql:
                  'ALTER TABLE vault_playlists ADD COLUMN encrypted_playlist_payload BLOB;',
            );
            await _ensureColumnExists(
              tableName: 'vault_track_refs',
              columnName: 'payload_version',
              alterSql:
                  'ALTER TABLE vault_track_refs ADD COLUMN payload_version INTEGER NOT NULL DEFAULT 1;',
            );
            await _ensureColumnExists(
              tableName: 'vault_track_refs',
              columnName: 'encrypted_track_payload',
              alterSql:
                  'ALTER TABLE vault_track_refs ADD COLUMN encrypted_track_payload BLOB;',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_vault_track_refs_playlist_order '
              'ON vault_track_refs (playlist_id, track_index);',
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA secure_delete = ON;');
        },
      );

  Future<void> _ensureColumnExists({
    required String tableName,
    required String columnName,
    required String alterSql,
  }) async {
    final rows = await customSelect('PRAGMA table_info($tableName);').get();
    final hasColumn = rows.any(
      (row) => row.readNullable<String>('name') == columnName,
    );
    if (!hasColumn) {
      await customStatement(alterSql);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(dbFolder.path, 'vault_data'));
    if (!vaultDir.existsSync()) {
      vaultDir.createSync(recursive: true);
    }
    final file = File(p.join(vaultDir.path, 'vault_metadata.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
