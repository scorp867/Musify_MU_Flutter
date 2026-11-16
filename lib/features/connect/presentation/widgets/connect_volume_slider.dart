// 1:1 replica of com.spotify.connect.volume (p199p/jel1.java, p199p/xsh1.java, p199p/srh1.java, p199p/qrh1.java, p199p/a0f1.java, p199p/lw51.java, p199p/rth1.java, p199p/C2436wt.java, p199p/xob.java, p199p/nsk1.java, p199p/d601.java)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';

/// Remote volume slider widget bound to [ConnectMobiusController] and
/// [RemoteVolumeController], replicating `p199p/jel1.java` and `p199p/nsk1.m66607y`.
///
/// Isolates 60fps drag updates inside a `StreamBuilder<ConnectVolumeState>` on
/// `remoteVolumeController.stream` and resets interactive drag state via a keyed
/// child widget whenever controllability, controller, or active device identity
/// changes.
class ConnectVolumeSlider extends StatefulWidget {
  const ConnectVolumeSlider({
    super.key,
    this.controller,
    this.volumeController,
    this.onVolumeChanged,
    this.onStepVolume,
    this.enabled,
    this.initialVolume,
    this.deviceName,
  });

  final ConnectMobiusController? controller;
  final RemoteVolumeController? volumeController;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<int>? onStepVolume;
  final bool? enabled;
  final double? initialVolume;
  final String? deviceName;

  @override
  State<ConnectVolumeSlider> createState() => _ConnectVolumeSliderState();
}

class _ConnectVolumeSliderState extends State<ConnectVolumeSlider> {
  RemoteVolumeController? _boundVolumeController;
  Stream<ConnectVolumeState>? _volumeStream;

  @override
  void initState() {
    super.initState();
    _bindVolumeController(_resolveVolumeController());
  }

  @override
  void didUpdateWidget(covariant ConnectVolumeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextController = _resolveVolumeController();
    if (!identical(_boundVolumeController, nextController)) {
      _bindVolumeController(nextController);
    }
  }

  void _bindVolumeController(RemoteVolumeController? controller) {
    _boundVolumeController = controller;
    if (controller != null) {
      _volumeStream = controller.stream;
    } else {
      _volumeStream = null;
    }
  }

  RemoteVolumeController? _resolveVolumeController() {
    if (widget.volumeController case final external?) {
      return external;
    }
    if (widget.controller case final mobius?) {
      return mobius.remoteVolumeController;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final volumeCtrl = _boundVolumeController;
    final volumeStream = _volumeStream;
    if (volumeCtrl != null && volumeStream != null) {
      return StreamBuilder<ConnectVolumeState>(
        key: ObjectKey(volumeCtrl),
        stream: volumeStream,
        initialData: volumeCtrl.state,
        builder: (context, snapshot) {
          final ConnectVolumeState volumeState = switch (snapshot.data) {
            final s? => s,
            null => volumeCtrl.state,
          };
          final bool isControllable = switch (widget.enabled) {
            final override? => override,
            null => volumeState.isRemoteVolumeControllable,
          };
          final double resolvedVolume = _resolveStateVolume(volumeState);
          final String resolvedDeviceName = switch (widget.deviceName) {
            final name? => name,
            null => switch (volumeState.activeDevice) {
                final device? => device.name,
                null => '',
              },
          };
          final String? activeDeviceIdentity =
              _resolveActiveDeviceIdentity(volumeState);

          return _InteractiveVolumeSliderCard(
            key: ValueKey<
                (
                  bool,
                  bool,
                  ConnectMobiusController?,
                  RemoteVolumeController?,
                  String?,
                )>(
              (
                isControllable,
                isControllable,
                widget.controller,
                volumeCtrl,
                activeDeviceIdentity,
              ),
            ),
            isControllable: isControllable,
            canDragSlider: isControllable,
            canStep: isControllable,
            volume: resolvedVolume,
            deviceName: resolvedDeviceName,
            onVolumeChanged: (boundedVolume) =>
                _dispatchVolumeSet(boundedVolume, volumeCtrl),
            onStepVolume: (direction) => _dispatchStep(direction, volumeCtrl),
          );
        },
      );
    }

    final bool isControllable = switch (widget.enabled) {
      final override? => override,
      null => widget.onVolumeChanged != null || widget.onStepVolume != null,
    };
    final bool canDragSlider = switch (widget.enabled) {
      final override? => override,
      null => widget.onVolumeChanged != null,
    };
    final bool canStep = switch (widget.enabled) {
      final override? => override,
      null => widget.onStepVolume != null,
    };
    final double resolvedVolume = switch (widget.initialVolume) {
      final v? => boundNormalizedVolume(v),
      null => 0.5,
    };
    final String resolvedDeviceName = switch (widget.deviceName) {
      final name? => name,
      null => '',
    };

    return _InteractiveVolumeSliderCard(
      key: ValueKey<
          (
            bool,
            bool,
            ConnectMobiusController?,
            RemoteVolumeController?,
            String?,
          )>(
        (
          isControllable,
          canDragSlider,
          widget.controller,
          null,
          null,
        ),
      ),
      isControllable: isControllable,
      canDragSlider: canDragSlider,
      canStep: canStep,
      volume: resolvedVolume,
      deviceName: resolvedDeviceName,
      onVolumeChanged: (boundedVolume) =>
          _dispatchVolumeSet(boundedVolume, null),
      onStepVolume: (direction) => _dispatchStep(direction, null),
    );
  }

  String? _resolveActiveDeviceIdentity(ConnectVolumeState volumeState) {
    final device = volumeState.activeDevice;
    if (device == null) {
      return null;
    }
    final trimmedStateId = switch (volumeState.activeDeviceConnectStateIdentifier) {
      final stateId? => stateId.trim(),
      null => '',
    };
    final deviceConnectId = device.connectStateIdentifier.trim();
    if (trimmedStateId.isNotEmpty &&
        deviceConnectId.isNotEmpty &&
        trimmedStateId != deviceConnectId) {
      return 'id:$trimmedStateId';
    }
    final targetId = resolveDeviceTargetIdentifier(device);
    if (targetId.isNotEmpty) {
      return 'id:$targetId';
    }
    if (trimmedStateId.isNotEmpty) {
      return 'id:$trimmedStateId';
    }
    return 'name:${device.name}';
  }

  double _resolveStateVolume(ConnectVolumeState volumeState) {
    if (volumeState.effectiveVolume case final effective?) {
      return boundNormalizedVolume(effective);
    }
    if (volumeState.activeDevice case final device?) {
      return boundNormalizedVolume(device.normalizedVolume);
    }
    return switch (widget.initialVolume) {
      final v? => boundNormalizedVolume(v),
      null => 0.0,
    };
  }

  void _dispatchVolumeSet(
    double boundedVolume,
    RemoteVolumeController? volumeCtrl,
  ) {
    if (widget.onVolumeChanged case final callback?) {
      callback(boundedVolume);
      return;
    }
    if (widget.controller case final mobius?) {
      if (!mobius.isClosed) {
        mobius.dispatch(SetVolumeRequested(volume: boundedVolume));
      }
      return;
    }
    if (volumeCtrl != null) {
      volumeCtrl.setVolume(boundedVolume);
    }
  }

  void _dispatchStep(int direction, RemoteVolumeController? volumeCtrl) {
    if (widget.onStepVolume case final callback?) {
      callback(direction);
      return;
    }
    if (widget.controller case final mobius?) {
      if (!mobius.isClosed) {
        mobius.dispatch(StepVolumeRequested(direction: direction));
      }
      return;
    }
    if (volumeCtrl != null) {
      if (direction > 0) {
        volumeCtrl.volumeUp();
      } else {
        volumeCtrl.volumeDown();
      }
    }
  }
}

class _InteractiveVolumeSliderCard extends StatefulWidget {
  const _InteractiveVolumeSliderCard({
    super.key,
    required this.isControllable,
    required this.canDragSlider,
    required this.canStep,
    required this.volume,
    required this.deviceName,
    required this.onVolumeChanged,
    required this.onStepVolume,
  });

  final bool isControllable;
  final bool canDragSlider;
  final bool canStep;
  final double volume;
  final String deviceName;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<int> onStepVolume;

  @override
  State<_InteractiveVolumeSliderCard> createState() =>
      _InteractiveVolumeSliderCardState();
}

class _InteractiveVolumeSliderCardState
    extends State<_InteractiveVolumeSliderCard> {
  double? _dragValue;
  int? _lastHapticPercent;

  @override
  Widget build(BuildContext context) {
    final bool isControllable = widget.isControllable;
    final bool canDragSlider = widget.canDragSlider;
    final bool canStep = widget.canStep;
    final double displayValue = isControllable
        ? switch (_dragValue) {
            final dragging? => boundNormalizedVolume(dragging),
            null => boundNormalizedVolume(widget.volume),
          }
        : 0.0;
    final int percent = (displayValue * 100).round();

    return Container(
      key: const ValueKey<String>('connect_volume_slider_container'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PlayerColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                displayValue <= 0.0 || !isControllable
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                size: 16,
                color: isControllable
                    ? kSpotifyConnectGreen
                    : PlayerColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.deviceName.trim().isNotEmpty
                      ? 'Volume: ${widget.deviceName}'
                      : 'Remote volume',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isControllable
                        ? PlayerColors.textPrimary
                        : PlayerColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                isControllable ? '$percent%' : 'Unavailable',
                key: const ValueKey<String>('connect_volume_percentage'),
                style: TextStyle(
                  color: _dragValue != null && canDragSlider
                      ? kSpotifyConnectGreen
                      : PlayerColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                key: const ValueKey<String>('volume_step_down_button'),
                icon: const Icon(Icons.remove_rounded, size: 20),
                color: canStep
                    ? PlayerColors.textPrimary
                    : PlayerColors.muted,
                tooltip: 'Volume down',
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: canStep ? () => widget.onStepVolume(-1) : null,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: _dragValue != null ? 8.0 : 5.0,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: _dragValue != null ? 9.0 : 7.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16.0,
                    ),
                    activeTrackColor: kSpotifyConnectGreen,
                    inactiveTrackColor: PlayerColors.divider,
                    disabledActiveTrackColor: PlayerColors.muted,
                    disabledInactiveTrackColor: PlayerColors.divider,
                    thumbColor: Colors.white,
                    disabledThumbColor: PlayerColors.muted,
                  ),
                  child: Slider(
                    key: const ValueKey<String>('connect_volume_slider'),
                    value: displayValue,
                    min: 0.0,
                    max: 1.0,
                    onChangeStart: canDragSlider
                        ? (startValue) {
                            final bounded = boundNormalizedVolume(startValue);
                            setState(() {
                              _dragValue = bounded;
                              _lastHapticPercent = (bounded * 100).round();
                            });
                          }
                        : null,
                    onChanged: canDragSlider
                        ? (nextValue) {
                            final bounded = boundNormalizedVolume(nextValue);
                            final nextPercent = (bounded * 100).round();
                            if (_lastHapticPercent != nextPercent) {
                              _lastHapticPercent = nextPercent;
                              HapticFeedback.selectionClick();
                            }
                            setState(() {
                              _dragValue = bounded;
                            });
                            widget.onVolumeChanged(bounded);
                          }
                        : null,
                    onChangeEnd: canDragSlider
                        ? (endValue) {
                            final bounded = boundNormalizedVolume(endValue);
                            setState(() {
                              _dragValue = null;
                              _lastHapticPercent = null;
                            });
                            widget.onVolumeChanged(bounded);
                          }
                        : null,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey<String>('volume_step_up_button'),
                icon: const Icon(Icons.add_rounded, size: 20),
                color: canStep
                    ? PlayerColors.textPrimary
                    : PlayerColors.muted,
                tooltip: 'Volume up',
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: canStep ? () => widget.onStepVolume(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
