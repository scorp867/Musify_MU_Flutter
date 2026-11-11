import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

/// Deeply immutable value object representing one continuous single-stroke gesture sample.
///
/// Encapsulates the ordered sequence of touch coordinates, capture timestamp, and cumulative arc length.
@immutable
class GestureSample extends Equatable {
  /// Unmodifiable list of ordered touch coordinates comprising this stroke.
  final List<GesturePoint> points;

  /// Monotonic or epoch timestamp in milliseconds when the stroke was recorded.
  final int sampledAtEpochMs;

  /// Total Euclidean trajectory length in logical pixels.
  final double totalLength;

  /// Constructs a validated [GestureSample] instance.
  ///
  /// Defensively wraps [points] into an unmodifiable collection.
  /// Throws [FormatException] if [points] is empty, [sampledAtEpochMs] is non-positive,
  /// or [totalLength] is NaN, infinite, or negative.
  GestureSample({
    required List<GesturePoint> points,
    required this.sampledAtEpochMs,
    required this.totalLength,
  }) : points = List.unmodifiable(points) {
    if (points.isEmpty) {
      throw const FormatException('GestureSample points list must not be empty.');
    }
    if (sampledAtEpochMs <= 0) {
      throw FormatException(
        'GestureSample sampledAtEpochMs must be positive: $sampledAtEpochMs',
      );
    }
    if (totalLength.isNaN || totalLength.isInfinite || totalLength < 0.0) {
      throw FormatException(
        'GestureSample totalLength must be a non-negative finite number, got: $totalLength',
      );
    }
  }

  /// The number of discrete coordinates captured in this sample.
  int get pointCount => points.length;

  @override
  List<Object?> get props => [points, sampledAtEpochMs, totalLength];
}
