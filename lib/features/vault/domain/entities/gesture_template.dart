import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

/// Deeply immutable value object representing the synthesized golden master gesture template.
///
/// Contains exactly 64 equidistant arc-length resampled points along with the 7-dimensional
/// normalized Rubine geometric feature vector.
@immutable
class GestureTemplate extends Equatable {
  /// Unique identifier of this gesture template.
  final String id;

  /// Unmodifiable sequence of exactly 64 normalized coordinates.
  final List<GesturePoint> normalizedPoints;

  /// Unmodifiable 7-dimensional normalized Rubine geometric feature vector.
  final List<double> rubineFeatureVector;

  /// Monotonic or epoch timestamp in milliseconds when this template was synthesized and committed.
  final int createdAtEpochMs;

  /// Required number of resampled normalized points in the master template.
  static const int requiredPointCount = 64;

  /// Required dimensionality of the Rubine feature vector.
  static const int requiredFeatureVectorDimensions = 7;

  /// Constructs a validated [GestureTemplate] instance.
  ///
  /// Defensively wraps [normalizedPoints] and [rubineFeatureVector] into unmodifiable collections.
  /// Throws [FormatException] if [id] is empty, [normalizedPoints] does not contain exactly 64 points,
  /// [rubineFeatureVector] does not contain exactly 7 finite values, or [createdAtEpochMs] is non-positive.
  GestureTemplate({
    required this.id,
    required List<GesturePoint> normalizedPoints,
    required List<double> rubineFeatureVector,
    required this.createdAtEpochMs,
  })  : normalizedPoints = List.unmodifiable(normalizedPoints),
        rubineFeatureVector = List.unmodifiable(rubineFeatureVector) {
    if (id.trim().isEmpty) {
      throw const FormatException('GestureTemplate id must not be empty.');
    }
    if (normalizedPoints.length != requiredPointCount) {
      throw FormatException(
        'GestureTemplate normalizedPoints length must be exactly $requiredPointCount, got: ${normalizedPoints.length}',
      );
    }
    if (rubineFeatureVector.length != requiredFeatureVectorDimensions) {
      throw FormatException(
        'GestureTemplate rubineFeatureVector length must be exactly $requiredFeatureVectorDimensions, got: ${rubineFeatureVector.length}',
      );
    }
    for (int i = 0; i < rubineFeatureVector.length; i++) {
      final value = rubineFeatureVector[i];
      if (value.isNaN || value.isInfinite) {
        throw FormatException(
          'GestureTemplate rubineFeatureVector at index $i must be a finite number, got: $value',
        );
      }
    }
    if (createdAtEpochMs <= 0) {
      throw FormatException(
        'GestureTemplate createdAtEpochMs must be positive: $createdAtEpochMs',
      );
    }
  }

  @override
  List<Object?> get props => [
        id,
        normalizedPoints,
        rubineFeatureVector,
        createdAtEpochMs,
      ];
}
