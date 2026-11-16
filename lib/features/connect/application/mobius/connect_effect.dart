// 1:1 replica of p199p/d6k.java (lines 1-12), p199p/qtq.java (lines 55-76),
// p199p/kya.java (lines 153-171), p199p/azq.java (lines 54-58),
// p199p/v8k.java (lines 54-120), p199p/c8r.java (lines 200-226),
// p199p/c8k.java (lines 93-105), p199p/fsq.java (lines 50-62),
// p199p/C2086nd.java (lines 25-87), p199p/dmf.java (lines 403-412),
// p199p/a0f1.java (lines 409-422), and p199p/lw51.java (lines 295-333).

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

/// Sealed Mobius side-effect hierarchy for Connect command dispatch.
@immutable
sealed class ConnectEffect extends Equatable {
  const ConnectEffect();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Transfers playback to [deviceIdentifier] (or pulls if `'local_device'`)
/// (`p199p/qtq.java:55-76`, `p199p/kya.java:153-171`).
@immutable
final class TransferToDeviceEffect extends ConnectEffect {
  final String deviceIdentifier;
  final String localConnectStateIdentifier;
  final TransferSource source;
  final String? interactionId;
  final bool? dodo;

  TransferToDeviceEffect({
    required this.deviceIdentifier,
    this.localConnectStateIdentifier = '',
    this.source = TransferSource.inApp,
    this.interactionId,
    this.dodo,
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props => [
        deviceIdentifier,
        localConnectStateIdentifier,
        source,
        interactionId,
        dodo,
      ];
}

/// Pulls playback to the local device (`p199p/qtq.m74483i`, `p199p/v8k.m85994e`).
@immutable
final class PullPlaybackEffect extends ConnectEffect {
  final String? interactionId;

  const PullPlaybackEffect({this.interactionId});

  @override
  List<Object?> get props => [interactionId];
}

/// Records a remote device connection timestamp (`p199p/azq.java:54-58`).
@immutable
final class RecordDeviceConnectionEffect extends ConnectEffect {
  final String deviceIdentifier;
  final String localConnectStateIdentifier;

  RecordDeviceConnectionEffect({
    required this.deviceIdentifier,
    this.localConnectStateIdentifier = '',
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props => [deviceIdentifier, localConnectStateIdentifier];
}

/// Logs out a Connect device (`p199p/v8k.m85993d`).
@immutable
final class LogoutDeviceEffect extends ConnectEffect {
  final String deviceIdentifier;

  LogoutDeviceEffect({required this.deviceIdentifier}) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props => [deviceIdentifier];
}

/// Sets active remote volume `[0.0, 1.0]` via `RemoteVolumeController` (`p199p/a0f1.java:409-422`).
@immutable
final class SetVolumeEffect extends ConnectEffect {
  final double volume;
  final String? interactionId;

  SetVolumeEffect({
    required this.volume,
    this.interactionId,
  }) {
    if (!volume.isFinite) {
      throw RangeError.value(
        volume,
        'volume',
        'Must be finite and within [0.0, 1.0]',
      );
    }
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError.range(volume, 0, 1, 'volume', 'Must be within [0.0, 1.0]');
    }
  }

  @override
  List<Object?> get props => [volume, interactionId];
}

/// Steps active remote volume up or down via `RemoteVolumeController` (`p199p/lw51.java:295-333`).
@immutable
final class StepVolumeEffect extends ConnectEffect {
  final int direction;
  final String? interactionId;

  StepVolumeEffect({
    required this.direction,
    this.interactionId,
  }) {
    if (direction == 0) {
      throw ArgumentError.value(direction, 'direction', 'Must be non-zero');
    }
  }

  @override
  List<Object?> get props => [direction, interactionId];
}

/// Sets speaker group member volume `[0.0, 1.0]` (`p199p/a0f1.java:418-420`).
@immutable
final class SetGroupVolumeEffect extends ConnectEffect {
  final String groupDeviceIdentifier;
  final double volume;
  final String? interactionId;

  SetGroupVolumeEffect({
    required this.groupDeviceIdentifier,
    required this.volume,
    this.interactionId,
  }) {
    if (groupDeviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        groupDeviceIdentifier,
        'groupDeviceIdentifier',
        'Must be non-empty',
      );
    }
    if (!volume.isFinite) {
      throw RangeError.value(
        volume,
        'volume',
        'Must be finite and within [0.0, 1.0]',
      );
    }
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError.range(volume, 0, 1, 'volume', 'Must be within [0.0, 1.0]');
    }
  }

  @override
  List<Object?> get props => [groupDeviceIdentifier, volume, interactionId];
}

/// Steps speaker group member volume up or down (`p199p/lw51.java:299-332`).
@immutable
final class StepGroupVolumeEffect extends ConnectEffect {
  final String groupDeviceIdentifier;
  final int direction;
  final String? interactionId;

  StepGroupVolumeEffect({
    required this.groupDeviceIdentifier,
    required this.direction,
    this.interactionId,
  }) {
    if (groupDeviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        groupDeviceIdentifier,
        'groupDeviceIdentifier',
        'Must be non-empty',
      );
    }
    if (direction == 0) {
      throw ArgumentError.value(direction, 'direction', 'Must be non-zero');
    }
  }

  @override
  List<Object?> get props => [groupDeviceIdentifier, direction, interactionId];
}

/// Refreshes the Connect cluster (`p199p/C2086nd.java:50-52`).
@immutable
final class RefreshClusterEffect extends ConnectEffect {
  const RefreshClusterEffect();
}

/// Wakes sleeping devices in the Connect cluster (`p199p/C2086nd.java:85-87`).
@immutable
final class WakeSleepingDevicesEffect extends ConnectEffect {
  const WakeSleepingDevicesEffect();
}

/// Triggers local Connect device discovery (`p199p/C2086nd.java:25-27`).
@immutable
final class PerformDiscoveryEffect extends ConnectEffect {
  const PerformDiscoveryEffect();
}

/// Adds [deviceIdentifier] to speaker group [groupDeviceIdentifier] (`p199p/v8k.m85990a`).
@immutable
final class AddDeviceToGroupEffect extends ConnectEffect {
  final String deviceIdentifier;
  final String groupDeviceIdentifier;
  final String? interactionId;

  AddDeviceToGroupEffect({
    required this.deviceIdentifier,
    required this.groupDeviceIdentifier,
    this.interactionId,
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
    if (groupDeviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        groupDeviceIdentifier,
        'groupDeviceIdentifier',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props =>
      [deviceIdentifier, groupDeviceIdentifier, interactionId];
}

/// Removes [deviceIdentifier] from speaker group [groupDeviceIdentifier] (`p199p/v8k.m85995f`).
@immutable
final class RemoveDeviceFromGroupEffect extends ConnectEffect {
  final String deviceIdentifier;
  final String groupDeviceIdentifier;
  final String? interactionId;

  RemoveDeviceFromGroupEffect({
    required this.deviceIdentifier,
    required this.groupDeviceIdentifier,
    this.interactionId,
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
    if (groupDeviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        groupDeviceIdentifier,
        'groupDeviceIdentifier',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props =>
      [deviceIdentifier, groupDeviceIdentifier, interactionId];
}

/// Deletes a speaker group (`ConnectService.DeleteGroup`).
@immutable
final class DeleteGroupEffect extends ConnectEffect {
  final String deviceIdentifier;
  final String? interactionId;

  DeleteGroupEffect({
    required this.deviceIdentifier,
    this.interactionId,
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props => [deviceIdentifier, interactionId];
}

/// Sets preferred incarnation login type (`p199p/c8r.java:200-226`).
@immutable
final class SetPreferredIncarnationEffect extends ConnectEffect {
  final String deviceId;
  final IncarnationLoginType? preferredLoginType;
  final String? interactionId;

  SetPreferredIncarnationEffect({
    required this.deviceId,
    this.preferredLoginType,
    this.interactionId,
  }) {
    if (deviceId.trim().isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must be non-empty');
    }
  }

  @override
  List<Object?> get props => [deviceId, preferredLoginType, interactionId];
}

/// Notifies Connect backend of local audio route change (`p199p/fsq.java:50-62`).
@immutable
final class NotifyAudioRouteChangedEffect extends ConnectEffect {
  final String? audioOutputDeviceName;
  final OutputPeripheralConnectionType? connectionType;
  final String? audioOutputDeviceBrand;
  final String? audioOutputDeviceModel;
  final OutputPeripheralCategory? category;

  const NotifyAudioRouteChangedEffect({
    this.audioOutputDeviceName,
    this.connectionType,
    this.audioOutputDeviceBrand,
    this.audioOutputDeviceModel,
    this.category,
  });

  @override
  List<Object?> get props => [
        audioOutputDeviceName,
        connectionType,
        audioOutputDeviceBrand,
        audioOutputDeviceModel,
        category,
      ];
}

/// Streams Spotify installation on a remote device (`p199p/c8k.java:93-105`).
@immutable
final class InstallSpotifyEffect extends ConnectEffect {
  static const int _maxUint32 = 0xFFFFFFFF;

  final String deviceIdentifier;
  final int port;
  final String? interactionId;

  InstallSpotifyEffect({
    required this.deviceIdentifier,
    this.port = 0,
    this.interactionId,
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
    if (port < 0 || port > _maxUint32) {
      throw RangeError.range(
        port,
        0,
        _maxUint32,
        'port',
        'Must be within [0, $_maxUint32]',
      );
    }
  }

  @override
  List<Object?> get props => [deviceIdentifier, port, interactionId];
}

/// Switches active Dodo session (`DodoServiceClient.switchToDodo`).
@immutable
final class SwitchToDodoEffect extends ConnectEffect {
  final String csId;

  const SwitchToDodoEffect({required this.csId});

  @override
  List<Object?> get props => [csId];
}

/// Creates a new Dodo session (`DodoServiceClient.createNewDodo`).
@immutable
final class CreateNewDodoEffect extends ConnectEffect {
  const CreateNewDodoEffect();
}

/// Ends the active Dodo session (`DodoServiceClient.endDodo`).
@immutable
final class EndDodoEffect extends ConnectEffect {
  const EndDodoEffect();
}

/// Queries whether cluster update arrived after backend connection (`p199p/dmf.java:403-412`).
@immutable
final class ClusterUpdateAfterBackendConnectionEffect extends ConnectEffect {
  const ClusterUpdateAfterBackendConnectionEffect();
}
