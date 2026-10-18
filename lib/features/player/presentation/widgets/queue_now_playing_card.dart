import 'package:flutter/material.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

class QueueNowPlayingCard extends StatelessWidget {
  const QueueNowPlayingCard({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    this.imageUrl,
    this.songId,
    this.isPlaying = false,
  });

  final String title;
  final String artist;
  final String? imageUrl;
  final int? songId;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlayerColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PlayerArtworkImage(
                songId: songId,
                imageUrl: imageUrl,
                artworkWidth: 52,
                artworkHeight: 52,
                placeholderIconSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : 'Unknown Track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlayerColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  artist.isNotEmpty ? artist : 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlayerColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _NowPlayingIndicator(isPlaying: isPlaying),
        ],
      ),
    );
  }
}

class _NowPlayingIndicator extends StatefulWidget {
  const _NowPlayingIndicator({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_NowPlayingIndicator> createState() => _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends State<_NowPlayingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _barCount = 3;
  static const _durations = [480, 620, 530];
  static const _minHeights = [4.0, 6.0, 5.0];
  static const _maxHeights = [16.0, 22.0, 18.0];

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
  void didUpdateWidget(_NowPlayingIndicator oldWidget) {
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
          padding: EdgeInsets.only(right: i < _barCount - 1 ? 2.5 : 0),
          child: AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                width: 3.5,
                height: _animations[i].value,
                decoration: BoxDecoration(
                  color: PlayerColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
