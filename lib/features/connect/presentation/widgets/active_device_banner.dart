// 1:1 replica of com.spotify.connect.entrypoint (p199p/qsq.java, p199p/isq.java, p199p/usq.java, p199p/ptn.java, p199p/na7.java, p199p/n2n.java, p199p/jgb.java, p199p/hjn0.java, p199p/bdi0.java, p199p/mg20.java)

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';

/// Spotify Connect green (`#1DB954`) active output banner for `MiniPlayer`,
/// `PlayerScreen`, and Connect switcher entry points.
///
/// Supports either live reactive binding via [controller] or direct snapshot
/// props ([activeDevice], [activeSelfPeripheral], [selfDevice], [devices],
/// [transferState]).
class ActiveDeviceBanner extends StatelessWidget {
  const ActiveDeviceBanner({
    super.key,
    this.controller,
    this.activeDevice,
    this.activeSelfPeripheral,
    this.selfDevice,
    this.devices = const <ConnectDevice>[],
    this.transferState = const TransferIdle(),
    this.onTap,
    this.compact = false,
    this.showWhenLocalBuiltIn = false,
  });

  final ConnectMobiusController? controller;
  final ConnectDevice? activeDevice;
  final LocalAudioPeripheral? activeSelfPeripheral;
  final ConnectDevice? selfDevice;
  final List<ConnectDevice> devices;
  final TransferState transferState;
  final VoidCallback? onTap;
  final bool compact;
  final bool showWhenLocalBuiltIn;

  @override
  Widget build(BuildContext context) {
    final boundController = controller;
    if (boundController != null) {
      return ValueListenableBuilder<ConnectState>(
        valueListenable: boundController,
        builder: (context, state, _) {
          return _ActiveDeviceBannerView(
            activeDevice: state.activeDevice,
            activeSelfPeripheral: state.activeSelfPeripheral,
            selfDevice: state.selfDevice,
            devices: state.devices,
            transferState: state.transferState,
            onTap: onTap,
            compact: compact,
            showWhenLocalBuiltIn: showWhenLocalBuiltIn,
          );
        },
      );
    }

    return _ActiveDeviceBannerView(
      activeDevice: activeDevice,
      activeSelfPeripheral: activeSelfPeripheral,
      selfDevice: selfDevice,
      devices: devices,
      transferState: transferState,
      onTap: onTap,
      compact: compact,
      showWhenLocalBuiltIn: showWhenLocalBuiltIn,
    );
  }
}

class _ActiveDeviceBannerView extends StatelessWidget {
  const _ActiveDeviceBannerView({
    required this.activeDevice,
    required this.activeSelfPeripheral,
    required this.selfDevice,
    required this.devices,
    required this.transferState,
    required this.onTap,
    required this.compact,
    required this.showWhenLocalBuiltIn,
  });

  final ConnectDevice? activeDevice;
  final LocalAudioPeripheral? activeSelfPeripheral;
  final ConnectDevice? selfDevice;
  final List<ConnectDevice> devices;
  final TransferState transferState;
  final VoidCallback? onTap;
  final bool compact;
  final bool showWhenLocalBuiltIn;

  @override
  Widget build(BuildContext context) {
    final bool isTransferring = transferState is TransferInProgress;
    final ConnectDevice? currentActive = activeDevice;
    final bool isRemoteActive = currentActive != null && !currentActive.isSelf;

    final LocalAudioPeripheral? peripheral = activeSelfPeripheral;
    final bool isLocalExternalPeripheral = !isRemoteActive &&
        peripheral != null &&
        peripheral.id != kBuiltInSpeakerPeripheralId &&
        peripheral.connectionType !=
            OutputPeripheralConnectionType.builtInSpeaker;

    final bool isLocalBuiltIn = !isRemoteActive && !isLocalExternalPeripheral;
    if (isLocalBuiltIn && !isTransferring && !showWhenLocalBuiltIn) {
      return const SizedBox.shrink();
    }

    final _BannerPresentation presentation = _resolvePresentation(
      isTransferring: isTransferring,
      isRemoteActive: isRemoteActive,
      currentActive: currentActive,
    );

    final double radius = compact ? 4.0 : 8.0;
    final EdgeInsetsGeometry padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Semantics(
      button: onTap != null,
      label: 'Connect to a device. Opens the devices menu',
      child: Material(
        color: kSpotifyConnectGreen.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: kSpotifyConnectGreen.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (presentation.showSpinner)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: kSpotifyConnectGreen,
                    ),
                  )
                else
                  Icon(
                    presentation.icon,
                    size: compact ? 14 : 16,
                    color: kSpotifyConnectGreen,
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    presentation.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kSpotifyConnectGreen,
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: compact ? 14 : 16,
                    color: kSpotifyConnectGreen,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _BannerPresentation _resolvePresentation({
    required bool isTransferring,
    required bool isRemoteActive,
    required ConnectDevice? currentActive,
  }) {
    switch (transferState) {
      case TransferInProgress(:final targetDeviceId):
        final String targetName = _resolveTargetLabel(targetDeviceId);
        return _BannerPresentation(
          label: 'Connecting to $targetName...',
          icon: Icons.sync_rounded,
          showSpinner: true,
        );
      case TransferIdle():
      case TransferSucceeded():
      case TransferFailed():
        break;
    }

    if (isRemoteActive && currentActive != null) {
      return _BannerPresentation(
        label: 'Listening on ${currentActive.name}',
        icon: resolveDeviceTypeIcon(currentActive.type),
        showSpinner: false,
      );
    }

    final ConnectDevice? effectiveSelf = switch (selfDevice) {
      final d? => d,
      null => currentActive,
    };
    final String localLabel = resolveLocalOutputLabel(
      selfDevice: effectiveSelf,
      activeSelfPeripheral: activeSelfPeripheral,
    );
    final IconData localIcon = resolveLocalOutputIcon(
      selfDevice: effectiveSelf,
      activeSelfPeripheral: activeSelfPeripheral,
    );
    return _BannerPresentation(
      label: 'Listening on $localLabel',
      icon: localIcon,
      showSpinner: false,
    );
  }

  String _resolveTargetLabel(String targetDeviceId) {
    if (targetDeviceId == kLocalDeviceIdentifier) {
      return resolveLocalOutputLabel(
        selfDevice: selfDevice,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }
    if (activeDevice case final d?
        when _matchesTransferTarget(d, targetDeviceId)) {
      return _resolveMatchedDeviceLabel(d);
    }
    if (selfDevice case final s?
        when _matchesTransferTarget(s, targetDeviceId)) {
      return resolveLocalOutputLabel(
        selfDevice: s,
        activeSelfPeripheral: activeSelfPeripheral,
      );
    }
    for (final device in devices) {
      if (_matchesTransferTarget(device, targetDeviceId)) {
        return _resolveMatchedDeviceLabel(device);
      }
    }
    return 'device';
  }

  bool _matchesTransferTarget(ConnectDevice device, String targetDeviceId) {
    final normalizedTarget = targetDeviceId.trim();
    if (normalizedTarget.isEmpty) {
      return false;
    }
    return device.connectStateIdentifier.trim() == normalizedTarget ||
        device.localIdentifier.trim() == normalizedTarget;
  }

  String _resolveMatchedDeviceLabel(ConnectDevice device) {
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
}

final class _BannerPresentation {
  const _BannerPresentation({
    required this.label,
    required this.icon,
    required this.showSpinner,
  });

  final String label;
  final IconData icon;
  final bool showSpinner;
}
