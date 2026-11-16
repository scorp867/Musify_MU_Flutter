import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_data.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

ConnectDevice _buildDevice({
  bool isSelf = false,
  bool isActive = false,
  bool isLocal = false,
  bool supportsVolume = true,
  int volume = 32768,
  int volumeSteps = 64,
  String localIdentifier = 'local-1',
  String connectStateIdentifier = 'cs-1',
  String name = 'Living Room Speaker',
  ConnectDeviceState state = ConnectDeviceState.loggedIn,
  DeviceType type = DeviceType.speaker,
  List<Incarnation> incarnations = const <Incarnation>[],
  List<ConnectCapabilityEntry> capabilities = const <ConnectCapabilityEntry>[],
  List<String> supportedMediaTypes = const <String>['audio/mpeg'],
  OutputPeripheral? outputPeripheral,
  bool? isAuthenticatedWithCurrentUser,
  ConnectGroupData? groupData,
}) {
  return ConnectDevice(
    isSelf: isSelf,
    isActive: isActive,
    isBeingActivated: false,
    isWebapp: false,
    isZeroconf: false,
    isGroup: groupData != null,
    isSocialConnect: false,
    supportsLogout: true,
    supportsVolume: supportsVolume,
    supportsRename: true,
    creationTimeMs: 1700000000000,
    brandDisplayName: 'Spotify',
    modelDisplayName: 'Echo',
    localIdentifier: localIdentifier,
    connectStateIdentifier: connectStateIdentifier,
    name: name,
    state: state,
    type: type,
    incarnations: incarnations,
    volume: volume,
    isNewlyDiscovered: false,
    isDisabled: false,
    capabilities: capabilities,
    hifi: const ConnectHifiStatus(
      fullySupported: true,
      userEligible: true,
      deviceSupported: true,
    ),
    outputPeripheral: outputPeripheral,
    volumeSteps: volumeSteps,
    isVoiceEnabled: false,
    isLocal: isLocal,
    localIp: '192.168.1.50',
    supportedMediaTypes: supportedMediaTypes,
    supportsDj: true,
    libraryVersion: '1.2.3',
    supportsRemoteSleepTimer: true,
    supportsPlaylistMixing: false,
    supportsZephyr: false,
    supportsRemoteAudioQualityControl: true,
    discoveryMethod: 1,
    isAuthenticatedWithCurrentUser: isAuthenticatedWithCurrentUser,
    groupData: groupData,
  );
}

void main() {
  group('DeviceType (Item 150)', () {
    test('has exact 17 variants in p199p/t3t.java ordinal order', () {
      expect(DeviceType.values, const <DeviceType>[
        DeviceType.unknown,
        DeviceType.computer,
        DeviceType.tablet,
        DeviceType.smartphone,
        DeviceType.speaker,
        DeviceType.tv,
        DeviceType.avr,
        DeviceType.stb,
        DeviceType.audioDongle,
        DeviceType.gameConsole,
        DeviceType.castVideo,
        DeviceType.castAudio,
        DeviceType.automobile,
        DeviceType.smartwatch,
        DeviceType.chromebook,
        DeviceType.unknownSpotifyHw,
        DeviceType.homeThing,
      ]);
      expect(DeviceType.values.length, 17);
    });

    test('fromWireName parses all t3t names, proto aliases, and throws on empty',
        () {
      for (final value in DeviceType.values) {
        expect(DeviceType.fromWireName(value.wireName), value);
        expect(
          DeviceType.fromWireName('  ${value.wireName.toLowerCase()}  '),
          value,
        );
      }

      expect(
        DeviceType.fromWireName('UNKNOWN_SPOTIFY'),
        DeviceType.unknownSpotifyHw,
      );
      expect(DeviceType.fromWireName('HOME_THING'), DeviceType.homeThing);
      expect(DeviceType.fromWireName('CAR_THING'), DeviceType.unknown);
      expect(DeviceType.fromWireName('OBSERVER'), DeviceType.unknown);
      expect(DeviceType.fromWireName('GLASSES'), DeviceType.unknown);
      expect(DeviceType.fromWireName('UNRECOGNIZED_DEVICE'), DeviceType.unknown);

      expect(() => DeviceType.fromWireName(''), throwsFormatException);
      expect(() => DeviceType.fromWireName('   '), throwsFormatException);
    });
  });

  group('GroupingStatus (Item 151)', () {
    test('has exact 4 variants in p199p/im40.java order', () {
      expect(GroupingStatus.values, const <GroupingStatus>[
        GroupingStatus.unknown,
        GroupingStatus.grouped,
        GroupingStatus.groupable,
        GroupingStatus.connecting,
      ]);
    });

    test('fromProtoIndex and fromWireName map and fail fast', () {
      expect(GroupingStatus.fromProtoIndex(0), GroupingStatus.unknown);
      expect(GroupingStatus.fromProtoIndex(1), GroupingStatus.grouped);
      expect(GroupingStatus.fromProtoIndex(2), GroupingStatus.groupable);
      expect(GroupingStatus.fromProtoIndex(3), GroupingStatus.connecting);
      expect(() => GroupingStatus.fromProtoIndex(-1), throwsRangeError);
      expect(() => GroupingStatus.fromProtoIndex(4), throwsRangeError);

      expect(
        GroupingStatus.fromWireName('UNKNOWN_GROUPING_STATUS'),
        GroupingStatus.unknown,
      );
      expect(GroupingStatus.fromWireName('GROUPED'), GroupingStatus.grouped);
      expect(
        GroupingStatus.fromWireName('GROUPABLE'),
        GroupingStatus.groupable,
      );
      expect(
        GroupingStatus.fromWireName('GROUPING'),
        GroupingStatus.connecting,
      );
      expect(
        GroupingStatus.fromWireName('connecting'),
        GroupingStatus.connecting,
      );
      expect(() => GroupingStatus.fromWireName(''), throwsFormatException);
      expect(
        () => GroupingStatus.fromWireName('INVALID'),
        throwsFormatException,
      );
    });
  });

  group('ConnectHifiStatus (Item 149)', () {
    test('supports value equality, hashCode, and copyWith', () {
      const a = ConnectHifiStatus(
        fullySupported: true,
        userEligible: true,
        deviceSupported: false,
      );
      const b = ConnectHifiStatus(
        fullySupported: true,
        userEligible: true,
        deviceSupported: false,
      );
      final c = a.copyWith(deviceSupported: true);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(c.deviceSupported, isTrue);
      expect(c, isNot(equals(a)));
    });
  });

  group('Incarnation (Item 148)', () {
    test('preserves exact wire strings including CAST_JS and parses enums', () {
      const a = Incarnation(
        loginType: 'CAST_JS',
        identifier: 'cast-id-1',
        preferred: true,
        preferredReason: 'user_selected',
        connectStateIdentifier: 'cs-id-1',
      );
      const b = Incarnation(
        loginType: 'CAST_JS',
        identifier: 'cast-id-1',
        preferred: true,
        preferredReason: 'user_selected',
        connectStateIdentifier: 'cs-id-1',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.parsedLoginType, IncarnationLoginType.castJs);
      expect(
        a.parsedPreferredReason,
        IncarnationPreferredReason.userSelected,
      );

      final custom = a.copyWith(
        loginType: 'CUSTOM_PROTO',
        preferredReason: 'custom_reason',
      );
      expect(custom.loginType, 'CUSTOM_PROTO');
      expect(custom.parsedLoginType, isNull);
      expect(custom.parsedPreferredReason, isNull);

      expect(
        IncarnationLoginType.fromWireName('CONNECT'),
        IncarnationLoginType.connect,
      );
      expect(
        IncarnationLoginType.fromWireName('CAST'),
        IncarnationLoginType.cast,
      );
      expect(
        () => IncarnationLoginType.fromWireName(''),
        throwsFormatException,
      );
      expect(
        () => IncarnationLoginType.fromWireName('OTHER'),
        throwsFormatException,
      );

      expect(
        IncarnationPreferredReason.fromWireName('default'),
        IncarnationPreferredReason.defaultReason,
      );
      expect(
        IncarnationPreferredReason.fromWireName('stream_expansion'),
        IncarnationPreferredReason.streamExpansion,
      );
      expect(
        IncarnationPreferredReason.fromWireName('android_tv'),
        IncarnationPreferredReason.androidTv,
      );
      expect(
        IncarnationPreferredReason.fromWireName('tap_device'),
        IncarnationPreferredReason.tapDevice,
      );
      expect(
        () => IncarnationPreferredReason.fromWireName(''),
        throwsFormatException,
      );
    });
  });

  group('OutputPeripheral (Item 147)', () {
    test('models unset enums as null instead of sentinel 0 and clears cleanly',
        () {
      const unset = OutputPeripheral();
      expect(unset.hasConnectionType, isFalse);
      expect(unset.hasCategory, isFalse);
      expect(unset.connectionType, isNull);
      expect(unset.category, isNull);

      expect(OutputPeripheralConnectionType.fromK7kCode(0), isNull);
      expect(
        OutputPeripheralConnectionType.fromK7kCode(1),
        OutputPeripheralConnectionType.unknown,
      );
      expect(
        OutputPeripheralConnectionType.fromK7kCode(4),
        OutputPeripheralConnectionType.bluetooth,
      );
      expect(
        () => OutputPeripheralConnectionType.fromK7kCode(7),
        throwsRangeError,
      );
      expect(
        OutputPeripheralConnectionType.fromProtoIndex(5),
        OutputPeripheralConnectionType.builtInSpeaker,
      );
      expect(
        () => OutputPeripheralConnectionType.fromProtoIndex(6),
        throwsRangeError,
      );

      expect(OutputPeripheralCategory.fromK7kCode(0), isNull);
      expect(
        OutputPeripheralCategory.fromK7kCode(3),
        OutputPeripheralCategory.headphones,
      );
      expect(
        () => OutputPeripheralCategory.fromK7kCode(8),
        throwsRangeError,
      );
      expect(
        OutputPeripheralCategory.fromProtoIndex(6),
        OutputPeripheralCategory.app,
      );
      expect(
        () => OutputPeripheralCategory.fromProtoIndex(7),
        throwsRangeError,
      );

      const wired = OutputPeripheral(
        name: 'WH-1000XM5',
        brand: 'Sony',
        model: 'XM5',
        connectionType: OutputPeripheralConnectionType.bluetooth,
        category: OutputPeripheralCategory.headphones,
      );
      expect(wired.hasConnectionType, isTrue);
      expect(wired.hasCategory, isTrue);

      final cleared = wired.copyWith(
        clearName: true,
        clearBrand: true,
        clearModel: true,
        clearConnectionType: true,
        clearCategory: true,
      );
      expect(cleared, equals(unset));
      expect(cleared.hashCode, equals(unset.hashCode));
    });
  });

  group('ConnectCapabilities & ConnectCapabilityEntry (Item 143)', () {
    test('Equatable compares UnmodifiableMapView and UnmodifiableListView equally',
        () {
      final entryA = ConnectCapabilityEntry(
        id: 'dj',
        defaultTitle: 'DJ',
        iconUrl: 'https://example.com/icon.png',
        redirectUris: const ConnectCapabilityRedirectUris(
          android: ConnectCapabilityAndroidUris(
            uri: 'spotify://dj',
            redirectBackAppParam: 'back',
            deviceNameParam: 'dev',
            fallbackUrl: 'https://spotify.com',
          ),
        ),
        localizedTitle: <String, String>{'en': 'DJ', 'es': 'DJ ES'},
      );
      final mapInput = <String, String>{'en': 'DJ', 'es': 'DJ ES'};
      final entryB = ConnectCapabilityEntry(
        id: 'dj',
        defaultTitle: 'DJ',
        iconUrl: 'https://example.com/icon.png',
        redirectUris: const ConnectCapabilityRedirectUris(
          android: ConnectCapabilityAndroidUris(
            uri: 'spotify://dj',
            redirectBackAppParam: 'back',
            deviceNameParam: 'dev',
            fallbackUrl: 'https://spotify.com',
          ),
        ),
        localizedTitle: mapInput,
      );
      mapInput['fr'] = 'Mutated';

      expect(entryA, equals(entryB));
      expect(entryA.hashCode, equals(entryB.hashCode));
      final localized = entryB.localizedTitle;
      expect(localized, isA<UnmodifiableMapView<String, String>>());
      expect(localized?.containsKey('fr'), isFalse);
      expect(
        () => localized?.remove('en'),
        throwsUnsupportedError,
      );

      final capsA = ConnectCapabilities(
        canBePlayer: true,
        volumeSteps: 64,
        supportedTypes: <String>['audio/track', 'audio/episode'],
        disableVolume: false,
        supportsHifi: const ConnectHifiStatus(
          fullySupported: true,
          userEligible: true,
          deviceSupported: true,
        ),
        supportedAudioQuality: ConnectAudioQuality.hifi24,
      );
      final listInput = <String>['audio/track', 'audio/episode'];
      final capsB = ConnectCapabilities(
        canBePlayer: true,
        volumeSteps: 64,
        supportedTypes: listInput,
        disableVolume: false,
        supportsHifi: const ConnectHifiStatus(
          fullySupported: true,
          userEligible: true,
          deviceSupported: true,
        ),
        supportedAudioQuality: ConnectAudioQuality.hifi24,
      );
      listInput.add('audio/ad');

      expect(capsA, equals(capsB));
      expect(capsA.hashCode, equals(capsB.hashCode));
      expect(capsA.supportsVolume, isTrue);
      expect(capsB.supportedTypes.length, 2);
      expect(() => capsB.supportedTypes.add('x'), throwsUnsupportedError);

      final cleared = capsA.copyWith(
        disableVolume: true,
        clearSupportsHifi: true,
      );
      expect(cleared.supportsVolume, isFalse);
      expect(cleared.supportsHifi, isNull);

      expect(
        () => ConnectCapabilities(volumeSteps: -1),
        throwsRangeError,
      );
      expect(
        () => ConnectAudioQuality.fromProtoIndex(7),
        throwsRangeError,
      );
    });
  });

  group('ConnectVolumeState & GroupDeviceVolume (Item 144)', () {
    test('validates bounds, converts wire volumes, and derives state', () {
      expect(kMaxConnectVolumeWire, 65535);

      final gVol = GroupDeviceVolume.fromWire(
        rawVolume: 65535,
        volumeSteps: 50,
      );
      expect(gVol.volume, 1.0);
      expect(gVol.toWireVolume(), 65535);
      expect(gVol.stepSize, closeTo(0.02, 1e-12));

      expect(
        () => GroupDeviceVolume(volume: -0.01),
        throwsRangeError,
      );
      expect(
        () => GroupDeviceVolume(volume: 1.01),
        throwsRangeError,
      );
      expect(
        () => GroupDeviceVolume(volume: double.nan),
        throwsRangeError,
      );
      expect(
        () => GroupDeviceVolume(volume: double.infinity),
        throwsRangeError,
      );
      expect(
        () => GroupDeviceVolume(volume: 0.5, volumeSteps: -1),
        throwsRangeError,
      );
      expect(
        () => GroupDeviceVolume.fromWire(rawVolume: -1),
        throwsRangeError,
      );
      expect(
        () => GroupDeviceVolume.fromWire(rawVolume: 65536),
        throwsRangeError,
      );

      final remoteDevice = _buildDevice(
        isLocal: false,
        supportsVolume: true,
        volumeSteps: 64,
      );
      final stateA = ConnectVolumeState(
        remoteVolume: 0.0,
        localVolume: 0.5,
        activeDevice: remoteDevice,
        outputMode: VolumeOutputMode.remote,
        isChangingVolume: false,
        status: ConnectVolumeStatus.ok,
        activeDeviceConnectStateIdentifier: 'cs-1',
        groupDeviceVolumes: <String, GroupDeviceVolume>{
          'g1': GroupDeviceVolume(volume: 0.5, volumeSteps: 20),
        },
        pendingGroupDeviceIds: <String>{'g1'},
      );
      final mapInput = <String, GroupDeviceVolume>{
        'g1': GroupDeviceVolume(volume: 0.5, volumeSteps: 20),
      };
      final setInput = <String>{'g1'};
      final stateB = ConnectVolumeState(
        remoteVolume: 0.0,
        localVolume: 0.5,
        activeDevice: remoteDevice,
        outputMode: VolumeOutputMode.remote,
        isChangingVolume: false,
        status: ConnectVolumeStatus.ok,
        activeDeviceConnectStateIdentifier: 'cs-1',
        groupDeviceVolumes: mapInput,
        pendingGroupDeviceIds: setInput,
      );
      mapInput['g2'] = GroupDeviceVolume(volume: 1.0);
      setInput.add('g2');

      expect(stateA, equals(stateB));
      expect(stateA.hashCode, equals(stateB.hashCode));
      expect(stateA.effectiveVolume, 0.0);
      expect(stateA.isMuted, isTrue);
      expect(stateA.isRemoteVolumeControllable, isTrue);
      expect(stateA.stepSize, closeTo(1.0 / 64, 1e-12));
      expect(
        () => stateB.groupDeviceVolumes.remove('g1'),
        throwsUnsupportedError,
      );
      expect(
        () => stateB.pendingGroupDeviceIds.add('g3'),
        throwsUnsupportedError,
      );

      final localMode = stateA.copyWith(outputMode: VolumeOutputMode.local);
      expect(localMode.effectiveVolume, 0.5);
      expect(localMode.isMuted, isFalse);

      expect(
        () => ConnectVolumeState(remoteVolume: 1.5),
        throwsRangeError,
      );
      expect(
        () => ConnectVolumeState(localVolume: -0.1),
        throwsRangeError,
      );
      expect(
        () => ConnectVolumeStatus.fromProtoIndex(5),
        throwsRangeError,
      );
    });
  });

  group('ConnectGroupDevice & ConnectGroupData (Items 145–146)', () {
    test('enforces non-empty groupDeviceIdentifier and non-negative maxDevices',
        () {
      expect(
        () => GroupDeviceIdentifiers(groupDeviceIdentifier: ''),
        throwsArgumentError,
      );
      expect(
        () => ConnectGroupCapabilities(maxDevices: -1),
        throwsRangeError,
      );

      final memberA = ConnectGroupDevice(
        identifiers: GroupDeviceIdentifiers(
          groupDeviceIdentifier: 'group-dev-1',
          connectStateIdentifier: 'cs-sub-1',
        ),
        name: 'Kitchen',
        deviceType: DeviceType.speaker,
        modelDisplayName: 'Sonos One',
        capabilities: const GroupDeviceCapabilities(
          removable: true,
          removalDissolvesGroup: false,
        ),
        groupingStatus: GroupingStatus.grouped,
        volume: GroupDeviceVolume(volume: 0.75, volumeSteps: 100),
      );
      final memberB = memberA.copyWith();

      final groupA = ConnectGroupData(
        devices: <ConnectGroupDevice>[memberA],
        capabilities: ConnectGroupCapabilities(maxDevices: 5),
      );
      final groupB = ConnectGroupData(
        devices: <ConnectGroupDevice>[memberB],
        capabilities: ConnectGroupCapabilities(maxDevices: 5),
      );

      expect(groupA, equals(groupB));
      expect(groupA.hashCode, equals(groupB.hashCode));
      expect(() => groupA.devices.add(memberA), throwsUnsupportedError);
      expect(memberA.copyWith(clearVolume: true).volume, isNull);
    });
  });

  group('ConnectDevice (Item 141)', () {
    test('ConnectDeviceState has 22 variants and parses wire names', () {
      expect(ConnectDeviceState.values.length, 22);
      for (final state in ConnectDeviceState.values) {
        expect(ConnectDeviceState.fromWireName(state.wireName), state);
      }
      expect(
        ConnectDeviceState.fromWireName('logged_in'),
        ConnectDeviceState.loggedIn,
      );
      expect(
        ConnectDeviceState.fromWireName('SOME_FUTURE_STATE'),
        ConnectDeviceState.unknown,
      );
      expect(() => ConnectDeviceState.fromWireName(''), throwsFormatException);
    });

    test('validates bounds, enforces immutability, and clears nullables cleanly',
        () {
      final incarnations = <Incarnation>[
        const Incarnation(
          loginType: 'CONNECT',
          identifier: 'inc-1',
          preferred: true,
          preferredReason: 'default',
          connectStateIdentifier: 'cs-1',
        ),
      ];
      final capabilities = <ConnectCapabilityEntry>[
        ConnectCapabilityEntry(id: 'cap-1', defaultTitle: 'Cap'),
      ];
      final mediaTypes = <String>['audio/mpeg'];

      final deviceA = _buildDevice(
        incarnations: incarnations,
        capabilities: capabilities,
        supportedMediaTypes: mediaTypes,
        outputPeripheral: const OutputPeripheral(
          name: 'AirPods',
          connectionType: OutputPeripheralConnectionType.bluetooth,
          category: OutputPeripheralCategory.headphones,
        ),
        isAuthenticatedWithCurrentUser: true,
        groupData: ConnectGroupData(
          devices: const <ConnectGroupDevice>[],
          capabilities: ConnectGroupCapabilities(maxDevices: 4),
        ),
      );
      final deviceB = _buildDevice(
        incarnations: List<Incarnation>.of(incarnations),
        capabilities: List<ConnectCapabilityEntry>.of(capabilities),
        supportedMediaTypes: List<String>.of(mediaTypes),
        outputPeripheral: const OutputPeripheral(
          name: 'AirPods',
          connectionType: OutputPeripheralConnectionType.bluetooth,
          category: OutputPeripheralCategory.headphones,
        ),
        isAuthenticatedWithCurrentUser: true,
        groupData: ConnectGroupData(
          devices: const <ConnectGroupDevice>[],
          capabilities: ConnectGroupCapabilities(maxDevices: 4),
        ),
      );

      expect(deviceA, equals(deviceB));
      expect(deviceA.hashCode, equals(deviceB.hashCode));
      expect(deviceA.normalizedVolume, closeTo(32768 / 65535.0, 1e-12));
      expect(deviceA.isOffline, isFalse);
      expect(deviceA.isVolumeControllable, isTrue);

      expect(
        deviceA.copyWith(state: ConnectDeviceState.unavailable).isOffline,
        isTrue,
      );
      expect(deviceA.copyWith(isLocal: true).isVolumeControllable, isFalse);

      final cleared = deviceA.copyWith(
        clearOutputPeripheral: true,
        clearIsAuthenticatedWithCurrentUser: true,
        clearGroupData: true,
      );
      expect(cleared.outputPeripheral, isNull);
      expect(cleared.isAuthenticatedWithCurrentUser, isNull);
      expect(cleared.groupData, isNull);

      expect(
        () => _buildDevice(volume: -1),
        throwsRangeError,
      );
      expect(
        () => _buildDevice(volume: 65536),
        throwsRangeError,
      );
      expect(
        () => _buildDevice(volumeSteps: -1),
        throwsRangeError,
      );
      expect(
        () => ConnectDevice(
          isSelf: false,
          isActive: false,
          isBeingActivated: false,
          isWebapp: false,
          isZeroconf: false,
          isGroup: false,
          isSocialConnect: false,
          supportsLogout: false,
          supportsVolume: false,
          supportsRename: false,
          creationTimeMs: -1,
          brandDisplayName: '',
          modelDisplayName: '',
          localIdentifier: '',
          connectStateIdentifier: '',
          name: '',
          state: ConnectDeviceState.unknown,
          type: DeviceType.unknown,
          incarnations: const <Incarnation>[],
          volume: 0,
          isNewlyDiscovered: false,
          isDisabled: false,
          capabilities: const <ConnectCapabilityEntry>[],
          hifi: const ConnectHifiStatus(
            fullySupported: false,
            userEligible: false,
            deviceSupported: false,
          ),
          volumeSteps: 0,
          isVoiceEnabled: false,
          isLocal: false,
          localIp: '',
          supportedMediaTypes: const <String>[],
          supportsDj: false,
          libraryVersion: '',
          supportsRemoteSleepTimer: false,
          supportsPlaylistMixing: false,
          supportsZephyr: false,
          supportsRemoteAudioQualityControl: false,
          discoveryMethod: 0,
        ),
        throwsRangeError,
      );
    });
  });

  group('ConnectCluster (Item 142)', () {
    test('derives active, local, remote devices, activeDeviceId, and devicesById',
        () {
      final selfInactive = _buildDevice(
        isSelf: true,
        isActive: false,
        isLocal: true,
        localIdentifier: 'local-self',
        connectStateIdentifier: 'cs-self',
        name: 'This Phone',
      );
      final remoteActive = _buildDevice(
        isSelf: false,
        isActive: true,
        isLocal: false,
        localIdentifier: 'local-remote',
        connectStateIdentifier: 'cs-remote',
        name: 'Receiver',
      );
      final fallbackIdDevice = _buildDevice(
        isSelf: false,
        isActive: false,
        localIdentifier: 'local-only',
        connectStateIdentifier: '',
        name: 'Cast Device',
      );

      final clusterA = ConnectCluster(
        isActive: true,
        shouldUseLocalPlayback: false,
        devices: <ConnectDevice>[
          selfInactive,
          remoteActive,
          fallbackIdDevice,
        ],
        isActiveOnSameDevice: false,
        isSyncedWithBackend: true,
      );
      final clusterB = ConnectCluster(
        isActive: true,
        shouldUseLocalPlayback: false,
        devices: <ConnectDevice>[
          selfInactive,
          remoteActive,
          fallbackIdDevice,
        ],
        isActiveOnSameDevice: false,
        isSyncedWithBackend: true,
      );

      expect(clusterA, equals(clusterB));
      expect(clusterA.hashCode, equals(clusterB.hashCode));
      expect(clusterA.activeDevice, equals(remoteActive));
      expect(clusterA.activeRemoteDevice, equals(remoteActive));
      expect(clusterA.localDevice, equals(selfInactive));
      expect(clusterA.activeDeviceId, 'cs-remote');
      expect(
        clusterA.devicesById.keys,
        containsAll(<String>['cs-self', 'cs-remote', 'local-only']),
      );
      expect(
        () => clusterA.devices.add(selfInactive),
        throwsUnsupportedError,
      );
      expect(
        () => clusterA.devicesById.remove('cs-self'),
        throwsUnsupportedError,
      );

      expect(
        () => ConnectCluster(
          isActive: true,
          shouldUseLocalPlayback: false,
          devices: <ConnectDevice>[
            remoteActive,
            _buildDevice(
              isActive: true,
              connectStateIdentifier: 'cs-remote-2',
            ),
          ],
          isActiveOnSameDevice: false,
          isSyncedWithBackend: true,
        ),
        throwsArgumentError,
      );
    });
  });

  group('TransferState & TransferCommand (Item 152)', () {
    test('exhaustive switch and non-empty targetDeviceId validation', () {
      const idle = TransferIdle();
      final progress = TransferInProgress(
        targetDeviceId: 'dev-1',
        phase: TransferPhase.transferring,
        source: TransferSource.googleOutputSwitcher,
        intentionId: 'int-1',
      );
      final succeeded = TransferSucceeded(
        targetDeviceId: 'dev-1',
        intentionId: 'int-1',
        ackId: 'ack-1',
      );
      final failedA = TransferFailed(
        targetDeviceId: 'dev-1',
        reason: TransferFailureReason.noResponse,
        errorDescription: 'Timed out',
        reasons: <String>['timeout'],
      );
      final failedB = TransferFailed(
        targetDeviceId: 'dev-1',
        reason: TransferFailureReason.noResponse,
        errorDescription: 'Timed out',
        reasons: <String>['timeout'],
      );

      expect(failedA, equals(failedB));
      expect(failedA.hashCode, equals(failedB.hashCode));
      expect(() => failedA.reasons.add('x'), throwsUnsupportedError);

      String describeState(TransferState state) => switch (state) {
            TransferIdle() => 'idle',
            TransferInProgress(:final targetDeviceId) => 'progress:$targetDeviceId',
            TransferSucceeded(:final targetDeviceId) => 'ok:$targetDeviceId',
            TransferFailed(:final reason) => 'err:${reason.name}',
          };

      expect(describeState(idle), 'idle');
      expect(describeState(progress), 'progress:dev-1');
      expect(describeState(succeeded), 'ok:dev-1');
      expect(describeState(failedA), 'err:noResponse');

      const localCmd = TransferToLocal(source: TransferSource.inApp);
      final remoteCmd = TransferToRemote(
        targetDeviceId: 'dev-2',
        source: TransferSource.googleOutputSwitcher,
      );
      String describeCmd(TransferCommand cmd) => switch (cmd) {
            TransferToLocal(:final source) => 'local:${source.name}',
            TransferToRemote(:final targetDeviceId) => 'remote:$targetDeviceId',
          };
      expect(describeCmd(localCmd), 'local:inApp');
      expect(describeCmd(remoteCmd), 'remote:dev-2');

      expect(
        () => TransferToRemote(
          targetDeviceId: '',
          source: TransferSource.inApp,
        ),
        throwsArgumentError,
      );
      expect(
        () => TransferInProgress(
          targetDeviceId: '',
          phase: TransferPhase.created,
        ),
        throwsArgumentError,
      );
      expect(
        () => TransferSucceeded(targetDeviceId: ''),
        throwsArgumentError,
      );
      expect(
        () => TransferFailed(
          targetDeviceId: '',
          reason: TransferFailureReason.unknown,
        ),
        throwsArgumentError,
      );
    });
  });
}
