import 'dart:math' as math;

import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Pure mathematical utility for equidistant arc-length resampling of stroke trajectories.
///
/// Implements Job 3 of the Stealth Gesture Pipeline (Harel Region D: Gesture Engine).
/// Resamples arbitrary stroke polylines into an exact deterministic sequence of [targetCount]
/// points (defaults to 64) with uniform spatial intervals along the trajectory contour.
abstract final class GestureResampler {
  /// Resamples [points] into an unmodifiable list of exactly [targetCount] equidistant points.
  ///
  /// Anchors the initial point (R_1 = P_1) and terminal point (R_N = P_n).
  ///
  /// Throws [FormatException] if:
  /// - [points] contains fewer than 2 points.
  /// - [targetCount] is less than 2.
  /// - Cumulative trajectory length L <= 0.0 (coincident or zero-motion stroke).
  /// - Any coordinate is NaN or infinite.
  static List<GesturePoint> resample(
    List<GesturePoint> points, {
    int targetCount = GestureTemplate.requiredPointCount,
  }) {
    if (points.length < 2) {
      throw FormatException(
        'GestureResampler requires at least 2 points to resample, got: ${points.length}',
      );
    }
    if (targetCount < 2) {
      throw FormatException(
        'GestureResampler targetCount must be at least 2, got: $targetCount',
      );
    }

    // 1. Calculate cumulative path length L
    final double totalLength = computePathLength(points);
    if (totalLength <= 0.0 || totalLength.isNaN || totalLength.isInfinite) {
      throw FormatException(
        'GestureResampler: Cumulative path length must be strictly positive and finite, got: $totalLength',
      );
    }

    // 2. Compute uniform spatial step interval I = L / (N - 1)
    final double interval = totalLength / (targetCount - 1);
    if (interval <= 0.0 || interval.isNaN || interval.isInfinite) {
      throw FormatException(
        'GestureResampler: Computed step interval must be strictly positive and finite, got: $interval',
      );
    }

    // 3. Accumulator-based linear segment interpolation
    final List<GesturePoint> resampled = <GesturePoint>[];
    resampled.add(points.first);

    double accumulatedDistance = 0.0;
    double currentSegmentStartX = points.first.x;
    double currentSegmentStartY = points.first.y;
    double currentSegmentStartT = points.first.timestampMs.toDouble();

    for (int i = 1;
        i < points.length && resampled.length < targetCount - 1;
        i++) {
      final GesturePoint target = points[i];
      final double targetX = target.x;
      final double targetY = target.y;
      final double targetT = target.timestampMs.toDouble();

      double segDx = targetX - currentSegmentStartX;
      double segDy = targetY - currentSegmentStartY;
      double segDist = math.sqrt((segDx * segDx) + (segDy * segDy));

      if (segDist < 1e-12) {
        // Skip coincident points to avoid division by zero
        continue;
      }

      while (accumulatedDistance + segDist >= interval &&
          resampled.length < targetCount - 1) {
        final double distanceToNext = interval - accumulatedDistance;
        final double t = distanceToNext / segDist;

        final double interpX =
            currentSegmentStartX + (t * (targetX - currentSegmentStartX));
        final double interpY =
            currentSegmentStartY + (t * (targetY - currentSegmentStartY));
        final double interpT =
            currentSegmentStartT + (t * (targetT - currentSegmentStartT));

        resampled.add(GesturePoint(
          x: interpX,
          y: interpY,
          timestampMs: interpT.round(),
        ));

        // Advance current segment start to interpolated point
        currentSegmentStartX = interpX;
        currentSegmentStartY = interpY;
        currentSegmentStartT = interpT;
        segDist -= distanceToNext;
        accumulatedDistance = 0.0;
      }

      accumulatedDistance += segDist;
      currentSegmentStartX = targetX;
      currentSegmentStartY = targetY;
      currentSegmentStartT = targetT;
    }

    // 4. Handle edge cases where floating point truncation produced < targetCount - 1
    while (resampled.length < targetCount - 1) {
      final GesturePoint last = resampled.last;
      final GesturePoint end = points.last;
      final int remainingNeeded = (targetCount - 1) - resampled.length;
      final double t = 1.0 / (remainingNeeded + 1);

      final double interpX = last.x + (t * (end.x - last.x));
      final double interpY = last.y + (t * (end.y - last.y));
      final double interpT =
          last.timestampMs + (t * (end.timestampMs - last.timestampMs));

      resampled.add(GesturePoint(
        x: interpX,
        y: interpY,
        timestampMs: interpT.round(),
      ));
    }

    // 5. Always anchor terminal point as the final point
    resampled.add(points.last);

    return List<GesturePoint>.unmodifiable(resampled);
  }

  /// Calculates total Euclidean path length along polyline points.
  static double computePathLength(List<GesturePoint> points) {
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final double dx = points[i + 1].x - points[i].x;
      final double dy = points[i + 1].y - points[i].y;
      total += math.sqrt((dx * dx) + (dy * dy));
    }
    return total;
  }
}
