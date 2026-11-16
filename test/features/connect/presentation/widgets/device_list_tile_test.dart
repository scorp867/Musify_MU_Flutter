import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';

ConnectDevice _buildDevice({
  String id = 'dev-1',
  String localId = 'local-1',
  String name = 'Living Room Speaker',
  String brandDisplayName = 'Brand',
  DeviceType type = DeviceType.speaker,
  ConnectDeviceState state = ConnectDeviceState.loggedIn,
  bool isSelf = false,
  bool isActive = false,
  bool isBeingActivated = false,
  bool isDisabled = false,
  bool isGroup = false,
  bool supportsLogout = true,
  bool hifiSupported = false,
  OutputPeripheral? outputPeripheral,
}) {
  return ConnectDevice(
    isSelf: isSelf,
    isActive: isActive,
    isBeingActivated: isBeingActivated,
    isWebapp: false,
    isZeroconf: false,
    isGroup: isGroup,
    isSocialConnect: false,
    supportsLogout: supportsLogout,
    supportsVolume: true,
    supportsRename: false,
    creationTimeMs: 0,
    brandDisplayName: brandDisplayName,
    modelDisplayName: 'Model X',
    localIdentifier: localId,
    connectStateIdentifier: id,
    name: name,
    state: state,
    type: type,
    incarnations: const [],
    volume: 32768,
    isNewlyDiscovered: false,
    isDisabled: isDisabled,
    capabilities: const [],
    hifi: ConnectHifiStatus(
      fullySupported: hifiSupported,
      userEligible: hifiSupported,
      deviceSupported: hifiSupported,
    ),
    outputPeripheral: outputPeripheral,
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

String _expectedStateSubtitle(ConnectDeviceState state) {
  switch (state) {
    case ConnectDeviceState.connecting:
      return 'Connecting...';
    case ConnectDeviceState.incompatible:
      return 'Incompatible version';
    case ConnectDeviceState.unavailable:
      return 'Unavailable';
    case ConnectDeviceState.loggedIn:
      return 'Brand';
    case ConnectDeviceState.notLoggedIn:
      return 'Tap to connect';
    case ConnectDeviceState.premiumRequired:
      return 'Premium required';
    case ConnectDeviceState.notInstalled:
      return 'Spotify not installed';
    case ConnectDeviceState.unsupportedUri:
      return 'Track unsupported';
    case ConnectDeviceState.sleeping:
      return 'Sleeping - tap to wake';
    case ConnectDeviceState.notAuthorized:
      return 'Not authorized';
    case ConnectDeviceState.adPlaying:
      return 'Ad is playing';
    case ConnectDeviceState.narration:
      return 'Narration playing';
    case ConnectDeviceState.timedOutWakeup:
      return 'Wake-up timed out';
    case ConnectDeviceState.wakingUp:
      return 'Waking up...';
    case ConnectDeviceState.notLoaded:
      return 'Ready to connect';
    case ConnectDeviceState.wol:
      return 'Tap to wake';
    case ConnectDeviceState.busy:
      return 'Device is busy';
    case ConnectDeviceState.installationAvailable:
      return 'Tap to install Spotify';
    case ConnectDeviceState.installing:
      return 'Installing Spotify...';
    case ConnectDeviceState.managedAccountOnDisallowedDevice:
      return 'Unavailable for managed account';
    case ConnectDeviceState.unsupportedVersion:
      return 'Unsupported version';
    case ConnectDeviceState.unknown:
      return 'Brand';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceListTile and visual helpers', () {
    test('resolveBuiltInSpeakerLabel handles null and all DeviceType variants', () {
      expect(resolveBuiltInSpeakerLabel(null), 'This device');
      expect(resolveBuiltInSpeakerLabel(DeviceType.chromebook), 'This Chromebook');
      expect(resolveBuiltInSpeakerLabel(DeviceType.computer), 'This computer');
      expect(resolveBuiltInSpeakerLabel(DeviceType.tablet), 'This tablet');
      expect(resolveBuiltInSpeakerLabel(DeviceType.smartphone), 'This phone');
      for (final type in DeviceType.values) {
        expect(resolveBuiltInSpeakerLabel(type), isNotEmpty);
      }
    });

    test('resolveDeviceTypeIcon and resolvePeripheralIcon map every enum variant', () {
      for (final type in DeviceType.values) {
        expect(resolveDeviceTypeIcon(type), isA<IconData>());
      }
      for (final conn in OutputPeripheralConnectionType.values) {
        expect(resolvePeripheralIcon(conn), isA<IconData>());
        for (final cat in OutputPeripheralCategory.values) {
          expect(
            resolvePeripheralIcon(conn, category: cat),
            isA<IconData>(),
          );
        }
      }
    });

    testWidgets('self device with null peripheral falls back to built-in speaker label', (
      tester,
    ) async {
      final selfChromebook = _buildDevice(
        id: 'self-1',
        name: 'My Chromebook',
        type: DeviceType.chromebook,
        isSelf: true,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DeviceListTile(
              device: selfChromebook,
              activeSelfPeripheral: null,
            ),
          ),
        ),
      );

      expect(find.text('My Chromebook'), findsOneWidget);
      expect(find.text('This Chromebook'), findsOneWidget);
      expect(find.byIcon(Icons.laptop_chromebook_rounded), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
    });

    testWidgets('self device with Bluetooth headphones peripheral displays peripheral name and icon', (
      tester,
    ) async {
      final selfPhone = _buildDevice(
        id: 'self-2',
        name: 'Pixel 9',
        type: DeviceType.smartphone,
        isSelf: true,
        isActive: true,
      );
      final btPeripheral = LocalAudioPeripheral(
        id: 'bt-1',
        name: 'WH-1000XM5',
        isActive: true,
        isConnected: true,
        connectionType: OutputPeripheralConnectionType.bluetooth,
        category: OutputPeripheralCategory.headphones,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DeviceListTile(
              device: selfPhone,
              activeSelfPeripheral: btPeripheral,
            ),
          ),
        ),
      );

      expect(find.text('WH-1000XM5'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
    });

    testWidgets('renders HiFi, Group, Suggested badges and handles tap/logout/install/addToGroup', (
      tester,
    ) async {
      var tapped = 0;
      var loggedOut = 0;
      var installed = 0;
      var addedToGroup = 0;

      final device = _buildDevice(
        id: 'tv-1',
        name: 'Living Room TV',
        type: DeviceType.tv,
        state: ConnectDeviceState.notInstalled,
        isGroup: true,
        supportsLogout: true,
        hifiSupported: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DeviceListTile(
              device: device,
              isRecommended: true,
              onTap: () => tapped++,
              onLogout: () => loggedOut++,
              onInstall: () => installed++,
              onAddToGroup: () => addedToGroup++,
            ),
          ),
        ),
      );

      expect(find.text('Living Room TV'), findsOneWidget);
      expect(find.text('Spotify not installed'), findsOneWidget);
      expect(find.text('HiFi'), findsOneWidget);
      expect(find.text('Group'), findsOneWidget);
      expect(find.text('Suggested'), findsOneWidget);

      await tester.tap(find.text('Living Room TV'));
      await tester.pump();
      expect(tapped, 1);

      await tester.tap(find.byTooltip('Install Spotify'));
      await tester.pump();
      expect(installed, 1);

      await tester.tap(find.byTooltip('Add Living Room TV to speaker group'));
      await tester.pump();
      expect(addedToGroup, 1);

      await tester.tap(find.byTooltip('Device options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(loggedOut, 1);
    });

    testWidgets('disabled or offline device ignores taps', (tester) async {
      var tapped = 0;
      final offlineDevice = _buildDevice(
        id: 'offline-1',
        name: 'Kitchen Speaker',
        state: ConnectDeviceState.unavailable,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DeviceListTile(
              device: offlineDevice,
              onTap: () => tapped++,
            ),
          ),
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
      await tester.tap(find.text('Kitchen Speaker'));
      await tester.pump();
      expect(tapped, 0);
    });

    testWidgets('shows transfer progress and install progress subtitles', (
      tester,
    ) async {
      final speaker = _buildDevice(
        id: 'spk-1',
        name: 'Bedroom Speaker',
        state: ConnectDeviceState.loggedIn,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DeviceListTile(
              device: speaker,
              transferState: TransferInProgress(
                targetDeviceId: 'spk-1',
                phase: TransferPhase.becomingActive,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Starting playback...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DeviceListTile(
              device: speaker,
              isInstallingThisDevice: true,
              installSpotifyState:
                  connect_pb.InstallSpotifyState.WAITING_FOR_APP_TO_BE_INSTALLED,
            ),
          ),
        ),
      );

      expect(find.text('Installing Spotify...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders subtitles for all 22 ConnectDeviceState and all InstallSpotifyState values', (
      tester,
    ) async {
      expect(ConnectDeviceState.values.length, 22);

      for (final state in ConnectDeviceState.values) {
        final device = _buildDevice(state: state);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DeviceListTile(device: device),
            ),
          ),
        );
        expect(find.text(_expectedStateSubtitle(state)), findsOneWidget);
      }

      // Active loggedIn and empty-brand fallbacks
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                DeviceListTile(
                  device: _buildDevice(
                    id: 'active-logged-in',
                    state: ConnectDeviceState.loggedIn,
                    isActive: true,
                  ),
                ),
                DeviceListTile(
                  device: _buildDevice(
                    id: 'empty-brand-logged-in',
                    state: ConnectDeviceState.loggedIn,
                    brandDisplayName: '',
                  ),
                ),
                DeviceListTile(
                  device: _buildDevice(
                    id: 'empty-brand-unknown',
                    state: ConnectDeviceState.unknown,
                    brandDisplayName: '',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Active device'), findsOneWidget);
      expect(find.text('Spotify Connect'), findsOneWidget);
      expect(find.text('Connect device'), findsOneWidget);

      for (final installState in connect_pb.InstallSpotifyState.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DeviceListTile(
                device: _buildDevice(state: ConnectDeviceState.notInstalled),
                isInstallingThisDevice: true,
                installSpotifyState: installState,
              ),
            ),
          ),
        );
        expect(
          find.text(resolveInstallSpotifyStatusLabel(installState)),
          findsOneWidget,
        );
      }
    });

    testWidgets('renders all 3 badges and trailing controls without overflow at 320dp width', (
      tester,
    ) async {
      final device = _buildDevice(
        id: 'tv-narrow',
        name: 'Very Long Living Room Television Name',
        type: DeviceType.tv,
        state: ConnectDeviceState.notInstalled,
        isBeingActivated: true,
        isGroup: true,
        supportsLogout: true,
        hifiSupported: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 288,
                child: DeviceListTile(
                  device: device,
                  isRecommended: true,
                  onTap: () {},
                  onLogout: () {},
                  onInstall: () {},
                  onAddToGroup: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('HiFi'), findsOneWidget);
      expect(find.text('Group'), findsOneWidget);
      expect(find.text('Suggested'), findsOneWidget);
      expect(find.byTooltip('Install Spotify'), findsOneWidget);
      expect(
        find.byTooltip('Add Very Long Living Room Television Name to speaker group'),
        findsOneWidget,
      );
      expect(find.byTooltip('Device options'), findsOneWidget);
    });

    testWidgets('hides install button when device is disabled or offline', (
      tester,
    ) async {
      final disabledDevice = _buildDevice(
        id: 'dev-1',
        name: 'Disabled TV',
        type: DeviceType.tv,
        state: ConnectDeviceState.notInstalled,
        isDisabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DeviceListTile(
              device: disabledDevice,
              onInstall: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Install Spotify'), findsNothing);
      expect(find.byKey(const ValueKey<String>('install_dev-1')), findsNothing);
    });
  });
}
