import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';

import 'player_theme.dart';
import 'queue_controls_layout.dart';

class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    this.duration = const Duration(minutes: 3, seconds: 50),
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.dragPosition,
    required this.onDragPositionChanged,
    this.onSeek,
  });

  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? dragPosition;
  final ValueChanged<Duration?> onDragPositionChanged;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final currentPos = dragPosition ?? position;
    final currentPosMs = currentPos.inMilliseconds.toDouble();
    final durationMs = duration.inMilliseconds.toDouble();
    final bufferedMs = bufferedPosition.inMilliseconds.toDouble();

    final maxVal = durationMs > 0 ? durationMs : 1.0;
    final sliderVal = currentPosMs.clamp(0.0, maxVal);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.5,
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
            secondaryTrackValue: bufferedMs > 0 ? bufferedMs.clamp(0.0, maxVal) : null,
            onChanged: (val) {
              onDragPositionChanged(Duration(milliseconds: val.round()));
            },
            onChangeEnd: (val) {
              final target = Duration(milliseconds: val.round());
              onDragPositionChanged(null);
              onSeek?.call(target);
            },
          ),
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
                DurationFormatter.duration(duration),
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

class PlayerPlaybackControls extends StatelessWidget {
  const PlayerPlaybackControls({
    super.key,
    this.isPlaying = false,
    this.isBuffering = false,
    this.shuffleMode = QueueShuffleMode.none,
    this.repeatMode = QueueRepeatMode.none,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onShuffle,
    this.onRepeat,
  });

  final bool isPlaying;
  final bool isBuffering;
  final QueueShuffleMode shuffleMode;
  final QueueRepeatMode repeatMode;
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
          onPressed: onPrevious,
          size: 38,
        ),
        _PlayPauseButton(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
          onPressed: onPlayPause,
        ),
        _TransportButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next track',
          onPressed: onNext,
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
    required this.isPlaying,
    required this.isBuffering,
    this.onPressed,
  });

  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: isBuffering ? null : onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: isBuffering
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.black87,
                      ),
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.white, size: size),
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
            final color = animatedColor ?? targetColor;
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
            onPressed: onDevice ?? () {},
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
          onTap: onQueue,
        ),
        _SecondaryButton(
          icon: Icons.lyrics_outlined,
          label: 'Lyrics',
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
