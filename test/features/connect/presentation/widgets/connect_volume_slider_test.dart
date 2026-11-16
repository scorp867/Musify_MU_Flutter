import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pbenum.dart'
    as common_pbenum;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

final class _VolumeFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();

  final List<String> singleMethods = <String>[];
  final List<int> setVolumeValues = <int>[];

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleMethods.add(method);
    if (service == ConnectVolumeServiceClient.serviceName) {
      if (method == 'VolumeSet') {
        final req = volume_pb.VolumeSetRequest.fromBuffer(payload);
        setVolumeValues.add(req.volume);
      }
      return Uint8List.fromList(
        common_pb.StatusResponse(
          status: common_pbenum.Status.OK,
        ).writeToBuffer(),
      );
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
      return stateStreamController.stream;
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
  }
}

ConnectDevice _remoteDevice({
  String id = 'sonos-1',
  String localId = 'local-sonos',
  String name = 'Kitchen Sonos',
  String brandDisplayName = 'Sonos',
  String modelDisplayName = 'One',
  bool isLocal = false,
  bool supportsVolume = true,
  int volumeSteps = 64,
  int volume = 32768,
}) {
  return ConnectDevice(
    isSelf: false,
    isActive: true,
    isBeingActivated: false,
    isWebapp: false,
    isZeroconf: false,
    isGroup: false,
    isSocialConnect: false,
    supportsLogout: true,
    supportsVolume: supportsVolume,
    supportsRename: false,
    creationTimeMs: 0,
    brandDisplayName: brandDisplayName,
    modelDisplayName: modelDisplayName,
    localIdentifier: localId,
    connectStateIdentifier: id,
    name: name,
    state: ConnectDeviceState.loggedIn,
    type: DeviceType.speaker,
    incarnations: const [],
    volume: volume,
    isNewlyDiscovered: false,
    isDisabled: false,
    capabilities: const [],
    hifi: const ConnectHifiStatus(
      fullySupported: false,
      userEligible: false,
      deviceSupported: false,
    ),
    volumeSteps: volumeSteps,
    isVoiceEnabled: false,
    isLocal: isLocal,
    localIp: '',
    supportedMediaTypes: const [],
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectVolumeSlider', () {
    testWidgets('disables slider when active device is not remote-volume controllable', (
      tester,
    ) async {
      final transport = _VolumeFakeTransport();
      final volumeClient = ConnectVolumeServiceClient(transport);
      final volumeCtrl = RemoteVolumeController(
        volumeClient: volumeClient,
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      addTearDown(() async {
        await volumeCtrl.dispose();
        await transport.close();
      });

      // Local device (isLocal: true) -> not remote controllable
      volumeCtrl.updateActiveDevice(_remoteDevice(isLocal: true));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ConnectVolumeSlider(volumeController: volumeCtrl),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
      expect(find.text('Unavailable'), findsOneWidget);

      // Remote device with supportsVolume: false -> disabled
      volumeCtrl.updateActiveDevice(
        _remoteDevice(isLocal: false, supportsVolume: false),
      );
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);

      // Remote device with volumeSteps: 0 -> disabled
      volumeCtrl.updateActiveDevice(
        _remoteDevice(isLocal: false, supportsVolume: true, volumeSteps: 0),
      );
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    });

    testWidgets('drags slider and taps step buttons through ConnectMobiusController', (
      tester,
    ) async {
      final transport = _VolumeFakeTransport();
      final sortingDb = DevicePickerSortingDatabase.forTesting(
        NativeDatabase.memory(),
      );
      final volumeClient = ConnectVolumeServiceClient(transport);
      final volumeCtrl = RemoteVolumeController(
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
        remoteVolumeController: volumeCtrl,
      );
      controller.start();
      addTearDown(() async {
        await controller.close();
        await volumeCtrl.dispose();
        await sortingDb.close();
        await transport.close();
      });

      transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: [
              connect_pb.StateResponse_Device(
                isSelf: false,
                isActive: true,
                isLocal: false,
                connectStateIdentifier: 'sonos-1',
                localIdentifier: 'local-sonos',
                name: 'Kitchen Sonos',
                state: 'LOGGED_IN',
                type: 'SPEAKER',
                volume: 32768,
                volumeSteps: 24,
                supportsVolume: true,
                capabilities: '[]',
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      transport.volumeStreamController.add(
        Uint8List.fromList(
          volume_pb.VolumeResponse(
            volume: 32768,
            activeDeviceConnectStateIdentifier: 'sonos-1',
          ).writeToBuffer(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: ConnectVolumeSlider(controller: controller),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Volume: Kitchen Sonos'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('volume_step_up_button')));
      await tester.pumpAndSettle();
      expect(transport.singleMethods, contains('VolumeSet'));
      expect(transport.setVolumeValues.last, greaterThan(32768));

      final afterStepUp = transport.setVolumeValues.last;
      await tester.tap(find.byKey(const ValueKey<String>('volume_step_down_button')));
      await tester.pumpAndSettle();
      expect(transport.setVolumeValues.last, lessThan(afterStepUp));

      final countBeforeDrag = transport.setVolumeValues.length;
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(transport.setVolumeValues.length, greaterThan(countBeforeDrag));
    });

    testWidgets('preserves active drag value against incoming remote volume echoes', (
      tester,
    ) async {
      final transport = _VolumeFakeTransport();
      final volumeClient = ConnectVolumeServiceClient(transport);
      final volumeCtrl = RemoteVolumeController(
        volumeClient: volumeClient,
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      addTearDown(() async {
        await volumeCtrl.dispose();
        await transport.close();
      });

      volumeCtrl.updateActiveDevice(_remoteDevice(volume: 32768));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ConnectVolumeSlider(volumeController: volumeCtrl),
              ),
            ),
          ),
        ),
      );

      final sliderFinder = find.byType(Slider);
      final center = tester.getCenter(sliderFinder);
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();

      final draggingValue = tester.widget<Slider>(sliderFinder).value;
      expect(draggingValue, greaterThan(0.55));

      // Simulate stale remote echo while user still holds thumb
      transport.volumeStreamController.add(
        Uint8List.fromList(
          volume_pb.VolumeResponse(
            volume: 6553,
            activeDeviceConnectStateIdentifier: 'sonos-1',
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      expect(
        tester.widget<Slider>(sliderFinder).value,
        closeTo(draggingValue, 0.001),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('does not re-subscribe StreamBuilder during drag setState frames', (
      tester,
    ) async {
      final transport = _VolumeFakeTransport();
      final volumeClient = ConnectVolumeServiceClient(transport);
      final volumeCtrl = RemoteVolumeController(
        volumeClient: volumeClient,
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      addTearDown(() async {
        await volumeCtrl.dispose();
        await transport.close();
      });

      volumeCtrl.updateActiveDevice(_remoteDevice(volume: 32768));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ConnectVolumeSlider(volumeController: volumeCtrl),
              ),
            ),
          ),
        ),
      );

      final streamBuilderFinder =
          find.byType(StreamBuilder<ConnectVolumeState>);
      final initialStream = tester
          .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
          .stream;
      final initialStreamBuilderState = tester.state(streamBuilderFinder);
      expect(initialStream, isNotNull);

      final sliderFinder = find.byType(Slider);
      final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
      await tester.pump();
      expect(
        identical(
          tester
              .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
              .stream,
          initialStream,
        ),
        isTrue,
      );

      for (var step = 0; step < 4; step++) {
        await gesture.moveBy(const Offset(18, 0));
        await tester.pump();
        expect(
          identical(
            tester
                .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
                .stream,
            initialStream,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(streamBuilderFinder),
            initialStreamBuilderState,
          ),
          isTrue,
        );
      }

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        identical(
          tester
              .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
              .stream,
          initialStream,
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('didUpdateWidget rebinds stream and clears drag state when controller changes', (
      tester,
    ) async {
      final transportA = _VolumeFakeTransport();
      final transportB = _VolumeFakeTransport();
      final ctrlA = RemoteVolumeController(
        volumeClient: ConnectVolumeServiceClient(transportA),
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      final ctrlB = RemoteVolumeController(
        volumeClient: ConnectVolumeServiceClient(transportB),
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      addTearDown(() async {
        await ctrlA.dispose();
        await ctrlB.dispose();
        await transportA.close();
        await transportB.close();
      });

      ctrlA.updateActiveDevice(
        _remoteDevice(
          id: 'spk-a',
          localId: 'local-a',
          name: 'Speaker A',
          brandDisplayName: 'Sonos',
          modelDisplayName: 'One',
          volume: 16384,
        ),
      );
      ctrlA.setVolume(0.25);

      ctrlB.updateActiveDevice(
        _remoteDevice(
          id: 'spk-b',
          localId: 'local-b',
          name: 'Speaker B',
          brandDisplayName: 'Bose',
          modelDisplayName: 'Home',
          volume: 45875,
        ),
      );
      ctrlB.setVolume(0.70);

      final activeCtrl = ValueNotifier<RemoteVolumeController?>(ctrlA);
      final enabledNotifier = ValueNotifier<bool?>(null);
      addTearDown(() {
        activeCtrl.dispose();
        enabledNotifier.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ValueListenableBuilder<RemoteVolumeController?>(
                  valueListenable: activeCtrl,
                  builder: (context, currentCtrl, _) {
                    return ValueListenableBuilder<bool?>(
                      valueListenable: enabledNotifier,
                      builder: (context, enabled, _) {
                        return ConnectVolumeSlider(
                          volumeController: currentCtrl,
                          enabled: enabled,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final streamBuilderFinder =
          find.byType(StreamBuilder<ConnectVolumeState>);
      final streamA = tester
          .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
          .stream;
      expect(find.text('Volume: Speaker A'), findsOneWidget);

      final sliderFinder = find.byType(Slider);
      final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
      await tester.pump();
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.6));

      activeCtrl.value = ctrlB;
      await tester.pump();
      final streamB = tester
          .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
          .stream;
      expect(streamB, isNotNull);
      expect(identical(streamB, streamA), isFalse);
      expect(find.text('Volume: Speaker B'), findsOneWidget);
      expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.70, 0.02));
      expect(find.text('70%'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      activeCtrl.value = null;
      await tester.pump();
      expect(find.byType(StreamBuilder<ConnectVolumeState>), findsNothing);
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('didUpdateWidget clears drag state when enabled becomes false while keeping stream', (
      tester,
    ) async {
      final transport = _VolumeFakeTransport();
      final volumeCtrl = RemoteVolumeController(
        volumeClient: ConnectVolumeServiceClient(transport),
        throttleWindow: Duration.zero,
        suppressionWindow: Duration.zero,
        localDebounceWindow: Duration.zero,
      );
      final enabledNotifier = ValueNotifier<bool?>(null);
      addTearDown(() async {
        enabledNotifier.dispose();
        await volumeCtrl.dispose();
        await transport.close();
      });

      volumeCtrl.updateActiveDevice(_remoteDevice(volume: 32768));
      volumeCtrl.setVolume(0.50);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ValueListenableBuilder<bool?>(
                  valueListenable: enabledNotifier,
                  builder: (context, enabled, _) {
                    return ConnectVolumeSlider(
                      volumeController: volumeCtrl,
                      enabled: enabled,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final streamBuilderFinder =
          find.byType(StreamBuilder<ConnectVolumeState>);
      final initialStream = tester
          .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
          .stream;

      final sliderFinder = find.byType(Slider);
      final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
      await tester.pump();
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.70));

      enabledNotifier.value = false;
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);
      expect(find.text('Unavailable'), findsOneWidget);

      await gesture.up();
      await tester.pump();

      // Update controller volume while disabled; re-enabling must reflect 30%
      // rather than the stale >70% _dragValue from before enabled=false.
      volumeCtrl.setVolume(0.30);
      await tester.pump();

      enabledNotifier.value = null;
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
      expect(find.text('30%'), findsOneWidget);
      expect(
        identical(
          tester
              .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
              .stream,
          initialStream,
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
    });

    testWidgets(
      'clears drag state when isRemoteVolumeControllable drops true -> false -> true mid-drag under enabled=null',
      (tester) async {
        final transport = _VolumeFakeTransport();
        final volumeCtrl = RemoteVolumeController(
          volumeClient: ConnectVolumeServiceClient(transport),
          throttleWindow: Duration.zero,
          suppressionWindow: Duration.zero,
          localDebounceWindow: Duration.zero,
        );
        addTearDown(() async {
          await volumeCtrl.dispose();
          await transport.close();
        });

        volumeCtrl.updateActiveDevice(_remoteDevice(id: 'sonos-1', volume: 16384));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: ConnectVolumeSlider(volumeController: volumeCtrl),
                ),
              ),
            ),
          ),
        );

        final streamBuilderFinder =
            find.byType(StreamBuilder<ConnectVolumeState>);
        final initialStream = tester
            .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
            .stream;

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(140, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.75));

        // Drop controllability via non-controllable local device (widget.enabled == null)
        volumeCtrl.updateActiveDevice(
          _remoteDevice(id: 'local-phone', isLocal: true, volume: 32768),
        );
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);
        expect(find.text('Unavailable'), findsOneWidget);

        // Lift pointer while slider is disabled (onChangeEnd cannot fire)
        await gesture.up();
        await tester.pump();

        // Recover controllability at 30%; stale >75% drag value must NOT return
        volumeCtrl.updateActiveDevice(
          _remoteDevice(id: 'sonos-1', isLocal: false, volume: 19661),
        );
        volumeCtrl.setVolume(0.30);
        await tester.pumpAndSettle();

        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
        expect(find.text('30%'), findsOneWidget);
        expect(
          identical(
            tester
                .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
                .stream,
            initialStream,
          ),
          isTrue,
        );

        // Also verify activeDevice -> null -> controllable device mid-drag resets drag
        final gesture2 = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture2.moveBy(const Offset(140, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.75));

        volumeCtrl.updateActiveDevice(null);
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);

        await gesture2.up();
        await tester.pump();

        volumeCtrl.updateActiveDevice(
          _remoteDevice(id: 'sonos-1', isLocal: false, volume: 13107),
        );
        volumeCtrl.setVolume(0.20);
        await tester.pumpAndSettle();

        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.20, 0.02));
        expect(find.text('20%'), findsOneWidget);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'resets drag state when active device identity changes directly between controllable devices mid-drag',
      (tester) async {
        final transport = _VolumeFakeTransport();
        final volumeCtrl = RemoteVolumeController(
          volumeClient: ConnectVolumeServiceClient(transport),
          throttleWindow: Duration.zero,
          suppressionWindow: Duration.zero,
          localDebounceWindow: Duration.zero,
        );
        addTearDown(() async {
          await volumeCtrl.dispose();
          await transport.close();
        });

        volumeCtrl.updateActiveDevice(
          _remoteDevice(id: 'spk-a', name: 'Speaker A', volume: 16384),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: ConnectVolumeSlider(volumeController: volumeCtrl),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(140, 0));
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.75));

        final dispatchesBeforeSwitch = transport.setVolumeValues.length;

        // Switch directly to Speaker B (still controllable) while pointer is still down
        volumeCtrl.updateActiveDevice(
          _remoteDevice(id: 'spk-b', name: 'Speaker B', volume: 19661),
        );
        transport.volumeStreamController.add(
          Uint8List.fromList(
            volume_pb.VolumeResponse(
              volume: 19661,
              activeDeviceConnectStateIdentifier: 'spk-b',
            ).writeToBuffer(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Volume: Speaker B'), findsOneWidget);
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
        expect(find.text('30%'), findsOneWidget);
        expect(transport.setVolumeValues.length, dispatchesBeforeSwitch);

        await gesture.up();
        await tester.pumpAndSettle();

        // Lifting pointer after switch must NOT dispatch Speaker A's abandoned drag value
        expect(transport.setVolumeValues.length, dispatchesBeforeSwitch);
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
      },
    );

    testWidgets(
      'clears drag state in callback-only mode when callbacks drop to null mid-drag under enabled=null',
      (tester) async {
        final onVolumeNotifier = ValueNotifier<ValueChanged<double>?>(null);
        final onStepNotifier = ValueNotifier<ValueChanged<int>?>(null);
        final initialVolNotifier = ValueNotifier<double>(0.25);
        final recordedVolumes = <double>[];
        final recordedSteps = <int>[];
        addTearDown(() {
          onVolumeNotifier.dispose();
          onStepNotifier.dispose();
          initialVolNotifier.dispose();
        });

        void handleVolume(double v) => recordedVolumes.add(v);
        void handleStep(int dir) => recordedSteps.add(dir);

        onVolumeNotifier.value = handleVolume;
        onStepNotifier.value = handleStep;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: ValueListenableBuilder<ValueChanged<double>?>(
                    valueListenable: onVolumeNotifier,
                    builder: (context, onVol, _) {
                      return ValueListenableBuilder<ValueChanged<int>?>(
                        valueListenable: onStepNotifier,
                        builder: (context, onStep, _) {
                          return ValueListenableBuilder<double>(
                            valueListenable: initialVolNotifier,
                            builder: (context, initialVol, _) {
                              return ConnectVolumeSlider(
                                onVolumeChanged: onVol,
                                onStepVolume: onStep,
                                initialVolume: initialVol,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(140, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.75));
        expect(recordedVolumes, isNotEmpty);

        // Case 1: Both callbacks drop to null mid-drag under enabled=null
        onVolumeNotifier.value = null;
        onStepNotifier.value = null;
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);
        expect(find.text('Unavailable'), findsOneWidget);

        await gesture.up();
        await tester.pump();

        initialVolNotifier.value = 0.30;
        onVolumeNotifier.value = handleVolume;
        onStepNotifier.value = handleStep;
        await tester.pump();

        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
        expect(find.text('30%'), findsOneWidget);

        // Case 2: Only onVolumeChanged drops to null while onStepVolume remains active
        final gesture2 = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture2.moveBy(const Offset(140, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.75));

        onVolumeNotifier.value = null;
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey<String>('volume_step_up_button')),
              )
              .onPressed,
          isNotNull,
        );

        await gesture2.up();
        await tester.pump();

        initialVolNotifier.value = 0.40;
        onVolumeNotifier.value = handleVolume;
        await tester.pump();

        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.40, 0.02));
        expect(find.text('40%'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves StreamBuilder stream identity and active drag value across rapid parent rebuilds',
      (tester) async {
        final transport = _VolumeFakeTransport();
        final volumeCtrl = RemoteVolumeController(
          volumeClient: ConnectVolumeServiceClient(transport),
          throttleWindow: Duration.zero,
          suppressionWindow: Duration.zero,
          localDebounceWindow: Duration.zero,
        );
        final rebuildTick = ValueNotifier<int>(0);
        addTearDown(() async {
          rebuildTick.dispose();
          await volumeCtrl.dispose();
          await transport.close();
        });

        volumeCtrl.updateActiveDevice(_remoteDevice(id: 'sonos-1', volume: 32768));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: ValueListenableBuilder<int>(
                    valueListenable: rebuildTick,
                    builder: (context, tick, _) {
                      return ConnectVolumeSlider(volumeController: volumeCtrl);
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final streamBuilderFinder =
            find.byType(StreamBuilder<ConnectVolumeState>);
        final initialStream = tester
            .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
            .stream;
        final initialStreamState = tester.state(streamBuilderFinder);

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(90, 0));
        await tester.pump();
        final draggedValue = tester.widget<Slider>(sliderFinder).value;
        expect(draggedValue, greaterThan(0.60));

        for (var i = 1; i <= 5; i++) {
          rebuildTick.value = i;
          await tester.pump();
          expect(
            identical(
              tester
                  .widget<StreamBuilder<ConnectVolumeState>>(streamBuilderFinder)
                  .stream,
              initialStream,
            ),
            isTrue,
          );
          expect(
            identical(tester.state(streamBuilderFinder), initialStreamState),
            isTrue,
          );
          expect(
            tester.widget<Slider>(sliderFinder).value,
            closeTo(draggedValue, 0.001),
          );
        }

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
