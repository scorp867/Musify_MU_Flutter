import 'package:flutter/material.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';
import 'player_artwork.dart';

/// A sleek Spotify-authentic miniplayer featuring dynamic artwork palette extraction,
/// playback controls, swipe gestures, and a bottom progress bar.
class MiniPlayer extends StatefulWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final int? songId;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;
  final ColorExtractionService? colorService;

  const MiniPlayer({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    this.imageUrl,
    this.songId,
    this.isPlaying = false,
    this.progress = 0.35,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onTap,
    this.colorService,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final Color _currentColor = const Color(0xFF242424);
  bool _isFavorite = false;
  late bool _isPlaying;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
  }

  @override
  void didUpdateWidget(covariant MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _isPlaying = widget.isPlaying;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            PlayerScreen.show(context);
          }
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -250) {
            widget.onNext?.call();
          } else if (velocity > 250) {
            widget.onPrevious?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: PlayerArtworkImage(
                        songId: widget.songId,
                        imageUrl: widget.imageUrl,
                        artworkWidth: 40,
                        artworkHeight: 40,
                        placeholderIconSize: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.artist.isNotEmpty
                                ? widget.artist
                                : 'Unknown Artist',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontWeight: FontWeight.w400,
                              fontSize: 11,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isFavorite
                            ? Icons.check_circle_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite
                            ? const Color(0xFF1DB954)
                            : Colors.white.withValues(alpha: 0.75),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                        widget.onPlayPause?.call();
                      },
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: RepaintBoundary(
                  child: LinearProgressIndicator(
                    value: widget.progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
