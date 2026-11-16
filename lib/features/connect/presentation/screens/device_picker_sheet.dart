// 1:1 replica of com.spotify.connect.devicepicker (p199p/lxs.java, p199p/asq.java, p199p/n5o0.java, p199p/r3h0.java, p199p/gkp0.java, p199p/l8d0.java)

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/widgets/active_device_banner.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_header.dart';
import 'package:musify_mu/features/connect/presentation/widgets/group_device_tile.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';

/// Spotify Connect Output Switcher modal bottom sheet matching `p199p/lxs.java`,
/// `p199p/asq.java`, `p199p/n5o0.java`, `p199p/r3h0.java`, and `p199p/gkp0.java`.
class DevicePickerSheet extends StatefulWidget {
  const DevicePickerSheet({
    super.key,
    required this.controller,
    this.autoRefreshOnOpen = true,
    this.scrollController,
  });

  final ConnectMobiusController controller;
  final bool autoRefreshOnOpen;
  final ScrollController? scrollController;

  /// Presents [DevicePickerSheet] inside a modal bottom sheet bounded to 85%
  /// of the viewport height.
  static Future<void> show(
    BuildContext context, {
    required ConnectMobiusController controller,
    bool autoRefreshOnOpen = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: PlayerColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: DevicePickerSheet(
                controller: controller,
                autoRefreshOnOpen: autoRefreshOnOpen,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<DevicePickerSheet> {
  ScrollController? _ownedScrollController;

  ScrollController get _effectiveScrollController {
    if (widget.scrollController case final external?) {
      return external;
    }
    if (_ownedScrollController case final owned?) {
      return owned;
    }
    throw StateError(
      'DevicePickerSheet ScrollController invariant violated: '
      'both external and owned ScrollControllers are null.',
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }
    if (widget.autoRefreshOnOpen) {
      _triggerRefresh();
    }
  }

  @override
  void didUpdateWidget(covariant DevicePickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final owned = _ownedScrollController;
    if (widget.scrollController == null) {
      if (owned == null) {
        _ownedScrollController = ScrollController();
      }
    } else if (owned != null) {
      owned.dispose();
      _ownedScrollController = null;
    }

    if (widget.controller != oldWidget.controller && widget.autoRefreshOnOpen) {
      _triggerRefresh();
    }
  }

  @override
  void dispose() {
    if (_ownedScrollController case final owned?) {
      owned.dispose();
      _ownedScrollController = null;
    }
    super.dispose();
  }

  void _triggerRefresh() {
    if (widget.controller.isClosed) {
      return;
    }
    widget.controller.dispatch(const RefreshClusterRequested());
    widget.controller.dispatch(const PerformDiscoveryRequested());
    widget.controller.dispatch(const WakeSleepingDevicesRequested());
  }

  void _handleDeviceTap(ConnectDevice device) {
    if (widget.controller.isClosed) {
      return;
    }
    final targetId = resolveDeviceTargetIdentifier(device);
    if (device.state == ConnectDeviceState.notInstalled ||
        device.state == ConnectDeviceState.installationAvailable) {
      if (targetId.isNotEmpty) {
        widget.controller.dispatch(
          InstallSpotifyRequested(deviceIdentifier: targetId),
        );
      }
      return;
    }
    if (device.isSelf) {
      if (!device.isActive) {
        widget.controller.dispatch(const PullPlaybackRequested());
      }
      return;
    }
    if (device.isActive) {
      widget.controller.dispatch(const PullPlaybackRequested());
      return;
    }
    if (targetId.isNotEmpty) {
      widget.controller.dispatch(
        TransferToDeviceRequested(deviceIdentifier: targetId),
      );
    }
  }

  void _handleLogout(ConnectDevice device) {
    if (widget.controller.isClosed) {
      return;
    }
    final targetId = resolveDeviceTargetIdentifier(device);
    if (targetId.isNotEmpty) {
      widget.controller.dispatch(
        LogoutDeviceRequested(deviceIdentifier: targetId),
      );
    }
  }

  void _handleInstall(ConnectDevice device) {
    if (widget.controller.isClosed) {
      return;
    }
    final targetId = resolveDeviceTargetIdentifier(device);
    if (targetId.isNotEmpty) {
      widget.controller.dispatch(
        InstallSpotifyRequested(deviceIdentifier: targetId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompactViewport = MediaQuery.sizeOf(context).height < 600.0;

    return ValueListenableBuilder<ConnectState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        final List<Widget> scrollChildren = _buildScrollContent(state);

        if (isCompactViewport) {
          return ListView(
            controller: _effectiveScrollController,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              DevicePickerHeader(
                activeDevice: state.activeDevice,
                activeSelfPeripheral: state.activeSelfPeripheral,
                selfDevice: state.selfDevice,
                devices: state.devices,
                transferState: state.transferState,
                isSyncedWithBackend: state.isSyncedWithBackend,
                onRefresh: _triggerRefresh,
              ),
              const Divider(color: PlayerColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...scrollChildren,
                    const SizedBox(height: 12),
                    _buildFooter(state),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DevicePickerHeader(
              activeDevice: state.activeDevice,
              activeSelfPeripheral: state.activeSelfPeripheral,
              selfDevice: state.selfDevice,
              devices: state.devices,
              transferState: state.transferState,
              isSyncedWithBackend: state.isSyncedWithBackend,
              onRefresh: _triggerRefresh,
            ),
            const Divider(color: PlayerColors.divider, height: 1),
            Flexible(
              child: ListView(
                controller: _effectiveScrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: scrollChildren,
              ),
            ),
            const Divider(color: PlayerColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: _buildFooter(state),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildScrollContent(ConnectState state) {
    final List<Widget> children = <Widget>[];

    final Widget? errorBanner = _buildErrorOrTransferBanner(state);
    if (errorBanner != null) {
      children.add(errorBanner);
      children.add(const SizedBox(height: 12));
    }

    final ConnectDevice? activeDevice = state.activeDevice;
    if (activeDevice != null) {
      children.add(_buildPinnedActiveSection(state, activeDevice));
    } else {
      children.add(
        ActiveDeviceBanner(
          key: const ValueKey<String>('fallback_active_device_banner'),
          activeDevice: null,
          activeSelfPeripheral: state.activeSelfPeripheral,
          selfDevice: state.selfDevice,
          devices: state.devices,
          transferState: state.transferState,
          showWhenLocalBuiltIn: true,
        ),
      );
    }

    final List<ConnectDevice> remainingDevices = _filterRemainingDevices(
      state.sortedDevices,
      activeDevice,
    );

    if (remainingDevices.isEmpty) {
      if (activeDevice == null && state.sortedDevices.isEmpty) {
        children.add(const SizedBox(height: 16));
        children.add(_buildEmptyDevicesPlaceholder());
      }
      return children;
    }

    final List<ConnectDevice> localDevices = <ConnectDevice>[];
    final List<ConnectDevice> remoteOtherNetworkDevices = <ConnectDevice>[];
    for (final device in remainingDevices) {
      if (device.isSelf || device.isLocal) {
        localDevices.add(device);
      } else {
        remoteOtherNetworkDevices.add(device);
      }
    }

    children.add(const SizedBox(height: 16));
    children.add(
      const Text(
        'Select a device',
        style: TextStyle(
          color: PlayerColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    children.add(const SizedBox(height: 8));

    final Map<String, int> seenRowKeys = <String, int>{};

    for (final device in localDevices) {
      children.add(_buildDeviceRow(state, device, seenRowKeys));
      children.add(const SizedBox(height: 8));
    }

    if (remoteOtherNetworkDevices.isNotEmpty) {
      if (localDevices.isNotEmpty) {
        children.add(const SizedBox(height: 4));
      }
      children.add(
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'On other networks',
            key: ValueKey<String>('on_other_networks_header'),
            style: TextStyle(
              color: PlayerColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
      for (final device in remoteOtherNetworkDevices) {
        children.add(_buildDeviceRow(state, device, seenRowKeys));
        children.add(const SizedBox(height: 8));
      }
    }

    return children;
  }

  Widget _buildPinnedActiveSection(
    ConnectState state,
    ConnectDevice activeDevice,
  ) {
    final String activeTargetId = resolveDeviceTargetIdentifier(activeDevice);
    final List<ConnectGroupDevice> groupMembers = switch (activeDevice.groupData) {
      final data? => data.devices,
      null => const <ConnectGroupDevice>[],
    };

    final bool showVolumeSlider = !activeDevice.isSelf &&
        (!activeDevice.isLocal || state.volumeState.isRemoteVolumeControllable);
    final Map<String, int> seenGroupKeys = <String, int>{};

    return Container(
      key: const ValueKey<String>('pinned_active_device_card'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PlayerColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kSpotifyConnectGreen.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Current device',
              style: TextStyle(
                color: kSpotifyConnectGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DeviceListTile(
            key: ValueKey<String>('active_${resolveDeviceRowKeyValue(activeDevice)}'),
            device: activeDevice,
            activeSelfPeripheral: state.activeSelfPeripheral,
            transferState: state.transferState,
            installSpotifyState: state.installSpotifyState,
            isInstallingThisDevice:
                activeTargetId.isNotEmpty &&
                state.installSpotifyDeviceId == activeTargetId,
            onTap: () => _handleDeviceTap(activeDevice),
            onLogout: activeDevice.supportsLogout && !activeDevice.isSelf
                ? () => _handleLogout(activeDevice)
                : null,
          ),
          if (showVolumeSlider) ...[
            const SizedBox(height: 8),
            ConnectVolumeSlider(
              controller: widget.controller,
              deviceName: activeDevice.name,
            ),
          ],
          if (activeDevice.isGroup && groupMembers.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'Grouped speakers',
                style: TextStyle(
                  color: PlayerColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final member in groupMembers) ...[
              _buildGroupMemberTile(
                state,
                activeTargetId,
                member,
                rowKey: _allocateUniqueKey(
                  seenGroupKeys,
                  'group_${member.identifiers.groupDeviceIdentifier}',
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGroupMemberTile(
    ConnectState state,
    String parentGroupId,
    ConnectGroupDevice member, {
    required String rowKey,
  }) {
    final memberId = member.identifiers.groupDeviceIdentifier;
    final groupVol = state.volumeState.groupDeviceVolumes[memberId];
    final bool isPending =
        state.volumeState.pendingGroupDeviceIds.contains(memberId);

    return GroupDeviceTile(
      key: ValueKey<String>(rowKey),
      groupDevice: member,
      groupVolume: groupVol,
      isPending: isPending,
      onVolumeChanged: member.groupingStatus == GroupingStatus.grouped
          ? (value) {
              if (!widget.controller.isClosed) {
                widget.controller.dispatch(
                  SetGroupVolumeRequested(
                    groupDeviceIdentifier: memberId,
                    volume: value,
                  ),
                );
              }
            }
          : null,
      onStepVolume: member.groupingStatus == GroupingStatus.grouped
          ? (direction) {
              if (!widget.controller.isClosed) {
                widget.controller.dispatch(
                  StepGroupVolumeRequested(
                    groupDeviceIdentifier: memberId,
                    direction: direction,
                  ),
                );
              }
            }
          : null,
      onRemoveFromGroup:
          member.capabilities.removable && parentGroupId.isNotEmpty
              ? () {
                  if (!widget.controller.isClosed) {
                    widget.controller.dispatch(
                      RemoveDeviceFromGroupRequested(
                        deviceIdentifier: memberId,
                        groupDeviceIdentifier: parentGroupId,
                      ),
                    );
                  }
                }
              : null,
      onAddToGroup: member.groupingStatus == GroupingStatus.groupable &&
              parentGroupId.isNotEmpty
          ? () {
              if (!widget.controller.isClosed) {
                widget.controller.dispatch(
                  AddDeviceToGroupRequested(
                    deviceIdentifier: memberId,
                    groupDeviceIdentifier: parentGroupId,
                  ),
                );
              }
            }
          : null,
    );
  }

  Widget _buildDeviceRow(
    ConnectState state,
    ConnectDevice device,
    Map<String, int> seenRowKeys,
  ) {
    final targetId = resolveDeviceTargetIdentifier(device);
    final bool isRecommended = device.localIdentifier.isNotEmpty &&
        state.isRecommendedLocalDevice(device.localIdentifier);
    final rowKey = _allocateUniqueKey(
      seenRowKeys,
      resolveDeviceRowKeyValue(device),
    );

    return DeviceListTile(
      key: ValueKey<String>(rowKey),
      device: device,
      activeSelfPeripheral: state.activeSelfPeripheral,
      transferState: state.transferState,
      installSpotifyState: state.installSpotifyState,
      isInstallingThisDevice: targetId.isNotEmpty &&
          state.installSpotifyDeviceId == targetId,
      isRecommended: isRecommended,
      onTap: () => _handleDeviceTap(device),
      onLogout: device.supportsLogout && !device.isSelf
          ? () => _handleLogout(device)
          : null,
      onInstall: (device.state == ConnectDeviceState.notInstalled ||
              device.state == ConnectDeviceState.installationAvailable)
          ? () => _handleInstall(device)
          : null,
    );
  }

  String _allocateUniqueKey(Map<String, int> seenCounts, String baseKey) {
    var count = switch (seenCounts[baseKey]) {
      final existing? => existing + 1,
      null => 1,
    };
    var candidate = count == 1 ? baseKey : '$baseKey#$count';
    while (count > 1 && seenCounts.containsKey(candidate)) {
      count += 1;
      candidate = '$baseKey#$count';
    }
    seenCounts[baseKey] = count;
    seenCounts[candidate] = 1;
    return candidate;
  }

  List<ConnectDevice> _filterRemainingDevices(
    List<ConnectDevice> sortedDevices,
    ConnectDevice? activeDevice,
  ) {
    if (activeDevice == null) {
      return sortedDevices;
    }
    return sortedDevices
        .where(
          (device) =>
              !device.isActive && !_isSameDeviceIdentity(device, activeDevice),
        )
        .toList(growable: false);
  }

  bool _isSameDeviceIdentity(
    ConnectDevice candidate,
    ConnectDevice activeDevice,
  ) {
    if (identical(candidate, activeDevice)) {
      return true;
    }
    final activeConnectId = activeDevice.connectStateIdentifier.trim();
    final candidateConnectId = candidate.connectStateIdentifier.trim();
    if (activeConnectId.isNotEmpty || candidateConnectId.isNotEmpty) {
      return activeConnectId.isNotEmpty &&
          candidateConnectId == activeConnectId;
    }
    final activeLocalId = activeDevice.localIdentifier.trim();
    final candidateLocalId = candidate.localIdentifier.trim();
    return activeLocalId.isNotEmpty && candidateLocalId == activeLocalId;
  }

  Widget? _buildErrorOrTransferBanner(ConnectState state) {
    if (state.lastError case final failure?) {
      return Container(
        key: const ValueKey<String>('connect_error_banner'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFCA5A5),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                failure.message,
                style: const TextStyle(
                  color: PlayerColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey<String>('dismiss_connect_error_button'),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: PlayerColors.textSecondary,
              ),
              tooltip: 'Dismiss error',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                if (!widget.controller.isClosed) {
                  widget.controller.dispatch(
                    const DismissConnectErrorRequested(),
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    switch (state.transferState) {
      case TransferFailed(
          reason: final reason,
          errorDescription: final errorDescription,
        ):
        final message = switch (errorDescription) {
          final desc? => desc.trim().isNotEmpty
              ? desc
              : _resolveTransferFailureReasonLabel(reason),
          null => _resolveTransferFailureReasonLabel(reason),
        };
        return Container(
          key: const ValueKey<String>('connect_transfer_failed_banner'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFCA5A5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: PlayerColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      case TransferIdle():
      case TransferInProgress():
      case TransferSucceeded():
        return null;
    }
  }

  String _resolveTransferFailureReasonLabel(TransferFailureReason reason) {
    switch (reason) {
      case TransferFailureReason.notFound:
        return 'Selected device could not be found';
      case TransferFailureReason.invalidArguments:
        return 'Invalid device transfer request';
      case TransferFailureReason.backendFailure:
        return 'Spotify Connect service unavailable';
      case TransferFailureReason.aborted:
        return 'Transfer cancelled';
      case TransferFailureReason.noResponse:
        return 'Device did not respond';
      case TransferFailureReason.loginFailed:
        return 'Could not sign in on target device';
      case TransferFailureReason.transportError:
        return 'Connection error while transferring playback';
      case TransferFailureReason.unknown:
        return 'Unable to transfer playback';
    }
  }

  Widget _buildEmptyDevicesPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PlayerColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.devices_rounded,
            size: 28,
            color: PlayerColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const Text(
            'No other devices found',
            style: TextStyle(
              color: PlayerColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Make sure your speakers or TV are powered on and connected to Wi-Fi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PlayerColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ConnectState state) {
    final ConnectDevice? activeDevice = state.activeDevice;
    final bool canDeleteGroup = activeDevice != null &&
        activeDevice.isGroup &&
        resolveDeviceTargetIdentifier(activeDevice).isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey<String>('discover_devices_button'),
            onPressed: _triggerRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: PlayerColors.textPrimary,
              side: const BorderSide(color: PlayerColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.wifi_find_rounded, size: 18),
            label: const Text(
              'Scan for devices',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (canDeleteGroup) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            key: const ValueKey<String>('delete_group_button'),
            onPressed: () {
              if (!widget.controller.isClosed) {
                widget.controller.dispatch(
                  DeleteGroupRequested(
                    deviceIdentifier: resolveDeviceTargetIdentifier(
                      activeDevice,
                    ),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFCA5A5),
              side: BorderSide(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text(
              'End group',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}
