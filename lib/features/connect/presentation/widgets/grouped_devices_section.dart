// 1:1 replica of Spotify's expandable speaker group devices section inside the
// Device Picker (`p199p/qk20.java`, `p199p/kl40.java`, `p199p/am40.java`,
// `p199p/zew0.java:309`).

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';

/// Expandable speaker-group members panel rendered beneath the active device
/// card (`p199p/qk20.java` + `p199p/zew0.java`).
class GroupedDevicesSection extends StatelessWidget {
  const GroupedDevicesSection({
    super.key,
    required this.members,
    required this.groupDeviceVolumes,
    required this.pendingGroupDeviceIds,
    required this.onVolumeChanged,
    required this.onStepVolume,
    required this.onAddToGroup,
    required this.onRemoveFromGroup,
  });

  final List<ConnectGroupDevice> members;
  final Map<String, GroupDeviceVolume> groupDeviceVolumes;
  final Set<String> pendingGroupDeviceIds;
  final void Function(String groupDeviceId, double volume) onVolumeChanged;
  final void Function(String groupDeviceId, int direction) onStepVolume;
  final void Function(String groupDeviceId) onAddToGroup;
  final void Function(String groupDeviceId) onRemoveFromGroup;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey<String>('grouped_devices_section'),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: const BoxDecoration(
        color: ConnectEncoreTheme.elevatedSurface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(ConnectEncoreTheme.activeCardCornerRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(
            height: 1.0,
            thickness: 1.0,
            color: ConnectEncoreTheme.tintedBase,
          ),
          for (final member in members)
            _GroupedMemberItem(
              key: ValueKey<String>(
                'group_member_${member.identifiers.groupDeviceIdentifier}',
              ),
              member: member,
              volume: groupDeviceVolumes[member.identifiers.groupDeviceIdentifier],
              isPending: pendingGroupDeviceIds.contains(
                member.identifiers.groupDeviceIdentifier,
              ),
              onVolumeChanged: (value) => onVolumeChanged(
                member.identifiers.groupDeviceIdentifier,
                value,
              ),
              onStepVolume: (dir) => onStepVolume(
                member.identifiers.groupDeviceIdentifier,
                dir,
              ),
              onAddToGroup: () => onAddToGroup(
                member.identifiers.groupDeviceIdentifier,
              ),
              onRemoveFromGroup: () => onRemoveFromGroup(
                member.identifiers.groupDeviceIdentifier,
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupedMemberItem extends StatelessWidget {
  const _GroupedMemberItem({
    super.key,
    required this.member,
    required this.volume,
    required this.isPending,
    required this.onVolumeChanged,
    required this.onStepVolume,
    required this.onAddToGroup,
    required this.onRemoveFromGroup,
  });

  final ConnectGroupDevice member;
  final GroupDeviceVolume? volume;
  final bool isPending;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<int> onStepVolume;
  final VoidCallback onAddToGroup;
  final VoidCallback onRemoveFromGroup;

  @override
  Widget build(BuildContext context) {
    final bool isGrouped = member.groupingStatus == GroupingStatus.grouped;
    final bool isGroupable = member.groupingStatus == GroupingStatus.groupable;
    final bool isRemovable = isGrouped && member.capabilities.removable;
    final GroupDeviceVolume? effectiveVolume = switch (volume) {
      final live? => live,
      null => member.volume,
    };
    final bool showVolumeSlider = isGrouped && effectiveVolume != null;
    final double normalizedVolume = switch (effectiveVolume) {
      final v? => boundNormalizedVolume(v.volume),
      null => 0.0,
    };

    final EncoreIconPair iconPair = resolveDeviceTypeEncoreIcon(member.deviceType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                ConnectEncoreIcon.pair(
                  iconPair: iconPair,
                  size: 24.0,
                  color: isGrouped
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
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ConnectEncoreTheme.deviceRow16Regular.copyWith(
                          color: isGrouped
                              ? ConnectEncoreTheme.textBase
                              : ConnectEncoreTheme.textSubdued,
                        ),
                      ),
                      if (member.modelDisplayName.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            member.modelDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ConnectEncoreTheme.caption11Regular,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isGroupable)
                  IconButton(
                    key: ValueKey<String>(
                      'group_add_${member.identifiers.groupDeviceIdentifier}',
                    ),
                    tooltip: 'Add ${member.name} to group',
                    onPressed: onAddToGroup,
                    icon: const ConnectEncoreIcon(
                      icon: ConnectEncoreIcons.plusAlt24,
                      size: 20.0,
                      color: ConnectEncoreTheme.textBase,
                    ),
                  )
                else if (isRemovable)
                  IconButton(
                    key: ValueKey<String>(
                      'group_remove_${member.identifiers.groupDeviceIdentifier}',
                    ),
                    tooltip: 'Remove ${member.name} from group',
                    onPressed: onRemoveFromGroup,
                    icon: const ConnectEncoreIcon(
                      icon: ConnectEncoreIcons.checkAltFill24,
                      size: 20.0,
                      color: ConnectEncoreTheme.brightAccent,
                    ),
                  ),
              ],
            ),
          ),
          if (showVolumeSlider)
            Padding(
              // Exact 16dp horizontal padding from `zew0.java:309`.
              key: ValueKey<String>(
                'group_device_volume_slider_${member.identifiers.groupDeviceIdentifier}',
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SpotifyVolumeSliderBar(
                value: normalizedVolume,
                deviceName: member.name,
                enabled: !isPending,
                showIcons: true,
                onChanged: onVolumeChanged,
                onStepDown: () => onStepVolume(-1),
                onStepUp: () => onStepVolume(1),
              ),
            ),
        ],
      ),
    );
  }
}
