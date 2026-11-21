// 1:1 replica of Spotify's custom Canvas Connect volume slider
// (`p199p/jel1.java` lines 2250-2800, `p199p/jth1.java`, `p199p/zew0.java`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// Stream-isolated Connect remote volume slider bound to [ConnectMobiusController]
/// (`p199p/jel1.java` + `p199p/jth1.java`).
class ConnectVolumeSlider extends StatelessWidget {
  const ConnectVolumeSlider({
    super.key,
    required this.controller,
    required this.deviceName,
    this.showIcons = true,
  });

  final ConnectMobiusController controller;
  final String deviceName;
  final bool showIcons;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectVolumeState>(
      stream: controller.remoteVolumeController.stream,
      initialData: controller.remoteVolumeController.state,
      builder: (context, snapshot) {
        final ConnectVolumeState volumeState = switch (snapshot.data) {
          final data? => data,
          null => controller.remoteVolumeController.state,
        };

        final bool controllable = volumeState.isRemoteVolumeControllable;
        final double normalizedVolume = switch (volumeState.effectiveVolume) {
          final v? => boundNormalizedVolume(v),
          null => 0.0,
        };

        return SpotifyVolumeSliderBar(
          value: normalizedVolume,
          deviceName: deviceName,
          enabled: controllable,
          showIcons: showIcons,
          onChanged: controllable
              ? (next) {
                  if (!controller.isClosed) {
                    controller.dispatch(SetVolumeRequested(volume: next));
                  }
                }
              : null,
          onStepDown: controllable
              ? () {
                  if (!controller.isClosed) {
                    controller.dispatch(StepVolumeRequested(direction: -1));
                  }
                }
              : null,
          onStepUp: controllable
              ? () {
                  if (!controller.isClosed) {
                    controller.dispatch(StepVolumeRequested(direction: 1));
                  }
                }
              : null,
        );
      },
    );
  }
}

/// Pure Spotify Canvas volume slider bar matching `jel1.java` + `jth1.java`
/// byte for byte:
/// - Outer padding: `16dp H` (with icons) or `4dp H` (without), `8dp V`, `minHeight 28dp`.
/// - Start/End `16dp` icons (`VolumeOneWave16` / `Volume16`) with `16dp` gap to track.
/// - Animated idle -> drag morph (`150ms`):
///   - Track height: `12dp -> 22dp`
///   - Thumb height: `16dp -> 26dp`
///   - Corner radius: `6dp -> 12dp`
///   - Square-cap extra: `4dp -> 6dp`
/// - Thumb: `4dp` wide `#FFFFFF` vertical pill (`2dp` radius).
/// - Active fill: `#1ED760` (enabled) or `#B3B3B3` (disabled), squared right edge
///   against the thumb when `activeWidth > radius + extra`.
/// - Floating drag percentage (`0..100`, `13sp Bold`): visible only while dragging;
///   white `#FFFFFF` `4dp` left of thumb when `> 85%`, else `#1ED760` `4dp` right of thumb.
class SpotifyVolumeSliderBar extends StatefulWidget {
  const SpotifyVolumeSliderBar({
    super.key,
    required this.value,
    required this.deviceName,
    this.enabled = true,
    this.showIcons = true,
    this.onChanged,
    this.onStepDown,
    this.onStepUp,
  });

  final double value;
  final String deviceName;
  final bool enabled;
  final bool showIcons;
  final ValueChanged<double>? onChanged;
  final VoidCallback? onStepDown;
  final VoidCallback? onStepUp;

  @override
  State<SpotifyVolumeSliderBar> createState() => _SpotifyVolumeSliderBarState();
}

class _SpotifyVolumeSliderBarState extends State<SpotifyVolumeSliderBar>
    with SingleTickerProviderStateMixin {
  static const double _thumbWidth = 4.0;
  static const double _thumbRadius = 2.0;

  AnimationController? _dragMorphController;
  bool _isDragging = false;
  double _displayValue = 0.0;
  int _lastHapticPercent = -1;

  @override
  void initState() {
    super.initState();
    _displayValue = boundNormalizedVolume(widget.value);
    _dragMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant SpotifyVolumeSliderBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _displayValue = boundNormalizedVolume(widget.value);
    }
    if (!widget.enabled && _isDragging) {
      _finishDrag();
    }
  }

  @override
  void dispose() {
    if (_dragMorphController case final controller?) {
      controller.dispose();
      _dragMorphController = null;
    }
    super.dispose();
  }

  void _updateFromLocalDx(double localDx, double trackWidth) {
    if (!widget.enabled || trackWidth <= 0) {
      return;
    }
    final double raw = localDx / trackWidth;
    final double bounded = boundNormalizedVolume(raw);
    final int percent = (bounded * 100.0).round();
    if (percent != _lastHapticPercent &&
        (percent == 0 || percent == 100 || (percent - _lastHapticPercent).abs() >= 5)) {
      _lastHapticPercent = percent;
      HapticFeedback.selectionClick();
    }
    if ((bounded - _displayValue).abs() >= 0.001) {
      setState(() {
        _displayValue = bounded;
      });
      widget.onChanged?.call(bounded);
    }
  }

  void _startDrag(double localDx, double trackWidth) {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _isDragging = true;
    });
    _dragMorphController?.forward();
    HapticFeedback.lightImpact();
    _updateFromLocalDx(localDx, trackWidth);
  }

  void _finishDrag() {
    if (!_isDragging) {
      return;
    }
    setState(() {
      _isDragging = false;
      _lastHapticPercent = -1;
    });
    _dragMorphController?.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = widget.showIcons ? 16.0 : 4.0;
    final Color iconColor = widget.enabled
        ? ConnectEncoreTheme.textBase
        : ConnectEncoreTheme.textSubdued;
    final Color activeColor = widget.enabled
        ? ConnectEncoreTheme.brightAccent
        : ConnectEncoreTheme.textSubdued;
    final int volumePercent = (_displayValue * 100.0).round();

    final morph = _dragMorphController;
    if (morph == null) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Volume for ${widget.deviceName}',
      value: '$volumePercent%',
      enabled: widget.enabled,
      slider: true,
      increasedValue: '${volumePercent + 5 > 100 ? 100 : volumePercent + 5}%',
      decreasedValue: '${volumePercent - 5 < 0 ? 0 : volumePercent - 5}%',
      onIncrease: widget.enabled ? widget.onStepUp : null,
      onDecrease: widget.enabled ? widget.onStepDown : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28.0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showIcons) ...[
                GestureDetector(
                  key: const ValueKey<String>('volume_icon_start'),
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.enabled ? widget.onStepDown : null,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: ConnectEncoreIcon(
                      icon: _displayValue <= 0.001
                          ? ConnectEncoreIcons.volumeOff16
                          : ConnectEncoreIcons.volumeOneWave16,
                      size: 16.0,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double trackWidth = constraints.maxWidth;
                    return GestureDetector(
                      key: const ValueKey<String>('connect_volume_track'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: widget.enabled
                          ? (details) =>
                              _startDrag(details.localPosition.dx, trackWidth)
                          : null,
                      onTapUp: widget.enabled ? (_) => _finishDrag() : null,
                      onTapCancel: widget.enabled ? _finishDrag : null,
                      onHorizontalDragStart: widget.enabled
                          ? (details) =>
                              _startDrag(details.localPosition.dx, trackWidth)
                          : null,
                      onHorizontalDragUpdate: widget.enabled
                          ? (details) => _updateFromLocalDx(
                                details.localPosition.dx,
                                trackWidth,
                              )
                          : null,
                      onHorizontalDragEnd:
                          widget.enabled ? (_) => _finishDrag() : null,
                      onHorizontalDragCancel:
                          widget.enabled ? _finishDrag : null,
                      child: AnimatedBuilder(
                        animation: morph,
                        builder: (context, _) {
                          final double t = Curves.easeOutCubic.transform(morph.value);
                          final double trackHeight = 12.0 + (22.0 - 12.0) * t;
                          final double thumbHeight = 16.0 + (26.0 - 16.0) * t;
                          final double trackRadius = 6.0 + (12.0 - 6.0) * t;
                          final double squareCapExtra = 4.0 + (6.0 - 4.0) * t;

                          final double thumbCenterX =
                              _computeThumbCenterX(trackWidth, _displayValue);
                          final bool showLeftOfThumb = _displayValue > 0.85;

                          return SizedBox(
                            height: 28.0,
                            width: trackWidth,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.centerLeft,
                              children: [
                                Positioned.fill(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _SpotifyVolumeTrackPainter(
                                        progress: _displayValue,
                                        trackHeight: trackHeight,
                                        thumbHeight: thumbHeight,
                                        trackRadius: trackRadius,
                                        squareCapExtra: squareCapExtra,
                                        thumbWidth: _thumbWidth,
                                        thumbRadius: _thumbRadius,
                                        inactiveColor:
                                            ConnectEncoreTheme.tintedBase,
                                        activeColor: activeColor,
                                        thumbColor: ConnectEncoreTheme.textBase,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isDragging)
                                  Positioned(
                                    key: const ValueKey<String>(
                                      'volume_drag_percentage_label',
                                    ),
                                    left: showLeftOfThumb ? null : thumbCenterX + (_thumbWidth / 2.0) + 4.0,
                                    right: showLeftOfThumb
                                        ? (trackWidth - thumbCenterX) + (_thumbWidth / 2.0) + 4.0
                                        : null,
                                    child: IgnorePointer(
                                      child: Text(
                                        '$volumePercent',
                                        style: ConnectEncoreTheme.bodySmall13Bold
                                            .copyWith(
                                          color: showLeftOfThumb
                                              ? ConnectEncoreTheme.textBase
                                              : ConnectEncoreTheme.brightAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              if (widget.showIcons) ...[
                GestureDetector(
                  key: const ValueKey<String>('volume_icon_end'),
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.enabled ? widget.onStepUp : null,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: ConnectEncoreIcon(
                      icon: ConnectEncoreIcons.volume16,
                      size: 16.0,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static double _computeThumbCenterX(double trackWidth, double progress) {
    final double halfThumb = _thumbWidth / 2.0;
    if (trackWidth <= _thumbWidth) {
      return halfThumb;
    }
    final double rawCenter = trackWidth * progress;
    if (rawCenter < halfThumb) {
      return halfThumb;
    }
    if (rawCenter > trackWidth - halfThumb) {
      return trackWidth - halfThumb;
    }
    return rawCenter;
  }
}

final class _SpotifyVolumeTrackPainter extends CustomPainter {
  _SpotifyVolumeTrackPainter({
    required this.progress,
    required this.trackHeight,
    required this.thumbHeight,
    required this.trackRadius,
    required this.squareCapExtra,
    required this.thumbWidth,
    required this.thumbRadius,
    required this.inactiveColor,
    required this.activeColor,
    required this.thumbColor,
  });

  final double progress;
  final double trackHeight;
  final double thumbHeight;
  final double trackRadius;
  final double squareCapExtra;
  final double thumbWidth;
  final double thumbRadius;
  final Color inactiveColor;
  final Color activeColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final double centerY = size.height / 2.0;
    final double trackTop = centerY - (trackHeight / 2.0);
    final Radius corner = Radius.circular(trackRadius);

    // 1. Inactive full track rounded rectangle (`backgroundTintedBase`).
    final RRect inactiveRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.0, trackTop, size.width, trackHeight),
      corner,
    );
    canvas.drawRRect(
      inactiveRRect,
      Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // 2. Active filled track clipped cleanly against the vertical pill thumb
    // matching `jth1.java`: squared right side once activeWidth > radius + extra.
    final double activeWidth = size.width * progress;
    if (activeWidth > 0.5) {
      final Paint activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.save();
      canvas.clipRRect(inactiveRRect);

      if (activeWidth > trackRadius + squareCapExtra) {
        final RRect activeRRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(0.0, trackTop, activeWidth, trackHeight),
          topLeft: corner,
          bottomLeft: corner,
        );
        canvas.drawRRect(activeRRect, activePaint);
      } else {
        final RRect activeRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0.0, trackTop, activeWidth, trackHeight),
          corner,
        );
        canvas.drawRRect(activeRRect, activePaint);
      }
      canvas.restore();
    }

    // 3. White vertical pill thumb (`4dp` wide, `16dp -> 26dp` tall, `2dp` radius).
    final double halfThumb = thumbWidth / 2.0;
    double thumbCenterX = activeWidth;
    if (thumbCenterX < halfThumb) {
      thumbCenterX = halfThumb;
    } else if (thumbCenterX > size.width - halfThumb) {
      thumbCenterX = size.width - halfThumb;
    }

    final double thumbTop = centerY - (thumbHeight / 2.0);
    final RRect thumbRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        thumbCenterX - halfThumb,
        thumbTop,
        thumbWidth,
        thumbHeight,
      ),
      Radius.circular(thumbRadius),
    );
    canvas.drawRRect(
      thumbRRect,
      Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotifyVolumeTrackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.thumbHeight != thumbHeight ||
        oldDelegate.trackRadius != trackRadius ||
        oldDelegate.squareCapExtra != squareCapExtra ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.thumbColor != thumbColor;
  }
}
