import 'package:flutter/material.dart';

/// Scroll physics that caps the maximum fling velocity.
///
/// No matter how hard the user flings, the scroll velocity won't
/// exceed [maxVelocity] pixels/second. Normal slow scrolls are
/// unaffected -- only fast flings get clamped.
class VelocityCappedScrollPhysics extends ScrollPhysics {
  final double maxVelocity;

  const VelocityCappedScrollPhysics({
    this.maxVelocity = 3000.0,
    super.parent,
  });

  @override
  VelocityCappedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return VelocityCappedScrollPhysics(
      maxVelocity: maxVelocity,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final clamped = velocity.clamp(-maxVelocity, maxVelocity);
    return super.createBallisticSimulation(position, clamped);
  }
}

/// App-wide scroll behavior that applies the velocity cap.
///
/// Set on MaterialApp:
/// ```dart
/// MaterialApp(
///   scrollBehavior: AppScrollBehavior(),
/// )
/// ```
class AppScrollBehavior extends MaterialScrollBehavior {
  final double maxVelocity;

  const AppScrollBehavior({this.maxVelocity = 3000.0});

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return VelocityCappedScrollPhysics(
      maxVelocity: maxVelocity,
      parent: super.getScrollPhysics(context),
    );
  }
}
