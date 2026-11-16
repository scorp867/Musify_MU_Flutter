// 1:1 replica of p199p/d6k.java (lines 1-12), p199p/qtq.java (lines 55-76),
// p199p/kya.java (lines 153-171), p199p/azq.java (lines 54-58),
// p199p/v8k.java (lines 54-120), p199p/c8r.java (lines 200-226),
// p199p/c8k.java (lines 93-105), p199p/ntq.java (lines 20-40),
// p199p/fsq.java (lines 50-62), p199p/C2086nd.java (lines 25-87),
// p199p/dmf.java (lines 403-412), p199p/a0f1.java (lines 409-422),
// and p199p/lw51.java (lines 295-333).

import 'dart:async';
import 'dart:math' as math;

import 'package:musify_mu/features/connect/application/mobius/connect_effect.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_event.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/mappers/connect_proto_mappers.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';

/// Generates a 32-character lowercase hexadecimal command identifier matching
/// `p199p/cnb.m34826w()`.
String _defaultCommandIdGenerator() {
  final random = math.Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

final class _InstallSession {
  final Completer<ConnectEvent?> completer = Completer<ConnectEvent?>();
  StreamSubscription<connect_pb.InstallSpotifyState>? subscription;
  Future<void>? cancelFuture;
  bool isCancelled = false;
}

/// Executes asynchronous Connect side effects against [ConnectServiceClient],
/// [RemoteVolumeController], [DodoServiceClient], and [DevicePickerSortingDatabase].
final class ConnectEffectHandler
    implements MobiusEffectHandler<ConnectEffect, ConnectEvent> {
  static const String localDeviceIdentifier = kLocalDeviceIdentifier;

  final ConnectServiceClient _connectServiceClient;
  final RemoteVolumeController _remoteVolumeController;
  final DodoServiceClient _dodoServiceClient;
  final DevicePickerSortingDatabase _sortingDatabase;
  final ConnectProtoMappers _mappers;
  final void Function(ConnectEvent event)? _onIntermediateEvent;
  final String Function() _commandIdGenerator;
  final Set<_InstallSession> _activeInstallSessions = <_InstallSession>{};
  int _handlerEpoch = 0;

  ConnectEffectHandler({
    required ConnectServiceClient connectServiceClient,
    required RemoteVolumeController remoteVolumeController,
    required DodoServiceClient dodoServiceClient,
    required DevicePickerSortingDatabase sortingDatabase,
    ConnectProtoMappers mappers = const ConnectProtoMappers(),
    void Function(ConnectEvent event)? onIntermediateEvent,
    String Function()? commandIdGenerator,
  })  : _connectServiceClient = connectServiceClient,
        _remoteVolumeController = remoteVolumeController,
        _dodoServiceClient = dodoServiceClient,
        _sortingDatabase = sortingDatabase,
        _mappers = mappers,
        _onIntermediateEvent = onIntermediateEvent,
        _commandIdGenerator = switch (commandIdGenerator) {
          final generator? => generator,
          null => _defaultCommandIdGenerator,
        };

  /// Cancels any active streaming side effects (such as `InstallSpotify`),
  /// completing their pending futures with `null` without emitting synthetic
  /// error events and keeping this handler reusable across restarts.
  Future<void> cancelActiveEffects() async {
    _handlerEpoch += 1;
    if (_activeInstallSessions.isEmpty) {
      return;
    }
    final sessions = List<_InstallSession>.of(_activeInstallSessions);
    _activeInstallSessions.clear();
    final cancelFutures = <Future<void>>[];
    for (final session in sessions) {
      session.isCancelled = true;
      final sub = session.subscription;
      session.subscription = null;
      if (sub != null) {
        final future = sub.cancel();
        session.cancelFuture = future;
        cancelFutures.add(future);
      }
      if (!session.completer.isCompleted) {
        session.completer.complete(null);
      }
    }
    if (cancelFutures.isNotEmpty) {
      await Future.wait<void>(cancelFutures);
    }
  }

  @override
  Future<ConnectEvent?> handleEffect(ConnectEffect effect) {
    return switch (effect) {
      TransferToDeviceEffect() => _handleTransferToDevice(effect),
      PullPlaybackEffect() => _handlePullPlayback(effect),
      RecordDeviceConnectionEffect() => _handleRecordDeviceConnection(effect),
      LogoutDeviceEffect() => _handleLogoutDevice(effect),
      SetVolumeEffect() => _handleSetVolume(effect),
      StepVolumeEffect() => _handleStepVolume(effect),
      SetGroupVolumeEffect() => _handleSetGroupVolume(effect),
      StepGroupVolumeEffect() => _handleStepGroupVolume(effect),
      RefreshClusterEffect() => _handleRefreshCluster(),
      WakeSleepingDevicesEffect() => _handleWakeSleepingDevices(),
      PerformDiscoveryEffect() => _handlePerformDiscovery(),
      AddDeviceToGroupEffect() => _handleAddDeviceToGroup(effect),
      RemoveDeviceFromGroupEffect() => _handleRemoveDeviceFromGroup(effect),
      DeleteGroupEffect() => _handleDeleteGroup(effect),
      SetPreferredIncarnationEffect() => _handleSetPreferredIncarnation(effect),
      NotifyAudioRouteChangedEffect() => _handleNotifyAudioRouteChanged(effect),
      InstallSpotifyEffect() => _handleInstallSpotify(effect),
      SwitchToDodoEffect() => _handleSwitchToDodo(effect),
      CreateNewDodoEffect() => _handleCreateNewDodo(),
      EndDodoEffect() => _handleEndDodo(),
      ClusterUpdateAfterBackendConnectionEffect() =>
        _handleClusterUpdateAfterBackendConnection(),
    };
  }

  Future<ConnectEvent> _handleTransferToDevice(
    TransferToDeviceEffect effect,
  ) async {
    // 1:1 with qtq.m74484k + kya.java:153-171:
    // 'local_device' invokes Pull and NEVER calls sortingDatabase.recordConnection.
    if (effect.deviceIdentifier == localDeviceIdentifier) {
      try {
        final status = await _connectServiceClient.pull(
          loggingParams: _buildLoggingParams(
            interactionId: effect.interactionId,
          ),
        );
        final failureReason = _mappers.mapStatusToTransferFailureReason(status);
        if (failureReason == null) {
          return TransferResultEvent(
            TransferSucceeded(targetDeviceId: localDeviceIdentifier),
          );
        }
        return TransferResultEvent(
          TransferFailed(
            targetDeviceId: localDeviceIdentifier,
            reason: failureReason,
          ),
        );
      } on Object catch (error) {
        return TransferResultEvent(
          TransferFailed(
            targetDeviceId: localDeviceIdentifier,
            reason: TransferFailureReason.transportError,
            errorDescription: error.toString(),
            exception: error,
          ),
        );
      }
    }

    final commandId = _commandIdGenerator();
    try {
      await _sortingDatabase.recordConnection(
        deviceIdentifier: effect.deviceIdentifier,
        localConnectStateIdentifier: effect.localConnectStateIdentifier,
      );
      final loggingParams = _buildLoggingParams(
        interactionId: effect.interactionId,
        commandId: commandId,
      );
      final transferState = await _connectServiceClient.transfer(
        connectDeviceIdentifier: effect.deviceIdentifier,
        loggingParams: loggingParams,
        dodo: effect.dodo,
      );
      return TransferResultEvent(transferState);
    } on Object catch (error) {
      return TransferResultEvent(
        TransferFailed(
          targetDeviceId: effect.deviceIdentifier,
          reason: TransferFailureReason.transportError,
          errorDescription: error.toString(),
          intentionId: commandId,
          exception: error,
        ),
      );
    }
  }

  Future<ConnectEvent> _handlePullPlayback(PullPlaybackEffect effect) async {
    try {
      final status = await _connectServiceClient.pull(
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );
      final failureReason = _mappers.mapStatusToTransferFailureReason(status);
      return PullResultEvent(status: status, failureReason: failureReason);
    } on Object catch (error) {
      return PullResultEvent(
        failureReason: TransferFailureReason.transportError,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleRecordDeviceConnection(
    RecordDeviceConnectionEffect effect,
  ) async {
    if (effect.deviceIdentifier == localDeviceIdentifier) {
      return RecordDeviceConnectionResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        skippedLocalDevice: true,
      );
    }
    try {
      await _sortingDatabase.recordConnection(
        deviceIdentifier: effect.deviceIdentifier,
        localConnectStateIdentifier: effect.localConnectStateIdentifier,
      );
      return RecordDeviceConnectionResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        skippedLocalDevice: false,
      );
    } on Object catch (error) {
      return RecordDeviceConnectionResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        skippedLocalDevice: false,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleLogoutDevice(LogoutDeviceEffect effect) async {
    try {
      final status = await _connectServiceClient.logout(
        connectDeviceIdentifier: effect.deviceIdentifier,
      );
      return LogoutResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        status: status,
      );
    } on Object catch (error) {
      return LogoutResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleSetVolume(SetVolumeEffect effect) async {
    try {
      final status = await _remoteVolumeController.setVolume(
        effect.volume,
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );
      return VolumeCommandResultEvent(status: status);
    } on Object catch (error) {
      return VolumeCommandResultEvent(error: error);
    }
  }

  Future<ConnectEvent> _handleStepVolume(StepVolumeEffect effect) async {
    try {
      final loggingParams = _buildLoggingParams(
        interactionId: effect.interactionId,
      );
      final status = effect.direction > 0
          ? await _remoteVolumeController.volumeUp(loggingParams: loggingParams)
          : await _remoteVolumeController.volumeDown(
              loggingParams: loggingParams,
            );
      return VolumeCommandResultEvent(status: status);
    } on Object catch (error) {
      return VolumeCommandResultEvent(error: error);
    }
  }

  Future<ConnectEvent> _handleSetGroupVolume(
    SetGroupVolumeEffect effect,
  ) async {
    try {
      final status = await _remoteVolumeController.setGroupVolume(
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        volume: effect.volume,
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );
      return VolumeCommandResultEvent(
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        status: status,
      );
    } on Object catch (error) {
      return VolumeCommandResultEvent(
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleStepGroupVolume(
    StepGroupVolumeEffect effect,
  ) async {
    try {
      final loggingParams = _buildLoggingParams(
        interactionId: effect.interactionId,
      );
      final status = effect.direction > 0
          ? await _remoteVolumeController.groupVolumeUp(
              groupDeviceIdentifier: effect.groupDeviceIdentifier,
              loggingParams: loggingParams,
            )
          : await _remoteVolumeController.groupVolumeDown(
              groupDeviceIdentifier: effect.groupDeviceIdentifier,
              loggingParams: loggingParams,
            );
      return VolumeCommandResultEvent(
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        status: status,
      );
    } on Object catch (error) {
      return VolumeCommandResultEvent(
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleRefreshCluster() async {
    try {
      await _connectServiceClient.refreshCluster();
      return const RefreshClusterResultEvent(succeeded: true);
    } on Object catch (error) {
      return RefreshClusterResultEvent(succeeded: false, error: error);
    }
  }

  Future<ConnectEvent> _handleWakeSleepingDevices() async {
    try {
      await _connectServiceClient.wakeSleepingClusterDevices();
      return const WakeSleepingDevicesResultEvent(succeeded: true);
    } on Object catch (error) {
      return WakeSleepingDevicesResultEvent(succeeded: false, error: error);
    }
  }

  Future<ConnectEvent> _handlePerformDiscovery() async {
    try {
      await _connectServiceClient.performDiscovery();
      return const PerformDiscoveryResultEvent(succeeded: true);
    } on Object catch (error) {
      return PerformDiscoveryResultEvent(succeeded: false, error: error);
    }
  }

  Future<ConnectEvent> _handleAddDeviceToGroup(
    AddDeviceToGroupEffect effect,
  ) async {
    try {
      final response = await _connectServiceClient.addDeviceToGroup(
        connectDeviceIdentifier: effect.deviceIdentifier,
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );
      return AddDeviceToGroupResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        success: response.success,
        groupError: response.hasError() ? response.error : null,
      );
    } on Object catch (error) {
      return AddDeviceToGroupResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        success: false,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleRemoveDeviceFromGroup(
    RemoveDeviceFromGroupEffect effect,
  ) async {
    try {
      final response = await _connectServiceClient.removeDeviceFromGroup(
        connectDeviceIdentifier: effect.deviceIdentifier,
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );
      return RemoveDeviceFromGroupResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        success: response.success,
        removeGroupError: response.hasError() ? response.error : null,
      );
    } on Object catch (error) {
      return RemoveDeviceFromGroupResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        groupDeviceIdentifier: effect.groupDeviceIdentifier,
        success: false,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleDeleteGroup(DeleteGroupEffect effect) async {
    try {
      final response = await _connectServiceClient.deleteGroup(
        connectDeviceIdentifier: effect.deviceIdentifier,
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );
      return DeleteGroupResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        success: response.success,
        deleteGroupError: response.hasError() ? response.error : null,
      );
    } on Object catch (error) {
      return DeleteGroupResultEvent(
        deviceIdentifier: effect.deviceIdentifier,
        success: false,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleSetPreferredIncarnation(
    SetPreferredIncarnationEffect effect,
  ) async {
    try {
      final status = await _connectServiceClient.setPreferredIncarnation(
        deviceId: effect.deviceId,
        preferredLoginType: effect.preferredLoginType,
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );
      return SetPreferredIncarnationResultEvent(
        deviceId: effect.deviceId,
        status: status,
      );
    } on Object catch (error) {
      return SetPreferredIncarnationResultEvent(
        deviceId: effect.deviceId,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleNotifyAudioRouteChanged(
    NotifyAudioRouteChangedEffect effect,
  ) async {
    try {
      await _connectServiceClient.notifyAudioRouteChanged(
        audioOutputDeviceName: effect.audioOutputDeviceName,
        connectionType: effect.connectionType,
        audioOutputDeviceBrand: effect.audioOutputDeviceBrand,
        audioOutputDeviceModel: effect.audioOutputDeviceModel,
        category: effect.category,
      );
      return const NotifyAudioRouteChangedResultEvent(succeeded: true);
    } on Object catch (error) {
      return NotifyAudioRouteChangedResultEvent(
        succeeded: false,
        error: error,
      );
    }
  }

  Future<ConnectEvent?> _handleInstallSpotify(
    InstallSpotifyEffect effect,
  ) async {
    final sessionEpoch = _handlerEpoch;
    final session = _InstallSession();
    _activeInstallSessions.add(session);

    void finishSession(ConnectEvent? event) {
      _activeInstallSessions.remove(session);
      final sub = session.subscription;
      session.subscription = null;
      if (sub != null) {
        session.cancelFuture = sub.cancel();
      }
      if (!session.completer.isCompleted) {
        session.completer.complete(event);
      }
    }

    try {
      final stream = _connectServiceClient.installSpotify(
        connectDeviceIdentifier: effect.deviceIdentifier,
        port: effect.port,
        loggingParams: _buildLoggingParams(interactionId: effect.interactionId),
      );

      if (session.isCancelled || sessionEpoch != _handlerEpoch) {
        _activeInstallSessions.remove(session);
        return null;
      }

      final subscription = stream.listen(
        (installState) {
          if (session.isCancelled ||
              sessionEpoch != _handlerEpoch ||
              session.completer.isCompleted) {
            return;
          }
          if (installState.value >= 100) {
            finishSession(
              InstallSpotifyProgressEvent(
                deviceIdentifier: effect.deviceIdentifier,
                installState: installState,
                isTerminalSuccess: false,
                isTerminalFailure: true,
              ),
            );
            return;
          }
          if (installState == connect_pb.InstallSpotifyState.SUCCESS) {
            finishSession(
              InstallSpotifyProgressEvent(
                deviceIdentifier: effect.deviceIdentifier,
                installState: installState,
                isTerminalSuccess: true,
                isTerminalFailure: false,
              ),
            );
            return;
          }
          _onIntermediateEvent?.call(
            InstallSpotifyProgressEvent(
              deviceIdentifier: effect.deviceIdentifier,
              installState: installState,
              isTerminalSuccess: false,
              isTerminalFailure: false,
            ),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          if (session.isCancelled ||
              sessionEpoch != _handlerEpoch ||
              session.completer.isCompleted) {
            return;
          }
          finishSession(
            InstallSpotifyProgressEvent(
              deviceIdentifier: effect.deviceIdentifier,
              isTerminalSuccess: false,
              isTerminalFailure: true,
              error: error,
            ),
          );
        },
        onDone: () {
          if (session.isCancelled ||
              sessionEpoch != _handlerEpoch ||
              session.completer.isCompleted) {
            return;
          }
          finishSession(
            InstallSpotifyProgressEvent(
              deviceIdentifier: effect.deviceIdentifier,
              isTerminalSuccess: false,
              isTerminalFailure: true,
              error: StateError(
                'InstallSpotify stream closed before reaching a terminal state',
              ),
            ),
          );
        },
        cancelOnError: true,
      );

      if (session.isCancelled ||
          sessionEpoch != _handlerEpoch ||
          session.completer.isCompleted) {
        _activeInstallSessions.remove(session);
        await subscription.cancel();
        if (session.isCancelled || sessionEpoch != _handlerEpoch) {
          return null;
        }
        return await session.completer.future;
      }

      session.subscription = subscription;
      final terminalEvent = await session.completer.future;
      final cancelFuture = session.cancelFuture;
      if (cancelFuture != null) {
        await cancelFuture;
      }
      if (session.isCancelled || sessionEpoch != _handlerEpoch) {
        return null;
      }
      return terminalEvent;
    } on Object catch (error) {
      _activeInstallSessions.remove(session);
      final sub = session.subscription;
      session.subscription = null;
      if (sub != null) {
        await sub.cancel();
      }
      if (session.isCancelled || sessionEpoch != _handlerEpoch) {
        return null;
      }
      return InstallSpotifyProgressEvent(
        deviceIdentifier: effect.deviceIdentifier,
        isTerminalSuccess: false,
        isTerminalFailure: true,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleSwitchToDodo(SwitchToDodoEffect effect) async {
    try {
      final status = await _dodoServiceClient.switchToDodo(effect.csId);
      return DodoOperationResultEvent(
        operation: DodoOperationType.switchToDodo,
        status: status,
      );
    } on Object catch (error) {
      return DodoOperationResultEvent(
        operation: DodoOperationType.switchToDodo,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleCreateNewDodo() async {
    try {
      final status = await _dodoServiceClient.createNewDodo();
      return DodoOperationResultEvent(
        operation: DodoOperationType.createNewDodo,
        status: status,
      );
    } on Object catch (error) {
      return DodoOperationResultEvent(
        operation: DodoOperationType.createNewDodo,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleEndDodo() async {
    try {
      final status = await _dodoServiceClient.endDodo();
      return DodoOperationResultEvent(
        operation: DodoOperationType.endDodo,
        status: status,
      );
    } on Object catch (error) {
      return DodoOperationResultEvent(
        operation: DodoOperationType.endDodo,
        error: error,
      );
    }
  }

  Future<ConnectEvent> _handleClusterUpdateAfterBackendConnection() async {
    try {
      final updated =
          await _connectServiceClient.clusterUpdateAfterBackendConnection();
      return ClusterUpdateAfterBackendConnectionResultEvent(
        hasReceivedClusterUpdate: updated,
      );
    } on Object catch (error) {
      return ClusterUpdateAfterBackendConnectionResultEvent(error: error);
    }
  }

  common_pb.LoggingParams? _buildLoggingParams({
    String? interactionId,
    String? commandId,
  }) {
    final hasInteraction = interactionId != null && interactionId.isNotEmpty;
    final hasCommand = commandId != null && commandId.isNotEmpty;
    if (!hasInteraction && !hasCommand) {
      return null;
    }
    return _mappers.buildLoggingParams(
      interactionIds: hasInteraction ? <String>[interactionId] : const <String>[],
      commandId: hasCommand ? commandId : null,
    );
  }
}
