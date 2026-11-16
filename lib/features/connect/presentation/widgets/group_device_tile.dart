// 1:1 replica of com.spotify.connect.grouping (p199p/c4s0.java, p199p/yzr0.java, p199p/lp30.java, p199p/ug40.java, p199p/rl40.java, p199p/d5r.java, p199p/qk20.java, p199p/txt.java, p199p/qyq.java, p199p/v8k.java)

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';

/// Multi-speaker group sub-item widget matching `p199p/c4s0.java`,
/// `p199p/yzr0.java`, and `p199p/qk20.java`.
///
/// Displays member name, [DeviceType] icon, exhaustive [GroupingStatus] label,
/// per-member volume slider (`SetGroupVolumeRequested` / `StepGroupVolumeRequested`),
/// and group add/remove controls (with the "Stop group playback?" confirmation
/// dialog when `capabilities.removalDissolvesGroup == true`).
class GroupDeviceTile extends StatefulWidget {
  const GroupDeviceTile({
    super.key,
    required this.groupDevice,
    this.groupVolume,
    this.isPending = false,
    this.onVolumeChanged,
    this.onStepVolume,
    this.onRemoveFromGroup,
    this.onAddToGroup,
  });

  final ConnectGroupDevice groupDevice;
  final GroupDeviceVolume? groupVolume;
  final bool isPending;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<int>? onStepVolume;
  final VoidCallback? onRemoveFromGroup;
  final VoidCallback? onAddToGroup;

  @override
  State<GroupDeviceTile> createState() => _GroupDeviceTileState();
}

class _GroupDeviceTileState extends State<GroupDeviceTile> {
  String _resolveGroupingStatusLabel(GroupingStatus status) {
    switch (status) {
      case GroupingStatus.unknown:
        if (widget.groupDevice.modelDisplayName.trim().isNotEmpty) {
          return widget.groupDevice.modelDisplayName;
        }
        return 'Group speaker';
      case GroupingStatus.grouped:
        return 'In group';
      case GroupingStatus.groupable:
        return 'Available to group';
      case GroupingStatus.connecting:
        return 'Connecting...';
    }
  }

  GroupDeviceVolume? _resolveEffectiveGroupVolume() {
    return switch (widget.groupVolume) {
      final overrideVolume? => overrideVolume,
      null => widget.groupDevice.volume,
    };
  }

  Future<void> _handleRemoveTap(
    BuildContext context,
    VoidCallback removeCallback,
  ) async {
    if (!widget.groupDevice.capabilities.removalDissolvesGroup) {
      removeCallback();
      return;
    }

    final deviceName = widget.groupDevice.name;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: PlayerColors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: PlayerColors.divider),
          ),
          title: const Text(
            'Stop group playback?',
            style: TextStyle(
              color: PlayerColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Removing $deviceName will stop playback on all grouped devices.',
            style: const TextStyle(
              color: PlayerColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keep playing',
                style: TextStyle(
                  color: PlayerColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: kSpotifyConnectGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'End group',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }
    if (confirmed == true &&
        widget.groupDevice.groupingStatus == GroupingStatus.grouped &&
        widget.groupDevice.capabilities.removable) {
      if (widget.onRemoveFromGroup case final currentRemoveCallback?) {
        currentRemoveCallback();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.groupDevice;
    final memberId = device.identifiers.groupDeviceIdentifier;
    final GroupingStatus status = device.groupingStatus;
    final GroupDeviceVolume? effectiveVolume = _resolveEffectiveGroupVolume();
    final bool isConnecting = status == GroupingStatus.connecting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PlayerColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                resolveDeviceTypeIcon(device.deviceType),
                size: 22,
                color: status == GroupingStatus.grouped
                    ? kSpotifyConnectGreen
                    : PlayerColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlayerColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resolveGroupingStatusLabel(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isConnecting
                            ? kSpotifyConnectGreen
                            : PlayerColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isPending && !isConnecting)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: kSpotifyConnectGreen,
                    ),
                  ),
                ),
              _buildTrailingControl(context, status, memberId),
            ],
          ),
          if (status == GroupingStatus.grouped && effectiveVolume != null) ...[
            const SizedBox(height: 6),
            _GroupMemberVolumeRow(
              key: ValueKey<String>('group_volume_row_$memberId'),
              memberId: memberId,
              deviceName: device.name,
              effectiveVolume: effectiveVolume,
              onVolumeChanged: widget.onVolumeChanged,
              onStepVolume: widget.onStepVolume,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrailingControl(
    BuildContext context,
    GroupingStatus status,
    String memberId,
  ) {
    switch (status) {
      case GroupingStatus.connecting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: kSpotifyConnectGreen,
          ),
        );
      case GroupingStatus.groupable:
        if (widget.onAddToGroup case final addCallback?) {
          return IconButton(
            key: ValueKey<String>('group_add_$memberId'),
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: kSpotifyConnectGreen,
              size: 22,
            ),
            tooltip: 'Add ${widget.groupDevice.name} to speaker group',
            onPressed: addCallback,
          );
        }
        return const SizedBox.shrink();
      case GroupingStatus.grouped:
        if (widget.groupDevice.capabilities.removable) {
          if (widget.onRemoveFromGroup case final removeCallback?) {
            return IconButton(
              key: ValueKey<String>('group_remove_$memberId'),
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: PlayerColors.textSecondary,
                size: 22,
              ),
              tooltip: 'Remove ${widget.groupDevice.name} from speaker group',
              onPressed: () => _handleRemoveTap(context, removeCallback),
            );
          }
        }
        return const Icon(
          Icons.check_rounded,
          color: kSpotifyConnectGreen,
          size: 20,
        );
      case GroupingStatus.unknown:
        return const SizedBox.shrink();
    }
  }
}

class _GroupMemberVolumeRow extends StatefulWidget {
  const _GroupMemberVolumeRow({
    super.key,
    required this.memberId,
    required this.deviceName,
    required this.effectiveVolume,
    required this.onVolumeChanged,
    required this.onStepVolume,
  });

  final String memberId;
  final String deviceName;
  final GroupDeviceVolume effectiveVolume;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<int>? onStepVolume;

  @override
  State<_GroupMemberVolumeRow> createState() => _GroupMemberVolumeRowState();
}

class _GroupMemberVolumeRowState extends State<_GroupMemberVolumeRow> {
  double? _dragValue;

  @override
  void didUpdateWidget(covariant _GroupMemberVolumeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId ||
        widget.onVolumeChanged == null) {
      _dragValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String memberId = widget.memberId;
    final ValueChanged<double>? onVolumeChanged = widget.onVolumeChanged;
    final ValueChanged<int>? onStepVolume = widget.onStepVolume;
    final double displayVolume = switch (_dragValue) {
      final dragging? => boundNormalizedVolume(dragging),
      null => boundNormalizedVolume(widget.effectiveVolume.volume),
    };
    final int percent = (displayVolume * 100).round();

    return Row(
      children: [
        if (onStepVolume != null)
          IconButton(
            key: ValueKey<String>('group_step_down_$memberId'),
            icon: const Icon(Icons.remove_rounded, size: 18),
            color: PlayerColors.textSecondary,
            tooltip: 'Decrease ${widget.deviceName} volume',
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            onPressed: () => onStepVolume(-1),
          ),
        Expanded(
          key: ValueKey<String>('group_slider_expanded_$memberId'),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6.5,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 14.0,
              ),
              activeTrackColor: kSpotifyConnectGreen,
              inactiveTrackColor: PlayerColors.divider,
              thumbColor: Colors.white,
            ),
            child: Slider(
              key: ValueKey<String>('group_volume_slider_$memberId'),
              value: displayVolume,
              min: 0.0,
              max: 1.0,
              onChangeStart: onVolumeChanged != null
                  ? (value) {
                      setState(() {
                        _dragValue = boundNormalizedVolume(value);
                      });
                    }
                  : null,
              onChanged: onVolumeChanged != null
                  ? (value) {
                      final bounded = boundNormalizedVolume(value);
                      setState(() {
                        _dragValue = bounded;
                      });
                      onVolumeChanged(bounded);
                    }
                  : null,
              onChangeEnd: onVolumeChanged != null
                  ? (value) {
                      final bounded = boundNormalizedVolume(value);
                      setState(() {
                        _dragValue = null;
                      });
                      onVolumeChanged(bounded);
                    }
                  : null,
            ),
          ),
        ),
        if (onStepVolume != null)
          IconButton(
            key: ValueKey<String>('group_step_up_$memberId'),
            icon: const Icon(Icons.add_rounded, size: 18),
            color: PlayerColors.textSecondary,
            tooltip: 'Increase ${widget.deviceName} volume',
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            onPressed: () => onStepVolume(1),
          ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          child: Text(
            '$percent%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: PlayerColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
