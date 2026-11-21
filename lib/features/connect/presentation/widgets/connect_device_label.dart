// 1:1 replica of Spotify's `connect_label` (`p199p/jgb.java` `m54989d` &
// `m54996k`, `p199p/r9k.java`, `p199p/bcb1.java`, `res/layout/device_name_label.xml`).

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/spotify_marquee_text.dart';

/// Exact 5-variant badge enum matching Spotify's `p199p/bcb1.java` (`jgb.m54996k`).
enum ConnectLabelBadge {
  chromecast, // ordinal 0: ChromecastConnected16 (gnw)
  bluetooth, // ordinal 1: Bluetooth16 (lmw)
  airPlay, // ordinal 2: AirPlay16 (plw)
  spotifyConnect, // ordinal 3: SpotifyConnect16 (iuw)
  none, // ordinal 4: hidden
}

/// Exhaustive sealed Connect device label state matching Spotify's `p199p/r9k.java`.
@immutable
sealed class ConnectLabelState extends Equatable {
  const ConnectLabelState();
}

/// Idle/local built-in state: no Connect device label shown.
@immutable
final class ConnectLabelIdle extends ConnectLabelState {
  const ConnectLabelIdle();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Connecting/transferring state: displays `"Connecting..."` (or target status)
/// in white `#FFFFFF`.
@immutable
final class ConnectLabelConnecting extends ConnectLabelState {
  const ConnectLabelConnecting({
    required this.text,
  });

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Active Connect or external peripheral state: displays active output name in
/// `#1ED760` (`textBrightAccent`) with optional `12dp` protocol badge icon.
@immutable
final class ConnectLabelActive extends ConnectLabelState {
  const ConnectLabelActive({
    required this.text,
    this.badge = ConnectLabelBadge.none,
  });

  final String text;
  final ConnectLabelBadge badge;

  @override
  List<Object?> get props => [text, badge];
}

/// Resolves the protocol badge icon (`bcb1`) for an active Connect output.
ConnectLabelBadge resolveConnectLabelBadge(
  ConnectState state, {
  ConnectOutputStatusPolicy policy = ConnectOutputStatusPolicy.instance,
}) {
  if (state.activeDevice case final active? when !active.isSelf) {
    if (isCastConnectDevice(active)) {
      return ConnectLabelBadge.chromecast;
    }
    if (active.outputPeripheral?.connectionType ==
        OutputPeripheralConnectionType.airplay) {
      return ConnectLabelBadge.airPlay;
    }
    if (active.outputPeripheral?.connectionType ==
        OutputPeripheralConnectionType.bluetooth) {
      return ConnectLabelBadge.bluetooth;
    }
    return ConnectLabelBadge.spotifyConnect;
  }

  if (state.activeSelfPeripheral case final peripheral?
      when policy.isExternalLocalPeripheral(peripheral)) {
    switch (peripheral.connectionType) {
      case OutputPeripheralConnectionType.bluetooth:
        return ConnectLabelBadge.bluetooth;
      case OutputPeripheralConnectionType.airplay:
        return ConnectLabelBadge.airPlay;
      case OutputPeripheralConnectionType.wired:
      case OutputPeripheralConnectionType.carProjected:
      case OutputPeripheralConnectionType.builtInSpeaker:
      case OutputPeripheralConnectionType.unknown:
        return ConnectLabelBadge.none;
    }
  }

  return ConnectLabelBadge.none;
}

/// Pure deterministic mapper from [ConnectState] to Spotify's [ConnectLabelState].
ConnectLabelState resolveConnectLabelState(
  ConnectState state, {
  ConnectOutputStatusPolicy policy = ConnectOutputStatusPolicy.instance,
}) {
  switch (state.transferState) {
    case TransferInProgress():
      return const ConnectLabelConnecting(text: 'Connecting...');
    case TransferIdle():
    case TransferSucceeded():
    case TransferFailed():
      break;
  }

  if (!policy.isConnectOutputActive(state)) {
    return const ConnectLabelIdle();
  }

  final String label = policy.resolveActiveOutputLabel(
    activeDevice: state.activeDevice,
    selfDevice: state.selfDevice,
    activeSelfPeripheral: state.activeSelfPeripheral,
  );
  if (label.trim().isEmpty) {
    return const ConnectLabelIdle();
  }

  return ConnectLabelActive(
    text: label,
    badge: resolveConnectLabelBadge(state, policy: policy),
  );
}

/// Renders Spotify's exact `connect_label` row (`jgb.m54989d` + `m54996k`):
/// optional `12dp` protocol badge icon + `4dp` gap + `11sp` single-line
/// marquee text (`#1ED760` when active, `#FFFFFF` when connecting).
class ConnectDeviceLabel extends StatelessWidget {
  const ConnectDeviceLabel({
    super.key,
    required this.labelState,
    this.textStyle = ConnectEncoreTheme.caption11Regular,
    this.activeColor = ConnectEncoreTheme.brightAccent,
    this.connectingColor = ConnectEncoreTheme.textBase,
    this.showBadgeIcon = true,
    this.enableMarquee = true,
  });

  final ConnectLabelState labelState;
  final TextStyle textStyle;
  final Color activeColor;
  final Color connectingColor;
  final bool showBadgeIcon;
  final bool enableMarquee;

  EncoreVectorIconData? _resolveBadgeVector(ConnectLabelBadge badge) {
    switch (badge) {
      case ConnectLabelBadge.chromecast:
        return ConnectEncoreIcons.chromecastConnected16;
      case ConnectLabelBadge.bluetooth:
        return ConnectEncoreIcons.bluetooth16;
      case ConnectLabelBadge.airPlay:
        return ConnectEncoreIcons.airPlay16;
      case ConnectLabelBadge.spotifyConnect:
        return ConnectEncoreIcons.spotifyConnect16;
      case ConnectLabelBadge.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (labelState) {
      case ConnectLabelIdle():
        return const SizedBox.shrink();
      case ConnectLabelConnecting(:final text):
        return SpotifyMarqueeText(
          text: text,
          style: textStyle.copyWith(color: connectingColor),
          enableMarquee: enableMarquee,
        );
      case ConnectLabelActive(:final text, :final badge):
        final EncoreVectorIconData? badgeIcon =
            showBadgeIcon ? _resolveBadgeVector(badge) : null;
        final TextStyle resolvedStyle = textStyle.copyWith(color: activeColor);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (badgeIcon != null) ...[
              ConnectEncoreIcon(
                icon: badgeIcon,
                size: 12.0,
                color: activeColor,
              ),
              const SizedBox(width: 4.0),
            ],
            Flexible(
              child: SpotifyMarqueeText(
                text: text,
                style: resolvedStyle,
                enableMarquee: enableMarquee,
              ),
            ),
          ],
        );
    }
  }
}
