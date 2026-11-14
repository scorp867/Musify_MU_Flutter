import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';

import 'player_theme.dart';
import 'queue_controls_layout.dart';

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

class PlayerPlaybackControls extends StatelessWidget {
  const PlayerPlaybackControls({
    super.key,
    this.transportPhase = NowPlayingTransportPhase.paused,
    this.shuffleMode = QueueShuffleMode.none,
    this.repeatMode = QueueRepeatMode.none,
    this.canSkipNext = true,
    this.canSkipPrevious = true,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onShuffle,
    this.onRepeat,
  });

  final NowPlayingTransportPhase transportPhase;
  final QueueShuffleMode shuffleMode;
  final QueueRepeatMode repeatMode;
  final bool canSkipNext;
  final bool canSkipPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;

  bool get _isShuffling => shuffleMode == QueueShuffleMode.all;

  bool get _isRepeating =>
      repeatMode == QueueRepeatMode.all || repeatMode == QueueRepeatMode.one;

  bool get _isRepeatingOne => repeatMode == QueueRepeatMode.one;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SpotifyTransportButton(
          tooltip: _isShuffling ? 'Disable shuffle' : 'Enable shuffle',
          isActive: _isShuffling,
          onPressed: onShuffle,
          iconBuilder: (color) => SpotifyIcon.shuffle(color: color, size: 22),
        ),
        _TransportButton(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous track',
          onPressed: canSkipPrevious ? onPrevious : null,
          size: 38,
        ),
        _PlayPauseButton(
          transportPhase: transportPhase,
          onPressed: onPlayPause,
        ),
        _TransportButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next track',
          onPressed: canSkipNext ? onNext : null,
          size: 38,
        ),
        _SpotifyTransportButton(
          tooltip: _isRepeatingOne
              ? 'Repeat one'
              : _isRepeating
                  ? 'Repeat all'
                  : 'Enable repeat',
          isActive: _isRepeating,
          onPressed: onRepeat,
          iconBuilder: (color) => _isRepeatingOne
              ? SpotifyIcon.repeatOnce(color: color, size: 22)
              : SpotifyIcon.repeat(color: color, size: 22),
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.transportPhase,
    this.onPressed,
  });

  final NowPlayingTransportPhase transportPhase;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconData = switch (transportPhase) {
      NowPlayingTransportPhase.playing ||
      NowPlayingTransportPhase.bufferingUnplayedSegment =>
        Icons.pause_rounded,
      NowPlayingTransportPhase.paused => Icons.play_arrow_rounded,
    };

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Icon(
              iconData,
              color: Colors.black,
              size: 38,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 28,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: isEnabled ? Colors.white : Colors.white38,
        size: size,
      ),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}

class _SpotifyTransportButton extends StatelessWidget {
  const _SpotifyTransportButton({
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
    required this.iconBuilder,
  });

  final String tooltip;
  final bool isActive;
  final VoidCallback? onPressed;
  final Widget Function(Color color) iconBuilder;

  @override
  Widget build(BuildContext context) {
    final targetColor = isActive
        ? PlayerColors.accent
        : Colors.white.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: targetColor),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, animatedColor, _) {
            final color = switch (animatedColor) {
              final c? => c,
              null => targetColor,
            };
            return IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              icon: iconBuilder(color),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            );
          },
        ),
        if (isActive)
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: PlayerColors.accent,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}

class PlayerUtilityRow extends StatelessWidget {
  const PlayerUtilityRow({
    super.key,
    required this.onQueue,
    this.onDevice,
  });

  final VoidCallback onQueue;
  final VoidCallback? onDevice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.devices_rounded,
              color: Colors.white60,
              size: 22,
            ),
            tooltip: 'Devices',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: switch (onDevice) {
              final cb? => cb,
              null => () {},
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.queue_music_rounded,
              color: Colors.white60,
              size: 24,
            ),
            tooltip: 'Queue',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onQueue,
          ),
        ],
      ),
    );
  }
}

class PlayerSecondaryControls extends StatelessWidget {
  const PlayerSecondaryControls({
    super.key,
    required this.shuffleEnabled,
    required this.repeatEnabled,
    required this.onShuffle,
    required this.onRepeat,
    required this.onQueue,
    required this.onLyrics,
  });

  final bool shuffleEnabled;
  final bool repeatEnabled;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final VoidCallback onQueue;
  final VoidCallback onLyrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SecondaryButton(
          icon: Icons.shuffle_rounded,
          label: 'Shuffle',
          active: shuffleEnabled,
          onTap: onShuffle,
        ),
        _SecondaryButton(
          icon: repeatEnabled ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          label: repeatEnabled ? 'Repeat one' : 'Repeat',
          active: repeatEnabled,
          onTap: onRepeat,
        ),
        _SecondaryButton(
          icon: Icons.queue_music_rounded,
          label: 'Queue',
          active: false,
          onTap: onQueue,
        ),
        _SecondaryButton(
          icon: Icons.lyrics_outlined,
          label: 'Lyrics',
          active: false,
          onTap: onLyrics,
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? PlayerColors.accent : PlayerColors.muted;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Icon(icon, color: color, size: 23),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
