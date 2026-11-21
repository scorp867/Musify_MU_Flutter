import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_device_label.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_entrypoint_button.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_state_icon.dart';
import 'package:musify_mu/features/connect/presentation/widgets/playing_equalizer_indicator.dart';

ConnectDevice _device({
  String id = 'dev-1',
  String name = 'Studio Speaker',
  bool isSelf = false,
  bool isActive = false,
  bool isGroup = false,
  DeviceType type = DeviceType.speaker,
  List<Incarnation> incarnations = const [],
  OutputPeripheral? outputPeripheral,
}) {
  return ConnectDevice(
    isSelf: isSelf,
    isActive: isActive,
    isBeingActivated: false,
    isWebapp: false,
    isZeroconf: false,
    isGroup: isGroup,
    isSocialConnect: false,
    supportsLogout: !isSelf,
    supportsVolume: true,
    supportsRename: !isSelf,
    creationTimeMs: 0,
    brandDisplayName: 'Sonos',
    modelDisplayName: 'Era 100',
    localIdentifier: 'local-$id',
    connectStateIdentifier: id,
    name: name,
    state: ConnectDeviceState.loggedIn,
    type: type,
    incarnations: incarnations,
    volume: 32768,
    isNewlyDiscovered: false,
    isDisabled: false,
    capabilities: const [],
    hifi: const ConnectHifiStatus(
      fullySupported: false,
      userEligible: false,
      deviceSupported: false,
    ),
    outputPeripheral: outputPeripheral,
    volumeSteps: 24,
    isVoiceEnabled: false,
    isLocal: true,
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

  group('ConnectEncoreIcons byte-exact vector parsing', () {
    final allVectors = <EncoreVectorIconData>[
      ConnectEncoreIcons.devices16,
      ConnectEncoreIcons.devices24,
      ConnectEncoreIcons.deviceMobile16,
      ConnectEncoreIcons.deviceMobile24,
      ConnectEncoreIcons.deviceComputer16,
      ConnectEncoreIcons.deviceComputer24,
      ConnectEncoreIcons.deviceTablet16,
      ConnectEncoreIcons.deviceTablet24,
      ConnectEncoreIcons.deviceSpeaker16,
      ConnectEncoreIcons.deviceSpeaker24,
      ConnectEncoreIcons.deviceTv16,
      ConnectEncoreIcons.deviceTv24,
      ConnectEncoreIcons.deviceArm16,
      ConnectEncoreIcons.deviceArm24,
      ConnectEncoreIcons.deviceCar16,
      ConnectEncoreIcons.deviceCar24,
      ConnectEncoreIcons.deviceOther16,
      ConnectEncoreIcons.deviceOther24,
      ConnectEncoreIcons.deviceMultispeaker16,
      ConnectEncoreIcons.deviceMultispeaker24,
      ConnectEncoreIcons.deviceSmartGlasses16,
      ConnectEncoreIcons.deviceSmartGlasses24,
      ConnectEncoreIcons.gamesConsole16,
      ConnectEncoreIcons.gamesConsole24,
      ConnectEncoreIcons.watch16,
      ConnectEncoreIcons.watch24,
      ConnectEncoreIcons.headphones16,
      ConnectEncoreIcons.headphones24,
      ConnectEncoreIcons.headphonesOptimize16,
      ConnectEncoreIcons.bluetooth16,
      ConnectEncoreIcons.bluetooth24,
      ConnectEncoreIcons.airPlay16,
      ConnectEncoreIcons.airPlay24,
      ConnectEncoreIcons.chromecastDisconnected16,
      ConnectEncoreIcons.chromecastDisconnected24,
      ConnectEncoreIcons.chromecastConnected16,
      ConnectEncoreIcons.chromecastConnected24,
      ConnectEncoreIcons.spotifyConnect16,
      ConnectEncoreIcons.spotifyConnect24,
      ConnectEncoreIcons.volumeOneWave16,
      ConnectEncoreIcons.volumeOneWave24,
      ConnectEncoreIcons.volume16,
      ConnectEncoreIcons.volume24,
      ConnectEncoreIcons.volumeOff16,
      ConnectEncoreIcons.volumeOff24,
      ConnectEncoreIcons.more16,
      ConnectEncoreIcons.more24,
      ConnectEncoreIcons.moreAndroid16,
      ConnectEncoreIcons.moreAndroid24,
      ConnectEncoreIcons.chevronDown16,
      ConnectEncoreIcons.chevronUp16,
      ConnectEncoreIcons.chevronRight16,
      ConnectEncoreIcons.checkAlt16,
      ConnectEncoreIcons.checkAlt24,
      ConnectEncoreIcons.checkAltFill16,
      ConnectEncoreIcons.checkAltFill24,
      ConnectEncoreIcons.plusAlt16,
      ConnectEncoreIcons.plusAlt24,
      ConnectEncoreIcons.play24,
      ConnectEncoreIcons.pause24,
      ConnectEncoreIcons.queue24,
      ConnectEncoreIcons.queueBadge16,
      ConnectEncoreIcons.queueBadge24,
      ConnectEncoreIcons.enhanceBadge16,
      ConnectEncoreIcons.enhanceBadge24,
      ConnectEncoreIcons.exclamationCircle16,
      ConnectEncoreIcons.exclamationCircle24,
      ConnectEncoreIcons.spotifyLogo16,
    ];

    testWidgets('every extracted Spotify Encore vector paints cleanly with zero exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final icon in allVectors)
                    ConnectEncoreIcon(
                      key: ValueKey<String>('vec_${icon.id}'),
                      icon: icon,
                      size: icon.viewportSize,
                      color: ConnectEncoreTheme.textBase,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(ConnectEncoreIcon), findsNWidgets(allVectors.length));
    });

    test('resolveDeviceTypeEncoreIcon and resolvePeripheralEncoreIcon handle every enum value', () {
      for (final type in DeviceType.values) {
        final pair = resolveDeviceTypeEncoreIcon(type);
        expect(pair.small16.paths, isNotEmpty);
        expect(pair.medium24.paths, isNotEmpty);
      }
      for (final category in OutputPeripheralCategory.values) {
        for (final conn in OutputPeripheralConnectionType.values) {
          final pair = resolvePeripheralEncoreIcon(
            category: category,
            connectionType: conn,
          );
          expect(pair.small16.paths, isNotEmpty);
        }
      }
      expect(
        resolveDeviceTypeEncoreIcon(DeviceType.speaker, isGroup: true),
        equals(ConnectEncoreIcons.deviceMultispeaker),
      );
      expect(
        resolveDeviceTypeEncoreIcon(DeviceType.castAudio, isCastConnected: true),
        equals(ConnectEncoreIcons.chromecastConnected),
      );
      expect(
        resolveDeviceTypeEncoreIcon(DeviceType.castVideo, isCastConnected: false),
        equals(ConnectEncoreIcons.chromecastDisconnected),
      );
    });
  });

  group('ConnectStateIcon, ConnectDeviceLabel & ConnectEntrypointButton', () {
    test('resolveConnectIconState and resolveConnectLabelState cover all 4 u7k states', () {
      final selfDev = _device(
        id: 'self-1',
        name: 'Phone',
        isSelf: true,
        isActive: true,
        type: DeviceType.smartphone,
      );
      final remoteCast = _device(
        id: 'cast-1',
        name: 'Living Room TV',
        isSelf: false,
        isActive: true,
        type: DeviceType.castVideo,
      );

      final idleState = ConnectState.initial().copyWith(
        devices: [selfDev],
        activeDevice: selfDev,
        selfDevice: selfDev,
      );
      expect(resolveConnectIconState(idleState, isDisabled: true), isA<ConnectIconDisabled>());
      expect(resolveConnectIconState(idleState), isA<ConnectIconIdle>());
      expect(resolveConnectLabelState(idleState), isA<ConnectLabelIdle>());

      final connectingState = ConnectState.initial().copyWith(
        devices: [selfDev, remoteCast],
        activeDevice: selfDev,
        selfDevice: selfDev,
        transferState: TransferInProgress(
          targetDeviceId: 'cast-1',
          phase: TransferPhase.transferring,
        ),
      );
      final connectingIcon = resolveConnectIconState(connectingState);
      expect(connectingIcon, isA<ConnectIconConnecting>());
      expect(
        (connectingIcon as ConnectIconConnecting).icon,
        equals(ConnectEncoreIcons.chromecastDisconnected),
      );
      expect(
        resolveConnectLabelState(connectingState),
        equals(const ConnectLabelConnecting(text: 'Connecting...')),
      );

      final activeCastState = ConnectState.initial().copyWith(
        devices: [selfDev, remoteCast],
        activeDevice: remoteCast,
        selfDevice: selfDev,
      );
      final activeIcon = resolveConnectIconState(activeCastState);
      expect(activeIcon, isA<ConnectIconActive>());
      expect(
        (activeIcon as ConnectIconActive).icon,
        equals(ConnectEncoreIcons.chromecastConnected),
      );
      expect(
        resolveConnectLabelState(activeCastState),
        equals(
          const ConnectLabelActive(
            text: 'Living Room TV',
            badge: ConnectLabelBadge.chromecast,
          ),
        ),
      );
    });

    testWidgets('ConnectStateIcon pulses during ConnectIconConnecting and stops cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectStateIcon(
              iconState: ConnectIconConnecting(icon: ConnectEncoreIcons.deviceSpeaker),
              highlightActive: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final iconFadeFinder = find.descendant(
        of: find.byType(ConnectStateIcon),
        matching: find.byType(FadeTransition),
      );
      expect(iconFadeFinder, findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectStateIcon(
              iconState: ConnectIconActive(icon: ConnectEncoreIcons.deviceSpeaker),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(iconFadeFinder, findsNothing);
    });

    testWidgets('ConnectEntrypointButton renders icon + inline label and fires onPressed', (
      tester,
    ) async {
      var tapped = false;
      final remote = _device(
        id: 'spk-1',
        name: 'Office Sonos',
        isSelf: false,
        isActive: true,
      );
      final state = ConnectState.initial().copyWith(
        devices: [remote],
        activeDevice: remote,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ConnectEntrypointButton(
              connectState: state,
              showHighlightPill: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Office Sonos'), findsOneWidget);
      await tester.tap(find.byType(ConnectEntrypointButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('PlayingEqualizerIndicator animates while playing and settles cleanly when paused', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayingEqualizerIndicator(isPlaying: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PlayingEqualizerIndicator), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayingEqualizerIndicator(isPlaying: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
