import 'dart:math' as math;
import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Direct, line-by-line Dart implementation of Android's official
/// [android.widget.EdgeEffect](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/base/core/java/android/widget/EdgeEffect.java).
///
/// Implements the exact Android 12+ stretch overscroll physical constants,
/// state machine, damped harmonic oscillator equations, linear take-over settling,
/// and stretch vector damping.
class AndroidEdgeEffect {
  AndroidEdgeEffect();

  // EdgeEffect types
  static const int typeNone = -1;
  static const int typeGlow = 0;
  static const int typeStretch = 1;

  // EdgeEffect states
  static const int stateIdle = 0;
  static const int statePull = 1;
  static const int stateAbsorb = 2;
  static const int stateRecede = 3;
  static const int statePullDecay = 4;

  // AOSP Physical Constants
  static const double velocityThreshold = 0.01;
  static const double linearVelocityTakeOver = 200.0;
  static const double valueThreshold = 0.001;
  static const double linearDistanceTakeOver = 8.0;
  static const double naturalFrequency = 24.657;
  static const double dampingRatio = 0.98;
  static const double onAbsorbVelocityAdjustment = 13.0;

  static const double linearStretchIntensity = 0.016;
  static const double expStretchIntensity = 0.016;
  static const double scrollDistAffectedByExpStretch = 0.33;

  static const int recedeTime = 600;
  static const int pullTime = 167;
  static const int pullDecayTime = 2000;

  // State variables
  int _state = stateIdle;
  double _distance = 0.0;
  double _velocity = 0.0;
  double _pullDistance = 0.0;
  double _displacement = 0.5;
  double _targetDisplacement = 0.5;

  int _startTime = 0;
  double _duration = 0.0;

  double _width = 0.0;
  double _height = 0.0;

  int get state => _state;
  double get distance => _distance;
  double get velocity => _velocity;
  double get displacement => _displacement;
  double get targetDisplacement => _targetDisplacement;
  double get duration => _duration;
  double get width => _width;
  double get height => _height;
  bool get isFinished => _state == stateIdle;

  void setSize(double width, double height) {
    _width = width;
    _height = height;
  }

  void finish() {
    _state = stateIdle;
    _distance = 0.0;
    _velocity = 0.0;
  }

  /// Called when content is pulled away from an edge.
  /// Matches AOSP `onPull(float deltaDistance, float displacement)`.
  void onPull(double deltaDistance, [double displacement = 0.5, int? nowMillis]) {
    final int now = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    _targetDisplacement = displacement;
    _displacement = displacement;

    if (_state != statePull) {
      _pullDistance = _distance;
    }

    _state = statePull;
    _startTime = now;
    _duration = pullTime.toDouble();

    _pullDistance += deltaDistance;
    _pullDistance = math.min(1.0, _pullDistance);
    _distance = math.max(0.0, _pullDistance);
    _velocity = 0.0;

    if (_distance == 0.0) {
      _state = stateIdle;
    }
  }

  /// Pulls by [deltaDistance] and returns the consumed amount.
  /// Matches AOSP `onPullDistance(float deltaDistance, float displacement)`.
  double onPullDistance(double deltaDistance, [double displacement = 0.5, int? nowMillis]) {
    final double finalDistance = math.max(0.0, deltaDistance + _distance);
    final double delta = finalDistance - _distance;
    if (delta == 0.0 && _distance == 0.0) {
      return 0.0;
    }
    onPull(delta, displacement, nowMillis);
    return delta;
  }

  double getDistance() => _distance;

  /// Call when touch release occurs after being pulled.
  /// Matches AOSP `onRelease()`.
  void onRelease([int? nowMillis]) {
    _pullDistance = 0.0;
    if (_state != statePull && _state != statePullDecay) {
      return;
    }
    _state = stateRecede;
    _velocity = 0.0;
    _startTime = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    _duration = recedeTime.toDouble();
  }

  /// Call when absorbing an impact velocity from a fling reaching the boundary.
  /// Matches AOSP `onAbsorb(int velocity)`.
  void onAbsorb(double impactVelocity, [int? nowMillis]) {
    _state = stateRecede;
    _velocity = impactVelocity * onAbsorbVelocityAdjustment;
    _startTime = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// Evaluates the spring ODE differential equations for one tick.
  /// Matches AOSP `updateSpring()`.
  bool updateSpring([int? nowMillis]) {
    final int time = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    final double deltaT = (time - _startTime) / 1000.0;
    if (deltaT < 0.001) {
      return false;
    }
    _startTime = time;

    if (_height <= 0.0) {
      _distance = 0.0;
      _velocity = 0.0;
      _state = stateIdle;
      return false;
    }

    if (_velocity.abs() <= linearVelocityTakeOver &&
        (_distance * _height).abs() < linearDistanceTakeOver &&
        (_velocity * _distance <= 0.0)) {
      final double sign = _velocity == 0.0
          ? (_distance > 0.0 ? -1.0 : 1.0)
          : (_velocity > 0.0 ? 1.0 : -1.0);
      _velocity = sign * linearVelocityTakeOver;

      final double targetDistance = _distance + (_velocity * deltaT / _height);
      if ((_distance > 0.0 && targetDistance <= 0.0) ||
          (_distance < 0.0 && targetDistance >= 0.0)) {
        _distance = 0.0;
        _velocity = 0.0;
        _state = stateIdle;
      } else {
        _distance = targetDistance;
      }
      return !isFinished;
    }

    final double dampedFreq =
        naturalFrequency * math.sqrt(1.0 - dampingRatio * dampingRatio);

    final double cosCoeff = _distance * _height;
    final double sinCoeff = (1.0 / dampedFreq) *
        (dampingRatio * naturalFrequency * _distance * _height + _velocity);
    final double expFactor =
        math.exp(-dampingRatio * naturalFrequency * deltaT);

    final double distance = expFactor *
        (cosCoeff * math.cos(dampedFreq * deltaT) +
            sinCoeff * math.sin(dampedFreq * deltaT));
    final double velocity = distance * (-naturalFrequency) * dampingRatio +
        expFactor *
            (-dampedFreq * cosCoeff * math.sin(dampedFreq * deltaT) +
                dampedFreq * sinCoeff * math.cos(dampedFreq * deltaT));

    _distance = distance / _height;
    _velocity = velocity;

    if (_distance > 1.0) {
      _distance = 1.0;
      _velocity = 0.0;
    }

    if (isAtEquilibrium()) {
      _distance = 0.0;
      _velocity = 0.0;
      _state = stateIdle;
    }

    return !isFinished;
  }

  bool isAtEquilibrium() {
    final double displacement = _distance * _height;
    final double velocityVal = _velocity;

    return displacement < 0.0 ||
        (velocityVal.abs() < velocityThreshold && displacement < valueThreshold);
  }

  double dampStretchVector(double normalizedVec) {
    if (normalizedVec == 0.0) return 0.0;
    final double sign = normalizedVec > 0.0 ? 1.0 : -1.0;
    final double overscroll = normalizedVec.abs();
    final double linearIntensity = linearStretchIntensity * overscroll;
    final double scalar = math.e / scrollDistAffectedByExpStretch;
    final double expIntensity =
        expStretchIntensity * (1.0 - math.exp(-overscroll * scalar));
    return sign * (linearIntensity + expIntensity);
  }

  double getDampedStretch() {
    return dampStretchVector(_distance);
  }
}

/// Official Android EdgeEffect stretch overscroll controller.
///
/// Uses an unbounded [AnimationController] with an authentic [SpringSimulation]
/// derived directly from Android's `EdgeEffect.java` physical constants
/// (naturalFrequency = 24.657, dampingRatio = 0.98, timeCorrection = 0.8).
class SpotifyStretchController extends Listenable {
  SpotifyStretchController({required this.vsync});

  final TickerProvider vsync;
  AnimationController? _controller;

  final ValueNotifier<double> _overscrollNotifier = ValueNotifier<double>(0.0);
  double get overscroll => _overscrollNotifier.value;
  set overscroll(double newValue) {
    _overscrollNotifier.value = clampDouble(newValue, minOverscroll, maxOverscroll);
  }

  double _interruptedOverscroll = 0.0;

  static const double _exponentialScalar = math.e / 0.33;
  static const double _stretchIntensity = 0.016;

  static const double minOverscroll = -1.0;
  static const double maxOverscroll = 1.0;

  static const double _flingVelocityFriction = 1 / 6000;
  static const double _absorbImpactVelocityFriction = 1 / 3000;
  static const double _maxFlingVelocity = 0.5;
  static const double _maxAbsorbImpactVelocity = 1.25;

  static const double kNaturalFrequency = 24.657;
  static const double kDampingRatio = 0.98;
  static const double kTimeCorrectionFactor = 0.8;
  static const double kStiffness = kNaturalFrequency * kNaturalFrequency;

  static final SpringDescription _kStretchSpringDescription =
      SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: kStiffness * kTimeCorrectionFactor * kTimeCorrectionFactor,
    ratio: kDampingRatio,
  );

  @override
  void addListener(VoidCallback listener) {
    _overscrollNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _overscrollNotifier.removeListener(listener);
  }

  SpringSimulation _createStretchSimulation(double velocity) {
    return SpringSimulation(
      _kStretchSpringDescription,
      overscroll,
      0.0,
      velocity * kTimeCorrectionFactor,
    );
  }

  void pull(double normalizedOverscroll) {
    if (_controller != null) {
      _interruptedOverscroll = _controller!.value;
      _controller!.dispose();
      _controller = null;
    }

    final double pullDistance = normalizedOverscroll;
    final double absDistance = pullDistance.abs();
    final double linearIntensity = _stretchIntensity * absDistance;
    final double exponentialIntensity =
        _stretchIntensity * (1 - math.exp(-absDistance * _exponentialScalar));

    final double directionSign = pullDistance.sign;
    final double newOverscroll =
        directionSign * (linearIntensity + exponentialIntensity);
    overscroll = newOverscroll + _interruptedOverscroll;
  }

  void scrollEnd(double velocity) {
    if (velocity == 0.0 && overscroll == 0.0) {
      return;
    }
    final double scaledVelocity = clampDouble(
      -(velocity * _flingVelocityFriction),
      -_maxFlingVelocity,
      _maxFlingVelocity,
    );

    animate(_createStretchSimulation(scaledVelocity));
  }

  void absorbImpact(double velocity) {
    if (velocity == 0.0) {
      return;
    }
    final double scaledVelocity = clampDouble(
      velocity * _absorbImpactVelocityFriction,
      -_maxAbsorbImpactVelocity,
      _maxAbsorbImpactVelocity,
    );

    animate(_createStretchSimulation(scaledVelocity));
  }

  void animate(Simulation simulation) {
    _controller?.dispose();
    final controller = AnimationController.unbounded(vsync: vsync);
    _controller = controller;

    controller
      ..addListener(() {
        overscroll = controller.value;
      })
      ..animateWith(simulation).whenComplete(() {
        overscroll = 0.0;
        _interruptedOverscroll = 0.0;
        controller.dispose();
        if (_controller == controller) {
          _controller = null;
        }
      });
  }

  void finish() {
    _controller?.dispose();
    _controller = null;
    overscroll = 0.0;
    _interruptedOverscroll = 0.0;
  }

  void dispose() {
    _controller?.dispose();
    _overscrollNotifier.dispose();
  }
}

/// Scroll behavior providing Spotify-native Android stretch overscroll.
class SpotifyStretchScrollBehavior extends MaterialScrollBehavior {
  const SpotifyStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return SpotifyStretchOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

/// Enhanced overscroll indicator replicating native Spotify Android stretch.
///
/// Features:
/// 1. Follows pointer into overscroll with logarithmic/exponential stretch.
/// 2. Smoothly contracts when dragging back in opposite direction without lifting finger.
/// 3. Automatically rebounds cleanly to 0.0 via authentic AOSP spring simulation upon touch lift.
/// 4. Absorbs momentum from fling impacts at viewport boundaries.
class SpotifyStretchOverscrollIndicator extends StatefulWidget {
  const SpotifyStretchOverscrollIndicator({
    super.key,
    required this.axisDirection,
    required this.child,
    this.controller,
  });

  final AxisDirection axisDirection;
  final Widget child;
  final SpotifyStretchController? controller;

  Axis get axis => axisDirectionToAxis(axisDirection);

  @override
  State<SpotifyStretchOverscrollIndicator> createState() =>
      SpotifyStretchOverscrollIndicatorState();
}

class SpotifyStretchOverscrollIndicatorState
    extends State<SpotifyStretchOverscrollIndicator>
    with TickerProviderStateMixin {
  late SpotifyStretchController _internalController;
  SpotifyStretchController get controller =>
      widget.controller ?? _internalController;

  double _totalOverscroll = 0.0;
  final Set<int> _activePointers = <int>{};

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = SpotifyStretchController(vsync: this);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    // ONLY when all pointers have left the surface do we trigger release rebound:
    if (_activePointers.isEmpty && controller.overscroll != 0.0) {
      _totalOverscroll = 0.0;
      controller.scrollEnd(0.0);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty && controller.overscroll != 0.0) {
      _totalOverscroll = 0.0;
      controller.scrollEnd(0.0);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != widget.axis) return false;

    final viewport = notification.metrics.viewportDimension;
    if (viewport <= 0) return false;

    // When an external controller is passed (e.g. from SpotifyPeekScrollPosition),
    // drag-driven pulls and reversals are coordinated directly by ScrollPosition
    // to prevent simultaneous list scrolling. Only ballistic flings reaching boundaries
    // need impact absorption here.
    if (widget.controller != null) {
      if (notification is OverscrollNotification && notification.velocity != 0.0) {
        controller.absorbImpact(notification.velocity);
      }
      return false;
    }

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null && controller.overscroll == 0.0) {
        _totalOverscroll = 0.0;
      }
    } else if (notification is OverscrollNotification) {
      if (notification.velocity != 0.0) {
        _totalOverscroll = 0.0;
        controller.absorbImpact(notification.velocity);
      } else if (notification.dragDetails != null) {
        _totalOverscroll += notification.overscroll;
        final double distanceForPull = _totalOverscroll / viewport;
        final double clampedOverscroll = clampDouble(distanceForPull, -1.0, 1.0);
        controller.pull(clampedOverscroll);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (_totalOverscroll != 0.0 && notification.dragDetails != null) {
        final double delta = notification.scrollDelta ?? 0.0;
        if (delta != 0.0) {
          final double previousSign = _totalOverscroll.sign;
          final double updatedTotal = _totalOverscroll + delta;

          if (updatedTotal.sign != previousSign || updatedTotal.abs() < 0.5) {
            _totalOverscroll = 0.0;
            controller.finish();
          } else {
            _totalOverscroll = updatedTotal;
            final double distanceForPull = _totalOverscroll / viewport;
            final double clampedOverscroll = clampDouble(distanceForPull, -1.0, 1.0);
            controller.pull(clampedOverscroll);
          }
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_activePointers.isNotEmpty) {
        // Multi-touch handoff: other pointers are still down, do not end rebound!
        return false;
      }

      double velocity = switch (widget.axis) {
        Axis.vertical =>
          notification.dragDetails?.velocity.pixelsPerSecond.dy ?? 0.0,
        Axis.horizontal =>
          notification.dragDetails?.velocity.pixelsPerSecond.dx ?? 0.0,
      };

      if (notification.metrics.axisDirection == AxisDirection.left ||
          notification.metrics.axisDirection == AxisDirection.up) {
        velocity = -velocity;
      }

      _totalOverscroll = 0.0;
      controller.scrollEnd(velocity);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final double stretch = controller.overscroll;
            double overscroll = -stretch;

            if (widget.axisDirection == AxisDirection.up ||
                widget.axisDirection == AxisDirection.left) {
              overscroll = -overscroll;
            }

            return StretchEffect(
              stretchStrength: overscroll,
              axis: widget.axis,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}
