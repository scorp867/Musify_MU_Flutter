// 1:1 replica of com.spotify.connect.devicepicker.row (p199p/btl1.java, p199p/byl1.java, p199p/n8d.java, p199p/c0m1.java, p199p/c8k.java, p199p/tcz0.java, p199p/ol01.java, p199p/bsq.java, p199p/dsq.java)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';

/// Spotify Connect brand green (`resources/res/values/colors.xml:453`).
const Color kSpotifyConnectGreen = Color(0xFF1DB954);

/// Resolves the canonical target identifier used for Connect transfer, logout,
/// rename, preferred incarnation, and installation commands.
String resolveDeviceTargetIdentifier(ConnectDevice device) {
  final connectId = device.connectStateIdentifier.trim();
  if (connectId.isNotEmpty) {
    return connectId;
  }
  return device.localIdentifier.trim();
}

/// Deterministic widget key value for a [ConnectDevice] list row.
String resolveDeviceRowKeyValue(ConnectDevice device) {
  final targetId = resolveDeviceTargetIdentifier(device);
  if (targetId.isNotEmpty) {
    return 'device_$targetId';
  }
  return 'device_name_${device.name}';
}

/// Built-in speaker fallback label delegating to [ConnectOutputStatusPolicy] SSOT
/// (`p199p/g1m1.java:1300-1327`, `p199p/gtg.java:448-484`).
String resolveBuiltInSpeakerLabel(DeviceType? selfDeviceType) {
  return ConnectOutputStatusPolicy.instance.resolveBuiltInSpeakerLabel(
    selfDeviceType,
  );
}

/// Resolves the active local output display label delegating to
/// [ConnectOutputStatusPolicy] SSOT (`p199p/gtg.java:448-484`,
/// `p199p/g1m1.java:1300-1327`).
String resolveLocalOutputLabel({
  required ConnectDevice? selfDevice,
  required LocalAudioPeripheral? activeSelfPeripheral,
}) {
  return ConnectOutputStatusPolicy.instance.resolveLocalOutputLabel(
    selfDevice: selfDevice,
    activeSelfPeripheral: activeSelfPeripheral,
  );
}

/// Human-readable display label for an [IncarnationLoginType] protocol option
/// (`p199p/c8r.java:55-200`, `p199p/s13.java:472-493`).
String resolveIncarnationLoginTypeLabel(IncarnationLoginType loginType) {
  switch (loginType) {
    case IncarnationLoginType.connect:
      return 'Spotify Connect';
    case IncarnationLoginType.cast:
      return 'Google Cast';
    case IncarnationLoginType.castJs:
      return 'Google Cast (Web)';
  }
}

/// Exhaustive 17-variant [DeviceType] icon mapping matching `p199p/byl1.java:1879-1977`.
IconData resolveDeviceTypeIcon(DeviceType type) {
  switch (type) {
    case DeviceType.unknown:
      return Icons.devices_other_rounded;
    case DeviceType.computer:
      return Icons.computer_rounded;
    case DeviceType.tablet:
      return Icons.tablet_android_rounded;
    case DeviceType.smartphone:
      return Icons.smartphone_rounded;
    case DeviceType.speaker:
      return Icons.speaker_rounded;
    case DeviceType.tv:
      return Icons.tv_rounded;
    case DeviceType.avr:
      return Icons.surround_sound_rounded;
    case DeviceType.stb:
      return Icons.settings_input_hdmi_rounded;
    case DeviceType.audioDongle:
      return Icons.cast_rounded;
    case DeviceType.gameConsole:
      return Icons.videogame_asset_rounded;
    case DeviceType.castVideo:
      return Icons.cast_connected_rounded;
    case DeviceType.castAudio:
      return Icons.speaker_rounded;
    case DeviceType.automobile:
      return Icons.directions_car_rounded;
    case DeviceType.smartwatch:
      return Icons.watch_rounded;
    case DeviceType.chromebook:
      return Icons.laptop_chromebook_rounded;
    case DeviceType.unknownSpotifyHw:
      return Icons.devices_other_rounded;
    case DeviceType.homeThing:
      return Icons.smart_display_rounded;
  }
}

IconData _resolveCategoryIcon(
  OutputPeripheralCategory category, {
  required IconData fallback,
}) {
  switch (category) {
    case OutputPeripheralCategory.headphones:
      return Icons.headphones_rounded;
    case OutputPeripheralCategory.car:
      return Icons.directions_car_rounded;
    case OutputPeripheralCategory.speaker:
      return Icons.speaker_rounded;
    case OutputPeripheralCategory.wearable:
      return Icons.watch_rounded;
    case OutputPeripheralCategory.glasses:
      return Icons.visibility_rounded;
    case OutputPeripheralCategory.app:
    case OutputPeripheralCategory.unknown:
      return fallback;
  }
}

/// Exhaustive peripheral route icon mapping across [OutputPeripheralConnectionType]
/// and [OutputPeripheralCategory].
IconData resolvePeripheralIcon(
  OutputPeripheralConnectionType connectionType, {
  OutputPeripheralCategory? category,
  DeviceType? fallbackDeviceType,
}) {
  switch (connectionType) {
    case OutputPeripheralConnectionType.bluetooth:
      return switch (category) {
        final c? => _resolveCategoryIcon(
            c,
            fallback: Icons.bluetooth_audio_rounded,
          ),
        null => Icons.bluetooth_audio_rounded,
      };
    case OutputPeripheralConnectionType.wired:
      return switch (category) {
        final c? => _resolveCategoryIcon(
            c,
            fallback: Icons.headphones_rounded,
          ),
        null => Icons.headphones_rounded,
      };
    case OutputPeripheralConnectionType.carProjected:
      return Icons.directions_car_rounded;
    case OutputPeripheralConnectionType.airplay:
      return Icons.airplay_rounded;
    case OutputPeripheralConnectionType.builtInSpeaker:
      return switch (fallbackDeviceType) {
        final t? => resolveDeviceTypeIcon(t),
        null => Icons.smartphone_rounded,
      };
    case OutputPeripheralConnectionType.unknown:
      return switch (fallbackDeviceType) {
        final t? => resolveDeviceTypeIcon(t),
        null => Icons.speaker_rounded,
      };
  }
}

/// Resolves the active local output icon, treating `activeSelfPeripheral == null`
/// as the built-in speaker fallback.
IconData resolveLocalOutputIcon({
  required ConnectDevice? selfDevice,
  required LocalAudioPeripheral? activeSelfPeripheral,
}) {
  final DeviceType? selfType = switch (selfDevice) {
    final d? => d.type,
    null => null,
  };
  return switch (activeSelfPeripheral) {
    final peripheral? => resolvePeripheralIcon(
        peripheral.connectionType,
        category: peripheral.category,
        fallbackDeviceType: selfType,
      ),
    null => _resolveNullPeripheralIcon(
        selfDevice: selfDevice,
        selfType: selfType,
      ),
  };
}

IconData _resolveNullPeripheralIcon({
  required ConnectDevice? selfDevice,
  required DeviceType? selfType,
}) {
  final outputPeripheral = switch (selfDevice) {
    final d? => d.outputPeripheral,
    null => null,
  };
  if (outputPeripheral != null) {
    if (outputPeripheral.connectionType case final connType?) {
      return resolvePeripheralIcon(
        connType,
        category: outputPeripheral.category,
        fallbackDeviceType: selfType,
      );
    }
  }
  return switch (selfType) {
    final t? => resolveDeviceTypeIcon(t),
    null => Icons.smartphone_rounded,
  };
}

/// Maps [InstallSpotifyState] (`$pb.ProtobufEnum`) using explicit equality
/// checks so zero wildcard switch branches are used.
String resolveInstallSpotifyStatusLabel(connect_pb.InstallSpotifyState state) {
  if (state == connect_pb.InstallSpotifyState.CONNECTING) {
    return 'Connecting to device...';
  }
  if (state == connect_pb.InstallSpotifyState.PAIRING) {
    return 'Pairing device...';
  }
  if (state == connect_pb.InstallSpotifyState.SUBSCRIBING) {
    return 'Preparing installation...';
  }
  if (state == connect_pb.InstallSpotifyState.LAUNCHING_APP_STORE) {
    return 'Opening app store...';
  }
  if (state == connect_pb.InstallSpotifyState.WAITING_FOR_APP_TO_BE_INSTALLED) {
    return 'Installing Spotify...';
  }
  if (state == connect_pb.InstallSpotifyState.LAUNCHING_THE_APP) {
    return 'Launching Spotify...';
  }
  if (state == connect_pb.InstallSpotifyState.SUCCESS) {
    return 'Spotify installed';
  }
  if (state == connect_pb.InstallSpotifyState.DEVICE_NOT_FOUND) {
    return 'Device not found';
  }
  if (state == connect_pb.InstallSpotifyState.DEVICE_NOT_SUPPORTED) {
    return 'Device not supported';
  }
  if (state == connect_pb.InstallSpotifyState.TIMEOUT) {
    return 'Installation timed out';
  }
  if (state == connect_pb.InstallSpotifyState.CANCELLED) {
    return 'Installation cancelled';
  }
  return 'Installation failed';
}

bool _isInstallInProgress(connect_pb.InstallSpotifyState state) {
  return state == connect_pb.InstallSpotifyState.CONNECTING ||
      state == connect_pb.InstallSpotifyState.PAIRING ||
      state == connect_pb.InstallSpotifyState.SUBSCRIBING ||
      state == connect_pb.InstallSpotifyState.LAUNCHING_APP_STORE ||
      state == connect_pb.InstallSpotifyState.WAITING_FOR_APP_TO_BE_INSTALLED ||
      state == connect_pb.InstallSpotifyState.LAUNCHING_THE_APP;
}

String _resolveTransferPhaseLabel(TransferPhase phase) {
  switch (phase) {
    case TransferPhase.created:
      return 'Preparing transfer...';
    case TransferPhase.discovering:
      return 'Finding device...';
    case TransferPhase.transferring:
      return 'Connecting...';
    case TransferPhase.becomingActive:
      return 'Starting playback...';
  }
}

String _resolveDeviceStateLabel(ConnectDevice device) {
  switch (device.state) {
    case ConnectDeviceState.connecting:
      return 'Connecting...';
    case ConnectDeviceState.incompatible:
      return 'Incompatible version';
    case ConnectDeviceState.unavailable:
      return 'Unavailable';
    case ConnectDeviceState.loggedIn:
      if (device.isActive) {
        return 'Active device';
      }
      if (device.brandDisplayName.trim().isNotEmpty) {
        return device.brandDisplayName;
      }
      return 'Spotify Connect';
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
      if (device.brandDisplayName.trim().isNotEmpty) {
        return device.brandDisplayName;
      }
      return 'Connect device';
  }
}

/// Connect device row widget matching `p199p/btl1.java`, `p199p/byl1.java`,
/// `p199p/c0m1.java`, `p199p/cup.java:194-252`, and `p199p/c8r.java:55-200`.
class DeviceListTile extends StatelessWidget {
  const DeviceListTile({
    super.key,
    required this.device,
    this.activeSelfPeripheral,
    this.transferState = const TransferIdle(),
    this.installSpotifyState,
    this.isInstallingThisDevice = false,
    this.isRecommended = false,
    this.onTap,
    this.onLogout,
    this.onRename,
    this.onSelectPreferredIncarnation,
    this.onInstall,
    this.onAddToGroup,
    this.outputStatusPolicy,
  });

  final ConnectDevice device;
  final LocalAudioPeripheral? activeSelfPeripheral;
  final TransferState transferState;
  final connect_pb.InstallSpotifyState? installSpotifyState;
  final bool isInstallingThisDevice;
  final bool isRecommended;
  final VoidCallback? onTap;
  final VoidCallback? onLogout;
  final VoidCallback? onRename;
  final ValueChanged<IncarnationLoginType>? onSelectPreferredIncarnation;
  final VoidCallback? onInstall;
  final VoidCallback? onAddToGroup;
  final ConnectOutputStatusPolicy? outputStatusPolicy;

  ConnectOutputStatusPolicy _resolvePolicy(BuildContext context) {
    if (outputStatusPolicy case final explicit?) {
      return explicit;
    }
    if (context.read<ConnectOutputStatusPolicy?>() case final provided?) {
      return provided;
    }
    return ConnectOutputStatusPolicy.instance;
  }

  @override
  Widget build(BuildContext context) {
    final policy = _resolvePolicy(context);
    final targetId = resolveDeviceTargetIdentifier(device);
    final bool isTransferTarget = switch (transferState) {
      TransferInProgress(:final targetDeviceId) =>
        targetDeviceId == targetId ||
            (device.isSelf && targetDeviceId == kLocalDeviceIdentifier),
      TransferIdle() => false,
      TransferSucceeded() => false,
      TransferFailed() => false,
    };

    final bool isInstallBusy = isInstallingThisDevice &&
        switch (installSpotifyState) {
          final state? => _isInstallInProgress(state),
          null => false,
        };
    final bool showSpinner = isTransferTarget ||
        device.isBeingActivated ||
        isInstallBusy;

    final bool isDisabled = device.isDisabled || device.isOffline;
    final bool isActive = device.isActive;

    final Color accentColor = kSpotifyConnectGreen;
    final Color foregroundColor = isActive
        ? accentColor
        : (isDisabled ? PlayerColors.muted : PlayerColors.textPrimary);
    final Color subtitleColor = isActive
        ? accentColor.withValues(alpha: 0.90)
        : (isDisabled ? PlayerColors.muted : PlayerColors.textSecondary);

    final IconData leadingIcon = device.isSelf
        ? resolveLocalOutputIcon(
            selfDevice: device,
            activeSelfPeripheral: activeSelfPeripheral,
          )
        : resolveDeviceTypeIcon(device.type);

    final String titleText = device.isSelf
        ? (device.name.trim().isNotEmpty
            ? device.name
            : policy.resolveBuiltInSpeakerLabel(device.type))
        : (device.name.trim().isNotEmpty
            ? device.name
            : (device.modelDisplayName.trim().isNotEmpty
                ? device.modelDisplayName
                : 'Connect device'));

    final String subtitleText = _resolveSubtitle(targetId, policy);

    final bool showInstallButton = !isDisabled &&
        onInstall != null &&
        (device.state == ConnectDeviceState.notInstalled ||
            device.state == ConnectDeviceState.installationAvailable);

    final bool showLogoutItem =
        device.supportsLogout && !device.isSelf && onLogout != null;
    final bool showRenameItem =
        device.supportsRename && !device.isSelf && onRename != null;
    final List<Incarnation> selectableIncarnations =
        (!device.isSelf &&
                onSelectPreferredIncarnation != null &&
                device.incarnations.length > 1)
            ? device.incarnations
                .where((inc) => inc.parsedLoginType != null)
                .toList(growable: false)
            : const <Incarnation>[];
    final bool showIncarnationItems = selectableIncarnations.length > 1;
    final bool showOverflowMenu =
        showLogoutItem || showRenameItem || showIncarnationItems;

    final Color backgroundColor = isActive
        ? accentColor.withValues(alpha: 0.14)
        : (isDisabled
            ? PlayerColors.surfaceHigh.withValues(alpha: 0.55)
            : PlayerColors.surfaceHigh);

    return Semantics(
      button: onTap != null && !isDisabled,
      enabled: !isDisabled,
      selected: isActive,
      label: isDisabled
          ? '$titleText, unavailable'
          : (isActive ? '$titleText, active device' : 'Connect to $titleText'),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive
                ? accentColor.withValues(alpha: 0.55)
                : PlayerColors.divider,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    leadingIcon,
                    size: 24,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              titleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: foregroundColor,
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                            if (device.hifi.fullySupported)
                              const _DeviceBadge(
                                label: 'HiFi',
                                color: PlayerColors.accent,
                              ),
                            if (device.isGroup)
                              const _DeviceBadge(
                                label: 'Group',
                                color: PlayerColors.textSecondary,
                              ),
                            if (isRecommended && !isActive)
                              const _DeviceBadge(
                                label: 'Suggested',
                                color: kSpotifyConnectGreen,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showSpinner) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kSpotifyConnectGreen,
                      ),
                    ),
                  ] else if (isActive) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.graphic_eq_rounded,
                      size: 20,
                      color: kSpotifyConnectGreen,
                    ),
                  ],
                  if (showInstallButton)
                    IconButton(
                      key: ValueKey<String>('install_$targetId'),
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: PlayerColors.textPrimary,
                      ),
                      tooltip: 'Install Spotify',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: const EdgeInsets.all(6),
                      onPressed: onInstall,
                    ),
                  if (onAddToGroup != null && !device.isSelf && !isDisabled)
                    IconButton(
                      key: ValueKey<String>('add_to_group_$targetId'),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                        color: PlayerColors.textSecondary,
                      ),
                      tooltip: 'Add ${device.name} to speaker group',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: const EdgeInsets.all(6),
                      onPressed: onAddToGroup,
                    ),
                  if (showOverflowMenu)
                    PopupMenuButton<String>(
                      key: ValueKey<String>('device_menu_$targetId'),
                      tooltip: 'Device options',
                      color: PlayerColors.surfaceHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: PlayerColors.divider),
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: PlayerColors.textSecondary,
                      ),
                      onSelected: (value) {
                        if (value == 'logout') {
                          onLogout?.call();
                          return;
                        }
                        if (value == 'rename') {
                          onRename?.call();
                          return;
                        }
                        if (value.startsWith('incarnation:')) {
                          final rawWire = value.substring('incarnation:'.length);
                          if (IncarnationLoginType.tryFromWireName(rawWire)
                              case final loginType?) {
                            onSelectPreferredIncarnation?.call(loginType);
                          }
                        }
                      },
                      itemBuilder: (menuContext) {
                        final entries = <PopupMenuEntry<String>>[];
                        if (showRenameItem) {
                          entries.add(
                            PopupMenuItem<String>(
                              key: ValueKey<String>(
                                'device_menu_rename_$targetId',
                              ),
                              value: 'rename',
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: PlayerColors.textPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rename device',
                                    style: TextStyle(
                                      color: PlayerColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (showIncarnationItems) {
                          for (final incarnation in selectableIncarnations) {
                            if (incarnation.parsedLoginType
                                case final loginType?) {
                              final isPreferred = incarnation.preferred;
                              entries.add(
                                PopupMenuItem<String>(
                                  key: ValueKey<String>(
                                    'device_menu_incarnation_${targetId}_${loginType.wireName}',
                                  ),
                                  value: 'incarnation:${loginType.wireName}',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPreferred
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        size: 18,
                                        color: isPreferred
                                            ? kSpotifyConnectGreen
                                            : PlayerColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Connect via ${resolveIncarnationLoginTypeLabel(loginType)}',
                                        style: TextStyle(
                                          color: isPreferred
                                              ? kSpotifyConnectGreen
                                              : PlayerColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: isPreferred
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }
                        }
                        if (showLogoutItem) {
                          entries.add(
                            PopupMenuItem<String>(
                              key: ValueKey<String>(
                                'device_menu_logout_$targetId',
                              ),
                              value: 'logout',
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                    color: PlayerColors.textPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Log out',
                                    style: TextStyle(
                                      color: PlayerColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return entries;
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resolveSubtitle(String targetId, ConnectOutputStatusPolicy policy) {
    switch (transferState) {
      case TransferInProgress(
          targetDeviceId: final pendingId,
          phase: final phase,
        ):
        final matchesTarget = pendingId == targetId ||
            (device.isSelf && pendingId == kLocalDeviceIdentifier);
        if (matchesTarget) {
          return _resolveTransferPhaseLabel(phase);
        }
      case TransferFailed(
          targetDeviceId: final failedId,
          errorDescription: final description,
        ):
        final matchesTarget = failedId == targetId ||
            (device.isSelf && failedId == kLocalDeviceIdentifier);
        if (matchesTarget) {
          if (description case final text? when text.trim().isNotEmpty) {
            return text;
          }
          return 'Transfer failed';
        }
      case TransferIdle():
      case TransferSucceeded():
        break;
    }

    if (isInstallingThisDevice) {
      if (installSpotifyState case final installState?) {
        return resolveInstallSpotifyStatusLabel(installState);
      }
    }

    if (device.isBeingActivated) {
      return 'Connecting...';
    }

    if (device.isSelf) {
      return policy.resolveLocalOutputLabel(
        selfDevice: device,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }

    return _resolveDeviceStateLabel(device);
  }
}

class _DeviceBadge extends StatelessWidget {
  const _DeviceBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
          width: 0.75,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
