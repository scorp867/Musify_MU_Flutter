// 1:1 Spotify Player utility row hosting Spotify Connect entrypoint (`qsq.java`:
// reactive Encore icon + inline active device/connecting label) and Encore Queue trigger.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_entrypoint_button.dart';

/// Player utility row hosting Spotify's `qsq.java` Connect entrypoint
/// (`ConnectStateIcon` + inline `ConnectDeviceLabel`) and Encore Queue trigger.
class PlayerUtilityRow extends StatelessWidget {
  const PlayerUtilityRow({
    super.key,
    required this.onQueue,
    this.onDevice,
    this.connectController,
    this.outputStatusPolicy,
  });

  final VoidCallback onQueue;
  final VoidCallback? onDevice;
  final ConnectMobiusController? connectController;
  final ConnectOutputStatusPolicy? outputStatusPolicy;

  static void _noop() {}

  ConnectMobiusController? _resolveConnectController(BuildContext context) {
    if (connectController case final explicit?) {
      return explicit;
    }
    return context.read<ConnectMobiusController?>();
  }

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
    final effectiveController = _resolveConnectController(context);
    final policy = _resolvePolicy(context);

    final VoidCallback resolvedOnDevice = switch (onDevice) {
      final cb? => cb,
      null => switch (effectiveController) {
          final controller? => () => DevicePickerSheet.show(
                context,
                controller: controller,
              ),
          null => _noop,
        },
    };

    final Widget connectEntrypoint = switch (effectiveController) {
      final controller? => ValueListenableBuilder<ConnectState>(
          valueListenable: controller,
          builder: (context, state, _) {
            return ConnectEntrypointButton(
              key: const ValueKey<String>('player_utility_connect_entrypoint'),
              connectState: state,
              outputStatusPolicy: policy,
              iconSize: 20.0,
              showLabel: true,
              showBadgeIcon: false,
              idleColor: ConnectEncoreTheme.textSubdued,
              onPressed: resolvedOnDevice,
            );
          },
        ),
      null => ConnectEntrypointButton(
          key: const ValueKey<String>('player_utility_connect_entrypoint'),
          connectState: null,
          outputStatusPolicy: policy,
          iconSize: 20.0,
          showLabel: false,
          idleColor: ConnectEncoreTheme.textSubdued,
          onPressed: resolvedOnDevice,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: connectEntrypoint),
          IconButton(
            key: const ValueKey<String>('player_utility_queue_button'),
            icon: const ConnectEncoreIcon(
              icon: ConnectEncoreIcons.queue24,
              color: ConnectEncoreTheme.textSubdued,
              size: 20.0,
            ),
            tooltip: 'Queue',
            padding: const EdgeInsets.all(8.0),
            constraints: const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
            onPressed: onQueue,
          ),
        ],
      ),
    );
  }
}
