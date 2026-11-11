import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Pure mathematical extractor for 7-dimensional normalized Rubine geometric feature vectors
/// and bidirectional cosine similarity matching.
///
/// Implements Job 7 of the Single-Stroke Stealth Gesture Recognition Pipeline
/// (Harel Region D: Gesture Engine).
///
/// Extracts vector F in [0.0, 1.0]^7:
/// - f1, f2: Initial vector direction cos(alpha_start), sin(alpha_start) from P0 to P3 mapped to [0, 1].
/// - f3, f4: Terminal vector direction cos(alpha_end), sin(alpha_end) from P_N-4 to P_N-1 mapped to [0, 1].
/// - f5: Start-to-end net displacement magnitude normalized by path length ||P_N-1 - P0|| / L in [0, 1].
/// - f6: Total signed turning angle normalized (Theta_signed + 4*pi) / (8*pi) in [0, 1].
/// - f7: Peak curvature point index normalized i_peak / N in [0, 1].
///
/// Conforms strictly to workspace architectural invariants: stateless, deeply pure,
/// zero non-null assertions (!), zero .clamp() AST tokens, zero fallback operators (??),
/// and fail-fast validation.
@immutable
class RubineFeatureExtractor {
  /// Required dimensionality of the Rubine feature vector.
  static const int featureDimensions = GestureTemplate.requiredFeatureVectorDimensions; // 7

  /// Minimum number of trajectory points required to extract 3-segment initial/terminal vectors.
  static const int minRequiredPoints = 4;

  /// Numerical epsilon for floating-point zero-norm guards.
  static const double epsilon = 1e-12;

  /// Constructs a [RubineFeatureExtractor] instance.
  const RubineFeatureExtractor();

  /// Extracts the 7-dimensional normalized geometric feature vector from [points].
  ///
  /// Instance method for dependency injection into services.
  List<double> extractFeatures(List<GesturePoint> points) {
    return extractFeaturesStatic(points);
  }

  /// Computes the cosine similarity between two 7-dimensional normalized feature vectors.
  ///
  /// Instance method for dependency injection into services.
  double computeCosineSimilarity(List<double> vectorA, List<double> vectorB) {
    return computeCosineSimilarityStatic(vectorA, vectorB);
  }

  /// Evaluates bidirectional cosine similarity between candidate points and a template vector:
  /// S_feat = max(cosine(F_C_fwd, F_T), cosine(F_C_rev, F_T)) in [0.0, 1.0].
  ///
  /// Instance method for dependency injection into services.
  double matchBidirectional(
    List<GesturePoint> candidatePoints,
    List<double> templateVector,
  ) {
    return matchBidirectionalStatic(candidatePoints, templateVector);
  }

  /// Static extraction of the 7-dimensional normalized geometric feature vector from [points].
  ///
  /// Throws [FormatException] if [points] length is less than [minRequiredPoints] (4)
  /// or if any coordinate is non-finite.
  static List<double> extractFeaturesStatic(List<GesturePoint> points) {
    final int n = points.length;
    if (n < minRequiredPoints) {
      throw FormatException(
        'RubineFeatureExtractor requires at least $minRequiredPoints points, got: $n',
      );
    }

    for (int i = 0; i < n; i++) {
      final p = points[i];
      if (p.x.isNaN || p.x.isInfinite || p.y.isNaN || p.y.isInfinite) {
        throw FormatException(
          'RubineFeatureExtractor point coordinates must be finite, got: (${p.x}, ${p.y}) at index $i',
        );
      }
    }

    // 1. Initial vector direction: P0 to P3 (spanning 3 segments)
    final double dxStart = points[3].x - points[0].x;
    final double dyStart = points[3].y - points[0].y;
    final double distStart = math.sqrt((dxStart * dxStart) + (dyStart * dyStart));

    final double cosStart;
    final double sinStart;
    if (distStart < epsilon) {
      cosStart = 0.0;
      sinStart = 0.0;
    } else {
      cosStart = dxStart / distStart;
      sinStart = dyStart / distStart;
    }
    final double f1 = _boundUnit((cosStart + 1.0) / 2.0);
    final double f2 = _boundUnit((sinStart + 1.0) / 2.0);

    // 2. Terminal vector direction: P_N-4 to P_N-1 (spanning 3 segments)
    final double dxEnd = points[n - 1].x - points[n - 4].x;
    final double dyEnd = points[n - 1].y - points[n - 4].y;
    final double distEnd = math.sqrt((dxEnd * dxEnd) + (dyEnd * dyEnd));

    final double cosEnd;
    final double sinEnd;
    if (distEnd < epsilon) {
      cosEnd = 0.0;
      sinEnd = 0.0;
    } else {
      cosEnd = dxEnd / distEnd;
      sinEnd = dyEnd / distEnd;
    }
    final double f3 = _boundUnit((cosEnd + 1.0) / 2.0);
    final double f4 = _boundUnit((sinEnd + 1.0) / 2.0);

    // 3. Path length (L) and segment orientations
    double pathLength = 0.0;
    final List<double> segmentOrientations = List<double>.filled(n - 1, 0.0);
    double previousHeading = 0.0;

    for (int i = 0; i < n - 1; i++) {
      final double dx = points[i + 1].x - points[i].x;
      final double dy = points[i + 1].y - points[i].y;
      final double segDist = math.sqrt((dx * dx) + (dy * dy));
      pathLength += segDist;

      if (segDist < epsilon) {
        segmentOrientations[i] = previousHeading;
      } else {
        final double heading = math.atan2(dy, dx);
        segmentOrientations[i] = heading;
        previousHeading = heading;
      }
    }

    // 4. Net displacement to path length ratio (f5)
    final double dxNet = points[n - 1].x - points[0].x;
    final double dyNet = points[n - 1].y - points[0].y;
    final double dNet = math.sqrt((dxNet * dxNet) + (dyNet * dyNet));

    final double f5;
    if (pathLength < epsilon) {
      f5 = 0.0;
    } else {
      f5 = _boundUnit(dNet / pathLength);
    }

    // 5. Total signed turning angle (f6) and peak curvature index (f7)
    double totalSignedTurningAngle = 0.0;
    double maxCurvature = 0.0;
    int peakIndex = 0;

    for (int i = 1; i < n - 1; i++) {
      double deltaTheta = segmentOrientations[i] - segmentOrientations[i - 1];

      // Wrap angular difference to (-pi, +pi]
      while (deltaTheta > math.pi) {
        deltaTheta -= 2.0 * math.pi;
      }
      while (deltaTheta < -math.pi) {
        deltaTheta += 2.0 * math.pi;
      }

      totalSignedTurningAngle += deltaTheta;

      final double absCurvature = deltaTheta.abs();
      if (absCurvature > maxCurvature) {
        maxCurvature = absCurvature;
        peakIndex = i;
      }
    }

    final double f6 = _boundUnit(
      (totalSignedTurningAngle + (4.0 * math.pi)) / (8.0 * math.pi),
    );

    final double f7;
    if (maxCurvature < 1e-6) {
      f7 = 0.0;
    } else {
      f7 = _boundUnit(peakIndex / n.toDouble());
    }

    return List<double>.unmodifiable(<double>[
      f1,
      f2,
      f3,
      f4,
      f5,
      f6,
      f7,
    ]);
  }

  /// Computes the cosine similarity between two 7-dimensional normalized feature vectors.
  ///
  /// Safe against zero-norm division without non-null assertions.
  /// Output is strictly bounded in [0.0, 1.0].
  /// Throws [FormatException] if either vector length is not [featureDimensions] (7).
  static double computeCosineSimilarityStatic(
    List<double> vectorA,
    List<double> vectorB,
  ) {
    if (vectorA.length != featureDimensions) {
      throw FormatException(
        'vectorA must have exactly $featureDimensions dimensions, got: ${vectorA.length}',
      );
    }
    if (vectorB.length != featureDimensions) {
      throw FormatException(
        'vectorB must have exactly $featureDimensions dimensions, got: ${vectorB.length}',
      );
    }

    double dotProduct = 0.0;
    double normASquared = 0.0;
    double normBSquared = 0.0;

    for (int i = 0; i < featureDimensions; i++) {
      final double a = vectorA[i];
      final double b = vectorB[i];

      if (a.isNaN || a.isInfinite || b.isNaN || b.isInfinite) {
        throw FormatException(
          'Feature vector components must be finite, got: a=$a, b=$b at index $i',
        );
      }

      dotProduct += a * b;
      normASquared += a * a;
      normBSquared += b * b;
    }

    final double denom = math.sqrt(normASquared) * math.sqrt(normBSquared);
    if (denom < epsilon) {
      return 0.0;
    }

    return _boundUnit(dotProduct / denom);
  }

  /// Evaluates bidirectional cosine similarity between candidate points and a template vector:
  /// S_feat = max(cosine(F_C_fwd, F_T), cosine(F_C_rev, F_T)) in [0.0, 1.0].
  static double matchBidirectionalStatic(
    List<GesturePoint> candidatePoints,
    List<double> templateVector,
  ) {
    final List<double> forwardVector = extractFeaturesStatic(candidatePoints);
    final List<GesturePoint> reversePoints = List<GesturePoint>.unmodifiable(
      candidatePoints.reversed,
    );
    final List<double> reverseVector = extractFeaturesStatic(reversePoints);

    final double forwardSimilarity =
        computeCosineSimilarityStatic(forwardVector, templateVector);
    final double reverseSimilarity =
        computeCosineSimilarityStatic(reverseVector, templateVector);

    return math.max(forwardSimilarity, reverseSimilarity);
  }

  /// Bounds [value] strictly into [0.0, 1.0] without using AST-banned .clamp().
  static double _boundUnit(double value) {
    if (value < 0.0) {
      return 0.0;
    }
    if (value > 1.0) {
      return 1.0;
    }
    return value;
  }
}
