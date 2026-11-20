import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart'
    as dodos_pb;
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

final class _ControllerFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> installStreamController =
      StreamController<Uint8List>.broadcast();

  final List<String> singleMethods = <String>[];
  connect_pb.StateRequest? lastStateRequest;
  Future<Uint8List> Function(String service, String method, Uint8List payload)?
      onCallSingle;
  Stream<Uint8List> Function(Uint8List payload)? onInstallSpotify;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleMethods.add(method);
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
    if (service == ConnectServiceClient.serviceName && method == 'State') {
      lastStateRequest = connect_pb.StateRequest.fromBuffer(payload);
      return stateStreamController.stream;
    }
    if (service == ConnectServiceClient.serviceName &&
        method == 'InstallSpotify') {
      final handler = onInstallSpotify;
      if (handler != null) {
        return handler(payload);
      }
      return installStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'Volume') {
      return volumeStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'LocalVolume') {
      return localVolumeStreamController.stream;
    }
    if (service == DodoServiceClient.serviceName && method == 'DodoSub') {
      return dodoStreamController.stream;
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    return Uint8List(0);
  }

  Future<void> close() async {
    await stateStreamController.close();
    await volumeStreamController.close();
    await localVolumeStreamController.close();
    await dodoStreamController.close();
    await installStreamController.close();
  }
}

Uint8List _encodeCluster({
  required bool isSyncedWithBackend,
  required List<connect_pb.StateResponse_Device> devices,
}) {
  return Uint8List.fromList(
    connect_pb.StateResponse(
      isActive: devices.any((d) => d.isActive),
      isSyncedWithBackend: isSyncedWithBackend,
      devices: devices,
    ).writeToBuffer(),
  );
}

connect_pb.StateResponse_Device _protoDevice({
  required String id,
  required String name,
  bool isSelf = false,
  bool isActive = false,
  bool isLocal = false,
}) {
  return connect_pb.StateResponse_Device(
    isSelf: isSelf,
    isActive: isActive,
    isLocal: isLocal,
    connectStateIdentifier: id,
    localIdentifier: 'local-$id',
    name: name,
    state: 'LOGGED_IN',
    type: isSelf ? 'SMARTPHONE' : 'SPEAKER',
    volume: 32768,
    volumeSteps: 64,
    supportsVolume: true,
    capabilities: '[]',
  );
}

final class _ControllerHarness {
  final _ControllerFakeTransport transport;
  final DevicePickerSortingDatabase sortingDb;
  final StreamController<List<LocalAudioPeripheral>> peripheralsController;
  final StreamController<List<String>> recommendedController;
  final RemoteVolumeController volumeController;
  final ConnectMobiusController controller;

  _ControllerHarness({
    required this.transport,
    required this.sortingDb,
    required this.peripheralsController,
    required this.recommendedController,
    required this.volumeController,
    required this.controller,
  });
}

void main() {
  _ControllerHarness? activeHarness;
  _ControllerHarness harness() {
    final current = activeHarness;
    if (current == null) {
      throw StateError('Test harness accessed outside setUp/test');
    }
    return current;
  }

  _ControllerFakeTransport getTransport() => harness().transport;
  DevicePickerSortingDatabase getSortingDb() => harness().sortingDb;
  StreamController<List<LocalAudioPeripheral>> getPeripheralsController() =>
      harness().peripheralsController;
  ConnectMobiusController getController() => harness().controller;

  setUp(() {
    var fakeTimeMs = 1000;
    final transport = _ControllerFakeTransport();
    final sortingDb = DevicePickerSortingDatabase.forTesting(
      NativeDatabase.memory(),
      nowMsProvider: () {
        fakeTimeMs += 1000;
        return fakeTimeMs;
      },
    );
    final peripheralsController =
        StreamController<List<LocalAudioPeripheral>>.broadcast();
    final recommendedController = StreamController<List<String>>.broadcast();
    final volumeClient = ConnectVolumeServiceClient(transport);
    final volumeController = RemoteVolumeController(
      volumeClient: volumeClient,
      throttleWindow: Duration.zero,
      suppressionWindow: Duration.zero,
      localDebounceWindow: Duration.zero,
    );
    final controller = ConnectMobiusController(
      connectServiceClient: ConnectServiceClient(transport),
      volumeServiceClient: volumeClient,
      dodoServiceClient: DodoServiceClient(transport),
      sortingDatabase: sortingDb,
      remoteVolumeController: volumeController,
      peripheralsStream: peripheralsController.stream,
      recommendedLocalDeviceIdsStream: recommendedController.stream,
      commandIdGenerator: () => 'abcdef0123456789abcdef0123456789',
    );
    activeHarness = _ControllerHarness(
      transport: transport,
      sortingDb: sortingDb,
      peripheralsController: peripheralsController,
      recommendedController: recommendedController,
      volumeController: volumeController,
      controller: controller,
    );
  });

  tearDown(() async {
    final current = activeHarness;
    activeHarness = null;
    if (current == null) {
      return;
    }
    await current.controller.close();
    await current.volumeController.dispose();
    await current.peripheralsController.close();
    await current.recommendedController.close();
    await current.sortingDb.close();
    await current.transport.close();
  });

  group('ConnectMobiusController (Item 153)', () {
    test('exposes ValueListenable/StateStreamableSource and replay-1 stream before and after start', () async {
      final controller = getController();
      expect(controller, isA<ValueListenable<ConnectState>>());
      expect(controller.isStarted, isFalse);
      expect(controller.state, ConnectState.initial());
      expect(controller.value, ConnectState.initial());

      final replayFirst = await controller.stream.first;
      expect(replayFirst, ConnectState.initial());

      controller.start();
      expect(controller.isStarted, isTrue);

      final lateSnapshot = await controller.stream.first;
      expect(lateSnapshot, controller.state);
    });

    test('buffers pre-start dispatch events (csq parity) and flushes FIFO on start()', () async {
      final transport = getTransport();
      final controller = getController();
      transport.onCallSingle = (service, method, payload) async {
        return Uint8List(0);
      };

      controller.dispatch(const RefreshClusterRequested());
      controller.dispatch(const WakeSleepingDevicesRequested());
      expect(transport.singleMethods, isEmpty);

      controller.start();
      await pumpEventQueue();

      expect(
        transport.singleMethods,
        <String>['RefreshCluster', 'WakeSleepingClusterDevices'],
      );
    });

    test('devicesStream preserves cluster order while sortedDevicesStream applies sorting DB', () async {
      final transport = getTransport();
      final sortingDb = getSortingDb();
      final controller = getController();
      controller.start();
      await pumpEventQueue();

      final clusterLists = <List<String>>[];
      final sortedLists = <List<String>>[];
      final activeIds = <String?>[];
      final selfIds = <String?>[];
      final syncedValues = <bool>[];

      final subDevices = controller.devicesStream.listen(
        (list) => clusterLists.add(list.map((d) => d.name).toList()),
      );
      final subSorted = controller.sortedDevicesStream.listen(
        (list) => sortedLists.add(list.map((d) => d.name).toList()),
      );
      final subActive = controller.activeDeviceStream.listen(
        (device) => activeIds.add(device?.connectStateIdentifier),
      );
      final subSelf = controller.selfDeviceStream.listen(
        (device) => selfIds.add(device?.connectStateIdentifier),
      );
      final subSync = controller.isSyncedWithBackendStream.listen(
        syncedValues.add,
      );
      addTearDown(() async {
        await subDevices.cancel();
        await subSorted.cancel();
        await subActive.cancel();
        await subSelf.cancel();
        await subSync.cancel();
      });

      transport.stateStreamController.add(
        _encodeCluster(
          isSyncedWithBackend: true,
          devices: <connect_pb.StateResponse_Device>[
            _protoDevice(id: 'remote-z', name: 'Zulu', isActive: true),
            _protoDevice(id: 'remote-a', name: 'Alpha'),
            _protoDevice(id: 'self-id', name: 'Phone', isSelf: true),
          ],
        ),
      );
      await pumpEventQueue();

      // Cluster order preserved on devices / devicesStream
      expect(
        clusterLists.last,
        <String>['Zulu', 'Alpha', 'Phone'],
      );
      // Sorted order: self first, then alphabetical (Alpha before Zulu)
      expect(
        sortedLists.last,
        <String>['Phone', 'Alpha', 'Zulu'],
      );
      expect(activeIds.last, 'remote-z');
      expect(selfIds.last, 'self-id');
      expect(syncedValues.last, isTrue);

      // Recording connection to 'remote-z' moves Zulu ahead of Alpha in sortedDevicesStream
      // while devicesStream stays in raw cluster order.
      await sortingDb.recordConnection(
        deviceIdentifier: 'remote-z',
        localConnectStateIdentifier: 'self-id',
      );
      await pumpEventQueue();

      expect(
        controller.devices.map((d) => d.name).toList(),
        <String>['Zulu', 'Alpha', 'Phone'],
      );
      expect(
        sortedLists.last,
        <String>['Phone', 'Zulu', 'Alpha'],
      );
    });

    test('stop() resets exposed snapshot while retaining internal v6k snapshot across restart', () async {
      final transport = getTransport();
      final peripheralsController = getPeripheralsController();
      final controller = getController();
      var notifyCount = 0;
      controller.addListener(() {
        notifyCount += 1;
      });
      controller.start();
      await pumpEventQueue();

      transport.stateStreamController.add(
        _encodeCluster(
          isSyncedWithBackend: true,
          devices: <connect_pb.StateResponse_Device>[
            _protoDevice(id: 'self-id', name: 'Phone', isSelf: true),
            _protoDevice(id: 'remote-1', name: 'Speaker', isActive: true),
          ],
        ),
      );
      peripheralsController.add(<LocalAudioPeripheral>[
        LocalAudioPeripheral(
          id: 'bt-1',
          name: 'Headphones',
          isActive: true,
          connectionType: OutputPeripheralConnectionType.bluetooth,
        ),
      ]);
      await pumpEventQueue();

      expect(controller.devices, hasLength(2));
      expect(controller.isSyncedWithBackend, isTrue);
      expect(controller.state.activeSelfPeripheral?.id, 'bt-1');
      final notificationsBeforeStop = notifyCount;

      await controller.stop();
      expect(controller.isStarted, isFalse);
      expect(controller.devices, isEmpty);
      expect(controller.activeDevice, isNull);
      expect(controller.selfDevice, isNull);
      expect(controller.isSyncedWithBackend, isFalse);
      expect(notifyCount, greaterThan(notificationsBeforeStop));

      // Restart restores cached v6k snapshot immediately before any new stream push
      controller.start();
      expect(controller.isStarted, isTrue);
      expect(controller.devices, hasLength(2));
      expect(controller.activeDevice?.connectStateIdentifier, 'remote-1');
      expect(controller.selfDevice?.connectStateIdentifier, 'self-id');
      expect(controller.isSyncedWithBackend, isTrue);
      expect(controller.state.activeSelfPeripheral?.id, 'bt-1');
    });

    test('forwards InstallSpotify intermediate and terminal events end-to-end', () async {
      final transport = getTransport();
      final controller = getController();
      controller.start();
      await pumpEventQueue();

      final observedInstallStates = <connect_pb.InstallSpotifyState?>[];
      final sub = controller.stream.listen((state) {
        observedInstallStates.add(state.installSpotifyState);
      });
      addTearDown(sub.cancel);

      controller.dispatch(
        InstallSpotifyRequested(deviceIdentifier: 'tv-1'),
      );
      await pumpEventQueue();

      transport.installStreamController.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.CONNECTING,
          ).writeToBuffer(),
        ),
      );
      transport.installStreamController.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.LAUNCHING_APP_STORE,
          ).writeToBuffer(),
        ),
      );
      transport.installStreamController.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.SUCCESS,
          ).writeToBuffer(),
        ),
      );
      await pumpEventQueue();

      expect(
        observedInstallStates,
        containsAllInOrder(<connect_pb.InstallSpotifyState?>[
          connect_pb.InstallSpotifyState.CONNECTING,
          connect_pb.InstallSpotifyState.LAUNCHING_APP_STORE,
          connect_pb.InstallSpotifyState.SUCCESS,
        ]),
      );
      expect(controller.state.lastError, isNull);
    });

    test('explicit onError handlers propagate upstream stream errors into state.lastError with zero uncaught errors', () async {
      final h = harness();
      final transport = h.transport;
      final peripheralsController = h.peripheralsController;
      final recommendedController = h.recommendedController;
      final controller = h.controller;
      await runZonedGuarded(() async {
        controller.start();
        await pumpEventQueue();

        transport.stateStreamController.addError(
          StateError('cluster stream failure'),
        );
        await pumpEventQueue();
        expect(controller.state.lastError?.kind, ConnectFailureKind.clusterStream);

        peripheralsController.addError(StateError('peripheral stream failure'));
        await pumpEventQueue();
        expect(
          controller.state.lastError?.kind,
          ConnectFailureKind.peripheralStream,
        );

        recommendedController.addError(StateError('recommended failure'));
        await pumpEventQueue();
        expect(
          controller.state.lastError?.kind,
          ConnectFailureKind.recommendedDevicesStream,
        );

        transport.dodoStreamController.addError(StateError('dodo stream failure'));
        await pumpEventQueue();
        expect(controller.state.lastError?.kind, ConnectFailureKind.dodoStream);

        // Dodo updates still work cleanly on non-error events
        transport.dodoStreamController.add(
          Uint8List.fromList(
            dodos_pb.DodoSubResponse(
              dodos: <dodos_pb.SingleDodo>[
                dodos_pb.SingleDodo(dodoId: 'd-1', csId: 'cs-1'),
              ],
            ).writeToBuffer(),
          ),
        );
        await pumpEventQueue();
        expect(controller.state.dodos, hasLength(1));
      }, (error, stack) {
        fail('Unexpected uncaught error escaped ConnectMobiusController: $error');
      });
    });

    test('transfer to local_device via controller executes Pull and never writes sorting DB', () async {
      final transport = getTransport();
      final sortingDb = getSortingDb();
      final controller = getController();
      transport.onCallSingle = (service, method, payload) async {
        return Uint8List.fromList(
          common_pb.StatusResponse(status: common_pb.Status.OK).writeToBuffer(),
        );
      };

      controller.start();
      await pumpEventQueue();

      controller.dispatch(
        TransferToDeviceRequested(deviceIdentifier: kLocalDeviceIdentifier),
      );
      await pumpEventQueue();

      expect(transport.singleMethods, <String>['Pull']);
      expect(
        controller.state.transferState,
        TransferSucceeded(targetDeviceId: kLocalDeviceIdentifier),
      );
      expect(await sortingDb.getLastConnections(), isEmpty);
    });

    test('throws StateError when start() is called after close()', () async {
      final controller = getController();
      await controller.close();
      expect(controller.isClosed, isTrue);
      expect(() => controller.start(), throwsStateError);
    });

    test('rapid unawaited stop() followed immediately by start() preserves restored v6k state and active subscriptions', () async {
      final h = harness();
      final transport = h.transport;
      final controller = h.controller;
      controller.start();
      await pumpEventQueue();

      transport.stateStreamController.add(
        _encodeCluster(
          isSyncedWithBackend: true,
          devices: <connect_pb.StateResponse_Device>[
            _protoDevice(id: 'self-1', name: 'Phone', isSelf: true),
            _protoDevice(id: 'spk-1', name: 'Speaker', isActive: true),
          ],
        ),
      );
      await pumpEventQueue();
      expect(controller.devices, hasLength(2));
      expect(
        h.volumeController.state.activeDevice?.connectStateIdentifier,
        'spk-1',
      );

      final observed = <ConnectState>[];
      final sub = controller.stream.listen(observed.add);
      addTearDown(sub.cancel);

      final stopFuture = controller.stop();
      controller.start();
      await stopFuture;
      await pumpEventQueue();

      expect(controller.isStarted, isTrue);
      expect(controller.devices, hasLength(2));
      expect(controller.activeDevice?.connectStateIdentifier, 'spk-1');
      expect(controller.selfDevice?.connectStateIdentifier, 'self-1');
      expect(controller.isSyncedWithBackend, isTrue);
      expect(controller.value, controller.state);
      expect(observed.last.devices, hasLength(2));
      expect(await controller.stream.first, controller.state);
      expect(
        h.volumeController.state.activeDevice?.connectStateIdentifier,
        'spk-1',
      );

      // Post-restart cluster updates continue flowing normally
      transport.stateStreamController.add(
        _encodeCluster(
          isSyncedWithBackend: true,
          devices: <connect_pb.StateResponse_Device>[
            _protoDevice(id: 'self-1', name: 'Phone', isSelf: true),
            _protoDevice(id: 'spk-1', name: 'Speaker', isActive: true),
            _protoDevice(id: 'spk-2', name: 'Kitchen'),
          ],
        ),
      );
      await pumpEventQueue();
      expect(controller.devices, hasLength(3));

      // Also verify slow-cancelling upstream subscription does not clobber restart
      final slowCancelCompleter = Completer<void>();
      var firstSlowCancel = true;
      final slowTransport = _ControllerFakeTransport();
      final slowSortingDb = DevicePickerSortingDatabase.forTesting(
        NativeDatabase.memory(),
      );
      final slowPeripheralsStream = Stream<List<LocalAudioPeripheral>>.multi(
        (streamController) {
          streamController.onCancel = () {
            if (firstSlowCancel) {
              firstSlowCancel = false;
              return slowCancelCompleter.future;
            }
            return null;
          };
        },
        isBroadcast: true,
      );
      final slowVolumeClient = ConnectVolumeServiceClient(slowTransport);
      final slowVolumeController = RemoteVolumeController(
        volumeClient: slowVolumeClient,
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      final slowController = ConnectMobiusController(
        connectServiceClient: ConnectServiceClient(slowTransport),
        volumeServiceClient: slowVolumeClient,
        dodoServiceClient: DodoServiceClient(slowTransport),
        sortingDatabase: slowSortingDb,
        remoteVolumeController: slowVolumeController,
        peripheralsStream: slowPeripheralsStream,
      );
      addTearDown(() async {
        if (!slowCancelCompleter.isCompleted) {
          slowCancelCompleter.complete();
        }
        await slowController.close();
        await slowVolumeController.dispose();
        await slowSortingDb.close();
        await slowTransport.close();
      });

      slowController.start();
      await pumpEventQueue();
      slowTransport.stateStreamController.add(
        _encodeCluster(
          isSyncedWithBackend: true,
          devices: <connect_pb.StateResponse_Device>[
            _protoDevice(id: 'self-slow', name: 'Phone', isSelf: true),
            _protoDevice(id: 'spk-slow', name: 'Living Room', isActive: true),
          ],
        ),
      );
      await pumpEventQueue();
      expect(slowController.devices, hasLength(2));

      final slowStopFuture = slowController.stop();
      slowController.start();
      await pumpEventQueue();
      slowCancelCompleter.complete();
      await slowStopFuture;
      await pumpEventQueue();

      expect(slowController.isStarted, isTrue);
      expect(slowController.devices, hasLength(2));
      expect(
        slowController.activeDevice?.connectStateIdentifier,
        'spk-slow',
      );
      expect(
        slowVolumeController.state.activeDevice?.connectStateIdentifier,
        'spk-slow',
      );
    });

    test('InstallSpotify interrupted by stop() or close() cancels subscription and does not leak stale progress across restart', () async {
      final h = harness();
      final transport = h.transport;
      final controller = h.controller;

      final session1Stream = StreamController<Uint8List>();
      var session1Canceled = false;
      session1Stream.onCancel = () {
        session1Canceled = true;
      };
      addTearDown(session1Stream.close);
      transport.onInstallSpotify = (payload) => session1Stream.stream;

      controller.start();
      await pumpEventQueue();

      controller.dispatch(InstallSpotifyRequested(deviceIdentifier: 'tv-9'));
      await pumpEventQueue();

      session1Stream.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.CONNECTING,
          ).writeToBuffer(),
        ),
      );
      await pumpEventQueue();
      expect(
        controller.state.installSpotifyState,
        connect_pb.InstallSpotifyState.CONNECTING,
      );

      await controller.stop();
      expect(session1Canceled, isTrue);

      session1Stream.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.PAIRING,
          ).writeToBuffer(),
        ),
      );
      await session1Stream.close();
      await pumpEventQueue();

      controller.start();
      await pumpEventQueue();
      expect(controller.state.installSpotifyState, isNull);
      expect(controller.state.installSpotifyDeviceId, isNull);
      expect(controller.state.lastError, isNull);

      // Also verify close() cancels active InstallSpotify session cleanly
      final session2Stream = StreamController<Uint8List>();
      var session2Canceled = false;
      session2Stream.onCancel = () {
        session2Canceled = true;
      };
      addTearDown(session2Stream.close);
      transport.onInstallSpotify = (payload) => session2Stream.stream;

      controller.dispatch(InstallSpotifyRequested(deviceIdentifier: 'tv-10'));
      await pumpEventQueue();
      session2Stream.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.CONNECTING,
          ).writeToBuffer(),
        ),
      );
      await pumpEventQueue();

      await controller.close();
      expect(session2Canceled, isTrue);
      await session2Stream.close();
    });

    test('late single-shot effect completion after stop() or close() is dropped by disposed MobiusLoop and never enters _pendingEvents', () async {
      final h = harness();
      final transport = h.transport;
      final controller = h.controller;
      final transferCompleter = Completer<Uint8List>();

      transport.onCallSingle = (service, method, payload) {
        if (method == 'Transfer') {
          return transferCompleter.future;
        }
        return Future<Uint8List>.value(Uint8List(0));
      };

      controller.start();
      await pumpEventQueue();

      controller.dispatch(
        TransferToDeviceRequested(deviceIdentifier: 'remote-1'),
      );
      await pumpEventQueue();

      await controller.stop();

      transferCompleter.complete(
        Uint8List.fromList(
          common_pb.StatusResponse(
            status: common_pb.Status.BACKEND_FAILURE,
          ).writeToBuffer(),
        ),
      );
      await pumpEventQueue();

      controller.start();
      await pumpEventQueue();
      expect(controller.state.transferState, const TransferIdle());
      expect(controller.state.lastError, isNull);
    });

    test('syncs RemoteVolumeController activeDevice including stop() reset, handles SetVolumeRequested end-to-end, and propagates volumeStream and sortingStream errors', () async {
      final h = harness();
      final transport = h.transport;
      final controller = h.controller;

      await runZonedGuarded(() async {
        controller.start();
        await pumpEventQueue();

        // 1) Active device sync: null -> remote -> stop() resets to null -> start() restores
        transport.stateStreamController.add(
          _encodeCluster(
            isSyncedWithBackend: true,
            devices: <connect_pb.StateResponse_Device>[
              _protoDevice(id: 'self-1', name: 'Phone', isSelf: true),
              _protoDevice(id: 'spk-1', name: 'Speaker', isActive: true),
            ],
          ),
        );
        await pumpEventQueue();

        expect(
          h.volumeController.state.activeDevice?.connectStateIdentifier,
          'spk-1',
        );
        expect(
          controller.state.volumeState.activeDevice?.connectStateIdentifier,
          'spk-1',
        );
        expect(controller.state.volumeState.outputMode, VolumeOutputMode.remote);

        await controller.stop();
        expect(h.volumeController.state.activeDevice, isNull);
        expect(h.volumeController.state.outputMode, VolumeOutputMode.local);

        controller.start();
        await pumpEventQueue();
        expect(
          h.volumeController.state.activeDevice?.connectStateIdentifier,
          'spk-1',
        );
        expect(
          controller.state.volumeState.activeDevice?.connectStateIdentifier,
          'spk-1',
        );

        // 2) SetVolumeRequested success
        volume_pb.VolumeSetRequest? capturedRequest;
        transport.onCallSingle = (service, method, payload) async {
          if (service == ConnectVolumeServiceClient.serviceName &&
              method == 'VolumeSet') {
            capturedRequest = volume_pb.VolumeSetRequest.fromBuffer(payload);
            return Uint8List.fromList(
              common_pb.StatusResponse(status: common_pb.Status.OK)
                  .writeToBuffer(),
            );
          }
          return Uint8List(0);
        };

        controller.dispatch(
          SetVolumeRequested(volume: 0.65, interactionId: 'vol-1'),
        );
        await pumpEventQueue();

        expect(capturedRequest, isNotNull);
        expect(capturedRequest?.volume, (0.65 * 65535).round());
        expect(
          capturedRequest?.loggingParams.interactionIds,
          <String>['vol-1'],
        );
        expect(controller.state.volumeState.remoteVolume, closeTo(0.65, 1e-6));
        expect(controller.state.lastError, isNull);

        // 3) SetVolumeRequested BACKEND_FAILURE -> ConnectFailureKind.volumeCommand
        transport.onCallSingle = (service, method, payload) async {
          return Uint8List.fromList(
            common_pb.StatusResponse(status: common_pb.Status.BACKEND_FAILURE)
                .writeToBuffer(),
          );
        };
        controller.dispatch(SetVolumeRequested(volume: 0.30));
        await pumpEventQueue();
        expect(
          controller.state.lastError?.kind,
          ConnectFailureKind.volumeCommand,
        );

        // 4) Empty cluster resets activeDevice to null
        transport.stateStreamController.add(
          _encodeCluster(
            isSyncedWithBackend: true,
            devices: const <connect_pb.StateResponse_Device>[],
          ),
        );
        await pumpEventQueue();
        expect(h.volumeController.state.activeDevice, isNull);
        expect(controller.state.volumeState.activeDevice, isNull);

        // 5) volumeStream error -> ConnectVolumeStatus.backendFailure
        transport.volumeStreamController.addError(
          StateError('vol stream failed'),
        );
        await pumpEventQueue();
        expect(
          controller.state.volumeState.status,
          ConnectVolumeStatus.backendFailure,
        );

        // 6) sortingStream SQLite query error -> ConnectFailureKind.sortingStream
        final failingSortingTransport = _ControllerFakeTransport();
        final failingSortingDb = DevicePickerSortingDatabase.forTesting(
          NativeDatabase.memory(),
        );
        await failingSortingDb.getLastConnections();
        await failingSortingDb.customStatement(
          'DROP TABLE DeviceLastConnection',
        );
        final failingSortingController = ConnectMobiusController(
          connectServiceClient: ConnectServiceClient(failingSortingTransport),
          volumeServiceClient:
              ConnectVolumeServiceClient(failingSortingTransport),
          dodoServiceClient: DodoServiceClient(failingSortingTransport),
          sortingDatabase: failingSortingDb,
        );
        addTearDown(() async {
          await failingSortingController.close();
          await failingSortingDb.close();
          await failingSortingTransport.close();
        });

        failingSortingController.start();
        await pumpEventQueue();
        expect(
          failingSortingController.state.lastError?.kind,
          ConnectFailureKind.sortingStream,
        );
      }, (error, stack) {
        fail('Unexpected uncaught error in volume/sorting test: $error');
      });
    });

    test('unconditionally subscribes with includeLocalDevice: true, auto-syncs AudioRoutePort peripherals to NotifyAudioRouteChanged, and clears cache on stop(clearCache: true)', () async {
      final transport = _ControllerFakeTransport();
      final routeEvents = StreamController<List<LocalAudioPeripheral>>.broadcast();
      final audioRoutePort = _FakeControllerAudioRoutePort(
        initialPeripherals: <LocalAudioPeripheral>[
          LocalAudioPeripheral(
            id: kBuiltInSpeakerPeripheralId,
            name: 'This phone',
            isActive: true,
            connectionType: OutputPeripheralConnectionType.builtInSpeaker,
          ),
        ],
        stream: routeEvents.stream,
      );
      final sortingDb = DevicePickerSortingDatabase.forTesting(
        NativeDatabase.memory(),
      );
      final routeNotifications = <connect_pb.NotifyAudioRouteChangedRequest>[];
      transport.onCallSingle = (service, method, payload) async {
        if (method == 'NotifyAudioRouteChanged') {
          routeNotifications.add(
            connect_pb.NotifyAudioRouteChangedRequest.fromBuffer(payload),
          );
        }
        return Uint8List(0);
      };

      final controller = ConnectMobiusController(
        connectServiceClient: ConnectServiceClient(transport),
        volumeServiceClient: ConnectVolumeServiceClient(transport),
        dodoServiceClient: DodoServiceClient(transport),
        sortingDatabase: sortingDb,
        audioRoutePort: audioRoutePort,
      );
      addTearDown(() async {
        await controller.close();
        await routeEvents.close();
        await sortingDb.close();
        await transport.close();
      });

      expect(controller.hasAudioRouteBinding, isTrue);

      controller.start();
      await pumpEventQueue();

      // Verify StateRequest unconditionally enables includeLocalDevice: true
      expect(transport.lastStateRequest, isNotNull);
      expect(transport.lastStateRequest?.includeLocalDevice, isTrue);

      // Seed cluster devices so selfDevice is present for selfPeripherals projection
      transport.stateStreamController.add(
        _encodeCluster(
          isSyncedWithBackend: true,
          devices: <connect_pb.StateResponse_Device>[
            _protoDevice(id: 'self-id', name: 'Phone', isSelf: true),
            _protoDevice(id: 'remote-1', name: 'Sonos', isActive: true),
          ],
        ),
      );
      await pumpEventQueue();
      expect(controller.devices, hasLength(2));

      // Verify initial getPeripherals() triggered NotifyAudioRouteChanged
      expect(routeNotifications, hasLength(1));
      expect(routeNotifications.single.audioOutputDeviceName, equals('This phone'));

      // Switching active peripheral to Bluetooth dispatches another NotifyAudioRouteChanged
      routeEvents.add(<LocalAudioPeripheral>[
        LocalAudioPeripheral(
          id: 'bt-1',
          name: 'Pixel Buds Pro',
          isActive: true,
          connectionType: OutputPeripheralConnectionType.bluetooth,
          brand: 'Google',
          model: 'Pixel Buds Pro',
          category: OutputPeripheralCategory.headphones,
        ),
      ]);
      await pumpEventQueue();

      expect(routeNotifications, hasLength(2));
      expect(
        routeNotifications.last.audioOutputDeviceName,
        equals('Pixel Buds Pro'),
      );
      expect(controller.state.activeSelfPeripheral?.name, equals('Pixel Buds Pro'));

      await controller.stop(clearCache: true);
      controller.start();
      expect(controller.devices, isEmpty);
      expect(controller.isSyncedWithBackend, isFalse);
    });
  });
}

final class _FakeControllerAudioRoutePort implements AudioRoutePort {
  final List<LocalAudioPeripheral> initialPeripherals;
  final Stream<List<LocalAudioPeripheral>> stream;

  const _FakeControllerAudioRoutePort({
    required this.initialPeripherals,
    required this.stream,
  });

  @override
  Future<List<LocalAudioPeripheral>> getPeripherals() async =>
      initialPeripherals;

  @override
  Stream<List<LocalAudioPeripheral>> watchPeripherals() => stream;

  @override
  Future<bool> openSystemOutputSwitcher() async => true;
}
