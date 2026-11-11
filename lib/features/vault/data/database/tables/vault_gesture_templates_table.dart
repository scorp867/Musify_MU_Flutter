import 'package:drift/drift.dart';

/// Drift table schema for encrypted golden master gesture templates (singleton record).
@DataClassName('VaultGestureTemplateEntry')
class VaultGestureTemplatesTable extends Table {
  @override
  String get tableName => 'vault_gesture_templates';

  /// Singleton identifier (canonical key: 'master_gesture').
  TextColumn get id => text()();

  /// AES-256-GCM encrypted JSON array of exactly 64 normalized coordinates.
  BlobColumn get encryptedPoints64 => blob()();

  /// AES-256-GCM encrypted JSON array of exactly 7 normalized Rubine features.
  BlobColumn get encryptedRubine7d => blob()();

  /// Synthesis epoch timestamp in milliseconds.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
