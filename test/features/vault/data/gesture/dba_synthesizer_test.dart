import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/dba_synthesizer.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

void main() {
  group('DbaSynthesizer & Pairwise DTW Consistency Tests', () {
    const synthesizer = DbaSynthesizer();

    // Helper to generate a realistic V-shape gesture sample with optional jitter and scale
    GestureSample createSampleV({
      double offsetX = 0.0,
      double offsetY = 0.0,
      double scale = 1.0,
      bool reverse = false,
      double jitter = 0.0,
      int pointCountPerArm = 25,
      int epoch = 1700000000000,
    }) {
      final rawPoints = <GesturePoint>[];
      // Left arm: (50, 50) -> (150, 250)
      for (int i = 0; i < pointCountPerArm; i++) {
        final double t = i / (pointCountPerArm - 1.0);
        final double x = offsetX + (50.0 + (t * 100.0) * scale) + (jitter * math.sin(i));
        final double y = offsetY + (50.0 + (t * 200.0) * scale) + (jitter * math.cos(i));
        rawPoints.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Right arm: (150, 250) -> (250, 50)
      for (int i = 0; i < pointCountPerArm; i++) {
        final double t = i / (pointCountPerArm - 1.0);
        final double x = offsetX + (150.0 + (t * 100.0) * scale) + (jitter * math.cos(i));
        final double y = offsetY + (250.0 - (t * 200.0) * scale) + (jitter * math.sin(i));
        rawPoints.add(
          GesturePoint(x: x, y: y, timestampMs: (pointCountPerArm + i) * 16),
        );
      }

      final List<GesturePoint> points = reverse
          ? List<GesturePoint>.unmodifiable(rawPoints.reversed)
          : List<GesturePoint>.unmodifiable(rawPoints);

      double length = 0.0;
      for (int i = 0; i < points.length - 1; i++) {
        final dx = points[i + 1].x - points[i].x;
        final dy = points[i + 1].y - points[i].y;
        length += math.sqrt(dx * dx + dy * dy);
      }

      return GestureSample(
        points: points,
        sampledAtEpochMs: epoch,
        totalLength: length,
      );
    }

    // Helper to generate a straight horizontal line sample
    GestureSample createSampleHorizontal({
      int pointCount = 50,
      int epoch = 1700000000000,
    }) {
      final points = List.generate(
        pointCount,
        (i) => GesturePoint(x: 50.0 + (i * 4.0), y: 150.0, timestampMs: i * 16),
      );
      return GestureSample(
        points: points,
        sampledAtEpochMs: epoch,
        totalLength: (pointCount - 1) * 4.0,
      );
    }

    group('standardizeSample', () {
      test('successfully standardizes a valid sample to 64 equidistant normalized points', () {
        final sample = createSampleV();
        final normalized = DbaSynthesizer.standardizeSample(sample);

        expect(normalized.length, GestureTemplate.requiredPointCount);

        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;
        double sumX = 0.0;
        double sumY = 0.0;

        for (final pt in normalized) {
          if (pt.x < minX) minX = pt.x;
          if (pt.x > maxX) maxX = pt.x;
          if (pt.y < minY) minY = pt.y;
          if (pt.y > maxY) maxY = pt.y;
          sumX += pt.x;
          sumY += pt.y;
        }

        // Width and height scaled to 250.0px, centroid centered at (0.0, 0.0)
        expect(maxX - minX, closeTo(250.0, 1e-4));
        expect(maxY - minY, closeTo(250.0, 1e-4));
        expect(sumX / 64.0, closeTo(0.0, 1e-4));
        expect(sumY / 64.0, closeTo(0.0, 1e-4));
      });

      test('throws FormatException if sample fails kinematic sanity gate', () {
        // Micro touch with span < 28px
        final microPoints = List.generate(
          15,
          (i) => GesturePoint(x: 100.0 + (i * 0.5), y: 100.0 + (i * 0.5), timestampMs: i * 16),
        );
        final sample = GestureSample(
          points: microPoints,
          sampledAtEpochMs: 1700000000000,
          totalLength: 10.0,
        );

        expect(
          () => DbaSynthesizer.standardizeSample(sample),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('extractWarpingPath', () {
      test('produces valid warping path spanning (0,0) to (N-1, M-1) within window band', () {
        final points = DefaultGestureTemplate.canonicalPoints;
        final path = DbaSynthesizer.extractWarpingPath(points, points, windowRadius: 10);

        expect(path.isNotEmpty, isTrue);
        expect(path.first, const DtwPathPoint(0, 0));
        expect(path.last, const DtwPathPoint(63, 63));

        for (final pt in path) {
          expect((pt.index1 - pt.index2).abs(), lessThanOrEqualTo(10));
        }
      });
    });

    group('checkConsistency & evaluateNormalizedConsistency', () {
      test('passes consistency check for 3 consistent samples', () {
        final sample1 = createSampleV(jitter: 0.5, scale: 1.0);
        final sample2 = createSampleV(jitter: 1.0, scale: 1.05);
        final sample3 = createSampleV(jitter: 0.8, scale: 0.95);

        final isConsistent = synthesizer.checkConsistency(
          samples: [sample1, sample2, sample3],
        );
        expect(isConsistent, isTrue);
      });

      test('passes consistency check even if one sample was drawn in reverse direction', () {
        final sample1 = createSampleV(scale: 1.0);
        final sample2 = createSampleV(scale: 1.02);
        final sample3 = createSampleV(scale: 0.98, reverse: true);

        final isConsistent = synthesizer.checkConsistency(
          samples: [sample1, sample2, sample3],
        );
        expect(isConsistent, isTrue);
      });

      test('fails consistency check and identifies outlier when one sample is divergent', () {
        final sample1 = createSampleV(scale: 1.0);
        final sample2 = createSampleV(scale: 1.05);
        final sample3 = createSampleHorizontal();

        final isConsistent = synthesizer.checkConsistency(
          samples: [sample1, sample2, sample3],
        );
        expect(isConsistent, isFalse);

        final norm1 = DbaSynthesizer.standardizeSample(sample1);
        final norm2 = DbaSynthesizer.standardizeSample(sample2);
        final norm3 = DbaSynthesizer.standardizeSample(sample3);

        final result = DbaSynthesizer.evaluateNormalizedConsistency(
          normalizedSamples: [norm1, norm2, norm3],
        );

        expect(result.isConsistent, isFalse);
        expect(result.outlierIndex, 2);
        expect(result.minimumPairScore, lessThan(0.60));
      });

      test('throws FormatException if fewer than 2 samples provided', () {
        final sample1 = createSampleV();
        expect(
          () => synthesizer.checkConsistency(samples: [sample1]),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('synthesize & synthesizeStatic', () {
      test('successfully synthesizes 3 consistent samples into authoritative master template', () {
        final sample1 = createSampleV(jitter: 0.5, scale: 1.0);
        final sample2 = createSampleV(jitter: 1.0, scale: 1.05);
        final sample3 = createSampleV(jitter: 0.8, scale: 0.95);

        final template = synthesizer.synthesize(
          samples: [sample1, sample2, sample3],
          id: 'test_master_template',
          createdAtEpochMs: 1700000000000,
        );

        expect(template.id, 'test_master_template');
        expect(template.normalizedPoints.length, 64);
        expect(template.rubineFeatureVector.length, 7);
        expect(template.createdAtEpochMs, 1700000000000);

        // Template matches canonical V with high DTW score
        final double dtwScore = const FastDtwRecognizer().match(
          template.normalizedPoints,
          DefaultGestureTemplate.canonicalPoints,
        );
        expect(dtwScore, greaterThan(0.90));
      });

      test('synthesizes consistent template when a sample is drawn in reverse order', () {
        final sample1 = createSampleV(scale: 1.0);
        final sample2 = createSampleV(scale: 1.02);
        final sample3 = createSampleV(scale: 0.98, reverse: true);

        final template = synthesizer.synthesize(
          samples: [sample1, sample2, sample3],
          id: 'reverse_tolerant_template',
        );

        expect(template.normalizedPoints.length, 64);

        // Verify shape orientation preserved and not collapsed
        final double dtwScore = const FastDtwRecognizer().match(
          template.normalizedPoints,
          DefaultGestureTemplate.canonicalPoints,
        );
        expect(dtwScore, greaterThan(0.90));
      });

      test('throws FormatException when synthesis is attempted on divergent samples', () {
        final sample1 = createSampleV(scale: 1.0);
        final sample2 = createSampleV(scale: 1.05);
        final sample3 = createSampleHorizontal();

        expect(
          () => synthesizer.synthesize(
            samples: [sample1, sample2, sample3],
            id: 'failing_template',
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('failed pairwise DTW consistency check'),
            ),
          ),
        );
      });
    });
  });
}
