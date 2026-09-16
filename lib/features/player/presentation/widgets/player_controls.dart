import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';

import 'player_theme.dart';

class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.item,
    required this.playbackController,
    required this.dragPosition,
    required this.onDragPositionChanged,
  });

  final MediaItem item;
  final PlaybackController playbackController;
  final Duration? dragPosition;
  final ValueChanged<Duration?> onDragPositionChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<PlaybackState>(
          stream: playbackController.playbackState,
          builder: (context, stateSnapshot) {
            final state = stateSnapshot.data;
            final duration = item.duration ?? Duration.zero;
            final currentPosition =
                dragPosition ??
                positionSnapshot.data ??
                state?.position ??
                Duration.zero;

            final hasDuration = duration.inMilliseconds > 0;
            final maxValue = hasDuration
                ? duration.inMilliseconds.toDouble()
                : 1.0;
            final sliderValue = currentPosition.inMilliseconds
                .toDouble()
                .clamp(0.0, maxValue)
                .toDouble();
            final bufferedValue = (state?.bufferedPosition ?? Duration.zero)
                .inMilliseconds
                .toDouble()
                .clamp(0.0, maxValue)
                .toDouble();

            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                    secondaryActiveTrackColor: Colors.white.withValues(
                      alpha: 0.35,
                    ),
                    thumbColor: Colors.white,
                    overlayColor: PlayerColors.accent.withValues(alpha: 0.16),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 15,
                    ),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: sliderValue,
                    max: maxValue,
                    secondaryTrackValue: hasDuration ? bufferedValue : null,
                    onChanged: hasDuration
                        ? (value) {
                            onDragPositionChanged(
                              Duration(milliseconds: value.round()),
                            );
                          }
                        : null,
                    onChangeEnd: hasDuration
                        ? (value) {
                            final target = Duration(
                              milliseconds: value.round(),
                            );
                            playbackController.seek(target);
                            onDragPositionChanged(null);
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(currentPosition), style: _timeStyle),
                      Text(_formatDuration(duration), style: _timeStyle),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatDuration(Duration duration) {
    return DurationFormatter.duration(duration);
  }

  static const _timeStyle = TextStyle(
    color: PlayerColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class PlayerPlaybackControls extends StatelessWidget {
  const PlayerPlaybackControls({
    super.key,
    required this.item,
    required this.playbackController,
  });

  final MediaItem item;
  final PlaybackController playbackController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: playbackController.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;
        final position = state?.position ?? Duration.zero;
        final duration = item.duration ?? Duration.zero;
        final isBuffering =
            state?.processingState == AudioProcessingState.loading ||
            state?.processingState == AudioProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TransportButton(
              icon: Icons.replay_10_rounded,
              tooltip: 'Rewind 10 seconds',
              onPressed: () => _seekRelative(
                position,
                const Duration(seconds: -10),
                duration,
              ),
            ),
            const SizedBox(width: 8),
            _TransportButton(
              icon: Icons.skip_previous_rounded,
              tooltip: 'Previous track',
              onPressed: playbackController.skipToPrevious,
              size: 38,
            ),
            const SizedBox(width: 14),
            Material(
              color: PlayerColors.accent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isBuffering
                    ? null
                    : playing
                    ? playbackController.pause
                    : playbackController.play,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                    child: isBuffering
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                PlayerColors.background,
                              ),
                            ),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: PlayerColors.background,
                            size: 46,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            _TransportButton(
              icon: Icons.skip_next_rounded,
              tooltip: 'Next track',
              onPressed: playbackController.skipToNext,
              size: 38,
            ),
            const SizedBox(width: 8),
            _TransportButton(
              icon: Icons.forward_30_rounded,
              tooltip: 'Forward 30 seconds',
              onPressed: () => _seekRelative(
                position,
                const Duration(seconds: 30),
                duration,
              ),
            ),
          ],
        );
      },
    );
  }

  void _seekRelative(Duration position, Duration offset, Duration duration) {
    var target = position + offset;

    if (target.isNegative) {
      target = Duration.zero;
    }

    if (duration > Duration.zero && target > duration) {
      target = duration;
    }

    playbackController.seek(target);
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 31,
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
