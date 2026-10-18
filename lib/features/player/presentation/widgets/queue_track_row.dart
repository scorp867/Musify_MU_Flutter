import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

/// 1:1 with Spotify's layout_default_track_row.xml & p/l1q0.java (ItemTouchHelper)
/// + p/z6y0.java (DefaultItemAnimator).
class QueueTrackRow extends StatefulWidget {
  const QueueTrackRow({
    super.key,
    required this.title,
    required this.artist,
    this.isQueued = false,
    this.imageUrl,
    this.songId,
    required this.index,
    required this.onTap,
    required this.onRemove,
    required this.onAddToQueue,
    this.onCollapseStart,
    this.showDragHandle = true,
    this.animateInsert = false,
    this.animateSlideDown = false,
    this.isClearing = false,
    this.isTappedPlaying = false,
  });

  final String title;
  final String artist;
  final bool isQueued;
  final String? imageUrl;
  final int? songId;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAddToQueue;
  final VoidCallback? onCollapseStart;
  final bool showDragHandle;
  final bool animateInsert;
  final bool animateSlideDown;
  final bool isClearing;
  final bool isTappedPlaying;

  @override
  State<QueueTrackRow> createState() => _QueueTrackRowState();
}

class _QueueTrackRowState extends State<QueueTrackRow>
    with TickerProviderStateMixin {
  final ValueNotifier<double> _dragOffsetX = ValueNotifier<double>(0.0);

  late final AnimationController _swipeController;
  Animation<double>? _swipeAnimation;

  late final AnimationController _collapseController;
  late final Animation<double> _sizeFactorAnimation;
  late final Animation<double> _slideDownSizeAnimation;
  late final Animation<double> _fadeAnimation;
  late final _SpotifySwipeBackgroundPainter _swipePainter;

  double _rawDragX = 0.0;
  bool _armedAddToQueue = false;
  bool _isRemoving = false;
  bool _isSlidingDown = false;

  // Matches DefaultItemAnimator (p/z6y0.java + p/y7o.java + p/s7o.java):
  //   moveDuration (this.e) = 250ms
  //   addDuration (this.c) = 120ms (delayed by moveDuration = 250ms on insert)
  //   removeDuration (this.d) = 120ms (followed by moveDuration = 250ms on remove)
  //   Total two-phase duration = 250ms + 120ms = 370ms
  //   Interpolator (y7o.java line 417): ValueAnimator default (AccelerateDecelerate / easeInOutSine)
  static const Duration _totalItemAnimDuration = Duration(milliseconds: 370);
  static const double _movePhaseFraction = 250.0 / 370.0;
  static const double _removePhaseFraction = 120.0 / 370.0;

  // Matches ItemTouchHelper (xn30.java / un30.java):
  //   DEFAULT_SWIPE_ANIMATION_DURATION = 250ms
  static const Duration _swipeDismissDuration = Duration(milliseconds: 250);
  static const Duration _recoverDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();

    _swipePainter = _SpotifySwipeBackgroundPainter(dragOffsetX: _dragOffsetX);

    _swipeController = AnimationController(
      vsync: this,
      duration: _recoverDuration,
    )..addListener(() {
        final anim = _swipeAnimation;
        if (anim != null) {
          _dragOffsetX.value = anim.value;
        }
      });

    final startCollapsed = widget.animateInsert || widget.animateSlideDown;
    _isSlidingDown = widget.animateSlideDown;

    _collapseController = AnimationController(
      vsync: this,
      duration: _totalItemAnimDuration,
      value: startCollapsed ? 0.0 : 1.0,
    );

    // Forward (Insert): 0..250ms opens the 64dp slot (sizeFactor 0->1) while alpha=0;
    //                   250..370ms fades the new item in (alpha 0->1 over 120ms).
    // Reverse (Remove): 0..120ms fades the item out (alpha 1->0) while sizeFactor=1;
    //                   120..370ms collapses the 64dp slot (sizeFactor 1->0 over 250ms).
    _sizeFactorAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: const Interval(
        0.0,
        _movePhaseFraction,
        curve: Curves.easeInOutSine,
      ),
      reverseCurve: const Interval(
        0.0,
        _movePhaseFraction,
        curve: Curves.easeInOutSine,
      ),
    );

    // Slide-down for preserved queued tracks entering from above the viewport:
    // Waits 120ms while skipped tracks fade out, then expands 0->1 over 120..370ms
    // in exact lockstep with the 250ms collapse of skipped tracks.
    _slideDownSizeAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: const Interval(
        _removePhaseFraction,
        1.0,
        curve: Curves.easeInOutSine,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: const Interval(
        _movePhaseFraction,
        1.0,
        curve: Curves.easeInOutSine,
      ),
      reverseCurve: const Interval(
        _movePhaseFraction,
        1.0,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.isClearing) {
      _isRemoving = true;
      _isSlidingDown = false;
      _collapseController.value = 1.0;
      _collapseController.reverse();
    } else if (startCollapsed) {
      _collapseController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant QueueTrackRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isClearing && !oldWidget.isClearing && !_isRemoving) {
      _isRemoving = true;
      _isSlidingDown = false;
      _collapseController.reverse(from: 1.0);
      return;
    }
    if (widget.animateSlideDown && !oldWidget.animateSlideDown && !_isRemoving) {
      _isSlidingDown = true;
      _collapseController.forward(from: 0.0);
      return;
    }
    if (!widget.animateSlideDown && oldWidget.animateSlideDown && !_isRemoving) {
      _isSlidingDown = false;
    }
    if (widget.animateInsert &&
        !oldWidget.animateInsert &&
        !_isRemoving &&
        _collapseController.value == 1.0) {
      _isSlidingDown = false;
      _collapseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _collapseController.dispose();
    _dragOffsetX.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isRemoving) return;
    if (_swipeController.isAnimating) {
      _swipeController.stop();
      _swipeAnimation = null;
    }
    _rawDragX = _dragOffsetX.value;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isRemoving) return;
    final width = context.size?.width ?? 360.0;
    _rawDragX += details.primaryDelta ?? 0.0;

    if (_rawDragX >= 0.0) {
      // Exact l1q0.java line 110 & 122: clamp right swipe to 0.45 * width
      final maxRight = width * 0.45;
      final clampedDx = _rawDragX.clamp(0.0, maxRight);
      // Exact l1q0.java line 185-193: arm when abs(f3)/width > 0.25f
      _armedAddToQueue = (clampedDx / width) > 0.25;
      _dragOffsetX.value = clampedDx;
    } else {
      _armedAddToQueue = false;
      _dragOffsetX.value = _rawDragX.clamp(-width, 0.0);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isRemoving) return;
    final width = context.size?.width ?? 360.0;
    final currentDx = _dragOffsetX.value;
    final velocityX = details.primaryVelocity ?? 0.0;

    if (currentDx == 0.0) return;

    if (currentDx > 0.0) {
      // Swipe right never dismisses (l1q0.java m() & n() return Float.MAX_VALUE).
      // RecoverAnimation (un30.java) animates back to 0.0, and triggers Add to Queue
      // right when f5 == 0.0f (l1q0.java line 130).
      final triggerAddOnZero = _armedAddToQueue;
      _armedAddToQueue = false;
      _animateSwipeTo(
        targetDx: 0.0,
        duration: _recoverDuration,
        curve: Curves.decelerate,
        onCompleted: () {
          if (triggerAddOnZero && mounted) {
            widget.onAddToQueue();
          }
        },
      );
    } else {
      // Swipe left (delete): threshold 0.45 of width or fast left fling
      final fraction = (-currentDx) / width;
      final shouldDelete =
          fraction >= 0.45 || (velocityX < -600.0 && currentDx < -24.0);

      if (!shouldDelete) {
        _animateSwipeTo(
          targetDx: 0.0,
          duration: _recoverDuration,
          curve: Curves.decelerate,
        );
      } else {
        _isRemoving = true;
        _isSlidingDown = false;

        // Exact Spotify sequence (xn30.java + un30.java + pa3.java + y7o.java):
        // 1) 250ms RecoverAnimation slides row out to -width (revealing full red bar)
        // 2) pa3 posts notifyItemRemoved -> y7o.java runs 120ms fade-out of the item
        // 3) y7o.java line 256 delays move by 120ms, then collapses height over 250ms
        _animateSwipeTo(
          targetDx: -width,
          duration: _swipeDismissDuration,
          curve: Curves.decelerate,
          onCompleted: () {
            if (!mounted) return;
            widget.onCollapseStart?.call();
            _collapseController.reverse(from: 1.0).then((_) {
              if (mounted) {
                widget.onRemove();
              }
            });
          },
        );
      }
    }
  }

  void _onHorizontalDragCancel() {
    if (_isRemoving) return;
    _armedAddToQueue = false;
    if (_dragOffsetX.value != 0.0) {
      _animateSwipeTo(
        targetDx: 0.0,
        duration: _recoverDuration,
        curve: Curves.decelerate,
      );
    }
  }

  void _animateSwipeTo({
    required double targetDx,
    required Duration duration,
    required Curve curve,
    VoidCallback? onCompleted,
  }) {
    final startDx = _dragOffsetX.value;
    _swipeAnimation = Tween<double>(
      begin: startDx,
      end: targetDx,
    ).animate(
      CurvedAnimation(
        parent: _swipeController,
        curve: curve,
      ),
    );
    _swipeController.duration = duration;
    _swipeController.forward(from: 0.0).then((_) {
      onCompleted?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pre-built static row subtree wrapped in its own RepaintBoundary + ColoredBox.
    final cachedRowLayer = RepaintBoundary(
      child: ColoredBox(
        color: PlayerColors.background,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    _StrictHorizontalDragGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            _StrictHorizontalDragGestureRecognizer>(
                      () => _StrictHorizontalDragGestureRecognizer(
                        debugOwner: this,
                      ),
                      (_StrictHorizontalDragGestureRecognizer instance) {
                        instance
                          ..onStart = _onHorizontalDragStart
                          ..onUpdate = _onHorizontalDragUpdate
                          ..onEnd = _onHorizontalDragEnd
                          ..onCancel = _onHorizontalDragCancel;
                      },
                    ),
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      splashColor: Colors.white.withValues(alpha: 0.06),
                      highlightColor: Colors.white.withValues(alpha: 0.03),
                      child: SizedBox(
                        height: 64,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            children: [
                              // 48x48 Artwork with 4dp corners
                              ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: PlayerArtworkImage(
                                    songId: widget.songId,
                                    imageUrl: widget.imageUrl,
                                    artworkWidth: 48,
                                    artworkHeight: 48,
                                    placeholderIconSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Title + Subtitle (with QueuedBadgeView)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title.isNotEmpty
                                            ? widget.title
                                            : 'Unknown Track',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: widget.isTappedPlaying
                                              ? PlayerColors.accent
                                              : Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (widget.isQueued)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 5,
                                              ),
                                              child: SpotifyIcon.queueBadge(
                                                color: PlayerColors.accent,
                                                size: 13,
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              widget.artist.isNotEmpty
                                                  ? widget.artist
                                                  : 'Unknown Artist',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color:
                                                    PlayerColors.textSecondary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Drag handle (encore_icon_sort, marginEnd=8dp)
              // Kept outside horizontal swipe GestureDetector for instant drag start
              if (widget.showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ReorderableDragStartListener(
                    index: widget.index,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.transparent,
                      child: SpotifyIcon.sort(
                        color: Colors.white.withValues(alpha: 0.75),
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Outer RepaintBoundary isolates each row in the SliverReorderableList.
    // _swipePainter listens to _dragOffsetX directly via super(repaint:), so
    // swipe background repaints happen purely at the canvas level with zero
    // painter allocations, and AnimatedBuilder only updates Transform.translate.
    return RepaintBoundary(
      child: SizeTransition(
        sizeFactor:
            _isSlidingDown ? _slideDownSizeAnimation : _sizeFactorAnimation,
        alignment:
            _isSlidingDown ? Alignment.bottomCenter : Alignment.topCenter,
        child: FadeTransition(
          opacity: _isSlidingDown
              ? const AlwaysStoppedAnimation<double>(1.0)
              : _fadeAnimation,
          child: CustomPaint(
            painter: _swipePainter,
            child: AnimatedBuilder(
              animation: _dragOffsetX,
              child: cachedRowLayer,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_dragOffsetX.value, 0.0),
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom horizontal drag recognizer that ONLY accepts pure horizontal swipes
/// (within ~24 degrees of horizontal) and immediately rejects when vertical
/// scroll movement is detected, preventing accidental row swipes while scrolling.
class _StrictHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  _StrictHorizontalDragGestureRecognizer({super.debugOwner});

  Offset _startPosition = Offset.zero;
  double _totalDx = 0.0;
  double _totalDy = 0.0;
  bool _isAccepted = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _startPosition = event.position;
    _totalDx = 0.0;
    _totalDy = 0.0;
    _isAccepted = false;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_isAccepted && event is PointerMoveEvent) {
      _totalDx = (event.position.dx - _startPosition.dx).abs();
      _totalDy = (event.position.dy - _startPosition.dy).abs();

      // If vertical movement exceeds 6px and angle is steeper than ~24 degrees
      // off horizontal, immediately reject so vertical scrolling wins cleanly.
      if (_totalDy > 6.0 && _totalDy > _totalDx * 0.45) {
        resolve(GestureDisposition.rejected);
        return;
      }
    }
    super.handleEvent(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    final minSlop = computeHitSlop(pointerDeviceKind, gestureSettings);
    final effectiveSlop = minSlop > 12.0 ? minSlop : 12.0;
    // Require pure horizontal swipe: at least effectiveSlop horizontally
    // and at least 2.2x any vertical drift.
    return _totalDx > effectiveSlop && _totalDx > _totalDy * 2.2;
  }

  @override
  void acceptGesture(int pointer) {
    _isAccepted = true;
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _isAccepted = false;
    super.rejectGesture(pointer);
  }
}

/// 1:1 implementation of p/l1q0.java lines 161-185 (onChildDraw):
/// Draws the green (#1ED760) or red (#E22134) rect for the current horizontal
/// translation [dragOffsetX], clips to that rect, and centers the Encore icon.
/// Driven directly via `super(repaint: dragOffsetX)` with a pre-allocated Paint
/// so 120Hz swipes allocate zero objects per frame.
class _SpotifySwipeBackgroundPainter extends CustomPainter {
  _SpotifySwipeBackgroundPainter({required this.dragOffsetX})
      : super(repaint: dragOffsetX);

  final ValueNotifier<double> dragOffsetX;

  static const Color _positiveGreen = Color(0xFF1ED760);
  static const Color _negativeRed = Color(0xFFE22134);

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = dragOffsetX.value;
    if (dx == 0.0) return;

    if (dx > 0.0) {
      // Swipe right: Add to Queue (l1q0.java lines 177-184)
      _fillPaint.color = _positiveGreen;
      final rect = Rect.fromLTWH(0.0, 0.0, dx, size.height);
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawRect(rect, _fillPaint);
      SpotifyIcon.paintIcon(
        canvas,
        SpotifyEncoreIcons.addToQueuePaths,
        center: Offset(dx * 0.5, size.height * 0.5),
        size: 24.0,
        color: Colors.white,
      );
      canvas.restore();
    } else {
      // Swipe left: Delete (l1q0.java lines 173-184)
      _fillPaint.color = _negativeRed;
      final rect = Rect.fromLTWH(size.width + dx, 0.0, -dx, size.height);
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawRect(rect, _fillPaint);
      SpotifyIcon.paintIcon(
        canvas,
        SpotifyEncoreIcons.deletePaths,
        center: Offset(size.width + dx * 0.5, size.height * 0.5),
        size: 24.0,
        color: Colors.white,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SpotifySwipeBackgroundPainter oldDelegate) {
    return oldDelegate.dragOffsetX != dragOffsetX;
  }
}
