import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';

import '../../application/queue/player_queue_bloc.dart';
import '../../data/queue/context_track_extensions.dart';
import '../../domain/models/context_track.dart';
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
  final PlayerQueueBloc? queueBloc;
  final ContextTrack? currentTrack;

  const MiniPlayer({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    this.imageUrl,
    this.songId,
    this.isPlaying = false,
    this.progress = 0.0,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onTap,
    this.colorService,
    this.queueBloc,
    this.currentTrack,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Color _currentColor = const Color(0xFF242424);
  bool _isFavorite = false;
  late bool _isPlaying;
  String? _lastExtractedKey;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    final initialSongId = widget.queueBloc?.state.songId ?? widget.currentTrack?.songId ?? widget.songId;
    final initialImageUrl = widget.queueBloc?.state.imageUrl ?? widget.currentTrack?.imageUrl ?? widget.imageUrl;
    _extractColor(songId: initialSongId, imageUrl: initialImageUrl);
  }

  @override
  void didUpdateWidget(covariant MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _isPlaying = widget.isPlaying;
    }
    if (oldWidget.songId != widget.songId || oldWidget.imageUrl != widget.imageUrl) {
      _extractColor(songId: widget.songId, imageUrl: widget.imageUrl);
    }
  }

  void _extractColor({int? songId, String? imageUrl}) {
    final key = songId != null ? 'song_$songId' : (imageUrl ?? '');
    if (key.isEmpty || key == _lastExtractedKey) return;
    _lastExtractedKey = key;

    final service = widget.colorService ??
        (getIt.isRegistered<ColorExtractionService>()
            ? getIt<ColorExtractionService>()
            : null);
    if (service == null) return;

    final cached = service.getCached(key);
    if (cached != null) {
      final targetColor = cached.isNeutral ? const Color(0xFF242424) : cached.surface;
      if (_currentColor != targetColor) {
        setState(() {
          _currentColor = targetColor;
        });
      }
      return;
    }

    service.extract(
      songId: songId,
      imageUrl: imageUrl,
      cacheKey: key,
    ).then((scheme) {
      if (mounted && _lastExtractedKey == key) {
        final targetColor = scheme.isNeutral ? const Color(0xFF242424) : scheme.surface;
        if (_currentColor != targetColor) {
          setState(() {
            _currentColor = targetColor;
          });
        }
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.queueBloc;
    if (bloc != null) {
      return BlocConsumer<PlayerQueueBloc, PlayerQueueState>(
        bloc: bloc,
        listenWhen: (previous, current) {
          return previous.songId != current.songId ||
              previous.imageUrl != current.imageUrl;
        },
        listener: (context, state) {
          _extractColor(songId: state.songId, imageUrl: state.imageUrl);
        },
        buildWhen: (previous, current) {
          return previous.nowPlaying != current.nowPlaying ||
              previous.isPlaying != current.isPlaying ||
              previous.isBuffering != current.isBuffering ||
              previous.playbackProgress != current.playbackProgress ||
              previous.songId != current.songId ||
              previous.imageUrl != current.imageUrl;
        },
        builder: (context, state) {
          return _buildMiniPlayerContent(context, state: state);
        },
      );
    }
    return _buildMiniPlayerContent(context);
  }

  Widget _buildMiniPlayerContent(BuildContext context, {PlayerQueueState? state}) {
    final displayTitle = (state?.title.isNotEmpty == true)
        ? state!.title
        : widget.title;
    final displayArtist = (state?.artist.isNotEmpty == true)
        ? state!.artist
        : widget.artist;
    final displayImageUrl = state?.imageUrl ?? widget.imageUrl;
    final displaySongId = state?.songId ?? widget.songId;
    final isPlaying = state?.isPlaying ?? _isPlaying;
    final progress = state != null ? state.playbackProgress : widget.progress;

    if (_lastExtractedKey == null && (displaySongId != null || displayImageUrl != null)) {
      _extractColor(songId: displaySongId, imageUrl: displayImageUrl);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            PlayerScreen.show(
              context,
              queueBloc: widget.queueBloc,
              currentTrack: state?.currentTrack ?? widget.currentTrack,
              title: displayTitle,
              artist: displayArtist,
              imageUrl: displayImageUrl,
              songId: displaySongId,
            );
          }
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -250) {
            if (widget.onNext != null) {
              widget.onNext!();
            } else {
              widget.queueBloc?.add(const SkipToNextTrack());
            }
          } else if (velocity > 250) {
            if (widget.onPrevious != null) {
              widget.onPrevious!();
            } else {
              widget.queueBloc?.add(const SkipToPrevTrack());
            }
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
                        songId: displaySongId,
                        imageUrl: displayImageUrl,
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
                            displayTitle,
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
                            displayArtist.isNotEmpty
                                ? displayArtist
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
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                        if (widget.onPlayPause != null) {
                          widget.onPlayPause!();
                        } else if (widget.queueBloc != null) {
                          widget.queueBloc!.add(const TogglePlayPause());
                        }
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
                    value: progress.clamp(0.0, 1.0),
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
