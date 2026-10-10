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
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
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
    color: Color(0xFFB3B3B3),
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
  );
}

class PlayerPlaybackControls extends StatelessWidget {
  const PlayerPlaybackControls({
    super.key,
    required this.item,
    required this.playbackController,
    this.shuffleEnabled = false,
    this.repeatEnabled = false,
    this.onShuffle,
    this.onRepeat,
  });

  final MediaItem item;
  final PlaybackController playbackController;
  final bool shuffleEnabled;
  final bool repeatEnabled;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TransportButton(
          icon: Icons.shuffle_rounded,
          tooltip: 'Shuffle',
          iconColor: shuffleEnabled ? PlayerColors.accent : Colors.white60,
          showActiveDot: shuffleEnabled,
          onPressed: onShuffle,
          size: 24,
        ),
        _TransportButton(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous track',
          onPressed: playbackController.skipToPrevious,
          size: 38,
        ),
        _PlayPauseButton(playbackController: playbackController),
        _TransportButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next track',
          onPressed: playbackController.skipToNext,
          size: 38,
        ),
        _TransportButton(
          icon: repeatEnabled ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          tooltip: repeatEnabled ? 'Repeat one' : 'Repeat',
          iconColor: repeatEnabled ? PlayerColors.accent : Colors.white60,
          showActiveDot: repeatEnabled,
          onPressed: onRepeat,
          size: 24,
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.playbackController});

  final PlaybackController playbackController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: playbackController.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;
        final isBuffering =
            state?.processingState == AudioProcessingState.loading ||
            state?.processingState == AudioProcessingState.buffering;

        return Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: Colors.black54,
          child: InkWell(
            onTap: isBuffering
                ? null
                : playing
                ? playbackController.pause
                : playbackController.play,
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
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 38,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor = Colors.white,
    this.showActiveDot = false,
    this.size = 28,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color iconColor;
  final bool showActiveDot;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, color: iconColor, size: size),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        if (showActiveDot)
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
