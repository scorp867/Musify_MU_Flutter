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

  static const Cubic _trackSwitchCurve = Cubic(0.3, 0.0, 0.0, 1.0);
  static const Duration _trackSwitchDuration = Duration(milliseconds: 280);

  static final Tween<double> _artworkScaleTween =
      Tween<double>(begin: 0.90, end: 1.0);
  static final Tween<Offset> _slideInTween = Tween<Offset>(
    begin: const Offset(0.0, 0.35),
    end: Offset.zero,
  );
  static final Tween<Offset> _slideOutTween = Tween<Offset>(
    begin: const Offset(0.0, -0.35),
    end: Offset.zero,
  );

  static Widget _slideStackLayoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        ...previousChildren,
        ?currentChild,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = track.toMediaItem();
    final trackKey = ValueKey<String>(track.uri);

    return RepaintBoundary(
      child: Material(
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
                  // 48x48 Artwork with 4dp corners + smooth crossfade/scale on track change
                  RepaintBoundary(
                    child: AnimatedSwitcher(
                      duration: _trackSwitchDuration,
                      switchInCurve: _trackSwitchCurve,
                      switchOutCurve: _trackSwitchCurve,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: _artworkScaleTween.animate(anim),
                          child: child,
                        ),
                      ),
                      child: ClipRRect(
                        key: trackKey,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
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
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Equalizer + Animated Title & Subtitle
                  Expanded(
                    child: RepaintBoundary(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _PlayIndicator(isPlaying: isPlaying),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRect(
                                  child: AnimatedSwitcher(
                                    duration: _trackSwitchDuration,
                                    switchInCurve: _trackSwitchCurve,
                                    switchOutCurve: _trackSwitchCurve,
                                    layoutBuilder: _slideStackLayoutBuilder,
                                    transitionBuilder: (child, anim) {
                                      final slideTween = child.key == trackKey
                                          ? _slideInTween
                                          : _slideOutTween;
                                      return FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: slideTween.animate(anim),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      track.title.isNotEmpty
                                          ? track.title
                                          : 'Unknown Track',
                                      key: trackKey,
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
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          ClipRect(
                            child: AnimatedSwitcher(
                              duration: _trackSwitchDuration,
                              switchInCurve: _trackSwitchCurve,
                              switchOutCurve: _trackSwitchCurve,
                              layoutBuilder: _slideStackLayoutBuilder,
                              transitionBuilder: (child, anim) {
                                final slideTween = child.key == trackKey
                                    ? _slideInTween
                                    : _slideOutTween;
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: slideTween.animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                track.artist.isNotEmpty
                                    ? track.artist
                                    : 'Unknown Artist',
                                key: trackKey,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PlayerColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Solid white circle Play/Pause button isolated in its own RepaintBoundary
                  RepaintBoundary(
                    child: _EncoreCirclePlayPauseButton(
                      isPlaying: isPlaying,
                      onTap: onPlayPause,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EncoreCirclePlayPauseButton extends StatefulWidget {
  const _EncoreCirclePlayPauseButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback? onTap;

  @override
  State<_EncoreCirclePlayPauseButton> createState() =>
      _EncoreCirclePlayPauseButtonState();
}

class _EncoreCirclePlayPauseButtonState
    extends State<_EncoreCirclePlayPauseButton> {
  bool _isPressed = false;

  // Matches Spotify res/anim/encore_button_animation_interpolator.xml
  // and @integer/encore_button_animation_time (200ms)
  static const Cubic _encoreButtonCurve = Cubic(0.3, 0.0, 0.0, 1.0);
  static const Duration _encoreButtonDuration = Duration(milliseconds: 200);
  static final Tween<double> _iconScaleTween =
      Tween<double>(begin: 0.78, end: 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: _encoreButtonDuration,
        curve: _encoreButtonCurve,
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: _encoreButtonDuration,
              switchInCurve: _encoreButtonCurve,
              switchOutCurve: _encoreButtonCurve,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: _iconScaleTween.animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: widget.isPlaying
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
      duration: const Duration(milliseconds: 850),
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
          duration: const Duration(milliseconds: 250),
          curve: const Cubic(0.3, 0.0, 0.0, 1.0),
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
    // Isolated in its own RepaintBoundary and driven via CustomPainter(repaint:)
    // so 120Hz equalizer ticks cause 0 widget rebuilds and never repaint neighbors.
    return RepaintBoundary(
      child: SizedBox(
        width: 13,
        height: 13,
        child: CustomPaint(
          painter: _EqualizerPainter(
            animation: _controller,
            isPlaying: widget.isPlaying,
            color: PlayerColors.accent,
          ),
        ),
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isPlaying;
  final Color color;
  final Paint _barPaint;

  _EqualizerPainter({
    required this.animation,
    required this.isPlaying,
    required this.color,
  })  : _barPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 3;
    final barWidth = size.width / 5.0;
    final gap = barWidth;
    final maxHeight = size.height;
    final progress = animation.value;

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
        _barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) {
    return oldDelegate.isPlaying != isPlaying || oldDelegate.color != color;
  }
}
