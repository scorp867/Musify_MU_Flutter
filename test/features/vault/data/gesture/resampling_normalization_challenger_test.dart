import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_normalizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_resampler.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('Adversarial Challenger: GestureResampler & GestureNormalizer', () {
    // -------------------------------------------------------------------------
    // Helper Generators
    // -------------------------------------------------------------------------

    /// Generates a stroke with [clusterCount] points tightly packed around [start],
    /// followed by a sudden jump to [end].
    List<GesturePoint> generateStartClusteredStroke({
      int clusterCount = 500,
      double clusterRadius = 0.001,
      GesturePoint? start,
      GesturePoint? end,
    }) {
      final s = start ?? GesturePoint(x: 10.0, y: 10.0, timestampMs: 0);
      final e = end ?? GesturePoint(x: 310.0, y: 410.0, timestampMs: 1000);
      final points = <GesturePoint>[s];
      final rng = math.Random(42);
      for (var i = 1; i < clusterCount; i++) {
        final angle = rng.nextDouble() * 2 * math.pi;
        final r = rng.nextDouble() * clusterRadius;
        points.add(GesturePoint(
          x: s.x + r * math.cos(angle),
          y: s.y + r * math.sin(angle),
          timestampMs: (i * 2).clamp(0, 500),
        ));
      }
      points.add(e);
      return points;
    }

    /// Generates a stroke with high-frequency alternating velocity:
    /// alternating slow clusters and fast jumps.
    List<GesturePoint> generateAlternatingVelocityStroke({
      int stages = 10,
      int pointsPerCluster = 50,
    }) {
      final points = <GesturePoint>[];
      var currentX = 0.0;
      var currentY = 0.0;
      var t = 0;

      for (var s = 0; s < stages; s++) {
        // Slow cluster
        for (var c = 0; c < pointsPerCluster; c++) {
          points.add(GesturePoint(
            x: currentX + (c * 0.01),
            y: currentY + (c * 0.01),
            timestampMs: t++,
          ));
        }
        currentX += (pointsPerCluster * 0.01);
        currentY += (pointsPerCluster * 0.01);

        // Fast jump
        currentX += 50.0;
        currentY += 30.0;
        points.add(GesturePoint(
          x: currentX,
          y: currentY,
          timestampMs: t + 50,
        ));
        t += 50;
      }
      return points;
    }

    // =========================================================================
    // 1. RESAMPLING STRESS: Extreme Non-Uniform Drawing Speeds
    // =========================================================================
    group('1. Resampling Stress: Extreme Non-Uniform Speed Inputs', () {
      test('500 points clustered at start followed by a long jump produces exactly 64 points', () {
        final stroke = generateStartClusteredStroke(clusterCount: 500, clusterRadius: 0.0005);
        expect(stroke.length, equals(501));

        final resampled = GestureResampler.resample(stroke);

        expect(resampled.length, equals(64));
        expect(resampled.first.x, closeTo(stroke.first.x, 1e-9));
        expect(resampled.first.y, closeTo(stroke.first.y, 1e-9));
        expect(resampled.last.x, closeTo(stroke.last.x, 1e-9));
        expect(resampled.last.y, closeTo(stroke.last.y, 1e-9));
      });

      test('500 points clustered at end preceded by a long jump produces exactly 64 points', () {
        final points = <GesturePoint>[
          GesturePoint(x: 10.0, y: 10.0, timestampMs: 0),
          GesturePoint(x: 300.0, y: 300.0, timestampMs: 100),
        ];
        for (var i = 1; i <= 500; i++) {
          points.add(GesturePoint(
            x: 300.0 + (i * 0.0001),
            y: 300.0 + (i * 0.0001),
            timestampMs: 100 + i,
          ));
        }

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, closeTo(points.first.x, 1e-9));
        expect(resampled.first.y, closeTo(points.first.y, 1e-9));
        expect(resampled.last.x, closeTo(points.last.x, 1e-9));
        expect(resampled.last.y, closeTo(points.last.y, 1e-9));
      });

      test('500 points clustered in middle between two large jumps produces exactly 64 points', () {
        final points = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 100.0, y: 100.0, timestampMs: 50),
        ];
        for (var i = 1; i <= 500; i++) {
          points.add(GesturePoint(
            x: 100.0 + (i * 0.0002),
            y: 100.0 + (i * 0.0002),
            timestampMs: 50 + i,
          ));
        }
        points.add(GesturePoint(x: 250.0, y: 50.0, timestampMs: 800));

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, closeTo(points.first.x, 1e-9));
        expect(resampled.first.y, closeTo(points.first.y, 1e-9));
        expect(resampled.last.x, closeTo(points.last.x, 1e-9));
        expect(resampled.last.y, closeTo(points.last.y, 1e-9));
      });

      test('extreme alternating velocity (10 dense clusters of 50 points + 10 jumps)', () {
        final stroke = generateAlternatingVelocityStroke(stages: 10, pointsPerCluster: 50);
        expect(stroke.length, greaterThan(500));

        final resampled = GestureResampler.resample(stroke);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, closeTo(stroke.first.x, 1e-9));
        expect(resampled.first.y, closeTo(stroke.first.y, 1e-9));
        expect(resampled.last.x, closeTo(stroke.last.x, 1e-9));
        expect(resampled.last.y, closeTo(stroke.last.y, 1e-9));
      });
    });

    // =========================================================================
    // 2. RESAMPLING STRESS: Floating-Point Accumulator Drift
    // =========================================================================
    group('2. Resampling Stress: Floating-Point Drift on Arc-Length Accumulator', () {
      test('800 irrational segment lengths (sqrt(2), pi/100, 1/7) strictly produces 64 points', () {
        final points = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
        ];
        var curX = 0.0;
        var curY = 0.0;

        for (var i = 1; i <= 800; i++) {
          final angle = (i * math.pi) / 200.0;
          final step = (i % 2 == 0) ? math.sqrt(2.0) : (1.0 / 7.0);
          curX += step * math.cos(angle);
          curY += step * math.sin(angle);
          points.add(GesturePoint(x: curX, y: curY, timestampMs: i * 5));
        }

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, closeTo(points.first.x, 1e-9));
        expect(resampled.first.y, closeTo(points.first.y, 1e-9));
        expect(resampled.last.x, closeTo(points.last.x, 1e-9));
        expect(resampled.last.y, closeTo(points.last.y, 1e-9));
      });

      test('stroke with total path length exactly (63 * 1.0) maintains perfect 1.0 intervals', () {
        final points = List<GesturePoint>.generate(
          64,
          (i) => GesturePoint(x: i * 1.0, y: 0.0, timestampMs: i * 16),
        );

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        for (var i = 0; i < 64; i++) {
          expect(resampled[i].x, closeTo(i * 1.0, 1e-6));
          expect(resampled[i].y, closeTo(0.0, 1e-6));
        }
      });

      test('microscopic stroke path length (total L = 1e-4 px) produces 64 finite points', () {
        final points = List<GesturePoint>.generate(
          10,
          (i) => GesturePoint(x: i * 1e-5, y: i * 1e-5, timestampMs: i * 10),
        );

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, closeTo(0.0, 1e-12));
        expect(resampled.last.x, closeTo(9e-5, 1e-12));
      });

      test('massive stroke path length (total L = 1e6 px) produces 64 finite points', () {
        final points = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 1e6, y: 0.0, timestampMs: 1000),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, closeTo(0.0, 1e-6));
        expect(resampled.last.x, closeTo(1e6, 1e-6));
        final expectedInterval = 1e6 / 63.0;
        for (var i = 0; i < 63; i++) {
          final dist = resampled[i + 1].x - resampled[i].x;
          expect(dist, closeTo(expectedInterval, 1e-4));
        }
      });
    });

    // =========================================================================
    // 3. RESAMPLING STRESS: Exact 64-Point Invariant & Endpoint Anchoring
    // =========================================================================
    group('3. Resampling Stress: Endpoint Anchoring and Invariants', () {
      test('R_1 == P_1 and R_64 == P_n under extreme coordinate values', () {
        final points = <GesturePoint>[
          GesturePoint(x: -987654.321, y: 123456.789, timestampMs: 100),
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 200),
          GesturePoint(x: 456789.123, y: -789123.456, timestampMs: 300),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, equals(points.first.x));
        expect(resampled.first.y, equals(points.first.y));
        expect(resampled.last.x, equals(points.last.x));
        expect(resampled.last.y, equals(points.last.y));
      });

      test('closed loop trajectory (P_1 == P_n) anchors both ends correctly', () {
        final points = <GesturePoint>[
          GesturePoint(x: 50.0, y: 50.0, timestampMs: 0),
          GesturePoint(x: 100.0, y: 100.0, timestampMs: 100),
          GesturePoint(x: 100.0, y: 0.0, timestampMs: 200),
          GesturePoint(x: 50.0, y: 50.0, timestampMs: 300),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
        expect(resampled.first.x, equals(50.0));
        expect(resampled.first.y, equals(50.0));
        expect(resampled.last.x, equals(50.0));
        expect(resampled.last.y, equals(50.0));
      });

      test('throws FormatException if points have 0.0 total length (all identical)', () {
        final points = List<GesturePoint>.generate(
          20,
          (i) => GesturePoint(x: 42.0, y: 42.0, timestampMs: 100),
        );
        expect(() => GestureResampler.resample(points), throwsFormatException);
      });
    });

    // =========================================================================
    // 4. COORDINATE NORMALIZATION: Centroid Translation to 10^-9 Precision
    // =========================================================================
    group('4. Coordinate Normalization: Centroid Translation Accuracy to 10^-9', () {
      test('residual sum of coordinates after normalization is < 1e-9 across diverse canvas offsets', () {
        final testOffsets = [
          [0.0, 0.0],
          [500.0, 800.0],
          [1440.0, 3200.0],
          [10000.0, 20000.0],
          [-5000.0, -10000.0],
          [-250.0, 250.0],
        ];

        for (final offset in testOffsets) {
          final raw = List<GesturePoint>.generate(10, (i) {
            final t = i / 9.0;
            return GesturePoint(
              x: offset[0] + (t * 150.0),
              y: offset[1] + (t * t * 100.0),
              timestampMs: i * 20,
            );
          });

          final resampled = GestureResampler.resample(raw, targetCount: 64);
          final normalized = GestureNormalizer.normalizeCoordinates(resampled);

          expect(normalized.length, equals(64));

          double sumX = 0.0;
          double sumY = 0.0;
          for (final p in normalized) {
            sumX += p.x;
            sumY += p.y;
          }

          final centroidX = sumX / 64.0;
          final centroidY = sumY / 64.0;

          expect(
            centroidX.abs(),
            lessThan(1e-9),
            reason: 'Centroid X residual ${centroidX.abs()} exceeded 1e-9 for offset $offset',
          );
          expect(
            centroidY.abs(),
            lessThan(1e-9),
            reason: 'Centroid Y residual ${centroidY.abs()} exceeded 1e-9 for offset $offset',
          );
        }
      });

      test('centroid residual across extreme canvas offsets (up to 100,000 px)', () {
        for (final offset in [50000.0, 100000.0]) {
          final raw = List<GesturePoint>.generate(10, (i) {
            final t = i / 9.0;
            return GesturePoint(
              x: offset + (t * 200.0),
              y: offset + (t * 200.0),
              timestampMs: i * 20,
            );
          });

          final resampled = GestureResampler.resample(raw, targetCount: 64);
          final normalized = GestureNormalizer.normalizeCoordinates(resampled);

          double sumX = 0.0;
          double sumY = 0.0;
          for (final p in normalized) {
            sumX += p.x;
            sumY += p.y;
          }

          final centroidX = sumX / 64.0;
          final centroidY = sumY / 64.0;

          expect(centroidX.abs(), lessThan(1e-9));
          expect(centroidY.abs(), lessThan(1e-9));
        }
      });

      test('characterizes floating-point amplification on microscopic sub-sanity strokes (< 0.01px span)', () {
        // Microscopic stroke: W = 0.001px, H = 0.001px at canvas offset (600, 600)
        // Scale factor B / W = 250 / 0.001 = 250,000x
        final raw = [
          GesturePoint(x: 600.0, y: 600.0, timestampMs: 0),
          GesturePoint(x: 600.001, y: 600.001, timestampMs: 100),
        ];

        final resampled = GestureResampler.resample(raw, targetCount: 64);
        final normalized = GestureNormalizer.normalizeCoordinates(resampled);

        double sumX = 0.0;
        double sumY = 0.0;
        for (final p in normalized) {
          sumX += p.x;
          sumY += p.y;
        }

        final centroidX = sumX / 64.0;
        final centroidY = sumY / 64.0;

        // Due to single-pass centroid centering, the 250,000x scale factor magnifies
        // the ~1e-13 base rounding error around 600.0 to ~2.5e-8.
        // It stays bounded by 1e-7, but exceeds 1e-9 without a second centering pass.
        expect(centroidX.abs(), lessThan(1e-7));
        expect(centroidY.abs(), lessThan(1e-7));
      });
    });

    // =========================================================================
    // 5. COORDINATE NORMALIZATION: 1D vs 2D Boundary Cases & Aspect Scaling
    // =========================================================================
    group('5. Coordinate Normalization: 1D Straight Lines vs 2D Shapes & Boundary Cases', () {
      test('1D perfectly horizontal straight line scales uniformly by B / max(W, H)', () {
        final raw = <GesturePoint>[
          GesturePoint(x: 100.0, y: 50.0, timestampMs: 0),
          GesturePoint(x: 350.0, y: 50.0, timestampMs: 300),
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

        // B = 250.0
        expect(maxX - minX, closeTo(250.0, 1e-6));
        expect(minX, closeTo(-125.0, 1e-6));
        expect(maxX, closeTo(125.0, 1e-6));
        // Y remains 0.0
        expect(maxY - minY, closeTo(0.0, 1e-9));
        expect(minY, closeTo(0.0, 1e-9));
      });

      test('1D perfectly vertical straight line scales uniformly by B / max(W, H)', () {
        final raw = <GesturePoint>[
          GesturePoint(x: 40.0, y: 200.0, timestampMs: 0),
          GesturePoint(x: 40.0, y: 700.0, timestampMs: 500),
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

        // B = 250.0 on Y
        expect(maxY - minY, closeTo(250.0, 1e-6));
        expect(minY, closeTo(-125.0, 1e-6));
        expect(maxY, closeTo(125.0, 1e-6));
        // X remains 0.0
        expect(maxX - minX, closeTo(0.0, 1e-9));
      });

      test('boundary aspect ratio 0.19999 classifies as 1D uniform scaling', () {
        // Width = 1000.0, Height = 199.99 -> aspect ratio = 0.19999 < 0.20
        final classification = GestureNormalizer.classifyDimensionality(1000.0, 199.99);
        expect(classification, equals(GestureDimensionalityType.oneDimensional));

        final raw = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 1000.0, y: 199.99, timestampMs: 500),
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

        final w = maxX - minX;
        final h = maxY - minY;

        // Dominant axis W = 250.0
        expect(w, closeTo(250.0, 1e-5));
        // Minor axis H scaled uniformly by 250.0 / 1000.0 = 0.25 -> 199.99 * 0.25 = 49.9975
        expect(h, closeTo(49.9975, 1e-4));
        expect(h / w, closeTo(0.19999, 1e-5));
      });

      test('boundary aspect ratio 0.20001 classifies as 2D non-uniform scaling', () {
        // Width = 1000.0, Height = 200.01 -> aspect ratio = 0.20001 >= 0.20
        final classification = GestureNormalizer.classifyDimensionality(1000.0, 200.01);
        expect(classification, equals(GestureDimensionalityType.twoDimensional));

        final raw = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 1000.0, y: 200.01, timestampMs: 500),
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

        final w = maxX - minX;
        final h = maxY - minY;

        // Both axes non-uniformly scaled to reference square 250x250
        expect(w, closeTo(250.0, 1e-5));
        expect(h, closeTo(250.0, 1e-5));
      });

      test('exact boundary aspect ratio 0.20000 classifies as 2D non-uniform scaling', () {
        final classification = GestureNormalizer.classifyDimensionality(100.0, 20.0);
        expect(classification, equals(GestureDimensionalityType.twoDimensional));
      });
    });

    // =========================================================================
    // 6. ZERO DIVISION & DEGENERATE GEOMETRY DEFENSES
    // =========================================================================
    group('6. Zero Division & Degenerate Geometry Defenses', () {
      test('classifyDimensionality with 0 width and 0 height safely returns oneDimensional', () {
        final classification = GestureNormalizer.classifyDimensionality(0.0, 0.0);
        expect(classification, equals(GestureDimensionalityType.oneDimensional));
      });

      test('normalizeCoordinates with 64 coincident points safely produces 64 origin points without NaN', () {
        final coincident = List<GesturePoint>.generate(
          64,
          (i) => GesturePoint(x: 100.0, y: 200.0, timestampMs: 100),
        );

        final normalized = GestureNormalizer.normalizeCoordinates(coincident);
        expect(normalized.length, equals(64));
        for (final p in normalized) {
          expect(p.x, equals(0.0));
          expect(p.y, equals(0.0));
          expect(p.x.isNaN, isFalse);
          expect(p.y.isNaN, isFalse);
        }
      });

      test('GesturePoint constructor throws FormatException on NaN or Infinite coordinates', () {
        expect(
          () => GesturePoint(x: double.nan, y: 0.0, timestampMs: 0),
          throwsFormatException,
        );
        expect(
          () => GesturePoint(x: 0.0, y: double.infinity, timestampMs: 0),
          throwsFormatException,
        );
      });

      test('normalizeCoordinates throws FormatException on non-64 length inputs', () {
        final list63 = List<GesturePoint>.generate(
          63,
          (i) => GesturePoint(x: i * 1.0, y: i * 1.0, timestampMs: i * 10),
        );
        expect(
          () => GestureNormalizer.normalizeCoordinates(list63),
          throwsFormatException,
        );
      });
    });

    // =========================================================================
    // 7. PROPERTY-BASED FUZZING: Random Geometries & Stress Verification
    // =========================================================================
    group('7. Property-Based Fuzzing & Invariant Verification (500 Random Strokes)', () {
      test('all invariants hold across 500 randomized multi-stroke trajectories', () {
        final rng = math.Random(1337);

        for (var trial = 0; trial < 500; trial++) {
          final pointCount = 2 + rng.nextInt(200); // 2 to 201 points
          final startX = (rng.nextDouble() - 0.5) * 2000.0;
          final startY = (rng.nextDouble() - 0.5) * 2000.0;

          final rawPoints = <GesturePoint>[
            GesturePoint(x: startX, y: startY, timestampMs: 0),
          ];

          var cx = startX;
          var cy = startY;
          var curTime = 0;

          for (var i = 1; i < pointCount; i++) {
            // Random step length: mix of tiny (1e-4) and large (100.0) jumps
            final stepType = rng.nextInt(5);
            final double step;
            if (stepType == 0) {
              step = 0.0; // coincident
            } else if (stepType == 1) {
              step = rng.nextDouble() * 0.01; // sub-pixel cluster
            } else {
              step = rng.nextDouble() * 50.0; // standard / large jump
            }

            final angle = rng.nextDouble() * 2 * math.pi;
            cx += step * math.cos(angle);
            cy += step * math.sin(angle);
            curTime += rng.nextInt(30);

            rawPoints.add(GesturePoint(x: cx, y: cy, timestampMs: curTime));
          }

          final totalLen = GestureResampler.computePathLength(rawPoints);
          if (totalLen <= 0.0) {
            // Coincident stroke, skip
            continue;
          }

          // Invariant 1: Resampling produces exactly 64 points
          final resampled = GestureResampler.resample(rawPoints);
          expect(resampled.length, equals(64),
              reason: 'Trial $trial failed length invariant');

          // Invariant 2: Endpoint anchoring R_1 = P_1, R_64 = P_n
          expect(resampled.first.x, closeTo(rawPoints.first.x, 1e-9),
              reason: 'Trial $trial failed start point X anchoring');
          expect(resampled.first.y, closeTo(rawPoints.first.y, 1e-9),
              reason: 'Trial $trial failed start point Y anchoring');
          expect(resampled.last.x, closeTo(rawPoints.last.x, 1e-9),
              reason: 'Trial $trial failed end point X anchoring');
          expect(resampled.last.y, closeTo(rawPoints.last.y, 1e-9),
              reason: 'Trial $trial failed end point Y anchoring');

          // Invariant 3: Normalization produces exactly 64 points
          final normalized = GestureNormalizer.normalizeCoordinates(resampled);
          expect(normalized.length, equals(64),
              reason: 'Trial $trial failed normalized length');

          // Invariant 4: Centroid residual < 1e-9
          double sumX = 0.0;
          double sumY = 0.0;
          for (final p in normalized) {
            sumX += p.x;
            sumY += p.y;
          }
          final centroidX = sumX / 64.0;
          final centroidY = sumY / 64.0;
          double minRx = double.infinity, maxRx = -double.infinity;
          double minRy = double.infinity, maxRy = -double.infinity;
          for (final p in resampled) {
            if (p.x < minRx) minRx = p.x;
            if (p.x > maxRx) maxRx = p.x;
            if (p.y < minRy) minRy = p.y;
            if (p.y > maxRy) maxRy = p.y;
          }
          final span = math.max(maxRx - minRx, maxRy - minRy);

          // For pipeline-valid strokes (span >= 28.0px), centroid residual is strictly < 1e-9.
          // For microscopic sub-sanity strokes (span < 28.0px), scaling factor B / span
          // magnifies the base rounding error; residual remains bounded by < 1e-7.
          final double tolerance = (span >= 28.0) ? 1e-9 : 1e-7;

          expect(centroidX.abs(), lessThan(tolerance),
              reason: 'Trial $trial (span=$span) failed centroid X residual: $centroidX vs tol $tolerance');
          expect(centroidY.abs(), lessThan(tolerance),
              reason: 'Trial $trial (span=$span) failed centroid Y residual: $centroidY vs tol $tolerance');

          // Invariant 5: All coordinates finite
          for (var i = 0; i < 64; i++) {
            expect(normalized[i].x.isFinite, isTrue);
            expect(normalized[i].y.isFinite, isTrue);
          }
        }
      });

      test('end-to-end pipeline (resample -> normalize) executes in Isolate.run', () async {
        final raw = List<GesturePoint>.generate(
          100,
          (i) => GesturePoint(
            x: 100.0 + (i * 2.0),
            y: 50.0 + 30.0 * math.sin(i * 0.1),
            timestampMs: i * 16,
          ),
        );

        final result = await Isolate.run(() {
          final resampled = GestureResampler.resample(raw);
          return GestureNormalizer.normalizeCoordinates(resampled);
        });

        expect(result.length, equals(64));
        expect(result.first.x.isFinite, isTrue);
        expect(result.last.x.isFinite, isTrue);
      });
    });
  });
}

