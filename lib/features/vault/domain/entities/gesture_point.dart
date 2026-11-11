import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Deeply immutable value object representing a single discrete touch point in a stroke trajectory.
///
/// Encapsulates normalized or raw spatial coordinates along with a monotonic timestamp in milliseconds.
@immutable
class GesturePoint extends Equatable {
  /// Horizontal coordinate on the sensor canvas.
  final double x;

  /// Vertical coordinate on the sensor canvas.
  final double y;

  /// Monotonic timestamp in milliseconds when this coordinate was captured.
  final int timestampMs;

  /// Constructs a validated [GesturePoint] instance.
  ///
  /// Throws [FormatException] if [x] or [y] is NaN or infinite, or if [timestampMs] is negative.
  GesturePoint({
    required this.x,
    required this.y,
    required this.timestampMs,
  }) {
    if (x.isNaN || x.isInfinite) {
      throw FormatException('GesturePoint x must be a finite number, got: $x');
    }
    if (y.isNaN || y.isInfinite) {
      throw FormatException('GesturePoint y must be a finite number, got: $y');
    }
    if (timestampMs < 0) {
      throw FormatException('GesturePoint timestampMs must be non-negative, got: $timestampMs');
    }
  }

  /// Constant constructor with assertions for compile-time constants.
  const GesturePoint.constant({
    required this.x,
    required this.y,
    required this.timestampMs,
  }) : assert(timestampMs >= 0, 'timestampMs must be non-negative');

  @override
  List<Object?> get props => [x, y, timestampMs];
}
