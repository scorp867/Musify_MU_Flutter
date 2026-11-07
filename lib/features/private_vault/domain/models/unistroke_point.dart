import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable 2D coordinate representation used in the $1 Unistroke geometric recognizer.
@immutable
final class UnistrokePoint extends Equatable {
  final double x;
  final double y;

  const UnistrokePoint(this.x, this.y);

  /// Computes Euclidean distance between this point and [other].
  double distanceTo(UnistrokePoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Deserializes a two-element [x, y] list into a [UnistrokePoint].
  factory UnistrokePoint.fromJson(dynamic json) {
    if (json is List && json.length >= 2) {
      final first = json[0];
      final second = json[1];
      if (first is num && second is num) {
        return UnistrokePoint(first.toDouble(), second.toDouble());
      }
    }
    throw const FormatException('Invalid UnistrokePoint JSON array: expected [num, num]');
  }

  /// Serializes the point to a compact [x, y] JSON array.
  List<double> toJson() => <double>[x, y];

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'UnistrokePoint(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}
