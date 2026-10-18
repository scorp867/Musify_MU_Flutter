import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

/// 1:1 with Spotify's sticky current track row in the Queue Sheet.
///
/// Visual structure:
///   [48x48 Artwork] [Equalizer + Green Title / Gray Subtitle] [34x34 Solid White Pause/Play Circle]
class QueueNowPlayingRow extends StatelessWidget {
  const QueueNowPlayingRow({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    this.imageUrl,
    this.songId,
    this.isPlaying = true,
    this.onTap,
    this.onPlayPause,
  });

  final String title;
  final String artist;
  final String? imageUrl;
  final int? songId;
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
    final trackKey = ValueKey<String>('$title-$artist');

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
                            songId: songId,
                            imageUrl: imageUrl,
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
                                      title.isNotEmpty
                                          ? title
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
                                artist.isNotEmpty
                                    ? artist
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
    extends State<_EncoreCirclePlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: widget.isPlaying
              ? SpotifyIcon.pause(size: 16, color: Colors.black)
              : Padding(
                  padding: const EdgeInsets.only(left: 1.5),
                  child: SpotifyIcon.play(size: 16, color: Colors.black),
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
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _barCount = 3;
  static const _durations = [480, 620, 530];
  static const _minHeights = [3.0, 5.0, 4.0];
  static const _maxHeights = [14.0, 18.0, 15.0];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      );
    });
    _animations = List.generate(_barCount, (i) {
      return Tween<double>(begin: _minHeights[i], end: _maxHeights[i]).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });
    _syncAnimations();
  }

  @override
  void didUpdateWidget(_PlayIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    for (int i = 0; i < _barCount; i++) {
      if (widget.isPlaying) {
        _controllers[i].repeat(reverse: true);
      } else {
        _controllers[i].stop();
        _controllers[i].animateTo(0.0, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_barCount, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < _barCount - 1 ? 2.0 : 0),
          child: AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                width: 2.5,
                height: _animations[i].value,
                decoration: BoxDecoration(
                  color: PlayerColors.accent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
