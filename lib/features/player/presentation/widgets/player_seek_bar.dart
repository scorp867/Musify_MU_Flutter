import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';

/// Seek bar with elapsed/total duration, scrubber interaction, and flowing
/// silver wave animation during unplayed segment buffering.
///
/// Citations:
/// - Decompiled Java: `com/spotify/music/nowplaying/` (Seek bar and scrubber timeline)
/// - Decompiled Java: `p199p/ac0.java` (Player transport and seek layout)
/// - Native binary: `spotify::connect::ConnectStateClientImpl` (`liborbit-jni-spotify.so` @ `0x1522e9`)
class PlayerSeekBar extends StatefulWidget {
  const PlayerSeekBar({
    super.key,
    this.duration = const Duration(minutes: 3, seconds: 50),
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.dragPosition,
    this.transportPhase = NowPlayingTransportPhase.paused,
    required this.onDragPositionChanged,
    this.onSeek,
  });

  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? dragPosition;
  final NowPlayingTransportPhase transportPhase;
  final ValueChanged<Duration?> onDragPositionChanged;
  final ValueChanged<Duration>? onSeek;

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _syncFlowAnimation(widget.transportPhase);
  }

  @override
  void didUpdateWidget(covariant PlayerSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transportPhase != widget.transportPhase) {
      _syncFlowAnimation(widget.transportPhase);
    }
  }

  void _syncFlowAnimation(NowPlayingTransportPhase phase) {
    switch (phase) {
      case NowPlayingTransportPhase.bufferingUnplayedSegment:
        if (!_flowController.isAnimating) {
          _flowController.repeat();
        }
      case NowPlayingTransportPhase.playing:
      case NowPlayingTransportPhase.paused:
        if (_flowController.isAnimating) {
          _flowController.stop();
        }
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawPos = switch (widget.dragPosition) {
      final p? => p,
      null => widget.position,
    };
    final currentPos = rawPos.isNegative
        ? Duration.zero
        : (widget.duration > Duration.zero && rawPos > widget.duration
              ? widget.duration
              : rawPos);
    final currentPosMs = currentPos.inMilliseconds.toDouble();
    final durationMs = widget.duration.inMilliseconds.toDouble();
    final bufferedMs = widget.bufferedPosition.inMilliseconds.toDouble();

    final maxVal = durationMs > 0 ? durationMs : 1.0;
    final double sliderVal;
    if (currentPosMs <= 0.0) {
      sliderVal = 0.0;
    } else if (currentPosMs >= maxVal) {
      sliderVal = maxVal;
    } else {
      sliderVal = currentPosMs;
    }

    final double? secondaryVal;
    if (bufferedMs <= 0.0) {
      secondaryVal = null;
    } else if (bufferedMs >= maxVal) {
      secondaryVal = maxVal;
    } else {
      secondaryVal = bufferedMs;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _flowController,
          builder: (context, _) {
            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.5,
                trackShape: _SilverFlowingSliderTrackShape(
                  transportPhase: widget.transportPhase,
                  flowProgress: _flowController.value,
                ),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 5.5,
                  elevation: 2,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.20),
                secondaryActiveTrackColor: Colors.white.withValues(alpha: 0.35),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: sliderVal,
                min: 0.0,
                max: maxVal,
                secondaryTrackValue: secondaryVal,
                onChanged: (val) {
                  widget.onDragPositionChanged(
                    Duration(milliseconds: val.round()),
                  );
                },
                onChangeEnd: (val) {
                  final target = Duration(milliseconds: val.round());
                  widget.onDragPositionChanged(null);
                  widget.onSeek?.call(target);
                },
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DurationFormatter.duration(currentPos),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                DurationFormatter.duration(widget.duration),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom slider track shape that renders:
/// 1. The played region (`trackRect.left` -> `thumbCenter.dx`) in solid white.
/// 2. The unplayed region (`thumbCenter.dx` -> `trackRect.right`):
///    - When `transportPhase == NowPlayingTransportPhase.bufferingUnplayedSegment`:
///      a hardware-accelerated right-to-left flowing metallic silver loading line
///      traveling from the right end of the bar toward the seek thumb.
///    - Otherwise: the standard static translucent inactive track.
class _SilverFlowingSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const _SilverFlowingSliderTrackShape({
    required this.transportPhase,
    required this.flowProgress,
  });

  final NowPlayingTransportPhase transportPhase;
  final double flowProgress;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (trackRect.isEmpty) {
      return;
    }

    final Canvas canvas = context.canvas;
    final Radius trackRadius = Radius.circular(trackRect.height / 2.0);
    final double splitX = thumbCenter.dx < trackRect.left
        ? trackRect.left
        : (thumbCenter.dx > trackRect.right ? trackRect.right : thumbCenter.dx);

    // 1. Played segment (left of seek thumb): solid white
    if (splitX > trackRect.left) {
      final Rect playedRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        splitX,
        trackRect.bottom,
      );
      final Paint activePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          playedRect,
          topLeft: trackRadius,
          bottomLeft: trackRadius,
        ),
        activePaint,
      );
    }

    // 2. Unplayed segment (seek thumb -> right end of bar)
    if (splitX >= trackRect.right) {
      return;
    }

    final Rect unplayedRect = Rect.fromLTRB(
      splitX,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );
    final RRect unplayedRRect = RRect.fromRectAndCorners(
      unplayedRect,
      topRight: trackRadius,
      bottomRight: trackRadius,
      topLeft: splitX <= trackRect.left ? trackRadius : Radius.zero,
      bottomLeft: splitX <= trackRect.left ? trackRadius : Radius.zero,
    );

    switch (transportPhase) {
      case NowPlayingTransportPhase.playing:
      case NowPlayingTransportPhase.paused:
        final Paint inactivePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.20)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(unplayedRRect, inactivePaint);

        if (secondaryOffset != null && secondaryOffset.dx > splitX) {
          final double secRight = secondaryOffset.dx > trackRect.right
              ? trackRect.right
              : secondaryOffset.dx;
          final Rect secondaryRect = Rect.fromLTRB(
            splitX,
            trackRect.top,
            secRight,
            trackRect.bottom,
          );
          final Paint secondaryPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill;
          canvas.drawRect(secondaryRect, secondaryPaint);
        }

      case NowPlayingTransportPhase.bufferingUnplayedSegment:
        // Base silver-steel unplayed bed
        final Paint baseBedPaint = Paint()
          ..color = const Color(0x3D9AA2AE)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(unplayedRRect, baseBedPaint);

        // Right-to-left flowing silver wave across the unplayed segment
        final double waveCenter = 1.28 - (flowProgress * 1.56);
        const double halfSpan = 0.28;
        final double startX =
            unplayedRect.left +
            (unplayedRect.width * (waveCenter - halfSpan));
        final double endX =
            unplayedRect.left +
            (unplayedRect.width * (waveCenter + halfSpan));

        final Shader silverWaveShader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const <Color>[
            Color(0x00B4BCC8),
            Color(0x8CD0D6E0),
            Color(0xFFF4F6FA),
            Color(0x8CD0D6E0),
            Color(0x00B4BCC8),
          ],
          stops: const <double>[0.0, 0.28, 0.50, 0.72, 1.0],
        ).createShader(
          Rect.fromLTRB(startX, unplayedRect.top, endX, unplayedRect.bottom),
        );

        final Paint wavePaint = Paint()
          ..shader = silverWaveShader
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.clipRRect(unplayedRRect);
        canvas.drawRect(unplayedRect, wavePaint);
        canvas.restore();
    }
  }
}
