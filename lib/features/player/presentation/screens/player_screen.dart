import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/color/eased_gradient.dart';

import '../../application/queue/player_queue_bloc.dart';
import '../../data/queue/context_track_extensions.dart';
import '../../domain/models/context_track.dart';
import '../widgets/peek_scroll_view.dart';
import '../widgets/player_artwork.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_header.dart';
import '../widgets/player_metadata.dart';
import '../widgets/player_sections.dart';
import '../widgets/player_sheets.dart';
import '../widgets/player_theme.dart';
import '../widgets/pull_to_dismiss_scaffold.dart';
import '../widgets/queue_controls_layout.dart';
import 'queue_sheet_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? imageUrl;
  final int? songId;
  final PlayerQueueBloc? queueBloc;
  final ContextTrack? currentTrack;

  const PlayerScreen({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    this.album = 'Starboy',
    this.duration = const Duration(minutes: 3, seconds: 50),
    this.imageUrl,
    this.songId,
    this.queueBloc,
    this.currentTrack,
  });

  static bool _isOpen = false;

  /// Launches the Now Playing view as a full-screen edge-to-edge window with
  /// native Spotify transition curves and single-top route guarding.
  static Future<void> show(
    BuildContext context, {
    String title = 'Starboy',
    String artist = 'The Weeknd, Daft Punk',
    String album = 'Starboy',
    Duration duration = const Duration(minutes: 3, seconds: 50),
    String? imageUrl,
    int? songId,
    PlayerQueueBloc? queueBloc,
    ContextTrack? currentTrack,
  }) async {
    if (_isOpen) return;
    _isOpen = true;

    final effectiveBloc = queueBloc ??
        (getIt.isRegistered<PlayerQueueBloc>() ? getIt<PlayerQueueBloc>() : null);

    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.70),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) {
            return PlayerScreen(
              title: title,
              artist: artist,
              album: album,
              duration: duration,
              imageUrl: imageUrl,
              songId: songId,
              queueBloc: effectiveBloc,
              currentTrack: currentTrack,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Cubic(0.3, 0.0, 0.0, 1.0);
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: curve,
                reverseCurve: curve,
              ),
            );
            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
        ),
      );
    } finally {
      _isOpen = false;
    }
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final GlobalKey<PeekScrollViewState> _peekScrollKey =
      GlobalKey<PeekScrollViewState>();
  final GlobalKey _lyricsKey = GlobalKey();

  final ValueNotifier<Duration?> _dragNotifier = ValueNotifier<Duration?>(null);
  late final ValueNotifier<Duration> _positionNotifier;

  bool _isPlaying = false;
  bool _isFavorite = false;
  QueueShuffleMode _shuffleMode = QueueShuffleMode.none;
  QueueRepeatMode _repeatMode = QueueRepeatMode.none;

  Timer? _positionTimer;

  static const Color _topGradientColor = Color(0xFF1E3264);

  // Memoized 16-step eased gradient decoration to achieve 120 FPS without per-frame rebuild overhead
  static final Decoration _tier1Decoration = BoxDecoration(
    gradient: EasedGradient.build(
      topColor: _topGradientColor,
      bottomColor: const Color(0xFF121212),
    ),
  );

  static const List<String> _mockLyrics = [
    'I\'m tryna put you in the worst mood, ah',
    'P1 cleaner than your church shoes, ah',
    'Milli point two just to hurt you, ah',
    'All red Lamb\' just to tease you, ah',
    'None of these toys on lease too, ah',
    'Made your whole year in a week too, yah',
    'Main bitch out your league too, ah',
    'Side bitch out of your league too, ah',
  ];

  PlayerQueueBloc? get _effectiveBloc =>
      widget.queueBloc ??
      (getIt.isRegistered<PlayerQueueBloc>() ? getIt<PlayerQueueBloc>() : null);

  @override
  void initState() {
    super.initState();
    _positionNotifier = ValueNotifier<Duration>(Duration.zero);

    final bloc = _effectiveBloc;
    if (bloc != null) {
      _isPlaying = bloc.state.isPlaying;
      _positionNotifier.value = bloc.state.currentPosition;
    }
    _updatePositionTicker(_isPlaying);
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _positionTimer = null;
    _positionNotifier.dispose();
    _dragNotifier.dispose();
    super.dispose();
  }

  void _updatePositionTicker(bool isPlaying) {
    if (isPlaying) {
      if (_positionTimer == null || !_positionTimer!.isActive) {
        _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
          if (_dragNotifier.value == null && mounted) {
            final bloc = _effectiveBloc;
            if (bloc != null) {
              _positionNotifier.value = bloc.state.currentPosition;
            }
          }
        });
      }
    } else {
      _positionTimer?.cancel();
      _positionTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _effectiveBloc;
    if (bloc != null) {
      return BlocConsumer<PlayerQueueBloc, PlayerQueueState>(
        bloc: bloc,
        listenWhen: (previous, current) {
          return previous.isPlaying != current.isPlaying;
        },
        listener: (context, state) {
          _updatePositionTicker(state.isPlaying);
          if (_dragNotifier.value == null) {
            _positionNotifier.value = state.currentPosition;
          }
        },
        buildWhen: (previous, current) {
          return previous.nowPlaying != current.nowPlaying ||
              previous.songId != current.songId ||
              previous.imageUrl != current.imageUrl ||
              previous.isPlaying != current.isPlaying ||
              previous.isBuffering != current.isBuffering ||
              previous.isShuffling != current.isShuffling ||
              previous.repeatMode != current.repeatMode ||
              previous.durationMs != current.durationMs;
        },
        builder: (context, queueState) {
          return _buildContent(context, queueState: queueState);
        },
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context, {PlayerQueueState? queueState}) {
    final activeTrack = queueState?.currentTrack ?? widget.currentTrack;
    final displayTitle = (activeTrack?.title.isNotEmpty == true)
        ? activeTrack!.title
        : (queueState?.title.isNotEmpty == true ? queueState!.title : widget.title);
    final displayArtist = (activeTrack?.artist.isNotEmpty == true)
        ? activeTrack!.artist
        : (queueState?.artist.isNotEmpty == true ? queueState!.artist : widget.artist);
    final displayAlbum = (activeTrack?.album.isNotEmpty == true)
        ? activeTrack!.album
        : (queueState?.album.isNotEmpty == true ? queueState!.album : widget.album);
    final displayDuration = (queueState != null && queueState.durationMs > 0)
        ? queueState.currentDuration
        : (activeTrack?.duration ?? widget.duration);
    final displayImageUrl = (activeTrack != null || queueState != null)
        ? (activeTrack?.imageUrl ?? queueState?.imageUrl)
        : widget.imageUrl;
    final displaySongId = (activeTrack != null || queueState != null)
        ? (activeTrack?.songId ?? queueState?.songId)
        : widget.songId;

    final isPlaying = queueState?.isPlaying ?? _isPlaying;
    final shuffleMode = queueState != null
        ? (queueState.isShuffling ? QueueShuffleMode.all : QueueShuffleMode.none)
        : _shuffleMode;
    final repeatMode = queueState != null
        ? (queueState.repeatTrack
            ? QueueRepeatMode.one
            : (queueState.repeatContext ? QueueRepeatMode.all : QueueRepeatMode.none))
        : _repeatMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PullToDismissScaffold(
        barrierBaseAlpha: 0.70,
        builder: (context, dismissController) {
          return PeekScrollView(
            key: _peekScrollKey,
            dismissController: dismissController,
            peekHeight: 64.0,
            tier1Decoration: _tier1Decoration,
            header: PlayerHeader(
              onClose: dismissController.dismiss,
              onMore: () => _showMoreOptions(
                context,
                title: displayTitle,
                artist: displayArtist,
                album: displayAlbum,
                duration: displayDuration,
                activeTrack: activeTrack,
                isPlayingVal: isPlaying,
                shuffleVal: shuffleMode,
                repeatVal: repeatMode,
              ),
              contextTitle: 'PLAYING FROM ALBUM',
              contextSubtitle: displayAlbum,
            ),
            mainContent: Column(
              children: [
                const Spacer(flex: 1),
                Flexible(
                  flex: 16,
                  child: RepaintBoundary(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 380,
                        maxHeight: 380,
                      ),
                      child: PlayerAlbumArtwork(
                        key: ValueKey('artwork_${activeTrack?.uid ?? activeTrack?.uri ?? displaySongId ?? displayImageUrl}'),
                        imageUrl: displayImageUrl,
                        songId: displaySongId,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                RepaintBoundary(
                  child: PlayerMetadata(
                    title: displayTitle,
                    artist: displayArtist,
                    isFavorite: _isFavorite,
                    onFavoriteChanged: _toggleFavorite,
                  ),
                ),
                const SizedBox(height: 10),
                RepaintBoundary(
                  child: ValueListenableBuilder<Duration?>(
                    valueListenable: _dragNotifier,
                    builder: (context, dragPos, _) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: _positionNotifier,
                        builder: (context, pos, _) {
                          return PlayerSeekBar(
                            duration: displayDuration,
                            position: dragPos ?? pos,
                            dragPosition: dragPos,
                            onDragPositionChanged: (newDragPos) {
                              _dragNotifier.value = newDragPos;
                              if (newDragPos != null) {
                                _positionNotifier.value = newDragPos;
                              }
                            },
                            onSeek: _handleSeek,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                RepaintBoundary(
                  child: PlayerPlaybackControls(
                    isPlaying: isPlaying,
                    isBuffering: queueState?.isBuffering ?? false,
                    shuffleMode: shuffleMode,
                    repeatMode: repeatMode,
                    onPlayPause: _handlePlayPause,
                    onShuffle: _handleShuffle,
                    onRepeat: _handleRepeat,
                    onNext: _handleNext,
                    onPrevious: _handlePrevious,
                  ),
                ),
                const SizedBox(height: 6),
                PlayerUtilityRow(
                  onQueue: () => _showQueue(
                    context,
                    activeTrack: activeTrack,
                    isPlayingVal: isPlaying,
                    shuffleVal: shuffleMode,
                    repeatVal: repeatMode,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            peekingCard: PlayerLyricsSection(
              key: _lyricsKey,
              lyricsLines: _mockLyrics,
              activeLineIndex: 1,
              backgroundColor: const Color(0xFF1E3264),
              onTapHeader: _onExpandLyrics,
            ),
            expandedCards: [
              PlayerAboutArtistSection(
                artistName: displayArtist,
              ),
              PlayerCreditsSection(
                artistName: displayArtist,
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSeek(Duration pos) {
    _dragNotifier.value = null;
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(SeekToTrackPosition(pos.inMilliseconds));
    } else {
      _positionNotifier.value = pos;
    }
  }

  void _handlePlayPause() {
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(const PlayerQueueTogglePlayPause());
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
        _updatePositionTicker(_isPlaying);
      });
    }
  }

  void _handleShuffle() {
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(const PlayerQueueToggleShuffle());
    } else {
      setState(() {
        _shuffleMode = _shuffleMode == QueueShuffleMode.all
            ? QueueShuffleMode.none
            : QueueShuffleMode.all;
      });
    }
  }

  void _handleRepeat() {
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(const PlayerQueueCycleRepeat());
    } else {
      setState(() {
        if (_repeatMode == QueueRepeatMode.none) {
          _repeatMode = QueueRepeatMode.all;
        } else if (_repeatMode == QueueRepeatMode.all) {
          _repeatMode = QueueRepeatMode.one;
        } else {
          _repeatMode = QueueRepeatMode.none;
        }
      });
    }
  }

  void _handleNext() {
    _effectiveBloc?.add(const PlayerQueueSkipNext());
  }

  void _handlePrevious() {
    _effectiveBloc?.add(const PlayerQueueSkipPrevious());
  }

  void _onExpandLyrics() {
    _peekScrollKey.currentState?.scrollToExpanded();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _showQueue(
    BuildContext context, {
    ContextTrack? activeTrack,
    bool? isPlayingVal,
    QueueShuffleMode? shuffleVal,
    QueueRepeatMode? repeatVal,
  }) {
    QueueSheetScreen.show(
      context,
      bloc: _effectiveBloc,
      nowPlayingContextTrack: activeTrack ?? widget.currentTrack,
      isPlaying: isPlayingVal ?? _isPlaying,
      shuffleMode: shuffleVal ?? _shuffleMode,
      repeatMode: repeatVal ?? _repeatMode,
      onPlayPause: _handlePlayPause,
      onShuffleTapped: _handleShuffle,
      onRepeatTapped: _handleRepeat,
    );
  }

  void _showMoreOptions(
    BuildContext context, {
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    ContextTrack? activeTrack,
    bool isPlayingVal = false,
    QueueShuffleMode shuffleVal = QueueShuffleMode.none,
    QueueRepeatMode repeatVal = QueueRepeatMode.none,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return PlayerOptionsSheet(
          onShowDetails: () {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: PlayerColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (detailsContext) {
                return PlayerTrackDetailsSheet(
                  title: title,
                  artist: artist,
                  album: album,
                  duration: duration,
                );
              },
            );
          },
          onShowQueue: () {
            _showQueue(
              context,
              activeTrack: activeTrack,
              isPlayingVal: isPlayingVal,
              shuffleVal: shuffleVal,
              repeatVal: repeatVal,
            );
          },
        );
      },
    );
  }
}
