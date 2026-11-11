import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Data Transfer Object for serializing 64-point trajectories and 7D Rubine feature vectors.
///
/// Strictly enforces the Layer 3 fail-fast deserialization rule: validates point counts,
/// finite float values, and timestamp ranges.
abstract final class GestureTemplateDto {
  /// Converts a sequence of [GesturePoint] objects into a JSON-compatible list of maps.
  static List<Map<String, Object>> pointsToJson(List<GesturePoint> points) {
    return points
        .map((point) => <String, Object>{
              'x': point.x,
              'y': point.y,
              't': point.timestampMs,
            })
        .toList(growable: false);
  }

  /// Deserializes a JSON List into a sequence of exactly 64 validated [GesturePoint] objects.
  ///
  /// Throws [FormatException] if [json] is not a List, length is not 64, or coordinates are invalid.
  static List<GesturePoint> pointsFromJson(Object? json) {
    if (json is! List) {
      throw const FormatException('Expected JSON List for gesture points.');
    }
    if (json.length != GestureTemplate.requiredPointCount) {
      throw FormatException(
        'Expected exactly ${GestureTemplate.requiredPointCount} points, got ${json.length}.',
      );
    }

    final List<GesturePoint> points = <GesturePoint>[];
    for (int i = 0; i < json.length; i++) {
      final item = json[i];
      if (item is! Map) {
        throw FormatException('Point at index $i is not a JSON Map.');
      }
      final xRaw = item['x'];
      if (xRaw is! num || xRaw.isNaN || xRaw.isInfinite) {
        throw FormatException('Invalid x coordinate at point $i.');
      }
      final yRaw = item['y'];
      if (yRaw is! num || yRaw.isNaN || yRaw.isInfinite) {
        throw FormatException('Invalid y coordinate at point $i.');
      }
      final tRaw = item['t'];
      if (tRaw is! int || tRaw < 0) {
        throw FormatException('Invalid timestamp at point $i.');
      }
      points.add(GesturePoint(
        x: xRaw.toDouble(),
        y: yRaw.toDouble(),
        timestampMs: tRaw,
      ));
    }
    return points;
  }

  /// Converts a 7-dimensional Rubine feature vector into an unmodifiable list of doubles.
  static List<double> rubineToJson(List<double> features) {
    return List<double>.unmodifiable(features);
  }

  /// Deserializes a JSON List into an unmodifiable 7-dimensional Rubine feature vector.
  ///
  /// Throws [FormatException] if [json] is not a List, length is not 7, or values are non-finite.
  static List<double> rubineFromJson(Object? json) {
    if (json is! List) {
      throw const FormatException('Expected JSON List for rubine features.');
    }
    if (json.length != GestureTemplate.requiredFeatureVectorDimensions) {
      throw FormatException(
        'Expected exactly ${GestureTemplate.requiredFeatureVectorDimensions} features, got ${json.length}.',
      );
    }

    final List<double> features = <double>[];
    for (int i = 0; i < json.length; i++) {
      final val = json[i];
      if (val is! num || val.isNaN || val.isInfinite) {
        throw FormatException('Invalid rubine feature at index $i: $val');
      }
      features.add(val.toDouble());
    }
    return features;
  }
}
