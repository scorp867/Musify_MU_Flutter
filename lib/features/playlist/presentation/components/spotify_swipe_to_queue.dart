library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 1:1 replica of Spotify's Swipe-to-Queue interaction
/// (`bqa1.java`, `vqa1.java`, `R.dimen.swipe_action_icon_size`).
///
/// Features:
/// 1. Horizontal swipe from Start to End (Left-to-Right in LTR).
/// 2. Clamped displacement to at most 45% of row width (`view.getWidth() * 0.45f`, `bqa1.java` line 86).
/// 3. Trigger activation threshold at 25% of row width (`abs / 0.25f`, `bqa1.java` line 127).
/// 4. Background color (#1DB954) and queue icon opacity scale linearly with swipe progress (0.0 -> 1.0).
/// 5. Single haptic feedback pulse when threshold is reached (`HapticFeedback.mediumImpact`).
/// 6. Fast spring snap-back animation (220ms, `Curves.easeOutCubic`) returning row to 0 displacement.
/// 7. Row is never dismissed or removed from the list.
class SpotifySwipeToQueue extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeToQueue;

  const SpotifySwipeToQueue({
    super.key,
    required this.child,
    this.onSwipeToQueue,
  });

  @override
  State<SpotifySwipeToQueue> createState() => _SpotifySwipeToQueueState();
}

class _SpotifySwipeToQueueState extends State<SpotifySwipeToQueue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _hasTriggeredHaptic = false;

  static const double _triggerThresholdFraction = 0.25;
  static const double _maxDragFraction = 0.45;
  static const double _iconSize = 24.0; // R.dimen.swipe_action_icon_size = 24dp

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = _controller.drive(Tween<double>(begin: 0.0, end: 0.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double totalWidth) {
    if (widget.onSwipeToQueue == null || totalWidth <= 0) return;

    final newOffset = _dragOffset + details.primaryDelta!;
    final maxAllowed = totalWidth * _maxDragFraction;
    final clamped = newOffset.clamp(0.0, maxAllowed);

    final threshold = totalWidth * _triggerThresholdFraction;
    if (clamped >= threshold && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticFeedback.mediumImpact();
    } else if (clamped < threshold && _hasTriggeredHaptic) {
      _hasTriggeredHaptic = false;
    }

    setState(() {
      _dragOffset = clamped;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double totalWidth) {
    if (widget.onSwipeToQueue == null || totalWidth <= 0) return;

    final threshold = totalWidth * _triggerThresholdFraction;
    if (_dragOffset >= threshold) {
      widget.onSwipeToQueue?.call();
    }

    _snapBack();
  }

  void _onHorizontalDragCancel() {
    _snapBack();
  }

  void _snapBack() {
    _hasTriggeredHaptic = false;
    _animation = _controller.drive(
      Tween<double>(begin: _dragOffset, end: 0.0).chain(
        CurveTween(curve: Curves.easeOutCubic),
      ),
    );
    _controller.reset();
    _controller.forward();
    _controller.addListener(_onAnimationTick);
  }

  void _onAnimationTick() {
    setState(() {
      _dragOffset = _animation.value;
    });
    if (_controller.isCompleted) {
      _controller.removeListener(_onAnimationTick);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onSwipeToQueue == null) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final threshold = totalWidth * _triggerThresholdFraction;
        final progress = threshold > 0 ? (_dragOffset / threshold).clamp(0.0, 1.0) : 0.0;
        final iconLeft = (_dragOffset - _iconSize) / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Revealed Green Swipe-to-Queue Background (bqa1.java lines 125-139)
            if (_dragOffset > 0)
              Positioned.fill(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: _dragOffset,
                      color: const Color(0xFF1DB954).withValues(alpha: progress),
                      child: iconLeft > 4
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: iconLeft),
                                child: Opacity(
                                  opacity: progress,
                                  child: const Icon(
                                    Icons.playlist_add,
                                    color: Colors.white,
                                    size: _iconSize,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),

            // 2. Foreground Track Content (translating horizontally)
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) =>
                    _onHorizontalDragUpdate(details, totalWidth),
                onHorizontalDragEnd: (details) =>
                    _onHorizontalDragEnd(details, totalWidth),
                onHorizontalDragCancel: _onHorizontalDragCancel,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
