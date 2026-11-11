import 'package:drift/drift.dart';

/// Drift table schema for encrypted vault configuration (singleton record).
@DataClassName('VaultConfigEntry')
class VaultConfigTable extends Table {
  @override
  String get tableName => 'vault_config';

  /// Singleton identifier (canonical key: 'vault_config').
  TextColumn get id => text()();

  /// AES-256-GCM encrypted JSON payload of all policy enum IDs and decoy persona fields.
  BlobColumn get encryptedPayload => blob()();

  /// Last modification epoch timestamp in milliseconds.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
