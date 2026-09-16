import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/player/application/queue/queue_bloc.dart';
import 'package:musify_mu/features/player/application/queue/queue_event.dart';
import 'package:musify_mu/features/player/application/queue/queue_state.dart';

import '../widgets/player_theme.dart';
import '../widgets/queue_now_playing_card.dart';
import '../widgets/queue_track_tile.dart';

class QueueSheetScreen {
  QueueSheetScreen._();

  static void show(BuildContext context, PlaybackController playbackController) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      enableDrag: false,
      builder: (_) {
        return BlocProvider(
          create: (_) => QueueBloc(playbackController: playbackController)
              ..add(const QueueStarted()),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.6, 0.92],
            snapAnimationDuration: const Duration(milliseconds: 250),
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: PlayerColors.background,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _QueueContent(
                  playbackController: playbackController,
                  scrollController: scrollController,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Content — uses BlocListener + local state for flicker-free reorder
// ---------------------------------------------------------------------------

class _QueueContent extends StatefulWidget {
  const _QueueContent({
    required this.playbackController,
    required this.scrollController,
  });

  final PlaybackController playbackController;
  final ScrollController scrollController;

  @override
  State<_QueueContent> createState() => _QueueContentState();
}

class _QueueContentState extends State<_QueueContent> {
  List<MediaItem> _upcoming = const [];
  QueueState _state = const QueueState();

  @override
  Widget build(BuildContext context) {
    return BlocListener<QueueBloc, QueueState>(
      listener: (context, state) {
        setState(() {
          _state = state;
          _upcoming = List.of(state.upcomingTracks);
        });
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (!_state.hasQueue) {
      return _buildEmpty(context);
    }

    return Column(
      children: [
        // Drag handle
        _buildDragHandle(),

        // Header
        _buildHeader(context),

        // Now Playing card with crossfade
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            );
          },
          child: _state.nowPlaying != null
              ? QueueNowPlayingCard(
                  key: ValueKey(_state.nowPlaying!.id),
                  item: _state.nowPlaying!,
                  playbackController: widget.playbackController,
                )
              : const SizedBox.shrink(),
        ),

        // "Next up" section
        if (_upcoming.isNotEmpty) _buildSectionHeader(),

        // Upcoming tracks — reorderable
        if (_upcoming.isNotEmpty) Expanded(child: _buildUpcomingList(context)),

        if (_upcoming.isEmpty) const Expanded(child: _EmptyUpcoming()),
      ],
    );
  }

  Widget _buildUpcomingList(BuildContext context) {
    return ReorderableListView.builder(
      scrollController: widget.scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final elevation = _lerpDouble(0, 6, animation.value);
            return Material(
              color: PlayerColors.surfaceHigh,
              elevation: elevation,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
        );
      },
      onReorderItem: (oldIndex, newIndex) {
        // Optimistic local update — prevents flicker.
        setState(() {
          final item = _upcoming.removeAt(oldIndex);
          _upcoming.insert(newIndex, item);
        });

        final absOld = _state.currentIndex + 1 + oldIndex;
        final absNew = _state.currentIndex + 1 + newIndex;
        context.read<QueueBloc>().add(QueueReordered(absOld, absNew));
      },
      itemCount: _upcoming.length,
      itemBuilder: (context, index) {
        final track = _upcoming[index];
        final absoluteIndex = _state.currentIndex + 1 + index;

        return QueueTrackTile(
          key: ValueKey(track.id),
          item: track,
          index: index + 1,
          onTap: () {
            context.read<QueueBloc>().add(QueueTrackTapped(absoluteIndex));
          },
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 2),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: PlayerColors.muted,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
      child: Row(
        children: [
          const Icon(
            Icons.queue_music_rounded,
            color: PlayerColors.accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Queue',
              style: TextStyle(
                color: PlayerColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close_rounded,
              color: PlayerColors.textSecondary,
              size: 22,
            ),
            splashRadius: 20,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          const Text(
            'Next up',
            style: TextStyle(
              color: PlayerColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '· ${_upcoming.length}',
            style: const TextStyle(
              color: PlayerColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        _buildHeader(context),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.queue_music_rounded,
                  color: PlayerColors.muted, size: 44),
              SizedBox(height: 14),
              Text(
                'Queue is empty',
                style: TextStyle(
                  color: PlayerColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Play a song to get started.',
                style: TextStyle(
                  color: PlayerColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No more tracks in queue.',
        style: TextStyle(
          color: PlayerColors.muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
