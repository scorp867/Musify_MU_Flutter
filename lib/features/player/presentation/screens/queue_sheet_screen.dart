import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/application/queue/queue_bloc.dart';
import 'package:musify_mu/features/player/application/queue/queue_event.dart';
import 'package:musify_mu/features/player/application/queue/queue_state.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

import '../widgets/peek_scroll_view.dart';
import '../widgets/player_theme.dart';
import '../widgets/pull_to_dismiss_scaffold.dart';
import '../widgets/queue_controls_layout.dart';
import '../widgets/queue_now_playing_row.dart';
import '../widgets/queue_track_row.dart';
import '../widgets/spotify_scroll_physics.dart';

/// 1:1 Replica of Spotify Android Queue Sheet
///
/// Architecture matches layout_queue_sheet_content.xml & Spotify screenshots:
///   CoordinatorLayout
///     LinearLayout (queue_sheet, core_bottom_sheet_background, top=statusBarInset)
///       Sticky Top Header (Grapple + Queue Header + Sticky Now Playing Row)
///       FrameLayout
///         RecyclerView (upcoming tracks, itemExtent=64dp, no section headers)
///     QueueControlsLayout (layout_gravity=bottom|center_horizontal)
class QueueSheetScreen extends StatelessWidget {
  const QueueSheetScreen({super.key});

  static void show(
    BuildContext context,
    PlaybackController playbackController,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (modalContext, _, _) {
          return BlocProvider(
            create: (_) => QueueBloc(playbackController: playbackController)
              ..add(const QueueStarted()),
            child: const QueueSheetScreen(),
          );
        },
        transitionsBuilder: (context, animation, _, child) {
          const curve = Cubic(0.3, 0.0, 0.0, 1.0);
          final curved = CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: curve,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PullToDismissScaffold(
      barrierBaseAlpha: 0.72,
      builder: (context, dismissController) {
        return _QueueSheetBody(dismissController: dismissController);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet Body
// ---------------------------------------------------------------------------

class _QueueSheetBody extends StatefulWidget {
  const _QueueSheetBody({required this.dismissController});

  final PullToDismissController dismissController;

  @override
  State<_QueueSheetBody> createState() => _QueueSheetBodyState();
}

class _QueueSheetBodyState extends State<_QueueSheetBody>
    with TickerProviderStateMixin {
  late final SpotifyStretchController _stretchController;
  late final SpotifyPeekScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _stretchController = SpotifyStretchController(vsync: this);
    _scrollController = SpotifyPeekScrollController(
      dismissController: widget.dismissController,
      stretchController: _stretchController,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stretchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extends right up to the system status bar inset with no extra gap
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      margin: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: PlayerColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<QueueBloc, QueueState>(
        builder: (context, state) {
          final currentTrack = state.nowPlaying;

          return Stack(
            children: [
              Column(
                children: [
                  // Sticky Top Area: Grapple + Queue Header + Sticky First Song
                  // Coordinated with PullToDismissController just like PlayerScreen
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (details) {
                      final delta = details.primaryDelta ?? 0;
                      if (delta > 0 ||
                          widget.dismissController.dragOffsetY > 0) {
                        widget.dismissController.onPullDelta(delta);
                      }
                    },
                    onVerticalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      widget.dismissController.onPullEnd(velocity);
                    },
                    child: Container(
                      color: PlayerColors.background,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _Grapple(),
                          _QueueHeader(state: state),
                          if (currentTrack != null)
                            QueueNowPlayingRow(
                              track: currentTrack,
                              isPlaying: state.isPlaying,
                              onTap: widget.dismissController.dismiss,
                              onPlayPause: () {
                                context
                                    .read<QueueBloc>()
                                    .add(const QueuePlayPauseToggled());
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Scrollable upcoming tracks list (scrolls cleanly under sticky first song)
                  Expanded(
                    child: _buildList(context, state),
                  ),
                ],
              ),

              // Bottom controls overlay (CoordinatorLayout layout_gravity=bottom)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: QueueControlsLayout(
                  shuffleMode: state.shuffleMode,
                  repeatMode: state.repeatMode,
                  onShuffleTapped: () {
                    context.read<QueueBloc>().add(const QueueShuffleToggled());
                  },
                  onRepeatTapped: () {
                    context.read<QueueBloc>().add(const QueueRepeatToggled());
                  },
                  onTimerTapped: () {
                    // Timer handled externally
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, QueueState state) {
    if (!state.hasQueue && !state.hasUpcoming) {
      return _buildPlaceholder();
    }

    final nextTracks = state.nextTracks;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 104;

    return SpotifyStretchOverscrollIndicator(
      controller: _stretchController,
      axisDirection: AxisDirection.down,
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        physics: const ClampingScrollPhysics(),
        buildDefaultDragHandles: false,
        itemExtent: 64.0,
        padding: EdgeInsets.only(bottom: bottomPad),
        proxyDecorator: _proxyDecorator,
        itemCount: nextTracks.length,
        onReorderItem: (oldIndex, newIndex) {
          context.read<QueueBloc>().add(QueueReordered(oldIndex, newIndex));
        },
        itemBuilder: (context, index) {
          final track = nextTracks[index];
          final absoluteIndex = state.currentIndex + 1 + index;

          return QueueTrackRow(
            key: ValueKey('track_${track.uid}'),
            track: track,
            index: index,
            onTap: () {
              context.read<QueueBloc>().add(
                    QueueTrackTapped(
                      track: track,
                      absoluteIndex: absoluteIndex,
                    ),
                  );
            },
            onRemove: () {
              context.read<QueueBloc>().add(QueueTrackRemoved(track.uid));
            },
            onAddToQueue: () {
              context.read<QueueBloc>().add(QueueTrackAdded(track));
            },
          );
        },
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, proxyChild) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final scale = lerpDouble(1.0, 1.02, t) ?? 1.0;
        final elevation = lerpDouble(0.0, 10.0, t) ?? 0.0;
        final bgColor = Color.lerp(
          PlayerColors.background,
          const Color(0xFF262626),
          t,
        )!;

        return Transform.scale(
          scale: scale,
          child: Material(
            color: bgColor,
            elevation: elevation,
            shadowColor: Colors.black87,
            child: proxyChild,
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpotifyIcon.addToQueue(size: 48, color: PlayerColors.muted),
            const SizedBox(height: 16),
            const Text(
              'Queue is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add tracks from playlists or albums to keep the music playing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlayerColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grapple - matches core_bottom_sheet_grapple.xml: 36x4dp, 4dp radius, white 30%
// ---------------------------------------------------------------------------

class _Grapple extends StatelessWidget {
  const _Grapple();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Queue Header - matches Spotify's queue_header_container from screenshots
//
// Left column:
//   "Queue" (20px bold white)
//   "Playing [context name]" ("Playing " in #B3B3B3 + context name in bold white)
// Right row:
//   [Clear] (animated pill, visible when state.hasUserQueue) + [Edit] pill
// ---------------------------------------------------------------------------

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.state});

  final QueueState state;

  @override
  Widget build(BuildContext context) {
    final currentTrack = state.nowPlaying;
    final contextTitle = _getPlayingContext(currentTrack);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 2, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Queue title + Playing context subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Queue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (contextTitle != null) ...[
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Playing ',
                          style: TextStyle(
                            color: PlayerColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: contextTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Right: Clear (animated) + Edit pill buttons
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: state.hasUserQueue
                  ? Padding(
                      key: const ValueKey('clear_btn'),
                      padding: const EdgeInsets.only(right: 8),
                      child: _HeaderPillButton(
                        label: 'Clear',
                        onTap: () {
                          context.read<QueueBloc>().add(const QueueCleared());
                        },
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no_clear_btn')),
            ),
          ),
          _HeaderPillButton(
            label: 'Edit',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  String? _getPlayingContext(ContextTrack? track) {
    if (track == null) return null;
    final ctxTitle = track.metadata['context_title'];
    if (ctxTitle != null && ctxTitle.isNotEmpty) return ctxTitle;
    if (track.album.isNotEmpty && track.album != 'Unknown Album') {
      return track.album;
    }
    if (track.artist.isNotEmpty) return track.artist;
    return null;
  }
}

class _HeaderPillButton extends StatefulWidget {
  const _HeaderPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HeaderPillButton> createState() => _HeaderPillButtonState();
}

class _HeaderPillButtonState extends State<_HeaderPillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
