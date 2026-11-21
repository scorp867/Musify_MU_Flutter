// 1:1 replica of Spotify Connect state icon (`p199p/na7.java`, `p199p/isq.java`,
// `p199p/u7k.java`, `p199p/q7k.java`, `p199p/r7k.java`, `p199p/s7k.java`,
// `p199p/t7k.java`).

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// Exhaustive sealed Connect icon state matching Spotify's `p199p/u7k.java`
/// hierarchy (`t7k` Disabled, `s7k` Idle/Local, `r7k` Connecting, `q7k` Active).
@immutable
sealed class ConnectIconState extends Equatable {
  const ConnectIconState();
}

/// Disabled state (`t7k`): default devices icon tinted `textSubdued` at 50% alpha.
@immutable
final class ConnectIconDisabled extends ConnectIconState {
  const ConnectIconDisabled({
    this.icon = ConnectEncoreIcons.devices,
  });

  final EncoreIconPair icon;

  @override
  List<Object?> get props => [icon.small16.id, icon.medium24.id];
}

/// Idle/local built-in speaker state (`s7k`): default devices icon (or local
/// peripheral icon override when inactive) in white `#FFFFFF`.
@immutable
final class ConnectIconIdle extends ConnectIconState {
  const ConnectIconIdle({
    this.icon = ConnectEncoreIcons.devices,
  });

  final EncoreIconPair icon;

  @override
  List<Object?> get props => [icon.small16.id, icon.medium24.id];
}

/// Connecting/transferring state (`r7k`): target device icon (or
/// `ChromecastDisconnected16` for Cast) in white `#FFFFFF` pulsing smoothly
/// with Spotify's `1000ms` infinite reverse alpha animation (`1.0 -> 0.0`).
@immutable
final class ConnectIconConnecting extends ConnectIconState {
  const ConnectIconConnecting({
    required this.icon,
  });

  final EncoreIconPair icon;

  @override
  List<Object?> get props => [icon.small16.id, icon.medium24.id];
}

/// Active/connected state (`q7k`): active device, group, Cast, or external
/// local peripheral Encore icon rendered in `#1ED760` (`textBrightAccent`).
@immutable
final class ConnectIconActive extends ConnectIconState {
  const ConnectIconActive({
    required this.icon,
  });

  final EncoreIconPair icon;

  @override
  List<Object?> get props => [icon.small16.id, icon.medium24.id];
}

/// Pure deterministic mapper converting [ConnectState] + [ConnectOutputStatusPolicy]
/// into Spotify's exact [ConnectIconState] (`p199p/na7.m65063h` + `p199p/byl1.java`).
ConnectIconState resolveConnectIconState(
  ConnectState state, {
  ConnectOutputStatusPolicy policy = ConnectOutputStatusPolicy.instance,
  bool isDisabled = false,
}) {
  if (isDisabled) {
    return const ConnectIconDisabled();
  }

  switch (state.transferState) {
    case TransferInProgress(:final targetDeviceId):
      final ConnectDevice? targetDevice = _findDeviceById(state, targetDeviceId);
      final EncoreIconPair targetIcon = switch (targetDevice) {
        final device? => isCastConnectDevice(device)
            ? ConnectEncoreIcons.chromecastDisconnected
            : resolveConnectDeviceEncoreIcon(device, isConnected: false),
        null => ConnectEncoreIcons.devices,
      };
      return ConnectIconConnecting(icon: targetIcon);
    case TransferIdle():
    case TransferSucceeded():
    case TransferFailed():
      break;
  }

  if (state.activeDevice case final active? when !active.isSelf) {
    return ConnectIconActive(
      icon: resolveConnectDeviceEncoreIcon(active, isConnected: true),
    );
  }

  if (state.activeSelfPeripheral case final peripheral?
      when policy.isExternalLocalPeripheral(peripheral)) {
    return ConnectIconActive(
      icon: resolvePeripheralEncoreIcon(
        category: peripheral.category,
        connectionType: peripheral.connectionType,
        fallbackDeviceType: state.selfDevice?.type,
      ),
    );
  }

  if (state.activeDevice?.outputPeripheral case final devicePeripheral?
      when devicePeripheral.connectionType !=
          OutputPeripheralConnectionType.builtInSpeaker) {
    return ConnectIconActive(
      icon: resolvePeripheralEncoreIcon(
        category: devicePeripheral.category,
        connectionType: devicePeripheral.connectionType,
        fallbackDeviceType: state.activeDevice?.type,
      ),
    );
  }

  return const ConnectIconIdle(icon: ConnectEncoreIcons.devices);
}

ConnectDevice? _findDeviceById(ConnectState state, String targetDeviceId) {
  if (state.activeDevice case final active?
      when active.connectStateIdentifier == targetDeviceId ||
          active.localIdentifier == targetDeviceId) {
    return active;
  }
  if (state.selfDevice case final self?
      when self.connectStateIdentifier == targetDeviceId ||
          self.localIdentifier == targetDeviceId) {
    return self;
  }
  for (final device in state.devices) {
    if (device.connectStateIdentifier == targetDeviceId ||
        device.localIdentifier == targetDeviceId) {
      return device;
    }
  }
  return null;
}

/// Renders Spotify's exact reactive Connect state icon (`p199p/na7.m65058c` &
/// `na7.m65063h`) with 1000ms reverse alpha pulsing during transfers and
/// optional 100ms 10% white circle highlight.
class ConnectStateIcon extends StatefulWidget {
  const ConnectStateIcon({
    super.key,
    required this.iconState,
    this.size = 24.0,
    this.highlightActive = false,
    this.highlightCircleSize = 36.0,
    this.idleColor = ConnectEncoreTheme.textBase,
    this.activeColor = ConnectEncoreTheme.brightAccent,
    this.semanticLabel,
  });

  final ConnectIconState iconState;
  final double size;
  final bool highlightActive;
  final double highlightCircleSize;
  final Color idleColor;
  final Color activeColor;
  final String? semanticLabel;

  @override
  State<ConnectStateIcon> createState() => _ConnectStateIconState();
}

class _ConnectStateIconState extends State<ConnectStateIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      value: 1.0,
    );
    _pulseController = controller;
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant ConnectStateIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconState != widget.iconState) {
      _syncPulseAnimation();
    }
  }

  @override
  void dispose() {
    if (_pulseController case final controller?) {
      controller.dispose();
      _pulseController = null;
    }
    super.dispose();
  }

  void _syncPulseAnimation() {
    final controller = _pulseController;
    if (controller == null) {
      return;
    }
    switch (widget.iconState) {
      case ConnectIconConnecting():
        if (!controller.isAnimating) {
          controller.repeat(reverse: true);
        }
      case ConnectIconDisabled():
      case ConnectIconIdle():
      case ConnectIconActive():
        if (controller.isAnimating) {
          controller.stop();
        }
        controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = switch (widget.iconState) {
      ConnectIconDisabled(:final icon) => ConnectEncoreIcon.pair(
          iconPair: icon,
          size: widget.size,
          color: ConnectEncoreTheme.iconDisabled,
          semanticLabel: widget.semanticLabel,
        ),
      ConnectIconIdle(:final icon) => ConnectEncoreIcon.pair(
          iconPair: icon,
          size: widget.size,
          color: widget.idleColor,
          semanticLabel: widget.semanticLabel,
        ),
      ConnectIconConnecting(:final icon) => switch (_pulseController) {
          final controller? => FadeTransition(
              opacity: controller,
              child: ConnectEncoreIcon.pair(
                iconPair: icon,
                size: widget.size,
                color: ConnectEncoreTheme.textBase,
                semanticLabel: widget.semanticLabel,
              ),
            ),
          null => ConnectEncoreIcon.pair(
              iconPair: icon,
              size: widget.size,
              color: ConnectEncoreTheme.textBase,
              semanticLabel: widget.semanticLabel,
            ),
        },
      ConnectIconActive(:final icon) => ConnectEncoreIcon.pair(
          iconPair: icon,
          size: widget.size,
          color: widget.activeColor,
          semanticLabel: widget.semanticLabel,
        ),
    };

    if (!widget.highlightActive) {
      return iconWidget;
    }

    return SizedBox.square(
      dimension: widget.highlightCircleSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: widget.highlightCircleSize,
            height: widget.highlightCircleSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ConnectEncoreTheme.tintedBase,
            ),
          ),
          iconWidget,
        ],
      ),
    );
  }
}
