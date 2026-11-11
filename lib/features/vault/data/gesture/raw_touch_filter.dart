import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

/// Pure functional pre-processing filter implementing spatial deadband de-jittering
/// and 3-point Gaussian smoothing for single-stroke stealth touch trajectories
/// (Harel Region D: Gesture Engine, Job 1).
///
/// Encapsulates two deterministic mathematical stages:
/// 1. Spatial Deadband Filtering: Drops consecutive points where Euclidean distance
///    Delta d < 2.5px to suppress stationary digitizer chatter and finger dwell noise.
///    Deterministically anchors stroke initial point P_1 and terminal point P_n.
/// 2. 3-Point Gaussian Smoothing: Convolves interior vertices with symmetric kernel
///    weights [0.25, 0.50, 0.25], eliminating high-frequency digitizer noise while
///    strictly preserving timestamps and stroke endpoints P_1 and P_n.
///
/// Strictly conforms to the Zero Loose Booleans mandate: stateless, pure functional,
/// deeply immutable, and throws typed [FormatException] on non-finite coordinates or invalid thresholds.
@immutable
class RawTouchFilter {
  /// Default Euclidean deadband threshold in logical pixels.
  static const double defaultDeadbandThreshold = 2.5;

  /// Discrete Gaussian kernel weight for preceding vertex (P_{i-1}).
  static const double kernelWeightLeft = 0.25;

  /// Discrete Gaussian kernel weight for center vertex (P_i).
  static const double kernelWeightCenter = 0.50;

  /// Discrete Gaussian kernel weight for subsequent vertex (P_{i+1}).
  static const double kernelWeightRight = 0.25;

  /// Constructs a [RawTouchFilter] instance.
  const RawTouchFilter();

  /// Executes the complete two-stage pre-filtering pipeline:
  /// Euclidean deadband filtering followed by 3-point Gaussian smoothing.
  ///
  /// Returns an unmodifiable [List<GesturePoint>].
  /// Throws [FormatException] if [deadbandThreshold] is non-positive, NaN, or infinite,
  /// or if any point in [rawPoints] contains non-finite coordinates.
  List<GesturePoint> filterRawPoints(
    List<GesturePoint> rawPoints, {
    double deadbandThreshold = defaultDeadbandThreshold,
  }) {
    final deJittered = applyDeadband(
      rawPoints,
      deadbandThreshold: deadbandThreshold,
    );
    return applyGaussianSmoothing(deJittered);
  }

  /// Stage 1: Filters consecutive touch points falling within the Euclidean [deadbandThreshold].
  ///
  /// Anchors initial point P_1 and preserves terminal point P_n.
  /// Uses distance squared comparison to eliminate square root overhead.
  /// Throws [FormatException] if [deadbandThreshold] is non-positive, NaN, or infinite,
  /// or if any point in [points] contains non-finite coordinates.
  List<GesturePoint> applyDeadband(
    List<GesturePoint> points, {
    double deadbandThreshold = defaultDeadbandThreshold,
  }) {
    if (deadbandThreshold <= 0.0 ||
        deadbandThreshold.isNaN ||
        deadbandThreshold.isInfinite) {
      throw FormatException(
        'deadbandThreshold must be a positive finite number, got: $deadbandThreshold',
      );
    }

    if (points.isEmpty) {
      return const [];
    }

    for (final p in points) {
      if (!p.x.isFinite || !p.y.isFinite) {
        throw FormatException(
          'RawTouchFilter point coordinates must be finite, got: (${p.x}, ${p.y})',
        );
      }
    }

    if (points.length <= 1) {
      return List<GesturePoint>.unmodifiable(points);
    }

    final thresholdSquared = deadbandThreshold * deadbandThreshold;
    final retained = <GesturePoint>[points.first];
    var lastAccepted = points.first;

    for (var i = 1; i < points.length; i++) {
      final current = points[i];
      final dx = current.x - lastAccepted.x;
      final dy = current.y - lastAccepted.y;
      final distSquared = (dx * dx) + (dy * dy);

      if (distSquared >= thresholdSquared) {
        retained.add(current);
        lastAccepted = current;
      }
    }

    // Deterministic terminal endpoint anchoring:
    // If the raw final point was omitted due to sub-threshold distance (< 2.5px)
    // from the last accepted point, anchor it to preserve the exact lift-off coordinate.
    // If retained has more than 1 point, replace the last accepted point with points.last
    // to preserve terminal lift-off coordinates while maintaining spatial extent.
    // If retained has only 1 point (pure stationary dwell where no point exceeded deadband),
    // retain the single anchor point without appending sub-deadband noise.
    final rawTerminal = points.last;
    if (retained.length > 1 && retained.last != rawTerminal) {
      retained[retained.length - 1] = rawTerminal;
    }

    return List<GesturePoint>.unmodifiable(retained);
  }

  /// Stage 2: Applies 3-point Gaussian smoothing with kernel [0.25, 0.50, 0.25].
  ///
  /// Strictly preserves stroke endpoints (P_1 and P_n) and timestamps (t_i).
  /// Strokes with fewer than 3 points pass through unmodified.
  /// Throws [FormatException] if any point in [points] contains non-finite coordinates.
  List<GesturePoint> applyGaussianSmoothing(List<GesturePoint> points) {
    if (points.isEmpty) {
      return const [];
    }

    for (final p in points) {
      if (!p.x.isFinite || !p.y.isFinite) {
        throw FormatException(
          'RawTouchFilter point coordinates must be finite, got: (${p.x}, ${p.y})',
        );
      }
    }

    if (points.length <= 2) {
      return List<GesturePoint>.unmodifiable(points);
    }

    final count = points.length;
    final smoothed = List<GesturePoint>.generate(
      count,
      (index) {
        // Endpoint boundary invariant: strictly preserve P_1 and P_n.
        if (index == 0 || index == count - 1) {
          return points[index];
        }

        final prev = points[index - 1];
        final curr = points[index];
        final next = points[index + 1];

        final smoothedX = (kernelWeightLeft * prev.x) +
            (kernelWeightCenter * curr.x) +
            (kernelWeightRight * next.x);

        final smoothedY = (kernelWeightLeft * prev.y) +
            (kernelWeightCenter * curr.y) +
            (kernelWeightRight * next.y);

        return GesturePoint(
          x: smoothedX,
          y: smoothedY,
          timestampMs: curr.timestampMs,
        );
      },
      growable: false,
    );

    return List<GesturePoint>.unmodifiable(smoothed);
  }
}
