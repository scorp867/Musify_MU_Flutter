import 'dart:ui' show clampDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'pull_to_dismiss_scaffold.dart';
import 'spotify_scroll_physics.dart';

/// Reusable two-tier scroll view replicating native Spotify's `PeekScrollView`
/// and `FullScreenLayout` architecture.
///
/// Tier 1: Viewport-locked main player (header, artwork, controls).
/// Tier 2: Scrollable cards container (lyrics, track details, about artist)
/// where the top card peeks into Tier 1 by [peekHeight] at scroll offset 0.
class PeekScrollView extends StatefulWidget {
  const PeekScrollView({
    super.key,
    required this.dismissController,
    required this.header,
    required this.mainContent,
    required this.peekingCard,
    this.expandedCards = const [],
    this.peekHeight = 64.0,
    this.bottomPaddingExtra = 36.0,
  });

  final PullToDismissController dismissController;
  final Widget header;
  final Widget mainContent;
  final Widget peekingCard;
  final List<Widget> expandedCards;
  final double peekHeight;
  final double bottomPaddingExtra;

  @override
  State<PeekScrollView> createState() => PeekScrollViewState();
}

class PeekScrollViewState extends State<PeekScrollView>
    with TickerProviderStateMixin {
  late final SpotifyStretchController _stretchController;
  late final SpotifyPeekScrollController _scrollController;

  SpotifyStretchController get stretchController => _stretchController;
  SpotifyPeekScrollController get scrollController => _scrollController;

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

  /// Scrolls smoothly into the expanded card tier over 500ms using
  /// Spotify's exact Cubic(0.3, 0.0, 0.0, 1.0) curve.
  void scrollToExpanded() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final targetOffset =
        screenHeight - widget.peekHeight - bottomPadding - topPadding;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: const Cubic(0.3, 0.0, 0.0, 1.0),
    );
  }

  /// Scrolls back to the main viewport.
  void scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: const Cubic(0.3, 0.0, 0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // Viewport 1 fills screen height minus peek height and bottom insets.
    final mainPlayerHeight = screenHeight - widget.peekHeight - bottomPadding;

    return SpotifyStretchOverscrollIndicator(
      controller: _stretchController,
      axisDirection: AxisDirection.down,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Tier 1: Viewport-locked Main Player
          SliverToBoxAdapter(
            child: SizedBox(
              height: mainPlayerHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
                child: Column(
                  children: [
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
                      child: widget.header,
                    ),
                    Expanded(child: widget.mainContent),
                  ],
                ),
              ),
            ),
          ),
          // Tier 2: Scroll Cards Container (Peeking + Expanded)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                widget.peekingCard,
                for (final card in widget.expandedCards) ...[
                  const SizedBox(height: 16),
                  card,
                ],
                SizedBox(height: bottomPadding + widget.bottomPaddingExtra),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom [ScrollController] coordinating dismiss drag at top and native stretch overscroll.
class SpotifyPeekScrollController extends ScrollController {
  SpotifyPeekScrollController({
    required this.dismissController,
    required this.stretchController,
  });

  final PullToDismissController dismissController;
  final SpotifyStretchController stretchController;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SpotifyPeekScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      dismissController: dismissController,
      stretchController: stretchController,
    );
  }
}

class _SpotifyPeekScrollPosition extends ScrollPositionWithSingleContext {
  _SpotifyPeekScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.dismissController,
    required this.stretchController,
  });

  final PullToDismissController dismissController;
  final SpotifyStretchController stretchController;

  /// Accumulated stretch pixel offsets for top and bottom overscroll.
  double _bottomOverscrollPx = 0.0;
  double _topOverscrollPx = 0.0;

  /// Timestamp recording when the scroll position arrived at 0.0 from an active
  /// scroll or fling. Used to ensure rapid continuous flinging stretches at the top
  /// instead of prematurely collapsing the sheet.
  DateTime? _topArrivalTimestamp;

  /// True when the active touch interaction started while the scroll view
  /// was already resting at offset 0.0 (top) for at least the settling duration.
  bool _gestureStartedAtTop = false;

  /// True while this drag gesture is actively driving the pull-to-dismiss route.
  bool _isPullingRoute = false;

  @override
  double setPixels(double newPixels) {
    if (hasPixels && pixels > 1.0 && newPixels <= 0.5) {
      _topArrivalTimestamp = DateTime.now();
    } else if (newPixels > 1.0) {
      _topArrivalTimestamp = null;
    }
    return super.setPixels(newPixels);
  }

  @override
  void correctPixels(double value) {
    if (hasPixels && pixels > 1.0 && value <= 0.5) {
      _topArrivalTimestamp = DateTime.now();
    } else if (value > 1.0) {
      _topArrivalTimestamp = null;
    }
    super.correctPixels(value);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final viewport = hasViewportDimension ? viewportDimension : 800.0;

    // If a stretch is already active (e.g. caught mid-rebound):
    if (stretchController.overscroll > 0.0) {
      _bottomOverscrollPx = stretchController.overscroll * viewport;
      _topOverscrollPx = 0.0;
    } else if (stretchController.overscroll < 0.0) {
      _topOverscrollPx = -stretchController.overscroll * viewport;
      _bottomOverscrollPx = 0.0;
    } else {
      _bottomOverscrollPx = 0.0;
      _topOverscrollPx = 0.0;
    }

    final isAtZero = hasPixels ? (pixels <= (minScrollExtent + 0.5)) : true;

    // Must be at 0 and have rested for at least 400ms (or at rest since route open)
    final isRestedAtTop = isAtZero &&
        (_topArrivalTimestamp == null ||
            DateTime.now().difference(_topArrivalTimestamp!) >=
                const Duration(milliseconds: 400));

    _gestureStartedAtTop = isRestedAtTop;

    if (isAtZero && !isRestedAtTop) {
      // User is continuously swiping without pausing: refresh timestamp so
      // ongoing rapid swipes keep absorbing as top stretch instead of collapsing.
      _topArrivalTimestamp = DateTime.now();
    }

    _isPullingRoute = dismissController.dragOffsetY > 0.0;
    return super.drag(details, dragCancelCallback);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
      delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
    );

    final currentDragY = dismissController.dragOffsetY;

    // 1. If sheet is already pulled down, handle sheet interaction:
    if (currentDragY > 0.0) {
      if (delta > 0.0) {
        // Dragging further down
        dismissController.onPullDelta(delta);
      } else {
        // Dragging up to restore the sheet back to 0.0
        final newDragY = currentDragY + delta;
        if (newDragY >= 0.0) {
          dismissController.onPullDelta(delta);
        } else {
          dismissController.onPullDelta(-currentDragY);
          final leftover = delta + currentDragY;
          applyUserOffset(leftover);
        }
      }
      return;
    }

    final viewport = hasViewportDimension ? viewportDimension : 800.0;

    // 2. If BOTTOM is currently stretched (_bottomOverscrollPx > 0.0):
    if (_bottomOverscrollPx > 0.0) {
      if (delta < 0.0) {
        // Dragging further into bottom overscroll (finger moving UP):
        _bottomOverscrollPx += -delta;
        final double normalized = _bottomOverscrollPx / viewport;
        stretchController.pull(clampDouble(normalized, 0.0, 1.0));
        return;
      } else {
        // Dragging in OPPOSITE direction (finger moving DOWN):
        // Contract the bottom stretch WITHOUT scrolling the list!
        final double newBottomOverscroll = _bottomOverscrollPx - delta;
        if (newBottomOverscroll >= 0.0) {
          _bottomOverscrollPx = newBottomOverscroll;
          final double normalized = _bottomOverscrollPx / viewport;
          stretchController.pull(clampDouble(normalized, 0.0, 1.0));
          return; // Entire delta consumed by stretch! Content stays firmly in place.
        } else {
          // Bottom stretch fully collapsed back to 0:
          final double leftover = delta - _bottomOverscrollPx;
          _bottomOverscrollPx = 0.0;
          stretchController.finish();
          // Now only the leftover delta scrolls the list back up:
          super.applyUserOffset(leftover);
          return;
        }
      }
    }

    // 3. If TOP is currently stretched (_topOverscrollPx > 0.0):
    if (_topOverscrollPx > 0.0) {
      if (delta > 0.0) {
        // Dragging further into top overscroll (finger moving DOWN):
        _topOverscrollPx += delta;
        final double normalized = -(_topOverscrollPx / viewport);
        stretchController.pull(clampDouble(normalized, -1.0, 0.0));
        return;
      } else {
        // Dragging in OPPOSITE direction (finger moving UP):
        // Contract the top stretch WITHOUT scrolling the list!
        final double newTopOverscroll = _topOverscrollPx + delta; // delta < 0
        if (newTopOverscroll >= 0.0) {
          _topOverscrollPx = newTopOverscroll;
          final double normalized = -(_topOverscrollPx / viewport);
          stretchController.pull(clampDouble(normalized, -1.0, 0.0));
          return; // Entire delta consumed by stretch! Content stays firmly in place.
        } else {
          // Top stretch fully collapsed back to 0:
          final double leftover = delta + _topOverscrollPx;
          _topOverscrollPx = 0.0;
          stretchController.finish();
          // Now only the leftover delta scrolls into the cards:
          super.applyUserOffset(leftover);
          return;
        }
      }
    }

    // 4. Neither edge is currently stretched: Check boundary conditions

    // 4A. User is dragging finger DOWN (delta > 0.0):
    if (delta > 0.0) {
      if (!hasPixels || pixels <= (minScrollExtent + 0.5)) {
        // Already at top:
        if (_gestureStartedAtTop) {
          _isPullingRoute = true;
          dismissController.onPullDelta(delta);
          return;
        } else {
          // Rapid swiping or inner fling reached top: stretch top!
          _topOverscrollPx += delta;
          final double normalized = -(_topOverscrollPx / viewport);
          stretchController.pull(clampDouble(normalized, -1.0, 0.0));
          return;
        }
      }

      final double availableToTop = pixels - minScrollExtent;
      if (delta > availableToTop && availableToTop >= 0.0) {
        // Scroll list to 0 first:
        super.applyUserOffset(availableToTop);
        final double overflow = delta - availableToTop;
        if (_gestureStartedAtTop) {
          _isPullingRoute = true;
          dismissController.onPullDelta(overflow);
        } else {
          _topOverscrollPx = overflow;
          final double normalized = -(_topOverscrollPx / viewport);
          stretchController.pull(clampDouble(normalized, -1.0, 0.0));
        }
        return;
      }

      // Normal downward scroll within bounds:
      super.applyUserOffset(delta);
      return;
    }

    // 4B. User is dragging finger UP (delta < 0.0):
    _isPullingRoute = false;

    if (hasPixels && pixels >= (maxScrollExtent - 0.5)) {
      // Already at bottom: all delta stretches the bottom!
      _bottomOverscrollPx += -delta;
      final double normalized = _bottomOverscrollPx / viewport;
      stretchController.pull(clampDouble(normalized, 0.0, 1.0));
      return;
    }

    final double availableToBottom = maxScrollExtent - pixels;
    if (hasPixels && -delta > availableToBottom && availableToBottom >= 0.0) {
      // Scroll list to bottom first:
      super.applyUserOffset(-availableToBottom);
      final double overflow = -delta - availableToBottom;
      _bottomOverscrollPx = overflow;
      final double normalized = _bottomOverscrollPx / viewport;
      stretchController.pull(clampDouble(normalized, 0.0, 1.0));
      return;
    }

    // Normal upward scroll within bounds:
    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    if (velocity.abs() > 50.0 && (!hasPixels || pixels <= 1.0)) {
      _topArrivalTimestamp = DateTime.now();
    }

    if (_isPullingRoute || dismissController.dragOffsetY > 0.0) {
      // User released during pull-to-dismiss: end pull gesture.
      dismissController.onPullEnd(-velocity);
      _isPullingRoute = false;
      super.goBallistic(0.0);
      return;
    }

    // If stretched at bottom upon release:
    if (_bottomOverscrollPx > 0.0 || stretchController.overscroll > 0.0) {
      _bottomOverscrollPx = 0.0;
      stretchController.scrollEnd(-velocity);
      super.goBallistic(0.0);
      return;
    }

    // If stretched at top upon release:
    if (_topOverscrollPx > 0.0 || stretchController.overscroll < 0.0) {
      _topOverscrollPx = 0.0;
      stretchController.scrollEnd(-velocity);
      super.goBallistic(0.0);
      return;
    }

    // Normal fling inside cards content:
    super.goBallistic(velocity);
  }
}
