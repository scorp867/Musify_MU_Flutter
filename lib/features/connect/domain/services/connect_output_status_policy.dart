import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

/// Pure domain SSOT policy for Connect output activity detection, active
/// device banner visibility, and target output label resolution (`#47 §5`).
///
/// Unifies the logic previously duplicated across `ActiveDeviceBanner`,
/// `DevicePickerHeader`, `PlayerUtilityRow`, `MiniPlayer`, and `PlayerScreen`.
@immutable
final class ConnectOutputStatusPolicy {
  static const ConnectOutputStatusPolicy instance =
      ConnectOutputStatusPolicy();

  const ConnectOutputStatusPolicy();

  /// Returns `true` when [activeDevice] is an active remote Connect device
  /// (`isActive && !isSelf`).
  bool isRemoteDeviceActive(ConnectDevice? activeDevice) {
    return activeDevice != null && !activeDevice.isSelf;
  }

  /// Returns `true` when [state] has an active remote Connect device.
  bool isRemoteOutputActive(ConnectState state) {
    return isRemoteDeviceActive(state.activeDevice);
  }

  /// Returns `true` when [peripheral] represents an external local audio route
  /// (Bluetooth, wired headphones, USB, CarPlay/Android Auto, AirPlay) rather
  /// than the built-in phone speaker.
  bool isExternalLocalPeripheral(LocalAudioPeripheral? peripheral) {
    return peripheral != null &&
        peripheral.id != kBuiltInSpeakerPeripheralId &&
        peripheral.connectionType !=
            OutputPeripheralConnectionType.builtInSpeaker;
  }

  /// Returns `true` when a Connect transfer is in progress, a remote Connect
  /// device is active, or a non-built-in local audio peripheral (e.g.
  /// Bluetooth or wired headphones) is active (`p199p/qsq.java`).
  bool isConnectOutputActive(ConnectState state) {
    return isConnectOutputActiveForProps(
      activeDevice: state.activeDevice,
      activeSelfPeripheral: state.activeSelfPeripheral,
      transferState: state.transferState,
    );
  }

  /// Property-level overload of [isConnectOutputActive] for widgets that accept
  /// decomposed state fields.
  bool isConnectOutputActiveForProps({
    required ConnectDevice? activeDevice,
    required LocalAudioPeripheral? activeSelfPeripheral,
    required TransferState transferState,
  }) {
    if (transferState is TransferInProgress) {
      return true;
    }
    if (isRemoteDeviceActive(activeDevice)) {
      return true;
    }
    if (isExternalLocalPeripheral(activeSelfPeripheral)) {
      return true;
    }
    return false;
  }

  /// Returns `true` when the green Connect active device banner should be
  /// rendered (`MiniPlayer`, `PlayerScreen`, `ActiveDeviceBanner`).
  bool shouldShowBanner(
    ConnectState state, {
    bool showWhenLocalBuiltIn = false,
  }) {
    return shouldShowBannerForProps(
      activeDevice: state.activeDevice,
      activeSelfPeripheral: state.activeSelfPeripheral,
      transferState: state.transferState,
      showWhenLocalBuiltIn: showWhenLocalBuiltIn,
    );
  }

  /// Property-level overload of [shouldShowBanner] for widgets that accept
  /// decomposed state fields.
  bool shouldShowBannerForProps({
    required ConnectDevice? activeDevice,
    required LocalAudioPeripheral? activeSelfPeripheral,
    required TransferState transferState,
    bool showWhenLocalBuiltIn = false,
  }) {
    if (showWhenLocalBuiltIn) {
      return true;
    }
    return isConnectOutputActiveForProps(
      activeDevice: activeDevice,
      activeSelfPeripheral: activeSelfPeripheral,
      transferState: transferState,
    );
  }

  /// Resolves the display label for the current or target Connect output
  /// device in [state].
  ///
  /// - If [targetDeviceId] is provided, or if [state.transferState] is
  ///   [TransferInProgress], resolves the label of that transfer target.
  /// - Otherwise, if a remote device is active, returns its display name.
  /// - Otherwise returns the active local output peripheral or built-in
  ///   speaker label (`"This phone"`, `"This tablet"`, etc.).
  String resolveTargetLabel(
    ConnectState state, {
    String? targetDeviceId,
  }) {
    final String? effectiveTargetId = switch (targetDeviceId) {
      final explicitId? when explicitId.trim().isNotEmpty => explicitId,
      _ => switch (state.transferState) {
          TransferInProgress(:final targetDeviceId) => targetDeviceId,
          TransferIdle() ||
          TransferSucceeded() ||
          TransferFailed() =>
            null,
        },
    };

    if (effectiveTargetId != null) {
      return resolveTransferTargetLabel(
        targetDeviceId: effectiveTargetId,
        activeDevice: state.activeDevice,
        selfDevice: state.selfDevice,
        activeSelfPeripheral: state.activeSelfPeripheral,
        devices: state.devices,
      );
    }

    return resolveActiveOutputLabel(
      activeDevice: state.activeDevice,
      selfDevice: state.selfDevice,
      activeSelfPeripheral: state.activeSelfPeripheral,
    );
  }

  /// Resolves the display name of an in-flight transfer target identified by
  /// [targetDeviceId] across [activeDevice], [selfDevice], and [devices].
  String resolveTransferTargetLabel({
    required String targetDeviceId,
    required ConnectDevice? activeDevice,
    required ConnectDevice? selfDevice,
    required LocalAudioPeripheral? activeSelfPeripheral,
    required Iterable<ConnectDevice> devices,
  }) {
    if (targetDeviceId == kLocalDeviceIdentifier) {
      return resolveLocalOutputLabel(
        selfDevice: selfDevice,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }
    if (activeDevice case final d?
        when matchesTransferTarget(d, targetDeviceId)) {
      return _resolveMatchedDeviceLabel(
        device: d,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }
    if (selfDevice case final s?
        when matchesTransferTarget(s, targetDeviceId)) {
      return resolveLocalOutputLabel(
        selfDevice: s,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }
    for (final device in devices) {
      if (matchesTransferTarget(device, targetDeviceId)) {
        return _resolveMatchedDeviceLabel(
          device: device,
          activeSelfPeripheral: activeSelfPeripheral,
        );
      }
    }
    return 'device';
  }

  /// Resolves the active listening target label (remote device name when
  /// remote is active, otherwise local peripheral / built-in speaker label).
  String resolveActiveOutputLabel({
    required ConnectDevice? activeDevice,
    required ConnectDevice? selfDevice,
    required LocalAudioPeripheral? activeSelfPeripheral,
  }) {
    if (activeDevice case final currentActive? when !currentActive.isSelf) {
      final trimmed = currentActive.name.trim();
      return trimmed.isNotEmpty ? currentActive.name : 'device';
    }
    final ConnectDevice? effectiveSelf = switch (selfDevice) {
      final self? => self,
      null => activeDevice,
    };
    return resolveLocalOutputLabel(
      selfDevice: effectiveSelf,
      activeSelfPeripheral: activeSelfPeripheral,
    );
  }

  /// Resolves the complete status banner string (`"Connecting to X..."` or
  /// `"Listening on X"`).
  String resolveBannerStatusText(ConnectState state) {
    return switch (state.transferState) {
      TransferInProgress(:final targetDeviceId) =>
        'Connecting to ${resolveTransferTargetLabel(
          targetDeviceId: targetDeviceId,
          activeDevice: state.activeDevice,
          selfDevice: state.selfDevice,
          activeSelfPeripheral: state.activeSelfPeripheral,
          devices: state.devices,
        )}...',
      TransferIdle() ||
      TransferSucceeded() ||
      TransferFailed() =>
        'Listening on ${resolveActiveOutputLabel(
          activeDevice: state.activeDevice,
          selfDevice: state.selfDevice,
          activeSelfPeripheral: state.activeSelfPeripheral,
        )}',
    };
  }

  /// Built-in speaker fallback label matching `p199p/g1m1.java:1300-1327`
  /// and `p199p/gtg.java:448-484`.
  String resolveBuiltInSpeakerLabel(DeviceType? selfDeviceType) {
    if (selfDeviceType == null) {
      return 'This device';
    }
    switch (selfDeviceType) {
      case DeviceType.chromebook:
        return 'This Chromebook';
      case DeviceType.computer:
        return 'This computer';
      case DeviceType.tablet:
        return 'This tablet';
      case DeviceType.unknown:
      case DeviceType.smartphone:
      case DeviceType.speaker:
      case DeviceType.tv:
      case DeviceType.avr:
      case DeviceType.stb:
      case DeviceType.audioDongle:
      case DeviceType.gameConsole:
      case DeviceType.castVideo:
      case DeviceType.castAudio:
      case DeviceType.automobile:
      case DeviceType.smartwatch:
      case DeviceType.unknownSpotifyHw:
      case DeviceType.homeThing:
        return 'This phone';
    }
  }

  /// Resolves the active local output display label, treating
  /// `activeSelfPeripheral == null` or `kBuiltInSpeakerPeripheralId` as the
  /// built-in speaker fallback.
  String resolveLocalOutputLabel({
    required ConnectDevice? selfDevice,
    required LocalAudioPeripheral? activeSelfPeripheral,
  }) {
    final DeviceType? selfType = switch (selfDevice) {
      final d? => d.type,
      null => null,
    };
    return switch (activeSelfPeripheral) {
      final peripheral? => _resolveNonNullPeripheralLabel(
          peripheral: peripheral,
          selfType: selfType,
        ),
      null => _resolveNullPeripheralLabel(
          selfDevice: selfDevice,
          selfType: selfType,
        ),
    };
  }

  /// Returns `true` if [device] matches [targetDeviceId] by either
  /// `connectStateIdentifier` or `localIdentifier`.
  bool matchesTransferTarget(ConnectDevice device, String targetDeviceId) {
    final normalizedTarget = targetDeviceId.trim();
    if (normalizedTarget.isEmpty) {
      return false;
    }
    return device.connectStateIdentifier.trim() == normalizedTarget ||
        device.localIdentifier.trim() == normalizedTarget;
  }

  String _resolveMatchedDeviceLabel({
    required ConnectDevice device,
    required LocalAudioPeripheral? activeSelfPeripheral,
  }) {
    if (device.isSelf) {
      return resolveLocalOutputLabel(
        selfDevice: device,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }
    if (device.name.trim().isNotEmpty) {
      return device.name;
    }
    return 'device';
  }

  String _resolveNonNullPeripheralLabel({
    required LocalAudioPeripheral peripheral,
    required DeviceType? selfType,
  }) {
    final trimmedName = peripheral.name.trim();
    final isBuiltIn = peripheral.id == kBuiltInSpeakerPeripheralId ||
        peripheral.connectionType ==
            OutputPeripheralConnectionType.builtInSpeaker;
    if (isBuiltIn) {
      if (trimmedName.isNotEmpty &&
          trimmedName != kBuiltInSpeakerPeripheralId) {
        return trimmedName;
      }
      return resolveBuiltInSpeakerLabel(selfType);
    }
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return resolveBuiltInSpeakerLabel(selfType);
  }

  String _resolveNullPeripheralLabel({
    required ConnectDevice? selfDevice,
    required DeviceType? selfType,
  }) {
    final outputPeripheral = switch (selfDevice) {
      final d? => d.outputPeripheral,
      null => null,
    };
    if (outputPeripheral != null) {
      final peripheralName = switch (outputPeripheral.name) {
        final n? => n.trim(),
        null => '',
      };
      if (peripheralName.isNotEmpty &&
          peripheralName != kBuiltInSpeakerPeripheralId) {
        return peripheralName;
      }
    }
    return resolveBuiltInSpeakerLabel(selfType);
  }
}
