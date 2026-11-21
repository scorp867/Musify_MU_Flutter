// 1:1 replica of Spotify's Active Device Card in Device Picker Sheet
// (`p199p/frl1.java`, `p199p/C2255rx.java` case 2, `p199p/c4s0.java`,
// `p199p/rdl1.java`, `p199p/C2545zr.java` case 29, `p199p/coj1.java` `m35021h`).

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';
import 'package:musify_mu/features/connect/presentation/widgets/playing_equalizer_indicator.dart';
import 'package:musify_mu/features/connect/presentation/widgets/spotify_marquee_text.dart';
import 'package:musify_mu/features/player/domain/models/bitrate_level.dart';
import 'package:musify_mu/features/player/domain/models/hifi_status.dart';
import 'package:musify_mu/features/player/domain/models/playback_quality.dart';

/// Streaming quality badge descriptor rendered next to the active device name
/// (`p199p/c4s0.java` lines 2310-2450).
@immutable
final class ActiveCardQualityBadge {
  const ActiveCardQualityBadge({
    required this.label,
    this.isHighlight = false,
  });

  final String label;
  final bool isHighlight;
}

/// Resolves the Spotify streaming quality pill label from real Musify
/// [ConnectHifiStatus] and/or [PlaybackQuality] data.
ActiveCardQualityBadge? resolveActiveCardQualityBadge({
  required ConnectDevice? activeDevice,
  required PlaybackQuality? playbackQuality,
}) {
  if (playbackQuality case final quality?) {
    if (quality.hifiStatus == HiFiStatus.on) {
      return const ActiveCardQualityBadge(
        label: 'Lossless',
        isHighlight: true,
      );
    }
    switch (quality.bitrateLevel) {
      case BitrateLevel.hifi:
      case BitrateLevel.hifi24:
        return const ActiveCardQualityBadge(
          label: 'Lossless',
          isHighlight: true,
        );
      case BitrateLevel.veryHigh:
        return const ActiveCardQualityBadge(label: 'Very high');
      case BitrateLevel.high:
        return const ActiveCardQualityBadge(label: 'High');
      case BitrateLevel.normal:
        return const ActiveCardQualityBadge(label: 'Normal');
      case BitrateLevel.low:
        return const ActiveCardQualityBadge(label: 'Low');
      case BitrateLevel.unknown:
        break;
    }
  }
  if (activeDevice case final device? when device.hifi.fullySupported) {
    return const ActiveCardQualityBadge(
      label: 'Lossless',
      isHighlight: true,
    );
  }
  return null;
}

/// Spotify's elevated Active Device Card (`#2A2A2A`, `16dp` corners, `8dp` H margin)
/// showing the active device title (`24sp Bold`), streaming quality pill badge,
/// optional `elbow-connector` peripheral subtitle, live `"Title – Artist"` marquee
/// with 3-bar equalizer (`#1ED760`), right `48dp` `#1ED760` device icon, and
/// embedded remote volume slider.
class DevicePickerActiveCard extends StatelessWidget {
  const DevicePickerActiveCard({
    super.key,
    required this.connectState,
    required this.controller,
    required this.outputStatusPolicy,
    this.playbackQuality,
    this.nowPlayingTitle,
    this.nowPlayingArtist,
    this.isPlaying = false,
    this.hasGroupedDevicesBelow = false,
    this.isGroupExpanded = false,
    this.onToggleGroupExpanded,
    this.onTapCard,
    this.onOpenContextMenu,
  });

  final ConnectState connectState;
  final ConnectMobiusController controller;
  final ConnectOutputStatusPolicy outputStatusPolicy;
  final PlaybackQuality? playbackQuality;
  final String? nowPlayingTitle;
  final String? nowPlayingArtist;
  final bool isPlaying;
  final bool hasGroupedDevicesBelow;
  final bool isGroupExpanded;
  final VoidCallback? onToggleGroupExpanded;
  final VoidCallback? onTapCard;
  final VoidCallback? onOpenContextMenu;

  String _resolvePrimaryTitle() {
    switch (connectState.transferState) {
      case TransferInProgress(:final targetDeviceId):
        final target = outputStatusPolicy.resolveTransferTargetLabel(
          targetDeviceId: targetDeviceId,
          activeDevice: connectState.activeDevice,
          selfDevice: connectState.selfDevice,
          activeSelfPeripheral: connectState.activeSelfPeripheral,
          devices: connectState.devices,
        );
        return 'Connecting to $target';
      case TransferIdle():
      case TransferSucceeded():
      case TransferFailed():
        break;
    }

    if (connectState.activeDevice case final active? when !active.isSelf) {
      final trimmed = active.name.trim();
      return trimmed.isNotEmpty ? active.name : 'Device';
    }

    final effectiveSelf = switch (connectState.selfDevice) {
      final self? => self,
      null => connectState.activeDevice,
    };
    return outputStatusPolicy.resolveBuiltInSpeakerLabel(effectiveSelf?.type);
  }

  String? _resolvePeripheralSubtitle() {
    if (connectState.transferState is TransferInProgress) {
      return 'Connecting...';
    }

    final activeDevice = connectState.activeDevice;
    if (activeDevice != null && !activeDevice.isSelf) {
      if (activeDevice.outputPeripheral case final peripheral?) {
        if (peripheral.name case final name? when name.trim().isNotEmpty) {
          return name;
        }
      }
      if (isCastConnectDevice(activeDevice)) {
        return 'Google Cast';
      }
      if (activeDevice.brandDisplayName.trim().isNotEmpty) {
        return activeDevice.brandDisplayName;
      }
      return null;
    }

    if (connectState.activeSelfPeripheral case final localPeripheral?
        when outputStatusPolicy.isExternalLocalPeripheral(localPeripheral)) {
      if (localPeripheral.name.trim().isNotEmpty) {
        return localPeripheral.name;
      }
    }
    return null;
  }

  EncoreIconPair? _resolvePeripheralSubtitleIcon() {
    if (connectState.transferState is TransferInProgress) {
      return null;
    }
    final activeDevice = connectState.activeDevice;
    if (activeDevice != null && !activeDevice.isSelf) {
      if (activeDevice.outputPeripheral case final peripheral?) {
        if (peripheral.connectionType ==
            OutputPeripheralConnectionType.bluetooth) {
          return ConnectEncoreIcons.bluetooth;
        }
        if (peripheral.connectionType ==
            OutputPeripheralConnectionType.airplay) {
          return ConnectEncoreIcons.airPlay;
        }
      }
      if (isCastConnectDevice(activeDevice)) {
        return ConnectEncoreIcons.chromecastConnected;
      }
      return null;
    }
    if (connectState.activeSelfPeripheral case final localPeripheral?
        when outputStatusPolicy.isExternalLocalPeripheral(localPeripheral)) {
      if (localPeripheral.connectionType ==
          OutputPeripheralConnectionType.bluetooth) {
        return ConnectEncoreIcons.bluetooth;
      }
      return resolvePeripheralEncoreIcon(
        category: localPeripheral.category,
        connectionType: localPeripheral.connectionType,
      );
    }
    return null;
  }

  EncoreIconPair _resolveActiveDeviceIcon() {
    if (connectState.activeDevice case final active?) {
      if (!active.isSelf) {
        return resolveConnectDeviceEncoreIcon(
          active,
          isConnected: true,
          preferDeviceIconOverPeripheral: true,
        );
      }
      if (connectState.activeSelfPeripheral case final localPeripheral?
          when outputStatusPolicy.isExternalLocalPeripheral(localPeripheral)) {
        return resolvePeripheralEncoreIcon(
          category: localPeripheral.category,
          connectionType: localPeripheral.connectionType,
          fallbackDeviceType: active.type,
        );
      }
      return resolveDeviceTypeEncoreIcon(active.type);
    }

    if (connectState.activeSelfPeripheral case final localPeripheral?
        when outputStatusPolicy.isExternalLocalPeripheral(localPeripheral)) {
      return resolvePeripheralEncoreIcon(
        category: localPeripheral.category,
        connectionType: localPeripheral.connectionType,
        fallbackDeviceType: connectState.selfDevice?.type,
      );
    }

    return switch (connectState.selfDevice) {
      final self? => resolveDeviceTypeEncoreIcon(self.type),
      null => ConnectEncoreIcons.deviceMobile,
    };
  }

  String? _buildNowPlayingLine() {
    final String title = switch (nowPlayingTitle) {
      final t? => t.trim(),
      null => '',
    };
    if (title.isEmpty) {
      return null;
    }
    final String artist = switch (nowPlayingArtist) {
      final a? => a.trim(),
      null => '',
    };
    if (artist.isEmpty) {
      return title;
    }
    // Exact separator captured on live Spotify 9.1.92.3058: "Title – Artist"
    return '$title \u2013 $artist';
  }

  @override
  Widget build(BuildContext context) {
    final ConnectDevice? activeDevice = connectState.activeDevice;
    final String title = _resolvePrimaryTitle();
    final String? peripheralSubtitle = _resolvePeripheralSubtitle();
    final EncoreIconPair? peripheralIcon = _resolvePeripheralSubtitleIcon();
    final String? nowPlayingLine = _buildNowPlayingLine();
    final ActiveCardQualityBadge? qualityBadge = resolveActiveCardQualityBadge(
      activeDevice: activeDevice,
      playbackQuality: playbackQuality,
    );
    final EncoreIconPair activeIconPair = _resolveActiveDeviceIcon();

    final bool showVolumeSlider = activeDevice != null &&
        !activeDevice.isSelf &&
        (!activeDevice.isLocal ||
            connectState.volumeState.isRemoteVolumeControllable);

    final double bottomRadius =
        (hasGroupedDevicesBelow && isGroupExpanded)
            ? 0.0
            : ConnectEncoreTheme.activeCardCornerRadius;

    return Container(
      key: const ValueKey<String>('active_device_card'),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: ConnectEncoreTheme.elevatedSurface,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(ConnectEncoreTheme.activeCardCornerRadius),
          bottom: Radius.circular(bottomRadius),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapCard,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(ConnectEncoreTheme.activeCardCornerRadius),
            bottom: Radius.circular(bottomRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: 24sp Bold title + 8dp gap + quality pill + optional context indicator
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  key: const ValueKey<String>(
                                    'active_device_card_title',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ConnectEncoreTheme.title24Bold,
                                ),
                              ),
                              if (qualityBadge case final badge?) ...[
                                const SizedBox(width: 8.0),
                                _StreamingQualityPill(badge: badge),
                              ],
                              if (onOpenContextMenu case final openMenu?) ...[
                                const SizedBox(width: 4.0),
                                GestureDetector(
                                  key: const ValueKey<String>(
                                    'active_device_context_menu_button',
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: openMenu,
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: ConnectEncoreIcon(
                                      icon: ConnectEncoreIcons.more16,
                                      size: 16.0,
                                      color: ConnectEncoreTheme.textSubdued,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Row 2 (4dp below): elbow-connector + peripheral icon + 13sp subtitle
                          if (peripheralSubtitle case final subtitle?) ...[
                            const SizedBox(height: 4.0),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 2.0),
                                  child: SizedBox(
                                    key: ValueKey<String>('elbow_connector'),
                                    width: 8.0,
                                    height: 10.0,
                                    child: CustomPaint(
                                      painter: _ElbowConnectorPainter(
                                        color: ConnectEncoreTheme.textSubdued,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                if (peripheralIcon case final pIcon?) ...[
                                  ConnectEncoreIcon.pair(
                                    iconPair: pIcon,
                                    size: 16.0,
                                    color: ConnectEncoreTheme.textSubdued,
                                  ),
                                  const SizedBox(width: 4.0),
                                ],
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    key: const ValueKey<String>(
                                      'active_device_card_subtitle',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        ConnectEncoreTheme.bodySmall13Regular,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Row 3 (8dp below): 16dp 3-bar equalizer + 4dp gap + green marquee "Title – Artist"
                          if (nowPlayingLine case final trackLine?) ...[
                            const SizedBox(height: 8.0),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (isPlaying) ...[
                                  const PlayingEqualizerIndicator(
                                    key: ValueKey<String>(
                                      'active_card_equalizer',
                                    ),
                                    isPlaying: true,
                                    size: 16.0,
                                    color: ConnectEncoreTheme.brightAccent,
                                  ),
                                  const SizedBox(width: 4.0),
                                ],
                                Expanded(
                                  child: SpotifyMarqueeText(
                                    key: const ValueKey<String>(
                                      'active_card_now_playing_text',
                                    ),
                                    text: trackLine,
                                    style: ConnectEncoreTheme.bodySmall13Regular
                                        .copyWith(
                                      color: ConnectEncoreTheme.brightAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Right 48dp active device Encore icon in #1ED760 (`C2255rx`).
                    ConnectEncoreIcon.pair(
                      key: const ValueKey<String>('active_device_icon'),
                      iconPair: activeIconPair,
                      size: 48.0,
                      color: ConnectEncoreTheme.brightAccent,
                    ),
                  ],
                ),
              ),

              if (showVolumeSlider) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ConnectVolumeSlider(
                    controller: controller,
                    deviceName: activeDevice.name,
                  ),
                ),
              ],

              if (hasGroupedDevicesBelow && onToggleGroupExpanded != null) ...[
                const Divider(
                  height: 1.0,
                  thickness: 1.0,
                  color: ConnectEncoreTheme.tintedBase,
                ),
                InkWell(
                  key: const ValueKey<String>('toggle_grouped_devices_button'),
                  onTap: onToggleGroupExpanded,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Grouped speakers',
                            style: ConnectEncoreTheme.bodySmall13Bold,
                          ),
                        ),
                        ConnectEncoreIcon(
                          icon: isGroupExpanded
                              ? ConnectEncoreIcons.chevronUp16
                              : ConnectEncoreIcons.chevronDown16,
                          size: 16.0,
                          color: ConnectEncoreTheme.textSubdued,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StreamingQualityPill extends StatelessWidget {
  const _StreamingQualityPill({
    required this.badge,
  });

  final ActiveCardQualityBadge badge;

  @override
  Widget build(BuildContext context) {
    final Color foreground = badge.isHighlight
        ? ConnectEncoreTheme.brightAccent
        : ConnectEncoreTheme.textSubdued;

    return Container(
      key: const ValueKey<String>('streaming_quality_pill'),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: ConnectEncoreTheme.tintedBase,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        badge.label,
        style: ConnectEncoreTheme.caption11Bold.copyWith(color: foreground),
      ),
    );
  }
}

/// Exact 8x10dp elbow-connector canvas from `p199p/C2545zr.java` (lines 275-285)
/// and `p199p/rdl1.java:344`.
final class _ElbowConnectorPainter extends CustomPainter {
  const _ElbowConnectorPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerRadius = 2.0;
    final double w = size.width;
    final double h = size.height;

    final path = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(0.0, h - cornerRadius)
      ..quadraticBezierTo(0.0, h, cornerRadius, h)
      ..lineTo(w, h);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ElbowConnectorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
