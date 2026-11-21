// 1:1 replica of Spotify's Device Picker pinned bottom action footer
// (`p199p/ekp0.java`, `p199p/ksi.java` case 2 `lj91`, `p199p/f4a.java` case 7).

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// Spotify Device Picker pinned bottom action footer (`ekp0` + `ksi` + `f4a`):
/// - Outer padding: `16dp H, 4dp V` (`ksi.java:2427`)
/// - Card gap: `12dp` (`ksi.java:2451`)
/// - Each card: `#2A2A2A` (`elevatedSurface`), `4dp` rounded corners (`ksi.java:2536`),
///   centered vertical column with `24dp` Encore icon + `8dp` gap + `11sp Regular` label
/// - Bluetooth label switches dynamically per `f4a.java:199-203`:
///   - `isBluetoothActive == true`: `"Bluetooth"` in `#1ED760`
///   - `isBluetoothActive == false`: `"Find Bluetooth devices"` in `#FFFFFF`
/// - Jam card is rendered conditionally ONLY when [onStartJam] is non-null.
class DevicePickerFooter extends StatelessWidget {
  const DevicePickerFooter({
    super.key,
    required this.isBluetoothActive,
    required this.onBluetoothTap,
    this.onStartJam,
  });

  final bool isBluetoothActive;
  final VoidCallback? onBluetoothTap;
  final VoidCallback? onStartJam;

  @override
  Widget build(BuildContext context) {
    final bool showJam = onStartJam != null;
    final bool showBluetooth = onBluetoothTap != null;
    if (!showJam && !showBluetooth) {
      return const SizedBox.shrink();
    }

    final Color bluetoothForeground = isBluetoothActive
        ? ConnectEncoreTheme.brightAccent
        : ConnectEncoreTheme.textBase;
    final String bluetoothLabel =
        isBluetoothActive ? 'Bluetooth' : 'Find Bluetooth devices';

    return Padding(
      key: const ValueKey<String>('device_picker_footer'),
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onStartJam case final startJam?) ...[
              Expanded(
                child: _FooterActionCard(
                  key: const ValueKey<String>('footer_start_jam_card'),
                  icon: ConnectEncoreIcons.devices24,
                  label: 'Start a Jam',
                  foregroundColor: ConnectEncoreTheme.textBase,
                  onTap: startJam,
                ),
              ),
              if (showBluetooth) const SizedBox(width: 12.0),
            ],
            if (onBluetoothTap case final openBluetooth?)
              Expanded(
                child: _FooterActionCard(
                  key: const ValueKey<String>('footer_bluetooth_card'),
                  icon: ConnectEncoreIcons.bluetooth24,
                  label: bluetoothLabel,
                  foregroundColor: bluetoothForeground,
                  onTap: openBluetooth,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FooterActionCard extends StatelessWidget {
  const _FooterActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.onTap,
  });

  final EncoreVectorIconData icon;
  final String label;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ConnectEncoreTheme.elevatedSurface,
      borderRadius: BorderRadius.circular(
        ConnectEncoreTheme.footerCardCornerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConnectEncoreIcon(
                icon: icon,
                size: 24.0,
                color: foregroundColor,
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ConnectEncoreTheme.caption11Regular.copyWith(
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
