import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_effect.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_effect_handler.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_event.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as empty_pb;

final class _RecordedRpc {
  final String service;
  final String method;
  final Uint8List payload;

  const _RecordedRpc({
    required this.service,
    required this.method,
    required this.payload,
  });
}

final class _FakeMobiusEsperantoTransport implements EsperantoTransport {
  final List<_RecordedRpc> singleCalls = <_RecordedRpc>[];
  final List<_RecordedRpc> streamCalls = <_RecordedRpc>[];

  Future<Uint8List> Function(String service, String method, Uint8List payload)?
      onCallSingle;
  Stream<Uint8List> Function(String service, String method, Uint8List payload)?
      onCallStream;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleCalls.add(
      _RecordedRpc(
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    final handler = onCallSingle;
    if (handler != null) {
      return handler(service, method, payload);
    }
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    streamCalls.add(
      _RecordedRpc(
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    final handler = onCallStream;
    if (handler != null) {
      return handler(service, method, payload);
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    return Uint8List(0);
  }
}

Uint8List _statusBytes(common_pb.Status status) {
  return Uint8List.fromList(common_pb.StatusResponse(status: status).writeToBuffer());
}

final class _HandlerHarness {
  final _FakeMobiusEsperantoTransport transport;
  final RemoteVolumeController volumeController;
  final DevicePickerSortingDatabase sortingDb;
  final List<ConnectEvent> intermediateEvents;
  final ConnectEffectHandler handler;

  _HandlerHarness({
    required this.transport,
    required this.volumeController,
    required this.sortingDb,
    required this.intermediateEvents,
    required this.handler,
  });
}

void main() {
  const fixedCommandId = '0123456789abcdef0123456789abcdef';

  _HandlerHarness? activeHarness;
  _HandlerHarness harness() {
    final current = activeHarness;
    if (current == null) {
      throw StateError('Handler harness accessed outside setUp/test');
    }
    return current;
  }

  setUp(() {
    final transport = _FakeMobiusEsperantoTransport();
    final connectClient = ConnectServiceClient(transport);
    final volumeClient = ConnectVolumeServiceClient(transport);
    final dodoClient = DodoServiceClient(transport);
    final volumeController = RemoteVolumeController(
      volumeClient: volumeClient,
      throttleWindow: Duration.zero,
      suppressionWindow: Duration.zero,
      localDebounceWindow: Duration.zero,
    );
    final sortingDb = DevicePickerSortingDatabase.forTesting(
      NativeDatabase.memory(),
      nowMsProvider: () => 1700000000000,
    );
    final intermediateEvents = <ConnectEvent>[];
    final handler = ConnectEffectHandler(
      connectServiceClient: connectClient,
      remoteVolumeController: volumeController,
      dodoServiceClient: dodoClient,
      sortingDatabase: sortingDb,
      onIntermediateEvent: intermediateEvents.add,
      commandIdGenerator: () => fixedCommandId,
    );
    activeHarness = _HandlerHarness(
      transport: transport,
      volumeController: volumeController,
      sortingDb: sortingDb,
      intermediateEvents: intermediateEvents,
      handler: handler,
    );
  });

  tearDown(() async {
    final current = activeHarness;
    activeHarness = null;
    if (current == null) {
      return;
    }
    await current.volumeController.dispose();
    await current.sortingDb.close();
  });

  group('ConnectEffectHandler (Item 157)', () {
    test('TransferToDeviceEffect for local_device skips recordConnection and invokes Pull', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      final sortingDb = h.sortingDb;
      transport.onCallSingle = (service, method, payload) async {
        expect(service, ConnectServiceClient.serviceName);
        expect(method, 'Pull');
        final req = connect_pb.PullRequest.fromBuffer(payload);
        expect(req.loggingParams.interactionIds, <String>['ui-pull']);
        return _statusBytes(common_pb.Status.OK);
      };

      final event = await handler.handleEffect(
        TransferToDeviceEffect(
          deviceIdentifier: kLocalDeviceIdentifier,
          localConnectStateIdentifier: 'self-1',
          interactionId: 'ui-pull',
        ),
      );

      expect(
        event,
        TransferResultEvent(
          TransferSucceeded(targetDeviceId: kLocalDeviceIdentifier),
        ),
      );
      expect(transport.singleCalls.map((c) => c.method), <String>['Pull']);
      expect(await sortingDb.getLastConnections(), isEmpty);
    });

    test('TransferToDeviceEffect for remote device records sorting DB and calls Transfer with commandId', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      final sortingDb = h.sortingDb;
      transport.onCallSingle = (service, method, payload) async {
        expect(service, ConnectServiceClient.serviceName);
        expect(method, 'Transfer');
        final req = connect_pb.TransferRequest.fromBuffer(payload);
        expect(req.connectDeviceIdentifier, 'remote-1');
        expect(req.dodo, isTrue);
        expect(req.loggingParams.commandId, fixedCommandId);
        expect(req.loggingParams.interactionIds, <String>['ui-tap']);
        return _statusBytes(common_pb.Status.OK);
      };

      final event = await handler.handleEffect(
        TransferToDeviceEffect(
          deviceIdentifier: 'remote-1',
          localConnectStateIdentifier: 'self-1',
          interactionId: 'ui-tap',
          dodo: true,
        ),
      );

      expect(
        event,
        TransferResultEvent(
          TransferSucceeded(
            targetDeviceId: 'remote-1',
            intentionId: fixedCommandId,
          ),
        ),
      );
      final rows = await sortingDb.getLastConnections();
      expect(rows, hasLength(1));
      expect(
        rows.single.deviceIdentifier,
        hashDeviceIdentifier(
          localConnectStateIdentifier: 'self-1',
          deviceIdentifier: 'remote-1',
        ),
      );
      expect(rows.single.timestamp, 1700000000000);
    });

    test('RecordDeviceConnectionEffect skips local_device and persists remote', () async {
      final h = harness();
      final handler = h.handler;
      final sortingDb = h.sortingDb;
      final skipped = await handler.handleEffect(
        RecordDeviceConnectionEffect(
          deviceIdentifier: kLocalDeviceIdentifier,
          localConnectStateIdentifier: 'self-1',
        ),
      );
      expect(
        skipped,
        const RecordDeviceConnectionResultEvent(
          deviceIdentifier: kLocalDeviceIdentifier,
          skippedLocalDevice: true,
        ),
      );
      expect(await sortingDb.getLastConnections(), isEmpty);

      final recorded = await handler.handleEffect(
        RecordDeviceConnectionEffect(
          deviceIdentifier: 'remote-2',
          localConnectStateIdentifier: 'self-1',
        ),
      );
      expect(
        recorded,
        const RecordDeviceConnectionResultEvent(
          deviceIdentifier: 'remote-2',
          skippedLocalDevice: false,
        ),
      );
      expect(await sortingDb.getLastConnections(), hasLength(1));
    });

    test('InstallSpotifyEffect forwards intermediate states and emits terminal success', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      final intermediateEvents = h.intermediateEvents;
      final streamController = StreamController<Uint8List>();
      addTearDown(streamController.close);

      transport.onCallStream = (service, method, payload) {
        expect(service, ConnectServiceClient.serviceName);
        expect(method, 'InstallSpotify');
        final req = connect_pb.InstallSpotifyRequest.fromBuffer(payload);
        expect(req.connectDeviceIdentifier, 'tv-1');
        expect(req.port, 0);
        return streamController.stream;
      };

      final future = handler.handleEffect(
        InstallSpotifyEffect(deviceIdentifier: 'tv-1'),
      );

      Uint8List statusUpdate(connect_pb.InstallSpotifyState st) {
        return Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(currentState: st).writeToBuffer(),
        );
      }

      streamController.add(statusUpdate(connect_pb.InstallSpotifyState.CONNECTING));
      streamController.add(statusUpdate(connect_pb.InstallSpotifyState.PAIRING));
      streamController.add(
        statusUpdate(connect_pb.InstallSpotifyState.LAUNCHING_THE_APP),
      );
      await pumpEventQueue();

      expect(
        intermediateEvents,
        const <ConnectEvent>[
          InstallSpotifyProgressEvent(
            deviceIdentifier: 'tv-1',
            installState: connect_pb.InstallSpotifyState.CONNECTING,
            isTerminalSuccess: false,
            isTerminalFailure: false,
          ),
          InstallSpotifyProgressEvent(
            deviceIdentifier: 'tv-1',
            installState: connect_pb.InstallSpotifyState.PAIRING,
            isTerminalSuccess: false,
            isTerminalFailure: false,
          ),
          InstallSpotifyProgressEvent(
            deviceIdentifier: 'tv-1',
            installState: connect_pb.InstallSpotifyState.LAUNCHING_THE_APP,
            isTerminalSuccess: false,
            isTerminalFailure: false,
          ),
        ],
      );

      streamController.add(statusUpdate(connect_pb.InstallSpotifyState.SUCCESS));
      final terminal = await future;
      expect(
        terminal,
        const InstallSpotifyProgressEvent(
          deviceIdentifier: 'tv-1',
          installState: connect_pb.InstallSpotifyState.SUCCESS,
          isTerminalSuccess: true,
          isTerminalFailure: false,
        ),
      );
    });

    test('InstallSpotifyEffect emits terminal failure on >= 100, early close, and exception', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      // 1) >= 100 error state
      transport.onCallStream = (service, method, payload) => Stream<Uint8List>.fromIterable(
            <Uint8List>[
              Uint8List.fromList(
                connect_pb.InstallSpotifyStatusUpdate(
                  currentState: connect_pb.InstallSpotifyState.TIMEOUT,
                ).writeToBuffer(),
              ),
            ],
          );
      final timeoutResult = await handler.handleEffect(
        InstallSpotifyEffect(deviceIdentifier: 'tv-1'),
      );
      expect(
        timeoutResult,
        const InstallSpotifyProgressEvent(
          deviceIdentifier: 'tv-1',
          installState: connect_pb.InstallSpotifyState.TIMEOUT,
          isTerminalSuccess: false,
          isTerminalFailure: true,
        ),
      );

      // 2) early close without terminal state
      transport.onCallStream =
          (service, method, payload) => const Stream<Uint8List>.empty();
      final earlyClose = await handler.handleEffect(
        InstallSpotifyEffect(deviceIdentifier: 'tv-1'),
      );
      expect(earlyClose, isA<InstallSpotifyProgressEvent>());
      if (earlyClose is InstallSpotifyProgressEvent) {
        expect(earlyClose.isTerminalFailure, isTrue);
        expect(earlyClose.isTerminalSuccess, isFalse);
        expect(earlyClose.error, isA<StateError>());
      }

      // 3) stream exception
      transport.onCallStream = (service, method, payload) =>
          Stream<Uint8List>.error(StateError('stream broken'));
      final streamErr = await handler.handleEffect(
        InstallSpotifyEffect(deviceIdentifier: 'tv-1'),
      );
      expect(streamErr, isA<InstallSpotifyProgressEvent>());
      if (streamErr is InstallSpotifyProgressEvent) {
        expect(streamErr.isTerminalFailure, isTrue);
        expect(streamErr.error, isA<StateError>());
      }
    });

    test('InstallSpotifyEffect canceled mid-stream completes with null without spurious failure and keeps handler reusable', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      final intermediateEvents = h.intermediateEvents;

      final firstController = StreamController<Uint8List>();
      var firstCanceled = false;
      firstController.onCancel = () {
        firstCanceled = true;
      };
      addTearDown(firstController.close);

      transport.onCallStream = (service, method, payload) {
        expect(service, ConnectServiceClient.serviceName);
        expect(method, 'InstallSpotify');
        return firstController.stream;
      };

      Uint8List statusUpdate(connect_pb.InstallSpotifyState st) {
        return Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(currentState: st).writeToBuffer(),
        );
      }

      final firstFuture = handler.handleEffect(
        InstallSpotifyEffect(deviceIdentifier: 'tv-1'),
      );

      firstController.add(statusUpdate(connect_pb.InstallSpotifyState.CONNECTING));
      await pumpEventQueue();
      expect(
        intermediateEvents,
        const <ConnectEvent>[
          InstallSpotifyProgressEvent(
            deviceIdentifier: 'tv-1',
            installState: connect_pb.InstallSpotifyState.CONNECTING,
            isTerminalSuccess: false,
            isTerminalFailure: false,
          ),
        ],
      );

      await handler.cancelActiveEffects();
      expect(firstCanceled, isTrue);
      expect(await firstFuture, isNull);

      firstController.add(statusUpdate(connect_pb.InstallSpotifyState.PAIRING));
      await firstController.close();
      await pumpEventQueue();
      expect(intermediateEvents, hasLength(1));

      // Handler remains reusable for subsequent InstallSpotify sessions
      final secondController = StreamController<Uint8List>();
      addTearDown(secondController.close);
      transport.onCallStream = (service, method, payload) {
        return secondController.stream;
      };

      final secondFuture = handler.handleEffect(
        InstallSpotifyEffect(deviceIdentifier: 'tv-2'),
      );
      secondController.add(statusUpdate(connect_pb.InstallSpotifyState.SUCCESS));
      expect(
        await secondFuture,
        const InstallSpotifyProgressEvent(
          deviceIdentifier: 'tv-2',
          installState: connect_pb.InstallSpotifyState.SUCCESS,
          isTerminalSuccess: true,
          isTerminalFailure: false,
        ),
      );
    });

    test('handles volume, group, logout, incarnation, audio route, discovery, refresh, wake, dodo, backendSync', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      transport.onCallSingle = (service, method, payload) async {
        if (method == 'VolumeSet' ||
            method == 'VolumeUp' ||
            method == 'VolumeDown') {
          return _statusBytes(common_pb.Status.OK);
        }
        if (method == 'AddDeviceToGroup') {
          return Uint8List.fromList(
            connect_pb.AddDeviceToGroupResponse(
              success: false,
              error: connect_pb.GroupError.BUSY,
            ).writeToBuffer(),
          );
        }
        if (method == 'RemoveDeviceFromGroup') {
          return Uint8List.fromList(
            connect_pb.RemoveDeviceFromGroupResponse(
              success: true,
            ).writeToBuffer(),
          );
        }
        if (method == 'DeleteGroup') {
          return Uint8List.fromList(
            connect_pb.DeleteGroupResponse(
              success: false,
              error: connect_pb.DeleteGroupError.DELETE_TARGET_NOT_FOUND,
            ).writeToBuffer(),
          );
        }
        if (method == 'ClusterUpdateAfterBackendConnection') {
          return Uint8List.fromList(
            connect_pb.ClusterUpdateAfterBackendConnectionResponse(
              hasReceivedClusterUpdateAfterBackendConnection: true,
            ).writeToBuffer(),
          );
        }
        if (method == 'RefreshCluster' ||
            method == 'WakeSleepingClusterDevices' ||
            method == 'PerformDiscovery' ||
            method == 'NotifyAudioRouteChanged') {
          return Uint8List.fromList(empty_pb.Empty().writeToBuffer());
        }
        return _statusBytes(common_pb.Status.OK);
      };

      expect(
        await handler.handleEffect(SetVolumeEffect(volume: 0.6)),
        const VolumeCommandResultEvent(status: ConnectVolumeStatus.ok),
      );
      expect(
        await handler.handleEffect(StepVolumeEffect(direction: 1)),
        const VolumeCommandResultEvent(status: ConnectVolumeStatus.ok),
      );
      expect(
        await handler.handleEffect(
          SetGroupVolumeEffect(groupDeviceIdentifier: 'grp-1', volume: 0.4),
        ),
        const VolumeCommandResultEvent(
          groupDeviceIdentifier: 'grp-1',
          status: ConnectVolumeStatus.ok,
        ),
      );
      expect(
        await handler.handleEffect(
          StepGroupVolumeEffect(groupDeviceIdentifier: 'grp-1', direction: -1),
        ),
        const VolumeCommandResultEvent(
          groupDeviceIdentifier: 'grp-1',
          status: ConnectVolumeStatus.ok,
        ),
      );
      expect(
        await handler.handleEffect(LogoutDeviceEffect(deviceIdentifier: 'r-1')),
        const LogoutResultEvent(
          deviceIdentifier: 'r-1',
          status: common_pb.Status.OK,
        ),
      );
      expect(
        await handler.handleEffect(
          SetPreferredIncarnationEffect(
            deviceId: 'r-1',
            preferredLoginType: IncarnationLoginType.connect,
          ),
        ),
        const SetPreferredIncarnationResultEvent(
          deviceId: 'r-1',
          status: common_pb.Status.OK,
        ),
      );
      expect(
        await handler.handleEffect(
          const NotifyAudioRouteChangedEffect(
            audioOutputDeviceName: 'Wired',
            connectionType: OutputPeripheralConnectionType.wired,
          ),
        ),
        const NotifyAudioRouteChangedResultEvent(succeeded: true),
      );
      expect(
        await handler.handleEffect(const RefreshClusterEffect()),
        const RefreshClusterResultEvent(succeeded: true),
      );
      expect(
        await handler.handleEffect(const WakeSleepingDevicesEffect()),
        const WakeSleepingDevicesResultEvent(succeeded: true),
      );
      expect(
        await handler.handleEffect(const PerformDiscoveryEffect()),
        const PerformDiscoveryResultEvent(succeeded: true),
      );
      expect(
        await handler.handleEffect(
          AddDeviceToGroupEffect(
            deviceIdentifier: 'd-1',
            groupDeviceIdentifier: 'g-1',
          ),
        ),
        const AddDeviceToGroupResultEvent(
          deviceIdentifier: 'd-1',
          groupDeviceIdentifier: 'g-1',
          success: false,
          groupError: connect_pb.GroupError.BUSY,
        ),
      );
      expect(
        await handler.handleEffect(
          RemoveDeviceFromGroupEffect(
            deviceIdentifier: 'd-1',
            groupDeviceIdentifier: 'g-1',
          ),
        ),
        const RemoveDeviceFromGroupResultEvent(
          deviceIdentifier: 'd-1',
          groupDeviceIdentifier: 'g-1',
          success: true,
        ),
      );
      expect(
        await handler.handleEffect(DeleteGroupEffect(deviceIdentifier: 'g-1')),
        const DeleteGroupResultEvent(
          deviceIdentifier: 'g-1',
          success: false,
          deleteGroupError: connect_pb.DeleteGroupError.DELETE_TARGET_NOT_FOUND,
        ),
      );
      expect(
        await handler.handleEffect(const SwitchToDodoEffect(csId: 'cs-1')),
        const DodoOperationResultEvent(
          operation: DodoOperationType.switchToDodo,
          status: common_pb.Status.OK,
        ),
      );
      expect(
        await handler.handleEffect(const CreateNewDodoEffect()),
        const DodoOperationResultEvent(
          operation: DodoOperationType.createNewDodo,
          status: common_pb.Status.OK,
        ),
      );
      expect(
        await handler.handleEffect(const EndDodoEffect()),
        const DodoOperationResultEvent(
          operation: DodoOperationType.endDodo,
          status: common_pb.Status.OK,
        ),
      );
      expect(
        await handler.handleEffect(
          const ClusterUpdateAfterBackendConnectionEffect(),
        ),
        const ClusterUpdateAfterBackendConnectionResultEvent(
          hasReceivedClusterUpdate: true,
        ),
      );
    });

    test('maps transport exceptions to typed error events without swallowing', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      transport.onCallSingle = (service, method, payload) async {
        throw StateError('rpc failed: $method');
      };

      final transferErr = await handler.handleEffect(
        TransferToDeviceEffect(deviceIdentifier: 'remote-1'),
      );
      expect(transferErr, isA<TransferResultEvent>());
      if (transferErr is TransferResultEvent) {
        expect(transferErr.transferState, isA<TransferFailed>());
      }

      final pullErr = await handler.handleEffect(const PullPlaybackEffect());
      expect(pullErr, isA<PullResultEvent>());
      if (pullErr is PullResultEvent) {
        expect(pullErr.failureReason, TransferFailureReason.transportError);
        expect(pullErr.error, isA<StateError>());
      }

      final refreshErr =
          await handler.handleEffect(const RefreshClusterEffect());
      expect(refreshErr, isA<RefreshClusterResultEvent>());
      if (refreshErr is RefreshClusterResultEvent) {
        expect(refreshErr.succeeded, isFalse);
        expect(refreshErr.error, isA<StateError>());
      }

      final dodoErr = await handler.handleEffect(const CreateNewDodoEffect());
      expect(dodoErr, isA<DodoOperationResultEvent>());
      if (dodoErr is DodoOperationResultEvent) {
        expect(dodoErr.error, isA<StateError>());
      }

      final renameErr = await handler.handleEffect(
        RenameDeviceEffect(deviceIdentifier: 'spk-1', newName: 'Studio'),
      );
      expect(renameErr, isA<RenameDeviceResultEvent>());
      if (renameErr is RenameDeviceResultEvent) {
        expect(renameErr.deviceIdentifier, equals('spk-1'));
        expect(renameErr.error, isA<StateError>());
      }

      final sendCmdErr = await handler.handleEffect(
        SendPlayerCommandEffect(
          deviceIdentifier: 'spk-1',
          commandJson: '{"endpoint":"pause"}',
        ),
      );
      expect(sendCmdErr, isA<SendPlayerCommandResultEvent>());
      if (sendCmdErr is SendPlayerCommandResultEvent) {
        expect(sendCmdErr.deviceIdentifier, equals('spk-1'));
        expect(sendCmdErr.error, isA<StateError>());
      }
    });

    test('handles RenameDeviceEffect and SendPlayerCommandEffect with exact ConnectService proto payloads', () async {
      final h = harness();
      final transport = h.transport;
      final handler = h.handler;
      connect_pb.RenameRequest? capturedRename;
      connect_pb.SendCommandRequest? capturedSendCmd;

      transport.onCallSingle = (service, method, payload) async {
        expect(service, ConnectServiceClient.serviceName);
        if (method == 'Rename') {
          capturedRename = connect_pb.RenameRequest.fromBuffer(payload);
          return _statusBytes(common_pb.Status.OK);
        }
        if (method == 'SendCommand') {
          capturedSendCmd = connect_pb.SendCommandRequest.fromBuffer(payload);
          return Uint8List.fromList(
            connect_pb.SendCommandResponse(contextPlayerError: 0)
                .writeToBuffer(),
          );
        }
        return Uint8List(0);
      };

      final renameEvent = await handler.handleEffect(
        RenameDeviceEffect(
          deviceIdentifier: 'spk-42',
          newName: 'Bedroom Sonos',
          interactionId: 'ren-42',
        ),
      );
      expect(
        renameEvent,
        const RenameDeviceResultEvent(
          deviceIdentifier: 'spk-42',
          status: common_pb.Status.OK,
        ),
      );
      expect(capturedRename?.deviceId, equals('spk-42'));
      expect(capturedRename?.newName, equals('Bedroom Sonos'));

      final cmdEvent = await handler.handleEffect(
        SendPlayerCommandEffect(
          deviceIdentifier: 'spk-42',
          commandJson: '{"endpoint":"resume"}',
          interactionId: 'cmd-42',
        ),
      );
      expect(
        cmdEvent,
        const SendPlayerCommandResultEvent(
          deviceIdentifier: 'spk-42',
          contextPlayerError: 0,
        ),
      );
      expect(capturedSendCmd?.connectDeviceIdentifier, equals('spk-42'));
      expect(capturedSendCmd?.commandJson, equals('{"endpoint":"resume"}'));
      expect(
        capturedSendCmd?.loggingParams.interactionIds,
        equals(<String>['cmd-42']),
      );
      expect(
        capturedSendCmd?.loggingParams.commandId,
        equals(fixedCommandId),
      );
    });
  });
}
