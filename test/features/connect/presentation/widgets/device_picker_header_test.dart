import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_header.dart';

ConnectDevice _device({
  required String id,
  required String name,
  required DeviceType type,
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

  group('DevicePickerHeader', () {
    testWidgets('uses built-in speaker fallback when activeSelfPeripheral is null', (
      tester,
    ) async {
      final selfTablet = _device(
        id: 'self-tab',
        name: 'Galaxy Tab',
        type: DeviceType.tablet,
        isSelf: true,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerHeader(
              activeDevice: selfTablet,
              selfDevice: selfTablet,
              activeSelfPeripheral: null,
            ),
          ),
        ),
      );

      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Listening on This tablet'), findsOneWidget);
      expect(find.byIcon(Icons.tablet_android_rounded), findsOneWidget);
    });

    testWidgets('uses "This device" fallback when both activeDevice and selfDevice are null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: DevicePickerHeader(
              activeDevice: null,
              selfDevice: null,
              activeSelfPeripheral: null,
              isSyncedWithBackend: true,
            ),
          ),
        ),
      );

      expect(find.text('Listening on This device'), findsOneWidget);
    });

    testWidgets('shows remote active device name and wires refresh/close callbacks', (
      tester,
    ) async {
      var refreshCount = 0;
      var closeCount = 0;
      final remoteTv = _device(
        id: 'tv-99',
        name: 'Living Room TV',
        type: DeviceType.tv,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerHeader(
              activeDevice: remoteTv,
              onRefresh: () => refreshCount++,
              onClose: () => closeCount++,
            ),
          ),
        ),
      );

      expect(find.text('Listening on Living Room TV'), findsOneWidget);
      expect(find.byIcon(Icons.tv_rounded), findsOneWidget);

      await tester.tap(find.byTooltip('Refresh devices'));
      await tester.pump();
      expect(refreshCount, 1);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('shows Bluetooth peripheral and TransferInProgress status', (
      tester,
    ) async {
      final selfPhone = _device(
        id: 'self-1',
        name: 'Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );
      final speaker = _device(
        id: 'spk-2',
        name: 'Kitchen Sonos',
        type: DeviceType.speaker,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerHeader(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              activeSelfPeripheral: LocalAudioPeripheral(
                id: 'bt-buds',
                name: 'Pixel Buds',
                isActive: true,
                connectionType: OutputPeripheralConnectionType.bluetooth,
                category: OutputPeripheralCategory.headphones,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Listening on Pixel Buds'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerHeader(
              activeDevice: speaker,
              selfDevice: selfPhone,
              transferState: TransferInProgress(
                targetDeviceId: 'spk-2',
                phase: TransferPhase.transferring,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connecting to Kitchen Sonos...'), findsOneWidget);
    });

    testWidgets('resolves inactive remote target name from devices during TransferInProgress', (
      tester,
    ) async {
      final selfPhone = _device(
        id: 'self-1',
        name: 'Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );
      final speaker = _device(
        id: 'spk-2',
        name: 'Kitchen Sonos',
        type: DeviceType.speaker,
        isActive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerHeader(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              devices: <ConnectDevice>[selfPhone, speaker],
              transferState: TransferInProgress(
                targetDeviceId: 'spk-2',
                phase: TransferPhase.transferring,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connecting to Kitchen Sonos...'), findsOneWidget);
      expect(find.text('Connecting to device...'), findsNothing);
    });

    testWidgets('resolves inactive remote target name by localIdentifier during TransferInProgress', (
      tester,
    ) async {
      final selfPhone = _device(
        id: 'self-1',
        name: 'Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );
      final zeroconfSpeaker = _device(
        id: 'zc-ignored',
        connectStateIdentifier: '',
        localIdentifier: 'zc-local-9',
        name: 'Bedroom HomePod',
        type: DeviceType.speaker,
        isActive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerHeader(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              devices: <ConnectDevice>[selfPhone, zeroconfSpeaker],
              transferState: TransferInProgress(
                targetDeviceId: 'zc-local-9',
                phase: TransferPhase.transferring,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connecting to Bedroom HomePod...'), findsOneWidget);
    });

    testWidgets('falls back to device label when TransferInProgress target is missing from devices', (
      tester,
    ) async {
      final selfPhone = _device(
        id: 'self-1',
        name: 'Phone',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerHeader(
              activeDevice: selfPhone,
              selfDevice: selfPhone,
              devices: <ConnectDevice>[selfPhone],
              transferState: TransferInProgress(
                targetDeviceId: 'unknown-spk',
                phase: TransferPhase.transferring,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connecting to device...'), findsOneWidget);
    });
  });
}
