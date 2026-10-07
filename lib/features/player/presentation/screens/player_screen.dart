import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';

import '../widgets/edge_to_edge_scrim.dart';
import '../widgets/peek_scroll_view.dart';
import '../widgets/player_artwork.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_header.dart';
import '../widgets/player_metadata.dart';
import '../widgets/player_sections.dart';
import '../widgets/player_sheets.dart';
import '../widgets/player_theme.dart';
import '../widgets/pull_to_dismiss_scaffold.dart';
import 'queue_sheet_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.playbackController,
  });

  final PlaybackController playbackController;

  static bool _isOpen = false;

  /// Launches the Now Playing view as a full-screen edge-to-edge window with
  /// native Spotify transition curves and single-top route guarding.
  static Future<void> show(
    BuildContext context,
    PlaybackController playbackController,
  ) async {
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
              playbackController: playbackController,
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
  PlaybackController get _playbackController => widget.playbackController;

  final GlobalKey<PeekScrollViewState> _peekScrollKey =
      GlobalKey<PeekScrollViewState>();
  final GlobalKey _lyricsKey = GlobalKey();

  Duration? _dragPosition;
  bool _isFavorite = false;
  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PullToDismissScaffold(
        builder: (context, dismissController) {
          return EdgeToEdgeScrim(
            child: StreamBuilder<MediaItem?>(
              stream: _playbackController.mediaItem,
              builder: (context, snapshot) {
                final item = snapshot.data;

                if (item == null) {
                  return PlayerEmptyState(
                    onClose: dismissController.dismiss,
                    onMore: () => _showMoreOptions(context),
                  );
                }

                return _buildPlayer(context, item, dismissController);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayer(
    BuildContext context,
    MediaItem item,
    PullToDismissController dismissController,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PlayerBackdrop(item: item),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xDD0A0A0A),
                Color(0xF20A0A0A),
                Color(0xFF0A0A0A),
              ],
              stops: [0, 0.42, 1],
            ),
          ),
        ),
        PeekScrollView(
          key: _peekScrollKey,
          dismissController: dismissController,
          peekHeight: 64.0,
          header: PlayerHeader(
            onClose: dismissController.dismiss,
            onMore: () => _showMoreOptions(context),
            contextTitle: 'PLAYING FROM ALBUM',
            contextSubtitle: item.album,
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
                  child: PlayerAlbumArtwork(item: item),
                ),
              ),
              const Spacer(flex: 1),
              PlayerMetadata(
                item: item,
                isFavorite: _isFavorite,
                onFavoriteChanged: _toggleFavorite,
              ),
              const SizedBox(height: 10),
              PlayerSeekBar(
                item: item,
                playbackController: _playbackController,
                dragPosition: _dragPosition,
                onDragPositionChanged: _setDragPosition,
              ),
              const SizedBox(height: 8),
              PlayerPlaybackControls(
                item: item,
                playbackController: _playbackController,
                shuffleEnabled: _shuffleEnabled,
                repeatEnabled: _repeatEnabled,
                onShuffle: _toggleShuffle,
                onRepeat: _toggleRepeat,
              ),
              const SizedBox(height: 6),
              PlayerUtilityRow(
                onQueue: () => _showQueue(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
          peekingCard: PlayerLyricsSection(
            key: _lyricsKey,
            onTapHeader: _onExpandLyrics,
          ),
          expandedCards: [
            PlayerTrackDetailsSection(item: item),
          ],
        ),
      ],
    );
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

  void _toggleShuffle() {
    setState(() {
      _shuffleEnabled = !_shuffleEnabled;
    });

    _playbackController.setShuffleMode(
      _shuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
  }

  void _toggleRepeat() {
    setState(() {
      _repeatEnabled = !_repeatEnabled;
    });

    _playbackController.setRepeatMode(
      _repeatEnabled ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none,
    );
  }

  void _showQueue(BuildContext context) {
    QueueSheetScreen.show(context, _playbackController);
  }

  void _showMoreOptions(BuildContext context) {
    final item = _playbackController.currentMediaItem;

    if (item == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return PlayerOptionsSheet(
          onShowDetails: () => _showTrackDetails(context, item),
          onShowQueue: () => _showQueue(context),
        );
      },
    );
  }

  void _showTrackDetails(BuildContext context, MediaItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PlayerTrackDetailsSheet(item: item),
    );
  }
}
