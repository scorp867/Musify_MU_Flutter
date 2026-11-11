import 'dart:math' as math;

import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Strongly-typed classification of stroke dimensionality based on aspect ratio envelope.
enum GestureDimensionalityType {
  /// 1D stroke (aspect ratio < 0.20): e.g. horizontal, vertical, or elongated straight line.
  oneDimensional,

  /// 2D stroke (aspect ratio >= 0.20): e.g. "V", checkmark, circle, polygon, or complex curve.
  twoDimensional,
}

/// Pure mathematical utility for centroid translation and reference bounding box scaling.
///
/// Implements Job 4 of the Stealth Gesture Pipeline (Harel Region D: Gesture Engine).
/// Normalizes 64-point resampled stroke trajectories to:
/// 1. Centroid centered at origin (0.0, 0.0).
/// 2. Aspect-preserving reference scaling to canonical bounding dimension B = 250.0px:
///    - 1D gestures (aspect ratio < 0.20): uniform scaling by B / max(W, H).
///    - 2D gestures (aspect ratio >= 0.20): non-uniform scaling to reference square B x B.
abstract final class GestureNormalizer {
  /// Canonical reference dimension in logical pixels (B = 250.0px).
  static const double canonicalReferenceDimension = 250.0;

  /// Aspect ratio threshold distinguishing 1D elongated gestures from 2D planar gestures.
  static const double aspectThreshold = 0.20;

  /// Classifies stroke dimensionality based on bounding box width and height.
  static GestureDimensionalityType classifyDimensionality(
    double width,
    double height, {
    double threshold = aspectThreshold,
  }) {
    final double maxDimension = math.max(width, height);
    final double minDimension = math.min(width, height);
    final double aspectRatio =
        (maxDimension > 0.0) ? (minDimension / maxDimension) : 0.0;

    return (aspectRatio < threshold)
        ? GestureDimensionalityType.oneDimensional
        : GestureDimensionalityType.twoDimensional;
  }

  /// Normalizes coordinates of [resampledPoints] to origin centroid and reference scale.
  ///
  /// Throws [FormatException] if:
  /// - [resampledPoints] length does not equal [GestureTemplate.requiredPointCount] (64).
  /// - [referenceDimension] is non-positive, NaN, or infinite.
  /// - Any coordinate is NaN or infinite.
  static List<GesturePoint> normalizeCoordinates(
    List<GesturePoint> resampledPoints, {
    double referenceDimension = canonicalReferenceDimension,
    double threshold = aspectThreshold,
  }) {
    if (resampledPoints.length != GestureTemplate.requiredPointCount) {
      throw FormatException(
        'GestureNormalizer requires exactly ${GestureTemplate.requiredPointCount} points, got: ${resampledPoints.length}',
      );
    }
    if (referenceDimension <= 0.0 ||
        referenceDimension.isNaN ||
        referenceDimension.isInfinite) {
      throw FormatException(
        'GestureNormalizer referenceDimension must be positive and finite, got: $referenceDimension',
      );
    }

    final int pointCount = resampledPoints.length;

    // 1. Compute geometric centroid (Cx, Cy)
    double sumX = 0.0;
    double sumY = 0.0;
    for (int i = 0; i < pointCount; i++) {
      sumX += resampledPoints[i].x;
      sumY += resampledPoints[i].y;
    }
    final double centroidX = sumX / pointCount;
    final double centroidY = sumY / pointCount;

    // 2. Translate to origin (0, 0) and determine bounding box (W, H)
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    final List<double> translatedX = List<double>.filled(pointCount, 0.0);
    final List<double> translatedY = List<double>.filled(pointCount, 0.0);

    for (int i = 0; i < pointCount; i++) {
      final double tx = resampledPoints[i].x - centroidX;
      final double ty = resampledPoints[i].y - centroidY;
      translatedX[i] = tx;
      translatedY[i] = ty;

      if (tx < minX) {
        minX = tx;
      }
      if (tx > maxX) {
        maxX = tx;
      }
      if (ty < minY) {
        minY = ty;
      }
      if (ty > maxY) {
        maxY = ty;
      }
    }

    final double width = maxX - minX;
    final double height = maxY - minY;
    final double maxDimension = math.max(width, height);

    // 3. Evaluate aspect ratio and classify dimensionality
    final GestureDimensionalityType dimensionality = classifyDimensionality(
      width,
      height,
      threshold: threshold,
    );

    // 4. Calculate scale factors
    final double scaleX;
    final double scaleY;

    switch (dimensionality) {
      case GestureDimensionalityType.oneDimensional:
        final double uniformScale = (maxDimension > 0.0)
            ? (referenceDimension / maxDimension)
            : 1.0;
        scaleX = uniformScale;
        scaleY = uniformScale;
      case GestureDimensionalityType.twoDimensional:
        scaleX = (width > 0.0) ? (referenceDimension / width) : 1.0;
        scaleY = (height > 0.0) ? (referenceDimension / height) : 1.0;
    }

    // 5. Apply scaling and construct immutable output points
    final List<GesturePoint> normalized = <GesturePoint>[];
    for (int i = 0; i < pointCount; i++) {
      final double finalX = translatedX[i] * scaleX;
      final double finalY = translatedY[i] * scaleY;

      if (finalX.isNaN ||
          finalX.isInfinite ||
          finalY.isNaN ||
          finalY.isInfinite) {
        throw FormatException(
          'GestureNormalizer produced non-finite coordinate at index $i: ($finalX, $finalY)',
        );
      }

      normalized.add(GesturePoint(
        x: finalX,
        y: finalY,
        timestampMs: resampledPoints[i].timestampMs,
      ));
    }

    return List<GesturePoint>.unmodifiable(normalized);
  }
}
