import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_data.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

final class _RecordedVolumeRpc {
  final String method;
  final Uint8List payload;

  const _RecordedVolumeRpc({
    required this.method,
    required this.payload,
  });
}

final class _FakeVolumeTransport implements EsperantoTransport {
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final List<_RecordedVolumeRpc> singleCalls = <_RecordedVolumeRpc>[];

  Future<Uint8List> Function(String method, Uint8List payload)? onCallSingle;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleCalls.add(
      _RecordedVolumeRpc(method: method, payload: Uint8List.fromList(payload)),
    );
    final handler = onCallSingle;
    if (handler != null) {
      return handler(method, payload);
    }
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    if (method == 'Volume') {
      return volumeStreamController.stream;
    }
    if (method == 'LocalVolume') {
      return localVolumeStreamController.stream;
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    return Uint8List(0);
  }

  void emitVolumeResponse({
    required double volume,
    String? activeDeviceId,
    Map<String, double> groupVolumes = const <String, double>{},
    common_pb.Status status = common_pb.Status.OK,
  }) {
    final wireGroup = <String, int>{};
    for (final entry in groupVolumes.entries) {
      wireGroup[entry.key] = (entry.value * kMaxConnectVolumeWire).round();
    }
    final pb = volume_pb.VolumeResponse(
      status: status,
      volume: (volume * kMaxConnectVolumeWire).round(),
      activeDeviceConnectStateIdentifier: activeDeviceId,
      groupDeviceVolumes: wireGroup.entries,
    );
    volumeStreamController.add(Uint8List.fromList(pb.writeToBuffer()));
  }

  void emitLocalVolume({
    required double volume,
    volume_pb.LocalVolumeResponse_Reason reason =
        volume_pb.LocalVolumeResponse_Reason.USER,
  }) {
    final pb = volume_pb.LocalVolumeResponse(
      volume: (volume * kMaxConnectVolumeWire).round(),
      reason: reason,
    );
    localVolumeStreamController.add(Uint8List.fromList(pb.writeToBuffer()));
  }

  Future<void> close() async {
    await volumeStreamController.close();
    await localVolumeStreamController.close();
  }
}

ConnectDevice _makeDevice({
  required String id,
  bool isLocal = false,
  bool supportsVolume = true,
  int volumeSteps = 100,
  double initialVolume = 0.5,
  ConnectGroupData? groupData,
}) {
  return ConnectDevice(
    isSelf: isLocal,
    isActive: true,
    isBeingActivated: false,
    isWebapp: false,
    isZeroconf: false,
    isGroup: groupData != null,
    isSocialConnect: false,
    supportsLogout: !isLocal,
    supportsVolume: supportsVolume,
    supportsRename: false,
    creationTimeMs: 1000,
    brandDisplayName: 'Brand',
    modelDisplayName: 'Model',
    localIdentifier: 'local-$id',
    connectStateIdentifier: id,
    name: 'Device $id',
    state: ConnectDeviceState.loggedIn,
    type: DeviceType.speaker,
    incarnations: const <Incarnation>[],
    volume: (initialVolume * kMaxConnectVolumeWire).round(),
    isNewlyDiscovered: false,
    isDisabled: false,
    capabilities: const <ConnectCapabilityEntry>[],
    hifi: const ConnectHifiStatus(
      fullySupported: false,
      userEligible: false,
      deviceSupported: false,
    ),
    volumeSteps: volumeSteps,
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
    discoveryMethod: 1,
    groupData: groupData,
  );
}

void main() {
  group('Volume Math & Quantization Helpers (Item 161)', () {
    test('boundNormalizedVolume enforces finite [0.0, 1.0] without clamping operator', () {
      expect(boundNormalizedVolume(-0.25), 0.0);
      expect(boundNormalizedVolume(0.0), 0.0);
      expect(boundNormalizedVolume(0.42), 0.42);
      expect(boundNormalizedVolume(1.0), 1.0);
      expect(boundNormalizedVolume(1.75), 1.0);
      expect(() => boundNormalizedVolume(double.nan), throwsArgumentError);
      expect(() => boundNormalizedVolume(double.infinity), throwsArgumentError);
      expect(
        () => boundNormalizedVolume(double.negativeInfinity),
        throwsArgumentError,
      );
    });

    test('hasMeaningfulVolumeChange applies 0.001 tolerance', () {
      expect(hasMeaningfulVolumeChange(null, 0.5), isTrue);
      expect(hasMeaningfulVolumeChange(0.5, 0.5005), isFalse);
      expect(hasMeaningfulVolumeChange(0.5, 0.5009), isFalse);
      expect(hasMeaningfulVolumeChange(0.5, 0.5), isFalse);
      expect(hasMeaningfulVolumeChange(0.5, 0.5015), isTrue);
      expect(hasMeaningfulVolumeChange(0.5, 0.4985), isTrue);
      expect(
        () => hasMeaningfulVolumeChange(0.5, double.nan),
        throwsArgumentError,
      );
    });

    test('computeSteppedVolume applies 24-step UI cap and hardware quantization', () {
      // 100 hardware steps -> capped at 24 UI steps (delta ~ 1/24 = 0.0416667),
      // snapped onto 1/100 hardware grid -> round(54.1667)/100 = 0.54.
      expect(
        computeSteppedVolume(
          currentVolume: 0.5,
          volumeSteps: 100,
          direction: 1,
        ),
        closeTo(0.54, 1e-12),
      );
      expect(
        computeSteppedVolume(
          currentVolume: 0.5,
          volumeSteps: 100,
          direction: -1,
        ),
        closeTo(0.46, 1e-12),
      );

      // 10 hardware steps (< 24) -> uses 10 UI steps (delta 0.1).
      expect(
        computeSteppedVolume(
          currentVolume: 0.5,
          volumeSteps: 10,
          direction: 1,
        ),
        closeTo(0.6, 1e-12),
      );

      // Boundary caps at 1.0 and 0.0.
      expect(
        computeSteppedVolume(
          currentVolume: 0.99,
          volumeSteps: 100,
          direction: 1,
        ),
        1.0,
      );
      expect(
        computeSteppedVolume(
          currentVolume: 0.01,
          volumeSteps: 100,
          direction: -1,
        ),
        0.0,
      );

      // Non-quantized mode uses exact 1 / volumeSteps.
      expect(
        computeSteppedVolume(
          currentVolume: 0.5,
          volumeSteps: 100,
          direction: 1,
          quantize: false,
        ),
        closeTo(0.51, 1e-12),
      );

      // volumeSteps <= 0 leaves volume unchanged.
      expect(
        computeSteppedVolume(
          currentVolume: 0.3,
          volumeSteps: 0,
          direction: 1,
        ),
        0.3,
      );
      expect(
        () => computeSteppedVolume(
          currentVolume: 0.5,
          volumeSteps: 10,
          direction: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RemoteVolumeController (Item 161)', () {
    testWidgets('throttles rapid slider drags with 200ms leading + trailing and serializes RPC execution', (tester) async {
      final transport = _FakeVolumeTransport();
      final inFlightCompleter = Completer<Uint8List>();
      var callIndex = 0;
      transport.onCallSingle = (method, payload) {
        callIndex += 1;
        if (callIndex == 1) {
          return inFlightCompleter.future;
        }
        return Future<Uint8List>.value(Uint8List(0));
      };

      final client = ConnectVolumeServiceClient(transport);
      final controller = RemoteVolumeController(volumeClient: client);
      addTearDown(controller.dispose);
      addTearDown(transport.close);

      final activeSpeaker = _makeDevice(id: 'spk-1', volumeSteps: 100);
      controller.updateActiveDevice(activeSpeaker);

      // t = 0ms: leading dispatch (0.2) executes immediately.
      final f1 = controller.setVolume(0.2);
      await tester.pump();
      expect(transport.singleCalls, hasLength(1));
      expect(
        volume_pb.VolumeSetRequest.fromBuffer(
          transport.singleCalls.single.payload,
        ).volume,
        (0.2 * kMaxConnectVolumeWire).round(),
      );
      expect(controller.state.remoteVolume, 0.2);
      expect(controller.state.isChangingVolume, isTrue);

      // t = 50ms, 100ms, 150ms: intermediate updates coalesce; latest (0.8) wins.
      await tester.pump(const Duration(milliseconds: 50));
      final f2 = controller.setVolume(0.4);
      await tester.pump(const Duration(milliseconds: 50));
      final f3 = controller.setVolume(0.6);
      await tester.pump(const Duration(milliseconds: 50));
      final f4 = controller.setVolume(0.8);
      await tester.pump();
      expect(transport.singleCalls, hasLength(1));
      expect(controller.state.remoteVolume, 0.8);

      // t = 200ms: trailing window fires, but serialChain waits until call #1 finishes.
      await tester.pump(const Duration(milliseconds: 50));
      expect(transport.singleCalls, hasLength(1));

      // Complete call #1 -> call #2 (0.8) immediately dispatches in order.
      inFlightCompleter.complete(Uint8List(0));
      await tester.pump();

      expect(transport.singleCalls, hasLength(2));
      expect(
        volume_pb.VolumeSetRequest.fromBuffer(
          transport.singleCalls[1].payload,
        ).volume,
        (0.8 * kMaxConnectVolumeWire).round(),
      );

      final statuses = await Future.wait<ConnectVolumeStatus>(
        <Future<ConnectVolumeStatus>>[f1, f2, f3, f4],
      );
      expect(
        statuses,
        equals(<ConnectVolumeStatus>[
          ConnectVolumeStatus.ok,
          ConnectVolumeStatus.ok,
          ConnectVolumeStatus.ok,
          ConnectVolumeStatus.ok,
        ]),
      );

      // Advance past 800ms suppression timer so no pending timers remain on teardown.
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('800ms echo-suppression blocks stale remote echoes and bypasses on active device switch', (tester) async {
      final transport = _FakeVolumeTransport();
      final client = ConnectVolumeServiceClient(transport);
      final controller = RemoteVolumeController(volumeClient: client);
      addTearDown(controller.dispose);
      addTearDown(transport.close);

      final speaker1 = _makeDevice(id: 'spk-1', volumeSteps: 100);
      controller.updateActiveDevice(speaker1);

      await controller.setVolume(0.75);
      await tester.pump();
      expect(controller.state.isChangingVolume, isTrue);
      expect(controller.state.remoteVolume, 0.75);

      // At t = 300ms (< 800ms): stale remote echo for spk-1 is suppressed.
      await tester.pump(const Duration(milliseconds: 300));
      transport.emitVolumeResponse(volume: 0.25, activeDeviceId: 'spk-1');
      await tester.pump();
      expect(controller.state.remoteVolume, 0.75);
      expect(controller.state.isChangingVolume, isTrue);

      // At t = 500ms: another user drag resets the 800ms suppression timer -> expires at 1300ms.
      await tester.pump(const Duration(milliseconds: 200));
      await controller.setVolume(0.85);
      await tester.pump();

      // At t = 1000ms (500ms after second drag): still suppressed.
      await tester.pump(const Duration(milliseconds: 500));
      transport.emitVolumeResponse(volume: 0.30, activeDeviceId: 'spk-1');
      await tester.pump();
      expect(controller.state.remoteVolume, 0.85);
      expect(controller.state.isChangingVolume, isTrue);

      // At t = 1300ms (800ms after second drag): suppression clears and remote updates apply.
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.state.isChangingVolume, isFalse);
      transport.emitVolumeResponse(volume: 0.90, activeDeviceId: 'spk-1');
      await tester.pump();
      expect(controller.state.remoteVolume, closeTo(0.90, 1e-4));

      // New drag followed by active device switch immediately bypasses suppression.
      await controller.setVolume(0.60);
      await tester.pump();
      expect(controller.state.isChangingVolume, isTrue);
      transport.emitVolumeResponse(volume: 0.15, activeDeviceId: 'spk-2');
      await tester.pump();
      expect(controller.state.isChangingVolume, isFalse);
      expect(controller.state.activeDeviceConnectStateIdentifier, 'spk-2');
      expect(controller.state.remoteVolume, closeTo(0.15, 1e-4));

      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('volumeUp/volumeDown quantize controllable remote devices and guard local/unsupported devices', (tester) async {
      final transport = _FakeVolumeTransport();
      final client = ConnectVolumeServiceClient(transport);
      final controller = RemoteVolumeController(volumeClient: client);
      addTearDown(controller.dispose);
      addTearDown(transport.close);

      // Controllable remote speaker with 100 steps at 0.50 -> +1 step = 0.54.
      controller.updateActiveDevice(
        _makeDevice(id: 'spk-1', volumeSteps: 100, initialVolume: 0.50),
      );
      expect(controller.isRemoteVolumeControllable, isTrue);
      await controller.volumeUp();
      await tester.pump();
      expect(transport.singleCalls.last.method, 'VolumeSet');
      expect(controller.state.remoteVolume, closeTo(0.54, 1e-12));

      // Wait past 200ms cooldown, then volumeDown -> 0.54 - 0.0416667 = 0.4983 -> 0.50.
      await tester.pump(const Duration(milliseconds: 250));
      await controller.volumeDown();
      await tester.pump();
      expect(transport.singleCalls.last.method, 'VolumeSet');
      expect(controller.state.remoteVolume, closeTo(0.50, 1e-12));

      // Local device -> guarded no-op (no RPC emitted).
      final countBeforeLocal = transport.singleCalls.length;
      controller.updateActiveDevice(_makeDevice(id: 'phone', isLocal: true));
      expect(controller.isRemoteVolumeControllable, isFalse);
      await controller.setVolume(0.9);
      await controller.volumeUp();
      await tester.pump();
      expect(transport.singleCalls.length, countBeforeLocal);

      // Unsupported remote device -> guarded no-op.
      controller.updateActiveDevice(
        _makeDevice(id: 'spk-fixed', supportsVolume: false, volumeSteps: 0),
      );
      expect(controller.isRemoteVolumeControllable, isFalse);
      await controller.volumeDown();
      await tester.pump();
      expect(transport.singleCalls.length, countBeforeLocal);

      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('debounces localVolume events by 200ms and exposes replay(1) stream', (tester) async {
      final transport = _FakeVolumeTransport();
      final client = ConnectVolumeServiceClient(transport);
      final controller = RemoteVolumeController(volumeClient: client);
      addTearDown(controller.dispose);
      addTearDown(transport.close);

      final states = <ConnectVolumeState>[];
      final sub = controller.stream.listen(states.add);
      addTearDown(sub.cancel);

      await tester.pump();
      expect(states, hasLength(1));

      transport.emitLocalVolume(volume: 0.2);
      await tester.pump(const Duration(milliseconds: 100));
      transport.emitLocalVolume(
        volume: 0.65,
        reason: volume_pb.LocalVolumeResponse_Reason.SYSTEM,
      );
      await tester.pump(const Duration(milliseconds: 150));
      // Still within 200ms of second local emission.
      expect(controller.state.localVolume, isNull);

      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.state.localVolume, closeTo(0.65, 1e-4));
      expect(controller.effectiveVolume, closeTo(0.65, 1e-4));
      expect(states.last.localVolume, closeTo(0.65, 1e-4));
    });

    testWidgets('supports per-group-device 200ms throttling, VolumeUp/Down, and 800ms echo suppression', (tester) async {
      final transport = _FakeVolumeTransport();
      final client = ConnectVolumeServiceClient(transport);
      final controller = RemoteVolumeController(volumeClient: client);
      addTearDown(controller.dispose);
      addTearDown(transport.close);

      final groupData = ConnectGroupData(
        capabilities: ConnectGroupCapabilities(maxDevices: 4),
        devices: <ConnectGroupDevice>[
          ConnectGroupDevice(
            identifiers: GroupDeviceIdentifiers(groupDeviceIdentifier: 'gd-1'),
            name: 'Kitchen',
            deviceType: DeviceType.speaker,
            modelDisplayName: 'Model',
            capabilities: const GroupDeviceCapabilities(
              removable: true,
              removalDissolvesGroup: false,
            ),
            groupingStatus: GroupingStatus.grouped,
            volume: GroupDeviceVolume(volume: 0.4, volumeSteps: 20),
          ),
          ConnectGroupDevice(
            identifiers: GroupDeviceIdentifiers(groupDeviceIdentifier: 'gd-2'),
            name: 'Living Room',
            deviceType: DeviceType.speaker,
            modelDisplayName: 'Model',
            capabilities: const GroupDeviceCapabilities(
              removable: true,
              removalDissolvesGroup: false,
            ),
            groupingStatus: GroupingStatus.grouped,
            volume: GroupDeviceVolume(volume: 0.6, volumeSteps: 20),
          ),
        ],
      );
      controller.updateActiveDevice(
        _makeDevice(id: 'grp-1', groupData: groupData),
      );

      // Two distinct group devices can send leading calls simultaneously without blocking each other.
      await controller.setGroupVolume(groupDeviceIdentifier: 'gd-1', volume: 0.7);
      await controller.groupVolumeUp(groupDeviceIdentifier: 'gd-2');
      await tester.pump();

      expect(transport.singleCalls, hasLength(2));
      expect(transport.singleCalls[0].method, 'VolumeSet');
      expect(transport.singleCalls[1].method, 'VolumeUp');
      expect(
        controller.state.pendingGroupDeviceIds,
        containsAll(<String>['gd-1', 'gd-2']),
      );
      expect(controller.state.groupDeviceVolumes['gd-1']?.volume, 0.7);
      expect(
        controller.state.groupDeviceVolumes['gd-2']?.volume,
        closeTo(0.65, 1e-12),
      );

      // Stale remote echo while pending keeps gd-1 optimistic value (0.7).
      await tester.pump(const Duration(milliseconds: 300));
      transport.emitVolumeResponse(
        volume: 0.5,
        activeDeviceId: 'grp-1',
        groupVolumes: <String, double>{'gd-1': 0.2, 'gd-2': 0.65},
      );
      await tester.pump();
      expect(controller.state.groupDeviceVolumes['gd-1']?.volume, 0.7);

      // After 800ms suppression expires, pendingGroupDeviceIds clears and remote values apply.
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.state.pendingGroupDeviceIds, isEmpty);
      transport.emitVolumeResponse(
        volume: 0.5,
        activeDeviceId: 'grp-1',
        groupVolumes: <String, double>{'gd-1': 0.8},
      );
      await tester.pump();
      expect(
        controller.state.groupDeviceVolumes['gd-1']?.volume,
        closeTo(0.8, 1e-4),
      );
    });

    test('surfaces stream and RPC failures via ConnectVolumeState.status and blocks post-dispose calls', () async {
      final transport = _FakeVolumeTransport();
      transport.onCallSingle =
          (method, payload) async => throw StateError('bridge down');
      final client = ConnectVolumeServiceClient(transport);
      final controller = RemoteVolumeController(volumeClient: client);
      addTearDown(transport.close);

      final status = await controller.setVolume(0.5);
      await pumpEventQueue();
      expect(status, ConnectVolumeStatus.backendFailure);
      expect(controller.state.status, ConnectVolumeStatus.backendFailure);

      transport.volumeStreamController.addError(StateError('stream broken'));
      await pumpEventQueue();
      expect(controller.state.status, ConnectVolumeStatus.backendFailure);

      await controller.dispose();

      expect(() => controller.setVolume(0.2), throwsStateError);
      expect(controller.volumeUp, throwsStateError);
      expect(controller.volumeDown, throwsStateError);
      expect(
        () => controller.setGroupVolume(
          groupDeviceIdentifier: 'gd-1',
          volume: 0.2,
        ),
        throwsStateError,
      );
    });

    testWidgets('cancels pending active and group throttle slots on active device switch and clears activeDeviceConnectStateIdentifier when device is null', (tester) async {
      final transport = _FakeVolumeTransport();
      final client = ConnectVolumeServiceClient(transport);
      final controller = RemoteVolumeController(volumeClient: client);
      addTearDown(controller.dispose);
      addTearDown(transport.close);

      final speaker1 = _makeDevice(id: 'spk-1', volumeSteps: 100);
      controller.updateActiveDevice(speaker1);
      expect(controller.state.activeDeviceConnectStateIdentifier, equals('spk-1'));

      // Leading call (0.2) fires immediately; trailing call (0.9) is queued in throttle slot.
      final fLeading = controller.setVolume(0.2);
      final fTrailing = controller.setVolume(0.9);
      await tester.pump();
      expect(transport.singleCalls, hasLength(1));

      // Before the 200ms cooldown expires, switch active device to null.
      // Must cancel the queued trailing command for spk-1 and clear activeDeviceConnectStateIdentifier.
      controller.updateActiveDevice(null);
      expect(controller.state.activeDevice, isNull);
      expect(controller.state.activeDeviceConnectStateIdentifier, isNull);
      expect(controller.state.outputMode, equals(VolumeOutputMode.local));
      expect(controller.state.isChangingVolume, isFalse);

      // Advance past 800ms -> cancelled trailing call for spk-1 must never fire.
      await tester.pump(const Duration(milliseconds: 850));
      expect(transport.singleCalls, hasLength(1));
      expect(await fLeading, equals(ConnectVolumeStatus.ok));
      expect(await fTrailing, equals(ConnectVolumeStatus.ok));
    });

    test('routes bidirectional hardware volume events across SystemVolumePort and ConnectNativeGateway', () async {
      final transport = _FakeVolumeTransport();
      final client = ConnectVolumeServiceClient(transport);
      final systemEvents = StreamController<SystemVolumeEvent>.broadcast();
      final gatewayLocalVol = StreamController<Uint8List>.broadcast();
      addTearDown(systemEvents.close);
      addTearDown(gatewayLocalVol.close);

      final configuredCalls = <Map<String, Object>>[];
      final updatedRemoteWireVols = <int>[];
      final setLocalSysVols = <int>[];
      final setLocalGatewayCalls = <Map<String, Object>>[];

      final sysPort = _FakeSystemVolumePort(
        events: systemEvents.stream,
        onConfigureRemote: ({
          required bool enabled,
          required bool supportsVolume,
          required int volumeSteps,
          required int currentVolume,
        }) {
          configuredCalls.add(<String, Object>{
            'enabled': enabled,
            'supportsVolume': supportsVolume,
            'volumeSteps': volumeSteps,
            'currentVolume': currentVolume,
          });
        },
        onUpdateRemote: (currentVolume) {
          updatedRemoteWireVols.add(currentVolume);
        },
        onSetLocal: (volume) {
          setLocalSysVols.add(volume);
        },
      );

      final nativeGateway = _FakeVolumeNativeGateway(
        localVolumeStream: gatewayLocalVol.stream,
        onSetLocalVolume: ({
          required int volume0To65535,
          required int volumeSteps,
          required ConnectLocalVolumeReason reason,
        }) {
          setLocalGatewayCalls.add(<String, Object>{
            'volume': volume0To65535,
            'steps': volumeSteps,
            'reason': reason,
          });
        },
      );

      final controller = RemoteVolumeController(
        volumeClient: client,
        systemVolumePort: sysPort,
        nativeGateway: nativeGateway,
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      addTearDown(controller.dispose);
      addTearDown(transport.close);
      await pumpEventQueue();

      // 1) Local active: OS LocalVolumeChanged pushes to nativeGateway.setLocalVolume(..., user)
      systemEvents.add(
        LocalVolumeChanged(volume: 20000, steps: 25, currentStep: 8),
      );
      await pumpEventQueue();
      expect(setLocalGatewayCalls, hasLength(1));
      expect(setLocalGatewayCalls.single['volume'], equals(20000));
      expect(setLocalGatewayCalls.single['steps'], equals(25));
      expect(
        setLocalGatewayCalls.single['reason'],
        equals(ConnectLocalVolumeReason.user),
      );

      // 2) Local active: nativeGateway.localVolumeStream pushes to systemVolumePort.setLocalVolume
      final remoteToLocalPb = volume_pb.LocalVolumeResponse(
        volume: 45000,
        reason: volume_pb.LocalVolumeResponse_Reason.USER,
      );
      gatewayLocalVol.add(Uint8List.fromList(remoteToLocalPb.writeToBuffer()));
      await pumpEventQueue();
      expect(setLocalSysVols, equals(<int>[45000]));

      // 3) Remote active: configures VolumeProviderCompat (enabled: true) and updates on volume change
      controller.updateActiveDevice(
        _makeDevice(
          id: 'remote-sonos',
          isLocal: false,
          supportsVolume: true,
          volumeSteps: 64,
          initialVolume: 0.5,
        ),
      );
      await pumpEventQueue();
      expect(configuredCalls, isNotEmpty);
      expect(configuredCalls.last['enabled'], isTrue);
      expect(configuredCalls.last['supportsVolume'], isTrue);
      expect(configuredCalls.last['volumeSteps'], equals(64));

      // Hardware volume up/down and slider events route to ConnectVolumeServiceClient
      transport.singleCalls.clear();
      systemEvents.add(RemoteVolumeAdjust(direction: 1));
      await pumpEventQueue();
      expect(transport.singleCalls, hasLength(1));
      expect(transport.singleCalls.last.method, equals('VolumeSet'));
      expect(updatedRemoteWireVols, isNotEmpty);

      systemEvents.add(RemoteVolumeSet(volume: 65535));
      await pumpEventQueue();
      expect(transport.singleCalls, hasLength(2));
      expect(
        volume_pb.VolumeSetRequest.fromBuffer(
          transport.singleCalls.last.payload,
        ).volume,
        equals(65535),
      );

      // 4) Switching back to local or stopping controller restores local hardware volume routing (enabled: false)
      await controller.stop();
      expect(controller.isStarted, isFalse);
      expect(configuredCalls.last['enabled'], isFalse);
    });
  });
}

final class _FakeSystemVolumePort implements SystemVolumePort {
  final Stream<SystemVolumeEvent> events;
  final void Function({
    required bool enabled,
    required bool supportsVolume,
    required int volumeSteps,
    required int currentVolume,
  }) onConfigureRemote;
  final void Function(int currentVolume) onUpdateRemote;
  final void Function(int volume) onSetLocal;

  _FakeSystemVolumePort({
    required this.events,
    required this.onConfigureRemote,
    required this.onUpdateRemote,
    required this.onSetLocal,
  });

  @override
  Future<SystemVolumeSnapshot> getLocalVolume() async =>
      SystemVolumeSnapshot(volume: 32768, steps: 25, currentStep: 12);

  @override
  Future<bool> setLocalVolume({
    required int volume,
    bool showUi = false,
  }) async {
    onSetLocal(volume);
    return true;
  }

  @override
  Future<bool> configureRemoteHardwareVolume({
    required bool enabled,
    required bool supportsVolume,
    required int volumeSteps,
    required int currentVolume,
  }) async {
    onConfigureRemote(
      enabled: enabled,
      supportsVolume: supportsVolume,
      volumeSteps: volumeSteps,
      currentVolume: currentVolume,
    );
    return true;
  }

  @override
  Future<bool> updateRemoteHardwareVolume({required int currentVolume}) async {
    onUpdateRemote(currentVolume);
    return true;
  }

  @override
  Stream<SystemVolumeEvent> watchEvents() => events;
}

final class _FakeVolumeNativeGateway extends Fake
    implements ConnectNativeGateway {
  @override
  final Stream<Uint8List> localVolumeStream;
  final void Function({
    required int volume0To65535,
    required int volumeSteps,
    required ConnectLocalVolumeReason reason,
  }) onSetLocalVolume;

  _FakeVolumeNativeGateway({
    required this.localVolumeStream,
    required this.onSetLocalVolume,
  });

  @override
  int setLocalVolume({
    required int volume0To65535,
    required int volumeSteps,
    required ConnectLocalVolumeReason reason,
  }) {
    onSetLocalVolume(
      volume0To65535: volume0To65535,
      volumeSteps: volumeSteps,
      reason: reason,
    );
    return 0;
  }
}
