import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_gesture_recognizer_service.dart';

export 'package:musify_mu/features/private_vault/domain/services/i_gesture_recognizer_service.dart';

/// Production implementation of Wobbrock's $1 Unistroke recognizer with bidirectional path matching.
final class UnistrokeRecognizer implements IGestureRecognizerService {
  static const int numPoints = GesturePattern.standardPointCount;
  static const double referenceSize = 100.0;
  static final double halfDiagonal = 0.5 * math.sqrt(referenceSize * referenceSize + referenceSize * referenceSize);

  const UnistrokeRecognizer();

  @override
  GestureRecognitionStatus evaluate({
    required List<Offset> rawPoints,
    required Size canvasSize,
    required GesturePattern template,
    double threshold = 0.70,
  }) {
    if (rawPoints.length < 5 || canvasSize.width <= 0 || canvasSize.height <= 0) {
      return GestureRecognitionStatus.mismatched;
    }

    final totalLength = _calculatePathLength(rawPoints);
    if (totalLength < 30.0) {
      return GestureRecognitionStatus.mismatched;
    }

    try {
      final drawnPattern = normalizeStroke(
        rawPoints: rawPoints,
        canvasSize: canvasSize,
      );

      final score = calculateSimilarity(drawnPattern, template);
      if (score >= threshold) {
        return GestureRecognitionStatus.matched;
      }
      return GestureRecognitionStatus.mismatched;
    } catch (_) {
      return GestureRecognitionStatus.mismatched;
    }
  }

  @override
  GesturePattern normalizeStroke({
    required List<Offset> rawPoints,
    required Size canvasSize,
  }) {
    if (rawPoints.length < 2) {
      throw const FormatException('Cannot normalize stroke with fewer than 2 points');
    }

    // Convert raw Offsets to UnistrokePoints, dropping zero-distance jitter
    final points = <UnistrokePoint>[];
    for (final pt in rawPoints) {
      final p = UnistrokePoint(pt.dx, pt.dy);
      if (points.isEmpty || points.last.distanceTo(p) > 0.5) {
        points.add(p);
      }
    }

    if (points.length < 2) {
      throw const FormatException('Stroke lacks sufficient length after jitter filtering');
    }

    // Step 1: Resample to 64 equidistant points along the continuous path
    final resampled = _resample(points, numPoints);

    // Step 2: Scale non-uniformly to reference square (100x100)
    final scaled = _scaleTo(resampled, referenceSize);

    // Step 3: Translate centroid to coordinate origin (0, 0)
    final centered = _translateToOrigin(scaled);

    return GesturePattern(centered);
  }

  @override
  double calculateSimilarity(GesturePattern patternA, GesturePattern patternB) {
    final ptsA = patternA.points;
    final ptsB = patternB.points;

    if (ptsA.length != ptsB.length || ptsA.isEmpty) {
      return 0.0;
    }

    // Forward path distance
    double sumDistForward = 0.0;
    for (int i = 0; i < ptsA.length; i++) {
      sumDistForward += ptsA[i].distanceTo(ptsB[i]);
    }
    final dForward = sumDistForward / ptsA.length;

    // Reverse path distance (bidirectional tolerance)
    double sumDistReverse = 0.0;
    final int count = ptsA.length;
    for (int i = 0; i < count; i++) {
      sumDistReverse += ptsA[i].distanceTo(ptsB[count - 1 - i]);
    }
    final dReverse = sumDistReverse / count;

    final minDistance = math.min(dForward, dReverse);
    final rawScore = 1.0 - (minDistance / halfDiagonal);
    if (rawScore < 0.0) return 0.0;
    if (rawScore > 1.0) return 1.0;
    return rawScore;
  }

  static double _calculatePathLength(List<Offset> points) {
    double length = 0.0;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].dx - points[i - 1].dx;
      final dy = points[i].dy - points[i - 1].dy;
      length += math.sqrt(dx * dx + dy * dy);
    }
    return length;
  }

  static double _calculateUnistrokePathLength(List<UnistrokePoint> points) {
    double length = 0.0;
    for (int i = 1; i < points.length; i++) {
      length += points[i - 1].distanceTo(points[i]);
    }
    return length;
  }

  static List<UnistrokePoint> _resample(List<UnistrokePoint> points, int n) {
    final totalLen = _calculateUnistrokePathLength(points);
    if (totalLen <= 0.0) {
      return List<UnistrokePoint>.filled(n, points.first);
    }

    final interval = totalLen / (n - 1);
    double accumulatedDistance = 0.0;
    final resampled = <UnistrokePoint>[points.first];
    final working = List<UnistrokePoint>.from(points);

    int i = 1;
    while (i < working.length) {
      final prev = working[i - 1];
      final curr = working[i];
      final segmentDist = prev.distanceTo(curr);

      if ((accumulatedDistance + segmentDist) >= interval && segmentDist > 0) {
        final t = (interval - accumulatedDistance) / segmentDist;
        final qx = prev.x + t * (curr.x - prev.x);
        final qy = prev.y + t * (curr.y - prev.y);
        final interpolated = UnistrokePoint(qx, qy);
        resampled.add(interpolated);
        working.insert(i, interpolated);
        accumulatedDistance = 0.0;
      } else {
        accumulatedDistance += segmentDist;
      }
      i++;
    }

    while (resampled.length < n) {
      resampled.add(points.last);
    }
    return resampled.take(n).toList(growable: false);
  }

  static List<UnistrokePoint> _scaleTo(List<UnistrokePoint> points, double size) {
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = math.max(maxX - minX, 1.0);
    final height = math.max(maxY - minY, 1.0);

    return points
        .map((p) => UnistrokePoint(
              (p.x - minX) * (size / width),
              (p.y - minY) * (size / height),
            ))
        .toList(growable: false);
  }

  static List<UnistrokePoint> _translateToOrigin(List<UnistrokePoint> points) {
    double sumX = 0.0;
    double sumY = 0.0;
    for (final p in points) {
      sumX += p.x;
      sumY += p.y;
    }
    final centroidX = sumX / points.length;
    final centroidY = sumY / points.length;

    return points
        .map((p) => UnistrokePoint(
              p.x - centroidX,
              p.y - centroidY,
            ))
        .toList(growable: false);
  }
}
