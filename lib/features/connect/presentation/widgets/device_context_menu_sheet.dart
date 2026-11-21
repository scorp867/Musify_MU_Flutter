// 1:1 replica of Spotify's Device Context Menu bottom sheet and Rename dialog
// (`p199p/cup.java`, `p199p/c8r.java`).

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// Action selected from [DeviceContextMenuSheet].
@immutable
sealed class DeviceContextAction {
  const DeviceContextAction();
}

@immutable
final class RenameDeviceAction extends DeviceContextAction {
  const RenameDeviceAction();
}

@immutable
final class LogoutDeviceAction extends DeviceContextAction {
  const LogoutDeviceAction();
}

@immutable
final class SelectPreferredIncarnationAction extends DeviceContextAction {
  const SelectPreferredIncarnationAction(this.loginType);

  final IncarnationLoginType loginType;
}

@immutable
final class InstallSpotifyAction extends DeviceContextAction {
  const InstallSpotifyAction();
}

/// Returns `true` when [device] exposes at least one context menu action.
bool hasDeviceContextMenuActions(ConnectDevice device) {
  if (device.isSelf) {
    return false;
  }
  return device.supportsRename ||
      device.supportsLogout ||
      device.incarnations.length > 1 ||
      device.state == ConnectDeviceState.notInstalled ||
      device.state == ConnectDeviceState.installationAvailable;
}

/// Spotify dark context menu bottom sheet for a Connect device (`p199p/cup.java`,
/// `p199p/c8r.java`).
class DeviceContextMenuSheet extends StatelessWidget {
  const DeviceContextMenuSheet({
    super.key,
    required this.device,
  });

  final ConnectDevice device;

  static Future<DeviceContextAction?> show(
    BuildContext context, {
    required ConnectDevice device,
  }) {
    return showModalBottomSheet<DeviceContextAction>(
      context: context,
      useRootNavigator: true,
      backgroundColor: ConnectEncoreTheme.sheetBackground,
      barrierColor: ConnectEncoreTheme.scrimBarrier,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ConnectEncoreTheme.devicePickerSheetCornerRadius),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: DeviceContextMenuSheet(device: device),
        );
      },
    );
  }

  static String _incarnationLabel(IncarnationLoginType loginType) {
    switch (loginType) {
      case IncarnationLoginType.connect:
        return 'Spotify Connect';
      case IncarnationLoginType.cast:
        return 'Google Cast';
      case IncarnationLoginType.castJs:
        return 'Google Cast (Web)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final EncoreIconPair iconPair = resolveConnectDeviceEncoreIcon(
      device,
      isConnected: device.isActive,
    );
    final bool canInstall = device.state == ConnectDeviceState.notInstalled ||
        device.state == ConnectDeviceState.installationAvailable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10.0, bottom: 12.0),
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: ConnectEncoreTheme.dragHandle,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 14.0),
            child: Row(
              children: [
                ConnectEncoreIcon.pair(
                  iconPair: iconPair,
                  size: 24.0,
                  color: device.isActive
                      ? ConnectEncoreTheme.brightAccent
                      : ConnectEncoreTheme.textSubdued,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ConnectEncoreTheme.section16Bold,
                      ),
                      if (device.brandDisplayName.trim().isNotEmpty ||
                          device.modelDisplayName.trim().isNotEmpty)
                        Text(
                          <String>[
                            if (device.brandDisplayName.trim().isNotEmpty)
                              device.brandDisplayName.trim(),
                            if (device.modelDisplayName.trim().isNotEmpty)
                              device.modelDisplayName.trim(),
                          ].join(' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ConnectEncoreTheme.caption11Regular,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1.0,
            thickness: 1.0,
            color: ConnectEncoreTheme.tintedBase,
          ),
          if (canInstall)
            _ContextMenuTile(
              key: const ValueKey<String>('context_action_install'),
              icon: ConnectEncoreIcons.plusAlt24,
              label: 'Install Spotify',
              onTap: () => Navigator.of(context).pop(const InstallSpotifyAction()),
            ),
          if (device.supportsRename && !device.isSelf)
            _ContextMenuTile(
              key: const ValueKey<String>('context_action_rename'),
              icon: ConnectEncoreIcons.deviceOther24,
              label: 'Rename device',
              onTap: () => Navigator.of(context).pop(const RenameDeviceAction()),
            ),
          if (device.incarnations.length > 1 && !device.isSelf) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
              child: Text(
                'Preferred connection',
                style: ConnectEncoreTheme.caption11Bold,
              ),
            ),
            for (final incarnation in device.incarnations)
              if (incarnation.parsedLoginType case final parsedType?)
                _ContextMenuTile(
                  key: ValueKey<String>(
                    'context_action_incarnation_${parsedType.name}',
                  ),
                  icon: incarnation.preferred
                      ? ConnectEncoreIcons.checkAltFill24
                      : ConnectEncoreIcons.devices24,
                  iconColor: incarnation.preferred
                      ? ConnectEncoreTheme.brightAccent
                      : ConnectEncoreTheme.textSubdued,
                  label: _incarnationLabel(parsedType),
                  onTap: () => Navigator.of(context).pop(
                    SelectPreferredIncarnationAction(parsedType),
                  ),
                ),
          ],
          if (device.supportsLogout && !device.isSelf)
            _ContextMenuTile(
              key: const ValueKey<String>('context_action_logout'),
              icon: ConnectEncoreIcons.exclamationCircle24,
              label: 'Forget device',
              onTap: () => Navigator.of(context).pop(const LogoutDeviceAction()),
            ),
        ],
      ),
    );
  }
}

class _ContextMenuTile extends StatelessWidget {
  const _ContextMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = ConnectEncoreTheme.textSubdued,
  });

  final EncoreVectorIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            ConnectEncoreIcon(
              icon: icon,
              size: 20.0,
              color: iconColor,
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                label,
                style: ConnectEncoreTheme.deviceRow16Regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spotify dark dialog to rename a Connect device (`RenameDeviceRequested`).
class RenameConnectDeviceDialog extends StatefulWidget {
  const RenameConnectDeviceDialog({
    super.key,
    required this.initialName,
  });

  final String initialName;

  static Future<String?> show(
    BuildContext context, {
    required String initialName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameConnectDeviceDialog(initialName: initialName),
    );
  }

  @override
  State<RenameConnectDeviceDialog> createState() =>
      _RenameConnectDeviceDialogState();
}

class _RenameConnectDeviceDialogState extends State<RenameConnectDeviceDialog> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    if (_controller case final ctrl?) {
      ctrl.dispose();
      _controller = null;
    }
    super.dispose();
  }

  void _submit() {
    final text = switch (_controller?.text) {
      final value? => value.trim(),
      null => '',
    };
    if (text.isEmpty) {
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    if (ctrl == null) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      backgroundColor: ConnectEncoreTheme.elevatedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: const Text(
        'Rename device',
        style: ConnectEncoreTheme.section16Bold,
      ),
      content: TextField(
        key: const ValueKey<String>('rename_device_text_field'),
        controller: ctrl,
        autofocus: true,
        style: ConnectEncoreTheme.deviceRow16Regular,
        cursorColor: ConnectEncoreTheme.brightAccent,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Device name',
          hintStyle: ConnectEncoreTheme.bodySmall13Regular,
          filled: true,
          fillColor: ConnectEncoreTheme.sheetBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: ConnectEncoreTheme.tintedBase),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: ConnectEncoreTheme.brightAccent,
              width: 1.5,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: ConnectEncoreTheme.textSubdued),
          ),
        ),
        TextButton(
          key: const ValueKey<String>('confirm_rename_device_button'),
          onPressed: _submit,
          child: const Text(
            'Save',
            style: TextStyle(
              color: ConnectEncoreTheme.brightAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
