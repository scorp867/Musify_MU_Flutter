import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

/// 1:1 with Spotify's sticky current track row in the Queue Sheet.
///
/// Visual structure:
///   [48x48 Artwork] [Equalizer + Green Title / Gray Subtitle] [34x34 Solid White Pause/Play Circle]
class QueueNowPlayingRow extends StatelessWidget {
  const QueueNowPlayingRow({
    super.key,
    required this.track,
    this.isPlaying = true,
    this.onTap,
    this.onPlayPause,
  });

  final ContextTrack track;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;

  @override
  Widget build(BuildContext context) {
    final mediaItem = track.toMediaItem();

    return Material(
      color: PlayerColors.background,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.06),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 48x48 Artwork with 4dp corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: PlayerArtworkImage(
                      item: mediaItem,
                      artworkWidth: 48,
                      artworkHeight: 48,
                      placeholderIconSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Equalizer + Title + Subtitle
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _PlayIndicator(isPlaying: isPlaying),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              track.title.isNotEmpty
                                  ? track.title
                                  : 'Unknown Track',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PlayerColors.accent,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist.isNotEmpty
                            ? track.artist
                            : 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PlayerColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Solid white circle Play/Pause button on right
                GestureDetector(
                  onTap: onPlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: Tween<double>(begin: 0.75, end: 1.0)
                              .animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: isPlaying
                            ? SpotifyIcon.pause(
                                key: const ValueKey('pause'),
                                color: Colors.black,
                                size: 15,
                              )
                            : SpotifyIcon.play(
                                key: const ValueKey('play'),
                                color: Colors.black,
                                size: 15,
                              ),
                      ),
                    ),
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

class _PlayIndicator extends StatefulWidget {
  const _PlayIndicator({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_PlayIndicator> createState() => _PlayIndicatorState();
}

class _PlayIndicatorState extends State<_PlayIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PlayIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(
          0.15,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 13,
      height: 13,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _EqualizerPainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
              color: PlayerColors.accent,
            ),
          );
        },
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;

  const _EqualizerPainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barCount = 3;
    final barWidth = size.width / 5.0;
    final gap = barWidth;
    final maxHeight = size.height;

    const heightsWhenPaused = [0.65, 0.35, 0.80];

    for (var i = 0; i < barCount; i++) {
      final double factor;
      if (!isPlaying) {
        factor = heightsWhenPaused[i];
      } else {
        final phase = (progress + i * 0.37) % 1.0;
        final wave = (phase * 2.0 - 1.0).abs();
        factor = 0.25 + 0.75 * wave;
      }
      final barHeight = maxHeight * factor;
      final x = i * (barWidth + gap);
      final y = maxHeight - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.0),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.color != color;
  }
}
