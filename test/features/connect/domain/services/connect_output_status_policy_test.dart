import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';

ConnectDevice _buildDevice({
  required String id,
  required String name,
  bool isSelf = false,
  bool isActive = false,
  DeviceType type = DeviceType.smartphone,
  String localIdentifier = '',
  OutputPeripheral? outputPeripheral,
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
    creationTimeMs: 1000,
    brandDisplayName: 'Google',
    modelDisplayName: 'Pixel',
    localIdentifier: localIdentifier.isNotEmpty ? localIdentifier : 'local-$id',
    connectStateIdentifier: id,
    name: name,
    state: ConnectDeviceState.loggedIn,
    type: type,
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
    volumeSteps: 32,
    isVoiceEnabled: false,
    isLocal: isSelf,
    localIp: '',
    supportedMediaTypes: const <String>['audio/track'],
    supportsDj: false,
    libraryVersion: '3.2.0',
    supportsRemoteSleepTimer: true,
    supportsPlaylistMixing: true,
    supportsZephyr: true,
    supportsRemoteAudioQualityControl: true,
    discoveryMethod: 0,
    outputPeripheral: outputPeripheral,
  );
}

ConnectState _buildState({
  required List<ConnectDevice> devices,
  List<LocalAudioPeripheral> peripherals = const <LocalAudioPeripheral>[],
  TransferState transferState = const TransferIdle(),
}) {
  final cluster = ConnectCluster(
    isActive: devices.any((d) => d.isActive),
    shouldUseLocalPlayback: devices.any((d) => d.isSelf && d.isActive),
    devices: devices,
    isActiveOnSameDevice: devices.any((d) => d.isSelf && d.isActive),
    isSyncedWithBackend: true,
  );
  return ConnectState.initial()
      .withProjection(
        internal: ConnectInternalState.initial().copyWith(
          isSyncedWithBackend: true,
          rawDevices: devices,
          peripherals: peripherals,
        ),
        cluster: cluster,
      )
      .copyWith(transferState: transferState);
}

void main() {
  const policy = ConnectOutputStatusPolicy.instance;

  group('ConnectOutputStatusPolicy', () {
    test('detects remote active output, external local peripherals, and transfer in progress', () {
      final selfPhone = _buildDevice(
        id: 'self-phone',
        name: 'Pixel 9 Pro',
        isSelf: true,
        isActive: true,
      );
      final remoteSpeaker = _buildDevice(
        id: 'remote-spk',
        name: 'Living Room Sonos',
        isSelf: false,
        isActive: true,
        type: DeviceType.speaker,
      );
      final builtInPeripheral = LocalAudioPeripheral(
        id: kBuiltInSpeakerPeripheralId,
        name: kBuiltInSpeakerPeripheralId,
        isActive: true,
        connectionType: OutputPeripheralConnectionType.builtInSpeaker,
      );
      final btPeripheral = LocalAudioPeripheral(
        id: 'bt-airpods',
        name: 'Sony WH-1000XM5',
        isActive: true,
        connectionType: OutputPeripheralConnectionType.bluetooth,
      );

      // 1) Local built-in phone speaker active, no transfer -> not active, banner hidden by default
      final localBuiltInState = _buildState(
        devices: <ConnectDevice>[selfPhone],
        peripherals: <LocalAudioPeripheral>[builtInPeripheral],
      );
      expect(policy.isRemoteOutputActive(localBuiltInState), isFalse);
      expect(policy.isConnectOutputActive(localBuiltInState), isFalse);
      expect(policy.shouldShowBanner(localBuiltInState), isFalse);
      expect(
        policy.shouldShowBanner(
          localBuiltInState,
          showWhenLocalBuiltIn: true,
        ),
        isTrue,
      );

      // 2) Local phone active with Bluetooth peripheral -> Connect output active, banner shown
      final localBtState = _buildState(
        devices: <ConnectDevice>[selfPhone],
        peripherals: <LocalAudioPeripheral>[builtInPeripheral, btPeripheral],
      );
      expect(policy.isRemoteOutputActive(localBtState), isFalse);
      expect(
        policy.isExternalLocalPeripheral(localBtState.activeSelfPeripheral),
        isTrue,
      );
      expect(policy.isConnectOutputActive(localBtState), isTrue);
      expect(policy.shouldShowBanner(localBtState), isTrue);

      // 3) Remote speaker active -> remote output active, Connect output active, banner shown
      final remoteState = _buildState(
        devices: <ConnectDevice>[
          selfPhone.copyWith(isActive: false),
          remoteSpeaker,
        ],
      );
      expect(policy.isRemoteOutputActive(remoteState), isTrue);
      expect(policy.isConnectOutputActive(remoteState), isTrue);
      expect(policy.shouldShowBanner(remoteState), isTrue);

      // 4) Transfer in progress while still on local built-in -> Connect output active, banner shown
      final transferringState = _buildState(
        devices: <ConnectDevice>[
          selfPhone,
          remoteSpeaker.copyWith(isActive: false),
        ],
        transferState: TransferInProgress(
          targetDeviceId: 'remote-spk',
          phase: TransferPhase.transferring,
        ),
      );
      expect(policy.isConnectOutputActive(transferringState), isTrue);
      expect(policy.shouldShowBanner(transferringState), isTrue);
    });

    test('resolves built-in speaker labels, active output labels, transfer target labels, and banner status text', () {
      expect(policy.resolveBuiltInSpeakerLabel(null), equals('This device'));
      expect(
        policy.resolveBuiltInSpeakerLabel(DeviceType.chromebook),
        equals('This Chromebook'),
      );
      expect(
        policy.resolveBuiltInSpeakerLabel(DeviceType.computer),
        equals('This computer'),
      );
      expect(
        policy.resolveBuiltInSpeakerLabel(DeviceType.tablet),
        equals('This tablet'),
      );
      expect(
        policy.resolveBuiltInSpeakerLabel(DeviceType.smartphone),
        equals('This phone'),
      );

      final selfTablet = _buildDevice(
        id: 'self-tab',
        name: 'Galaxy Tab S9',
        isSelf: true,
        isActive: true,
        type: DeviceType.tablet,
      );
      final remoteSpeaker = _buildDevice(
        id: 'remote-spk',
        name: 'Kitchen Echo',
        isSelf: false,
        isActive: false,
        type: DeviceType.speaker,
        localIdentifier: 'echo-local-id',
      );

      final localTabletState = _buildState(
        devices: <ConnectDevice>[selfTablet, remoteSpeaker],
      );
      expect(
        policy.resolveTargetLabel(localTabletState),
        equals('This tablet'),
      );
      expect(
        policy.resolveBannerStatusText(localTabletState),
        equals('Listening on This tablet'),
      );

      // Explicit targetDeviceId matches by connectStateIdentifier or localIdentifier
      expect(
        policy.resolveTargetLabel(
          localTabletState,
          targetDeviceId: 'echo-local-id',
        ),
        equals('Kitchen Echo'),
      );
      expect(
        policy.resolveTargetLabel(
          localTabletState,
          targetDeviceId: kLocalDeviceIdentifier,
        ),
        equals('This tablet'),
      );
      expect(
        policy.resolveTargetLabel(
          localTabletState,
          targetDeviceId: 'unknown-id',
        ),
        equals('device'),
      );

      // TransferInProgress banner status text
      final transferringToRemote = localTabletState.copyWith(
        transferState: TransferInProgress(
          targetDeviceId: 'remote-spk',
          phase: TransferPhase.transferring,
        ),
      );
      expect(
        policy.resolveBannerStatusText(transferringToRemote),
        equals('Connecting to Kitchen Echo...'),
      );

      // Active Bluetooth peripheral label on local device
      final withBt = _buildState(
        devices: <ConnectDevice>[selfTablet, remoteSpeaker],
        peripherals: <LocalAudioPeripheral>[
          LocalAudioPeripheral(
            id: 'bt-1',
            name: 'Pixel Buds Pro',
            isActive: true,
            connectionType: OutputPeripheralConnectionType.bluetooth,
          ),
        ],
      );
      expect(policy.resolveTargetLabel(withBt), equals('Pixel Buds Pro'));
      expect(
        policy.resolveBannerStatusText(withBt),
        equals('Listening on Pixel Buds Pro'),
      );

      // Remote device active
      final remoteActiveState = _buildState(
        devices: <ConnectDevice>[
          selfTablet.copyWith(isActive: false),
          remoteSpeaker.copyWith(isActive: true),
        ],
      );
      expect(
        policy.resolveTargetLabel(remoteActiveState),
        equals('Kitchen Echo'),
      );
      expect(
        policy.resolveBannerStatusText(remoteActiveState),
        equals('Listening on Kitchen Echo'),
      );
    });
  });
}
