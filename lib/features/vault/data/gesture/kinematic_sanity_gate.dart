import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';

/// Exhaustive sealed decision type emitted by [KinematicSanityGate].
///
/// Encapsulates the kinematic validation outcome with zero loose booleans.
@immutable
sealed class KinematicGateDecision extends Equatable {
  const KinematicGateDecision();

  /// Whether this decision represents a successful gate passage.
  bool get isPassed => switch (this) {
        KinematicGatePassed() => true,
        KinematicGateRejected() => false,
      };

  /// Maps the kinematic result to the domain recognition decision enum.
  GestureMatchDecisionEnum get domainDecision => switch (this) {
        KinematicGatePassed() => GestureMatchDecisionEnum.matched,
        KinematicGateRejected() =>
          GestureMatchDecisionEnum.rejectedAntiScribble,
      };
}

/// Variant indicating the gesture passed all 4 kinematic sanity checks.
final class KinematicGatePassed extends KinematicGateDecision {
  const KinematicGatePassed();

  @override
  List<Object?> get props => const [];
}

/// Variant indicating the gesture was rejected during one of the kinematic sanity stages.
final class KinematicGateRejected extends KinematicGateDecision {
  /// Typed diagnostic failure reason.
  final KinematicRejectionReason reason;

  /// Human-readable diagnostic details including measured metrics and thresholds.
  final String details;

  const KinematicGateRejected({
    required this.reason,
    required this.details,
  });

  @override
  List<Object?> get props => [reason, details];
}

/// Explicit enumerated diagnostic reasons for kinematic rejection.
enum KinematicRejectionReason {
  /// Raw point count below minimum limit (n < 10).
  insufficientPoints(
    id: 'INSUFFICIENT_POINTS',
    displayName: 'Stroke point count below minimum density bound',
  ),

  /// Raw point count above maximum limit (n > 800).
  excessivePoints(
    id: 'EXCESSIVE_POINTS',
    displayName: 'Stroke point count exceeded maximum density bound',
  ),

  /// Bounding span max(Delta x, Delta y) < 28.0px.
  insufficientBoundingSpan(
    id: 'INSUFFICIENT_BOUNDING_SPAN',
    displayName: 'Bounding box span smaller than 28.0px',
  ),

  /// Stroke path length was zero or non-positive.
  zeroPathLength(
    id: 'ZERO_PATH_LENGTH',
    displayName: 'Total stroke trajectory length is zero or non-positive',
  ),

  /// Closed dense looping stroke where D_net < 5.0px and L_raw > 50.0px.
  closedLoopScribble(
    id: 'CLOSED_LOOP_SCRIBBLE',
    displayName: 'Closed loop scribble detected with near-zero displacement',
  ),

  /// Tortuosity ratio L_raw / max(D_net, 1.0) exceeded threshold.
  excessiveTortuosity(
    id: 'EXCESSIVE_TORTUOSITY',
    displayName:
        'Stroke tortuosity ratio exceeded maximum straightness envelope',
  ),

  /// Cumulative directional turning angle exceeded angular budget.
  excessiveCurvature(
    id: 'EXCESSIVE_CURVATURE',
    displayName: 'Cumulative turning angle exceeded angular curvature budget',
  );

  final String id;
  final String displayName;

  const KinematicRejectionReason({
    required this.id,
    required this.displayName,
  });
}

/// Production implementation of the sub-0.1ms kinematic sanity and anti-scribble gate.
///
/// Executes 4 sequential fail-fast checks:
/// 1. Point Density Bounds: rejects strokes with n < 10 or n > 800.
/// 2. Bounding Box Span: rejects strokes with max(Delta x, Delta y) < 28.0px.
/// 3. Tortuosity Envelope: rejects strokes with raw length <= 0, closed loop scribbles,
///    or L_raw / max(D_net, 1.0) > 12.0.
/// 4. Cumulative Turning Angle: rejects strokes with total turning angle > 8*pi radians.
@immutable
class KinematicSanityGate {
  /// Minimum bounding span in logical pixels (default: 28.0px).
  final double minBoundingSpan;

  /// Minimum raw point count (default: 10).
  final int minPointCount;

  /// Maximum raw point count (default: 800).
  final int maxPointCount;

  /// Maximum allowable tortuosity ratio L_raw / max(D_net, 1.0) (default: 12.0).
  final double maxTortuosityRatio;

  /// Maximum cumulative turning angle in radians (default: 8*pi ~ 25.1327 rad).
  final double maxCumulativeTurningAngleRad;

  /// Maximum net displacement threshold for detecting closed-loop scribbles (default: 5.0px).
  final double closedLoopMaxDisplacement;

  /// Minimum path length threshold for detecting closed-loop scribbles (default: 50.0px).
  final double closedLoopMinPathLength;

  /// Constructs a validated [KinematicSanityGate] instance.
  const KinematicSanityGate({
    this.minBoundingSpan = 28.0,
    this.minPointCount = 10,
    this.maxPointCount = 800,
    this.maxTortuosityRatio = 12.0,
    this.maxCumulativeTurningAngleRad = 8.0 * math.pi,
    this.closedLoopMaxDisplacement = 5.0,
    this.closedLoopMinPathLength = 50.0,
  })  : assert(minBoundingSpan > 0.0, 'minBoundingSpan must be positive'),
        assert(minPointCount > 0, 'minPointCount must be positive'),
        assert(
          maxPointCount >= minPointCount,
          'maxPointCount must be >= minPointCount',
        ),
        assert(maxTortuosityRatio >= 1.0, 'maxTortuosityRatio must be >= 1.0'),
        assert(
          maxCumulativeTurningAngleRad > 0.0,
          'maxCumulativeTurningAngleRad must be positive',
        ),
        assert(
          closedLoopMaxDisplacement >= 0.0,
          'closedLoopMaxDisplacement must be non-negative',
        ),
        assert(
          closedLoopMinPathLength > 0.0,
          'closedLoopMinPathLength must be positive',
        );

  /// Standard pre-configured gate instance.
  static const KinematicSanityGate standard = KinematicSanityGate();

  /// Evaluates the kinematic properties of [rawPoints].
  ///
  /// Returns [KinematicGatePassed] if all 4 checks pass, or [KinematicGateRejected]
  /// with detailed diagnostic failure reason upon the first failed condition.
  KinematicGateDecision evaluate(List<GesturePoint> rawPoints) {
    final n = rawPoints.length;

    // Check 1: Point Density Budget (O(1))
    if (n < minPointCount) {
      return KinematicGateRejected(
        reason: KinematicRejectionReason.insufficientPoints,
        details: 'Point count $n is below minimum threshold of $minPointCount',
      );
    }
    if (n > maxPointCount) {
      return KinematicGateRejected(
        reason: KinematicRejectionReason.excessivePoints,
        details:
            'Point count $n exceeds maximum density limit of $maxPointCount',
      );
    }

    // Check 2: Bounding Box Span (O(n) comparisons, zero sqrt)
    double minX = rawPoints[0].x;
    double maxX = rawPoints[0].x;
    double minY = rawPoints[0].y;
    double maxY = rawPoints[0].y;

    for (int i = 1; i < n; i++) {
      final p = rawPoints[i];
      if (p.x < minX) {
        minX = p.x;
      }
      if (p.x > maxX) {
        maxX = p.x;
      }
      if (p.y < minY) {
        minY = p.y;
      }
      if (p.y > maxY) {
        maxY = p.y;
      }
    }

    final deltaX = maxX - minX;
    final deltaY = maxY - minY;
    final span = math.max(deltaX, deltaY);

    if (span < minBoundingSpan) {
      return KinematicGateRejected(
        reason: KinematicRejectionReason.insufficientBoundingSpan,
        details:
            'Bounding span ${span.toStringAsFixed(2)}px is smaller than threshold ${minBoundingSpan}px',
      );
    }

    // Fused Pass 2 (Path Length) & Pass 3 (Cumulative Turning Angle)
    // Traverses polyline once in O(n), sharing vector subtractions (dx, dy),
    // segment squared distances, and eliminating 799 duplicate math passes.
    double lRaw = 0.0;
    double cumulativeTurningAngle = 0.0;
    double? previousHeading;

    for (int i = 0; i < n - 1; i++) {
      final pCurrent = rawPoints[i];
      final pNext = rawPoints[i + 1];
      final dx = pNext.x - pCurrent.x;
      final dy = pNext.y - pCurrent.y;
      final segDistSquared = (dx * dx) + (dy * dy);

      // Skip coincident / sub-micro-pixel jitter points for angle calculation
      if (segDistSquared < 1e-12) {
        continue;
      }

      lRaw += math.sqrt(segDistSquared);
      final heading = math.atan2(dy, dx);

      if (previousHeading != null) {
        double deltaTheta = heading - previousHeading;

        // Wrap to [-pi, +pi]
        if (deltaTheta > math.pi) {
          deltaTheta -= 2.0 * math.pi;
        } else if (deltaTheta < -math.pi) {
          deltaTheta += 2.0 * math.pi;
        }

        cumulativeTurningAngle += deltaTheta.abs();

        // Fail fast: early break the moment budget is exhausted
        if (cumulativeTurningAngle > maxCumulativeTurningAngleRad) {
          return KinematicGateRejected(
            reason: KinematicRejectionReason.excessiveCurvature,
            details:
                'Cumulative turning angle ${cumulativeTurningAngle.toStringAsFixed(2)} rad exceeded budget of ${maxCumulativeTurningAngleRad.toStringAsFixed(2)} rad',
          );
        }
      }

      previousHeading = heading;
    }

    if (lRaw <= 0.0) {
      return const KinematicGateRejected(
        reason: KinematicRejectionReason.zeroPathLength,
        details: 'Trajectory path length is zero or non-positive',
      );
    }

    // Post-loop Check 3: Straightness / Tortuosity Envelope
    final pFirst = rawPoints[0];
    final pLast = rawPoints[n - 1];
    final dNetX = pLast.x - pFirst.x;
    final dNetY = pLast.y - pFirst.y;
    final dNet = math.sqrt((dNetX * dNetX) + (dNetY * dNetY));

    // Closed loop dense scribble check
    if (dNet < closedLoopMaxDisplacement && lRaw > closedLoopMinPathLength) {
      return KinematicGateRejected(
        reason: KinematicRejectionReason.closedLoopScribble,
        details:
            'Closed loop detected: D_net=${dNet.toStringAsFixed(2)}px < ${closedLoopMaxDisplacement}px with L_raw=${lRaw.toStringAsFixed(2)}px',
      );
    }

    // Guard denominator with 1.0px epsilon
    final effectiveDNet = math.max(dNet, 1.0);
    final tortuosity = lRaw / effectiveDNet;

    if (tortuosity > maxTortuosityRatio) {
      return KinematicGateRejected(
        reason: KinematicRejectionReason.excessiveTortuosity,
        details:
            'Tortuosity ratio ${tortuosity.toStringAsFixed(2)} exceeds threshold of $maxTortuosityRatio',
      );
    }

    return const KinematicGatePassed();
  }

  /// Convenience boolean evaluator for high-speed gating pipelines.
  bool isValid(List<GesturePoint> rawPoints) => evaluate(rawPoints).isPassed;
}
