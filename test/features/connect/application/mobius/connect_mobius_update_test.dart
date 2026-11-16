import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_effect.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_event.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_update.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pbenum.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart'
    as dodos_pb;
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

ConnectDevice _makeDevice({
  required String id,
  required String name,
  bool isSelf = false,
  bool isActive = false,
  bool isLocal = false,
  String localIdentifier = '',
}) {
  return ConnectDevice(
    isSelf: isSelf,
    isActive: isActive,
    isBeingActivated: false,
    isWebapp: false,
    isZeroconf: false,
    isGroup: false,
    isSocialConnect: false,
    supportsLogout: !isSelf,
    supportsVolume: true,
    supportsRename: false,
    creationTimeMs: 0,
    brandDisplayName: 'Brand',
    modelDisplayName: 'Model',
    localIdentifier: localIdentifier,
    connectStateIdentifier: id,
    name: name,
    state: ConnectDeviceState.loggedIn,
    type: isSelf ? DeviceType.smartphone : DeviceType.speaker,
    incarnations: const <Incarnation>[],
    volume: 32768,
    isNewlyDiscovered: false,
    isDisabled: false,
    capabilities: const <ConnectCapabilityEntry>[],
    hifi: const ConnectHifiStatus(
      fullySupported: false,
      userEligible: false,
      deviceSupported: false,
    ),
    volumeSteps: 64,
    isVoiceEnabled: false,
    isLocal: isLocal,
    localIp: '',
    supportedMediaTypes: const <String>['audio'],
    supportsDj: false,
    libraryVersion: '1.0.0',
    supportsRemoteSleepTimer: false,
    supportsPlaylistMixing: false,
    supportsZephyr: false,
    supportsRemoteAudioQualityControl: false,
    discoveryMethod: 0,
  );
}

void main() {
  group('connectMobiusUpdate (Item 158 — pure transition determinism)', () {
    test('ClusterStateUpdatedEvent (g6k) updates internal and projected fields with zero effects', () {
      final self = _makeDevice(
        id: 'self-id',
        name: 'This Phone',
        isSelf: true,
      );
      final remoteA = _makeDevice(
        id: 'remote-a',
        name: 'Zulu Speaker',
        isActive: true,
      );
      final remoteB = _makeDevice(
        id: 'remote-b',
        name: 'Alpha Speaker',
      );
      final cluster = ConnectCluster(
        isActive: true,
        shouldUseLocalPlayback: false,
        devices: <ConnectDevice>[remoteA, remoteB, self],
        isActiveOnSameDevice: false,
        isSyncedWithBackend: true,
      );

      final next = connectMobiusUpdate(
        ConnectState.initial(),
        ClusterStateUpdatedEvent(cluster),
      );

      expect(next.hasEffects, isFalse);
      expect(next.hasModel, isTrue);
      final model = next.model;
      expect(model, isNotNull);
      if (model == null) return;

      expect(model.isSyncedWithBackend, isTrue);
      expect(model.internal.isSyncedWithBackend, isTrue);
      expect(model.internal.rawDevices, <ConnectDevice>[remoteA, remoteB, self]);
      // devices preserves raw cluster order (yrq.m95027j)
      expect(model.devices, <ConnectDevice>[remoteA, remoteB, self]);
      // sortedDevices applies 4-stage DeviceSortingComparator (self first, then name ASC)
      expect(model.sortedDevices, <ConnectDevice>[self, remoteB, remoteA]);
      expect(model.activeDevice, remoteA);
      expect(model.activeRemoteDevice, remoteA);
      expect(model.selfDevice, self);
      expect(model.selfPeripherals, isEmpty);
      expect(model.activeSelfPeripheral, isNull);
    });

    test('PeripheralsUpdatedEvent (f6k) projects gtg case 17 built_in_speaker and sorting', () {
      final self = _makeDevice(id: 'self-id', name: 'Phone', isSelf: true);
      final cluster = ConnectCluster(
        isActive: true,
        shouldUseLocalPlayback: true,
        devices: <ConnectDevice>[self],
        isActiveOnSameDevice: true,
        isSyncedWithBackend: true,
      );
      final afterCluster = connectMobiusUpdate(
        ConnectState.initial(),
        ClusterStateUpdatedEvent(cluster),
      ).model;
      expect(afterCluster, isNotNull);
      if (afterCluster == null) return;

      // Case A: inactive peripherals -> built_in_speaker injected & activated first
      final btInactive = LocalAudioPeripheral(
        id: 'bt-1',
        name: 'Headphones',
        isActive: false,
        connectionType: OutputPeripheralConnectionType.bluetooth,
      );
      final nextA = connectMobiusUpdate(
        afterCluster,
        PeripheralsUpdatedEvent(<LocalAudioPeripheral>[btInactive]),
      );
      expect(nextA.hasEffects, isFalse);
      final modelA = nextA.model;
      expect(modelA, isNotNull);
      if (modelA == null) return;
      expect(modelA.selfPeripherals.length, 2);
      expect(modelA.activeSelfPeripheral?.id, kBuiltInSpeakerPeripheralId);
      expect(modelA.activeSelfPeripheral?.isActive, isTrue);

      // Case B: active carProjected & existing built_in_speaker -> carProjected active first, built_in_speaker deactivated
      final carActive = LocalAudioPeripheral(
        id: 'car-1',
        name: 'Android Auto',
        isActive: true,
        connectionType: OutputPeripheralConnectionType.carProjected,
        isConnected: true,
      );
      final builtInActive = LocalAudioPeripheral(
        id: kBuiltInSpeakerPeripheralId,
        name: kBuiltInSpeakerPeripheralId,
        isActive: true,
        connectionType: OutputPeripheralConnectionType.builtInSpeaker,
      );
      final nextB = connectMobiusUpdate(
        modelA,
        PeripheralsUpdatedEvent(<LocalAudioPeripheral>[
          builtInActive,
          carActive,
        ]),
      );
      final modelB = nextB.model;
      expect(modelB, isNotNull);
      if (modelB == null) return;
      expect(modelB.selfPeripherals.first.id, 'car-1');
      expect(modelB.selfPeripherals.first.isActive, isTrue);
      expect(modelB.selfPeripherals.last.id, kBuiltInSpeakerPeripheralId);
      expect(modelB.selfPeripherals.last.isActive, isFalse);
    });

    test('RecommendedLocalDevicesUpdatedEvent (h6k) and SortingTimestampsUpdatedEvent update projection', () {
      final self = _makeDevice(id: 'self-id', name: 'Phone', isSelf: true);
      final remoteA = _makeDevice(
        id: 'remote-a',
        name: 'Alpha',
        localIdentifier: 'local-a',
      );
      final remoteB = _makeDevice(
        id: 'remote-b',
        name: 'Beta',
        localIdentifier: 'local-b',
      );
      final cluster = ConnectCluster(
        isActive: false,
        shouldUseLocalPlayback: false,
        devices: <ConnectDevice>[self, remoteA, remoteB],
        isActiveOnSameDevice: false,
        isSyncedWithBackend: true,
      );
      final seeded = connectMobiusUpdate(
        ConnectState.initial(),
        ClusterStateUpdatedEvent(cluster),
      ).model;
      expect(seeded, isNotNull);
      if (seeded == null) return;

      final afterRec = connectMobiusUpdate(
        seeded,
        RecommendedLocalDevicesUpdatedEvent(const <String>['local-b']),
      );
      expect(afterRec.hasEffects, isFalse);
      final recModel = afterRec.model;
      expect(recModel, isNotNull);
      if (recModel == null) return;
      expect(recModel.isRecommendedLocalDevice('local-b'), isTrue);
      expect(recModel.isRecommendedLocalDevice('local-a'), isFalse);

      final hashedBeta = hashDeviceIdentifier(
        localConnectStateIdentifier: 'self-id',
        deviceIdentifier: 'remote-b',
      );
      final afterTimestamps = connectMobiusUpdate(
        recModel,
        SortingTimestampsUpdatedEvent(<String, int>{hashedBeta: 5000}),
      );
      expect(afterTimestamps.hasEffects, isFalse);
      final sortedModel = afterTimestamps.model;
      expect(sortedModel, isNotNull);
      if (sortedModel == null) return;
      expect(sortedModel.devices, <ConnectDevice>[self, remoteA, remoteB]);
      expect(sortedModel.sortedDevices, <ConnectDevice>[self, remoteB, remoteA]);
    });

    test('VolumeStateUpdatedEvent, DodoSubUpdatedEvent, and ConnectStreamErrorEvent update state', () {
      final volumeState = ConnectVolumeState(
        remoteVolume: 0.42,
        outputMode: VolumeOutputMode.remote,
      );
      final dodo = dodos_pb.SingleDodo(
        dodoId: 'dodo-1',
        csId: 'cs-1',
        isPrimary: true,
        isBeingObserved: true,
      )..freeze();
      const failure = ConnectFailure(
        kind: ConnectFailureKind.clusterStream,
        message: 'stream failure',
      );

      final afterVol = connectMobiusUpdate(
        ConnectState.initial(),
        VolumeStateUpdatedEvent(volumeState),
      ).model;
      expect(afterVol?.volumeState, volumeState);
      if (afterVol == null) {
        fail('Expected VolumeStateUpdatedEvent to produce a new model');
      }

      final afterDodo = connectMobiusUpdate(
        afterVol,
        DodoSubUpdatedEvent(<dodos_pb.SingleDodo>[dodo]),
      ).model;
      expect(afterDodo?.dodos, <dodos_pb.SingleDodo>[dodo]);
      if (afterDodo == null) {
        fail('Expected DodoSubUpdatedEvent to produce a new model');
      }

      final afterErr = connectMobiusUpdate(
        afterDodo,
        const ConnectStreamErrorEvent(failure),
      ).model;
      expect(afterErr?.lastError, failure);
      expect(afterErr?.hasError, isTrue);
      if (afterErr == null) {
        fail('Expected ConnectStreamErrorEvent to produce a new model');
      }

      final dismissed = connectMobiusUpdate(
        afterErr,
        const DismissConnectErrorRequested(),
      );
      expect(dismissed.hasEffects, isFalse);
      expect(dismissed.model?.lastError, isNull);
    });

    test('TransferToDeviceRequested enforces local_device vs remote device branching', () {
      final self = _makeDevice(id: 'self-cs-id', name: 'Phone', isSelf: true);
      final remote = _makeDevice(id: 'remote-1', name: 'Speaker');
      final cluster = ConnectCluster(
        isActive: false,
        shouldUseLocalPlayback: false,
        devices: <ConnectDevice>[self, remote],
        isActiveOnSameDevice: false,
        isSyncedWithBackend: true,
      );
      final stateWithError = connectMobiusUpdate(
        ConnectState.initial(),
        ClusterStateUpdatedEvent(cluster),
      ).model?.copyWith(
        lastError: const ConnectFailure(
          kind: ConnectFailureKind.transfer,
          message: 'stale error',
        ),
      );
      expect(stateWithError, isNotNull);
      if (stateWithError == null) return;

      // 'local_device' -> PullPlaybackEffect ONLY, never TransferToDeviceEffect / RecordDeviceConnectionEffect
      final localNext = connectMobiusUpdate(
        stateWithError,
        TransferToDeviceRequested(
          deviceIdentifier: kLocalDeviceIdentifier,
          source: TransferSource.googleOutputSwitcher,
          interactionId: 'int-1',
        ),
      );
      expect(localNext.model?.lastError, isNull);
      expect(
        localNext.model?.transferState,
        TransferInProgress(
          targetDeviceId: kLocalDeviceIdentifier,
          phase: TransferPhase.transferring,
          source: TransferSource.googleOutputSwitcher,
        ),
      );
      expect(
        localNext.effects,
        <ConnectEffect>{
          const PullPlaybackEffect(interactionId: 'int-1'),
        },
      );

      // Remote device -> TransferToDeviceEffect with self connectStateIdentifier
      final remoteNext = connectMobiusUpdate(
        stateWithError,
        TransferToDeviceRequested(
          deviceIdentifier: 'remote-1',
          source: TransferSource.inApp,
          interactionId: 'int-2',
          dodo: true,
        ),
      );
      expect(remoteNext.model?.lastError, isNull);
      expect(
        remoteNext.model?.transferState,
        TransferInProgress(
          targetDeviceId: 'remote-1',
          phase: TransferPhase.transferring,
          source: TransferSource.inApp,
        ),
      );
      expect(
        remoteNext.effects,
        <ConnectEffect>{
          TransferToDeviceEffect(
            deviceIdentifier: 'remote-1',
            localConnectStateIdentifier: 'self-cs-id',
            source: TransferSource.inApp,
            interactionId: 'int-2',
            dodo: true,
          ),
        },
      );
    });

    test('all remaining user command intents emit exact expected effects', () {
      final base = ConnectState.initial();

      final pullNext = connectMobiusUpdate(
        base,
        const PullPlaybackRequested(
          source: TransferSource.inApp,
          interactionId: 'pull-1',
        ),
      );
      expect(
        pullNext.effects,
        <ConnectEffect>{const PullPlaybackEffect(interactionId: 'pull-1')},
      );
      expect(pullNext.model?.isTransferring, isTrue);

      expect(
        connectMobiusUpdate(
          base,
          LogoutDeviceRequested(deviceIdentifier: 'dev-1'),
        ).effects,
        <ConnectEffect>{LogoutDeviceEffect(deviceIdentifier: 'dev-1')},
      );

      expect(
        connectMobiusUpdate(
          base,
          SetVolumeRequested(volume: 0.75, interactionId: 'v-1'),
        ).effects,
        <ConnectEffect>{SetVolumeEffect(volume: 0.75, interactionId: 'v-1')},
      );

      expect(
        connectMobiusUpdate(
          base,
          StepVolumeRequested(direction: 1, interactionId: 'v-2'),
        ).effects,
        <ConnectEffect>{StepVolumeEffect(direction: 1, interactionId: 'v-2')},
      );

      expect(
        connectMobiusUpdate(
          base,
          SetGroupVolumeRequested(
            groupDeviceIdentifier: 'grp-1',
            volume: 0.5,
            interactionId: 'gv-1',
          ),
        ).effects,
        <ConnectEffect>{
          SetGroupVolumeEffect(
            groupDeviceIdentifier: 'grp-1',
            volume: 0.5,
            interactionId: 'gv-1',
          ),
        },
      );

      expect(
        connectMobiusUpdate(
          base,
          StepGroupVolumeRequested(
            groupDeviceIdentifier: 'grp-1',
            direction: -1,
            interactionId: 'gv-2',
          ),
        ).effects,
        <ConnectEffect>{
          StepGroupVolumeEffect(
            groupDeviceIdentifier: 'grp-1',
            direction: -1,
            interactionId: 'gv-2',
          ),
        },
      );

      expect(
        connectMobiusUpdate(base, const RefreshClusterRequested()).effects,
        <ConnectEffect>{const RefreshClusterEffect()},
      );

      expect(
        connectMobiusUpdate(base, const WakeSleepingDevicesRequested()).effects,
        <ConnectEffect>{const WakeSleepingDevicesEffect()},
      );

      expect(
        connectMobiusUpdate(base, const PerformDiscoveryRequested()).effects,
        <ConnectEffect>{const PerformDiscoveryEffect()},
      );

      expect(
        connectMobiusUpdate(
          base,
          AddDeviceToGroupRequested(
            deviceIdentifier: 'd1',
            groupDeviceIdentifier: 'g1',
            interactionId: 'add-1',
          ),
        ).effects,
        <ConnectEffect>{
          AddDeviceToGroupEffect(
            deviceIdentifier: 'd1',
            groupDeviceIdentifier: 'g1',
            interactionId: 'add-1',
          ),
        },
      );

      expect(
        connectMobiusUpdate(
          base,
          RemoveDeviceFromGroupRequested(
            deviceIdentifier: 'd1',
            groupDeviceIdentifier: 'g1',
            interactionId: 'rem-1',
          ),
        ).effects,
        <ConnectEffect>{
          RemoveDeviceFromGroupEffect(
            deviceIdentifier: 'd1',
            groupDeviceIdentifier: 'g1',
            interactionId: 'rem-1',
          ),
        },
      );

      expect(
        connectMobiusUpdate(
          base,
          DeleteGroupRequested(deviceIdentifier: 'g1', interactionId: 'del-1'),
        ).effects,
        <ConnectEffect>{
          DeleteGroupEffect(deviceIdentifier: 'g1', interactionId: 'del-1'),
        },
      );

      expect(
        connectMobiusUpdate(
          base,
          SetPreferredIncarnationRequested(
            deviceId: 'dev-1',
            preferredLoginType: IncarnationLoginType.cast,
            interactionId: 'inc-1',
          ),
        ).effects,
        <ConnectEffect>{
          SetPreferredIncarnationEffect(
            deviceId: 'dev-1',
            preferredLoginType: IncarnationLoginType.cast,
            interactionId: 'inc-1',
          ),
        },
      );

      expect(
        connectMobiusUpdate(
          base,
          const NotifyAudioRouteChangedRequested(
            audioOutputDeviceName: 'Pixel Buds',
            connectionType: OutputPeripheralConnectionType.bluetooth,
            audioOutputDeviceBrand: 'Google',
            audioOutputDeviceModel: 'Pro',
            category: OutputPeripheralCategory.headphones,
          ),
        ).effects,
        <ConnectEffect>{
          const NotifyAudioRouteChangedEffect(
            audioOutputDeviceName: 'Pixel Buds',
            connectionType: OutputPeripheralConnectionType.bluetooth,
            audioOutputDeviceBrand: 'Google',
            audioOutputDeviceModel: 'Pro',
            category: OutputPeripheralCategory.headphones,
          ),
        },
      );

      final installNext = connectMobiusUpdate(
        base,
        InstallSpotifyRequested(
          deviceIdentifier: 'tv-1',
          port: 8080,
          interactionId: 'inst-1',
        ),
      );
      expect(installNext.model?.installSpotifyDeviceId, 'tv-1');
      expect(installNext.model?.installSpotifyState, isNull);
      expect(
        installNext.effects,
        <ConnectEffect>{
          InstallSpotifyEffect(
            deviceIdentifier: 'tv-1',
            port: 8080,
            interactionId: 'inst-1',
          ),
        },
      );

      expect(
        connectMobiusUpdate(
          base,
          const SwitchToDodoRequested(csId: 'cs-9'),
        ).effects,
        <ConnectEffect>{const SwitchToDodoEffect(csId: 'cs-9')},
      );

      expect(
        connectMobiusUpdate(base, const CreateNewDodoRequested()).effects,
        <ConnectEffect>{const CreateNewDodoEffect()},
      );

      expect(
        connectMobiusUpdate(base, const EndDodoRequested()).effects,
        <ConnectEffect>{const EndDodoEffect()},
      );

      expect(
        connectMobiusUpdate(
          base,
          const ClusterUpdateAfterBackendConnectionRequested(),
        ).effects,
        <ConnectEffect>{const ClusterUpdateAfterBackendConnectionEffect()},
      );
    });

    test('effect feedback events update transfer, install, and typed errors', () {
      final base = ConnectState.initial();

      // TransferResultEvent succeeded & failed
      final trSuccess = connectMobiusUpdate(
        base,
        TransferResultEvent(TransferSucceeded(targetDeviceId: 'r1')),
      );
      expect(trSuccess.model?.transferState, TransferSucceeded(targetDeviceId: 'r1'));
      expect(trSuccess.model?.lastError, isNull);

      final trFail = connectMobiusUpdate(
        base,
        TransferResultEvent(
          TransferFailed(
            targetDeviceId: 'r1',
            reason: TransferFailureReason.notFound,
          ),
        ),
      );
      expect(trFail.model?.lastError?.kind, ConnectFailureKind.transfer);
      expect(
        trFail.model?.lastError?.transferFailureReason,
        TransferFailureReason.notFound,
      );

      // PullResultEvent OK vs failure
      final pullOk = connectMobiusUpdate(
        base,
        const PullResultEvent(status: common_pb.Status.OK),
      );
      expect(
        pullOk.model?.transferState,
        TransferSucceeded(targetDeviceId: kLocalDeviceIdentifier),
      );
      expect(pullOk.model?.lastError, isNull);

      final pullFail = connectMobiusUpdate(
        base,
        const PullResultEvent(
          status: common_pb.Status.BACKEND_FAILURE,
          failureReason: TransferFailureReason.backendFailure,
        ),
      );
      expect(pullFail.model?.lastError?.kind, ConnectFailureKind.pull);
      expect(
        pullFail.model?.transferState,
        isA<TransferFailed>(),
      );

      final pullNullStatus = connectMobiusUpdate(
        base,
        const PullResultEvent(),
      );
      expect(
        pullNullStatus.model?.transferState,
        TransferFailed(
          targetDeviceId: kLocalDeviceIdentifier,
          reason: TransferFailureReason.unknown,
        ),
      );
      expect(
        pullNullStatus.model?.lastError?.kind,
        ConnectFailureKind.pull,
      );
      expect(
        pullNullStatus.model?.lastError?.transferFailureReason,
        TransferFailureReason.unknown,
      );
      expect(pullNullStatus.model?.lastError?.status, isNull);

      // RecordDeviceConnectionResultEvent
      expect(
        connectMobiusUpdate(
          base,
          const RecordDeviceConnectionResultEvent(
            deviceIdentifier: 'local_device',
            skippedLocalDevice: true,
          ),
        ).hasModel,
        isFalse,
      );
      expect(
        connectMobiusUpdate(
          base,
          RecordDeviceConnectionResultEvent(
            deviceIdentifier: 'r1',
            skippedLocalDevice: false,
            error: StateError('db closed'),
          ),
        ).model?.lastError?.kind,
        ConnectFailureKind.recordConnection,
      );

      // LogoutResultEvent
      expect(
        connectMobiusUpdate(
          base,
          const LogoutResultEvent(
            deviceIdentifier: 'r1',
            status: common_pb.Status.OK,
          ),
        ).hasModel,
        isFalse,
      );
      expect(
        connectMobiusUpdate(
          base,
          const LogoutResultEvent(
            deviceIdentifier: 'r1',
            status: common_pb.Status.NOT_FOUND,
          ),
        ).model?.lastError?.kind,
        ConnectFailureKind.logout,
      );

      // VolumeCommandResultEvent
      expect(
        connectMobiusUpdate(
          base,
          const VolumeCommandResultEvent(status: ConnectVolumeStatus.ok),
        ).hasModel,
        isFalse,
      );
      expect(
        connectMobiusUpdate(
          base,
          const VolumeCommandResultEvent(
            groupDeviceIdentifier: 'g1',
            status: ConnectVolumeStatus.backendFailure,
          ),
        ).model?.lastError?.kind,
        ConnectFailureKind.volumeCommand,
      );

      // Refresh / Wake / Discovery / AudioRoute / BackendSync
      expect(
        connectMobiusUpdate(
          base,
          const RefreshClusterResultEvent(succeeded: true),
        ).hasModel,
        isFalse,
      );
      expect(
        connectMobiusUpdate(
          base,
          const RefreshClusterResultEvent(succeeded: false),
        ).model?.lastError?.kind,
        ConnectFailureKind.refreshCluster,
      );

      expect(
        connectMobiusUpdate(
          base,
          const WakeSleepingDevicesResultEvent(succeeded: false),
        ).model?.lastError?.kind,
        ConnectFailureKind.wakeDevices,
      );

      expect(
        connectMobiusUpdate(
          base,
          const PerformDiscoveryResultEvent(succeeded: false),
        ).model?.lastError?.kind,
        ConnectFailureKind.discovery,
      );

      expect(
        connectMobiusUpdate(
          base,
          const NotifyAudioRouteChangedResultEvent(succeeded: false),
        ).model?.lastError?.kind,
        ConnectFailureKind.audioRoute,
      );

      expect(
        connectMobiusUpdate(
          base,
          const ClusterUpdateAfterBackendConnectionResultEvent(
            hasReceivedClusterUpdate: true,
          ),
        ).hasModel,
        isFalse,
      );
      expect(
        connectMobiusUpdate(
          base,
          ClusterUpdateAfterBackendConnectionResultEvent(
            error: StateError('timeout'),
          ),
        ).model?.lastError?.kind,
        ConnectFailureKind.backendSync,
      );

      // Group operations
      expect(
        connectMobiusUpdate(
          base,
          const AddDeviceToGroupResultEvent(
            deviceIdentifier: 'd1',
            groupDeviceIdentifier: 'g1',
            success: false,
            groupError: connect_pb.GroupError.MAX_NUMBER_OF_DEVICES_REACHED,
          ),
        ).model?.lastError?.groupError,
        connect_pb.GroupError.MAX_NUMBER_OF_DEVICES_REACHED,
      );
      expect(
        connectMobiusUpdate(
          base,
          const RemoveDeviceFromGroupResultEvent(
            deviceIdentifier: 'd1',
            groupDeviceIdentifier: 'g1',
            success: false,
            removeGroupError:
                connect_pb.RemoveGroupError.REMOVE_TARGET_NOT_FOUND,
          ),
        ).model?.lastError?.removeGroupError,
        connect_pb.RemoveGroupError.REMOVE_TARGET_NOT_FOUND,
      );
      expect(
        connectMobiusUpdate(
          base,
          const DeleteGroupResultEvent(
            deviceIdentifier: 'g1',
            success: false,
            deleteGroupError: connect_pb.DeleteGroupError.DELETE_BUSY,
          ),
        ).model?.lastError?.deleteGroupError,
        connect_pb.DeleteGroupError.DELETE_BUSY,
      );

      // Incarnation & Dodo
      expect(
        connectMobiusUpdate(
          base,
          const SetPreferredIncarnationResultEvent(
            deviceId: 'd1',
            status: common_pb.Status.INVALID_ARGUMENTS,
          ),
        ).model?.lastError?.kind,
        ConnectFailureKind.incarnation,
      );
      expect(
        connectMobiusUpdate(
          base,
          const DodoOperationResultEvent(
            operation: DodoOperationType.switchToDodo,
            status: common_pb.Status.NOT_FOUND,
          ),
        ).model?.lastError?.kind,
        ConnectFailureKind.dodoCommand,
      );

      // InstallSpotifyProgressEvent intermediate, terminal failure, terminal success
      final instMid = connectMobiusUpdate(
        base,
        const InstallSpotifyProgressEvent(
          deviceIdentifier: 'tv-1',
          installState: connect_pb.InstallSpotifyState.PAIRING,
          isTerminalSuccess: false,
          isTerminalFailure: false,
        ),
      );
      expect(
        instMid.model?.installSpotifyState,
        connect_pb.InstallSpotifyState.PAIRING,
      );
      expect(instMid.model?.lastError, isNull);
      final instMidModel = instMid.model;
      if (instMidModel == null) {
        fail('Expected InstallSpotifyProgressEvent intermediate model');
      }

      final instFail = connectMobiusUpdate(
        instMidModel,
        const InstallSpotifyProgressEvent(
          deviceIdentifier: 'tv-1',
          installState: connect_pb.InstallSpotifyState.TIMEOUT,
          isTerminalSuccess: false,
          isTerminalFailure: true,
        ),
      );
      expect(
        instFail.model?.lastError?.kind,
        ConnectFailureKind.installSpotify,
      );
      expect(
        instFail.model?.lastError?.installSpotifyState,
        connect_pb.InstallSpotifyState.TIMEOUT,
      );
      final instFailModel = instFail.model;
      if (instFailModel == null) {
        fail('Expected InstallSpotifyProgressEvent failure model');
      }

      final instSuccess = connectMobiusUpdate(
        instFailModel,
        const InstallSpotifyProgressEvent(
          deviceIdentifier: 'tv-1',
          installState: connect_pb.InstallSpotifyState.SUCCESS,
          isTerminalSuccess: true,
          isTerminalFailure: false,
        ),
      );
      expect(
        instSuccess.model?.installSpotifyState,
        connect_pb.InstallSpotifyState.SUCCESS,
      );
      expect(instSuccess.model?.lastError, isNull);
    });

    test('event and effect constructors enforce strict input invariants', () {
      expect(
        () => TransferToDeviceRequested(deviceIdentifier: '   '),
        throwsArgumentError,
      );
      expect(
        () => SetVolumeRequested(volume: 1.5),
        throwsRangeError,
      );
      expect(
        () => StepVolumeRequested(direction: 0),
        throwsArgumentError,
      );
      expect(
        () => InstallSpotifyRequested(deviceIdentifier: 'tv-1', port: -1),
        throwsRangeError,
      );
      expect(
        () => LocalAudioPeripheral(
          id: ' ',
          name: 'bad',
          isActive: false,
          connectionType: OutputPeripheralConnectionType.unknown,
        ),
        throwsArgumentError,
      );
    });
  });
}
