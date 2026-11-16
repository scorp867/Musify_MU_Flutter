// 1:1 replica of com.spotify.connect.devicepicker.header (p199p/ohb1.java, p199p/bx40.java, p199p/frl1.java, p199p/C2255rx.java, p199p/u13.java, p199p/g1m1.java, p199p/gtg.java)

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';

/// Header bar for [DevicePickerSheet] displaying the "Connect" title, active
/// listening output status (with built-in speaker fallback when
/// `activeSelfPeripheral == null`), refresh action, and close button.
class DevicePickerHeader extends StatelessWidget {
  const DevicePickerHeader({
    super.key,
    this.activeDevice,
    this.activeSelfPeripheral,
    this.selfDevice,
    this.devices = const <ConnectDevice>[],
    this.transferState = const TransferIdle(),
    this.isSyncedWithBackend = true,
    this.onClose,
    this.onRefresh,
  });

  final ConnectDevice? activeDevice;
  final LocalAudioPeripheral? activeSelfPeripheral;
  final ConnectDevice? selfDevice;
  final List<ConnectDevice> devices;
  final TransferState transferState;
  final bool isSyncedWithBackend;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final _HeaderStatus resolvedStatus = _resolveStatus();
    final VoidCallback handleClose = switch (onClose) {
      final cb? => cb,
      null => () => Navigator.of(context).maybePop(),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PlayerColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          resolvedStatus.icon,
                          size: 14,
                          color: resolvedStatus.color,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            resolvedStatus.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: resolvedStatus.color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  key: const ValueKey<String>('device_picker_refresh_button'),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: PlayerColors.textSecondary,
                    size: 22,
                  ),
                  tooltip: 'Refresh devices',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onRefresh,
                ),
              IconButton(
                key: const ValueKey<String>('device_picker_close_button'),
                icon: const Icon(
                  Icons.close_rounded,
                  color: PlayerColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Close',
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                onPressed: handleClose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _HeaderStatus _resolveStatus() {
    switch (transferState) {
      case TransferInProgress(:final targetDeviceId):
        final resolvedName = _resolveTransferTargetName(targetDeviceId);
        return _HeaderStatus(
          label: 'Connecting to $resolvedName...',
          icon: Icons.sync_rounded,
          color: PlayerColors.accent,
        );
      case TransferIdle():
      case TransferSucceeded():
      case TransferFailed():
        break;
    }

    if (!isSyncedWithBackend && activeDevice == null) {
      return const _HeaderStatus(
        label: 'Syncing devices...',
        icon: Icons.devices_rounded,
        color: PlayerColors.textSecondary,
      );
    }

    final currentActive = activeDevice;
    if (currentActive != null && !currentActive.isSelf) {
      return _HeaderStatus(
        label: 'Listening on ${currentActive.name}',
        icon: resolveDeviceTypeIcon(currentActive.type),
        color: kSpotifyConnectGreen,
      );
    }

    final ConnectDevice? effectiveSelf = switch (selfDevice) {
      final d? => d,
      null => currentActive,
    };
    final localLabel = resolveLocalOutputLabel(
      selfDevice: effectiveSelf,
      activeSelfPeripheral: activeSelfPeripheral,
    );
    final localIcon = resolveLocalOutputIcon(
      selfDevice: effectiveSelf,
      activeSelfPeripheral: activeSelfPeripheral,
    );
    return _HeaderStatus(
      label: 'Listening on $localLabel',
      icon: localIcon,
      color: kSpotifyConnectGreen,
    );
  }

  String _resolveTransferTargetName(String targetDeviceId) {
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

final class _HeaderStatus {
  const _HeaderStatus({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
