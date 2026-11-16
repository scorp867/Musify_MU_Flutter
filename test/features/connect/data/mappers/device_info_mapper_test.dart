import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/mappers/device_info_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/group.pb.dart'
    as group_pb;
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';

void main() {
  const mapper = DeviceInfoMapper();

  group_pb.GroupData buildSampleGroupData() {
    return group_pb.GroupData(
      devices: [
        group_pb.GroupDevice(
          identifiers: group_pb.GroupDeviceIdentifiers(
            groupDeviceIdentifier: 'grp-dev-1',
            localIdentifier: 'grp-local-1',
            deduplicationId: 'grp-dedup-1',
            connectStateIdentifier: 'grp-cs-1',
          ),
          name: 'Living Room Pair',
          type: 'SPEAKER',
          modelDisplayName: 'Sonos Era 100',
          capabilities: group_pb.GroupDeviceCapabilities(
            removable: true,
            removalDissolvesGroup: false,
          ),
          groupingStatus: group_pb.GroupingStatus.GROUPED,
          volume: group_pb.GroupDeviceVolume(volume: 32768, volumeSteps: 64),
        ),
      ],
      capabilities: group_pb.GroupCapabilities(
        maxDevices: 4,
      ),
    );
  }

  connect_pb.StateResponse_Device buildMinimalValidDevice({
    String state = 'LOGGED_IN',
    String type = 'SPEAKER',
  }) {
    return connect_pb.StateResponse_Device(
      state: state,
      type: type,
    );
  }

  group('DeviceInfoMapper', () {
    test('maps full 39-field StateResponse_Device via wire-byte roundtrip', () {
      final capabilitiesPayload = jsonEncode([
        <String, Object?>{
          'id': 'alexa',
          'defaultTitle': 'Amazon Alexa',
          'iconUrl': 'https://cdn.example/alexa.png',
          'redirectUris': <String, Object?>{
            'android': <String, Object?>{
              'uri': 'alexa://link',
              'redirectBackAppParam': 'return_to',
              'deviceNameParam': 'device_name',
              'fallbackUrl': 'https://example.com/fallback',
            },
          },
          'localizedTitle': <String, Object?>{
            'en': 'Amazon Alexa',
            'es': 'Amazon Alexa ES',
          },
        },
      ]);

      final pb = connect_pb.StateResponse_Device(
        isSelf: false,
        isActive: true,
        isBeingActivated: false,
        isWebapp: false,
        isZeroconf: true,
        isGroup: true,
        isSocialConnect: false,
        supportsLogout: true,
        supportsVolume: true,
        supportsRename: true,
        creationTimeMs: fixnum.Int64(1700000000123),
        brandDisplayName: 'Sonos',
        modelDisplayName: 'Arc',
        localIdentifier: 'local-device-1',
        connectStateIdentifier: 'cs-device-1',
        name: 'Living Room Soundbar',
        state: 'LOGGED_IN',
        type: 'SPEAKER',
        incarnations: [
          connect_pb.StateResponse_Incarnation(
            loginType: connect_pb.LoginType.CONNECT,
            identifier: 'inc-1',
            preferred: true,
            preferredReason: connect_pb
                .ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_USER_SELECTED,
            connectStateIdentifier: 'inc-cs-1',
          ),
          connect_pb.StateResponse_Incarnation(
            loginType: connect_pb.LoginType.CAST,
            identifier: 'inc-2',
            preferred: false,
            preferredReason:
                connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_ANDROID_TV,
            connectStateIdentifier: 'inc-cs-2',
          ),
        ],
        volume: 49152,
        isNewlyDiscovered: true,
        isDisabled: false,
        capabilities: capabilitiesPayload,
        hifi: connect_pb.StateResponse_Hifi(
          fullySupported: true,
          userEligible: true,
          deviceSupported: true,
        ),
        outputPeripheral: connect_pb.OutputPeripheral(
          name: 'WH-1000XM5',
          brand: 'Sony',
          model: 'XM5',
          connectionType: connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH,
          category: connect_pb
              .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES,
        ),
        volumeSteps: 64,
        isVoiceEnabled: true,
        isLocal: false,
        localIp: '192.168.1.44',
        supportedMediaTypes: ['AUDIO', 'VIDEO'],
        supportsDj: true,
        libraryVersion: '3.2.1',
        supportsRemoteSleepTimer: true,
        supportsPlaylistMixing: false,
        supportsZephyr: true,
        supportsRemoteAudioQualityControl: true,
        discoveryMethod: 3,
        isAuthenticatedWithCurrentUser: true,
        groupData: buildSampleGroupData(),
      );

      final Uint8List wireBytes = pb.writeToBuffer();
      final mapped = mapper.deviceFromBuffer(wireBytes);

      expect(mapped.isSelf, isFalse);
      expect(mapped.isActive, isTrue);
      expect(mapped.isBeingActivated, isFalse);
      expect(mapped.isWebapp, isFalse);
      expect(mapped.isZeroconf, isTrue);
      expect(mapped.isGroup, isTrue);
      expect(mapped.isSocialConnect, isFalse);
      expect(mapped.supportsLogout, isTrue);
      expect(mapped.supportsVolume, isTrue);
      expect(mapped.supportsRename, isTrue);
      expect(mapped.creationTimeMs, 1700000000123);
      expect(mapped.brandDisplayName, 'Sonos');
      expect(mapped.modelDisplayName, 'Arc');
      expect(mapped.localIdentifier, 'local-device-1');
      expect(mapped.connectStateIdentifier, 'cs-device-1');
      expect(mapped.name, 'Living Room Soundbar');
      expect(mapped.state, ConnectDeviceState.loggedIn);
      expect(mapped.type, DeviceType.speaker);
      expect(mapped.incarnations, hasLength(2));
      expect(mapped.incarnations[0].loginType, IncarnationLoginType.connect.wireName);
      expect(
        mapped.incarnations[0].preferredReason,
        IncarnationPreferredReason.userSelected.wireName,
      );
      expect(mapped.incarnations[1].loginType, IncarnationLoginType.cast.wireName);
      expect(mapped.volume, 49152);
      expect(mapped.isNewlyDiscovered, isTrue);
      expect(mapped.isDisabled, isFalse);
      expect(
        mapped.capabilities,
        equals([
          ConnectCapabilityEntry(
            id: 'alexa',
            defaultTitle: 'Amazon Alexa',
            iconUrl: 'https://cdn.example/alexa.png',
            redirectUris: ConnectCapabilityRedirectUris(
              android: ConnectCapabilityAndroidUris(
                uri: 'alexa://link',
                redirectBackAppParam: 'return_to',
                deviceNameParam: 'device_name',
                fallbackUrl: 'https://example.com/fallback',
              ),
            ),
            localizedTitle: {'en': 'Amazon Alexa', 'es': 'Amazon Alexa ES'},
          ),
        ]),
      );
      expect(
        mapped.hifi,
        const ConnectHifiStatus(
          fullySupported: true,
          userEligible: true,
          deviceSupported: true,
        ),
      );
      expect(
        mapped.outputPeripheral,
        const OutputPeripheral(
          name: 'WH-1000XM5',
          brand: 'Sony',
          model: 'XM5',
          connectionType: OutputPeripheralConnectionType.bluetooth,
          category: OutputPeripheralCategory.headphones,
        ),
      );
      expect(mapped.volumeSteps, 64);
      expect(mapped.isVoiceEnabled, isTrue);
      expect(mapped.isLocal, isFalse);
      expect(mapped.localIp, '192.168.1.44');
      expect(mapped.supportedMediaTypes, equals(['AUDIO', 'VIDEO']));
      expect(mapped.supportsDj, isTrue);
      expect(mapped.libraryVersion, '3.2.1');
      expect(mapped.supportsRemoteSleepTimer, isTrue);
      expect(mapped.supportsPlaylistMixing, isFalse);
      expect(mapped.supportsZephyr, isTrue);
      expect(mapped.supportsRemoteAudioQualityControl, isTrue);
      expect(mapped.discoveryMethod, 3);
      expect(mapped.isAuthenticatedWithCurrentUser, isTrue);
      expect(mapped.groupData, isNotNull);
      expect(mapped.groupData?.devices.single.groupingStatus, GroupingStatus.grouped);
    });

    test(
      'applies positive hasX() guards when optional fields are absent vs false',
      () {
        final absentPb = buildMinimalValidDevice();
        final absentMapped = mapper.deviceFromBuffer(absentPb.writeToBuffer());

        expect(absentMapped.outputPeripheral, isNull);
        expect(absentMapped.isAuthenticatedWithCurrentUser, isNull);
        expect(absentMapped.groupData, isNull);
        expect(
          absentMapped.hifi,
          const ConnectHifiStatus(
            fullySupported: false,
            userEligible: false,
            deviceSupported: false,
          ),
        );
        expect(absentMapped.volumeSteps, 0);
        expect(absentMapped.supportsDj, isFalse);
        expect(absentMapped.capabilities, isEmpty);
        expect(absentMapped.localIdentifier, '');
        expect(absentMapped.connectStateIdentifier, '');

        final explicitFalsePb = buildMinimalValidDevice()
          ..isAuthenticatedWithCurrentUser = false
          ..supportsDj = false
          ..volumeSteps = 0;
        final explicitFalseMapped = mapper.deviceFromBuffer(
          explicitFalsePb.writeToBuffer(),
        );
        expect(explicitFalseMapped.isAuthenticatedWithCurrentUser, isFalse);
        expect(explicitFalseMapped.supportsDj, isFalse);
        expect(explicitFalseMapped.volumeSteps, 0);
      },
    );

    test('maps OutputPeripheral with partial/unset fields to nulls', () {
      final emptyPeripheral = mapper.mapOutputPeripheral(
        connect_pb.OutputPeripheral(),
      );
      expect(
        emptyPeripheral,
        const OutputPeripheral(
          name: null,
          brand: null,
          model: null,
          connectionType: null,
          category: null,
        ),
      );
    });

    test('maps all OutputPeripheralConnectionType and OutputPeripheralCategory values', () {
      expect(
        mapper.mapOutputPeripheralConnectionType(
          connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_UNKNOWN,
        ),
        OutputPeripheralConnectionType.unknown,
      );
      expect(
        mapper.mapOutputPeripheralConnectionType(
          connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED,
        ),
        OutputPeripheralConnectionType.wired,
      );
      expect(
        mapper.mapOutputPeripheralConnectionType(
          connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_CAR_PROJECTED,
        ),
        OutputPeripheralConnectionType.carProjected,
      );
      expect(
        mapper.mapOutputPeripheralConnectionType(
          connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH,
        ),
        OutputPeripheralConnectionType.bluetooth,
      );
      expect(
        mapper.mapOutputPeripheralConnectionType(
          connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_AIRPLAY,
        ),
        OutputPeripheralConnectionType.airplay,
      );
      expect(
        mapper.mapOutputPeripheralConnectionType(
          connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER,
        ),
        OutputPeripheralConnectionType.builtInSpeaker,
      );

      expect(
        mapper.mapOutputPeripheralCategory(
          connect_pb
              .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_UNKNOWN,
        ),
        OutputPeripheralCategory.unknown,
      );
      expect(
        mapper.mapOutputPeripheralCategory(
          connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_CAR,
        ),
        OutputPeripheralCategory.car,
      );
      expect(
        mapper.mapOutputPeripheralCategory(
          connect_pb
              .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES,
        ),
        OutputPeripheralCategory.headphones,
      );
      expect(
        mapper.mapOutputPeripheralCategory(
          connect_pb
              .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_SPEAKER,
        ),
        OutputPeripheralCategory.speaker,
      );
      expect(
        mapper.mapOutputPeripheralCategory(
          connect_pb
              .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_WEARABLE,
        ),
        OutputPeripheralCategory.wearable,
      );
      expect(
        mapper.mapOutputPeripheralCategory(
          connect_pb
              .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_GLASSES,
        ),
        OutputPeripheralCategory.glasses,
      );
      expect(
        mapper.mapOutputPeripheralCategory(
          connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_APP,
        ),
        OutputPeripheralCategory.app,
      );
    });

    test(
      'maps Incarnation with proto3 omitted defaults and all ProtocolChoiceReason values',
      () {
        final defaultIncarnation = connect_pb.StateResponse_Incarnation(
          identifier: 'default-inc',
          preferred: true,
        );
        final roundtrip = connect_pb.StateResponse_Incarnation.fromBuffer(
          defaultIncarnation.writeToBuffer(),
        );
        final mappedDefault = mapper.mapIncarnation(roundtrip);
        expect(mappedDefault.loginType, IncarnationLoginType.connect.wireName);
        expect(
          mappedDefault.preferredReason,
          IncarnationPreferredReason.defaultReason.wireName,
        );
        expect(mappedDefault.identifier, 'default-inc');
        expect(mappedDefault.preferred, isTrue);

        final reasons = <connect_pb.ProtocolChoiceReason,
            IncarnationPreferredReason>{
          connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_DEFAULT:
              IncarnationPreferredReason.defaultReason,
          connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_USER_SELECTED:
              IncarnationPreferredReason.userSelected,
          connect_pb
              .ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_STREAM_EXPANSION:
              IncarnationPreferredReason.streamExpansion,
          connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_ANDROID_TV:
              IncarnationPreferredReason.androidTv,
          connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_TAP_DEVICE:
              IncarnationPreferredReason.tapDevice,
        };
        for (final entry in reasons.entries) {
          final mapped = mapper.mapIncarnation(
            connect_pb.StateResponse_Incarnation(
              loginType: connect_pb.LoginType.CAST,
              identifier: 'id-${entry.key.value}',
              preferredReason: entry.key,
            ),
          );
          expect(mapped.loginType, IncarnationLoginType.cast.wireName);
          expect(mapped.preferredReason, entry.value.wireName);
        }
      },
    );

    test('parses capabilities JSON including literal null and nested fields', () {
      expect(mapper.parseCapabilitiesJson('null'), isEmpty);
      expect(mapper.parseCapabilitiesJson('[]'), isEmpty);

      final entries = mapper.parseCapabilitiesJson(
        jsonEncode([
          <String, Object?>{
            'id': 'cap-1',
            'defaultTitle': null,
            'redirectUris': null,
            'localizedTitle': null,
          },
        ]),
      );
      expect(entries, equals([ConnectCapabilityEntry(id: 'cap-1')]));
    });

    test('throws FormatException on malformed or type-mismatched capabilities JSON', () {
      expect(
        () => mapper.parseCapabilitiesJson('{not-json'),
        throwsFormatException,
      );
      expect(
        () => mapper.parseCapabilitiesJson('{}'),
        throwsFormatException,
      );
      expect(
        () => mapper.parseCapabilitiesJson('["not-an-object"]'),
        throwsFormatException,
      );
      expect(
        () => mapper.parseCapabilitiesJson('[{"id": 123}]'),
        throwsFormatException,
      );
      expect(
        () => mapper.parseCapabilitiesJson('[{"redirectUris": "bad"}]'),
        throwsFormatException,
      );
      expect(
        () => mapper.parseCapabilitiesJson(
          '[{"redirectUris": {"android": 42}}]',
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.parseCapabilitiesJson(
          '[{"localizedTitle": {"en": 99}}]',
        ),
        throwsFormatException,
      );
    });

    test('fails fast on missing or blank required Device state/type or invalid volume', () {
      expect(
        () => mapper.mapDevice(connect_pb.StateResponse_Device(type: 'SPEAKER')),
        throwsFormatException,
      );
      expect(
        () => mapper.mapDevice(
          connect_pb.StateResponse_Device(state: '   ', type: 'SPEAKER'),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.mapDevice(
          connect_pb.StateResponse_Device(state: 'LOGGED_IN'),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.mapDevice(
          connect_pb.StateResponse_Device(state: 'LOGGED_IN', type: '  '),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.mapDevice(
          buildMinimalValidDevice()..volume = 70000,
        ),
        throwsRangeError,
      );
      expect(
        () => mapper.mapDevice(
          buildMinimalValidDevice()..creationTimeMs = fixnum.Int64(-1),
        ),
        throwsRangeError,
      );
    });

    test('delegates GroupData validation errors through DeviceInfoMapper', () {
      final brokenGroupDevice = buildMinimalValidDevice()
        ..groupData = group_pb.GroupData(
          devices: [group_pb.GroupDevice(name: 'No caps')],
        );

      expect(
        () => mapper.mapDevice(brokenGroupDevice),
        throwsFormatException,
      );
    });
  });
}
