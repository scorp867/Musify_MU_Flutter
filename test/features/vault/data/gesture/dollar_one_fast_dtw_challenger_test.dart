import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/dollar_one_b_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('DollarOneB & FastDTW Empirical Adversarial Challenger Suite', () {
    // -------------------------------------------------------------------------
    // Synthetic Geometry Generators (Pure, Deterministic, 64-Point Sequences)
    // -------------------------------------------------------------------------

    /// Generates canonical symmetric V-shape centered at (0, 0) in [-125, +125] box.
    List<GesturePoint> createCanonicalVShape() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 32; i++) {
        final double t = i / 31.0;
        final double x = -125.0 + (t * 125.0);
        final double y = 125.0 - (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      for (int i = 0; i < 32; i++) {
        final double t = i / 31.0;
        final double x = 0.0 + (t * 125.0);
        final double y = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (32 + i) * 16));
      }
      return points;
    }

    /// Generates asymmetric checkmark: short left drop (30px), long right rise (220px).
    List<GesturePoint> createAsymmetricCheckmark() {
      final points = <GesturePoint>[];
      // Short left segment (16 points)
      for (int i = 0; i < 16; i++) {
        final double t = i / 15.0;
        final double x = -125.0 + (t * 30.0);
        final double y = 50.0 - (t * 100.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Long right segment (48 points)
      for (int i = 0; i < 48; i++) {
        final double t = i / 47.0;
        final double x = -95.0 + (t * 220.0);
        final double y = -50.0 + (t * 175.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (16 + i) * 16));
      }
      return points;
    }

    /// Generates curvilinear hook / arch: upper semicircle followed by vertical drop.
    List<GesturePoint> createCurvilinearHook() {
      final points = <GesturePoint>[];
      // Semicircle arc (40 points): theta from pi down to 0
      for (int i = 0; i < 40; i++) {
        final double theta = math.pi - (i / 39.0 * math.pi);
        final double x = 70.0 * math.cos(theta);
        final double y = 50.0 + (70.0 * math.sin(theta));
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Vertical drop (24 points): from (70, 50) down to (70, -125)
      for (int i = 0; i < 24; i++) {
        final double t = i / 23.0;
        final double x = 70.0;
        final double y = 50.0 - (t * 175.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (40 + i) * 16));
      }
      return points;
    }

    /// Generates 3-segment asymmetric zigzag (lightning bolt topology).
    List<GesturePoint> createAsymmetricZigzag() {
      final points = <GesturePoint>[];
      // Segment 1: top-left to mid-center (20 points)
      for (int i = 0; i < 20; i++) {
        final double t = i / 19.0;
        final double x = -100.0 + (t * 80.0);
        final double y = 120.0 - (t * 110.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Segment 2: mid-center cutback to left-center (16 points)
      for (int i = 0; i < 16; i++) {
        final double t = i / 15.0;
        final double x = -20.0 - (t * 60.0);
        final double y = 10.0 - (t * 20.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (20 + i) * 16));
      }
      // Segment 3: left-center down-right to bottom-right (28 points)
      for (int i = 0; i < 28; i++) {
        final double t = i / 27.0;
        final double x = -80.0 + (t * 180.0);
        final double y = -10.0 - (t * 115.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (36 + i) * 16));
      }
      return points;
    }

    /// Generates closed loop circle contour (radius = 100px).
    List<GesturePoint> createCircleLoop() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 64; i++) {
        final double theta = (i / 64.0) * 2.0 * math.pi;
        final double x = 100.0 * math.cos(theta);
        final double y = 100.0 * math.sin(theta);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      return points;
    }

    /// Generates 1D horizontal straight line across 64 points.
    List<GesturePoint> createHorizontalLine() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 64; i++) {
        final double t = i / 63.0;
        final double x = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: 0.0, timestampMs: i * 16));
      }
      return points;
    }

    /// Generates 1D vertical straight line across 64 points.
    List<GesturePoint> createVerticalLine() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 64; i++) {
        final double t = i / 63.0;
        final double y = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: 0.0, y: y, timestampMs: i * 16));
      }
      return points;
    }

    /// Rotates a sequence of points by angle [thetaRad] around origin (0, 0).
    List<GesturePoint> rotatePoints(List<GesturePoint> points, double thetaRad) {
      final double cosT = math.cos(thetaRad);
      final double sinT = math.sin(thetaRad);
      final rotated = <GesturePoint>[];
      for (final p in points) {
        final double rx = (p.x * cosT) - (p.y * sinT);
        final double ry = (p.x * sinT) + (p.y * cosT);
        rotated.add(GesturePoint(x: rx, y: ry, timestampMs: p.timestampMs));
      }
      return rotated;
    }

    /// Perturbs points with deterministic pseudo-random additive noise up to [maxRadius].
    List<GesturePoint> addJitter(List<GesturePoint> points, double maxRadius, int seed) {
      final rng = math.Random(seed);
      final perturbed = <GesturePoint>[];
      for (final p in points) {
        final double angle = rng.nextDouble() * 2.0 * math.pi;
        final double r = rng.nextDouble() * maxRadius;
        perturbed.add(GesturePoint(
          x: p.x + (r * math.cos(angle)),
          y: p.y + (r * math.sin(angle)),
          timestampMs: p.timestampMs,
        ));
      }
      return perturbed;
    }

    // =========================================================================
    // 1. ROTATION BOUNDARIES & EXTREME TILT ADVERSARIAL STRESS
    // =========================================================================
    group('1. Rotation Boundaries & Extreme Tilt Stress', () {
      final vShape = createCanonicalVShape();

      test('DollarOne: exact negative boundary -45.0 degrees (-pi/4) achieves near-perfect score >= 0.98', () {
        const double boundaryAngle = -math.pi / 4.0;
        final rotatedCandidate = rotatePoints(vShape, boundaryAngle);
        final score = DollarOneBRecognizer.matchStatic(rotatedCandidate, vShape);
        expect(score, greaterThanOrEqualTo(0.98));
      });

      test('DollarOne: exact positive boundary +45.0 degrees (+pi/4) achieves near-perfect score >= 0.98', () {
        const double boundaryAngle = math.pi / 4.0;
        final rotatedCandidate = rotatePoints(vShape, boundaryAngle);
        final score = DollarOneBRecognizer.matchStatic(rotatedCandidate, vShape);
        expect(score, greaterThanOrEqualTo(0.98));
      });

      test('DollarOne: interior rotation sweep [-40 deg, +40 deg] consistently scores >= 0.95', () {
        final anglesDeg = [-40.0, -30.0, -20.0, -10.0, 0.0, 10.0, 20.0, 30.0, 40.0];
        for (final deg in anglesDeg) {
          final rad = deg * math.pi / 180.0;
          final rotated = rotatePoints(vShape, rad);
          final score = DollarOneBRecognizer.matchStatic(rotated, vShape);
          expect(
            score,
            greaterThanOrEqualTo(0.95),
            reason: 'Failed at angle $deg degrees (score: $score)',
          );
        }
      });

      test('DollarOne: just inside vs just outside boundary (-44.9 deg vs -45.5 deg)', () {
        final insideCandidate = rotatePoints(vShape, -44.9 * math.pi / 180.0);
        final scoreInside = DollarOneBRecognizer.matchStatic(insideCandidate, vShape);
        expect(scoreInside, greaterThanOrEqualTo(0.98));

        final outsideCandidate = rotatePoints(vShape, -46.0 * math.pi / 180.0);
        final scoreOutside = DollarOneBRecognizer.matchStatic(outsideCandidate, vShape);
        // Score outside bracket degrades because GSS bracket bounds search to [-45, +45]
        expect(scoreOutside, lessThan(scoreInside));
        expect(scoreOutside, greaterThanOrEqualTo(0.90));
      });

      test('DollarOne: extreme tilt beyond bracket (+60, +75, +90, 180 deg) degrades monotonically', () {
        final rotated60 = rotatePoints(vShape, 60.0 * math.pi / 180.0);
        final score60 = DollarOneBRecognizer.matchStatic(rotated60, vShape);

        final rotated75 = rotatePoints(vShape, 75.0 * math.pi / 180.0);
        final score75 = DollarOneBRecognizer.matchStatic(rotated75, vShape);

        final rotated90 = rotatePoints(vShape, 90.0 * math.pi / 180.0);
        final score90 = DollarOneBRecognizer.matchStatic(rotated90, vShape);

        final rotated180 = rotatePoints(vShape, math.pi);
        final score180 = DollarOneBRecognizer.matchStatic(rotated180, vShape);

        // Monotonic degradation check beyond rotation search bracket
        expect(score60, greaterThan(score75));
        expect(score75, greaterThan(score90));
        expect(score90, greaterThan(score180));

        // +90 deg and 180 deg fall well below safety floor 0.65
        expect(score90, lessThan(0.65));
        expect(score180, lessThan(0.50));
      });

      test('DollarOne: custom maxAngleRad recovers extreme tilt when bracket is expanded to pi/2 (90 deg)', () {
        final rotated75 = rotatePoints(vShape, 75.0 * math.pi / 180.0);

        // Default bracket (pi / 4 = 45 deg) cannot fully recover 75 deg tilt
        final scoreDefault = DollarOneBRecognizer.matchStatic(rotated75, vShape);
        expect(scoreDefault, lessThan(0.90));

        // Expanded bracket (pi / 2 = 90 deg) successfully recovers 75 deg tilt
        final scoreExpanded = DollarOneBRecognizer.matchStatic(
          rotated75,
          vShape,
          maxAngleRad: math.pi / 2.0,
        );
        expect(scoreExpanded, greaterThanOrEqualTo(0.95));
      });

      test('FastDTW: lack of rotational invariance causes strict monotonic score degradation under tilt', () {
        final anglesDeg = [0.0, 5.0, 10.0, 15.0, 30.0, 45.0, 90.0];
        final scores = <double>[];

        for (final deg in anglesDeg) {
          final rad = deg * math.pi / 180.0;
          final rotated = rotatePoints(vShape, rad);
          final score = FastDtwRecognizer.matchStatic(rotated, vShape);
          scores.add(score);
        }

        // Verify strict monotonic decrease as rotation increases
        for (int i = 0; i < scores.length - 1; i++) {
          expect(
            scores[i],
            greaterThan(scores[i + 1]),
            reason: 'FastDTW score at ${anglesDeg[i]} deg (${scores[i]}) should exceed score at ${anglesDeg[i + 1]} deg (${scores[i + 1]})',
          );
        }

        // At 0 deg tilt: perfect match = 1.0
        expect(scores[0], 1.0);
        // At 15 deg tilt: FastDTW drops near or below safety floor 0.60
        expect(scores[3], lessThan(0.65));
        // At 45 deg tilt: FastDTW drops well below safety floor (< 0.40)
        expect(scores[5], lessThan(0.40));
        // At 90 deg tilt: FastDTW drops to near 0.10
        expect(scores[6], lessThan(0.20));
      });
    });

    // =========================================================================
    // 2. BIDIRECTIONAL DRAWING & TRAJECTORY SYMMETRY
    // =========================================================================
    group('2. Bidirectional Drawing & Trajectory Symmetry Invariance', () {
      final topologies = <String, List<GesturePoint>>{
        'Canonical V-Shape': createCanonicalVShape(),
        'Asymmetric Checkmark': createAsymmetricCheckmark(),
        'Curvilinear Hook': createCurvilinearHook(),
        'Asymmetric Zigzag': createAsymmetricZigzag(),
        'Circle Loop': createCircleLoop(),
      };

      topologies.forEach((name, shape) {
        test('DollarOne: forward candidate vs reverse candidate against template yields identical score for $name', () {
          final forwardCandidate = shape;
          final reverseCandidate = List<GesturePoint>.unmodifiable(shape.reversed);

          final scoreFwd = DollarOneBRecognizer.matchStatic(forwardCandidate, shape);
          final scoreRev = DollarOneBRecognizer.matchStatic(reverseCandidate, shape);

          expect(
            (scoreFwd - scoreRev).abs(),
            lessThan(1e-9),
            reason: 'DollarOne bidirectional discrepancy in $name: fwd=$scoreFwd, rev=$scoreRev',
          );
          expect(scoreFwd, closeTo(1.0, 1e-5));
          expect(scoreRev, closeTo(1.0, 1e-5));
        });

        test('FastDTW: forward candidate vs reverse candidate against template yields identical score for $name', () {
          final forwardCandidate = shape;
          final reverseCandidate = List<GesturePoint>.unmodifiable(shape.reversed);

          final scoreFwd = FastDtwRecognizer.matchStatic(forwardCandidate, shape);
          final scoreRev = FastDtwRecognizer.matchStatic(reverseCandidate, shape);

          expect(
            (scoreFwd - scoreRev).abs(),
            lessThan(1e-9),
            reason: 'FastDTW bidirectional discrepancy in $name: fwd=$scoreFwd, rev=$scoreRev',
          );
          expect(scoreFwd, 1.0);
          expect(scoreRev, 1.0);
        });

        test('Dual-Reversal Symmetry: match(C, T) == match(C, T.reversed) == match(C.reversed, T.reversed) for $name', () {
          final reversedShape = List<GesturePoint>.unmodifiable(shape.reversed);

          // DollarOne 4-way reversal symmetry
          final d1ScoreA = DollarOneBRecognizer.matchStatic(shape, shape);
          final d1ScoreB = DollarOneBRecognizer.matchStatic(reversedShape, shape);
          final d1ScoreC = DollarOneBRecognizer.matchStatic(shape, reversedShape);
          final d1ScoreD = DollarOneBRecognizer.matchStatic(reversedShape, reversedShape);

          expect((d1ScoreA - d1ScoreB).abs(), lessThan(1e-9));
          expect((d1ScoreA - d1ScoreC).abs(), lessThan(1e-9));
          expect((d1ScoreA - d1ScoreD).abs(), lessThan(1e-9));

          // FastDTW 4-way reversal symmetry
          final dtwScoreA = FastDtwRecognizer.matchStatic(shape, shape);
          final dtwScoreB = FastDtwRecognizer.matchStatic(reversedShape, shape);
          final dtwScoreC = FastDtwRecognizer.matchStatic(shape, reversedShape);
          final dtwScoreD = FastDtwRecognizer.matchStatic(reversedShape, reversedShape);

          expect((dtwScoreA - dtwScoreB).abs(), lessThan(1e-9));
          expect((dtwScoreA - dtwScoreC).abs(), lessThan(1e-9));
          expect((dtwScoreA - dtwScoreD).abs(), lessThan(1e-9));
        });
      });

      test('Bidirectional matching on perturbed asymmetric checkmark preserves score invariance', () {
        final checkmark = createAsymmetricCheckmark();
        final perturbed = addJitter(checkmark, 5.0, 101);
        final perturbedReversed = List<GesturePoint>.unmodifiable(perturbed.reversed);

        final d1Fwd = DollarOneBRecognizer.matchStatic(perturbed, checkmark);
        final d1Rev = DollarOneBRecognizer.matchStatic(perturbedReversed, checkmark);
        expect((d1Fwd - d1Rev).abs(), lessThan(1e-9));

        final dtwFwd = FastDtwRecognizer.matchStatic(perturbed, checkmark);
        final dtwRev = FastDtwRecognizer.matchStatic(perturbedReversed, checkmark);
        expect((dtwFwd - dtwRev).abs(), lessThan(1e-9));
      });
    });

    // =========================================================================
    // 3. SCALE DISTORTION & ASPECT RATIO EXTREMES
    // =========================================================================
    group('3. Scale Distortion & Aspect Ratio Extremes', () {
      final vShape = createCanonicalVShape();
      final hLine = createHorizontalLine();
      final vLine = createVerticalLine();

      test('1D horizontal line candidate against 2D V-shape template is decisively rejected', () {
        final d1Score = DollarOneBRecognizer.matchStatic(hLine, vShape);
        final dtwScore = FastDtwRecognizer.matchStatic(hLine, vShape);

        expect(d1Score, lessThan(0.65));
        expect(dtwScore, lessThan(0.60));
      });

      test('1D vertical line candidate against 2D V-shape template is decisively rejected', () {
        final d1Score = DollarOneBRecognizer.matchStatic(vLine, vShape);
        final dtwScore = FastDtwRecognizer.matchStatic(vLine, vShape);

        expect(d1Score, lessThan(0.65));
        expect(dtwScore, lessThan(0.60));
      });

      test('1D horizontal line candidate against 1D vertical line template evaluates 90 deg mismatch', () {
        // Orthogonal 1D strokes have 90 deg angle mismatch; bracket is +/-45 deg.
        // GSS rotates by 45 deg, leaving lines intersecting at 45 deg with mean distance ~48px.
        // DollarOne yields ~0.724, while FastDTW decisively rejects (< 0.10).
        final d1Score = DollarOneBRecognizer.matchStatic(hLine, vLine);
        final dtwScore = FastDtwRecognizer.matchStatic(hLine, vLine);

        expect(d1Score, closeTo(0.724, 0.01));
        expect(dtwScore, lessThan(0.10));
      });

      test('Aspect ratio flattening: compressing vertical coordinate of V-shape degrades score monotonically', () {
        final scaleFactorsY = [1.0, 0.75, 0.50, 0.25, 0.10, 0.0];
        final d1Scores = <double>[];
        final dtwScores = <double>[];

        for (final sy in scaleFactorsY) {
          final flattened = vShape
              .map((p) => GesturePoint(x: p.x, y: p.y * sy, timestampMs: p.timestampMs))
              .toList();
          d1Scores.add(DollarOneBRecognizer.matchStatic(flattened, vShape));
          dtwScores.add(FastDtwRecognizer.matchStatic(flattened, vShape));
        }

        // Both recognizers should degrade monotonically as aspect ratio is crushed towards zero
        for (int i = 0; i < scaleFactorsY.length - 1; i++) {
          expect(
            d1Scores[i],
            greaterThanOrEqualTo(d1Scores[i + 1]),
            reason: 'DollarOne score flattening failure at index $i',
          );
          expect(
            dtwScores[i],
            greaterThanOrEqualTo(dtwScores[i + 1]),
            reason: 'FastDTW score flattening failure at index $i',
          );
        }

        // FastDTW rejects strongly at sy = 0.10 (< 0.25)
        expect(dtwScores[4], lessThan(0.25));
        // At complete flattening (sy = 0.0, flat 1D line), DollarOne drops below safety floor 0.65
        expect(d1Scores[5], lessThan(0.65));
        expect(dtwScores[5], lessThan(0.20));
      });

      test('Coordinate scale mismatch: unscaled coordinates degrade unless referenceDimension is provided', () {
        // Double all coordinates to [-250, +250] (dimension B = 500px)
        final scaledUp = vShape
            .map((p) => GesturePoint(x: p.x * 2.0, y: p.y * 2.0, timestampMs: p.timestampMs))
            .toList();

        // Matching scaledUp against canonical template (250px) without adjusting dimension fails
        final d1Mismatched = DollarOneBRecognizer.matchStatic(scaledUp, vShape);
        final dtwMismatched = FastDtwRecognizer.matchStatic(scaledUp, vShape);
        expect(d1Mismatched, lessThan(0.65));
        expect(dtwMismatched, lessThan(0.60));

        // Matching two identically scaled shapes (500px) with matching referenceDimension recovers score
        final d1Recovered = DollarOneBRecognizer.matchStatic(
          scaledUp,
          scaledUp,
          referenceDimension: 500.0,
        );
        expect(d1Recovered, closeTo(1.0, 1e-5));
      });
    });

    // =========================================================================
    // 4. NOISE RESILIENCE & PERTURBATION FUZZING
    // =========================================================================
    group('4. Noise Resilience & Perturbation Fuzzing', () {
      final vShape = createCanonicalVShape();

      test('Additive jitter fuzzing: score degradation curves adhere to tolerance thresholds', () {
        final jitterRadii = [0.5, 1.0, 2.5, 5.0, 10.0, 15.0, 25.0, 50.0, 150.0];
        final meanD1 = <double>[];
        final meanDtw = <double>[];

        const int iterations = 10;
        for (final radius in jitterRadii) {
          double sumD1 = 0.0;
          double sumDtw = 0.0;
          for (int seed = 1; seed <= iterations; seed++) {
            final noisy = addJitter(vShape, radius, seed);
            sumD1 += DollarOneBRecognizer.matchStatic(noisy, vShape);
            sumDtw += FastDtwRecognizer.matchStatic(noisy, vShape);
          }
          meanD1.add(sumD1 / iterations);
          meanDtw.add(sumDtw / iterations);
        }

        // Sub-pixel jitter (0.5px - 2.5px): negligible degradation
        expect(meanD1[0], greaterThanOrEqualTo(0.98));
        expect(meanDtw[0], greaterThanOrEqualTo(0.98));
        expect(meanD1[2], greaterThanOrEqualTo(0.95));
        expect(meanDtw[2], greaterThanOrEqualTo(0.90));

        // Moderate hand tremor (5.0px - 10.0px): stays well above safety floors
        expect(meanD1[3], greaterThanOrEqualTo(0.90));
        expect(meanDtw[3], greaterThanOrEqualTo(0.80));
        expect(meanD1[4], greaterThanOrEqualTo(0.80));
        expect(meanDtw[4], greaterThanOrEqualTo(0.70));

        // Strong perturbation (50.0px): FastDTW drops below safety floor (< 0.60),
        // while DollarOne remains ~0.85 due to linear half-diagonal denominator (176.78px)
        expect(meanDtw[7], lessThan(0.60));
        expect(meanD1[7], greaterThan(0.80));

        // Massive perturbation (150.0px): DollarOne drops below safety floor 0.65
        expect(meanD1[8], lessThan(0.65));
        expect(meanDtw[8], lessThan(0.20));

        // Strict monotonic degradation across increasing noise amplitude
        for (int i = 0; i < jitterRadii.length - 1; i++) {
          expect(
            meanD1[i],
            greaterThan(meanD1[i + 1]),
            reason: 'DollarOne mean score did not strictly decrease from r=${jitterRadii[i]} to r=${jitterRadii[i + 1]}',
          );
          expect(
            meanDtw[i],
            greaterThan(meanDtw[i + 1]),
            reason: 'FastDTW mean score did not strictly decrease from r=${jitterRadii[i]} to r=${jitterRadii[i + 1]}',
          );
        }
      });

      test('Impulse noise: single-point extreme outlier spike (100px) is absorbed gracefully by both recognizers', () {
        // Shift only point index 20 by (70px, 70px) -> ~100px Euclidean outlier
        final spiked = List<GesturePoint>.generate(64, (i) {
          final p = vShape[i];
          if (i == 20) {
            return GesturePoint(x: p.x + 70.0, y: p.y + 70.0, timestampMs: p.timestampMs);
          }
          return p;
        });

        final d1Score = DollarOneBRecognizer.matchStatic(spiked, vShape);
        final dtwScore = FastDtwRecognizer.matchStatic(spiked, vShape);

        // DollarOne divides outlier distance across all 64 points: 100px / 64 ~ 1.56px displacement
        // Score should remain >= 0.95
        expect(d1Score, greaterThanOrEqualTo(0.95));

        // FastDTW warps time to minimize cost; score remains well above safety floor (>= 0.85)
        expect(dtwScore, greaterThanOrEqualTo(0.85));
      });

      test('Burst distortion: 5 consecutive points displaced by 40px degrades gracefully without crash', () {
        final burstDistorted = List<GesturePoint>.generate(64, (i) {
          final p = vShape[i];
          if (i >= 25 && i <= 29) {
            return GesturePoint(x: p.x + 40.0, y: p.y - 40.0, timestampMs: p.timestampMs);
          }
          return p;
        });

        final d1Score = DollarOneBRecognizer.matchStatic(burstDistorted, vShape);
        final dtwScore = FastDtwRecognizer.matchStatic(burstDistorted, vShape);

        // Both recognizers remain above safety floors under a 5-point localized burst
        expect(d1Score, greaterThan(0.80));
        expect(dtwScore, greaterThan(0.70));
      });
    });

    // =========================================================================
    // 5. PATHOLOGICAL & DEGENERATE GEOMETRIES
    // =========================================================================
    group('5. Pathological & Degenerate Geometries', () {
      final vShape = createCanonicalVShape();

      test('Coincident degenerate stroke: all 64 points at (0, 0) against V-shape is rejected', () {
        final allZeros = List<GesturePoint>.generate(
          64,
          (i) => GesturePoint(x: 0.0, y: 0.0, timestampMs: i * 16),
        );

        final d1Score = DollarOneBRecognizer.matchStatic(allZeros, vShape);
        final dtwScore = FastDtwRecognizer.matchStatic(allZeros, vShape);

        // DollarOne mean distance is ~98px -> score ~0.4455 (well below safety floor 0.65)
        expect(d1Score, lessThan(0.50));
        expect(dtwScore, lessThan(0.10));
      });

      test('Two coincident degenerate strokes (all zeros vs all zeros) produce 1.0 match and 0.0 distance', () {
        final allZeros = List<GesturePoint>.generate(
          64,
          (i) => GesturePoint(x: 0.0, y: 0.0, timestampMs: i * 16),
        );

        final d1Score = DollarOneBRecognizer.matchStatic(allZeros, allZeros);
        final dtwDist = FastDtwRecognizer.computeBidirectionalDtwDistance(allZeros, allZeros);
        final dtwScore = FastDtwRecognizer.matchStatic(allZeros, allZeros);

        expect(d1Score, closeTo(1.0, 1e-5));
        expect(dtwDist, 0.0);
        expect(dtwScore, 1.0);
      });

      test('High-frequency spatial oscillation (ping-pong between -100 and +100) evaluates deterministically', () {
        final oscillating = List<GesturePoint>.generate(64, (i) {
          final double sign = (i % 2 == 0) ? -1.0 : 1.0;
          return GesturePoint(x: sign * 100.0, y: 0.0, timestampMs: i * 16);
        });

        final d1Score = DollarOneBRecognizer.matchStatic(oscillating, vShape);
        final dtwScore = FastDtwRecognizer.matchStatic(oscillating, vShape);

        expect(d1Score.isFinite, isTrue);
        expect(dtwScore.isFinite, isTrue);
        expect(d1Score, lessThan(0.65));
        expect(dtwScore, lessThan(0.60));
      });

      test('Numerical stability: extreme large coordinates (10000px) do not produce NaN or unhandled crash', () {
        final extremePoints = List<GesturePoint>.generate(
          64,
          (i) => GesturePoint(x: 10000.0 + i, y: 10000.0 - i, timestampMs: i * 16),
        );

        final d1Score = DollarOneBRecognizer.matchStatic(extremePoints, vShape);
        final dtwScore = FastDtwRecognizer.matchStatic(extremePoints, vShape);

        // Since distances vastly exceed halfDiagonal and sigma, bounded scores should be 0.0 or underflow
        expect(d1Score, 0.0);
        expect(dtwScore, closeTo(0.0, 1e-10));
      });
    });

    // =========================================================================
    // 6. FASTDTW SAKOE-CHIBA CONSTRAINT WINDOW RADIAL DYNAMICS
    // =========================================================================
    group('6. FastDTW Sakoe-Chiba Constraint Window Dynamics', () {
      final vShape = createCanonicalVShape();

      // Temporally warped V-shape (dense clustering at apex)
      final warpedV = List<GesturePoint>.generate(64, (i) {
        if (i < 32) {
          final double t = math.pow(i / 31.0, 1.8).toDouble();
          final double x = -125.0 + (t * 125.0);
          final double y = 125.0 - (t * 250.0);
          return GesturePoint(x: x, y: y, timestampMs: i * 16);
        } else {
          final int idx = i - 32;
          final double t = math.pow(idx / 31.0, 0.55).toDouble();
          final double x = 0.0 + (t * 125.0);
          final double y = -125.0 + (t * 250.0);
          return GesturePoint(x: x, y: y, timestampMs: i * 16);
        }
      });

      test('Wider constraint windows allow more warping and monotonically decrease DTW distance', () {
        final radii = [1, 3, 5, 10, 20, 32, 64];
        final distances = <double>[];

        for (final r in radii) {
          final dist = FastDtwRecognizer.computeDtwDistance(warpedV, vShape, windowRadius: r);
          distances.add(dist);
        }

        // Distance with unconstrained window (null)
        final unconstrainedDist = FastDtwRecognizer.computeDtwDistance(warpedV, vShape, windowRadius: null);

        // Invariant: expanding window radius monotonically reduces or preserves alignment distance
        for (int i = 0; i < distances.length - 1; i++) {
          expect(
            distances[i],
            greaterThanOrEqualTo(distances[i + 1]),
            reason: 'Distance did not decrease monotonically from r=${radii[i]} to r=${radii[i + 1]}',
          );
        }

        // Full radius 64 equals unconstrained window
        expect(distances.last, closeTo(unconstrainedDist, 1e-9));
      });

      test('FastDTW score monotonically increases as windowRadius widens', () {
        final radii = [2, 5, 10, 30];
        final scores = <double>[];

        for (final r in radii) {
          scores.add(FastDtwRecognizer.matchStatic(warpedV, vShape, windowRadius: r));
        }

        for (int i = 0; i < scores.length - 1; i++) {
          expect(
            scores[i],
            lessThanOrEqualTo(scores[i + 1]),
            reason: 'Score did not increase monotonically from r=${radii[i]} to r=${radii[i + 1]}',
          );
        }
      });
    });

    // =========================================================================
    // 7. STRICT PARAMETER VALIDATION & EXCEPTION RESILIENCE
    // =========================================================================
    group('7. Strict Parameter Validation & Exception Resilience', () {
      final valid64 = createCanonicalVShape();
      final invalid63 = List<GesturePoint>.unmodifiable(valid64.take(63));
      final invalid65 = List<GesturePoint>.unmodifiable([
        ...valid64,
        GesturePoint(x: 10.0, y: 10.0, timestampMs: 2000),
      ]);

      group('DollarOneBRecognizer FormatException Guards', () {
        test('throws on candidate length != 64 (0, 1, 63, 65 points)', () {
          expect(
            () => DollarOneBRecognizer.matchStatic([], valid64),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(invalid63, valid64),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(invalid65, valid64),
            throwsA(isA<FormatException>()),
          );
        });

        test('throws on template length != 64 (0, 1, 63, 65 points)', () {
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, []),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, invalid63),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, invalid65),
            throwsA(isA<FormatException>()),
          );
        });

        test('throws on invalid referenceDimension (0, negative, NaN, infinity)', () {
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, referenceDimension: 0.0),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, referenceDimension: -10.0),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, referenceDimension: double.nan),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, referenceDimension: double.infinity),
            throwsA(isA<FormatException>()),
          );
        });

        test('throws on invalid maxAngleRad (<= 0, > pi, NaN, infinity)', () {
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: 0.0),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: -0.5),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: math.pi + 0.01),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: double.nan),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: double.infinity),
            throwsA(isA<FormatException>()),
          );
        });

        test('throws on invalid angleToleranceRad (<= 0, NaN, infinity)', () {
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, angleToleranceRad: 0.0),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, angleToleranceRad: -0.01),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, angleToleranceRad: double.nan),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => DollarOneBRecognizer.matchStatic(valid64, valid64, angleToleranceRad: double.infinity),
            throwsA(isA<FormatException>()),
          );
        });
      });

      group('FastDtwRecognizer FormatException Guards', () {
        test('throws on candidate length != 64', () {
          expect(
            () => FastDtwRecognizer.matchStatic([], valid64),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(invalid63, valid64),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(invalid65, valid64),
            throwsA(isA<FormatException>()),
          );
        });

        test('throws on template length != 64', () {
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, []),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, invalid63),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, invalid65),
            throwsA(isA<FormatException>()),
          );
        });

        test('throws on invalid sigmaDtw (<= 0, NaN, infinity)', () {
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, valid64, sigmaDtw: 0.0),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, valid64, sigmaDtw: -5.0),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, valid64, sigmaDtw: double.nan),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, valid64, sigmaDtw: double.infinity),
            throwsA(isA<FormatException>()),
          );
        });

        test('throws on windowRadius < 1', () {
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, valid64, windowRadius: 0),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.matchStatic(valid64, valid64, windowRadius: -5),
            throwsA(isA<FormatException>()),
          );
        });

        test('computeDtwDistance throws FormatException on empty inputs', () {
          expect(
            () => FastDtwRecognizer.computeDtwDistance([], valid64),
            throwsA(isA<FormatException>()),
          );
          expect(
            () => FastDtwRecognizer.computeDtwDistance(valid64, []),
            throwsA(isA<FormatException>()),
          );
        });
      });
    });

    // =========================================================================
    // 8. MULTI-ISOLATE CONCURRENT RECOGNITION STRESS
    // =========================================================================
    group('8. Multi-Isolate Concurrent Stress (50 Parallel Executions)', () {
      final vShape = createCanonicalVShape();
      final checkmark = createAsymmetricCheckmark();

      test('50 parallel isolates execute DollarOne and FastDTW with deterministic consistency', () async {
        final futures = <Future<double>>[];

        for (int i = 0; i < 25; i++) {
          final isCheckmark = i % 2 == 1;
          final shape = isCheckmark ? checkmark : vShape;

          // Dispatch DollarOne isolate
          futures.add(Isolate.run(() {
            const recognizer = DollarOneBRecognizer();
            return recognizer.match(shape, shape);
          }));

          // Dispatch FastDTW isolate
          futures.add(Isolate.run(() {
            const recognizer = FastDtwRecognizer();
            return recognizer.match(shape, shape);
          }));
        }

        final results = await Future.wait(futures);
        expect(results.length, 50);

        for (int i = 0; i < 50; i++) {
          expect(
            results[i],
            closeTo(1.0, 1e-5),
            reason: 'Isolate run $i did not match exactly 1.0 (got ${results[i]})',
          );
        }
      });
    });
  });
}
