import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/sorting/device_sorting_comparator.dart';
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';

ConnectDevice _makeDevice({
  required String name,
  required String connectStateIdentifier,
  bool isSelf = false,
  bool isLocal = false,
  bool isActive = false,
  DeviceType type = DeviceType.speaker,
}) {
  return ConnectDevice(
    isSelf: isSelf,
    isActive: isActive,
    isBeingActivated: false,
    isWebapp: false,
    isZeroconf: false,
    isGroup: false,
    isSocialConnect: false,
    supportsLogout: !isSelf,
    supportsVolume: true,
    supportsRename: false,
    creationTimeMs: 1000,
    brandDisplayName: 'Brand',
    modelDisplayName: 'Model',
    localIdentifier: 'local-$connectStateIdentifier',
    connectStateIdentifier: connectStateIdentifier,
    name: name,
    state: ConnectDeviceState.loggedIn,
    type: type,
    incarnations: const <Incarnation>[],
    volume: 32768,
    isNewlyDiscovered: false,
    isDisabled: false,
    capabilities: const <ConnectCapabilityEntry>[],
    hifi: const ConnectHifiStatus(
      fullySupported: false,
      userEligible: false,
      deviceSupported: false,
    ),
    volumeSteps: 100,
    isVoiceEnabled: false,
    isLocal: isLocal,
    localIp: isLocal ? '192.168.1.20' : '',
    supportedMediaTypes: const <String>['audio'],
    supportsDj: false,
    libraryVersion: '1.0.0',
    supportsRemoteSleepTimer: false,
    supportsPlaylistMixing: false,
    supportsZephyr: false,
    supportsRemoteAudioQualityControl: false,
    discoveryMethod: 1,
  );
}

void main() {
  const localId = 'cs-self';

  group('DeviceSortingComparator (Item 160)', () {
    test('effectiveTimestamp resolves self to Long.MAX_VALUE, hashed history, or Long.MIN_VALUE', () {
      final knownHash = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'cs-known',
      );
      final comparator = DeviceSortingComparator(
        localConnectStateIdentifier: localId,
        lastConnectionTimestamps: <String, int>{knownHash: 1700000000000},
      );

      final selfDev = _makeDevice(
        name: 'This Phone',
        connectStateIdentifier: localId,
        isSelf: true,
        isLocal: true,
      );
      final knownDev = _makeDevice(
        name: 'Known Speaker',
        connectStateIdentifier: 'cs-known',
      );
      final unknownDev = _makeDevice(
        name: 'Unknown Speaker',
        connectStateIdentifier: 'cs-unknown',
      );

      expect(
        comparator.effectiveTimestamp(selfDev),
        DeviceSortingComparator.selfEffectiveTimestamp,
      );
      expect(comparator.effectiveTimestamp(knownDev), 1700000000000);
      expect(
        comparator.effectiveTimestamp(unknownDev),
        DeviceSortingComparator.unknownEffectiveTimestamp,
      );

      // Different localConnectStateIdentifier produces different hash -> unknown.
      final otherComparator = DeviceSortingComparator(
        localConnectStateIdentifier: 'cs-other-self',
        lastConnectionTimestamps: <String, int>{knownHash: 1700000000000},
      );
      expect(
        otherComparator.effectiveTimestamp(knownDev),
        DeviceSortingComparator.unknownEffectiveTimestamp,
      );
    });

    test('Stage 1: isSelf always precedes non-self regardless of isLocal or timestamp', () {
      final remoteHash = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'cs-remote',
      );
      final comparator = DeviceSortingComparator(
        localConnectStateIdentifier: localId,
        lastConnectionTimestamps: <String, int>{remoteHash: 9999999999999},
      );

      final selfNonLocal = _makeDevice(
        name: 'Zebra Phone',
        connectStateIdentifier: localId,
        isSelf: true,
        isLocal: false,
      );
      final remoteLocalActive = _makeDevice(
        name: 'Alpha Speaker',
        connectStateIdentifier: 'cs-remote',
        isSelf: false,
        isLocal: true,
        isActive: true,
      );

      expect(comparator.compare(selfNonLocal, remoteLocalActive), -1);
      expect(comparator.compare(remoteLocalActive, selfNonLocal), 1);
    });

    test('Stage 1 tie-break: two isSelf devices skip Stage 2 (isLocal) and sort by name ascending', () {
      final comparator = DeviceSortingComparator(
        localConnectStateIdentifier: localId,
        lastConnectionTimestamps: const <String, int>{},
      );

      final selfNonLocalAlpha = _makeDevice(
        name: 'Alpha Self',
        connectStateIdentifier: 'cs-self-a',
        isSelf: true,
        isLocal: false,
      );
      final selfLocalBeta = _makeDevice(
        name: 'Beta Self',
        connectStateIdentifier: 'cs-self-b',
        isSelf: true,
        isLocal: true,
      );

      expect(comparator.compare(selfNonLocalAlpha, selfLocalBeta), lessThan(0));
      expect(comparator.compare(selfLocalBeta, selfNonLocalAlpha), greaterThan(0));
    });

    test('Stage 2: non-self isLocal precedes non-local even when non-local has newer DB timestamp', () {
      final nonLocalHash = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'cs-cloud',
      );
      final comparator = DeviceSortingComparator(
        localConnectStateIdentifier: localId,
        lastConnectionTimestamps: <String, int>{nonLocalHash: 5000000},
      );

      final localUnknown = _makeDevice(
        name: 'Zeta LAN',
        connectStateIdentifier: 'cs-lan',
        isLocal: true,
      );
      final cloudRecent = _makeDevice(
        name: 'Alpha Cloud',
        connectStateIdentifier: 'cs-cloud',
        isLocal: false,
      );

      expect(comparator.compare(localUnknown, cloudRecent), -1);
      expect(comparator.compare(cloudRecent, localUnknown), 1);
    });

    test('Stage 3: equal isLocal sorts by DB timestamp descending, known before unknown', () {
      final olderHash = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'cs-older',
      );
      final newerHash = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'cs-newer',
      );
      final comparator = DeviceSortingComparator(
        localConnectStateIdentifier: localId,
        lastConnectionTimestamps: <String, int>{
          olderHash: 1000,
          newerHash: 2000,
        },
      );

      final older = _makeDevice(
        name: 'A Older',
        connectStateIdentifier: 'cs-older',
        isLocal: true,
      );
      final newer = _makeDevice(
        name: 'Z Newer',
        connectStateIdentifier: 'cs-newer',
        isLocal: true,
      );
      final unknown = _makeDevice(
        name: '0 Unknown',
        connectStateIdentifier: 'cs-unknown',
        isLocal: true,
      );

      final sorted = comparator.sortDevices(<ConnectDevice>[
        unknown,
        older,
        newer,
      ]);
      expect(
        sorted.map((d) => d.connectStateIdentifier).toList(),
        <String>['cs-newer', 'cs-older', 'cs-unknown'],
      );
    });

    test('Stage 4: tie-breaks by case-sensitive UTF-16 name ascending and ignores isActive', () {
      final comparator = DeviceSortingComparator(
        localConnectStateIdentifier: localId,
        lastConnectionTimestamps: const <String, int>{},
      );

      final alphaUpper = _makeDevice(
        name: 'Alpha',
        connectStateIdentifier: 'id-1',
        isActive: false,
      );
      final zetaUpper = _makeDevice(
        name: 'Zeta',
        connectStateIdentifier: 'id-2',
        isActive: true,
      );
      final alphaLower = _makeDevice(
        name: 'alpha',
        connectStateIdentifier: 'id-3',
        isActive: true,
      );

      // UTF-16 code units: 'A' (65) < 'Z' (90) < 'a' (97).
      final input = <ConnectDevice>[alphaLower, zetaUpper, alphaUpper];
      final sorted = comparator.sortDevices(input);

      expect(
        sorted.map((d) => d.name).toList(),
        <String>['Alpha', 'Zeta', 'alpha'],
      );
      // Non-mutating verification.
      expect(
        input.map((d) => d.name).toList(),
        <String>['alpha', 'Zeta', 'Alpha'],
      );
    });

    test('DeviceSortingComparatorFactory resolves localConnectStateIdentifier and preserves total preorder', () {
      final hashLanOld = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'lan-old',
      );
      final hashLanNew = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'lan-new',
      );
      final hashCloud = hashDeviceIdentifier(
        localConnectStateIdentifier: localId,
        deviceIdentifier: 'cloud-recent',
      );

      final devices = <ConnectDevice>[
        _makeDevice(name: 'beta', connectStateIdentifier: 'cloud-unknown'),
        _makeDevice(name: 'Alpha', connectStateIdentifier: 'cloud-unknown-2'),
        _makeDevice(name: 'Cloud Recent', connectStateIdentifier: 'cloud-recent'),
        _makeDevice(name: 'LAN Old', connectStateIdentifier: 'lan-old', isLocal: true),
        _makeDevice(name: 'LAN New', connectStateIdentifier: 'lan-new', isLocal: true),
        _makeDevice(name: 'This Phone', connectStateIdentifier: localId, isSelf: true),
      ];

      const factory = DeviceSortingComparatorFactory();
      final comparator = factory.createForDevices(
        lastConnectionTimestamps: <String, int>{
          hashLanOld: 100,
          hashLanNew: 200,
          hashCloud: 9999,
        },
        devices: devices,
      );

      final sorted = comparator.sortDevices(devices);
      expect(
        sorted.map((d) => d.connectStateIdentifier).toList(),
        <String>[
          localId,
          'lan-new',
          'lan-old',
          'cloud-recent',
          'cloud-unknown-2', // 'Alpha'
          'cloud-unknown', // 'beta'
        ],
      );

      // Antisymmetry and reflexivity verification across all pairs.
      for (var i = 0; i < devices.length; i++) {
        expect(comparator.compare(devices[i], devices[i]), 0);
        for (var j = i + 1; j < devices.length; j++) {
          final ab = comparator.compare(devices[i], devices[j]);
          final ba = comparator.compare(devices[j], devices[i]);
          expect(ab.sign, equals(-ba.sign));
        }
      }
    });
  });
}
