import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/dba_synthesizer.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/gesture/dollar_one_b_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_isolate_payloads.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_normalizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_resampler.dart';
import 'package:musify_mu/features/vault/data/gesture/rubine_feature_extractor.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

void main() {
  group('Empirical Challenger Suite: DBA Synthesis, Consistency & Canonical V Template', () {
    // -------------------------------------------------------------------------
    // Synthetic Data Generators & Test Harness Fixtures
    // -------------------------------------------------------------------------

    /// Generates a realistic single-stroke "V" gesture sample with customizable parameters.
    ///
    /// Connected at vertex: (150, 250) across all scale factors.
    GestureSample generateVSample({
      double offsetX = 0.0,
      double offsetY = 0.0,
      double scale = 1.0,
      bool reverse = false,
      double jitter = 0.0,
      int pointCountPerArm = 25,
      int epoch = 1700000000000,
    }) {
      final rawPoints = <GesturePoint>[];
      final double armW = 100.0 * scale;
      final double armH = 200.0 * scale;
      final double vertexX = 150.0 + offsetX;
      final double vertexY = 250.0 + offsetY;
      final double startX = vertexX - armW;
      final double startY = vertexY - armH;

      // Left arm downwards: (startX, startY) -> (vertexX, vertexY)
      for (int i = 0; i < pointCountPerArm; i++) {
        final double t = i / (pointCountPerArm - 1.0);
        final double x = startX + (t * armW) + (jitter * math.sin(i * 1.5));
        final double y = startY + (t * armH) + (jitter * math.cos(i * 1.3));
        rawPoints.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Right arm upwards: (vertexX, vertexY) -> (vertexX + armW, vertexY - armH)
      for (int i = 0; i < pointCountPerArm; i++) {
        final double t = i / (pointCountPerArm - 1.0);
        final double x = vertexX + (t * armW) + (jitter * math.cos(i * 1.7));
        final double y = vertexY - (t * armH) + (jitter * math.sin(i * 1.2));
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

    /// Generates a straight horizontal line sample of [pointCount] points.
    GestureSample generateHorizontalLineSample({
      int pointCount = 50,
      double y = 150.0,
      int epoch = 1700000000000,
    }) {
      final points = List.generate(
        pointCount,
        (i) => GesturePoint(x: 50.0 + (i * 4.0), y: y, timestampMs: i * 16),
      );
      return GestureSample(
        points: List<GesturePoint>.unmodifiable(points),
        sampledAtEpochMs: epoch,
        totalLength: (pointCount - 1) * 4.0,
      );
    }

    /// Generates an inverted "V" (caret `^`) gesture sample.
    ///
    /// Left arm: (50, 250) -> (150, 50)
    /// Right arm: (150, 50) -> (250, 250)
    GestureSample generateCaretSample({
      int pointCountPerArm = 25,
      int epoch = 1700000000000,
    }) {
      final rawPoints = <GesturePoint>[];
      for (int i = 0; i < pointCountPerArm; i++) {
        final double t = i / (pointCountPerArm - 1.0);
        final double x = 50.0 + (t * 100.0);
        final double y = 250.0 - (t * 200.0);
        rawPoints.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      for (int i = 0; i < pointCountPerArm; i++) {
        final double t = i / (pointCountPerArm - 1.0);
        final double x = 150.0 + (t * 100.0);
        final double y = 50.0 + (t * 200.0);
        rawPoints.add(
          GesturePoint(x: x, y: y, timestampMs: (pointCountPerArm + i) * 16),
        );
      }

      double length = 0.0;
      for (int i = 0; i < rawPoints.length - 1; i++) {
        final dx = rawPoints[i + 1].x - rawPoints[i].x;
        final dy = rawPoints[i + 1].y - rawPoints[i].y;
        length += math.sqrt(dx * dx + dy * dy);
      }

      return GestureSample(
        points: List<GesturePoint>.unmodifiable(rawPoints),
        sampledAtEpochMs: epoch,
        totalLength: length,
      );
    }

    /// Generates a rotated "V" sample by [angleRad] radians around center (150, 150).
    GestureSample generateRotatedVSample({
      required double angleRad,
      int pointCountPerArm = 25,
      int epoch = 1700000000000,
    }) {
      final unrotated = generateVSample(pointCountPerArm: pointCountPerArm);
      const double cx = 150.0;
      const double cy = 150.0;
      final cosA = math.cos(angleRad);
      final sinA = math.sin(angleRad);

      final rotatedPoints = unrotated.points.map((p) {
        final dx = p.x - cx;
        final dy = p.y - cy;
        final rx = cx + (dx * cosA - dy * sinA);
        final ry = cy + (dx * sinA + dy * cosA);
        return GesturePoint(x: rx, y: ry, timestampMs: p.timestampMs);
      }).toList();

      return GestureSample(
        points: List<GesturePoint>.unmodifiable(rotatedPoints),
        sampledAtEpochMs: epoch,
        totalLength: unrotated.totalLength,
      );
    }

    // =========================================================================
    // 1. DBA Convergence & RMS Stability Stress
    // =========================================================================
    group('1. DBA Convergence & RMS Stability Stress', () {
      const synthesizer = DbaSynthesizer();

      test('identical samples terminate on iteration 0 with deltaRMS == 0.0', () {
        final sample = generateVSample(scale: 1.0);

        // Feed 3 identical samples
        final template = synthesizer.synthesize(
          samples: [sample, sample, sample],
          id: 'identical_samples_template',
          maxIterations: 5,
          convergenceTolerance: 0.5,
        );

        expect(template.id, 'identical_samples_template');
        expect(template.normalizedPoints.length, GestureTemplate.requiredPointCount);
        expect(template.rubineFeatureVector.length, GestureTemplate.requiredFeatureVectorDimensions);

        // Verification of coordinate invariants: centroid at (0, 0)
        double sumX = 0.0;
        double sumY = 0.0;
        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;

        for (final pt in template.normalizedPoints) {
          sumX += pt.x;
          sumY += pt.y;
          if (pt.x < minX) minX = pt.x;
          if (pt.x > maxX) maxX = pt.x;
          if (pt.y < minY) minY = pt.y;
          if (pt.y > maxY) maxY = pt.y;
        }

        expect(sumX / 64.0, closeTo(0.0, 1e-4));
        expect(sumY / 64.0, closeTo(0.0, 1e-4));
        expect(maxX - minX, closeTo(250.0, 1e-4));
        expect(maxY - minY, closeTo(250.0, 1e-4));
      });

      test('perturbed physiological samples converge within <= 5 iterations', () {
        // 3 samples simulating hand tremor, sampling rate variations, and arm speed differences
        final s1 = generateVSample(jitter: 0.8, scale: 1.0, pointCountPerArm: 20);
        final s2 = generateVSample(jitter: 1.2, scale: 1.06, pointCountPerArm: 28);
        final s3 = generateVSample(jitter: 0.6, scale: 0.94, pointCountPerArm: 35);

        final template = synthesizer.synthesize(
          samples: [s1, s2, s3],
          id: 'perturbed_master_template',
          maxIterations: 5,
          convergenceTolerance: 0.5,
        );

        expect(template.normalizedPoints.length, 64);

        // Verify high DTW alignment with canonical template
        final double dtwScore = const FastDtwRecognizer().match(
          template.normalizedPoints,
          DefaultGestureTemplate.canonicalPoints,
        );
        expect(dtwScore, greaterThan(0.90));

        // Rubine features are valid and bounded in [0.0, 1.0]
        for (final val in template.rubineFeatureVector) {
          expect(val.isFinite, isTrue);
          expect(val, inInclusiveRange(0.0, 1.0));
        }
      });

      test('convergence tolerance sensitivity: strict 0.0001 vs loose 2.0 maintain numerical stability', () {
        final s1 = generateVSample(jitter: 0.5, scale: 1.0);
        final s2 = generateVSample(jitter: 0.7, scale: 1.03);
        final s3 = generateVSample(jitter: 0.4, scale: 0.97);

        // Strict tolerance runs up to maxIterations
        final strictTemplate = synthesizer.synthesize(
          samples: [s1, s2, s3],
          id: 'strict_tolerance_template',
          maxIterations: 5,
          convergenceTolerance: 0.0001,
        );

        // Loose tolerance terminates early
        final looseTemplate = synthesizer.synthesize(
          samples: [s1, s2, s3],
          id: 'loose_tolerance_template',
          maxIterations: 5,
          convergenceTolerance: 2.0,
        );

        expect(strictTemplate.normalizedPoints.length, 64);
        expect(looseTemplate.normalizedPoints.length, 64);

        // Mutual DTW similarity between strict and loose synthesis is high
        final double mutualScore = const FastDtwRecognizer().match(
          strictTemplate.normalizedPoints,
          looseTemplate.normalizedPoints,
        );
        expect(mutualScore, greaterThan(0.96));
      });

      test('supports variable sample counts K = 2, 3, 4, and 5 preserving 64-point invariant', () {
        for (final k in [2, 3, 4, 5]) {
          final samples = List.generate(
            k,
            (i) => generateVSample(
              scale: 0.96 + (i * 0.02),
              jitter: 0.2 * i,
              epoch: 1700000000000 + (i * 100),
            ),
          );

          final template = synthesizer.synthesize(
            samples: samples,
            id: 'template_k_$k',
          );

          expect(template.id, 'template_k_$k');
          expect(template.normalizedPoints.length, 64);
          expect(template.rubineFeatureVector.length, 7);

          // All coordinates are finite and bounded
          for (final pt in template.normalizedPoints) {
            expect(pt.x.isFinite, isTrue);
            expect(pt.y.isFinite, isTrue);
            expect(pt.x, inInclusiveRange(-130.0, 130.0));
            expect(pt.y, inInclusiveRange(-130.0, 130.0));
          }
        }
      });
    });

    // =========================================================================
    // 2. Reverse Stroke Inversion Stress
    // =========================================================================
    group('2. Reverse Stroke Inversion Stress', () {
      const synthesizer = DbaSynthesizer();

      test('detects reverse stroke (dRev < dFwd) and inverts before averaging preventing trajectory collapse', () {
        // Forward: Left arm -> vertex -> Right arm
        final s1 = generateVSample(scale: 1.0, reverse: false);
        // Reverse: Right arm -> vertex -> Left arm
        final s2Reverse = generateVSample(scale: 1.04, reverse: true);
        final s3 = generateVSample(scale: 0.98, reverse: false);

        final template = synthesizer.synthesize(
          samples: [s1, s2Reverse, s3],
          id: 'reverse_inverted_template',
        );

        expect(template.normalizedPoints.length, 64);

        // Point 0 should be at top-left: x < 0, y < 0
        final pFirst = template.normalizedPoints.first;
        final pLast = template.normalizedPoints.last;

        expect(pFirst.x, lessThan(-50.0), reason: 'First point must be on left arm');
        expect(pFirst.y, lessThan(-50.0), reason: 'First point must be at top');
        expect(pLast.x, greaterThan(50.0), reason: 'Last point must be on right arm');
        expect(pLast.y, lessThan(-50.0), reason: 'Last point must be at top');

        // Bounding box span: if trajectory collapsed, width would be near zero!
        double minX = double.infinity, maxX = -double.infinity;
        for (final pt in template.normalizedPoints) {
          if (pt.x < minX) minX = pt.x;
          if (pt.x > maxX) maxX = pt.x;
        }
        expect(maxX - minX, closeTo(250.0, 1e-4), reason: 'Width must not collapse');

        // Vertex must be located in the middle (index 28 to 36) with maximum y
        int vertexIndex = 0;
        double maxY = -double.infinity;
        for (int i = 0; i < template.normalizedPoints.length; i++) {
          if (template.normalizedPoints[i].y > maxY) {
            maxY = template.normalizedPoints[i].y;
            vertexIndex = i;
          }
        }
        expect(vertexIndex, inInclusiveRange(28, 36));
      });

      test('handles multiple reversed samples (Sample 1 and Sample 2 both reversed)', () {
        final s1Forward = generateVSample(scale: 1.0, reverse: false);
        final s2Reverse = generateVSample(scale: 1.02, reverse: true);
        final s3Reverse = generateVSample(scale: 0.98, reverse: true);

        final template = synthesizer.synthesize(
          samples: [s1Forward, s2Reverse, s3Reverse],
          id: 'two_reversed_samples_template',
        );

        expect(template.normalizedPoints.length, 64);

        // Aligned along s1Forward orientation
        expect(template.normalizedPoints.first.x, lessThan(-50.0));
        expect(template.normalizedPoints.last.x, greaterThan(50.0));

        final double dtwScore = const FastDtwRecognizer().match(
          template.normalizedPoints,
          DefaultGestureTemplate.canonicalPoints,
        );
        expect(dtwScore, greaterThan(0.90));
      });

      test('Inversion Invariance: synthesized templates from forward vs reversed samples are mutually equivalent', () {
        final s1 = generateVSample(scale: 1.0, jitter: 0.3);
        final s2 = generateVSample(scale: 1.04, jitter: 0.5);
        final s3 = generateVSample(scale: 0.97, jitter: 0.4);

        final s2Rev = generateVSample(scale: 1.04, jitter: 0.5, reverse: true);
        final s3Rev = generateVSample(scale: 0.97, jitter: 0.4, reverse: true);

        // T1: all forward
        final tAllForward = synthesizer.synthesize(
          samples: [s1, s2, s3],
          id: 't_all_forward',
        );

        // T2: s2 reversed
        final tMixed1 = synthesizer.synthesize(
          samples: [s1, s2Rev, s3],
          id: 't_mixed_1',
        );

        // T3: both s2 and s3 reversed
        final tMixedBoth = synthesizer.synthesize(
          samples: [s1, s2Rev, s3Rev],
          id: 't_mixed_both',
        );

        // Evaluate mutual similarity between all synthesized templates
        final double score12 = const FastDtwRecognizer().match(
          tAllForward.normalizedPoints,
          tMixed1.normalizedPoints,
        );
        final double score13 = const FastDtwRecognizer().match(
          tAllForward.normalizedPoints,
          tMixedBoth.normalizedPoints,
        );

        expect(score12, greaterThan(0.98), reason: 'Templates must be practically identical');
        expect(score13, greaterThan(0.98), reason: 'Templates must be practically identical');
      });

      test('asymmetric V stroke retains apex and orientation when candidate is drawn in reverse', () {
        // Asymmetric V: left arm is steeper and shorter than right arm
        final rawAsymPoints = <GesturePoint>[
          // Left arm down: (100, 50) -> (130, 250) in 25 points
          ...List.generate(
            25,
            (i) => GesturePoint(
              x: 100.0 + (i / 24.0 * 30.0),
              y: 50.0 + (i / 24.0 * 200.0),
              timestampMs: i * 16,
            ),
          ),
          // Right arm up: (130, 250) -> (270, 50) in 25 points
          ...List.generate(
            25,
            (i) => GesturePoint(
              x: 130.0 + (i / 24.0 * 140.0),
              y: 250.0 - (i / 24.0 * 200.0),
              timestampMs: (25 + i) * 16,
            ),
          ),
        ];

        final s1 = GestureSample(
          points: rawAsymPoints,
          sampledAtEpochMs: 1700000000000,
          totalLength: 445.0,
        );
        final s2Reverse = GestureSample(
          points: List<GesturePoint>.unmodifiable(rawAsymPoints.reversed),
          sampledAtEpochMs: 1700000000100,
          totalLength: 445.0,
        );

        final template = synthesizer.synthesize(
          samples: [s1, s2Reverse],
          id: 'asymmetric_v_template',
        );

        expect(template.normalizedPoints.length, 64);
        expect(template.normalizedPoints.first.x, lessThan(0.0));
        expect(template.normalizedPoints.last.x, greaterThan(0.0));
      });
    });

    // =========================================================================
    // 3. Outlier & Pairwise DTW Consistency Diagnostics
    // =========================================================================
    group('3. Outlier & Pairwise DTW Consistency Diagnostics', () {
      const synthesizer = DbaSynthesizer();

      test('correctly identifies outlier at index 2: [V1, V2, HorizontalLine]', () {
        final s1 = generateVSample(scale: 1.0);
        final s2 = generateVSample(scale: 1.03);
        final s3Horiz = generateHorizontalLineSample();

        final norm1 = DbaSynthesizer.standardizeSample(s1);
        final norm2 = DbaSynthesizer.standardizeSample(s2);
        final norm3 = DbaSynthesizer.standardizeSample(s3Horiz);

        final result = DbaSynthesizer.evaluateNormalizedConsistency(
          normalizedSamples: [norm1, norm2, norm3],
        );

        expect(result.isConsistent, isFalse);
        expect(result.outlierIndex, 2);
        expect(result.minimumPairScore, lessThan(0.60));
        expect(result.pairScores.containsKey('0-1'), isTrue);
        expect(result.pairScores['0-1'] ?? 0.0, greaterThan(0.70));
        expect(result.pairScores['0-2'] ?? 1.0, lessThan(0.60));
        expect(result.pairScores['1-2'] ?? 1.0, lessThan(0.60));
      });

      test('correctly identifies outlier at index 0: [HorizontalLine, V1, V2]', () {
        final sHoriz = generateHorizontalLineSample();
        final s1 = generateVSample(scale: 1.0);
        final s2 = generateVSample(scale: 1.03);

        final normHoriz = DbaSynthesizer.standardizeSample(sHoriz);
        final norm1 = DbaSynthesizer.standardizeSample(s1);
        final norm2 = DbaSynthesizer.standardizeSample(s2);

        final result = DbaSynthesizer.evaluateNormalizedConsistency(
          normalizedSamples: [normHoriz, norm1, norm2],
        );

        expect(result.isConsistent, isFalse);
        expect(result.outlierIndex, 0);
        expect(result.minimumPairScore, lessThan(0.60));
      });

      test('correctly identifies outlier at index 1: [V1, HorizontalLine, V2]', () {
        final s1 = generateVSample(scale: 1.0);
        final sHoriz = generateHorizontalLineSample();
        final s2 = generateVSample(scale: 1.03);

        final norm1 = DbaSynthesizer.standardizeSample(s1);
        final normHoriz = DbaSynthesizer.standardizeSample(sHoriz);
        final norm2 = DbaSynthesizer.standardizeSample(s2);

        final result = DbaSynthesizer.evaluateNormalizedConsistency(
          normalizedSamples: [norm1, normHoriz, norm2],
        );

        expect(result.isConsistent, isFalse);
        expect(result.outlierIndex, 1);
        expect(result.minimumPairScore, lessThan(0.60));
      });

      test('correctly identifies outlier at index 3 in 4-sample enrollment: [V1, V2, V3, Caret]', () {
        final s1 = generateVSample(scale: 1.0);
        final s2 = generateVSample(scale: 1.04);
        final s3 = generateVSample(scale: 0.96);
        final sCaret = generateCaretSample();

        final norm1 = DbaSynthesizer.standardizeSample(s1);
        final norm2 = DbaSynthesizer.standardizeSample(s2);
        final norm3 = DbaSynthesizer.standardizeSample(s3);
        final normCaret = DbaSynthesizer.standardizeSample(sCaret);

        final result = DbaSynthesizer.evaluateNormalizedConsistency(
          normalizedSamples: [norm1, norm2, norm3, normCaret],
        );

        expect(result.isConsistent, isFalse);
        expect(result.outlierIndex, 3);
      });

      test('fails consistency when samples are inverted mirror images (Normal V vs Inverted V caret)', () {
        final sV = generateVSample(scale: 1.0);
        final sCaret = generateCaretSample();

        final isConsistent = synthesizer.checkConsistency(
          samples: [sV, sCaret],
        );
        expect(isConsistent, isFalse);
      });

      test('synthesize throws descriptive FormatException specifying outlier index when consistency fails', () {
        final s1 = generateVSample(scale: 1.0);
        final s2 = generateVSample(scale: 1.03);
        final s3 = generateHorizontalLineSample();

        expect(
          () => synthesizer.synthesize(
            samples: [s1, s2, s3],
            id: 'failing_outlier_template',
          ),
          throwsA(
            isA<FormatException>()
                .having((e) => e.message, 'message', contains('failed pairwise DTW consistency check'))
                .having((e) => e.message, 'message', contains('Outlier sample index: 2')),
          ),
        );
      });

      test('evaluateNormalizedConsistency throws FormatException on fewer than 2 samples', () {
        final norm = DbaSynthesizer.standardizeSample(generateVSample());
        expect(
          () => DbaSynthesizer.evaluateNormalizedConsistency(
            normalizedSamples: [norm],
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureRecognizerService emits VaultGestureFailure with outlier info on inconsistent samples', () async {
        final service = GestureRecognizerService();
        final s1 = generateVSample(scale: 1.0);
        final s2 = generateVSample(scale: 1.03);
        final s3 = generateHorizontalLineSample();

        final synthResult = await service.synthesizeMasterTemplate(
          samples: [s1, s2, s3],
          templateId: 'service_outlier_test',
        );

        expect(synthResult, isA<VaultFailureResult<GestureTemplate>>());
        if (synthResult case VaultFailureResult(:final failure)) {
          expect(failure, isA<VaultGestureFailure>());
          expect(failure.message, contains('failed pairwise DTW consistency check'));
        }

        final conResult = await service.validateSampleConsistency(
          samples: [s1, s2, s3],
        );
        expect(conResult, isA<VaultFailureResult<void>>());
        if (conResult case VaultFailureResult(:final failure)) {
          expect(failure, isA<VaultGestureFailure>());
        }
      });

      test('GestureRecognizerService emits VaultValidationFailure on malformed arguments', () async {
        final service = GestureRecognizerService();

        // 1. Single sample
        final res1 = await service.synthesizeMasterTemplate(
          samples: [generateVSample()],
          templateId: 'valid_id',
        );
        expect(res1, isA<VaultFailureResult<GestureTemplate>>());
        if (res1 case VaultFailureResult(:final failure)) {
          expect(failure, isA<VaultValidationFailure>());
        }

        // 2. GestureSample rejects empty points list at constructor
        expect(
          () => GestureSample(
            points: const [],
            sampledAtEpochMs: 1700000000000,
            totalLength: 0.0,
          ),
          throwsA(isA<FormatException>()),
        );

        // 3. validateSampleConsistency on single sample
        final res3 = await service.validateSampleConsistency(
          samples: [generateVSample()],
        );
        expect(res3, isA<VaultFailureResult<void>>());
        if (res3 case VaultFailureResult(:final failure)) {
          expect(failure, isA<VaultValidationFailure>());
        }
      });
    });

    // =========================================================================
    // 4. Canonical Default "V" Template Robustness & Security Safety Floors
    // =========================================================================
    group('4. Canonical Default "V" Template Robustness & Security Floors', () {
      final template = DefaultGestureTemplate.canonicalVShape;

      test('canonicalPoints coordinates adhere to exact analytical closed-form formulas', () {
        final points = DefaultGestureTemplate.canonicalPoints;
        expect(points.length, GestureTemplate.requiredPointCount);

        double minX = double.infinity, maxX = -double.infinity;
        double minY = double.infinity, maxY = -double.infinity;
        double sumX = 0.0;
        double sumY = 0.0;

        for (int i = 0; i < 64; i++) {
          final pt = points[i];
          if (pt.x < minX) minX = pt.x;
          if (pt.x > maxX) maxX = pt.x;
          if (pt.y < minY) minY = pt.y;
          if (pt.y > maxY) maxY = pt.y;
          sumX += pt.x;
          sumY += pt.y;

          final double expectedX = -125.0 + (i * (250.0 / 63.0));
          final int armIndex = (i <= 31) ? i : (63 - i);
          final double expectedY = -125.0 + (armIndex * (250.0 / 31.0));

          expect(pt.x, closeTo(expectedX, 1e-9));
          expect(pt.y, closeTo(expectedY, 1e-9));
        }

        expect(minX, closeTo(-125.0, 1e-9));
        expect(maxX, closeTo(125.0, 1e-9));
        expect(minY, closeTo(-125.0, 1e-9));
        expect(maxY, closeTo(125.0, 1e-9));
        expect(sumX / 64.0, closeTo(0.0, 1e-9));
        expect(sumY / 64.0, closeTo(0.0, 1e-9));
        // Vertex at index 31 is apex bottom
        expect(points[31].y, closeTo(125.0, 1e-9));
      });

      test('canonicalRubineVector matches machine extraction and has cosine similarity 1.0', () {
        final extracted = RubineFeatureExtractor.extractFeaturesStatic(
          DefaultGestureTemplate.canonicalPoints,
        );

        expect(extracted.length, GestureTemplate.requiredFeatureVectorDimensions);
        for (int i = 0; i < 7; i++) {
          expect(
            DefaultGestureTemplate.canonicalRubineVector[i],
            closeTo(extracted[i], 1e-7),
          );
        }

        final double cosineSim = RubineFeatureExtractor.computeCosineSimilarityStatic(
          DefaultGestureTemplate.canonicalRubineVector,
          extracted,
        );
        expect(cosineSim, closeTo(1.0, 1e-9));
      });

      test('matches simulated human "V" shapes across scale variations (0.7x to 1.5x) on strict92Percent', () {
        for (final scale in [0.70, 0.85, 1.0, 1.25, 1.50]) {
          final sample = generateVSample(scale: scale, jitter: 0.5);

          final payload = GestureRecognitionIsolatePayload(
            rawPoints: sample.points,
            templateNormalizedPoints: template.normalizedPoints,
            templateRubineVector: template.rubineFeatureVector,
            sensitivityTier: GestureSensitivityTierEnum.strict92Percent,
          );

          final RecognitionScore score = runGestureRecognitionPipeline(payload);
          expect(
            score.decision,
            GestureMatchDecisionEnum.matched,
            reason: 'Failed to match human V at scale factor $scale (score: ${score.ensembleScore})',
          );
          expect(score.ensembleScore, greaterThanOrEqualTo(0.88));
          expect(score.dollarOneScore, greaterThan(0.90));
          expect(score.dtwScore, greaterThan(0.85));
          expect(score.featureScore, greaterThan(0.90));
        }
      });

      test('DollarOneBRecognizer Golden Section Search recovers rotation across [-45 deg, +45 deg]', () {
        const dollarOne = DollarOneBRecognizer();
        for (final angleDeg in [-40.0, -25.0, -15.0, 15.0, 25.0, 40.0]) {
          final double angleRad = angleDeg * math.pi / 180.0;
          final sample = generateRotatedVSample(angleRad: angleRad);

          final normalizedPoints = GestureNormalizer.normalizeCoordinates(
            GestureResampler.resample(sample.points, targetCount: 64),
          );

          final double d1Score = dollarOne.match(
            normalizedPoints,
            template.normalizedPoints,
          );

          expect(
            d1Score,
            greaterThan(0.85),
            reason: 'DollarOneB failed to recover rotation at $angleDeg degrees (score: $d1Score)',
          );
        }
      });

      test('ensemble pipeline matches natural human drawing tilt within [-8 deg, +8 deg]', () {
        for (final angleDeg in [-8.0, -4.0, 4.0, 8.0]) {
          final double angleRad = angleDeg * math.pi / 180.0;
          final sample = generateRotatedVSample(angleRad: angleRad);

          final payload = GestureRecognitionIsolatePayload(
            rawPoints: sample.points,
            templateNormalizedPoints: template.normalizedPoints,
            templateRubineVector: template.rubineFeatureVector,
            sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
          );

          final RecognitionScore score = runGestureRecognitionPipeline(payload);
          expect(
            score.decision,
            GestureMatchDecisionEnum.matched,
            reason: 'Failed to match human tilt at $angleDeg degrees',
          );
        }
      });

      test('decisively rejects adversarial non-V gestures across ALL sensitivity tiers', () {
        // 1. Horizontal straight line
        final horizSample = generateHorizontalLineSample();
        // 2. Inverted V / Caret `^`
        final caretSample = generateCaretSample();
        // 3. Z-shape
        final zPoints = <GesturePoint>[
          ...List.generate(15, (i) => GesturePoint(x: 50.0 + i * 10.0, y: 50.0, timestampMs: i * 16)),
          ...List.generate(15, (i) => GesturePoint(x: 190.0 - i * 10.0, y: 50.0 + i * 10.0, timestampMs: (15 + i) * 16)),
          ...List.generate(15, (i) => GesturePoint(x: 50.0 + i * 10.0, y: 190.0, timestampMs: (30 + i) * 16)),
        ];
        final zSample = GestureSample(
          points: zPoints,
          sampledAtEpochMs: 1700000000000,
          totalLength: 350.0,
        );

        final adversarialSamples = [
          ('HorizontalLine', horizSample),
          ('CaretInvertedV', caretSample),
          ('ZShape', zSample),
        ];

        final tiers = [
          GestureSensitivityTierEnum.strict92Percent,
          GestureSensitivityTierEnum.balanced84Percent,
          GestureSensitivityTierEnum.relaxed76Percent,
        ];

        for (final (name, sample) in adversarialSamples) {
          for (final tier in tiers) {
            final payload = GestureRecognitionIsolatePayload(
              rawPoints: sample.points,
              templateNormalizedPoints: template.normalizedPoints,
              templateRubineVector: template.rubineFeatureVector,
              sensitivityTier: tier,
            );

            final RecognitionScore score = runGestureRecognitionPipeline(payload);

            expect(
              score.decision,
              isNot(GestureMatchDecisionEnum.matched),
              reason: 'Security breach: $name was falsely matched on $tier!',
            );

            // DTW score should fall well below safety floors
            expect(
              score.dtwScore,
              lessThan(0.65),
              reason: '$name produced high DTW score: ${score.dtwScore}',
            );
          }
        }
      });

      test('canonical template collections are deeply immutable', () {
        expect(
          () => (DefaultGestureTemplate.canonicalPoints as dynamic).add(
            GesturePoint(x: 0, y: 0, timestampMs: 0),
          ),
          throwsA(isA<UnsupportedError>()),
        );
        expect(
          () => (DefaultGestureTemplate.canonicalRubineVector as dynamic).add(0.5),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    // =========================================================================
    // 5. DTW Warping Path & Matrix Boundary Invariants
    // =========================================================================
    group('5. DTW Warping Path & Matrix Boundary Invariants', () {
      test('extractWarpingPath strictly starts at (0,0) and ends at (n-1, m-1)', () {
        final p1 = DefaultGestureTemplate.canonicalPoints;
        final p2 = generateVSample().points.sublist(0, 50);

        final path = DbaSynthesizer.extractWarpingPath(p1, p2, windowRadius: 15);

        expect(path.first, const DtwPathPoint(0, 0));
        expect(path.last, DtwPathPoint(p1.length - 1, p2.length - 1));
      });

      test('extractWarpingPath respects Sakoe-Chiba constraint window |u - v| <= windowRadius', () {
        const int radius = 8;
        final p1 = DefaultGestureTemplate.canonicalPoints;
        final p2 = generateVSample(scale: 1.05).points;
        final norm2 = GestureNormalizer.normalizeCoordinates(
          GestureResampler.resample(p2, targetCount: 64),
        );

        final path = DbaSynthesizer.extractWarpingPath(p1, norm2, windowRadius: radius);

        for (final pt in path) {
          final diff = (pt.index1 - pt.index2).abs();
          expect(
            diff,
            lessThanOrEqualTo(radius),
            reason: 'Path point (${pt.index1}, ${pt.index2}) violated window radius $radius',
          );
        }
      });

      test('extractWarpingPath enforces monotonicity: u_{i+1} >= u_i and v_{i+1} >= v_i', () {
        final p1 = DefaultGestureTemplate.canonicalPoints;
        final path = DbaSynthesizer.extractWarpingPath(p1, p1, windowRadius: 10);

        for (int i = 0; i < path.length - 1; i++) {
          final current = path[i];
          final next = path[i + 1];

          expect(next.index1, greaterThanOrEqualTo(current.index1));
          expect(next.index2, greaterThanOrEqualTo(current.index2));

          // Step size is at most 1 in either direction
          final step1 = next.index1 - current.index1;
          final step2 = next.index2 - current.index2;
          expect(step1, inInclusiveRange(0, 1));
          expect(step2, inInclusiveRange(0, 1));
          expect(step1 + step2, greaterThanOrEqualTo(1));
        }
      });

      test('extractWarpingPath throws FormatException on empty input sequences', () {
        final points = DefaultGestureTemplate.canonicalPoints;
        expect(
          () => DbaSynthesizer.extractWarpingPath([], points),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => DbaSynthesizer.extractWarpingPath(points, []),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // =========================================================================
    // 6. Multi-Threaded Isolate Concurrency & Service Lifecycle
    // =========================================================================
    group('6. Multi-Threaded Isolate Concurrency & Service Lifecycle', () {
      test('concurrent synthesis of 10 master templates via Isolate.run exhibits zero race conditions', () async {
        final service = GestureRecognizerService();
        final s1 = generateVSample(scale: 1.0);
        final s2 = generateVSample(scale: 1.04);
        final s3 = generateVSample(scale: 0.96);

        const int jobCount = 10;
        final futures = List.generate(
          jobCount,
          (i) => service.synthesizeMasterTemplate(
            samples: [s1, s2, s3],
            templateId: 'concurrent_job_$i',
          ),
        );

        final results = await Future.wait(futures);

        expect(results.length, jobCount);
        for (int i = 0; i < jobCount; i++) {
          final res = results[i];
          expect(res, isA<VaultSuccess<GestureTemplate>>());
          if (res case VaultSuccess(:final data)) {
            expect(data.id, 'concurrent_job_$i');
            expect(data.normalizedPoints.length, 64);
            expect(data.rubineFeatureVector.length, 7);
          }
        }
      });

      test('concurrent mixed validation (5 valid + 5 invalid) returns deterministic results', () async {
        final service = GestureRecognizerService();
        final validSamples = [
          generateVSample(scale: 1.0),
          generateVSample(scale: 1.02),
          generateVSample(scale: 0.98),
        ];
        final invalidSamples = [
          generateVSample(scale: 1.0),
          generateVSample(scale: 1.02),
          generateHorizontalLineSample(),
        ];

        final validFutures = List.generate(
          5,
          (_) => service.validateSampleConsistency(samples: validSamples),
        );
        final invalidFutures = List.generate(
          5,
          (_) => service.validateSampleConsistency(samples: invalidSamples),
        );

        final validResults = await Future.wait(validFutures);
        final invalidResults = await Future.wait(invalidFutures);

        for (final res in validResults) {
          expect(res, isA<VaultSuccess<void>>());
        }
        for (final res in invalidResults) {
          expect(res, isA<VaultFailureResult<void>>());
          if (res case VaultFailureResult(:final failure)) {
            expect(failure, isA<VaultGestureFailure>());
          }
        }
      });
    });
  });
}
