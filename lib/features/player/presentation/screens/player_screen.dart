import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';

import '../widgets/player_artwork.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_header.dart';
import '../widgets/player_metadata.dart';
import '../widgets/player_sections.dart';
import '../widgets/player_sheets.dart';
import '../widgets/player_theme.dart';
import 'queue_sheet_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    this.scrollController,
    required this.playbackController,
  });

  final ScrollController? scrollController;
  final PlaybackController playbackController;

  static void show(
    BuildContext context,
    PlaybackController playbackController,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      enableDrag: false,
      useSafeArea: false,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 1,
          minChildSize: 0.50,
          maxChildSize: 1,
          expand: false,
          snap: true,
          snapSizes: const [0.50, 1.0],
          snapAnimationDuration: const Duration(milliseconds: 250),
          builder: (_, controller) {
            return PlayerScreen(
              scrollController: controller,
              playbackController: playbackController,
            );
          },
        );
      },
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  PlaybackController get _playbackController => widget.playbackController;

  final GlobalKey _lyricsKey = GlobalKey();

  Duration? _dragPosition;
  bool _isFavorite = false;
  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: _playbackController.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;

        if (item == null) {
          return PlayerEmptyState(
            onClose: () => Navigator.pop(context),
            onMore: () => _showMoreOptions(context),
          );
        }

        return _buildPlayer(context, item);
      },
    );
  }

  Widget _buildPlayer(BuildContext context, MediaItem item) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Stack(
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
          SafeArea(
            child: CustomScrollView(
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: PlayerHeader(
                    onClose: () => Navigator.pop(context),
                    onMore: () => _showMoreOptions(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 42),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PlayerAlbumArtwork(item: item),
                      const SizedBox(height: 28),
                      PlayerMetadata(
                        item: item,
                        isFavorite: _isFavorite,
                        onFavoriteChanged: _toggleFavorite,
                      ),
                      const SizedBox(height: 26),
                      PlayerSeekBar(
                        item: item,
                        playbackController: _playbackController,
                        dragPosition: _dragPosition,
                        onDragPositionChanged: _setDragPosition,
                      ),
                      const SizedBox(height: 20),
                      PlayerPlaybackControls(
                        item: item,
                        playbackController: _playbackController,
                      ),
                      const SizedBox(height: 20),
                      PlayerSecondaryControls(
                        shuffleEnabled: _shuffleEnabled,
                        repeatEnabled: _repeatEnabled,
                        onShuffle: _toggleShuffle,
                        onRepeat: _toggleRepeat,
                        onQueue: () => _showQueue(context),
                        onLyrics: _scrollToLyrics,
                      ),
                      const SizedBox(height: 34),
                      PlayerLyricsSection(key: _lyricsKey),
                      const SizedBox(height: 18),
                      PlayerTrackDetailsSection(item: item),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  void _scrollToLyrics() {
    final lyricsContext = _lyricsKey.currentContext;

    if (lyricsContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      lyricsContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
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
