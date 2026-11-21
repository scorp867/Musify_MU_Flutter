// 1:1 replica of Spotify's Connect Device Picker row (`p199p/btl1.java`,
// `p199p/y231.java` `row-context-menu-entry-point`).

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// Resolves the canonical Connect target identifier for command dispatch
/// (`connectStateIdentifier` preferred, falling back to `localIdentifier`).
String resolveDeviceTargetIdentifier(ConnectDevice device) {
  final connectId = device.connectStateIdentifier.trim();
  if (connectId.isNotEmpty) {
    return connectId;
  }
  return device.localIdentifier.trim();
}

/// Resolves a deterministic, unique-per-device key value for list identity
/// (`ValueKey`). Never falls back to a list index.
String resolveDeviceRowKeyValue(ConnectDevice device) {
  final connectId = device.connectStateIdentifier.trim();
  if (connectId.isNotEmpty) {
    return 'connect_$connectId';
  }
  final localId = device.localIdentifier.trim();
  if (localId.isNotEmpty) {
    return 'local_$localId';
  }
  return 'device_${device.type.wireName}_${device.name.trim()}_${device.creationTimeMs}';
}

/// Single subtitle token rendered inside a [DevicePickerRow] separated by `"•"`.
@immutable
final class DeviceSubtitleSegment {
  const DeviceSubtitleSegment({
    required this.label,
    this.icon,
    this.isAccent = false,
  });

  final String label;
  final EncoreIconPair? icon;
  final bool isAccent;
}

/// Spotify Device Picker device list row matching `p199p/btl1.java` (`m32098f`)
/// and `p199p/y231.java` (`m93175a`):
/// - Minimum height: `56dp`
/// - Outer padding: `8dp H / 4dp V`
/// - Inner padding: `12dp H / 6dp V`
/// - Leading `24dp` Encore device icon (`#B3B3B3`, or `#1ED760` when active/transferring)
/// - Device name (`16sp Regular`, `#FFFFFF`, or `#B3B3B3` when disabled)
/// - Subtitle segments (`11sp Regular #B3B3B3`, joined by `"•"` with `2dp H` padding,
///   each supporting an optional leading `12dp` Encore icon)
/// - Trailing `...` (`More16`) context menu trigger when actions exist.
class DevicePickerRow extends StatelessWidget {
  const DevicePickerRow({
    super.key,
    required this.device,
    required this.onTap,
    this.activeSelfPeripheral,
    this.transferState = const TransferIdle(),
    this.installSpotifyState,
    this.isInstallingThisDevice = false,
    this.isRecommended = false,
    this.outputStatusPolicy = ConnectOutputStatusPolicy.instance,
    this.onOpenContextMenu,
  });

  final ConnectDevice device;
  final VoidCallback onTap;
  final LocalAudioPeripheral? activeSelfPeripheral;
  final TransferState transferState;
  final connect_pb.InstallSpotifyState? installSpotifyState;
  final bool isInstallingThisDevice;
  final bool isRecommended;
  final ConnectOutputStatusPolicy outputStatusPolicy;
  final VoidCallback? onOpenContextMenu;

  bool _isTransferringToThisDevice() {
    switch (transferState) {
      case TransferInProgress(:final targetDeviceId):
        return outputStatusPolicy.matchesTransferTarget(device, targetDeviceId);
      case TransferIdle():
      case TransferSucceeded():
      case TransferFailed():
        return false;
    }
  }

  String _resolveDisplayName() {
    if (device.isSelf) {
      return outputStatusPolicy.resolveLocalOutputLabel(
        selfDevice: device,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }
    final trimmed = device.name.trim();
    return trimmed.isNotEmpty ? device.name : 'Device';
  }

  List<DeviceSubtitleSegment> _buildSubtitleSegments(bool isTransferring) {
    final segments = <DeviceSubtitleSegment>[];

    if (isTransferring || device.isBeingActivated) {
      segments.add(
        const DeviceSubtitleSegment(
          label: 'Connecting...',
          isAccent: true,
        ),
      );
      return segments;
    }

    if (isInstallingThisDevice && _isActiveInstallState(installSpotifyState)) {
      segments.add(
        const DeviceSubtitleSegment(
          label: 'Installing Spotify...',
          isAccent: true,
        ),
      );
      return segments;
    }

    switch (device.state) {
      case ConnectDeviceState.connecting:
        segments.add(const DeviceSubtitleSegment(label: 'Connecting...'));
      case ConnectDeviceState.wakingUp:
        segments.add(const DeviceSubtitleSegment(label: 'Waking up...'));
      case ConnectDeviceState.sleeping:
      case ConnectDeviceState.wol:
        segments.add(const DeviceSubtitleSegment(label: 'Tap to wake'));
      case ConnectDeviceState.notInstalled:
      case ConnectDeviceState.installationAvailable:
        segments.add(const DeviceSubtitleSegment(label: 'Install Spotify'));
      case ConnectDeviceState.installing:
        segments.add(const DeviceSubtitleSegment(label: 'Installing...'));
      case ConnectDeviceState.premiumRequired:
        segments.add(const DeviceSubtitleSegment(label: 'Premium required'));
      case ConnectDeviceState.notLoggedIn:
      case ConnectDeviceState.notAuthorized:
        segments.add(const DeviceSubtitleSegment(label: 'Sign in required'));
      case ConnectDeviceState.busy:
        segments.add(const DeviceSubtitleSegment(label: 'Busy'));
      case ConnectDeviceState.unavailable:
      case ConnectDeviceState.incompatible:
      case ConnectDeviceState.unsupportedVersion:
      case ConnectDeviceState.unsupportedUri:
      case ConnectDeviceState.managedAccountOnDisallowedDevice:
        segments.add(const DeviceSubtitleSegment(label: 'Unavailable'));
      case ConnectDeviceState.timedOutWakeup:
        segments.add(const DeviceSubtitleSegment(label: 'Could not wake up'));
      case ConnectDeviceState.loggedIn:
      case ConnectDeviceState.adPlaying:
      case ConnectDeviceState.narration:
      case ConnectDeviceState.notLoaded:
      case ConnectDeviceState.unknown:
        break;
    }

    if (isCastConnectDevice(device)) {
      segments.add(
        const DeviceSubtitleSegment(
          label: 'Google Cast',
          icon: ConnectEncoreIcons.chromecastDisconnected,
        ),
      );
    } else if (!device.isSelf) {
      if (device.brandDisplayName.trim().isNotEmpty) {
        segments.add(
          DeviceSubtitleSegment(
            label: device.brandDisplayName.trim(),
            icon: ConnectEncoreIcons.spotifyConnect,
          ),
        );
      } else if (device.isZeroconf) {
        segments.add(
          const DeviceSubtitleSegment(
            label: 'Spotify Connect',
            icon: ConnectEncoreIcons.spotifyConnect,
          ),
        );
      }
    }

    if (device.hifi.fullySupported) {
      segments.add(
        const DeviceSubtitleSegment(
          label: 'Lossless',
          isAccent: true,
        ),
      );
    }

    if (isRecommended) {
      segments.add(
        const DeviceSubtitleSegment(
          label: 'Recommended',
          isAccent: true,
        ),
      );
    }

    return segments;
  }

  static bool _isActiveInstallState(connect_pb.InstallSpotifyState? state) {
    if (state == null) {
      return false;
    }
    return state == connect_pb.InstallSpotifyState.CONNECTING ||
        state == connect_pb.InstallSpotifyState.PAIRING ||
        state == connect_pb.InstallSpotifyState.SUBSCRIBING ||
        state == connect_pb.InstallSpotifyState.LAUNCHING_APP_STORE ||
        state == connect_pb.InstallSpotifyState.WAITING_FOR_APP_TO_BE_INSTALLED ||
        state == connect_pb.InstallSpotifyState.LAUNCHING_THE_APP;
  }

  @override
  Widget build(BuildContext context) {
    final bool isTransferring = _isTransferringToThisDevice();
    final bool isActiveOrTransferring = device.isActive || isTransferring;
    final bool isDisabled = device.isDisabled ||
        device.state == ConnectDeviceState.unavailable ||
        device.state == ConnectDeviceState.incompatible ||
        device.state == ConnectDeviceState.unsupportedVersion ||
        device.state == ConnectDeviceState.managedAccountOnDisallowedDevice;

    final String displayName = _resolveDisplayName();
    final List<DeviceSubtitleSegment> segments =
        _buildSubtitleSegments(isTransferring);
    final EncoreIconPair iconPair = resolveConnectDeviceEncoreIcon(
      device,
      isConnected: device.isActive,
    );

    final Color iconColor = isActiveOrTransferring
        ? ConnectEncoreTheme.brightAccent
        : ConnectEncoreTheme.textSubdued;
    final Color titleColor = isActiveOrTransferring
        ? ConnectEncoreTheme.brightAccent
        : (isDisabled
            ? ConnectEncoreTheme.textSubdued
            : ConnectEncoreTheme.textBase);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ConnectEncoreTheme.deviceRowMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 24.0,
                    child: isTransferring
                        ? const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ConnectEncoreTheme.brightAccent,
                              ),
                            ),
                          )
                        : ConnectEncoreIcon.pair(
                            iconPair: iconPair,
                            size: 24.0,
                            color: iconColor,
                          ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ConnectEncoreTheme.deviceRow16Regular.copyWith(
                            color: titleColor,
                          ),
                        ),
                        if (segments.isNotEmpty) ...[
                          const SizedBox(height: 2.0),
                          _SubtitleSegmentsLine(segments: segments),
                        ],
                      ],
                    ),
                  ),
                  if (onOpenContextMenu case final openMenu?) ...[
                    const SizedBox(width: 4.0),
                    Semantics(
                      label: 'More options for $displayName',
                      button: true,
                      child: InkResponse(
                        key: ValueKey<String>(
                          'row_context_menu_${resolveDeviceRowKeyValue(device)}',
                        ),
                        onTap: isDisabled ? null : openMenu,
                        radius: 20.0,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ConnectEncoreIcon(
                            icon: ConnectEncoreIcons.more16,
                            size: 16.0,
                            color: ConnectEncoreTheme.textSubdued,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtitleSegmentsLine extends StatelessWidget {
  const _SubtitleSegmentsLine({
    required this.segments,
  });

  final List<DeviceSubtitleSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                ' \u2022 ',
                style: ConnectEncoreTheme.caption11Regular,
              ),
            ),
          if (segments[i].icon case final segIcon?) ...[
            ConnectEncoreIcon.pair(
              iconPair: segIcon,
              size: 12.0,
              color: segments[i].isAccent
                  ? ConnectEncoreTheme.brightAccent
                  : ConnectEncoreTheme.textSubdued,
            ),
            const SizedBox(width: 4.0),
          ],
          Flexible(
            child: Text(
              segments[i].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ConnectEncoreTheme.caption11Regular.copyWith(
                color: segments[i].isAccent
                    ? ConnectEncoreTheme.brightAccent
                    : ConnectEncoreTheme.textSubdued,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
