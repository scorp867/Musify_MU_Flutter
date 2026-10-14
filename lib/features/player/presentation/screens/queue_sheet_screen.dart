import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/application/queue/queue_bloc.dart';
import 'package:musify_mu/features/player/application/queue/queue_event.dart';
import 'package:musify_mu/features/player/application/queue/queue_state.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/queue/queue_filter_helper.dart';

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

  /// Indicates whether the Queue Sheet is currently open on top of [PlayerScreen].
  /// Used by [PlayerScreen] to defer heavy background rebuilds, 720x720 artwork
  /// texture decodes, and palette extraction while queue animations are running.
  static final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  static void show(
    BuildContext context,
    PlaybackController playbackController,
  ) {
    isOpenNotifier.value = true;
    Navigator.of(context, rootNavigator: true)
        .push(
          PageRouteBuilder<void>(
            opaque: false,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            transitionDuration: const Duration(milliseconds: 420),
            reverseTransitionDuration: const Duration(milliseconds: 380),
            pageBuilder: (modalContext, _, _) {
              return BlocProvider<QueueBloc>.value(
                value: getIt<QueueBloc>(),
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
        )
        .whenComplete(() {
          isOpenNotifier.value = false;
        });
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

  final Set<String> _animatedInsertUids = <String>{};
  final Set<String> _slideDownUids = <String>{};
  final Set<String> _clearingUids = <String>{};
  List<ContextTrack>? _tapTransitionTracks;
  String? _tappedTrackUid;
  int _tapAnimationGeneration = 0;
  bool _isClearingQueue = false;

  // Matches p/y7o.java + p/z6y0.java DefaultItemAnimator:
  // 120ms (add/remove fade) + 250ms (move translation) = 370ms total (+5ms buffer)
  static const Duration _itemAnimatorTotalWait = Duration(milliseconds: 375);

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

  void _handleTrackAddedAnimation(QueueState state, String addedUid) {
    final userQueue = state.queue.userQueue;
    final index = userQueue.indexWhere((t) => t.uid == addedUid);
    if (index == -1) return;

    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;

    // Check if the insertion slot [index] is above the current viewport.
    // If above the viewport, do NOT animate 0->64px; instead keep its height
    // at 64px and compensate scrollOffset by +64px so visible items in the
    // viewport do not shift down by 1 step.
    if (_scrollController.hasClients && index * 64.0 < scrollOffset - 4.0) {
      _scrollController.jumpTo(scrollOffset + 64.0);
      return;
    }

    _animatedInsertUids.add(addedUid);
    if (mounted) {
      setState(() {});
    }

    Future<void>.delayed(_itemAnimatorTotalWait, () {
      if (!mounted) return;
      if (_animatedInsertUids.remove(addedUid)) {
        setState(() {});
      }
    });
  }

  void _handleClearQueue() {
    final state = context.read<QueueBloc>().state;
    if (_isClearingQueue || !state.hasUserQueue) return;

    final userQueue = state.queue.userQueue;
    final userQueueCount = userQueue.length;
    if (userQueueCount == 0) return;

    final currentTracks = List<ContextTrack>.from(
        QueueFilterHelper.getVisibleUpcomingTracks(state.queue));
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final firstVisibleIndex =
        (scrollOffset / 64.0).floor().clamp(0, currentTracks.length);
    final offScreenClearedCount = firstVisibleIndex.clamp(0, userQueueCount);

    // If all queued tracks are above the current viewport, clear them immediately
    // and compensate scrollOffset so the visible viewport items do not move.
    if (offScreenClearedCount >= userQueueCount) {
      if (_scrollController.hasClients) {
        final targetOffset =
            (scrollOffset - userQueueCount * 64.0).clamp(0.0, double.infinity);
        _scrollController.jumpTo(targetOffset);
      }
      context.read<QueueBloc>().add(const QueueCleared());
      return;
    }

    // Otherwise, drop any off-screen queued tracks immediately (compensating
    // scrollOffset) and smoothly animate all visible queued tracks in unison.
    final visibleQueuedUids = userQueue
        .sublist(offScreenClearedCount)
        .map((t) => t.uid)
        .toList();

    final gen = ++_tapAnimationGeneration;
    setState(() {
      _isClearingQueue = true;
      _slideDownUids.clear();
      _clearingUids
        ..clear()
        ..addAll(visibleQueuedUids);
      if (offScreenClearedCount > 0) {
        _tapTransitionTracks = currentTracks.sublist(offScreenClearedCount);
      }
    });

    if (offScreenClearedCount > 0 && _scrollController.hasClients) {
      final targetOffset = (scrollOffset - offScreenClearedCount * 64.0)
          .clamp(0.0, double.infinity);
      _scrollController.jumpTo(targetOffset);
    }

    // Wait for the 370ms DefaultItemAnimator (120ms fade-out + 250ms move collapse
    // from p/y7o.java + p/z6y0.java) before committing the clear in QueueBloc.
    Future<void>.delayed(_itemAnimatorTotalWait, () {
      if (!mounted || _tapAnimationGeneration != gen) return;
      context.read<QueueBloc>().add(const QueueCleared());
      setState(() {
        _isClearingQueue = false;
        _clearingUids.clear();
        _tapTransitionTracks = null;
      });
    });
  }

  void _handleTrackTapped(ContextTrack track) {
    final state = context.read<QueueBloc>().state;
    final currentTracks = List<ContextTrack>.from(
        QueueFilterHelper.getVisibleUpcomingTracks(state.queue));
    final tapIdx = currentTracks.indexWhere((t) => t.uid == track.uid);
    if (tapIdx == -1) return;

    final absoluteIndex = state.currentIndex + 1 + tapIdx;
    final userQueueCount = state.queue.userQueue.length;
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final firstVisibleIndex =
        (scrollOffset / 64.0).floor().clamp(0, currentTracks.length);
    final subRowOffset =
        (scrollOffset - firstVisibleIndex * 64.0).clamp(0.0, 64.0);

    final gen = ++_tapAnimationGeneration;

    // 1. Start audio playback & sticky QueueNowPlayingRow transition immediately at t=0ms
    context.read<QueueBloc>().add(
          QueueTrackTapped(
            track: track,
            absoluteIndex: absoluteIndex,
          ),
        );

    // 2. Build the viewport-anchored transition list so both sides animate
    //    continuously over the 370ms DefaultItemAnimator window:
    if (tapIdx < userQueueCount || userQueueCount == 0) {
      // Scenario A: Tapped a queued track (or no queued tracks exist).
      // Drop off-screen skipped rows above the viewport immediately at t=0ms,
      // and collapse only the visible skipped rows [startVisibleIdx .. tapIdx]
      // so all songs below the tapped song smoothly move UPWARDS to the top.
      final startVisibleIdx = firstVisibleIndex.clamp(0, tapIdx);
      final visibleSkipped = currentTracks.sublist(startVisibleIdx, tapIdx + 1);
      final remainingAfterTap = currentTracks.sublist(tapIdx + 1);
      final transitionTracks = <ContextTrack>[
        ...visibleSkipped,
        ...remainingAfterTap,
      ];
      final skippedUids = visibleSkipped.map((t) => t.uid).toList();

      setState(() {
        _tapTransitionTracks = transitionTracks;
        _tappedTrackUid = track.uid;
        _slideDownUids.clear();
        _clearingUids
          ..clear()
          ..addAll(skippedUids);
      });

      if (_scrollController.hasClients && _scrollController.offset > 0.0) {
        final initialOffset = startVisibleIdx == firstVisibleIndex
            ? subRowOffset
            : 0.0;
        _scrollController.jumpTo(initialOffset);
        if (initialOffset > 0.5) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutSine,
          );
        }
      }

      Future<void>.delayed(_itemAnimatorTotalWait, () {
        if (!mounted || _tapAnimationGeneration != gen) return;
        setState(() {
          _tapTransitionTracks = null;
          _tappedTrackUid = null;
          _clearingUids.removeAll(skippedUids);
        });
      });
    } else {
      // Scenario B: Tapped a context track below preserved queued tracks (userQueueCount > 0).
      // - Preserved queued tracks that were above the viewport smoothly slide
      //   DOWNWARDS from under the sticky Now Playing row (0 -> 64px).
      // - Visible skipped context tracks up to tapIdx fade out and collapse (64 -> 0px).
      // - Remaining context tracks below tapIdx smoothly move UPWARDS to meet
      //   the preserved queued tracks as a continuous list.
      final offScreenQueuedCount = firstVisibleIndex.clamp(0, userQueueCount);
      final firstVisibleRemovedContextIdx = firstVisibleIndex > userQueueCount
          ? firstVisibleIndex.clamp(userQueueCount, tapIdx)
          : userQueueCount;

      final animatedOffScreenQueued = currentTracks
          .take(offScreenQueuedCount.clamp(0, 10))
          .toList();
      final visibleQueued = currentTracks.sublist(
        offScreenQueuedCount,
        userQueueCount,
      );
      final visibleRemovedContext = currentTracks.sublist(
        firstVisibleRemovedContextIdx,
        tapIdx + 1,
      );
      final remainingContext = currentTracks.sublist(tapIdx + 1);

      final transitionTracks = <ContextTrack>[
        ...animatedOffScreenQueued,
        ...visibleQueued,
        ...visibleRemovedContext,
        ...remainingContext,
      ];

      final slideDownUids = animatedOffScreenQueued.map((t) => t.uid).toList();
      final skippedUids = visibleRemovedContext.map((t) => t.uid).toList();

      setState(() {
        _tapTransitionTracks = transitionTracks;
        _tappedTrackUid = track.uid;
        _slideDownUids
          ..clear()
          ..addAll(slideDownUids);
        _clearingUids
          ..clear()
          ..addAll(skippedUids);
      });

      if (_scrollController.hasClients && _scrollController.offset > 0.0) {
        _scrollController.jumpTo(subRowOffset);
        if (subRowOffset > 0.5) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutSine,
          );
        }
      }

      Future<void>.delayed(_itemAnimatorTotalWait, () {
        if (!mounted || _tapAnimationGeneration != gen) return;
        setState(() {
          _tapTransitionTracks = null;
          _tappedTrackUid = null;
          _slideDownUids.removeAll(slideDownUids);
          _clearingUids.removeAll(skippedUids);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extends right up to the system status bar inset with no extra gap.
    // Avoids full-screen Clip.antiAlias offscreen saveLayer by rounding the
    // top sticky header directly.
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      margin: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: PlayerColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Sticky Top Area: Grapple + Queue Header + Sticky First Song
              // Isolated in its own RepaintBoundary + targeted BlocBuilder so
              // play/pause changes never rebuild the track list below.
              RepaintBoundary(
                child: GestureDetector(
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
                  child: BlocBuilder<QueueBloc, QueueState>(
                    buildWhen: (previous, current) =>
                        previous.nowPlaying != current.nowPlaying ||
                        previous.isPlaying != current.isPlaying ||
                        previous.hasUserQueue != current.hasUserQueue,
                    builder: (context, state) {
                      final currentTrack = state.nowPlaying;
                      final showClear =
                          state.hasUserQueue && !_isClearingQueue;

                      return Container(
                        decoration: const BoxDecoration(
                          color: PlayerColors.background,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Grapple(),
                            _QueueHeader(
                              nowPlaying: currentTrack,
                              hasUserQueue: showClear,
                              onClearTapped: _handleClearQueue,
                            ),
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
                      );
                    },
                  ),
                ),
              ),

              // Scrollable upcoming tracks list (scrolls cleanly under sticky first song)
              // Isolated via RepaintBoundary + buildWhen so Play/Pause, Shuffle,
              // and Repeat toggles NEVER rebuild or repaint the ReorderableListView.
              Expanded(
                child: RepaintBoundary(
                  child: BlocConsumer<QueueBloc, QueueState>(
                    listenWhen: (previous, current) =>
                        previous.queue.revision != current.queue.revision ||
                        previous.currentIndex != current.currentIndex,
                    listener: (context, state) {
                      final addedUid = state.lastAddedUid;
                      if (addedUid != null) {
                        _handleTrackAddedAnimation(state, addedUid);
                      }
                    },
                    buildWhen: (previous, current) =>
                        previous.queue.revision != current.queue.revision ||
                        previous.currentIndex != current.currentIndex,
                    builder: (context, state) {
                      return _buildList(context, state);
                    },
                  ),
                ),
              ),
            ],
          ),

          // Bottom controls overlay (CoordinatorLayout layout_gravity=bottom)
          // Isolated via buildWhen so only shuffle/repeat mode changes rebuild it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BlocBuilder<QueueBloc, QueueState>(
              buildWhen: (previous, current) =>
                   previous.shuffleMode != current.shuffleMode ||
                   previous.repeatMode != current.repeatMode,
              builder: (context, state) {
                return QueueControlsLayout(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, QueueState state) {
    final nextTracks = _tapTransitionTracks ??
        QueueFilterHelper.getVisibleUpcomingTracks(state.queue);
    if (!state.hasQueue && !state.hasUpcoming && nextTracks.isEmpty) {
      return _buildPlaceholder();
    }

    final bottomPad = MediaQuery.paddingOf(context).bottom + 104;

    return SpotifyStretchOverscrollIndicator(
      controller: _stretchController,
      axisDirection: AxisDirection.down,
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        physics: const ClampingScrollPhysics(),
        buildDefaultDragHandles: false,
        scrollCacheExtent: const ScrollCacheExtent.pixels(400.0),
        padding: EdgeInsets.only(bottom: bottomPad),
        proxyDecorator: _proxyDecorator,
        itemCount: nextTracks.length,
        onReorderItem: (oldIndex, newIndex) {
          context.read<QueueBloc>().add(QueueReordered(oldIndex, newIndex));
        },
        itemBuilder: (context, index) {
          final track = nextTracks[index];
          final shouldAnimateInsert =
              _animatedInsertUids.contains(track.uid);
          final shouldAnimateSlideDown =
              _slideDownUids.contains(track.uid);
          final isClearingRow = _clearingUids.contains(track.uid);
          final isTappedRow = _tappedTrackUid == track.uid;

          return QueueTrackRow(
            key: ValueKey('track_${track.uid}'),
            track: track,
            index: index,
            animateInsert: shouldAnimateInsert,
            animateSlideDown: shouldAnimateSlideDown,
            isClearing: isClearingRow,
            isTappedPlaying: isTappedRow,
            onTap: () => _handleTrackTapped(track),
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

  /// 1:1 with Spotify's l1q0.java line 207:
  /// Transitions dragged row background to R.color.gray_15 (#262626) with an
  /// isolated RepaintBoundary (zero blur or shadow recalculation during 120Hz drag).
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        child: RepaintBoundary(child: child),
        builder: (context, proxyChild) {
          const curve = Cubic(0.3, 0.0, 0.0, 1.0);
          final t = curve.transform(animation.value);
          final bgColor = Color.lerp(
            PlayerColors.background,
            const Color(0xFF262626),
            t,
          )!;

          return ColoredBox(
            color: bgColor,
            child: proxyChild,
          );
        },
      ),
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
// and f1q0.java / c0b1.java (300ms DecelerateInterpolator transition)
//
// Left column:
//   "Queue" (20px bold white)
//   "Playing [context name]" ("Playing " in #B3B3B3 + context name in bold white)
// Right row:
//   [Clear] (animated pill, 300ms Decelerate, visible when hasUserQueue) + [Edit] pill
// ---------------------------------------------------------------------------

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.nowPlaying,
    required this.hasUserQueue,
    required this.onClearTapped,
  });

  final ContextTrack? nowPlaying;
  final bool hasUserQueue;
  final VoidCallback onClearTapped;

  // Matches f1q0.java line 264 & c0b1.java line 86: 300L + DecelerateInterpolator
  static const Duration _headerAnimDuration = Duration(milliseconds: 300);
  static final Tween<double> _clearScaleTween =
      Tween<double>(begin: 0.88, end: 1.0);

  @override
  Widget build(BuildContext context) {
    final contextTitle = _getPlayingContext(nowPlaying);

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

          // Right: Clear (animated 300ms Decelerate matching c0b1.java) + Edit pill buttons
          AnimatedSize(
            duration: _headerAnimDuration,
            curve: Curves.decelerate,
            child: AnimatedSwitcher(
              duration: _headerAnimDuration,
              switchInCurve: Curves.decelerate,
              switchOutCurve: Curves.decelerate,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: _clearScaleTween.animate(anim),
                  child: child,
                ),
              ),
              child: hasUserQueue
                  ? Padding(
                      key: const ValueKey('clear_btn'),
                      padding: const EdgeInsets.only(right: 8),
                      child: _HeaderPillButton(
                        label: 'Clear',
                        onTap: onClearTapped,
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

  // Matches res/anim/encore_button_animation_interpolator.xml
  // and @integer/encore_button_animation_time (200ms)
  static const Cubic _encoreButtonCurve = Cubic(0.3, 0.0, 0.0, 1.0);
  static const Duration _encoreButtonDuration = Duration(milliseconds: 200);

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
        scale: _isPressed ? 0.95 : 1.0,
        duration: _encoreButtonDuration,
        curve: _encoreButtonCurve,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF282828),
            borderRadius: BorderRadius.all(Radius.circular(20)),
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
