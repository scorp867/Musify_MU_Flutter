import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';

/// Player utility row hosting Spotify Connect output switcher trigger and
/// Queue drawer sheet trigger.
///
/// Citations:
/// - Decompiled Java: `p199p/ac0.java` (line 51: `device_picker_button`)
/// - Decompiled Java: `p199p/es81.java` (lines 1678-1682: `spotify:connect-device-picker`, `spotify:internal:gaia-picker`)
/// - Decompiled Java: `p199p/nhr.java` (lines 513-567: `R.id.accessory_row`)
/// - Decompiled Java: `p199p/qsq.java` (Connect entrypoint active-state color)
/// - Native binary: `spotify::connect::ConnectDevicesImpl` (`liborbit-jni-spotify.so` @ `0x18e180`)
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

    final Widget deviceButton = switch (effectiveController) {
      final controller? => ValueListenableBuilder<ConnectState>(
          valueListenable: controller,
          builder: (context, state, _) {
            final Color iconColor = policy.isConnectOutputActive(state)
                ? kSpotifyConnectGreen
                : Colors.white60;
            return IconButton(
              icon: Icon(
                Icons.devices_rounded,
                color: iconColor,
                size: 22,
              ),
              tooltip: 'Devices',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: resolvedOnDevice,
            );
          },
        ),
      null => IconButton(
          icon: const Icon(
            Icons.devices_rounded,
            color: Colors.white60,
            size: 22,
          ),
          tooltip: 'Devices',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: resolvedOnDevice,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          deviceButton,
          IconButton(
            icon: const Icon(
              Icons.queue_music_rounded,
              color: Colors.white60,
              size: 24,
            ),
            tooltip: 'Queue',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onQueue,
          ),
        ],
      ),
    );
  }
}
