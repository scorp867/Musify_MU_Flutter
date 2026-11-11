import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Pure mathematical implementation of Bidirectional Fast Dynamic Time Warping (FastDTW)
/// sequence alignment with memory-bounded 2-row buffer DP and exponential score normalization.
///
/// Implements Job 6 of the Single-Stroke Stealth Gesture Recognition Pipeline
/// (Harel Region D: Gesture Engine).
///
/// Features:
/// 1. Memory-Bounded 2-Row Buffer DP: Operates strictly on two Float64List rows of size N+1 (65),
///    consuming ~1KB RAM and generating zero intermediate garbage.
/// 2. Bidirectional Alignment: Evaluates DTW(C_fwd, T) and DTW(C_rev, T) to support
///    reverse-drawn strokes with identical fidelity.
/// 3. Optional Sakoe-Chiba Constraint Band: Restricts warping window to radius r
///    (default: 10 points ~15.6% of contour) to prevent pathologically skewed warpings.
/// 4. Exponential Score Decay: Normalizes warp cost via S_DTW = exp(-DTW_bi / (N * sigma_DTW))
///    parameterized by sigma_DTW = 35.0px, aligning safety floor 0.60 with 17.88px mean warp error.
///
/// Conforms strictly to workspace architectural invariants: stateless, deeply pure,
/// zero non-null assertions (!), zero .clamp() AST tokens, zero fallback operators (??),
/// and fail-fast validation.
@immutable
class FastDtwRecognizer {
  /// Default exponential decay scaling parameter: sigma_DTW = 35.0 logical pixels.
  static const double defaultSigmaDtw = 35.0;

  /// Default Sakoe-Chiba constraint window radius (10 points ~ 15.6% of N = 64).
  static const int defaultWindowRadius = 10;

  /// Constructs a [FastDtwRecognizer] instance.
  const FastDtwRecognizer();

  /// Matches [candidate] against [template] and returns normalized similarity score in [0.0, 1.0].
  ///
  /// Instance method for dependency injection into services.
  double match(
    List<GesturePoint> candidate,
    List<GesturePoint> template, {
    double sigmaDtw = defaultSigmaDtw,
    int? windowRadius = defaultWindowRadius,
  }) {
    return matchStatic(
      candidate,
      template,
      sigmaDtw: sigmaDtw,
      windowRadius: windowRadius,
    );
  }

  /// Pure static evaluation matching [candidate] against [template].
  ///
  /// Throws [FormatException] if:
  /// - [candidate] or [template] does not contain exactly 64 points.
  /// - [sigmaDtw] is non-positive or non-finite.
  /// - [windowRadius] is provided but less than 1.
  static double matchStatic(
    List<GesturePoint> candidate,
    List<GesturePoint> template, {
    double sigmaDtw = defaultSigmaDtw,
    int? windowRadius = defaultWindowRadius,
  }) {
    if (candidate.length != GestureTemplate.requiredPointCount) {
      throw FormatException(
        'FastDtwRecognizer: candidate length must be exactly '
        '${GestureTemplate.requiredPointCount}, got: ${candidate.length}',
      );
    }
    if (template.length != GestureTemplate.requiredPointCount) {
      throw FormatException(
        'FastDtwRecognizer: template length must be exactly '
        '${GestureTemplate.requiredPointCount}, got: ${template.length}',
      );
    }
    if (sigmaDtw <= 0.0 || sigmaDtw.isNaN || sigmaDtw.isInfinite) {
      throw FormatException(
        'FastDtwRecognizer: sigmaDtw must be positive and finite, got: $sigmaDtw',
      );
    }
    if (windowRadius != null && windowRadius < 1) {
      throw FormatException(
        'FastDtwRecognizer: windowRadius must be at least 1, got: $windowRadius',
      );
    }

    final double dtwBi = computeBidirectionalDtwDistance(
      candidate,
      template,
      windowRadius: windowRadius,
    );

    final int pointCount = candidate.length;
    final double rawScore = math.exp(-dtwBi / (pointCount * sigmaDtw));
    return _boundToUnitInterval(rawScore);
  }

  /// Computes bidirectional minimum DTW distance across forward and reverse candidate paths.
  static double computeBidirectionalDtwDistance(
    List<GesturePoint> candidate,
    List<GesturePoint> template, {
    int? windowRadius = defaultWindowRadius,
  }) {
    final List<GesturePoint> candidateFwd = candidate;
    final List<GesturePoint> candidateRev =
        List<GesturePoint>.unmodifiable(candidate.reversed);

    final double dtwFwd = computeDtwDistance(
      candidateFwd,
      template,
      windowRadius: windowRadius,
    );
    final double dtwRev = computeDtwDistance(
      candidateRev,
      template,
      windowRadius: windowRadius,
    );

    return math.min(dtwFwd, dtwRev);
  }

  /// Computes unidirectional DTW distance using memory-bounded 2-row buffer dynamic programming.
  ///
  /// Restricts search to a Sakoe-Chiba constraint band if [windowRadius] is specified.
  static double computeDtwDistance(
    List<GesturePoint> s1,
    List<GesturePoint> s2, {
    int? windowRadius = defaultWindowRadius,
  }) {
    final int n = s1.length;
    final int m = s2.length;

    if (n == 0 || m == 0) {
      throw const FormatException('FastDtwRecognizer: sequences must not be empty');
    }

    // Allocate 2 rows of size m + 1
    Float64List prevRow = Float64List(m + 1);
    Float64List currRow = Float64List(m + 1);

    // Base initialization
    prevRow[0] = 0.0;
    for (int j = 1; j <= m; j++) {
      prevRow[j] = double.infinity;
    }

    final int effectiveRadius;
    if (windowRadius case final int r) {
      effectiveRadius = r;
    } else {
      effectiveRadius = m;
    }

    for (int i = 1; i <= n; i++) {
      currRow[0] = double.infinity;

      final GesturePoint p1 = s1[i - 1];
      final int minJ = math.max(1, i - effectiveRadius);
      final int maxJ = math.min(m, i + effectiveRadius);

      // Pad cells to the left of the constraint band with infinity
      for (int j = 1; j < minJ; j++) {
        currRow[j] = double.infinity;
      }

      for (int j = minJ; j <= maxJ; j++) {
        final GesturePoint p2 = s2[j - 1];
        final double dx = p1.x - p2.x;
        final double dy = p1.y - p2.y;
        final double dist = math.sqrt((dx * dx) + (dy * dy));

        // Evaluate 3 predecessor neighbors: diagonal, left, up
        final double left = currRow[j - 1];
        final double up = prevRow[j];
        final double diag = prevRow[j - 1];

        double minPrev = diag;
        if (up < minPrev) {
          minPrev = up;
        }
        if (left < minPrev) {
          minPrev = left;
        }

        currRow[j] = dist + minPrev;
      }

      // Pad cells to the right of the constraint band with infinity
      for (int j = maxJ + 1; j <= m; j++) {
        currRow[j] = double.infinity;
      }

      // Buffer swap: prevRow becomes currRow for next iteration
      final Float64List temp = prevRow;
      prevRow = currRow;
      currRow = temp;
    }

    return prevRow[m];
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
