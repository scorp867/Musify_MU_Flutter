import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';

void main() {
  group('DevicePickerSortingDatabase (Item 159)', () {
    test('creates exact Room v1 DeviceLastConnection schema and constraints', () async {
      final db = DevicePickerSortingDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      expect(DevicePickerSortingDatabase.databaseName, 'DevicePickerSortingDatabase');
      expect(db.schemaVersion, 1);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'DeviceLastConnection';",
          )
          .get();
      expect(tables, hasLength(1));

      final columns =
          await db.customSelect('PRAGMA table_info(DeviceLastConnection);').get();
      expect(columns, hasLength(2));

      final idCol = columns[0];
      expect(idCol.read<String>('name'), 'deviceIdentifier');
      expect(idCol.read<String>('type'), 'TEXT');
      expect(idCol.read<int>('notnull'), 1);
      expect(idCol.read<int>('pk'), 1);

      final tsCol = columns[1];
      expect(tsCol.read<String>('name'), 'timestamp');
      expect(tsCol.read<String>('type'), 'INTEGER');
      expect(tsCol.read<int>('notnull'), 1);
      expect(tsCol.read<int>('pk'), 0);

      final indexes = await db
          .customSelect('PRAGMA index_list(DeviceLastConnection);')
          .get();
      // Only SQLite autoindex for PRIMARY KEY; no secondary indices.
      expect(indexes.where((row) => row.read<int>('unique') == 0), isEmpty);
    });

    test('hashDeviceIdentifier and DeviceSortingKeyHasher match SHA-256 lowercase hex of local + target', () {
      const localId = 'local-cs-123';
      const remoteId = 'remote-cs-456';
      final expected = sha256.convert(utf8.encode('$localId$remoteId')).toString();

      final hashed = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: remoteId,
      );
      expect(hashed, expected);
      expect(hashed, hasLength(64));
      expect(hashed, matches(RegExp(r'^[0-9a-f]{64}$')));

      const hasher = DeviceSortingKeyHasher(localConnectStateIdentifier: localId);
      expect(hasher.hashIdentifier(remoteId), expected);
      expect(
        DeviceSortingKeyHasher.hash(
          localConnectStateIdentifier: '',
          deviceIdentifier: remoteId,
        ),
        sha256.convert(utf8.encode(remoteId)).toString(),
      );
    });

    test('DeviceLastConnection validates non-empty identifier and non-negative timestamp', () {
      final a = DeviceLastConnection(deviceIdentifier: 'abc', timestamp: 0);
      final b = DeviceLastConnection(deviceIdentifier: 'abc', timestamp: 0);
      expect(a, equals(b));

      expect(
        () => DeviceLastConnection(deviceIdentifier: '', timestamp: 100),
        throwsArgumentError,
      );
      expect(
        () => DeviceLastConnection(deviceIdentifier: 'abc', timestamp: -1),
        throwsRangeError,
      );
    });

    test('recordConnection executes INSERT OR REPLACE and reads ORDER BY timestamp DESC', () async {
      final db = DevicePickerSortingDatabase.forTesting(
        NativeDatabase.memory(),
        nowMsProvider: () => 5000,
      );
      addTearDown(db.close);

      const localId = 'local-1';
      await db.recordConnection(
        deviceIdentifier: 'dev-a',
        localConnectStateIdentifier: localId,
        timestampMs: 1000,
      );
      await db.recordConnection(
        deviceIdentifier: 'dev-b',
        localConnectStateIdentifier: localId,
        timestampMs: 3000,
      );
      await db.recordConnection(
        deviceIdentifier: 'dev-c',
        localConnectStateIdentifier: localId,
      );

      final hashA = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'dev-a',
      );
      final hashB = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'dev-b',
      );
      final hashC = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'dev-c',
      );

      final initial = await db.getLastConnectionTimestamps();
      expect(initial.keys.toList(), <String>[hashC, hashB, hashA]);
      expect(initial[hashC], 5000);
      expect(initial[hashB], 3000);
      expect(initial[hashA], 1000);

      // Update dev-a with a newer timestamp -> replaces existing PK without duplicate row.
      await db.recordConnection(
        deviceIdentifier: 'dev-a',
        localConnectStateIdentifier: localId,
        timestampMs: 9000,
      );

      final rows = await db.getLastConnections();
      expect(rows, hasLength(3));
      expect(
        rows.map((e) => e.deviceIdentifier).toList(),
        <String>[hashA, hashC, hashB],
      );
      expect(rows.first.timestamp, 9000);

      expect(
        () => db.recordConnection(deviceIdentifier: ''),
        throwsArgumentError,
      );
      expect(
        () => db.recordConnection(deviceIdentifier: 'dev-x', timestampMs: -10),
        throwsRangeError,
      );
    });

    test('watchLastConnectionTimestamps emits initial snapshot, updates on insert, and clears on clearAllTables', () async {
      final db = DevicePickerSortingDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final emissions = <Map<String, int>>[];
      final sub = db.watchLastConnectionTimestamps().listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions.first, isEmpty);

      await db.recordConnection(
        deviceIdentifier: 'speaker-1',
        localConnectStateIdentifier: 'phone-1',
        timestampMs: 4200,
      );
      await pumpEventQueue();

      final expectedKey = hashDeviceIdentifier(
        localConnectStateIdentifier: 'phone-1',
        deviceIdentifier: 'speaker-1',
      );
      expect(emissions, hasLength(2));
      expect(emissions[1], equals(<String, int>{expectedKey: 4200}));

      await db.clearAllTables();
      await pumpEventQueue();

      expect(emissions, hasLength(3));
      expect(emissions[2], isEmpty);
      expect(await db.getLastConnections(), isEmpty);
    });

    test('fails fast with FormatException when persisted SQLite row violates domain constraints', () async {
      final db = DevicePickerSortingDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customInsert(
        DevicePickerSortingDatabase.insertOrReplaceSql,
        variables: <Variable<Object>>[
          Variable.withString('corrupted-key'),
          Variable.withInt(-99),
        ],
      );

      await expectLater(db.getLastConnections, throwsFormatException);
    });

    test('throws StateError on operations after close and close is idempotent', () async {
      final db = DevicePickerSortingDatabase.forTesting(NativeDatabase.memory());
      await db.close();
      await db.close();

      await expectLater(
        () => db.recordConnection(deviceIdentifier: 'dev-1', timestampMs: 1),
        throwsStateError,
      );
      await expectLater(db.getLastConnections, throwsStateError);
      await expectLater(db.clearAllTables, throwsStateError);
    });
  });
}
