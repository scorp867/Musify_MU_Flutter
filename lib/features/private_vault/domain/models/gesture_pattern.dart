import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/private_vault/domain/models/unistroke_point.dart';

export 'package:musify_mu/features/private_vault/domain/models/unistroke_point.dart';

/// Immutable domain model representing a normalized trajectory pattern in the $1 Unistroke geometric space.
@immutable
final class GesturePattern extends Equatable {
  static const int standardPointCount = 64;

  final UnmodifiableListView<UnistrokePoint> _points;

  /// Creates a [GesturePattern] wrapping a sequence of normalized points.
  GesturePattern(List<UnistrokePoint> points)
      : _points = UnmodifiableListView<UnistrokePoint>(List<UnistrokePoint>.from(points)) {
    if (_points.length < 4) {
      throw const FormatException('GesturePattern requires at least 4 points');
    }
  }

  /// Exposed read-only list of normalized trajectory points.
  UnmodifiableListView<UnistrokePoint> get points => _points;

  /// Canonical default gesture template: single-stroke letter "P" (resampled to 64 normalized points).
  static final GesturePattern defaultPattern = GesturePattern(
    const <UnistrokePoint>[
      UnistrokePoint(-20.17, -41.43),
      UnistrokePoint(-20.17, -36.43),
      UnistrokePoint(-20.17, -31.43),
      UnistrokePoint(-20.17, -26.43),
      UnistrokePoint(-20.17, -21.43),
      UnistrokePoint(-20.17, -16.43),
      UnistrokePoint(-20.17, -11.43),
      UnistrokePoint(-20.17, -6.43),
      UnistrokePoint(-20.17, -1.43),
      UnistrokePoint(-20.17, 3.57),
      UnistrokePoint(-20.17, 8.57),
      UnistrokePoint(-20.17, 13.57),
      UnistrokePoint(-20.17, 18.57),
      UnistrokePoint(-20.17, 23.57),
      UnistrokePoint(-20.17, 28.57),
      UnistrokePoint(-20.17, 33.57),
      UnistrokePoint(-20.17, 38.57),
      UnistrokePoint(-20.17, 43.57),
      UnistrokePoint(-20.17, 48.57),
      UnistrokePoint(-20.17, 53.57),
      UnistrokePoint(-20.17, 58.57),
      UnistrokePoint(-20.17, 56.45),
      UnistrokePoint(-20.17, 51.45),
      UnistrokePoint(-20.17, 46.45),
      UnistrokePoint(-20.17, 41.45),
      UnistrokePoint(-20.17, 36.45),
      UnistrokePoint(-20.17, 31.45),
      UnistrokePoint(-20.17, 26.45),
      UnistrokePoint(-20.17, 21.45),
      UnistrokePoint(-20.17, 16.45),
      UnistrokePoint(-20.17, 11.45),
      UnistrokePoint(-20.17, 6.45),
      UnistrokePoint(-20.17, 1.45),
      UnistrokePoint(-20.17, -3.55),
      UnistrokePoint(-20.17, -8.55),
      UnistrokePoint(-20.17, -13.55),
      UnistrokePoint(-20.17, -18.55),
      UnistrokePoint(-20.17, -23.55),
      UnistrokePoint(-20.17, -28.55),
      UnistrokePoint(-20.17, -33.55),
      UnistrokePoint(-20.17, -38.55),
      UnistrokePoint(-15.35, -41.43),
      UnistrokePoint(-3.96, -41.43),
      UnistrokePoint(7.42, -41.43),
      UnistrokePoint(18.81, -41.43),
      UnistrokePoint(29.01, -39.72),
      UnistrokePoint(38.49, -36.94),
      UnistrokePoint(47.96, -34.17),
      UnistrokePoint(57.44, -31.40),
      UnistrokePoint(66.71, -28.54),
      UnistrokePoint(71.80, -24.07),
      UnistrokePoint(76.89, -19.60),
      UnistrokePoint(79.83, -15.13),
      UnistrokePoint(74.74, -10.65),
      UnistrokePoint(69.65, -6.18),
      UnistrokePoint(62.91, -2.35),
      UnistrokePoint(53.43, 0.43),
      UnistrokePoint(43.96, 3.20),
      UnistrokePoint(34.48, 5.97),
      UnistrokePoint(25.01, 8.75),
      UnistrokePoint(13.99, 9.29),
      UnistrokePoint(2.61, 9.29),
      UnistrokePoint(-8.78, 9.29),
      UnistrokePoint(-20.17, 9.29),
    ],
  );

  /// Deserializes a JSON list of point coordinates into a [GesturePattern].
  ///
  /// Migrates legacy grid integer arrays seamlessly to [defaultPattern].
  factory GesturePattern.fromJson(List<dynamic> jsonList) {
    if (jsonList.isEmpty) {
      throw const FormatException('Empty JSON list provided for GesturePattern');
    }

    // Check if legacy grid format (list of ints)
    if (jsonList.first is int) {
      return GesturePattern.defaultPattern;
    }

    final parsedPoints = <UnistrokePoint>[];
    for (final element in jsonList) {
      parsedPoints.add(UnistrokePoint.fromJson(element));
    }
    return GesturePattern(parsedPoints);
  }

  /// Serializes the normalized points into a JSON-compatible list of coordinate pairs.
  List<dynamic> toJson() {
    return _points.map((p) => p.toJson()).toList(growable: false);
  }

  @override
  List<Object?> get props => [_points];
}
