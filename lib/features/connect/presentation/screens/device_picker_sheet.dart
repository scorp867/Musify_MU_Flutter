// 1:1 replica of Spotify 9.1.92.3058 Connect Device Picker Sheet
// (`p199p/lxs.java`, `p199p/r3h0.java`, `p199p/n5o0.java`, `p199p/ohb1.java`,
// `p199p/frl1.java`, `p199p/btl1.java`, `p199p/ka0.java`, `p199p/ltl1.java`,
// `p199p/ekp0.java`, `p199p/ksi.java`, `p199p/f4a.java`).

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
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_context_menu_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_active_card.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_footer.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_row.dart';
import 'package:musify_mu/features/connect/presentation/widgets/grouped_devices_section.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/domain/models/playback_quality.dart';

/// Spotify Connect Device Picker modal bottom sheet matching Spotify 9.1.92.3058:
/// - Viewport height: `70%` initial height (or fully expanded `< 600dp` viewport)
/// - Surface: `#1F1F1F` (`sheetBackground`) with `16dp` top corners & drag handle
/// - Header (`ohb1`): left-aligned `"Connect"` (`20sp Bold #FFFFFF`)
/// - Elevated Active Device Card (`#2A2A2A`, `16dp` corners, `8dp` H margin)
///   with `24sp Bold` title, streaming quality pill badge, `elbow-connector`
///   peripheral row, `16dp` 3-bar equalizer + `#1ED760` marquee `"Title – Artist"`,
///   right `48dp` `#1ED760` Encore device icon, embedded Canvas volume slider,
///   and expandable grouped speakers section
/// - Thin `1dp` `#1AFFFFFF` divider
/// - Scrollable on-network devices list, `"No devices found on this network"`
///   empty state (`ka0.m56885e`), and `"On other networks"` section (`ltl1.m61220f`)
/// - Pinned bottom footer (`ekp0`/`ksi`/`f4a`) with `"Find Bluetooth devices"` /
///   `"Bluetooth"` action card (and optional Jam slot when supported)
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
    this.queueController,
    this.playbackQuality,
    this.onStartJam,
  });

  final ConnectMobiusController controller;
  final bool autoRefreshOnOpen;
  final ScrollController? scrollController;
  final ConnectSessionCoordinator? sessionCoordinator;
  final DeviceEnvironmentPort? deviceEnvironmentPort;
  final AudioRoutePort? audioRoutePort;
  final ConnectOutputStatusPolicy? outputStatusPolicy;
  final PlayerQueueMobiusController? queueController;
  final PlaybackQuality? playbackQuality;
  final VoidCallback? onStartJam;

  /// Presents [DevicePickerSheet] inside a Spotify-styled modal bottom sheet
  /// matching `lxs.java` (`70%` viewport height, expanding fully on `< 600dp`
  /// compact viewports).
  static Future<void> show(
    BuildContext context, {
    required ConnectMobiusController controller,
    bool autoRefreshOnOpen = true,
    ConnectSessionCoordinator? sessionCoordinator,
    DeviceEnvironmentPort? deviceEnvironmentPort,
    AudioRoutePort? audioRoutePort,
    ConnectOutputStatusPolicy? outputStatusPolicy,
    PlayerQueueMobiusController? queueController,
    PlaybackQuality? playbackQuality,
    VoidCallback? onStartJam,
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
    final resolvedQueueController = switch (queueController) {
      final explicit? => explicit,
      null => context.read<PlayerQueueMobiusController?>(),
    };

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ConnectEncoreTheme.scrimBarrier,
      builder: (sheetContext) {
        final double viewportHeight = MediaQuery.sizeOf(sheetContext).height;
        final bool isCompactViewport =
            viewportHeight < ConnectEncoreTheme.devicePickerCompactViewportThreshold;
        final double targetHeight = isCompactViewport
            ? viewportHeight * 0.92
            : viewportHeight * ConnectEncoreTheme.devicePickerInitialHeightFraction;

        return SizedBox(
          height: targetHeight,
          child: Material(
            color: ConnectEncoreTheme.sheetBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(
                ConnectEncoreTheme.devicePickerSheetCornerRadius,
              ),
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
                queueController: resolvedQueueController,
                playbackQuality: playbackQuality,
                onStartJam: onStartJam,
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
  bool _isGroupExpanded = true;

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

  PlayerQueueMobiusController? _resolveQueueController() {
    if (widget.queueController case final explicit?) {
      return explicit;
    }
    return context.read<PlayerQueueMobiusController?>();
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

  Future<void> _openDeviceContextMenu(ConnectDevice device) async {
    final DeviceContextAction? action = await DeviceContextMenuSheet.show(
      context,
      device: device,
    );
    if (!mounted || action == null || widget.controller.isClosed) {
      return;
    }
    switch (action) {
      case RenameDeviceAction():
        await _handleRename(device);
      case LogoutDeviceAction():
        _handleLogout(device);
      case SelectPreferredIncarnationAction(:final loginType):
        _handleSelectPreferredIncarnation(device, loginType);
      case InstallSpotifyAction():
        _handleInstall(device);
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

  Future<void> _handleRename(ConnectDevice device) async {
    if (widget.controller.isClosed) {
      return;
    }
    final targetId = resolveDeviceTargetIdentifier(device);
    if (targetId.isEmpty) {
      return;
    }
    final String? submittedName = await RenameConnectDeviceDialog.show(
      context,
      initialName: device.name,
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
    final ConnectOutputStatusPolicy policy = _resolveOutputStatusPolicy();
    final PlayerQueueMobiusController? queueController = _resolveQueueController();
    final AudioRoutePort? audioRoutePort = _resolveAudioRoutePort();

    return ValueListenableBuilder<ConnectState>(
      valueListenable: widget.controller,
      builder: (context, connectState, _) {
        if (queueController case final queue?) {
          return ValueListenableBuilder<QueueModel>(
            valueListenable: queue,
            builder: (context, queueState, _) {
              final PlaybackQuality? effectiveQuality = switch (widget.playbackQuality) {
                final explicit? => explicit,
                null => queueState.playerState?.playbackQuality,
              };
              return _buildSheetBody(
                context: context,
                connectState: connectState,
                policy: policy,
                audioRoutePort: audioRoutePort,
                playbackQuality: effectiveQuality,
                nowPlayingTitle: queueState.title,
                nowPlayingArtist: queueState.artist,
                isPlaying: queueState.isPlaying,
              );
            },
          );
        }
        return _buildSheetBody(
          context: context,
          connectState: connectState,
          policy: policy,
          audioRoutePort: audioRoutePort,
          playbackQuality: widget.playbackQuality,
          nowPlayingTitle: null,
          nowPlayingArtist: null,
          isPlaying: false,
        );
      },
    );
  }

  Widget _buildSheetBody({
    required BuildContext context,
    required ConnectState connectState,
    required ConnectOutputStatusPolicy policy,
    required AudioRoutePort? audioRoutePort,
    required PlaybackQuality? playbackQuality,
    required String? nowPlayingTitle,
    required String? nowPlayingArtist,
    required bool isPlaying,
  }) {
    final bool isBluetoothActive =
        connectState.activeSelfPeripheral?.connectionType ==
            OutputPeripheralConnectionType.bluetooth ||
        connectState.activeDevice?.outputPeripheral?.connectionType ==
            OutputPeripheralConnectionType.bluetooth;

    final ConnectDevice? activeDevice = connectState.activeDevice;
    final List<ConnectGroupDevice> groupMembers = switch (activeDevice?.groupData) {
      final data? => data.devices,
      null => const <ConnectGroupDevice>[],
    };
    final bool hasGroupMembers =
        activeDevice != null && activeDevice.isGroup && groupMembers.isNotEmpty;
    final String activeTargetId = switch (activeDevice) {
      final d? => resolveDeviceTargetIdentifier(d),
      null => '',
    };

    final List<ConnectDevice> remainingDevices = _filterRemainingDevices(
      connectState.sortedDevices,
      activeDevice,
    );
    final List<ConnectDevice> onNetworkDevices = <ConnectDevice>[];
    final List<ConnectDevice> otherNetworkDevices = <ConnectDevice>[];
    for (final device in remainingDevices) {
      if (device.isSelf || device.isLocal) {
        onNetworkDevices.add(device);
      } else {
        otherNetworkDevices.add(device);
      }
    }

    final Map<String, int> seenRowKeys = <String, int>{};

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Centered drag handle pill (`36x4dp`, `#535353`)
        Center(
          child: Container(
            key: const ValueKey<String>('device_picker_drag_handle'),
            margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
            width: 36.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: ConnectEncoreTheme.dragHandle,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
        ),

        // Left-aligned Spotify `ohb1` sheet header ("Connect", 20sp Bold)
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
          child: Text(
            'Connect',
            key: ValueKey<String>('device_picker_title'),
            style: ConnectEncoreTheme.header20Bold,
          ),
        ),

        // Scrollable sheet body (`device-picker-scrollable-content`)
        Expanded(
          child: ListView(
            key: const ValueKey<String>('device_picker_scrollable_content'),
            controller: _effectiveScrollController,
            padding: const EdgeInsets.only(bottom: 12.0),
            children: [
              // Dismissible error / transfer failure banner when present
              if (_buildErrorOrTransferBanner(connectState) case final banner?) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
                  child: banner,
                ),
              ],

              // Active Device Card (`frl1` + `C2255rx` + `c4s0` + `rdl1` + `coj1`)
              DevicePickerActiveCard(
                connectState: connectState,
                controller: widget.controller,
                outputStatusPolicy: policy,
                playbackQuality: playbackQuality,
                nowPlayingTitle: nowPlayingTitle,
                nowPlayingArtist: nowPlayingArtist,
                isPlaying: isPlaying,
                hasGroupedDevicesBelow: hasGroupMembers,
                isGroupExpanded: _isGroupExpanded,
                onToggleGroupExpanded: hasGroupMembers
                    ? () => setState(() {
                          _isGroupExpanded = !_isGroupExpanded;
                        })
                    : null,
                onTapCard: activeDevice != null && !activeDevice.isSelf
                    ? () => _handleDeviceTap(activeDevice)
                    : null,
                onOpenContextMenu: activeDevice != null &&
                        hasDeviceContextMenuActions(activeDevice)
                    ? () => unawaited(_openDeviceContextMenu(activeDevice))
                    : null,
              ),

              // Expandable Grouped Speakers panel (`qk20` + `zew0`)
              if (hasGroupMembers && _isGroupExpanded)
                GroupedDevicesSection(
                  members: groupMembers,
                  groupDeviceVolumes: connectState.volumeState.groupDeviceVolumes,
                  pendingGroupDeviceIds:
                      connectState.volumeState.pendingGroupDeviceIds,
                  onVolumeChanged: (memberId, volume) {
                    if (!widget.controller.isClosed) {
                      widget.controller.dispatch(
                        SetGroupVolumeRequested(
                          groupDeviceIdentifier: memberId,
                          volume: volume,
                        ),
                      );
                    }
                  },
                  onStepVolume: (memberId, direction) {
                    if (!widget.controller.isClosed) {
                      widget.controller.dispatch(
                        StepGroupVolumeRequested(
                          groupDeviceIdentifier: memberId,
                          direction: direction,
                        ),
                      );
                    }
                  },
                  onAddToGroup: (memberId) {
                    if (!widget.controller.isClosed &&
                        activeTargetId.isNotEmpty) {
                      widget.controller.dispatch(
                        AddDeviceToGroupRequested(
                          deviceIdentifier: memberId,
                          groupDeviceIdentifier: activeTargetId,
                        ),
                      );
                    }
                  },
                  onRemoveFromGroup: (memberId) {
                    if (!widget.controller.isClosed &&
                        activeTargetId.isNotEmpty) {
                      widget.controller.dispatch(
                        RemoveDeviceFromGroupRequested(
                          deviceIdentifier: memberId,
                          groupDeviceIdentifier: activeTargetId,
                        ),
                      );
                    }
                  },
                ),

              // Permissions prompt card when Bluetooth / Nearby Wi-Fi missing
              if (_permissionStatus case final permStatus?
                  when permStatus.anyMissing) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                  child: _PermissionPromptCard(
                    status: permStatus,
                    onRequestPermissions: _handleRequestPermissions,
                    onOpenSettings: _handleOpenPermissionSettings,
                  ),
                ),
              ],

              // Thin 1dp divider beneath Active Card (`backgroundTintedBase`)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(
                  height: 1.0,
                  thickness: 1.0,
                  color: ConnectEncoreTheme.tintedBase,
                ),
              ),

              // On-network Connect devices OR exact Spotify empty state (`ka0.m56885e`)
              if (onNetworkDevices.isEmpty)
                const Padding(
                  key: ValueKey<String>('no_devices_error'),
                  padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                  child: Text(
                    'No devices found on this network',
                    style: ConnectEncoreTheme.bodySmall13Regular,
                  ),
                )
              else
                for (final device in onNetworkDevices)
                  _buildDeviceRow(
                    context: context,
                    state: connectState,
                    device: device,
                    seenRowKeys: seenRowKeys,
                    policy: policy,
                  ),

              // Off-network devices section (`ltl1.m61220f` "On other networks")
              if (otherNetworkDevices.isNotEmpty) ...[
                const Padding(
                  key: ValueKey<String>('on_other_networks_header'),
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'On other networks',
                    style: TextStyle(
                      color: ConnectEncoreTheme.textSubdued,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                for (final device in otherNetworkDevices)
                  _buildDeviceRow(
                    context: context,
                    state: connectState,
                    device: device,
                    seenRowKeys: seenRowKeys,
                    policy: policy,
                  ),
              ],
            ],
          ),
        ),

        // Pinned bottom action footer (`ekp0` + `ksi` + `f4a`)
        DevicePickerFooter(
          isBluetoothActive: isBluetoothActive,
          onBluetoothTap: audioRoutePort != null
              ? () => unawaited(_handleOpenSystemOutputSwitcher())
              : null,
          onStartJam: widget.onStartJam,
        ),
      ],
    );
  }

  Widget _buildDeviceRow({
    required BuildContext context,
    required ConnectState state,
    required ConnectDevice device,
    required Map<String, int> seenRowKeys,
    required ConnectOutputStatusPolicy policy,
  }) {
    final String targetId = resolveDeviceTargetIdentifier(device);
    final bool isRecommended = device.localIdentifier.isNotEmpty &&
        state.isRecommendedLocalDevice(device.localIdentifier);
    final String rowKey = _allocateUniqueKey(
      seenRowKeys,
      resolveDeviceRowKeyValue(device),
    );

    return DevicePickerRow(
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
      onOpenContextMenu: hasDeviceContextMenuActions(device)
          ? () => unawaited(_openDeviceContextMenu(device))
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
      return _ConnectBannerCard(
        key: const ValueKey<String>('connect_error_banner'),
        message: failure.message,
        onDismiss: () {
          if (!widget.controller.isClosed) {
            widget.controller.dispatch(const DismissConnectErrorRequested());
          }
        },
      );
    }

    switch (state.transferState) {
      case TransferFailed(
          reason: final reason,
          errorDescription: final errorDescription,
        ):
        final String message = switch (errorDescription) {
          final desc? when desc.trim().isNotEmpty => desc.trim(),
          _ => 'Transfer failed (${reason.name})',
        };
        return _ConnectBannerCard(
          key: const ValueKey<String>('transfer_failed_banner'),
          message: message,
          onDismiss: null,
        );
      case TransferIdle():
      case TransferInProgress():
      case TransferSucceeded():
        return null;
    }
  }
}

class _ConnectBannerCard extends StatelessWidget {
  const _ConnectBannerCard({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: ConnectEncoreTheme.negativeSurface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ConnectEncoreTheme.negativeBorder),
      ),
      child: Row(
        children: [
          const ConnectEncoreIcon(
            icon: ConnectEncoreIcons.exclamationCircle16,
            size: 16.0,
            color: ConnectEncoreTheme.negativeAccent,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: ConnectEncoreTheme.bodySmall13Regular.copyWith(
                color: ConnectEncoreTheme.textBase,
              ),
            ),
          ),
          if (onDismiss case final dismiss?)
            GestureDetector(
              key: const ValueKey<String>('dismiss_connect_error_button'),
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Text(
                  'Dismiss',
                  style: TextStyle(
                    color: ConnectEncoreTheme.negativeAccent,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionPromptCard extends StatelessWidget {
  const _PermissionPromptCard({
    required this.status,
    required this.onRequestPermissions,
    required this.onOpenSettings,
  });

  final ConnectPermissionStatus status;
  final VoidCallback onRequestPermissions;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final String description;
    if (!status.bluetoothConnect && !status.nearbyWifi) {
      description =
          'Allow Bluetooth and local network access to discover speakers and headphones.';
    } else if (!status.bluetoothConnect) {
      description =
          'Allow Bluetooth access to show connected headphones and speakers.';
    } else {
      description =
          'Allow local network access to discover devices on your Wi-Fi.';
    }

    return Container(
      key: const ValueKey<String>('connect_permissions_card'),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: ConnectEncoreTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ConnectEncoreIcon(
                icon: ConnectEncoreIcons.bluetooth24,
                size: 18.0,
                color: ConnectEncoreTheme.brightAccent,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Allow Bluetooth and local network access',
                  style: ConnectEncoreTheme.bodySmall13Bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            description,
            style: ConnectEncoreTheme.caption11Regular,
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              FilledButton(
                key: const ValueKey<String>('grant_connect_permissions_button'),
                onPressed: onRequestPermissions,
                style: FilledButton.styleFrom(
                  backgroundColor: ConnectEncoreTheme.brightAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                ),
                child: const Text(
                  'Allow access',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              OutlinedButton(
                key: const ValueKey<String>(
                  'open_connect_permission_settings_button',
                ),
                onPressed: onOpenSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ConnectEncoreTheme.textBase,
                  side: const BorderSide(color: ConnectEncoreTheme.tintedBase),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                ),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 12.0,
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
}
