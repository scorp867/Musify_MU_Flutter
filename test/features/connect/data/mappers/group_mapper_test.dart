import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/mappers/group_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/group.pb.dart'
    as group_pb;
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';

void main() {
  const mapper = GroupMapper();

  group_pb.GroupDevice buildValidGroupDevice({
    String groupDeviceId = 'group-dev-1',
    String? localId = 'local-1',
    String? dedupId = 'dedup-1',
    String? csId = 'cs-1',
    String name = 'Kitchen Speaker',
    String type = 'SPEAKER',
    String modelDisplayName = 'Sonos One',
    bool removable = true,
    bool removalDissolvesGroup = false,
    group_pb.GroupingStatus groupingStatus = group_pb.GroupingStatus.GROUPED,
    group_pb.GroupDeviceVolume? volume,
  }) {
    final ids = group_pb.GroupDeviceIdentifiers(
      groupDeviceIdentifier: groupDeviceId,
      localIdentifier: localId,
      deduplicationId: dedupId,
      connectStateIdentifier: csId,
    );
    final caps = group_pb.GroupDeviceCapabilities(
      removable: removable,
      removalDissolvesGroup: removalDissolvesGroup,
    );
    return group_pb.GroupDevice(
      identifiers: ids,
      name: name,
      type: type,
      modelDisplayName: modelDisplayName,
      capabilities: caps,
      groupingStatus: groupingStatus,
      volume: volume,
    );
  }

  group('GroupMapper', () {
    test('maps GroupData with wire-byte roundtrip and all fields populated', () {
      final proto = group_pb.GroupData(
        devices: [
          buildValidGroupDevice(
            volume: group_pb.GroupDeviceVolume(volume: 32768, volumeSteps: 64),
          ),
          buildValidGroupDevice(
            groupDeviceId: 'group-dev-2',
            localId: null,
            dedupId: null,
            csId: null,
            name: 'Bedroom',
            type: 'AUDIO_DONGLE',
            modelDisplayName: 'Echo Input',
            removable: false,
            removalDissolvesGroup: true,
            groupingStatus: group_pb.GroupingStatus.GROUPING,
            volume: null,
          ),
        ],
        capabilities: group_pb.GroupCapabilities(maxDevices: 5),
      );

      final roundtripped =
          mapper.groupDataFromBuffer(Uint8List.fromList(proto.writeToBuffer()));

      expect(roundtripped.capabilities.maxDevices, 5);
      expect(roundtripped.devices, hasLength(2));

      final first = roundtripped.devices[0];
      expect(first.identifiers.groupDeviceIdentifier, 'group-dev-1');
      expect(first.identifiers.localIdentifier, 'local-1');
      expect(first.identifiers.deduplicationId, 'dedup-1');
      expect(first.identifiers.connectStateIdentifier, 'cs-1');
      expect(first.name, 'Kitchen Speaker');
      expect(first.deviceType, DeviceType.speaker);
      expect(first.modelDisplayName, 'Sonos One');
      expect(first.capabilities.removable, isTrue);
      expect(first.capabilities.removalDissolvesGroup, isFalse);
      expect(first.groupingStatus, GroupingStatus.grouped);
      expect(first.volume, isNotNull);
      expect(
        first.volume?.volume,
        closeTo(32768 / kMaxConnectVolumeWire, 1e-12),
      );
      expect(first.volume?.volumeSteps, 64);

      final second = roundtripped.devices[1];
      expect(second.identifiers.localIdentifier, isNull);
      expect(second.identifiers.deduplicationId, isNull);
      expect(second.identifiers.connectStateIdentifier, isNull);
      expect(second.deviceType, DeviceType.audioDongle);
      expect(second.capabilities.removable, isFalse);
      expect(second.capabilities.removalDissolvesGroup, isTrue);
      expect(second.groupingStatus, GroupingStatus.connecting);
      expect(second.volume, isNull);
    });

    test('JADX positive hasVolume() parity: present vs absent volume', () {
      final withVol = mapper.mapGroupDevice(
        buildValidGroupDevice(
          volume: group_pb.GroupDeviceVolume(volume: 0, volumeSteps: 20),
        ),
      );
      final withoutVol = mapper.mapGroupDevice(buildValidGroupDevice());

      expect(withVol.volume, isNotNull);
      expect(withVol.volume?.volume, 0.0);
      expect(withVol.volume?.volumeSteps, 20);
      expect(withoutVol.volume, isNull);
    });

    test('maps all GroupingStatus proto3 values including omitted index 0', () {
      final omitted = mapper.mapGroupDevice(
        group_pb.GroupDevice(
          identifiers: group_pb.GroupDeviceIdentifiers(
            groupDeviceIdentifier: 'gd-0',
          ),
          type: 'SPEAKER',
          capabilities: group_pb.GroupDeviceCapabilities(),
        ),
      );
      expect(omitted.groupingStatus, GroupingStatus.unknown);
      expect(
        mapper.mapGroupingStatus(group_pb.GroupingStatus.UNKNOWN_GROUPING_STATUS),
        GroupingStatus.unknown,
      );
      expect(
        mapper.mapGroupingStatus(group_pb.GroupingStatus.GROUPED),
        GroupingStatus.grouped,
      );
      expect(
        mapper.mapGroupingStatus(group_pb.GroupingStatus.GROUPABLE),
        GroupingStatus.groupable,
      );
      expect(
        mapper.mapGroupingStatus(group_pb.GroupingStatus.GROUPING),
        GroupingStatus.connecting,
      );
    });

    test('proto3 implicit zero maxDevices maps to 0', () {
      final proto = group_pb.GroupData(
        capabilities: group_pb.GroupCapabilities(),
      );
      final result =
          mapper.groupDataFromBuffer(Uint8List.fromList(proto.writeToBuffer()));
      expect(result.capabilities.maxDevices, 0);
      expect(result.devices, isEmpty);
    });

    test('GroupDeviceVolume without volumeSteps leaves volumeSteps null', () {
      final mapped = mapper.mapGroupDeviceVolume(
        group_pb.GroupDeviceVolume(volume: 65535),
      );
      expect(mapped.volume, 1.0);
      expect(mapped.volumeSteps, isNull);
    });

    test('fail-fast on missing GroupData.capabilities', () {
      final proto = group_pb.GroupData(devices: [buildValidGroupDevice()]);
      expect(
        () => mapper.mapGroupData(proto),
        throwsFormatException,
      );
      expect(
        () => mapper.groupDataFromBuffer(Uint8List(0)),
        throwsFormatException,
      );
    });

    test('fail-fast on missing GroupDevice required sub-messages and fields', () {
      expect(
        () => mapper.mapGroupDevice(
          group_pb.GroupDevice(
            type: 'SPEAKER',
            capabilities: group_pb.GroupDeviceCapabilities(),
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.mapGroupDevice(
          group_pb.GroupDevice(
            identifiers: group_pb.GroupDeviceIdentifiers(
              groupDeviceIdentifier: 'gd-1',
            ),
            capabilities: group_pb.GroupDeviceCapabilities(),
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.mapGroupDevice(
          group_pb.GroupDevice(
            identifiers: group_pb.GroupDeviceIdentifiers(
              groupDeviceIdentifier: 'gd-1',
            ),
            type: '   ',
            capabilities: group_pb.GroupDeviceCapabilities(),
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.mapGroupDevice(
          group_pb.GroupDevice(
            identifiers: group_pb.GroupDeviceIdentifiers(
              groupDeviceIdentifier: 'gd-1',
            ),
            type: 'SPEAKER',
          ),
        ),
        throwsFormatException,
      );
    });

    test('fail-fast on missing or blank groupDeviceIdentifier', () {
      expect(
        () => mapper.mapGroupDeviceIdentifiers(
          group_pb.GroupDeviceIdentifiers(),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.mapGroupDeviceIdentifiers(
          group_pb.GroupDeviceIdentifiers(groupDeviceIdentifier: '   '),
        ),
        throwsFormatException,
      );
    });

    test('fail-fast on out-of-range GroupDeviceVolume', () {
      expect(
        () => mapper.mapGroupDeviceVolume(
          group_pb.GroupDeviceVolume(volume: 65536),
        ),
        throwsRangeError,
      );
      expect(
        () => group_pb.GroupDeviceVolume(volume: -1),
        throwsArgumentError,
      );
      expect(
        () => mapper.mapGroupDeviceVolume(
          group_pb.GroupDeviceVolume(volume: 1000, volumeSteps: -1),
        ),
        throwsRangeError,
      );
    });
  });
}
