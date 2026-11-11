import 'package:drift/drift.dart';

/// Drift table schema for encrypted private playlist metadata.
@DataClassName('VaultPlaylistEntry')
class VaultPlaylistsTable extends Table {
  @override
  String get tableName => 'vault_playlists';

  /// Primary key UUID string.
  TextColumn get id => text()();

  /// AES-256-GCM encrypted playlist title payload.
  BlobColumn get encryptedTitle => blob()();

  /// AES-256-GCM encrypted playlist description payload.
  BlobColumn get encryptedDescription => blob()();

  /// Optional AES-256-GCM encrypted cover artwork URI payload.
  BlobColumn get encryptedCoverPath => blob().nullable()();

  /// Creation epoch timestamp in milliseconds.
  IntColumn get createdAt => integer()();

  /// Last modification epoch timestamp in milliseconds.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
