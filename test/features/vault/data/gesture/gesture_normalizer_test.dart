import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_normalizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_resampler.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

void main() {
  group('GestureNormalizer', () {
    // Helper to generate a 64-point resampled stroke along any function
    List<GesturePoint> create64Points(double Function(double t) xFn, double Function(double t) yFn) {
      final raw = List.generate(
        10,
        (i) {
          final t = i / 9.0;
          return GesturePoint(
            x: xFn(t),
            y: yFn(t),
            timestampMs: i * 20,
          );
        },
      );
      return GestureResampler.resample(raw, targetCount: 64);
    }

    group('Invariants & Boundary Conditions', () {
      test('throws FormatException if input point count != 64', () {
        final points63 = List.generate(
          63,
          (i) => GesturePoint(x: i * 1.0, y: i * 1.0, timestampMs: i * 10),
        );
        expect(
          () => GestureNormalizer.normalizeCoordinates(points63),
          throwsFormatException,
        );

        final points65 = List.generate(
          65,
          (i) => GesturePoint(x: i * 1.0, y: i * 1.0, timestampMs: i * 10),
        );
        expect(
          () => GestureNormalizer.normalizeCoordinates(points65),
          throwsFormatException,
        );
      });

      test('throws FormatException if referenceDimension <= 0 or non-finite', () {
        final points = create64Points((t) => t * 100.0, (t) => t * 100.0);
        expect(
          () => GestureNormalizer.normalizeCoordinates(points, referenceDimension: 0.0),
          throwsFormatException,
        );
        expect(
          () => GestureNormalizer.normalizeCoordinates(points, referenceDimension: -250.0),
          throwsFormatException,
        );
        expect(
          () => GestureNormalizer.normalizeCoordinates(points, referenceDimension: double.nan),
          throwsFormatException,
        );
      });
    });

    group('Centroid Translation to Origin (0, 0)', () {
      test('translates centroid to (0.0, 0.0) with tolerance < 1e-9', () {
        final points = create64Points(
          (t) => 500.0 + t * 200.0,
          (t) => 800.0 + t * 150.0,
        );

        final normalized = GestureNormalizer.normalizeCoordinates(points);
        expect(normalized.length, equals(64));

        double sumX = 0.0;
        double sumY = 0.0;
        for (final p in normalized) {
          sumX += p.x;
          sumY += p.y;
        }

        final centroidX = sumX / 64;
        final centroidY = sumY / 64;

        expect(centroidX.abs(), lessThan(1e-9));
        expect(centroidY.abs(), lessThan(1e-9));
      });

      test('translation is invariant to canvas offset', () {
        // Same shape drawn at (0, 0) vs (1000, 2000)
        final shape1 = create64Points((t) => t * 100.0, (t) => t * 100.0);
        final shape2 = create64Points((t) => 1000.0 + t * 100.0, (t) => 2000.0 + t * 100.0);

        final norm1 = GestureNormalizer.normalizeCoordinates(shape1);
        final norm2 = GestureNormalizer.normalizeCoordinates(shape2);

        for (var i = 0; i < 64; i++) {
          expect(norm1[i].x, closeTo(norm2[i].x, 1e-6));
          expect(norm1[i].y, closeTo(norm2[i].y, 1e-6));
        }
      });
    });

    group('Dimensionality Classification', () {
      test('classifies aspect ratio < 0.20 as oneDimensional', () {
        expect(
          GestureNormalizer.classifyDimensionality(200.0, 0.0),
          equals(GestureDimensionalityType.oneDimensional),
        );
        expect(
          GestureNormalizer.classifyDimensionality(0.0, 200.0),
          equals(GestureDimensionalityType.oneDimensional),
        );
        expect(
          GestureNormalizer.classifyDimensionality(100.0, 19.9),
          equals(GestureDimensionalityType.oneDimensional),
        );
      });

      test('classifies aspect ratio >= 0.20 as twoDimensional', () {
        expect(
          GestureNormalizer.classifyDimensionality(100.0, 20.0),
          equals(GestureDimensionalityType.twoDimensional),
        );
        expect(
          GestureNormalizer.classifyDimensionality(100.0, 50.0),
          equals(GestureDimensionalityType.twoDimensional),
        );
        expect(
          GestureNormalizer.classifyDimensionality(100.0, 100.0),
          equals(GestureDimensionalityType.twoDimensional),
        );
      });
    });

    group('1D Uniform Reference Scaling (Aspect Ratio < 0.20)', () {
      test('scales purely horizontal line uniformly to span 250px without vertical noise amplification', () {
        final points = create64Points((t) => t * 180.0, (t) => 50.0);
        final normalized = GestureNormalizer.normalizeCoordinates(points);

        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;
        for (final p in normalized) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }

        // Width must be exactly B = 250.0, centered from -125.0 to +125.0
        expect(maxX - minX, closeTo(250.0, 1e-6));
        expect(minX, closeTo(-125.0, 1e-6));
        expect(maxX, closeTo(125.0, 1e-6));

        // Height must remain exactly 0.0
        expect(maxY - minY, closeTo(0.0, 1e-6));
      });

      test('scales purely vertical line uniformly to span 250px on Y axis', () {
        final points = create64Points((t) => 30.0, (t) => t * 200.0);
        final normalized = GestureNormalizer.normalizeCoordinates(points);

        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;
        for (final p in normalized) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }

        // Height must be exactly B = 250.0 (-125 to +125)
        expect(maxY - minY, closeTo(250.0, 1e-6));
        expect(minY, closeTo(-125.0, 1e-6));
        expect(maxY, closeTo(125.0, 1e-6));

        // Width remains 0.0
        expect(maxX - minX, closeTo(0.0, 1e-6));
      });

      test('scales 1D elongated stroke (W = 100, H = 10) uniformly without altering aspect ratio', () {
        final points = create64Points((t) => t * 100.0, (t) => t * 10.0);
        final normalized = GestureNormalizer.normalizeCoordinates(points);

        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;
        for (final p in normalized) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }

        final w = maxX - minX;
        final h = maxY - minY;

        // Dominant axis W = 250.0
        expect(w, closeTo(250.0, 1e-6));
        // Minor axis H scaled by 250 / 100 = 2.5 -> H = 25.0
        expect(h, closeTo(25.0, 1e-6));
      });
    });

    group('2D Non-Uniform Reference Scaling (Aspect Ratio >= 0.20)', () {
      test('scales 2D rectangular stroke (W = 200, H = 80) to reference square 250x250', () {
        final points = create64Points((t) => t * 200.0, (t) => t * 80.0);
        final normalized = GestureNormalizer.normalizeCoordinates(points);

        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;
        for (final p in normalized) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }

        final w = maxX - minX;
        final h = maxY - minY;

        // Both dimensions scale to 250.0
        expect(w, closeTo(250.0, 1e-6));
        expect(h, closeTo(250.0, 1e-6));
        expect(minX, closeTo(-125.0, 1e-6));
        expect(maxX, closeTo(125.0, 1e-6));
        expect(minY, closeTo(-125.0, 1e-6));
        expect(maxY, closeTo(125.0, 1e-6));
      });

      test('scales checkmark gesture to 250x250 canvas', () {
        final raw = [
          GesturePoint(x: 0.0, y: 50.0, timestampMs: 0),
          GesturePoint(x: 40.0, y: 10.0, timestampMs: 50),
          GesturePoint(x: 100.0, y: 100.0, timestampMs: 100),
        ];
        final resampled = GestureResampler.resample(raw, targetCount: 64);
        final normalized = GestureNormalizer.normalizeCoordinates(resampled);

        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;
        for (final p in normalized) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }

        expect(maxX - minX, closeTo(250.0, 1e-6));
        expect(maxY - minY, closeTo(250.0, 1e-6));
      });
    });

    group('Downstream Entity & Isolate Compatibility', () {
      test('normalized points directly satisfy GestureTemplate constructor invariants', () {
        final points = create64Points((t) => t * 100.0, (t) => t * 100.0);
        final normalized = GestureNormalizer.normalizeCoordinates(points);

        final template = GestureTemplate(
          id: 'template_alpha_01',
          normalizedPoints: normalized,
          rubineFeatureVector: const [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7],
          createdAtEpochMs: 1700000000000,
        );

        expect(template.normalizedPoints.length, equals(64));
        expect(template.id, equals('template_alpha_01'));
      });

      test('is thread-safe and executes inside Isolate.run', () async {
        final points = create64Points((t) => t * 150.0, (t) => t * 100.0);

        final result = await Isolate.run(() {
          return GestureNormalizer.normalizeCoordinates(points);
        });

        expect(result.length, equals(64));
      });
    });
  });
}
