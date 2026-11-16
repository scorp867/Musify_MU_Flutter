// 1:1 replica of p199p/n8d.java (lines 764–868), p199p/of40.java, p199p/te40.java,
// p199p/ug40.java, p199p/yg40.java, p199p/vg40.java, p199p/zg40.java,
// p199p/im40.java, p199p/z9k.java, and ConnectServiceImpl.cpp (lines 313–341).

import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/proto/group.pb.dart'
    as group_pb;
import 'package:musify_mu/features/connect/domain/models/connect_group_data.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';

/// Pure deterministic mapper from `spotify.connect.GroupData` protobuf wire
/// messages to M3a immutable speaker-group domain entities.
final class GroupMapper {
  const GroupMapper();

  /// Decodes raw `GroupData` protobuf bytes and maps to [ConnectGroupData].
  ///
  /// Throws [FormatException] when wire bytes are malformed or required
  /// sub-messages/fields are absent.
  ConnectGroupData groupDataFromBuffer(Uint8List bytes) {
    final pb = group_pb.GroupData.fromBuffer(bytes);
    return mapGroupData(pb);
  }

  /// Maps [group_pb.GroupData] to [ConnectGroupData].
  ///
  /// Requires `pb.hasCapabilities()` (`FormatException` if missing).
  ConnectGroupData mapGroupData(group_pb.GroupData pb) {
    if (!pb.hasCapabilities()) {
      throw const FormatException('GroupData.capabilities is required');
    }

    final devices = pb.devices.map(mapGroupDevice).toList(growable: false);
    final capabilities = mapGroupCapabilities(pb.capabilities);
    return ConnectGroupData(
      devices: devices,
      capabilities: capabilities,
    );
  }

  /// Maps [group_pb.GroupCapabilities] to [ConnectGroupCapabilities].
  ConnectGroupCapabilities mapGroupCapabilities(
    group_pb.GroupCapabilities pb,
  ) {
    return ConnectGroupCapabilities(maxDevices: pb.maxDevices);
  }

  /// Maps [group_pb.GroupDevice] to [ConnectGroupDevice].
  ///
  /// Uses positive `pb.hasVolume()` (correcting the JADX CFG inversion at
  /// `p199p/n8d.java:839`). Throws [FormatException] when `identifiers`,
  /// `type`, or `capabilities` are missing or empty.
  ConnectGroupDevice mapGroupDevice(group_pb.GroupDevice pb) {
    if (!pb.hasIdentifiers()) {
      throw const FormatException('GroupDevice.identifiers is required');
    }
    if (!pb.hasType() || pb.type.trim().isEmpty) {
      throw FormatException(
        'GroupDevice.type must be present and non-empty',
        pb.type,
      );
    }
    if (!pb.hasCapabilities()) {
      throw const FormatException('GroupDevice.capabilities is required');
    }

    final identifiers = mapGroupDeviceIdentifiers(pb.identifiers);
    final deviceType = DeviceType.fromWireName(pb.type);
    final capabilities = mapGroupDeviceCapabilities(pb.capabilities);
    final groupingStatus = mapGroupingStatus(pb.groupingStatus);
    final volume = pb.hasVolume() ? mapGroupDeviceVolume(pb.volume) : null;

    return ConnectGroupDevice(
      identifiers: identifiers,
      name: pb.name,
      deviceType: deviceType,
      modelDisplayName: pb.modelDisplayName,
      capabilities: capabilities,
      groupingStatus: groupingStatus,
      volume: volume,
    );
  }

  /// Maps [group_pb.GroupDeviceIdentifiers] to [GroupDeviceIdentifiers].
  ///
  /// Throws [FormatException] if `groupDeviceIdentifier` is missing or blank.
  GroupDeviceIdentifiers mapGroupDeviceIdentifiers(
    group_pb.GroupDeviceIdentifiers pb,
  ) {
    if (!pb.hasGroupDeviceIdentifier() ||
        pb.groupDeviceIdentifier.trim().isEmpty) {
      throw FormatException(
        'GroupDeviceIdentifiers.groupDeviceIdentifier must be present and non-empty',
        pb.groupDeviceIdentifier,
      );
    }

    return GroupDeviceIdentifiers(
      groupDeviceIdentifier: pb.groupDeviceIdentifier,
      localIdentifier: pb.hasLocalIdentifier() ? pb.localIdentifier : null,
      deduplicationId: pb.hasDeduplicationId() ? pb.deduplicationId : null,
      connectStateIdentifier:
          pb.hasConnectStateIdentifier() ? pb.connectStateIdentifier : null,
    );
  }

  /// Maps [group_pb.GroupDeviceCapabilities] to [GroupDeviceCapabilities].
  GroupDeviceCapabilities mapGroupDeviceCapabilities(
    group_pb.GroupDeviceCapabilities pb,
  ) {
    return GroupDeviceCapabilities(
      removable: pb.removable,
      removalDissolvesGroup: pb.removalDissolvesGroup,
    );
  }

  /// Maps [group_pb.GroupingStatus] to [GroupingStatus].
  ///
  /// Proto3 implicit presence omits `UNKNOWN_GROUPING_STATUS (0)` on the wire,
  /// so `pb` is matched directly without requiring `hasGroupingStatus()`.
  GroupingStatus mapGroupingStatus(group_pb.GroupingStatus pb) {
    if (pb == group_pb.GroupingStatus.UNKNOWN_GROUPING_STATUS) {
      return GroupingStatus.unknown;
    } else if (pb == group_pb.GroupingStatus.GROUPED) {
      return GroupingStatus.grouped;
    } else if (pb == group_pb.GroupingStatus.GROUPABLE) {
      return GroupingStatus.groupable;
    } else if (pb == group_pb.GroupingStatus.GROUPING) {
      return GroupingStatus.connecting;
    } else {
      throw FormatException(
        'Unsupported GroupingStatus proto enum: ${pb.value} (${pb.name})',
      );
    }
  }

  /// Maps [group_pb.GroupDeviceVolume] to [GroupDeviceVolume].
  ///
  /// Validates `volume` within `0..65535` and non-negative `volumeSteps`.
  GroupDeviceVolume mapGroupDeviceVolume(group_pb.GroupDeviceVolume pb) {
    return GroupDeviceVolume.fromWire(
      rawVolume: pb.volume,
      volumeSteps: pb.hasVolumeSteps() ? pb.volumeSteps : null,
    );
  }
}
