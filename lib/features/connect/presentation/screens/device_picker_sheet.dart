// 1:1 replica of com.spotify.connect.devicepicker (p199p/lxs.java, p199p/asq.java, p199p/n5o0.java, p199p/r3h0.java, p199p/gkp0.java, p199p/l8d0.java, p199p/fkm0.java, p199p/cup.java, p199p/c8r.java)

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/connect/application/lifecycle/connect_session_coordinator.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/widgets/active_device_banner.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_header.dart';
import 'package:musify_mu/features/connect/presentation/widgets/group_device_tile.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';

/// Spotify Connect Output Switcher modal bottom sheet matching `p199p/lxs.java`,
/// `p199p/asq.java`, `p199p/n5o0.java`, `p199p/r3h0.java`, `p199p/gkp0.java`,
/// `p199p/fkm0.java:108-115`, `p199p/cup.java:194-252`, and `p199p/c8r.java:55-200`.
class DevicePickerSheet extends StatefulWidget {
  const DevicePickerSheet({
    super.key,
    required this.controller,
    this.autoRefreshOnOpen = true,
    this.scrollController,
    this.sessionCoordinator,
    this.deviceEnvironmentPort,
    this.audioRoutePort,
    this.outputStatusPolicy,
  });

  final ConnectMobiusController controller;
  final bool autoRefreshOnOpen;
  final ScrollController? scrollController;
  final ConnectSessionCoordinator? sessionCoordinator;
  final DeviceEnvironmentPort? deviceEnvironmentPort;
  final AudioRoutePort? audioRoutePort;
  final ConnectOutputStatusPolicy? outputStatusPolicy;

  /// Presents [DevicePickerSheet] inside a modal bottom sheet bounded to 85%
  /// of the viewport height.
  static Future<void> show(
    BuildContext context, {
    required ConnectMobiusController controller,
    bool autoRefreshOnOpen = true,
    ConnectSessionCoordinator? sessionCoordinator,
    DeviceEnvironmentPort? deviceEnvironmentPort,
    AudioRoutePort? audioRoutePort,
    ConnectOutputStatusPolicy? outputStatusPolicy,
  }) {
    final resolvedCoordinator = switch (sessionCoordinator) {
      final explicit? => explicit,
      null => context.read<ConnectSessionCoordinator?>(),
    };
    final resolvedEnvironmentPort = switch (deviceEnvironmentPort) {
      final explicit? => explicit,
      null => context.read<DeviceEnvironmentPort?>(),
    };
    final resolvedAudioRoutePort = switch (audioRoutePort) {
      final explicit? => explicit,
      null => context.read<AudioRoutePort?>(),
    };
    final resolvedPolicy = switch (outputStatusPolicy) {
      final explicit? => explicit,
      null => context.read<ConnectOutputStatusPolicy?>(),
    };

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
                sessionCoordinator: resolvedCoordinator,
                deviceEnvironmentPort: resolvedEnvironmentPort,
                audioRoutePort: resolvedAudioRoutePort,
                outputStatusPolicy: resolvedPolicy,
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
  ConnectSessionCoordinator? _boundCoordinator;
  bool _notifiedCoordinatorOpen = false;
  ConnectPermissionStatus? _permissionStatus;
  int _permissionLoadEpoch = 0;

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

  ConnectSessionCoordinator? _resolveSessionCoordinator() {
    if (widget.sessionCoordinator case final explicit?) {
      return explicit;
    }
    return context.read<ConnectSessionCoordinator?>();
  }

  DeviceEnvironmentPort? _resolveDeviceEnvironmentPort() {
    if (widget.deviceEnvironmentPort case final explicit?) {
      return explicit;
    }
    return context.read<DeviceEnvironmentPort?>();
  }

  AudioRoutePort? _resolveAudioRoutePort() {
    if (widget.audioRoutePort case final explicit?) {
      return explicit;
    }
    return context.read<AudioRoutePort?>();
  }

  ConnectOutputStatusPolicy _resolveOutputStatusPolicy() {
    if (widget.outputStatusPolicy case final explicit?) {
      return explicit;
    }
    if (context.read<ConnectOutputStatusPolicy?>() case final provided?) {
      return provided;
    }
    return ConnectOutputStatusPolicy.instance;
  }

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }

    final coordinator = _resolveSessionCoordinator();
    if (coordinator != null) {
      final wasAlreadyOpen = coordinator.isDevicePickerOpen;
      _boundCoordinator = coordinator;
      coordinator.onDevicePickerOpened();
      _notifiedCoordinatorOpen = true;
      if (widget.autoRefreshOnOpen &&
          (wasAlreadyOpen || !widget.controller.isStarted)) {
        _triggerRefresh();
      }
    } else if (widget.autoRefreshOnOpen) {
      _triggerRefresh();
    }

    if (_resolveDeviceEnvironmentPort() case final envPort?) {
      _schedulePermissionStatusLoad(envPort);
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

    final nextCoordinator = _resolveSessionCoordinator();
    if (!identical(_boundCoordinator, nextCoordinator)) {
      if (_notifiedCoordinatorOpen) {
        _boundCoordinator?.onDevicePickerClosed();
        _notifiedCoordinatorOpen = false;
      }
      _boundCoordinator = nextCoordinator;
      if (nextCoordinator != null) {
        nextCoordinator.onDevicePickerOpened();
        _notifiedCoordinatorOpen = true;
      }
    }

    if (widget.deviceEnvironmentPort != oldWidget.deviceEnvironmentPort) {
      if (_resolveDeviceEnvironmentPort() case final envPort?) {
        _schedulePermissionStatusLoad(envPort);
      } else {
        _permissionLoadEpoch += 1;
        _permissionStatus = null;
      }
    }

    if (widget.controller != oldWidget.controller && widget.autoRefreshOnOpen) {
      _triggerRefresh();
    }
  }

  @override
  void dispose() {
    _permissionLoadEpoch += 1;
    if (_notifiedCoordinatorOpen) {
      _boundCoordinator?.onDevicePickerClosed();
      _notifiedCoordinatorOpen = false;
    }
    _boundCoordinator = null;
    if (_ownedScrollController case final owned?) {
      owned.dispose();
      _ownedScrollController = null;
    }
    super.dispose();
  }

  void _schedulePermissionStatusLoad(DeviceEnvironmentPort port) {
    _permissionLoadEpoch += 1;
    final epoch = _permissionLoadEpoch;
    unawaited(_loadPermissionStatus(port, epoch));
  }

  Future<void> _loadPermissionStatus(
    DeviceEnvironmentPort port,
    int epoch,
  ) async {
    try {
      final env = await port.getDeviceEnvironment();
      if (!mounted || epoch != _permissionLoadEpoch) {
        return;
      }
      final nextStatus = env.permissionStatus;
      if (_permissionStatus != nextStatus) {
        setState(() {
          _permissionStatus = nextStatus;
        });
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'DevicePickerSheet: getDeviceEnvironment failed: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleRequestPermissions() async {
    final port = _resolveDeviceEnvironmentPort();
    if (port == null) {
      return;
    }
    _permissionLoadEpoch += 1;
    final epoch = _permissionLoadEpoch;
    try {
      final updated = await port.requestConnectPermissions();
      if (!mounted || epoch != _permissionLoadEpoch) {
        return;
      }
      setState(() {
        _permissionStatus = updated;
      });
      if (updated.bluetoothConnect || updated.nearbyWifi) {
        _triggerRefresh();
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'DevicePickerSheet: requestConnectPermissions failed: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleOpenPermissionSettings() async {
    final port = _resolveDeviceEnvironmentPort();
    if (port == null) {
      return;
    }
    try {
      await port.openAppSettings();
    } on Object catch (error, stackTrace) {
      dev.log(
        'DevicePickerSheet: openAppSettings failed: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleOpenSystemOutputSwitcher() async {
    final routePort = _resolveAudioRoutePort();
    if (routePort == null) {
      return;
    }
    try {
      await routePort.openSystemOutputSwitcher();
    } on Object catch (error, stackTrace) {
      dev.log(
        'DevicePickerSheet: openSystemOutputSwitcher failed: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleLocalPeripheralTap(
    ConnectState state,
    LocalAudioPeripheral peripheral,
    ConnectOutputStatusPolicy policy,
  ) {
    if (policy.isRemoteOutputActive(state) && !widget.controller.isClosed) {
      widget.controller.dispatch(const PullPlaybackRequested());
    }
    if (!peripheral.isActive && _resolveAudioRoutePort() != null) {
      unawaited(_handleOpenSystemOutputSwitcher());
    }
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

  Future<void> _handleRename(BuildContext context, ConnectDevice device) async {
    if (widget.controller.isClosed) {
      return;
    }
    final targetId = resolveDeviceTargetIdentifier(device);
    if (targetId.isEmpty) {
      return;
    }
    final String? submittedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _RenameDeviceDialog(initialName: device.name);
      },
    );
    if (!mounted || widget.controller.isClosed) {
      return;
    }
    if (submittedName case final rawName?) {
      final trimmed = rawName.trim();
      if (trimmed.isNotEmpty && trimmed != device.name.trim()) {
        widget.controller.dispatch(
          RenameDeviceRequested(
            deviceIdentifier: targetId,
            newName: trimmed,
          ),
        );
      }
    }
  }

  void _handleSelectPreferredIncarnation(
    ConnectDevice device,
    IncarnationLoginType loginType,
  ) {
    if (widget.controller.isClosed) {
      return;
    }
    final targetId = resolveDeviceTargetIdentifier(device);
    if (targetId.isNotEmpty) {
      widget.controller.dispatch(
        SetPreferredIncarnationRequested(
          deviceId: targetId,
          preferredLoginType: loginType,
        ),
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
    final ConnectOutputStatusPolicy policy = _resolveOutputStatusPolicy();

    return ValueListenableBuilder<ConnectState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        final List<Widget> scrollChildren = _buildScrollContent(
          context,
          state,
          policy,
        );

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
                outputStatusPolicy: policy,
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
              outputStatusPolicy: policy,
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

  List<Widget> _buildScrollContent(
    BuildContext context,
    ConnectState state,
    ConnectOutputStatusPolicy policy,
  ) {
    final List<Widget> children = <Widget>[];

    final Widget? errorBanner = _buildErrorOrTransferBanner(state);
    if (errorBanner != null) {
      children.add(errorBanner);
      children.add(const SizedBox(height: 12));
    }

    final ConnectDevice? activeDevice = state.activeDevice;
    if (activeDevice != null) {
      children.add(_buildPinnedActiveSection(context, state, activeDevice, policy));
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
          outputStatusPolicy: policy,
        ),
      );
    }

    if (_permissionStatus case final permStatus? when permStatus.anyMissing) {
      children.add(const SizedBox(height: 12));
      children.add(_buildPermissionPromptCard(permStatus));
    }

    final List<LocalAudioPeripheral> localPeripherals =
        state.selfPeripherals.isNotEmpty
            ? state.selfPeripherals
            : state.internal.peripherals;
    final bool hasAudioRoutePort = _resolveAudioRoutePort() != null;
    if (localPeripherals.isNotEmpty || hasAudioRoutePort) {
      children.add(const SizedBox(height: 12));
      children.add(
        _buildLocalAudioOutputSection(
          state: state,
          peripherals: localPeripherals,
          hasAudioRoutePort: hasAudioRoutePort,
          policy: policy,
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
      children.add(_buildDeviceRow(context, state, device, seenRowKeys, policy));
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
        children.add(_buildDeviceRow(context, state, device, seenRowKeys, policy));
        children.add(const SizedBox(height: 8));
      }
    }

    return children;
  }

  Widget _buildPermissionPromptCard(ConnectPermissionStatus status) {
    final String description;
    if (!status.bluetoothConnect && !status.nearbyWifi) {
      description =
          'Grant Bluetooth and nearby Wi-Fi permissions to discover speakers and headphones.';
    } else if (!status.bluetoothConnect) {
      description =
          'Grant Bluetooth permission to show connected headphones and speakers.';
    } else {
      description =
          'Grant nearby Wi-Fi permission to discover devices on your network.';
    }

    return Container(
      key: const ValueKey<String>('connect_permissions_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kSpotifyConnectGreen.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bluetooth_searching_rounded,
                size: 18,
                color: kSpotifyConnectGreen,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Allow Bluetooth and local network access',
                  style: TextStyle(
                    color: PlayerColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: PlayerColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                key: const ValueKey<String>('grant_connect_permissions_button'),
                onPressed: _handleRequestPermissions,
                style: FilledButton.styleFrom(
                  backgroundColor: kSpotifyConnectGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Allow access',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const ValueKey<String>(
                  'open_connect_permission_settings_button',
                ),
                onPressed: _handleOpenPermissionSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PlayerColors.textPrimary,
                  side: const BorderSide(color: PlayerColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalAudioOutputSection({
    required ConnectState state,
    required List<LocalAudioPeripheral> peripherals,
    required bool hasAudioRoutePort,
    required ConnectOutputStatusPolicy policy,
  }) {
    final DeviceType? selfType = switch (state.selfDevice) {
      final d? => d.type,
      null => null,
    };
    final Map<String, int> seenPeripheralKeys = <String, int>{};

    return Container(
      key: const ValueKey<String>('local_audio_output_section'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PlayerColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Audio output',
                  style: TextStyle(
                    color: PlayerColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasAudioRoutePort)
                OutlinedButton.icon(
                  key: const ValueKey<String>(
                    'open_system_output_switcher_button',
                  ),
                  onPressed: _handleOpenSystemOutputSwitcher,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PlayerColors.textPrimary,
                    side: const BorderSide(color: PlayerColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 15),
                  label: const Text(
                    'Change output',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (peripherals.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (var i = 0; i < peripherals.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _LocalPeripheralTile(
                key: ValueKey<String>(
                  _allocateUniqueKey(
                    seenPeripheralKeys,
                    'peripheral_${peripherals[i].id}',
                  ),
                ),
                peripheral: peripherals[i],
                selfDeviceType: selfType,
                policy: policy,
                onTap: () => _handleLocalPeripheralTap(
                  state,
                  peripherals[i],
                  policy,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPinnedActiveSection(
    BuildContext context,
    ConnectState state,
    ConnectDevice activeDevice,
    ConnectOutputStatusPolicy policy,
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
            outputStatusPolicy: policy,
            onTap: () => _handleDeviceTap(activeDevice),
            onLogout: activeDevice.supportsLogout && !activeDevice.isSelf
                ? () => _handleLogout(activeDevice)
                : null,
            onRename: activeDevice.supportsRename && !activeDevice.isSelf
                ? () => _handleRename(context, activeDevice)
                : null,
            onSelectPreferredIncarnation:
                activeDevice.incarnations.length > 1 && !activeDevice.isSelf
                    ? (loginType) => _handleSelectPreferredIncarnation(
                          activeDevice,
                          loginType,
                        )
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
    BuildContext context,
    ConnectState state,
    ConnectDevice device,
    Map<String, int> seenRowKeys,
    ConnectOutputStatusPolicy policy,
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
      outputStatusPolicy: policy,
      onTap: () => _handleDeviceTap(device),
      onLogout: device.supportsLogout && !device.isSelf
          ? () => _handleLogout(device)
          : null,
      onRename: device.supportsRename && !device.isSelf
          ? () => _handleRename(context, device)
          : null,
      onSelectPreferredIncarnation:
          device.incarnations.length > 1 && !device.isSelf
              ? (loginType) => _handleSelectPreferredIncarnation(
                    device,
                    loginType,
                  )
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
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.devices_rounded,
            size: 28,
            color: PlayerColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'No other devices found',
            style: TextStyle(
              color: PlayerColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
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

class _LocalPeripheralTile extends StatelessWidget {
  const _LocalPeripheralTile({
    super.key,
    required this.peripheral,
    required this.selfDeviceType,
    required this.policy,
    required this.onTap,
  });

  final LocalAudioPeripheral peripheral;
  final DeviceType? selfDeviceType;
  final ConnectOutputStatusPolicy policy;
  final VoidCallback onTap;

  String _resolveTitle() {
    final trimmed = peripheral.name.trim();
    final isBuiltIn = peripheral.id == kBuiltInSpeakerPeripheralId ||
        peripheral.connectionType ==
            OutputPeripheralConnectionType.builtInSpeaker;
    if (isBuiltIn) {
      if (trimmed.isNotEmpty && trimmed != kBuiltInSpeakerPeripheralId) {
        return trimmed;
      }
      return policy.resolveBuiltInSpeakerLabel(selfDeviceType);
    }
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return policy.resolveBuiltInSpeakerLabel(selfDeviceType);
  }

  String _resolveConnectionSubtitle() {
    switch (peripheral.connectionType) {
      case OutputPeripheralConnectionType.bluetooth:
        return peripheral.isActive ? 'Bluetooth - active' : 'Bluetooth';
      case OutputPeripheralConnectionType.wired:
        return peripheral.isActive ? 'Wired audio - active' : 'Wired audio';
      case OutputPeripheralConnectionType.carProjected:
        return peripheral.isActive ? 'Car audio - active' : 'Car audio';
      case OutputPeripheralConnectionType.airplay:
        return peripheral.isActive ? 'AirPlay - active' : 'AirPlay';
      case OutputPeripheralConnectionType.builtInSpeaker:
        return peripheral.isActive ? 'Phone speaker - active' : 'Phone speaker';
      case OutputPeripheralConnectionType.unknown:
        return peripheral.isActive ? 'Local output - active' : 'Local output';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = peripheral.isActive;
    final String title = _resolveTitle();
    final String subtitle = _resolveConnectionSubtitle();
    final IconData icon = resolvePeripheralIcon(
      peripheral.connectionType,
      category: peripheral.category,
      fallbackDeviceType: selfDeviceType,
    );

    return Material(
      color: isActive
          ? kSpotifyConnectGreen.withValues(alpha: 0.12)
          : PlayerColors.background.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive
              ? kSpotifyConnectGreen.withValues(alpha: 0.45)
              : PlayerColors.divider,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? kSpotifyConnectGreen
                    : PlayerColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? kSpotifyConnectGreen
                            : PlayerColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlayerColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: kSpotifyConnectGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenameDeviceDialog extends StatefulWidget {
  const _RenameDeviceDialog({
    required this.initialName,
  });

  final String initialName;

  @override
  State<_RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<_RenameDeviceDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialName;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _textController.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PlayerColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: PlayerColors.divider),
      ),
      title: const Text(
        'Rename device',
        style: TextStyle(
          color: PlayerColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        key: const ValueKey<String>('rename_device_text_field'),
        controller: _textController,
        autofocus: true,
        style: const TextStyle(
          color: PlayerColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Enter device name',
          hintStyle: const TextStyle(
            color: PlayerColors.textSecondary,
            fontSize: 14,
          ),
          filled: true,
          fillColor: PlayerColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: PlayerColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kSpotifyConnectGreen),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          key: const ValueKey<String>('rename_device_cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: PlayerColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _textController,
          builder: (context, value, _) {
            final bool canSave = value.text.trim().isNotEmpty;
            return FilledButton(
              key: const ValueKey<String>('rename_device_save_button'),
              onPressed: canSave ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: kSpotifyConnectGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          },
        ),
      ],
    );
  }
}
