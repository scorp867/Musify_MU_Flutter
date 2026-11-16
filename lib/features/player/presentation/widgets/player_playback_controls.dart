import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';

import 'player_theme.dart';
import 'queue_controls_layout.dart';

/// Primary playback transport controls: Shuffle, Skip Previous, Play/Pause,
/// Skip Next, and Repeat cycling with Spotify encore visual cues.
///
/// Citations:
/// - Decompiled Java: `p199p/ac0.java` (Player playback transport buttons)
/// - Native binary: `spotify::connect::ConnectStateClientImpl` (`liborbit-jni-spotify.so` @ `0x1522e9`)
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
