// 1:1 replica of p199p/i6k.java (line 4), p199p/f6k.java (lines 6-13),
// p199p/g6k.java (lines 4-11), p199p/h6k.java (lines 6-13),
// p199p/qtq.java (lines 55-76), p199p/kya.java (lines 153-171),
// p199p/v8k.java, p199p/c8r.java (lines 200-226), p199p/c8k.java (lines 93-105),
// p199p/ntq.java (lines 20-40), p199p/fsq.java (lines 50-62),
// p199p/C2086nd.java (lines 25-87), p199p/dmf.java (lines 403-412),
// p199p/a0f1.java (lines 409-422), and p199p/lw51.java (lines 295-333).

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pbenum.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart'
    as dodos_pb;
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

/// Operation identifier for Dodo RPC result feedback events.
enum DodoOperationType {
  switchToDodo,
  createNewDodo,
  endDodo,
}

/// Sealed Mobius event hierarchy for Spotify Connect (`p199p/i6k.java`).
@immutable
sealed class ConnectEvent extends Equatable {
  const ConnectEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

// ============================================================================
// External Stream & Core Aggregator Events (1:1 with i6k + companion streams)
// ============================================================================

/// Available local audio output peripherals updated (`p199p/f6k.java:6-13`).
@immutable
final class PeripheralsUpdatedEvent extends ConnectEvent {
  final UnmodifiableListView<LocalAudioPeripheral> peripherals;

  PeripheralsUpdatedEvent(List<LocalAudioPeripheral> peripherals)
      : peripherals = UnmodifiableListView<LocalAudioPeripheral>(
          List<LocalAudioPeripheral>.of(peripherals),
        );

  @override
  List<Object?> get props => [peripherals];
}

/// Connect cluster state updated (`p199p/g6k.java:4-11`, `p199p/tck.java`).
@immutable
final class ClusterStateUpdatedEvent extends ConnectEvent {
  final ConnectCluster cluster;

  const ClusterStateUpdatedEvent(this.cluster);

  @override
  List<Object?> get props => [cluster];
}

/// Recommended local device identifiers updated (`p199p/h6k.java:6-13`).
@immutable
final class RecommendedLocalDevicesUpdatedEvent extends ConnectEvent {
  final UnmodifiableListView<String> deviceIds;

  RecommendedLocalDevicesUpdatedEvent(List<String> deviceIds)
      : deviceIds = UnmodifiableListView<String>(List<String>.of(deviceIds));

  @override
  List<Object?> get props => [deviceIds];
}

/// Device picker sorting timestamps updated (`DevicePickerSortingDatabase`).
@immutable
final class SortingTimestampsUpdatedEvent extends ConnectEvent {
  final UnmodifiableMapView<String, int> lastConnectionTimestamps;

  SortingTimestampsUpdatedEvent(Map<String, int> lastConnectionTimestamps)
      : lastConnectionTimestamps = UnmodifiableMapView<String, int>(
          Map<String, int>.of(lastConnectionTimestamps),
        );

  @override
  List<Object?> get props => [lastConnectionTimestamps];
}

/// Volume state updated (`RemoteVolumeController.stream`).
@immutable
final class VolumeStateUpdatedEvent extends ConnectEvent {
  final ConnectVolumeState volumeState;

  const VolumeStateUpdatedEvent(this.volumeState);

  @override
  List<Object?> get props => [volumeState];
}

/// Dodo session list updated (`DodoServiceClient.dodoSub()`).
@immutable
final class DodoSubUpdatedEvent extends ConnectEvent {
  final UnmodifiableListView<dodos_pb.SingleDodo> dodos;

  DodoSubUpdatedEvent(List<dodos_pb.SingleDodo> dodos)
      : dodos = UnmodifiableListView<dodos_pb.SingleDodo>(
          List<dodos_pb.SingleDodo>.of(dodos),
        );

  @override
  List<Object?> get props => [dodos];
}

/// Explicit upstream stream error event (never swallowed, `p199p/C2352uj.java`).
@immutable
final class ConnectStreamErrorEvent extends ConnectEvent {
  final ConnectFailure failure;

  const ConnectStreamErrorEvent(this.failure);

  @override
  List<Object?> get props => [failure];
}

// ============================================================================
// User & System Command Intent Events
// ============================================================================

/// Requests playback transfer to [deviceIdentifier] (`p199p/qtq.java:55-76`).
@immutable
final class TransferToDeviceRequested extends ConnectEvent {
  final String deviceIdentifier;
  final TransferSource source;
  final String? interactionId;
  final bool? dodo;

  TransferToDeviceRequested({
    required this.deviceIdentifier,
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
  List<Object?> get props => [deviceIdentifier, source, interactionId, dodo];
}

/// Requests pulling playback to the local device (`p199p/qtq.m74483i`).
@immutable
final class PullPlaybackRequested extends ConnectEvent {
  final TransferSource source;
  final String? interactionId;

  const PullPlaybackRequested({
    this.source = TransferSource.inApp,
    this.interactionId,
  });

  @override
  List<Object?> get props => [source, interactionId];
}

/// Requests logging out a Connect device (`p199p/v8k.m85993d`).
@immutable
final class LogoutDeviceRequested extends ConnectEvent {
  final String deviceIdentifier;

  LogoutDeviceRequested({required this.deviceIdentifier}) {
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

/// Requests renaming a remote Connect device (`ConnectService.Rename`).
@immutable
final class RenameDeviceRequested extends ConnectEvent {
  final String deviceIdentifier;
  final String newName;
  final String? interactionId;

  RenameDeviceRequested({
    required this.deviceIdentifier,
    required this.newName,
    this.interactionId,
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
    if (newName.trim().isEmpty) {
      throw ArgumentError.value(
        newName,
        'newName',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props => [deviceIdentifier, newName, interactionId];
}

/// Requests sending a raw Connect player command JSON payload to a device
/// (`ConnectService.SendCommand`).
@immutable
final class SendPlayerCommandRequested extends ConnectEvent {
  final String deviceIdentifier;
  final String commandJson;
  final String? interactionId;

  SendPlayerCommandRequested({
    required this.deviceIdentifier,
    required this.commandJson,
    this.interactionId,
  }) {
    if (deviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        deviceIdentifier,
        'deviceIdentifier',
        'Must be non-empty',
      );
    }
    if (commandJson.trim().isEmpty) {
      throw ArgumentError.value(
        commandJson,
        'commandJson',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props => [deviceIdentifier, commandJson, interactionId];
}

/// Requests setting active remote volume `[0.0, 1.0]` (`p199p/a0f1.java:409-422`).
@immutable
final class SetVolumeRequested extends ConnectEvent {
  final double volume;
  final String? interactionId;

  SetVolumeRequested({
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

/// Requests stepping active remote volume up or down (`p199p/lw51.java:295-333`).
@immutable
final class StepVolumeRequested extends ConnectEvent {
  final int direction;
  final String? interactionId;

  StepVolumeRequested({
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

/// Requests setting speaker group member volume `[0.0, 1.0]` (`p199p/a0f1.java:418-420`).
@immutable
final class SetGroupVolumeRequested extends ConnectEvent {
  final String groupDeviceIdentifier;
  final double volume;
  final String? interactionId;

  SetGroupVolumeRequested({
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

/// Requests stepping speaker group member volume up or down (`p199p/lw51.java:299-332`).
@immutable
final class StepGroupVolumeRequested extends ConnectEvent {
  final String groupDeviceIdentifier;
  final int direction;
  final String? interactionId;

  StepGroupVolumeRequested({
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

/// Requests refreshing the Connect cluster (`p199p/C2086nd.java:50-52`).
@immutable
final class RefreshClusterRequested extends ConnectEvent {
  const RefreshClusterRequested();
}

/// Requests waking sleeping Connect cluster devices (`p199p/C2086nd.java:85-87`).
@immutable
final class WakeSleepingDevicesRequested extends ConnectEvent {
  const WakeSleepingDevicesRequested();
}

/// Requests performing local Connect device discovery (`p199p/C2086nd.java:25-27`).
@immutable
final class PerformDiscoveryRequested extends ConnectEvent {
  const PerformDiscoveryRequested();
}

/// Requests adding [deviceIdentifier] to speaker group [groupDeviceIdentifier] (`p199p/v8k.m85990a`).
@immutable
final class AddDeviceToGroupRequested extends ConnectEvent {
  final String deviceIdentifier;
  final String groupDeviceIdentifier;
  final String? interactionId;

  AddDeviceToGroupRequested({
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

/// Requests removing [deviceIdentifier] from speaker group [groupDeviceIdentifier] (`p199p/v8k.m85995f`).
@immutable
final class RemoveDeviceFromGroupRequested extends ConnectEvent {
  final String deviceIdentifier;
  final String groupDeviceIdentifier;
  final String? interactionId;

  RemoveDeviceFromGroupRequested({
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

/// Requests deleting a speaker group (`ConnectService.DeleteGroup`).
@immutable
final class DeleteGroupRequested extends ConnectEvent {
  final String deviceIdentifier;
  final String? interactionId;

  DeleteGroupRequested({
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

/// Requests setting preferred incarnation login type (`p199p/c8r.java:200-226`).
@immutable
final class SetPreferredIncarnationRequested extends ConnectEvent {
  final String deviceId;
  final IncarnationLoginType? preferredLoginType;
  final String? interactionId;

  SetPreferredIncarnationRequested({
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

/// Requests notifying Connect backend of local audio route change (`p199p/fsq.java:50-62`).
@immutable
final class NotifyAudioRouteChangedRequested extends ConnectEvent {
  final String? audioOutputDeviceName;
  final OutputPeripheralConnectionType? connectionType;
  final String? audioOutputDeviceBrand;
  final String? audioOutputDeviceModel;
  final OutputPeripheralCategory? category;

  const NotifyAudioRouteChangedRequested({
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

/// Requests installing Spotify on a remote target device (`p199p/c8k.java:93-105`).
@immutable
final class InstallSpotifyRequested extends ConnectEvent {
  static const int _maxUint32 = 0xFFFFFFFF;

  final String deviceIdentifier;
  final int port;
  final String? interactionId;

  InstallSpotifyRequested({
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

/// Requests switching active Dodo session (`DodoServiceClient.switchToDodo`).
@immutable
final class SwitchToDodoRequested extends ConnectEvent {
  final String csId;

  const SwitchToDodoRequested({required this.csId});

  @override
  List<Object?> get props => [csId];
}

/// Requests creating a new Dodo session (`DodoServiceClient.createNewDodo`).
@immutable
final class CreateNewDodoRequested extends ConnectEvent {
  const CreateNewDodoRequested();
}

/// Requests ending the active Dodo session (`DodoServiceClient.endDodo`).
@immutable
final class EndDodoRequested extends ConnectEvent {
  const EndDodoRequested();
}

/// Requests querying whether cluster update arrived after backend connection (`p199p/dmf.java:403-412`).
@immutable
final class ClusterUpdateAfterBackendConnectionRequested extends ConnectEvent {
  const ClusterUpdateAfterBackendConnectionRequested();
}

/// Clears transient [ConnectState.lastError].
@immutable
final class DismissConnectErrorRequested extends ConnectEvent {
  const DismissConnectErrorRequested();
}

// ============================================================================
// Effect Feedback Events
// ============================================================================

/// Feedback event emitted when `TransferToDeviceEffect` finishes.
@immutable
final class TransferResultEvent extends ConnectEvent {
  final TransferState transferState;

  const TransferResultEvent(this.transferState);

  @override
  List<Object?> get props => [transferState];
}

/// Feedback event emitted when `PullPlaybackEffect` finishes.
@immutable
final class PullResultEvent extends ConnectEvent {
  final common_pb.Status? status;
  final TransferFailureReason? failureReason;
  final Object? error;

  const PullResultEvent({
    this.status,
    this.failureReason,
    this.error,
  });

  @override
  List<Object?> get props => [status, failureReason, error];
}

/// Feedback event emitted when `RecordDeviceConnectionEffect` finishes.
@immutable
final class RecordDeviceConnectionResultEvent extends ConnectEvent {
  final String deviceIdentifier;
  final bool skippedLocalDevice;
  final Object? error;

  const RecordDeviceConnectionResultEvent({
    required this.deviceIdentifier,
    required this.skippedLocalDevice,
    this.error,
  });

  @override
  List<Object?> get props => [deviceIdentifier, skippedLocalDevice, error];
}

/// Feedback event emitted when `LogoutDeviceEffect` finishes.
@immutable
final class LogoutResultEvent extends ConnectEvent {
  final String deviceIdentifier;
  final common_pb.Status? status;
  final Object? error;

  const LogoutResultEvent({
    required this.deviceIdentifier,
    this.status,
    this.error,
  });

  @override
  List<Object?> get props => [deviceIdentifier, status, error];
}

/// Feedback event emitted when `RenameDeviceEffect` finishes.
@immutable
final class RenameDeviceResultEvent extends ConnectEvent {
  final String deviceIdentifier;
  final common_pb.Status? status;
  final Object? error;

  const RenameDeviceResultEvent({
    required this.deviceIdentifier,
    this.status,
    this.error,
  });

  @override
  List<Object?> get props => [deviceIdentifier, status, error];
}

/// Feedback event emitted when `SendPlayerCommandEffect` finishes.
@immutable
final class SendPlayerCommandResultEvent extends ConnectEvent {
  final String deviceIdentifier;
  final int? contextPlayerError;
  final Object? error;

  const SendPlayerCommandResultEvent({
    required this.deviceIdentifier,
    this.contextPlayerError,
    this.error,
  });

  @override
  List<Object?> get props => [deviceIdentifier, contextPlayerError, error];
}

/// Feedback event emitted when a volume effect finishes.
@immutable
final class VolumeCommandResultEvent extends ConnectEvent {
  final String? groupDeviceIdentifier;
  final ConnectVolumeStatus? status;
  final Object? error;

  const VolumeCommandResultEvent({
    this.groupDeviceIdentifier,
    this.status,
    this.error,
  });

  @override
  List<Object?> get props => [groupDeviceIdentifier, status, error];
}

/// Feedback event emitted when `RefreshClusterEffect` finishes.
@immutable
final class RefreshClusterResultEvent extends ConnectEvent {
  final bool succeeded;
  final Object? error;

  const RefreshClusterResultEvent({
    required this.succeeded,
    this.error,
  });

  @override
  List<Object?> get props => [succeeded, error];
}

/// Feedback event emitted when `WakeSleepingDevicesEffect` finishes.
@immutable
final class WakeSleepingDevicesResultEvent extends ConnectEvent {
  final bool succeeded;
  final Object? error;

  const WakeSleepingDevicesResultEvent({
    required this.succeeded,
    this.error,
  });

  @override
  List<Object?> get props => [succeeded, error];
}

/// Feedback event emitted when `PerformDiscoveryEffect` finishes.
@immutable
final class PerformDiscoveryResultEvent extends ConnectEvent {
  final bool succeeded;
  final Object? error;

  const PerformDiscoveryResultEvent({
    required this.succeeded,
    this.error,
  });

  @override
  List<Object?> get props => [succeeded, error];
}

/// Feedback event emitted when `AddDeviceToGroupEffect` finishes.
@immutable
final class AddDeviceToGroupResultEvent extends ConnectEvent {
  final String deviceIdentifier;
  final String groupDeviceIdentifier;
  final bool success;
  final connect_pb.GroupError? groupError;
  final Object? error;

  const AddDeviceToGroupResultEvent({
    required this.deviceIdentifier,
    required this.groupDeviceIdentifier,
    required this.success,
    this.groupError,
    this.error,
  });

  @override
  List<Object?> get props => [
        deviceIdentifier,
        groupDeviceIdentifier,
        success,
        groupError,
        error,
      ];
}

/// Feedback event emitted when `RemoveDeviceFromGroupEffect` finishes.
@immutable
final class RemoveDeviceFromGroupResultEvent extends ConnectEvent {
  final String deviceIdentifier;
  final String groupDeviceIdentifier;
  final bool success;
  final connect_pb.RemoveGroupError? removeGroupError;
  final Object? error;

  const RemoveDeviceFromGroupResultEvent({
    required this.deviceIdentifier,
    required this.groupDeviceIdentifier,
    required this.success,
    this.removeGroupError,
    this.error,
  });

  @override
  List<Object?> get props => [
        deviceIdentifier,
        groupDeviceIdentifier,
        success,
        removeGroupError,
        error,
      ];
}

/// Feedback event emitted when `DeleteGroupEffect` finishes.
@immutable
final class DeleteGroupResultEvent extends ConnectEvent {
  final String deviceIdentifier;
  final bool success;
  final connect_pb.DeleteGroupError? deleteGroupError;
  final Object? error;

  const DeleteGroupResultEvent({
    required this.deviceIdentifier,
    required this.success,
    this.deleteGroupError,
    this.error,
  });

  @override
  List<Object?> get props =>
      [deviceIdentifier, success, deleteGroupError, error];
}

/// Feedback event emitted when `SetPreferredIncarnationEffect` finishes.
@immutable
final class SetPreferredIncarnationResultEvent extends ConnectEvent {
  final String deviceId;
  final common_pb.Status? status;
  final Object? error;

  const SetPreferredIncarnationResultEvent({
    required this.deviceId,
    this.status,
    this.error,
  });

  @override
  List<Object?> get props => [deviceId, status, error];
}

/// Feedback event emitted when `NotifyAudioRouteChangedEffect` finishes.
@immutable
final class NotifyAudioRouteChangedResultEvent extends ConnectEvent {
  final bool succeeded;
  final Object? error;

  const NotifyAudioRouteChangedResultEvent({
    required this.succeeded,
    this.error,
  });

  @override
  List<Object?> get props => [succeeded, error];
}

/// Feedback event emitted for intermediate and terminal `InstallSpotifyEffect` states (`p199p/ntq.java:20-40`).
@immutable
final class InstallSpotifyProgressEvent extends ConnectEvent {
  final String deviceIdentifier;
  final connect_pb.InstallSpotifyState? installState;
  final bool isTerminalSuccess;
  final bool isTerminalFailure;
  final Object? error;

  const InstallSpotifyProgressEvent({
    required this.deviceIdentifier,
    this.installState,
    required this.isTerminalSuccess,
    required this.isTerminalFailure,
    this.error,
  });

  @override
  List<Object?> get props => [
        deviceIdentifier,
        installState,
        isTerminalSuccess,
        isTerminalFailure,
        error,
      ];
}

/// Feedback event emitted when a Dodo operation finishes.
@immutable
final class DodoOperationResultEvent extends ConnectEvent {
  final DodoOperationType operation;
  final common_pb.Status? status;
  final Object? error;

  const DodoOperationResultEvent({
    required this.operation,
    this.status,
    this.error,
  });

  @override
  List<Object?> get props => [operation, status, error];
}

/// Feedback event emitted when `ClusterUpdateAfterBackendConnectionEffect` finishes.
@immutable
final class ClusterUpdateAfterBackendConnectionResultEvent extends ConnectEvent {
  final bool? hasReceivedClusterUpdate;
  final Object? error;

  const ClusterUpdateAfterBackendConnectionResultEvent({
    this.hasReceivedClusterUpdate,
    this.error,
  });

  @override
  List<Object?> get props => [hasReceivedClusterUpdate, error];
}
