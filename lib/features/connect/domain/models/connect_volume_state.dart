// 1:1 replica of p199p/xsh1.java (lines 7–186), p199p/x3t.java (lines 4–15),
// p199p/dh40.java (lines 4–15), p199p/zg40.java (lines 4–42),
// p199p/krb.java (line 194), p199p/efa1.java (line 177),
// p199p/gsk1.java (lines 291–297), p199p/jel1.java (lines 2910–2946),
// p199p/nsk1.java (lines 1270–1275), p199p/r1h.java (lines 4–11),
// and protos/esperanto/volume_messages.proto (VolumeResponse, lines 17–22).

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';

/// Maximum wire volume value (`0..65535`) used by Connect Esperanto volume RPCs
/// (`p199p/krb.java:194`, `p199p/efa1.java:177`, `ConnectSubsystem.h:57`).
const int kMaxConnectVolumeWire = 65535;

/// Target audio output mode for Connect volume control (`p199p/xsh1.f278733g`,
/// `p199p/ekv0.java:289–292`).
enum VolumeOutputMode {
  local, // 1 in xsh1
  remote, // 2 in xsh1
}

/// Esperanto volume response status matching `spotify.connect.esperanto.proto.Status`
/// (`p199p/r1h.java:4–11`, `es_common_messages.pbenum.dart:23–33`).
enum ConnectVolumeStatus {
  ok, // 0: OK
  notFound, // 1: NOT_FOUND
  invalidArguments, // 2: INVALID_ARGUMENTS
  backendFailure, // 3: BACKEND_FAILURE
  unimplemented; // 4: UNIMPLEMENTED

  /// Maps proto `Status` integer (`0..4`) to [ConnectVolumeStatus].
  static ConnectVolumeStatus fromProtoIndex(int value) {
    switch (value) {
      case 0:
        return ConnectVolumeStatus.ok;
      case 1:
        return ConnectVolumeStatus.notFound;
      case 2:
        return ConnectVolumeStatus.invalidArguments;
      case 3:
        return ConnectVolumeStatus.backendFailure;
      case 4:
        return ConnectVolumeStatus.unimplemented;
      default:
        throw RangeError.range(
          value,
          0,
          4,
          'value',
          'Invalid ConnectVolumeStatus proto index',
        );
    }
  }
}

/// Normalized volume snapshot for a speaker group sub-device (`p199p/zg40.java`,
/// `p199p/dh40.java`).
@immutable
final class GroupDeviceVolume extends Equatable {
  /// Normalized volume in `[0.0, 1.0]`.
  final double volume;

  /// Optional discrete volume steps supported by the sub-device.
  final int? volumeSteps;

  GroupDeviceVolume({
    required this.volume,
    this.volumeSteps,
  }) {
    if (!volume.isFinite) {
      throw RangeError.value(
        volume,
        'volume',
        'Must be a finite value within [0.0, 1.0]',
      );
    }
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError.range(
        volume,
        0,
        1,
        'volume',
        'Must be within [0.0, 1.0]',
      );
    }
    final steps = volumeSteps;
    if (steps != null && steps < 0) {
      throw RangeError.value(
        steps,
        'volumeSteps',
        'Must be non-negative',
      );
    }
  }

  /// Constructs a [GroupDeviceVolume] from a raw `0..65535` wire integer
  /// (`p199p/n8d.java:841`, `p199p/krb.java:194`).
  factory GroupDeviceVolume.fromWire({
    required int rawVolume,
    int? volumeSteps,
  }) {
    if (rawVolume < 0 || rawVolume > kMaxConnectVolumeWire) {
      throw RangeError.range(
        rawVolume,
        0,
        kMaxConnectVolumeWire,
        'rawVolume',
        'Must be within [0, $kMaxConnectVolumeWire]',
      );
    }
    return GroupDeviceVolume(
      volume: rawVolume / kMaxConnectVolumeWire,
      volumeSteps: volumeSteps,
    );
  }

  /// Converts normalized [volume] back to a `0..65535` wire integer
  /// (`p199p/efa1.java:177`).
  int toWireVolume() => (volume * kMaxConnectVolumeWire).round();

  /// Step delta (`1.0 / volumeSteps`) when `volumeSteps > 0`, else `null`.
  double? get stepSize {
    final steps = volumeSteps;
    if (steps == null || steps <= 0) {
      return null;
    }
    return 1.0 / steps;
  }

  GroupDeviceVolume copyWith({
    double? volume,
    int? volumeSteps,
    bool clearVolumeSteps = false,
  }) {
    return GroupDeviceVolume(
      volume: switch (volume) {
        final value? => value,
        null => this.volume,
      },
      volumeSteps: clearVolumeSteps
          ? null
          : switch (volumeSteps) {
              final value? => value,
              null => this.volumeSteps,
            },
    );
  }

  @override
  List<Object?> get props => [volume, volumeSteps];
}

/// Aggregate Connect volume state matching `p199p/xsh1.java` and
/// `VolumeMessages$VolumeResponse` (`volume_messages.proto:17–22`).
@immutable
final class ConnectVolumeState extends Equatable {
  /// Normalized remote active-device volume in `[0.0, 1.0]` (`xsh1.f278727a`).
  final double? remoteVolume;

  /// Normalized local device volume in `[0.0, 1.0]` (`xsh1.f278728b`).
  final double? localVolume;

  /// Active Connect device paired with this volume state (`xsh1.f278729c`).
  final ConnectDevice? activeDevice;

  /// Whether effective volume targets local or remote output (`xsh1.f278733g`).
  final VolumeOutputMode outputMode;

  /// Whether a remote volume change request is currently in flight (`xsh1.f278732f`).
  final bool isChangingVolume;

  /// Esperanto response status (`VolumeResponse.status`).
  final ConnectVolumeStatus status;

  /// Active device Connect state identifier (`VolumeResponse.active_device_connect_state_identifier`).
  final String? activeDeviceConnectStateIdentifier;

  /// Group sub-device volumes keyed by `groupDeviceIdentifier` (`xsh1.f278736j`,
  /// `VolumeResponse.group_device_volumes`).
  final UnmodifiableMapView<String, GroupDeviceVolume> groupDeviceVolumes;

  /// Group sub-device IDs with pending volume updates (`xsh1.f278737k`).
  final UnmodifiableSetView<String> pendingGroupDeviceIds;

  ConnectVolumeState({
    this.remoteVolume,
    this.localVolume,
    this.activeDevice,
    this.outputMode = VolumeOutputMode.local,
    this.isChangingVolume = false,
    this.status = ConnectVolumeStatus.ok,
    this.activeDeviceConnectStateIdentifier,
    Map<String, GroupDeviceVolume> groupDeviceVolumes =
        const <String, GroupDeviceVolume>{},
    Set<String> pendingGroupDeviceIds = const <String>{},
  })  : groupDeviceVolumes = UnmodifiableMapView<String, GroupDeviceVolume>(
          Map<String, GroupDeviceVolume>.of(groupDeviceVolumes),
        ),
        pendingGroupDeviceIds = UnmodifiableSetView<String>(
          Set<String>.of(pendingGroupDeviceIds),
        ) {
    final remote = remoteVolume;
    if (remote != null) {
      if (!remote.isFinite) {
        throw RangeError.value(
          remote,
          'remoteVolume',
          'Must be a finite value within [0.0, 1.0]',
        );
      }
      if (remote < 0.0 || remote > 1.0) {
        throw RangeError.range(
          remote,
          0,
          1,
          'remoteVolume',
          'Must be within [0.0, 1.0]',
        );
      }
    }
    final local = localVolume;
    if (local != null) {
      if (!local.isFinite) {
        throw RangeError.value(
          local,
          'localVolume',
          'Must be a finite value within [0.0, 1.0]',
        );
      }
      if (local < 0.0 || local > 1.0) {
        throw RangeError.range(
          local,
          0,
          1,
          'localVolume',
          'Must be within [0.0, 1.0]',
        );
      }
    }
  }

  /// Active output volume selected by [outputMode], mirroring `p199p/xsh1.m92581b()`.
  double? get effectiveVolume => switch (outputMode) {
        VolumeOutputMode.local => localVolume,
        VolumeOutputMode.remote => remoteVolume,
      };

  /// Whether the active device supports remote volume control, matching
  /// `p199p/nsk1.m66607y` (`!device.isLocal && device.supportsVolume && device.volumeSteps > 0`).
  bool get isRemoteVolumeControllable {
    final device = activeDevice;
    if (device == null) {
      return false;
    }
    return !device.isLocal && device.supportsVolume && device.volumeSteps > 0;
  }

  /// Single-step normalized increment (`1.0 / volumeSteps`) when `volumeSteps > 0`,
  /// matching `p199p/jel1.java:2911–2916`.
  double? get stepSize {
    final device = activeDevice;
    if (device == null || device.volumeSteps <= 0) {
      return null;
    }
    return 1.0 / device.volumeSteps;
  }

  /// Derived mute indicator (`VolumeResponse` has no wire `is_muted` boolean field).
  bool get isMuted => effectiveVolume == 0.0;

  ConnectVolumeState copyWith({
    double? remoteVolume,
    bool clearRemoteVolume = false,
    double? localVolume,
    bool clearLocalVolume = false,
    ConnectDevice? activeDevice,
    bool clearActiveDevice = false,
    VolumeOutputMode? outputMode,
    bool? isChangingVolume,
    ConnectVolumeStatus? status,
    String? activeDeviceConnectStateIdentifier,
    bool clearActiveDeviceConnectStateIdentifier = false,
    Map<String, GroupDeviceVolume>? groupDeviceVolumes,
    Set<String>? pendingGroupDeviceIds,
  }) {
    return ConnectVolumeState(
      remoteVolume: clearRemoteVolume
          ? null
          : switch (remoteVolume) {
              final value? => value,
              null => this.remoteVolume,
            },
      localVolume: clearLocalVolume
          ? null
          : switch (localVolume) {
              final value? => value,
              null => this.localVolume,
            },
      activeDevice: clearActiveDevice
          ? null
          : switch (activeDevice) {
              final value? => value,
              null => this.activeDevice,
            },
      outputMode: switch (outputMode) {
        final value? => value,
        null => this.outputMode,
      },
      isChangingVolume: switch (isChangingVolume) {
        final value? => value,
        null => this.isChangingVolume,
      },
      status: switch (status) {
        final value? => value,
        null => this.status,
      },
      activeDeviceConnectStateIdentifier: clearActiveDeviceConnectStateIdentifier
          ? null
          : switch (activeDeviceConnectStateIdentifier) {
              final value? => value,
              null => this.activeDeviceConnectStateIdentifier,
            },
      groupDeviceVolumes: switch (groupDeviceVolumes) {
        final value? => value,
        null => this.groupDeviceVolumes,
      },
      pendingGroupDeviceIds: switch (pendingGroupDeviceIds) {
        final value? => value,
        null => this.pendingGroupDeviceIds,
      },
    );
  }

  @override
  List<Object?> get props => [
        remoteVolume,
        localVolume,
        activeDevice,
        outputMode,
        isChangingVolume,
        status,
        activeDeviceConnectStateIdentifier,
        groupDeviceVolumes,
        pendingGroupDeviceIds,
      ];
}
