// 1:1 replica of com/spotify/connect/devicessortingimpl/data/DevicePickerSortingDatabase.java (lines 9-12),
// com/spotify/connect/devicessortingimpl/data/DevicePickerSortingDatabase_Impl.java (lines 29-72),
// p199p/sus.java (lines 292-294), p199p/qr0.java (lines 152-156, 241-243, 444-452, 685-688),
// p199p/or0.java (lines 55-59, 326-327), p199p/wwj.java (lines 147-170),
// p199p/rus.java (lines 1-15), p199p/qus.java (lines 4-15),
// p199p/azq.java (lines 39-58), p199p/bzq.java (lines 14-23),
// p199p/rdk1.java (lines 1030-1034), and p199p/fc41.java (lines 226-227).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Computes the 64-character lowercase hexadecimal SHA-256 digest of
/// UTF-8 `'$localConnectStateIdentifier$deviceIdentifier'`, matching
/// `p199p/bzq.java:14-23`, `p199p/rdk1.java:1030-1034`, and
/// `p199p/fc41.java:226-227`.
String hashDeviceIdentifier({
  required String localConnectStateIdentifier,
  required String deviceIdentifier,
}) {
  final bytes = utf8.encode('$localConnectStateIdentifier$deviceIdentifier');
  return sha256.convert(bytes).toString();
}

/// Key derivation helper matching `p199p/bzq.java` (`m32547a`).
@immutable
final class DeviceSortingKeyHasher {
  final String localConnectStateIdentifier;

  const DeviceSortingKeyHasher({
    this.localConnectStateIdentifier = '',
  });

  /// Hashes `deviceIdentifier` using [localConnectStateIdentifier] as prefix.
  String hashIdentifier(String deviceIdentifier) {
    return hashDeviceIdentifier(
      localConnectStateIdentifier: localConnectStateIdentifier,
      deviceIdentifier: deviceIdentifier,
    );
  }

  /// Hashes `deviceIdentifier` with an explicit [localConnectStateIdentifier].
  static String hash({
    required String localConnectStateIdentifier,
    required String deviceIdentifier,
  }) {
    return hashDeviceIdentifier(
      localConnectStateIdentifier: localConnectStateIdentifier,
      deviceIdentifier: deviceIdentifier,
    );
  }
}

/// Immutable row entity for table `DeviceLastConnection`, matching
/// `p199p/qus.java:4-15`.
@immutable
final class DeviceLastConnection extends Equatable {
  /// SHA-256 hex digest (`qus.f200493a`, SQLite column `deviceIdentifier`).
  final String deviceIdentifier;

  /// Epoch milliseconds (`qus.f200494b`, SQLite column `timestamp`).
  final int timestamp;

  DeviceLastConnection({
    required this.deviceIdentifier,
    required this.timestamp,
  }) {
    if (deviceIdentifier.isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
    if (timestamp < 0) {
      throw RangeError.value(
        timestamp,
        'timestamp',
        'Must be non-negative',
      );
    }
  }

  @override
  List<Object?> get props => [deviceIdentifier, timestamp];
}

/// 1:1 SQLite database and repository for Connect device last-connection sorting
/// timestamps, replicating `DevicePickerSortingDatabase`, `qr0`, `or0`, `wwj`,
/// `rus`, `qus`, and `azq`.
class DevicePickerSortingDatabase extends GeneratedDatabase {
  /// Exact database file name (`p199p/sus.java:292-294`).
  static const String databaseName = 'DevicePickerSortingDatabase';

  /// Exact Room schema version (`p199p/qr0.java:685-688`).
  static const int databaseVersion = 1;

  /// Exact Room schema identity hashes (`p199p/qr0.java:686`).
  static const String roomIdentityHashV1 = '914d67f6f529727de34d02b66c756daf';
  static const String roomIdentityHashV2 = '35110f9adf249772dd17e1baf16948e8';

  /// Exact table name (`p199p/qr0.java:152-156`).
  static const String tableName = 'DeviceLastConnection';

  /// Exact DDL (`p199p/qr0.java:152-156`).
  static const String createTableSql =
      'CREATE TABLE IF NOT EXISTS `DeviceLastConnection` '
      '(`deviceIdentifier` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, '
      'PRIMARY KEY(`deviceIdentifier`))';

  /// Exact drop DDL (`p199p/qr0.java:241-243`).
  static const String dropTableSql =
      'DROP TABLE IF EXISTS `DeviceLastConnection`';

  /// Exact upsert SQL (`p199p/or0.java:55-59`).
  static const String insertOrReplaceSql =
      'INSERT OR REPLACE INTO `DeviceLastConnection` '
      '(`deviceIdentifier`,`timestamp`) VALUES (?,?)';

  /// Exact query SQL (`p199p/wwj.java:147-170`).
  static const String selectAllOrderedSql =
      'SELECT * FROM DeviceLastConnection ORDER BY timestamp DESC';

  /// Exact logout wipe SQL (`DevicePickerSortingDatabase_Impl.mo7282d()`).
  static const String deleteAllSql = 'DELETE FROM DeviceLastConnection';

  final int Function() _nowMs;
  final StreamController<Map<String, int>> _snapshotsController =
      StreamController<Map<String, int>>.broadcast();
  int _mutationEpoch = 0;
  bool _isClosed = false;

  /// Opens `"DevicePickerSortingDatabase"` in the application documents
  /// directory using a background native SQLite isolate.
  DevicePickerSortingDatabase({
    int Function()? nowMsProvider,
  })  : _nowMs = switch (nowMsProvider) {
          final provider? => provider,
          null => _defaultNowMs,
        },
        super(_openConnection());

  /// Testing constructor accepting an explicit [QueryExecutor] (such as
  /// `NativeDatabase.memory()`).
  DevicePickerSortingDatabase.forTesting(
    super.executor, {
    int Function()? nowMsProvider,
  }) : _nowMs = switch (nowMsProvider) {
          final provider? => provider,
          null => _defaultNowMs,
        };

  static int _defaultNowMs() => DateTime.now().millisecondsSinceEpoch;

  @override
  int get schemaVersion => databaseVersion;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      const <TableInfo<Table, Object?>>[];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      const <DatabaseSchemaEntity>[];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await customStatement(createTableSql);
        },
      );

  /// Records a connection timestamp for [deviceIdentifier], hashed with
  /// [localConnectStateIdentifier] (`p199p/azq.java:54-58`, `p199p/bzq.java:14-23`,
  /// `p199p/or0.java:55-59`).
  Future<void> recordConnection({
    required String deviceIdentifier,
    String localConnectStateIdentifier = '',
    int? timestampMs,
  }) async {
    _ensureOpen();
    if (deviceIdentifier.isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
    final resolvedTimestamp = switch (timestampMs) {
      final value? => value,
      null => _nowMs(),
    };
    final hashedIdentifier = hashDeviceIdentifier(
      localConnectStateIdentifier: localConnectStateIdentifier,
      deviceIdentifier: deviceIdentifier,
    );
    final entity = DeviceLastConnection(
      deviceIdentifier: hashedIdentifier,
      timestamp: resolvedTimestamp,
    );

    await transaction(() async {
      await customInsert(
        insertOrReplaceSql,
        variables: <Variable<Object>>[
          Variable.withString(entity.deviceIdentifier),
          Variable.withInt(entity.timestamp),
        ],
      );
    });
    await _notifyObservers();
  }

  /// Queries all rows ordered by `timestamp DESC` (`p199p/wwj.java:147-170`).
  Future<List<DeviceLastConnection>> getLastConnections() async {
    _ensureOpen();
    final rows = await customSelect(selectAllOrderedSql).get();
    return List<DeviceLastConnection>.unmodifiable(rows.map(_parseRow));
  }

  /// Queries all rows ordered by `timestamp DESC` as an unmodifiable map
  /// keyed by hashed `deviceIdentifier` (`p199p/azq.java:39-51`).
  Future<Map<String, int>> getLastConnectionTimestamps() async {
    final entries = await getLastConnections();
    return _entriesToUnmodifiableMap(entries);
  }

  /// Emits the current `DeviceLastConnection` timestamp map upon subscription
  /// and re-emits on every insert or table clear (Room `InvalidationTracker`
  /// parity in `p199p/in1.java:36-37`, `p199p/roi1.java:123-124`).
  Stream<Map<String, int>> watchLastConnectionTimestamps() {
    return Stream<Map<String, int>>.multi(
      (controller) {
        if (_isClosed || _snapshotsController.isClosed) {
          controller.close();
          return;
        }
        final subscribeEpoch = _mutationEpoch;
        final subscription = _snapshotsController.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;

        getLastConnectionTimestamps().then(
          (initialSnapshot) {
            if (!controller.isClosed &&
                !_isClosed &&
                _mutationEpoch == subscribeEpoch) {
              controller.add(initialSnapshot);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) {
              controller.addError(error, stackTrace);
            }
          },
        );
      },
      isBroadcast: true,
    );
  }

  /// Deletes all rows from `DeviceLastConnection` inside a transaction and
  /// notifies observers (`DevicePickerSortingDatabase_Impl.mo7282d()`).
  Future<void> clearAllTables() async {
    _ensureOpen();
    await transaction(() async {
      await customStatement(deleteAllSql);
    });
    await _notifyObservers();
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    await _snapshotsController.close();
    await super.close();
  }

  Future<void> _notifyObservers() async {
    if (_isClosed || _snapshotsController.isClosed) {
      return;
    }
    _mutationEpoch += 1;
    final snapshot = await getLastConnectionTimestamps();
    if (!_isClosed && !_snapshotsController.isClosed) {
      _snapshotsController.add(snapshot);
    }
  }

  void _ensureOpen() {
    if (_isClosed) {
      throw StateError('DevicePickerSortingDatabase is closed');
    }
  }

  static DeviceLastConnection _parseRow(QueryRow row) {
    final identifier = row.readNullable<String>('deviceIdentifier');
    final timestamp = row.readNullable<int>('timestamp');
    if (identifier == null || identifier.isEmpty) {
      throw const FormatException(
        'DeviceLastConnection.deviceIdentifier must be a non-empty TEXT column',
      );
    }
    if (timestamp == null || timestamp < 0) {
      throw FormatException(
        'DeviceLastConnection.timestamp must be a non-negative INTEGER column',
        timestamp,
      );
    }
    return DeviceLastConnection(
      deviceIdentifier: identifier,
      timestamp: timestamp,
    );
  }

  static Map<String, int> _entriesToUnmodifiableMap(
    Iterable<DeviceLastConnection> entries,
  ) {
    final map = <String, int>{};
    for (final entry in entries) {
      map[entry.deviceIdentifier] = entry.timestamp;
    }
    return Map<String, int>.unmodifiable(map);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, DevicePickerSortingDatabase.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
