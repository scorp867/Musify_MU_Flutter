import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Controller interface exposed by [PullToDismissScaffold] to child views
/// and custom scroll controllers.
abstract class PullToDismissController {
  double get dragOffsetY;
  bool get isDismissing;
  void onPullDelta(double delta);
  void onPullEnd(double velocity);
  void dismiss();
}

/// Reusable host widget providing interactive pull-to-dismiss physics,
/// velocity-aware threshold snapping, and touch safety locking.
class PullToDismissScaffold extends StatefulWidget {
  const PullToDismissScaffold({
    super.key,
    required this.builder,
    this.dismissDistanceThreshold = 110.0,
    this.dismissVelocityThreshold = 750.0,
    this.barrierBaseAlpha = 0.70,
  });

  final Widget Function(BuildContext context, PullToDismissController controller)
      builder;
  final double dismissDistanceThreshold;
  final double dismissVelocityThreshold;
  final double barrierBaseAlpha;

  @override
  State<PullToDismissScaffold> createState() => _PullToDismissScaffoldState();
}

class _PullToDismissScaffoldState extends State<PullToDismissScaffold>
    with SingleTickerProviderStateMixin
    implements PullToDismissController {
  late final AnimationController _animController;
  Animation<double>? _dragAnimation;

  double _dragOffsetY = 0.0;
  bool _isDismissing = false;

  final Set<int> _sheetPointers = <int>{};
  final Set<int> _scrimPointers = <int>{};
  final Map<int, Offset> _scrimPointerStartPositions = <int, Offset>{};
  final Map<int, Offset> _scrimPointerLastPositions = <int, Offset>{};
  final Map<int, VelocityTracker> _scrimVelocityTrackers = <int, VelocityTracker>{};
  final Set<int> _scrimPointersDidDrag = <int>{};
  double _pendingVelocity = 0.0;
  int? _activeDraggingPointer;
  bool _lastMoveDirectionDown = true;
  bool _isSnappingBack = false;

  @override
  double get dragOffsetY => _dragOffsetY;

  @override
  bool get isDismissing => _isDismissing;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )
      ..addListener(() {
        if (_dragAnimation != null) {
          setState(() {
            _dragOffsetY = _dragAnimation!.value;
          });
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _isSnappingBack = false;
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _sheetPointers.clear();
    _scrimPointers.clear();
    _scrimPointerStartPositions.clear();
    _scrimPointerLastPositions.clear();
    _scrimVelocityTrackers.clear();
    _scrimPointersDidDrag.clear();
    _activeDraggingPointer = null;
    super.dispose();
  }

  @override
  void onPullDelta(double delta) {
    if (_isDismissing) return;
    // When the active dragging pointer is currently on the scrim, ignore sheet deltas
    // so touches on sheet and scrim do not double the drag speed.
    if (_activeDraggingPointer != null &&
        _scrimPointers.contains(_activeDraggingPointer)) {
      return;
    }
    _applyDelta(delta);
  }

  void _applyDelta(double delta) {
    if (_isDismissing) return;
    if (_animController.isAnimating) {
      _animController.stop();
      _dragAnimation = null;
    }
    if (delta > 0.5) {
      _lastMoveDirectionDown = true;
    } else if (delta < -0.5) {
      _lastMoveDirectionDown = false;
    }
    setState(() {
      _dragOffsetY = (_dragOffsetY + delta).clamp(0.0, double.infinity);
    });
  }

  @override
  void onPullEnd(double velocity) {
    if (_isDismissing) return;
    if (_scrimPointers.isNotEmpty) {
      // Touch is still held on the exposed scrim; retain offset and defer resolution.
      if (velocity.abs() > 50.0) {
        _pendingVelocity = velocity;
      }
      return;
    }
    _sheetPointers.clear();
    _activeDraggingPointer = null;
    _resolveGestureEnd(velocity);
  }

  @override
  void dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    Navigator.of(context).pop();
  }

  void _onScrimPointerDown(PointerDownEvent event) {
    if (_isDismissing) return;
    if (_animController.isAnimating) {
      _animController.stop();
      _dragAnimation = null;
      _isSnappingBack = false;
    }
    _scrimPointerStartPositions[event.pointer] = event.position;
    _scrimPointerLastPositions[event.pointer] = event.position;
    _scrimVelocityTrackers[event.pointer] = VelocityTracker.withKind(event.kind);
    _scrimVelocityTrackers[event.pointer]!.addPosition(event.timeStamp, event.position);
    _scrimPointers.add(event.pointer);
    _activeDraggingPointer = event.pointer;
  }

  void _onScrimPointerMove(PointerMoveEvent event) {
    if (_isDismissing) return;
    _scrimVelocityTrackers[event.pointer]?.addPosition(event.timeStamp, event.position);

    final startPos = _scrimPointerStartPositions[event.pointer];
    if (startPos != null && (event.position - startPos).distance > 4.0) {
      _scrimPointersDidDrag.add(event.pointer);
    }

    final lastPos = _scrimPointerLastPositions[event.pointer] ?? event.position;
    final deltaY = event.position.dy - lastPos.dy;
    _scrimPointerLastPositions[event.pointer] = event.position;

    // Only the single active dragging pointer is allowed to move the sheet at a time:
    if (_activeDraggingPointer == event.pointer) {
      if (deltaY != 0.0) {
        _applyDelta(deltaY);
      }
    }
  }

  void _onScrimPointerUp(PointerUpEvent event) {
    final didDrag = _scrimPointersDidDrag.remove(event.pointer);
    _scrimPointerStartPositions.remove(event.pointer);
    _scrimPointerLastPositions.remove(event.pointer);
    final tracker = _scrimVelocityTrackers.remove(event.pointer);
    _scrimPointers.remove(event.pointer);

    if (_activeDraggingPointer == event.pointer) {
      if (_scrimPointers.isNotEmpty) {
        _activeDraggingPointer = _scrimPointers.last;
      } else if (_sheetPointers.isNotEmpty) {
        _activeDraggingPointer = _sheetPointers.last;
      } else {
        _activeDraggingPointer = null;
      }
    }

    if (_isDismissing) return;

    // Tap on scrim area outside the player sheet dismisses the route.
    if (!didDrag && _dragOffsetY > 0) {
      _animateAndDismiss();
      return;
    }

    final velocityEstimate = tracker?.getVelocity();
    final velocityY = velocityEstimate?.pixelsPerSecond.dy ?? 0.0;

    if (_scrimPointers.isNotEmpty || _sheetPointers.isNotEmpty) {
      if (velocityY.abs() > 50.0) {
        _pendingVelocity = velocityY;
      }
      return;
    }

    _resolveGestureEnd(velocityY);
  }

  void _onScrimPointerCancel(PointerCancelEvent event) {
    _scrimPointersDidDrag.remove(event.pointer);
    _scrimPointerStartPositions.remove(event.pointer);
    _scrimPointerLastPositions.remove(event.pointer);
    _scrimVelocityTrackers.remove(event.pointer);
    _scrimPointers.remove(event.pointer);

    if (_activeDraggingPointer == event.pointer) {
      if (_scrimPointers.isNotEmpty) {
        _activeDraggingPointer = _scrimPointers.last;
      } else if (_sheetPointers.isNotEmpty) {
        _activeDraggingPointer = _sheetPointers.last;
      } else {
        _activeDraggingPointer = null;
      }
    }

    if (!_isDismissing && _scrimPointers.isEmpty && _sheetPointers.isEmpty) {
      _resolveGestureEnd(0.0);
    }
  }

  void _onSheetPointerDown(PointerDownEvent event) {
    if (_isDismissing) return;
    if (_animController.isAnimating) {
      _animController.stop();
      _dragAnimation = null;
      _isSnappingBack = false;
    }
    _sheetPointers.add(event.pointer);
    _activeDraggingPointer = event.pointer;
  }

  void _onSheetPointerUp(PointerUpEvent event) {
    _sheetPointers.remove(event.pointer);

    if (_activeDraggingPointer == event.pointer) {
      if (_scrimPointers.isNotEmpty) {
        _activeDraggingPointer = _scrimPointers.last;
      } else if (_sheetPointers.isNotEmpty) {
        _activeDraggingPointer = _sheetPointers.last;
      } else {
        _activeDraggingPointer = null;
      }
    }

    if (!_isDismissing &&
        _sheetPointers.isEmpty &&
        _scrimPointers.isEmpty &&
        _dragOffsetY > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_isDismissing &&
            _dragOffsetY > 0 &&
            !_animController.isAnimating) {
          _resolveGestureEnd(0.0);
        }
      });
    }
  }

  void _onSheetPointerCancel(PointerCancelEvent event) {
    _sheetPointers.remove(event.pointer);

    if (_activeDraggingPointer == event.pointer) {
      if (_scrimPointers.isNotEmpty) {
        _activeDraggingPointer = _scrimPointers.last;
      } else if (_sheetPointers.isNotEmpty) {
        _activeDraggingPointer = _sheetPointers.last;
      } else {
        _activeDraggingPointer = null;
      }
    }

    if (!_isDismissing &&
        _sheetPointers.isEmpty &&
        _scrimPointers.isEmpty &&
        _dragOffsetY > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_isDismissing &&
            _dragOffsetY > 0 &&
            !_animController.isAnimating) {
          _resolveGestureEnd(0.0);
        }
      });
    }
  }

  void _resolveGestureEnd(double velocity) {
    if (_isDismissing) return;

    final effectiveVelocity =
        velocity.abs() > 50.0 ? velocity : _pendingVelocity;
    _pendingVelocity = 0.0;
    _activeDraggingPointer = null;

    if (_dragOffsetY > 0) {
      final bool shouldCollapse;
      if (effectiveVelocity > 200.0) {
        shouldCollapse = true;
      } else if (effectiveVelocity < -200.0) {
        shouldCollapse = false;
      } else {
        shouldCollapse = _lastMoveDirectionDown;
      }

      if (shouldCollapse) {
        _animateAndDismiss(effectiveVelocity);
      } else {
        _animateSnapBack(effectiveVelocity);
      }
    }
  }

  void _animateAndDismiss([double velocity = 0]) {
    if (_isDismissing) return;
    _isDismissing = true;
    _isSnappingBack = false;

    final startY = _dragOffsetY;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final remainingDistance = (screenHeight - startY).clamp(0.0, screenHeight);

    // Spotify-style distance and velocity adaptive duration (~400-520ms):
    final distanceFraction = (remainingDistance / screenHeight).clamp(0.0, 1.0);
    final velocityReduction = velocity.abs() > 100.0
        ? (1.0 - (velocity.abs() / 4000.0).clamp(0.0, 0.45))
        : 1.0;
    final durationMs = (400 + 120 * distanceFraction * velocityReduction)
        .round()
        .clamp(380, 520);

    // Assign the new animation BEFORE updating controller to avoid evaluating stale animations
    _dragAnimation = Tween<double>(
      begin: startY,
      end: screenHeight,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.3, 0.0, 0.0, 1.0),
      ),
    );

    _animController.duration = Duration(milliseconds: durationMs);
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _animateSnapBack([double velocity = 0]) {
    final startY = _dragOffsetY;
    if (startY <= 0.5) {
      _animController.stop();
      _dragAnimation = null;
      _isSnappingBack = false;
      setState(() {
        _dragOffsetY = 0.0;
      });
      return;
    }

    if (_animController.isAnimating && _isSnappingBack) {
      // Already smoothly animating to 0.0; avoid stutter from mid-flight reset
      return;
    }
    _isSnappingBack = true;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final distance = startY.clamp(0.0, screenHeight);

    // Spotify-style distance and velocity adaptive duration (~400-520ms):
    final distanceFraction = (distance / screenHeight).clamp(0.0, 1.0);
    final velocityReduction = velocity.abs() > 100.0
        ? (1.0 - (velocity.abs() / 4000.0).clamp(0.0, 0.45))
        : 1.0;
    final durationMs = (400 + 120 * distanceFraction * velocityReduction)
        .round()
        .clamp(380, 520);

    // Assign the new animation BEFORE updating controller to avoid evaluating stale animations
    _dragAnimation = Tween<double>(
      begin: startY,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.3, 0.0, 0.0, 1.0),
      ),
    );

    _animController.duration = Duration(milliseconds: durationMs);
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final barrierDarkness = widget.barrierBaseAlpha *
        (1.0 - (_dragOffsetY / screenHeight).clamp(0.0, 1.0));

    return PopScope(
      canPop: !_isDismissing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isDismissing) {
          _animateAndDismiss();
        }
      },
      child: IgnorePointer(
        ignoring: _isDismissing,
        child: Scaffold(
          backgroundColor: Colors.black.withValues(alpha: barrierDarkness),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, _dragOffsetY),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _onSheetPointerDown,
                  onPointerUp: _onSheetPointerUp,
                  onPointerCancel: _onSheetPointerCancel,
                  child: widget.builder(context, this),
                ),
              ),
              if (_dragOffsetY > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _dragOffsetY,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onScrimPointerDown,
                    onPointerMove: _onScrimPointerMove,
                    onPointerUp: _onScrimPointerUp,
                    onPointerCancel: _onScrimPointerCancel,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
