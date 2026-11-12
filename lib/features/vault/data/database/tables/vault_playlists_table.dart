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

  /// Schema row payload version (`1` = legacy per-field blobs, `2` = consolidated JSON payload).
  IntColumn get payloadVersion => integer().withDefault(const Constant(1))();

  /// Consolidated v2 AES-256-GCM encrypted playlist metadata JSON (`description`, `coverUri`).
  BlobColumn get encryptedPlaylistPayload => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
