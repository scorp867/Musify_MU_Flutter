import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/color/artwork_color_scheme.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';
import 'player_artwork.dart';

/// A sleek Spotify-authentic miniplayer featuring dynamic artwork palette extraction,
/// clamped contrast, full playback controls, swipe-to-skip gestures, and a bottom progress bar.
class MiniPlayer extends StatefulWidget {
  final PlaybackController? controller;
  final ColorExtractionService? colorService;

  const MiniPlayer({
    super.key,
    this.controller,
    this.colorService,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  String? _lastTrackId;
  Color _currentColor = const Color(0xFF242424);
  bool _isFavorite = false;

  ColorExtractionService? _resolveColorService() {
    if (widget.colorService != null) return widget.colorService;
    try {
      return context.read<ColorExtractionService>();
    } catch (_) {
      return null;
    }
  }

  void _extractColorForTrack(MediaItem item) async {
    final service = _resolveColorService();
    if (service == null) return;

    final artUriString = item.artUri?.toString();
    final cached = service.getCached(item.id) ??
        (artUriString != null ? service.getCached(artUriString) : null);

    if (cached != null) {
      if (mounted && _currentColor != cached.primary) {
        setState(() => _currentColor = cached.primary);
      }
      return;
    }

    ArtworkColorScheme? scheme;

    // 1. Try online image URL extraction
    final artUri = item.artUri;
    if (artUri != null && (artUri.scheme == 'http' || artUri.scheme == 'https')) {
      try {
        scheme = await service.extract(
          imageUrl: artUri.toString(),
          cacheKey: item.id,
        );
      } catch (_) {}
    }

    // 2. Try local artwork extraction via configured local artwork provider
    if (scheme == null) {
      final songId = MediaItemMapper.songId(item);
      if (songId != null) {
        try {
          scheme = await service.extract(
            songId: songId,
            cacheKey: item.id,
          );
        } catch (_) {}
      }
    }

    final finalColor = scheme?.secondary ?? const Color(0xFF242424);

    if (mounted && _lastTrackId == item.id) {
      setState(() {
        _currentColor = finalColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = widget.controller;
    if (audioHandler == null) return const SizedBox.shrink();

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        if (_lastTrackId != mediaItem.id) {
          _lastTrackId = mediaItem.id;
          final service = _resolveColorService();
          final cached = service?.getCached(mediaItem.id) ??
              (mediaItem.artUri != null
                  ? service?.getCached(mediaItem.artUri.toString())
                  : null);
          _currentColor = cached?.primary ?? const Color(0xFF242424);
          _extractColorForTrack(mediaItem);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              PlayerScreen.show(context, audioHandler);
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -250) {
                audioHandler.skipToNext();
              } else if (velocity > 250) {
                audioHandler.skipToPrevious();
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
                            item: mediaItem,
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
                                mediaItem.title,
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
                                mediaItem.artist ?? 'Unknown Artist',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.devices_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 6),
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
                        StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, stateSnapshot) {
                            final playing =
                                stateSnapshot.data?.playing ?? false;
                            return IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                if (playing) {
                                  audioHandler.pause();
                                } else {
                                  audioHandler.play();
                                }
                              },
                            );
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
                      child: StreamBuilder<Duration>(
                        stream: AudioService.position,
                        builder: (context, positionSnapshot) {
                          final position =
                              positionSnapshot.data ?? Duration.zero;
                          final duration =
                              mediaItem.duration ?? Duration.zero;
                          final progress = duration.inMilliseconds > 0
                              ? (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                              : 0.0;
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 2,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
