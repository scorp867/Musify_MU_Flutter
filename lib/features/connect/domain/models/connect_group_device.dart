// 1:1 replica of p199p/ug40.java (lines 4–61), p199p/yg40.java (lines 4–64),
// p199p/vg40.java (lines 4–34), p199p/zg40.java (lines 4–42),
// p199p/n8d.java (lines 769–846), and protos/spotify/connect/group.proto (lines 26–51).

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';

/// Identifiers for a member device within a Connect speaker group (`p199p/yg40.java`).
@immutable
final class GroupDeviceIdentifiers extends Equatable {
  /// Non-empty group member identifier (`yg40.f285814a`).
  final String groupDeviceIdentifier;

  /// Optional local discovery identifier (`yg40.f285815b`).
  final String? localIdentifier;

  /// Optional deduplication identifier (`yg40.f285816c`).
  final String? deduplicationId;

  /// Optional Connect state identifier (`yg40.f285817d`).
  final String? connectStateIdentifier;

  GroupDeviceIdentifiers({
    required this.groupDeviceIdentifier,
    this.localIdentifier,
    this.deduplicationId,
    this.connectStateIdentifier,
  }) {
    if (groupDeviceIdentifier.isEmpty) {
      throw ArgumentError.value(
        groupDeviceIdentifier,
        'groupDeviceIdentifier',
        'Must be non-empty',
      );
    }
  }

  GroupDeviceIdentifiers copyWith({
    String? groupDeviceIdentifier,
    String? localIdentifier,
    bool clearLocalIdentifier = false,
    String? deduplicationId,
    bool clearDeduplicationId = false,
    String? connectStateIdentifier,
    bool clearConnectStateIdentifier = false,
  }) {
    return GroupDeviceIdentifiers(
      groupDeviceIdentifier: switch (groupDeviceIdentifier) {
        final value? => value,
        null => this.groupDeviceIdentifier,
      },
      localIdentifier: clearLocalIdentifier
          ? null
          : switch (localIdentifier) {
              final value? => value,
              null => this.localIdentifier,
            },
      deduplicationId: clearDeduplicationId
          ? null
          : switch (deduplicationId) {
              final value? => value,
              null => this.deduplicationId,
            },
      connectStateIdentifier: clearConnectStateIdentifier
          ? null
          : switch (connectStateIdentifier) {
              final value? => value,
              null => this.connectStateIdentifier,
            },
    );
  }

  @override
  List<Object?> get props => [
        groupDeviceIdentifier,
        localIdentifier,
        deduplicationId,
        connectStateIdentifier,
      ];
}

/// Capabilities of an individual member inside a Connect speaker group (`p199p/vg40.java`).
@immutable
final class GroupDeviceCapabilities extends Equatable {
  /// Whether this device can be removed from the group (`vg40.f251858a`).
  final bool removable;

  /// Whether removing this device dissolves the entire group (`vg40.f251859b`).
  final bool removalDissolvesGroup;

  const GroupDeviceCapabilities({
    required this.removable,
    required this.removalDissolvesGroup,
  });

  GroupDeviceCapabilities copyWith({
    bool? removable,
    bool? removalDissolvesGroup,
  }) {
    return GroupDeviceCapabilities(
      removable: switch (removable) {
        final value? => value,
        null => this.removable,
      },
      removalDissolvesGroup: switch (removalDissolvesGroup) {
        final value? => value,
        null => this.removalDissolvesGroup,
      },
    );
  }

  @override
  List<Object?> get props => [removable, removalDissolvesGroup];
}

/// Member device in a Connect audio group session matching `p199p/ug40.java`
/// (exact 7 fields).
@immutable
final class ConnectGroupDevice extends Equatable {
  /// Member identifiers (`ug40.f240889a`).
  final GroupDeviceIdentifiers identifiers;

  /// Display name (`ug40.f240890b`).
  final String name;

  /// Device form-factor type (`ug40.f240891c`).
  final DeviceType deviceType;

  /// Hardware model display name (`ug40.f240892d`).
  final String modelDisplayName;

  /// Group-membership mutation capabilities (`ug40.f240893e`).
  final GroupDeviceCapabilities capabilities;

  /// Current grouping status (`ug40.f240894f`).
  final GroupingStatus groupingStatus;

  /// Optional sub-device volume (`ug40.f240895g`, `p199p/zg40.java`).
  final GroupDeviceVolume? volume;

  const ConnectGroupDevice({
    required this.identifiers,
    required this.name,
    required this.deviceType,
    required this.modelDisplayName,
    required this.capabilities,
    required this.groupingStatus,
    this.volume,
  });

  ConnectGroupDevice copyWith({
    GroupDeviceIdentifiers? identifiers,
    String? name,
    DeviceType? deviceType,
    String? modelDisplayName,
    GroupDeviceCapabilities? capabilities,
    GroupingStatus? groupingStatus,
    GroupDeviceVolume? volume,
    bool clearVolume = false,
  }) {
    return ConnectGroupDevice(
      identifiers: switch (identifiers) {
        final value? => value,
        null => this.identifiers,
      },
      name: switch (name) {
        final value? => value,
        null => this.name,
      },
      deviceType: switch (deviceType) {
        final value? => value,
        null => this.deviceType,
      },
      modelDisplayName: switch (modelDisplayName) {
        final value? => value,
        null => this.modelDisplayName,
      },
      capabilities: switch (capabilities) {
        final value? => value,
        null => this.capabilities,
      },
      groupingStatus: switch (groupingStatus) {
        final value? => value,
        null => this.groupingStatus,
      },
      volume: clearVolume
          ? null
          : switch (volume) {
              final value? => value,
              null => this.volume,
            },
    );
  }

  @override
  List<Object?> get props => [
        identifiers,
        name,
        deviceType,
        modelDisplayName,
        capabilities,
        groupingStatus,
        volume,
      ];
}
