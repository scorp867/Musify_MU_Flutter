import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              queueBloc: queueBloc,
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

  Duration? _dragPosition;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isFavorite = false;
  QueueShuffleMode _shuffleMode = QueueShuffleMode.none;
  QueueRepeatMode _repeatMode = QueueRepeatMode.none;

  static const Color _topGradientColor = Color(0xFF1E3264);

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

  @override
  Widget build(BuildContext context) {
    if (widget.queueBloc != null) {
      return BlocBuilder<PlayerQueueBloc, PlayerQueueState>(
        bloc: widget.queueBloc,
        builder: (context, queueState) {
          return _buildContent(context, queueState: queueState);
        },
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context, {PlayerQueueState? queueState}) {
    final topInset = MediaQuery.paddingOf(context).top;

    final activeTrack = queueState?.currentTrack ?? widget.currentTrack;
    final displayTitle = (activeTrack?.title.isNotEmpty == true)
        ? activeTrack!.title
        : widget.title;
    final displayArtist = (activeTrack?.artist.isNotEmpty == true)
        ? activeTrack!.artist
        : widget.artist;
    final displayAlbum = (activeTrack?.album.isNotEmpty == true)
        ? activeTrack!.album
        : widget.album;
    final displayDuration = activeTrack?.duration ?? widget.duration;
    final displayImageUrl = activeTrack?.imageUrl ?? widget.imageUrl;

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
          return Container(
            margin: EdgeInsets.only(top: topInset),
            child: PeekScrollView(
              key: _peekScrollKey,
              dismissController: dismissController,
              peekHeight: 64.0,
              tier1Decoration: BoxDecoration(
                gradient: EasedGradient.build(
                  topColor: _topGradientColor,
                  bottomColor: const Color(0xFF121212),
                ),
              ),
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 380,
                        maxHeight: 380,
                      ),
                      child: PlayerAlbumArtwork(
                        imageUrl: displayImageUrl,
                        songId: widget.songId,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  PlayerMetadata(
                    title: displayTitle,
                    artist: displayArtist,
                    isFavorite: _isFavorite,
                    onFavoriteChanged: _toggleFavorite,
                  ),
                  const SizedBox(height: 10),
                  PlayerSeekBar(
                    duration: displayDuration,
                    position: _currentPosition,
                    dragPosition: _dragPosition,
                    onDragPositionChanged: _setDragPosition,
                    onSeek: (pos) => setState(() => _currentPosition = pos),
                  ),
                  const SizedBox(height: 8),
                  PlayerPlaybackControls(
                    isPlaying: isPlaying,
                    shuffleMode: shuffleMode,
                    repeatMode: repeatMode,
                    onPlayPause: _handlePlayPause,
                    onShuffle: _handleShuffle,
                    onRepeat: _handleRepeat,
                    onNext: _handleNext,
                    onPrevious: _handlePrevious,
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
            ),
          );
        },
      ),
    );
  }

  void _handlePlayPause() {
    if (widget.queueBloc != null) {
      widget.queueBloc!.add(const PlayerQueueTogglePlayPause());
    } else {
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  void _handleShuffle() {
    if (widget.queueBloc != null) {
      widget.queueBloc!.add(const PlayerQueueToggleShuffle());
    } else {
      setState(() {
        _shuffleMode = _shuffleMode == QueueShuffleMode.all
            ? QueueShuffleMode.none
            : QueueShuffleMode.all;
      });
    }
  }

  void _handleRepeat() {
    if (widget.queueBloc != null) {
      widget.queueBloc!.add(const PlayerQueueCycleRepeat());
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
    widget.queueBloc?.add(const PlayerQueueSkipNext());
  }

  void _handlePrevious() {
    widget.queueBloc?.add(const PlayerQueueSkipPrevious());
  }

  void _onExpandLyrics() {
    _peekScrollKey.currentState?.scrollToExpanded();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _setDragPosition(Duration? position) {
    setState(() {
      _dragPosition = position;
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
      bloc: widget.queueBloc,
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
    bool? isPlayingVal,
    QueueShuffleMode? shuffleVal,
    QueueRepeatMode? repeatVal,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return PlayerOptionsSheet(
          onShowDetails: () => _showTrackDetails(
            context,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
          ),
          onShowQueue: () => _showQueue(
            context,
            activeTrack: activeTrack,
            isPlayingVal: isPlayingVal,
            shuffleVal: shuffleVal,
            repeatVal: repeatVal,
          ),
        );
      },
    );
  }

  void _showTrackDetails(
    BuildContext context, {
    required String title,
    required String artist,
    required String album,
    required Duration duration,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PlayerTrackDetailsSheet(
        title: title,
        artist: artist,
        album: album,
        duration: duration,
      ),
    );
  }
}
