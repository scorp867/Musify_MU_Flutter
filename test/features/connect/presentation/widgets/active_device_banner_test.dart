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
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/widgets/active_device_banner.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

final class _BannerFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();
  Completer<Uint8List>? transferCompleter;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    if (method == 'Transfer') {
      if (transferCompleter case final completer?) {
        return completer.future;
      }
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

ConnectDevice _makeDevice({
  required String id,
  required String name,
  DeviceType type = DeviceType.speaker,
  String? connectStateIdentifier,
  String? localIdentifier,
  bool isSelf = false,
  bool isActive = false,
}) {
  final resolvedConnectId = switch (connectStateIdentifier) {
    final value? => value,
    null => id,
  };
  final resolvedLocalId = switch (localIdentifier) {
    final value? => value,
    null => 'local-$id',
  };
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
    brandDisplayName: '',
    modelDisplayName: '',
    localIdentifier: resolvedLocalId,
    connectStateIdentifier: resolvedConnectId,
    name: name,
    state: ConnectDeviceState.loggedIn,
    type: type,
    incarnations: const [],
    volume: 32768,
    isNewlyDiscovered: false,
    isDisabled: false,
    capabilities: const [],
    hifi: const ConnectHifiStatus(
      fullySupported: false,
      userEligible: false,
      deviceSupported: false,
    ),
    volumeSteps: 64,
    isVoiceEnabled: false,
    isLocal: isSelf,
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

  group('ActiveDeviceBanner', () {
    testWidgets('hides on local built-in speaker when showWhenLocalBuiltIn is false', (
      tester,
    ) async {
      final selfPhone = _makeDevice(
        id: 'self-1',
        name: 'My Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              activeSelfPeripheral: null,
              showWhenLocalBuiltIn: false,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows built-in speaker fallback when showWhenLocalBuiltIn is true and peripheral is null', (
      tester,
    ) async {
      final selfComputer = _makeDevice(
        id: 'self-pc',
        name: 'Workstation',
        type: DeviceType.computer,
        isSelf: true,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfComputer,
              selfDevice: selfComputer,
              activeSelfPeripheral: null,
              showWhenLocalBuiltIn: true,
            ),
          ),
        ),
      );

      expect(find.text('Listening on This computer'), findsOneWidget);
      expect(find.byIcon(Icons.computer_rounded), findsOneWidget);
    });

    testWidgets('renders Spotify Connect green banner for remote active device and fires onTap', (
      tester,
    ) async {
      var tapCount = 0;
      final speaker = _makeDevice(
        id: 'spk-1',
        name: 'Studio Monitor',
        type: DeviceType.speaker,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: speaker,
              compact: true,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text('Listening on Studio Monitor'),
      );
      expect(textWidget.style?.color, kSpotifyConnectGreen);

      await tester.tap(find.text('Listening on Studio Monitor'));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('renders external Bluetooth peripheral and TransferInProgress states', (
      tester,
    ) async {
      final selfPhone = _makeDevice(
        id: 'self-1',
        name: 'Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );
      final bt = LocalAudioPeripheral(
        id: 'bt-1',
        name: 'AirPods Pro',
        isActive: true,
        connectionType: OutputPeripheralConnectionType.bluetooth,
        category: OutputPeripheralCategory.headphones,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              activeSelfPeripheral: bt,
            ),
          ),
        ),
      );

      expect(find.text('Listening on AirPods Pro'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              transferState: TransferInProgress(
                targetDeviceId: 'self-1',
                phase: TransferPhase.transferring,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connecting to This phone...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('reactively updates when bound to ConnectMobiusController', (
      tester,
    ) async {
      final transport = _BannerFakeTransport();
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              controller: controller,
              showWhenLocalBuiltIn: false,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);

      transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: [
              connect_pb.StateResponse_Device(
                isSelf: false,
                isActive: true,
                isLocal: true,
                connectStateIdentifier: 'avr-1',
                localIdentifier: 'local-avr-1',
                name: 'Denon AVR',
                state: 'LOGGED_IN',
                type: 'AVR',
                volume: 32768,
                volumeSteps: 64,
                supportsVolume: true,
                capabilities: '[]',
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listening on Denon AVR'), findsOneWidget);
      expect(find.byIcon(Icons.surround_sound_rounded), findsOneWidget);
    });

    testWidgets('resolves inactive remote target name from devices prop during TransferInProgress', (
      tester,
    ) async {
      final selfPhone = _makeDevice(
        id: 'self-1',
        name: 'Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );
      final remoteSpeaker = _makeDevice(
        id: 'spk-2',
        name: 'Kitchen Sonos',
        type: DeviceType.speaker,
        isActive: false,
      );
      final zeroconfSpeaker = _makeDevice(
        id: 'zc-ignored',
        connectStateIdentifier: '',
        localIdentifier: 'zc-speaker-7',
        name: 'Office Cast',
        type: DeviceType.castAudio,
        isActive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              devices: <ConnectDevice>[selfPhone, remoteSpeaker, zeroconfSpeaker],
              transferState: TransferInProgress(
                targetDeviceId: 'spk-2',
                phase: TransferPhase.transferring,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connecting to Kitchen Sonos...'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              devices: <ConnectDevice>[selfPhone, remoteSpeaker, zeroconfSpeaker],
              transferState: TransferInProgress(
                targetDeviceId: 'zc-speaker-7',
                phase: TransferPhase.transferring,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connecting to Office Cast...'), findsOneWidget);
    });

    testWidgets('resolves inactive remote target name via bound ConnectMobiusController on TransferToDeviceRequested', (
      tester,
    ) async {
      final transport = _BannerFakeTransport();
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              controller: controller,
              showWhenLocalBuiltIn: false,
            ),
          ),
        ),
      );

      transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: [
              connect_pb.StateResponse_Device(
                isSelf: true,
                isActive: true,
                isLocal: true,
                connectStateIdentifier: 'self-1',
                localIdentifier: 'local-self-1',
                name: 'Phone',
                state: 'LOGGED_IN',
                type: 'SMARTPHONE',
                volume: 32768,
                volumeSteps: 64,
                supportsVolume: true,
                capabilities: '[]',
              ),
              connect_pb.StateResponse_Device(
                isSelf: false,
                isActive: false,
                isLocal: false,
                connectStateIdentifier: 'spk-2',
                localIdentifier: 'local-spk-2',
                name: 'Kitchen Sonos',
                state: 'LOGGED_IN',
                type: 'SPEAKER',
                volume: 32768,
                volumeSteps: 64,
                supportsVolume: true,
                capabilities: '[]',
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsNothing);

      final transferCompleter = Completer<Uint8List>();
      transport.transferCompleter = transferCompleter;
      addTearDown(() {
        if (!transferCompleter.isCompleted) {
          transferCompleter.complete(Uint8List(0));
        }
      });

      controller.dispatch(
        TransferToDeviceRequested(deviceIdentifier: 'spk-2'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Connecting to Kitchen Sonos...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      transferCompleter.complete(Uint8List(0));
      await tester.pumpAndSettle();
    });

    testWidgets('treats kBuiltInSpeakerPeripheralId with unknown connectionType as local built-in speaker', (
      tester,
    ) async {
      final selfPhone = _makeDevice(
        id: 'self-1',
        name: 'Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );
      final builtInUnknownType = LocalAudioPeripheral(
        id: kBuiltInSpeakerPeripheralId,
        name: kBuiltInSpeakerPeripheralId,
        isActive: true,
        connectionType: OutputPeripheralConnectionType.unknown,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              activeSelfPeripheral: builtInUnknownType,
              showWhenLocalBuiltIn: false,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActiveDeviceBanner(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              activeSelfPeripheral: builtInUnknownType,
              showWhenLocalBuiltIn: true,
            ),
          ),
        ),
      );

      expect(find.text('Listening on This phone'), findsOneWidget);
    });
  });
}
