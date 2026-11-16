// 1:1 replica of p199p/vrq.java (lines 7-12), p199p/lbv.java (lines 137-150),
// p199p/gtg.java (lines 442-519), and p199p/qtq.java (lines 55-76).

import 'package:musify_mu/features/connect/application/mobius/connect_effect.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_event.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pbenum.dart'
    as common_pb;
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';

Next<ConnectState, ConnectEffect> _next(
  ConnectState model, [
  Set<ConnectEffect> effects = const <ConnectEffect>{},
]) =>
    Next.next<ConnectState, ConnectEffect>(model, effects);

Next<ConnectState, ConnectEffect> _dispatch(Set<ConnectEffect> effects) =>
    Next.dispatch<ConnectState, ConnectEffect>(effects);

Next<ConnectState, ConnectEffect> _noChange() =>
    Next.noChange<ConnectState, ConnectEffect>();

/// Pure deterministic Mobius update function for Spotify Connect matching
/// `p199p/vrq.java` and `p199p/lbv.java#m59792d`, extended with `qtq`/`v8k`
/// command intents and effect-feedback transitions.
Next<ConnectState, ConnectEffect> connectMobiusUpdate(
  ConnectState model,
  ConnectEvent event,
) {
  return switch (event) {
    // ------------------------------------------------------------------------
    // Core i6k Read-Side Aggregation Events (f6k / g6k / h6k -> zero effects)
    // ------------------------------------------------------------------------
    PeripheralsUpdatedEvent(:final peripherals) => _next(
        model.withProjection(
          internal: model.internal.copyWith(peripherals: peripherals),
        ),
      ),

    ClusterStateUpdatedEvent(:final cluster) => _next(
        model.withProjection(
          internal: model.internal.copyWith(
            isSyncedWithBackend: cluster.isSyncedWithBackend,
            rawDevices: cluster.devices,
          ),
          cluster: cluster,
        ),
      ),

    RecommendedLocalDevicesUpdatedEvent(:final deviceIds) => _next(
        model.withProjection(
          internal: model.internal.copyWith(
            recommendedLocalDeviceIds: deviceIds,
          ),
        ),
      ),

    SortingTimestampsUpdatedEvent(:final lastConnectionTimestamps) => _next(
        model.withProjection(
          lastConnectionTimestamps: lastConnectionTimestamps,
        ),
      ),

    VolumeStateUpdatedEvent(:final volumeState) => _next(
        model.copyWith(volumeState: volumeState),
      ),

    DodoSubUpdatedEvent(:final dodos) => _next(
        model.copyWith(dodos: dodos),
      ),

    ConnectStreamErrorEvent(:final failure) => _next(
        model.copyWith(lastError: failure),
      ),

    // ------------------------------------------------------------------------
    // User / System Command Intent Events
    // ------------------------------------------------------------------------
    TransferToDeviceRequested(
      :final deviceIdentifier,
      :final source,
      :final interactionId,
      :final dodo,
    ) =>
      () {
        // 1:1 with qtq.m74484k: 'local_device' invokes Pull and never writes sorting DB.
        if (deviceIdentifier == kLocalDeviceIdentifier) {
          return _next(
            model.copyWith(
              transferState: TransferInProgress(
                targetDeviceId: kLocalDeviceIdentifier,
                phase: TransferPhase.transferring,
                source: source,
              ),
              clearLastError: true,
            ),
            <ConnectEffect>{
              PullPlaybackEffect(interactionId: interactionId),
            },
          );
        }

        final localConnectStateId = switch (model.selfDevice) {
          final self? => self.connectStateIdentifier,
          null => '',
        };
        return _next(
          model.copyWith(
            transferState: TransferInProgress(
              targetDeviceId: deviceIdentifier,
              phase: TransferPhase.transferring,
              source: source,
            ),
            clearLastError: true,
          ),
          <ConnectEffect>{
            TransferToDeviceEffect(
              deviceIdentifier: deviceIdentifier,
              localConnectStateIdentifier: localConnectStateId,
              source: source,
              interactionId: interactionId,
              dodo: dodo,
            ),
          },
        );
      }(),

    PullPlaybackRequested(:final source, :final interactionId) => _next(
        model.copyWith(
          transferState: TransferInProgress(
            targetDeviceId: kLocalDeviceIdentifier,
            phase: TransferPhase.transferring,
            source: source,
          ),
          clearLastError: true,
        ),
        <ConnectEffect>{
          PullPlaybackEffect(interactionId: interactionId),
        },
      ),

    LogoutDeviceRequested(:final deviceIdentifier) => _dispatch(
        <ConnectEffect>{
          LogoutDeviceEffect(deviceIdentifier: deviceIdentifier),
        },
      ),

    SetVolumeRequested(:final volume, :final interactionId) => _dispatch(
        <ConnectEffect>{
          SetVolumeEffect(volume: volume, interactionId: interactionId),
        },
      ),

    StepVolumeRequested(:final direction, :final interactionId) => _dispatch(
        <ConnectEffect>{
          StepVolumeEffect(direction: direction, interactionId: interactionId),
        },
      ),

    SetGroupVolumeRequested(
      :final groupDeviceIdentifier,
      :final volume,
      :final interactionId,
    ) =>
      _dispatch(
        <ConnectEffect>{
          SetGroupVolumeEffect(
            groupDeviceIdentifier: groupDeviceIdentifier,
            volume: volume,
            interactionId: interactionId,
          ),
        },
      ),

    StepGroupVolumeRequested(
      :final groupDeviceIdentifier,
      :final direction,
      :final interactionId,
    ) =>
      _dispatch(
        <ConnectEffect>{
          StepGroupVolumeEffect(
            groupDeviceIdentifier: groupDeviceIdentifier,
            direction: direction,
            interactionId: interactionId,
          ),
        },
      ),

    RefreshClusterRequested() => _dispatch(
        <ConnectEffect>{const RefreshClusterEffect()},
      ),

    WakeSleepingDevicesRequested() => _dispatch(
        <ConnectEffect>{const WakeSleepingDevicesEffect()},
      ),

    PerformDiscoveryRequested() => _dispatch(
        <ConnectEffect>{const PerformDiscoveryEffect()},
      ),

    AddDeviceToGroupRequested(
      :final deviceIdentifier,
      :final groupDeviceIdentifier,
      :final interactionId,
    ) =>
      _dispatch(
        <ConnectEffect>{
          AddDeviceToGroupEffect(
            deviceIdentifier: deviceIdentifier,
            groupDeviceIdentifier: groupDeviceIdentifier,
            interactionId: interactionId,
          ),
        },
      ),

    RemoveDeviceFromGroupRequested(
      :final deviceIdentifier,
      :final groupDeviceIdentifier,
      :final interactionId,
    ) =>
      _dispatch(
        <ConnectEffect>{
          RemoveDeviceFromGroupEffect(
            deviceIdentifier: deviceIdentifier,
            groupDeviceIdentifier: groupDeviceIdentifier,
            interactionId: interactionId,
          ),
        },
      ),

    DeleteGroupRequested(:final deviceIdentifier, :final interactionId) =>
      _dispatch(
        <ConnectEffect>{
          DeleteGroupEffect(
            deviceIdentifier: deviceIdentifier,
            interactionId: interactionId,
          ),
        },
      ),

    SetPreferredIncarnationRequested(
      :final deviceId,
      :final preferredLoginType,
      :final interactionId,
    ) =>
      _dispatch(
        <ConnectEffect>{
          SetPreferredIncarnationEffect(
            deviceId: deviceId,
            preferredLoginType: preferredLoginType,
            interactionId: interactionId,
          ),
        },
      ),

    NotifyAudioRouteChangedRequested(
      :final audioOutputDeviceName,
      :final connectionType,
      :final audioOutputDeviceBrand,
      :final audioOutputDeviceModel,
      :final category,
    ) =>
      _dispatch(
        <ConnectEffect>{
          NotifyAudioRouteChangedEffect(
            audioOutputDeviceName: audioOutputDeviceName,
            connectionType: connectionType,
            audioOutputDeviceBrand: audioOutputDeviceBrand,
            audioOutputDeviceModel: audioOutputDeviceModel,
            category: category,
          ),
        },
      ),

    InstallSpotifyRequested(
      :final deviceIdentifier,
      :final port,
      :final interactionId,
    ) =>
      _next(
        model.copyWith(
          installSpotifyDeviceId: deviceIdentifier,
          clearInstallSpotifyState: true,
          clearLastError: true,
        ),
        <ConnectEffect>{
          InstallSpotifyEffect(
            deviceIdentifier: deviceIdentifier,
            port: port,
            interactionId: interactionId,
          ),
        },
      ),

    SwitchToDodoRequested(:final csId) => _dispatch(
        <ConnectEffect>{SwitchToDodoEffect(csId: csId)},
      ),

    CreateNewDodoRequested() => _dispatch(
        <ConnectEffect>{const CreateNewDodoEffect()},
      ),

    EndDodoRequested() => _dispatch(
        <ConnectEffect>{const EndDodoEffect()},
      ),

    ClusterUpdateAfterBackendConnectionRequested() => _dispatch(
        <ConnectEffect>{const ClusterUpdateAfterBackendConnectionEffect()},
      ),

    DismissConnectErrorRequested() => _next(
        model.copyWith(clearLastError: true),
      ),

    // ------------------------------------------------------------------------
    // Effect Feedback Events
    // ------------------------------------------------------------------------
    TransferResultEvent(:final transferState) => switch (transferState) {
        TransferIdle() => _next(
            model.copyWith(transferState: transferState),
          ),
        TransferInProgress() => _next(
            model.copyWith(transferState: transferState),
          ),
        TransferSucceeded() => _next(
            model.copyWith(
              transferState: transferState,
              clearLastError: true,
            ),
          ),
        TransferFailed(
          :final targetDeviceId,
          :final reason,
          :final errorDescription,
          :final exception,
        ) =>
          _next(
            model.copyWith(
              transferState: transferState,
              lastError: ConnectFailure(
                kind: ConnectFailureKind.transfer,
                message: switch (errorDescription) {
                  final description? => description,
                  null => 'Playback transfer failed: ${reason.name}',
                },
                cause: exception,
                deviceIdentifier: targetDeviceId,
                transferFailureReason: reason,
              ),
            ),
          ),
      },

    PullResultEvent(:final status, :final failureReason, :final error) => () {
        final hasFailure = error != null ||
            failureReason != null ||
            status != common_pb.Status.OK;
        if (!hasFailure) {
          return _next(
            model.copyWith(
              transferState: TransferSucceeded(
                targetDeviceId: kLocalDeviceIdentifier,
              ),
              clearLastError: true,
            ),
          );
        }
        final resolvedReason = switch (failureReason) {
          final reason? => reason,
          null => TransferFailureReason.unknown,
        };
        final message = switch (error) {
          final err? => err.toString(),
          null => 'Pull playback failed: ${resolvedReason.name}',
        };
        return _next(
          model.copyWith(
            transferState: TransferFailed(
              targetDeviceId: kLocalDeviceIdentifier,
              reason: resolvedReason,
              errorDescription: error?.toString(),
              exception: error,
            ),
            lastError: ConnectFailure(
              kind: ConnectFailureKind.pull,
              message: message,
              cause: error,
              deviceIdentifier: kLocalDeviceIdentifier,
              transferFailureReason: resolvedReason,
              status: status,
            ),
          ),
        );
      }(),

    RecordDeviceConnectionResultEvent(
      :final deviceIdentifier,
      :final error,
    ) =>
      error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.recordConnection,
                  message: error.toString(),
                  cause: error,
                  deviceIdentifier: deviceIdentifier,
                ),
              ),
            ),

    LogoutResultEvent(:final deviceIdentifier, :final status, :final error) =>
      () {
        final hasFailure = error != null || status != common_pb.Status.OK;
        if (!hasFailure) {
          return _noChange();
        }
        final message = switch (error) {
          final err? => err.toString(),
          null => switch (status) {
              final st? => 'Logout failed with status ${st.name}',
              null => 'Logout failed',
            },
        };
        return _next(
          model.copyWith(
            lastError: ConnectFailure(
              kind: ConnectFailureKind.logout,
              message: message,
              cause: error,
              deviceIdentifier: deviceIdentifier,
              status: status,
            ),
          ),
        );
      }(),

    VolumeCommandResultEvent(
      :final groupDeviceIdentifier,
      :final status,
      :final error,
    ) =>
      () {
        final hasFailure = error != null || status != ConnectVolumeStatus.ok;
        if (!hasFailure) {
          return _noChange();
        }
        final message = switch (error) {
          final err? => err.toString(),
          null => switch (status) {
              final st? => 'Volume command failed: ${st.name}',
              null => 'Volume command failed',
            },
        };
        return _next(
          model.copyWith(
            lastError: ConnectFailure(
              kind: ConnectFailureKind.volumeCommand,
              message: message,
              cause: error,
              deviceIdentifier: groupDeviceIdentifier,
              volumeStatus: status,
            ),
          ),
        );
      }(),

    RefreshClusterResultEvent(:final succeeded, :final error) =>
      succeeded && error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.refreshCluster,
                  message: switch (error) {
                    final err? => err.toString(),
                    null => 'RefreshCluster failed',
                  },
                  cause: error,
                ),
              ),
            ),

    WakeSleepingDevicesResultEvent(:final succeeded, :final error) =>
      succeeded && error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.wakeDevices,
                  message: switch (error) {
                    final err? => err.toString(),
                    null => 'WakeSleepingClusterDevices failed',
                  },
                  cause: error,
                ),
              ),
            ),

    PerformDiscoveryResultEvent(:final succeeded, :final error) =>
      succeeded && error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.discovery,
                  message: switch (error) {
                    final err? => err.toString(),
                    null => 'PerformDiscovery failed',
                  },
                  cause: error,
                ),
              ),
            ),

    AddDeviceToGroupResultEvent(
      :final deviceIdentifier,
      :final success,
      :final groupError,
      :final error,
    ) =>
      success && error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.groupCommand,
                  message: switch (error) {
                    final err? => err.toString(),
                    null => switch (groupError) {
                        final ge? => 'AddDeviceToGroup failed: ${ge.name}',
                        null => 'AddDeviceToGroup failed',
                      },
                  },
                  cause: error,
                  deviceIdentifier: deviceIdentifier,
                  groupError: groupError,
                ),
              ),
            ),

    RemoveDeviceFromGroupResultEvent(
      :final deviceIdentifier,
      :final success,
      :final removeGroupError,
      :final error,
    ) =>
      success && error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.groupCommand,
                  message: switch (error) {
                    final err? => err.toString(),
                    null => switch (removeGroupError) {
                        final rge? =>
                          'RemoveDeviceFromGroup failed: ${rge.name}',
                        null => 'RemoveDeviceFromGroup failed',
                      },
                  },
                  cause: error,
                  deviceIdentifier: deviceIdentifier,
                  removeGroupError: removeGroupError,
                ),
              ),
            ),

    DeleteGroupResultEvent(
      :final deviceIdentifier,
      :final success,
      :final deleteGroupError,
      :final error,
    ) =>
      success && error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.groupCommand,
                  message: switch (error) {
                    final err? => err.toString(),
                    null => switch (deleteGroupError) {
                        final dge? => 'DeleteGroup failed: ${dge.name}',
                        null => 'DeleteGroup failed',
                      },
                  },
                  cause: error,
                  deviceIdentifier: deviceIdentifier,
                  deleteGroupError: deleteGroupError,
                ),
              ),
            ),

    SetPreferredIncarnationResultEvent(
      :final deviceId,
      :final status,
      :final error,
    ) =>
      () {
        final hasFailure = error != null || status != common_pb.Status.OK;
        if (!hasFailure) {
          return _noChange();
        }
        return _next(
          model.copyWith(
            lastError: ConnectFailure(
              kind: ConnectFailureKind.incarnation,
              message: switch (error) {
                final err? => err.toString(),
                null => switch (status) {
                    final st? =>
                      'SetPreferredIncarnation failed with status ${st.name}',
                    null => 'SetPreferredIncarnation failed',
                  },
              },
              cause: error,
              deviceIdentifier: deviceId,
              status: status,
            ),
          ),
        );
      }(),

    NotifyAudioRouteChangedResultEvent(:final succeeded, :final error) =>
      succeeded && error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.audioRoute,
                  message: switch (error) {
                    final err? => err.toString(),
                    null => 'NotifyAudioRouteChanged failed',
                  },
                  cause: error,
                ),
              ),
            ),

    InstallSpotifyProgressEvent(
      :final deviceIdentifier,
      :final installState,
      :final isTerminalSuccess,
      :final isTerminalFailure,
      :final error,
    ) =>
      () {
        if (isTerminalFailure || error != null) {
          final message = switch (error) {
            final err? => err.toString(),
            null => switch (installState) {
                final st? => 'InstallSpotify failed with state ${st.name}',
                null => 'InstallSpotify failed',
              },
          };
          return _next(
            model.copyWith(
              installSpotifyDeviceId: deviceIdentifier,
              installSpotifyState: installState,
              clearInstallSpotifyState: installState == null,
              lastError: ConnectFailure(
                kind: ConnectFailureKind.installSpotify,
                message: message,
                cause: error,
                deviceIdentifier: deviceIdentifier,
                installSpotifyState: installState,
              ),
            ),
          );
        }
        if (isTerminalSuccess) {
          return _next(
            model.copyWith(
              installSpotifyDeviceId: deviceIdentifier,
              installSpotifyState: installState,
              clearInstallSpotifyState: installState == null,
              clearLastError: true,
            ),
          );
        }
        return _next(
          model.copyWith(
            installSpotifyDeviceId: deviceIdentifier,
            installSpotifyState: installState,
            clearInstallSpotifyState: installState == null,
          ),
        );
      }(),

    DodoOperationResultEvent(:final operation, :final status, :final error) =>
      () {
        final hasFailure = error != null || status != common_pb.Status.OK;
        if (!hasFailure) {
          return _noChange();
        }
        return _next(
          model.copyWith(
            lastError: ConnectFailure(
              kind: ConnectFailureKind.dodoCommand,
              message: switch (error) {
                final err? => err.toString(),
                null => switch (status) {
                    final st? =>
                      'Dodo ${operation.name} failed with status ${st.name}',
                    null => 'Dodo ${operation.name} failed',
                  },
              },
              cause: error,
              status: status,
            ),
          ),
        );
      }(),

    ClusterUpdateAfterBackendConnectionResultEvent(:final error) =>
      error == null
          ? _noChange()
          : _next(
              model.copyWith(
                lastError: ConnectFailure(
                  kind: ConnectFailureKind.backendSync,
                  message: error.toString(),
                  cause: error,
                ),
              ),
            ),
  };
}
