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

  @override
  double get dragOffsetY => _dragOffsetY;

  @override
  bool get isDismissing => _isDismissing;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void onPullDelta(double delta) {
    if (_isDismissing) return;
    setState(() {
      _dragOffsetY = (_dragOffsetY + delta).clamp(0.0, double.infinity);
    });
  }

  @override
  void onPullEnd(double velocity) {
    if (_isDismissing) return;
    if (_dragOffsetY > 0) {
      if (_dragOffsetY > widget.dismissDistanceThreshold ||
          velocity > widget.dismissVelocityThreshold) {
        _animateAndDismiss(velocity);
      } else {
        _animateSnapBack();
      }
    }
  }

  @override
  void dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    Navigator.of(context).pop();
  }

  void _animateAndDismiss([double velocity = 0]) {
    if (_isDismissing) return;
    _isDismissing = true;

    final startY = _dragOffsetY;
    final screenHeight = MediaQuery.sizeOf(context).height;

    _animController.reset();
    _dragAnimation = Tween<double>(
      begin: startY,
      end: screenHeight,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.3, 0.0, 0.0, 1.0),
      ),
    )..addListener(() {
        setState(() {
          _dragOffsetY = _dragAnimation!.value;
        });
      });

    _animController.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _animateSnapBack() {
    final startY = _dragOffsetY;
    _animController.reset();
    _dragAnimation = Tween<double>(
      begin: startY,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        setState(() {
          _dragOffsetY = _dragAnimation!.value;
        });
      });

    _animController.forward();
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
          body: Transform.translate(
            offset: Offset(0, _dragOffsetY),
            child: widget.builder(context, this),
          ),
        ),
      ),
    );
  }
}
