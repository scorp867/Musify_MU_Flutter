// 1:1 replica of Spotify's Connect entrypoint (`p199p/qsq.java`):
// combines [ConnectStateIcon] + `2dp` gap + optional inline [ConnectDeviceLabel],
// with optional highlight pill container (`qsq.m74387h`).

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_device_label.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_state_icon.dart';

/// Spotify Connect entrypoint combining the reactive Connect state icon and
/// inline active device/connecting label (`p199p/qsq.java`).
class ConnectEntrypointButton extends StatelessWidget {
  const ConnectEntrypointButton({
    super.key,
    required this.onPressed,
    this.connectState,
    this.outputStatusPolicy = ConnectOutputStatusPolicy.instance,
    this.iconSize = 20.0,
    this.showLabel = true,
    this.showBadgeIcon = false,
    this.showHighlightPill = false,
    this.isDisabled = false,
    this.idleColor = ConnectEncoreTheme.textBase,
    this.tooltip = 'Devices',
  });

  final VoidCallback onPressed;
  final ConnectState? connectState;
  final ConnectOutputStatusPolicy outputStatusPolicy;
  final double iconSize;
  final bool showLabel;
  final bool showBadgeIcon;
  final bool showHighlightPill;
  final bool isDisabled;
  final Color idleColor;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ConnectIconState iconState = switch (connectState) {
      final state? => resolveConnectIconState(
          state,
          policy: outputStatusPolicy,
          isDisabled: isDisabled,
        ),
      null => isDisabled
          ? const ConnectIconDisabled()
          : const ConnectIconIdle(),
    };

    final ConnectLabelState labelState = switch (connectState) {
      final state? when showLabel => resolveConnectLabelState(
          state,
          policy: outputStatusPolicy,
        ),
      _ => const ConnectLabelIdle(),
    };

    final bool hasVisibleLabel = labelState is! ConnectLabelIdle;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConnectStateIcon(
          iconState: iconState,
          size: iconSize,
          idleColor: idleColor,
        ),
        if (hasVisibleLabel) ...[
          const SizedBox(width: 6.0),
          Flexible(
            child: ConnectDeviceLabel(
              labelState: labelState,
              textStyle: ConnectEncoreTheme.caption11Regular.copyWith(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
              showBadgeIcon: showBadgeIcon,
            ),
          ),
        ],
      ],
    );

    final Widget wrapped = showHighlightPill && hasVisibleLabel
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: ConnectEncoreTheme.tintedBase,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: content,
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: content,
          );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 44.0,
              minHeight: 44.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1.0,
              child: wrapped,
            ),
          ),
        ),
      ),
    );
  }
}
