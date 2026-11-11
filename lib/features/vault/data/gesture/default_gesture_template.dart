import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Provisioned canonical default single-stroke "V" shape gesture template.
///
/// Enables immediate out-of-the-box stealth unlocking and gateway activation
/// without requiring prior gesture enrollment wizard completion.
///
/// Conforms to:
/// - Closed-form analytical coordinates:
///     x_i = -125.0 + i * (250.0 / 63.0)
///     y_i = -125.0 + min(i, 63 - i) * (250.0 / 31.0)
///   for i in [0..63].
/// - Exactly N = 64 equidistant points, centered at (0.0, 0.0), scaled to 250.0px x 250.0px.
/// - Pre-computed 7D Rubine feature vector matching machine precision.
/// - Deeply immutable, thread-safe, and zero-allocation on repeated reads.
@immutable
abstract final class DefaultGestureTemplate {
  /// Canonical identifier for the provisioned default template.
  static const String canonicalId = 'canonical_default_v_shape';

  /// Alias for compatibility with project interface documentation.
  static const String defaultTemplateId = canonicalId;

  /// Synthetic epoch timestamp for the default template (2026-01-01T00:00:00.000Z).
  static const int defaultCreationEpochMs = 1767225600000;

  /// Pre-computed 7-dimensional normalized Rubine geometric feature vector.
  static const List<double> canonicalRubineVector = <double>[
    0.7207538256096554,
    0.9486287423680095,
    0.7207538256096548,
    0.05137125763199024,
    0.44545660527902775,
    0.41138904839076024,
    0.484375,
  ];

  /// Ground-truth unnormalized control vertices of the canonical "V" shape.
  static final List<GesturePoint> rawControlVertices =
      List<GesturePoint>.unmodifiable(<GesturePoint>[
    GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
    GesturePoint(x: 125.0, y: 250.0, timestampMs: 250),
    GesturePoint(x: 250.0, y: 0.0, timestampMs: 500),
  ]);

  /// Canonical 64 normalized equidistant points for the "V" shape template.
  static final List<GesturePoint> canonicalPoints = _buildCanonicalPoints();

  /// Lazily evaluated, authoritative singleton [GestureTemplate] for the "V" shape.
  static final GestureTemplate canonicalVShape = _buildCanonicalVShape();

  /// Constructs the deterministic 64-point sequence for the canonical "V" shape.
  static List<GesturePoint> _buildCanonicalPoints() {
    final points = <GesturePoint>[];
    const double stepX = 250.0 / 63.0;
    const double stepY = 250.0 / 31.0;

    for (int i = 0; i < GestureTemplate.requiredPointCount; i++) {
      final double x = -125.0 + (i * stepX);
      final int armIndex = (i <= 31) ? i : (63 - i);
      final double y = -125.0 + (armIndex * stepY);
      points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
    }

    return List<GesturePoint>.unmodifiable(points);
  }

  /// Builds the authoritative [GestureTemplate] wrapping [canonicalPoints] and [canonicalRubineVector].
  static GestureTemplate _buildCanonicalVShape() {
    return GestureTemplate(
      id: canonicalId,
      normalizedPoints: canonicalPoints,
      rubineFeatureVector: canonicalRubineVector,
      createdAtEpochMs: defaultCreationEpochMs,
    );
  }
}
