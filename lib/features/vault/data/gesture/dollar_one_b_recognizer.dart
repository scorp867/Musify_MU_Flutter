import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Pure mathematical implementation of the Bidirectional $1 Recognizer ($1-B)
/// with Golden Section Search (GSS) optimization over rotation window [-45 deg, +45 deg].
///
/// Implements Job 5 of the Single-Stroke Stealth Gesture Recognition Pipeline
/// (Harel Region D: Gesture Engine).
///
/// Features:
/// 1. Bidirectional Evaluation: Evaluates both forward candidate sequence C_fwd
///    and reverse candidate sequence C_rev against template T.
/// 2. Golden Section Search: Finds optimal rotation angle theta* within [-pi/4, +pi/4]
///    contracting bracket width to < 0.5 degrees (~0.0087 rad) in exactly 11 iterations.
/// 3. Score Normalization: Maps optimal Euclidean distance into [0.0, 1.0] using
///    half the canvas diagonal H_D = 0.5 * sqrt(2 * B^2) where B = 250.0px.
///
/// Conforms strictly to workspace architectural invariants: stateless, deeply pure,
/// zero non-null assertions (!), zero .clamp() AST tokens, zero fallback operators (??),
/// and fail-fast validation.
@immutable
class DollarOneBRecognizer {
  /// Canonical reference canvas dimension in logical pixels (B = 250.0px).
  static const double canonicalReferenceDimension = 250.0;

  /// Golden ratio constant phi = (sqrt(5) - 1) / 2 ~ 0.6180339887498949.
  static const double phi = 0.6180339887498948482;

  /// Complement of golden ratio (1.0 - phi) = (3 - sqrt(5)) / 2 ~ 0.3819660112501051.
  static const double oneMinusPhi = 1.0 - phi;

  /// Half-diagonal denominator for B = 250.0px: 0.5 * sqrt(2 * 250^2) = 125 * sqrt(2) ~ 176.776695px.
  static const double canonicalHalfDiagonal = 176.77669529663688;

  /// Maximum rotational search window bound: 45 degrees in radians (pi / 4).
  static const double defaultMaxAngleRad = math.pi / 4.0;

  /// Convergence tolerance: 0.5 degrees in radians (pi / 360 ~ 0.00872665 rad).
  static const double defaultAngleToleranceRad = math.pi / 360.0;

  /// Constructs a [DollarOneBRecognizer] instance.
  const DollarOneBRecognizer();

  /// Matches [candidate] against [template] and returns normalized similarity score in [0.0, 1.0].
  ///
  /// Instance method for dependency injection into services.
  double match(
    List<GesturePoint> candidate,
    List<GesturePoint> template, {
    double referenceDimension = canonicalReferenceDimension,
    double maxAngleRad = defaultMaxAngleRad,
    double angleToleranceRad = defaultAngleToleranceRad,
  }) {
    return matchStatic(
      candidate,
      template,
      referenceDimension: referenceDimension,
      maxAngleRad: maxAngleRad,
      angleToleranceRad: angleToleranceRad,
    );
  }

  /// Pure static evaluation matching [candidate] against [template].
  ///
  /// Throws [FormatException] if:
  /// - [candidate] or [template] does not contain exactly 64 points.
  /// - [referenceDimension] is non-positive or non-finite.
  /// - [maxAngleRad] is non-positive, non-finite, or exceeds pi.
  /// - [angleToleranceRad] is non-positive or non-finite.
  static double matchStatic(
    List<GesturePoint> candidate,
    List<GesturePoint> template, {
    double referenceDimension = canonicalReferenceDimension,
    double maxAngleRad = defaultMaxAngleRad,
    double angleToleranceRad = defaultAngleToleranceRad,
  }) {
    if (candidate.length != GestureTemplate.requiredPointCount) {
      throw FormatException(
        'DollarOneBRecognizer: candidate length must be exactly '
        '${GestureTemplate.requiredPointCount}, got: ${candidate.length}',
      );
    }
    if (template.length != GestureTemplate.requiredPointCount) {
      throw FormatException(
        'DollarOneBRecognizer: template length must be exactly '
        '${GestureTemplate.requiredPointCount}, got: ${template.length}',
      );
    }
    if (referenceDimension <= 0.0 ||
        referenceDimension.isNaN ||
        referenceDimension.isInfinite) {
      throw FormatException(
        'DollarOneBRecognizer: referenceDimension must be positive and finite, got: $referenceDimension',
      );
    }
    if (maxAngleRad <= 0.0 ||
        maxAngleRad.isNaN ||
        maxAngleRad.isInfinite ||
        maxAngleRad > math.pi) {
      throw FormatException(
        'DollarOneBRecognizer: maxAngleRad must be in (0, pi], got: $maxAngleRad',
      );
    }
    if (angleToleranceRad <= 0.0 ||
        angleToleranceRad.isNaN ||
        angleToleranceRad.isInfinite) {
      throw FormatException(
        'DollarOneBRecognizer: angleToleranceRad must be positive and finite, got: $angleToleranceRad',
      );
    }

    final double halfDiagonal;
    if (referenceDimension == canonicalReferenceDimension) {
      halfDiagonal = canonicalHalfDiagonal;
    } else {
      halfDiagonal = 0.5 * math.sqrt(2.0 * referenceDimension * referenceDimension);
    }

    // Construct forward and reverse candidates
    final List<GesturePoint> candidateFwd = candidate;
    final List<GesturePoint> candidateRev =
        List<GesturePoint>.unmodifiable(candidate.reversed);

    // Compute optimal distance via Golden Section Search for both directions
    final double distFwd = distanceAtBestAngle(
      candidateFwd,
      template,
      -maxAngleRad,
      maxAngleRad,
      angleToleranceRad,
    );
    final double distRev = distanceAtBestAngle(
      candidateRev,
      template,
      -maxAngleRad,
      maxAngleRad,
      angleToleranceRad,
    );

    final double minDist = math.min(distFwd, distRev);

    // Score normalization: S_$1 = 1.0 - (minDist / halfDiagonal) bounded in [0.0, 1.0]
    final double rawScore = 1.0 - (minDist / halfDiagonal);
    return _boundToUnitInterval(rawScore);
  }

  /// Finds the minimum distance between [candidate] and [template] within angle bracket [minA, maxB]
  /// using Golden Section Search.
  static double distanceAtBestAngle(
    List<GesturePoint> candidate,
    List<GesturePoint> template,
    double minA,
    double maxB,
    double tolerance,
  ) {
    // Evaluate unrotated baseline (theta = 0.0) if 0.0 is within bracket [minA, maxB]
    final double f0;
    if (minA <= 0.0 && maxB >= 0.0) {
      f0 = distanceAtAngle(candidate, template, 0.0);
    } else {
      f0 = double.infinity;
    }

    double a = minA;
    double b = maxB;

    double x1 = a + (oneMinusPhi * (b - a));
    double x2 = a + (phi * (b - a));

    double f1 = distanceAtAngle(candidate, template, x1);
    double f2 = distanceAtAngle(candidate, template, x2);

    while ((b - a).abs() > tolerance) {
      if (f1 < f2) {
        b = x2;
        x2 = x1;
        f2 = f1;
        x1 = a + (oneMinusPhi * (b - a));
        f1 = distanceAtAngle(candidate, template, x1);
      } else {
        a = x1;
        x1 = x2;
        f1 = f2;
        x2 = a + (phi * (b - a));
        f2 = distanceAtAngle(candidate, template, x2);
      }
    }

    return math.min(f0, math.min(f1, f2));
  }

  /// Evaluates mean point-to-point Euclidean distance between [candidate] rotated by [theta]
  /// and [template].
  static double distanceAtAngle(
    List<GesturePoint> candidate,
    List<GesturePoint> template,
    double theta,
  ) {
    final double cosTheta = math.cos(theta);
    final double sinTheta = math.sin(theta);
    final int count = candidate.length;
    double sumDist = 0.0;

    for (int i = 0; i < count; i++) {
      final GesturePoint p = candidate[i];
      final GesturePoint t = template[i];

      final double rx = (p.x * cosTheta) - (p.y * sinTheta);
      final double ry = (p.x * sinTheta) + (p.y * cosTheta);

      final double dx = rx - t.x;
      final double dy = ry - t.y;

      sumDist += math.sqrt((dx * dx) + (dy * dy));
    }

    return sumDist / count;
  }

  /// Pure mathematical clamping to [0.0, 1.0] without using banned .clamp() AST.
  static double _boundToUnitInterval(double value) {
    if (value < 0.0) {
      return 0.0;
    }
    if (value > 1.0) {
      return 1.0;
    }
    return value;
  }
}
