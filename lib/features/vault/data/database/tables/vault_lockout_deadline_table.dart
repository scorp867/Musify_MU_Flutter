import 'package:drift/drift.dart';

/// Drift table schema for unencrypted monotonic brute-force lockout deadlines (singleton record).
///
/// Kept unencrypted by architectural invariant so the authentication coordinator can inspect
/// cooldown state before the hardware master key is unlocked.
@DataClassName('VaultLockoutDeadlineEntry')
class VaultLockoutDeadlineTable extends Table {
  @override
  String get tableName => 'vault_lockout_deadline';

  /// Singleton identifier (canonical key: 'lockout_deadline').
  TextColumn get id => text()();

  /// Monotonic clock deadline timestamp in milliseconds.
  IntColumn get deadlineMonotonicMs => integer()();

  /// Consecutive failed PIN attempts recorded.
  IntColumn get failedAttempts => integer()();

  /// Epoch timestamp in milliseconds when this record was persisted or updated.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
