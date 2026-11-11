import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_ensemble_fusion.dart';
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
  group('Empirical Challenger: Ensemble Fusion, Rubine Extractor & Isolate Concurrency', () {
    // -------------------------------------------------------------------------
    // Helper Generators
    // -------------------------------------------------------------------------

    /// Generates a realistic raw single-stroke "V" shape with 50 points and span > 100px.
    List<GesturePoint> createRawVShape() {
      final points = <GesturePoint>[];
      // Downwards left arm: (50, 50) -> (150, 250) (25 points)
      for (int i = 0; i < 25; i++) {
        final t = i / 24.0;
        final x = 50.0 + (t * 100.0);
        final y = 50.0 + (t * 200.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Upwards right arm: (150, 250) -> (250, 50) (25 points)
      for (int i = 0; i < 25; i++) {
        final t = i / 24.0;
        final x = 150.0 + (t * 100.0);
        final y = 250.0 - (t * 200.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (25 + i) * 16));
      }
      return points;
    }

    /// Constructs an authoritative canonical "V" shape reference template.
    GestureTemplate createVShapeTemplate() {
      final rawPoints = createRawVShape();
      final resampled = GestureResampler.resample(rawPoints);
      final normalized = GestureNormalizer.normalizeCoordinates(resampled);
      final rubine = RubineFeatureExtractor.extractFeaturesStatic(normalized);

      return GestureTemplate(
        id: 'canonical-v-template',
        normalizedPoints: normalized,
        rubineFeatureVector: rubine,
        createdAtEpochMs: 1700000000000,
      );
    }

    /// Generates a perfectly collinear sequence of [count] points with displacement ([dx], [dy]).
    List<GesturePoint> createCollinearStroke({
      required double startX,
      required double startY,
      required double endX,
      required double endY,
      int count = 64,
    }) {
      final points = <GesturePoint>[];
      final double spanX = endX - startX;
      final double spanY = endY - startY;
      for (int i = 0; i < count; i++) {
        final double t = count == 1 ? 0.0 : i / (count - 1).toDouble();
        points.add(
          GesturePoint(
            x: startX + (t * spanX),
            y: startY + (t * spanY),
            timestampMs: i * 16,
          ),
        );
      }
      return points;
    }

    // =========================================================================
    // 1. Decision Fusion Numerical Precision Boundaries
    // =========================================================================
    group('Decision Fusion Numerical Precision Boundaries', () {
      const tierStrict = GestureSensitivityTierEnum.strict92Percent; // 0.88
      const tierBalanced = GestureSensitivityTierEnum.balanced84Percent; // 0.78
      const tierRelaxed = GestureSensitivityTierEnum.relaxed76Percent; // 0.68

      test('Structural Gate: S_feat = 0.679 strictly rejected with rejectedStructuralGate', () {
        // High $1 and DTW scores must NOT rescue a failing structural cosine gate
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.98,
          dtwScore: 0.98,
          featureScore: 0.679,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedStructuralGate);
        expect(score.featureScore, 0.679);
      });

      test('Structural Gate: S_feat = 0.679999999999 strictly rejected below gate', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.95,
          dtwScore: 0.95,
          featureScore: 0.679999999999,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedStructuralGate);
      });

      test('Structural Gate: S_feat = 0.680 passes gate and matches when ensemble satisfies tier', () {
        // S_$1 = 0.70, S_DTW = 0.70, S_feat = 0.680
        // S_ensemble = 0.50*0.70 + 0.35*0.70 + 0.15*0.680 = 0.35 + 0.245 + 0.102 = 0.697 >= 0.68
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.70,
          dtwScore: 0.70,
          featureScore: 0.680,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.matched);
        expect(score.ensembleScore, closeTo(0.697, 1e-6));
      });

      test('Structural Gate Precedence: S_feat < 0.68 overrides failing classifier floors', () {
        // Both structural gate AND classifier floors fail; Stage 1 must take precedence
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.50, // Below 0.65 floor
          dtwScore: 0.40, // Below 0.60 floor
          featureScore: 0.679, // Below 0.68 gate
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedStructuralGate);
      });

      test(r'Classifier Floor $1: S_$1 = 0.649 strictly rejected with rejectedClassifierFloor', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.649,
          dtwScore: 0.90,
          featureScore: 0.90,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedClassifierFloor);
      });

      test(r'Classifier Floor $1: S_$1 = 0.650 passes floor when S_DTW >= 0.60', () {
        // S_$1 = 0.650, S_DTW = 0.85, S_feat = 0.85
        // S_ens = 0.50*0.650 + 0.35*0.85 + 0.15*0.85 = 0.325 + 0.2975 + 0.1275 = 0.750 >= 0.68
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.650,
          dtwScore: 0.85,
          featureScore: 0.85,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.matched);
      });

      test('Classifier Floor DTW: S_DTW = 0.599 strictly rejected with rejectedClassifierFloor', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.90,
          dtwScore: 0.599,
          featureScore: 0.90,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedClassifierFloor);
      });

      test(r'Classifier Floor DTW: S_DTW = 0.600 passes floor when S_$1 >= 0.65', () {
        // S_$1 = 0.85, S_DTW = 0.600, S_feat = 0.85
        // S_ens = 0.50*0.85 + 0.35*0.600 + 0.15*0.85 = 0.425 + 0.210 + 0.1275 = 0.7625 >= 0.68
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.85,
          dtwScore: 0.600,
          featureScore: 0.85,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.matched);
      });

      test('Classifier Floor Precedence: failing floor rejects even if ensemble meets strict tier', () {
        // S_$1 = 0.649 (fails floor), S_DTW = 0.99, S_feat = 0.99
        // S_ens = 0.50*0.649 + 0.35*0.99 + 0.15*0.99 = 0.3245 + 0.3465 + 0.1485 = 0.8195 (meets balanced tier)
        // Must still be rejected at Stage 2 due to $1 floor failure!
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.649,
          dtwScore: 0.99,
          featureScore: 0.99,
          sensitivityTier: tierBalanced,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedClassifierFloor);
      });

      test('Sensitivity Tier Strict: S_ens = 0.879 rejects while 0.880 matches', () {
        final scoreBelow = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.879,
          dtwScore: 0.879,
          featureScore: 0.879,
          sensitivityTier: tierStrict,
        );
        expect(scoreBelow.decision, GestureMatchDecisionEnum.rejectedBelowSensitivityTier);

        final scoreAbove = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.880,
          dtwScore: 0.880,
          featureScore: 0.880,
          sensitivityTier: tierStrict,
        );
        expect(scoreAbove.decision, GestureMatchDecisionEnum.matched);
      });

      test('Sensitivity Tier Balanced: S_ens = 0.779 rejects while 0.780 matches', () {
        final scoreBelow = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.779,
          dtwScore: 0.779,
          featureScore: 0.779,
          sensitivityTier: tierBalanced,
        );
        expect(scoreBelow.decision, GestureMatchDecisionEnum.rejectedBelowSensitivityTier);

        final scoreAbove = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.780,
          dtwScore: 0.780,
          featureScore: 0.780,
          sensitivityTier: tierBalanced,
        );
        expect(scoreAbove.decision, GestureMatchDecisionEnum.matched);
      });

      test('Sensitivity Tier Relaxed: S_ens = 0.679 rejects while S_ens >= 0.680 matches (isolated from gate)', () {
        // Keeping S_feat = 0.680 (passing structural gate) and S_DTW = 0.600 (passing DTW floor):
        // S_ensemble = 0.50*S_$1 + 0.35*0.600 + 0.15*0.680 = 0.50*S_$1 + 0.210 + 0.102 = 0.50*S_$1 + 0.312
        // For S_ens = 0.679: 0.50*S_$1 = 0.367 => S_$1 = 0.734
        final scoreBelow = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.734,
          dtwScore: 0.600,
          featureScore: 0.680,
          sensitivityTier: tierRelaxed,
        );
        expect(scoreBelow.decision, GestureMatchDecisionEnum.rejectedBelowSensitivityTier);
        expect(scoreBelow.ensembleScore, closeTo(0.679, 1e-6));

        // For S_ens >= 0.680: S_$1 = 0.737 => 0.50*0.737 + 0.210 + 0.102 = 0.6805 >= 0.680
        final scoreAbove = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.737,
          dtwScore: 0.600,
          featureScore: 0.680,
          sensitivityTier: tierRelaxed,
        );
        expect(scoreAbove.decision, GestureMatchDecisionEnum.matched);
        expect(scoreAbove.ensembleScore, greaterThanOrEqualTo(0.680));
      });

      test('Sensitivity Tier Relaxed: exact 0.680 triplet matches at threshold boundary', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.680,
          dtwScore: 0.680,
          featureScore: 0.680,
          sensitivityTier: tierRelaxed,
        );
        expect(score.ensembleScore, closeTo(0.680, 1e-6));
        expect(score.decision, GestureMatchDecisionEnum.matched);
      });
    });

    // =========================================================================
    // 2. Degenerate Geometry Stress in RubineFeatureExtractor
    // =========================================================================
    group('Degenerate Geometry Defense in RubineFeatureExtractor', () {
      test('all points zero displacement (repeated point x64) produces valid vector without NaN or crash', () {
        final zeroDispPoints = List.generate(
          64,
          (i) => GesturePoint(x: 125.0, y: 125.0, timestampMs: i * 16),
        );

        final features = RubineFeatureExtractor.extractFeaturesStatic(zeroDispPoints);

        expect(features.length, 7);
        for (int i = 0; i < 7; i++) {
          expect(features[i].isNaN, isFalse);
          expect(features[i].isInfinite, isFalse);
          expect(features[i], greaterThanOrEqualTo(0.0));
          expect(features[i], lessThanOrEqualTo(1.0));
        }

        // Analytical check for zero displacement:
        // distStart < epsilon -> cos=0, sin=0 -> f1=0.5, f2=0.5
        expect(features[0], closeTo(0.5, 1e-6));
        expect(features[1], closeTo(0.5, 1e-6));
        // distEnd < epsilon -> f3=0.5, f4=0.5
        expect(features[2], closeTo(0.5, 1e-6));
        expect(features[3], closeTo(0.5, 1e-6));
        // pathLength < epsilon -> f5=0.0
        expect(features[4], closeTo(0.0, 1e-6));
        // total signed turning angle = 0 -> f6 = 4pi / 8pi = 0.5
        expect(features[5], closeTo(0.5, 1e-6));
        // maxCurvature = 0.0 < 1e-6 -> f7 = 0.0
        expect(features[6], closeTo(0.0, 1e-6));
      });

      test('single point repeated 4 times (minRequiredPoints) succeeds safely', () {
        final fourPoints = List.generate(
          4,
          (i) => GesturePoint(x: 50.0, y: 50.0, timestampMs: i * 16),
        );

        final features = RubineFeatureExtractor.extractFeaturesStatic(fourPoints);
        expect(features.length, 7);
        expect(features[4], 0.0); // f5 = 0.0
        expect(features[6], 0.0); // f7 = 0.0
      });

      test('single point repeated 3 times fails with FormatException (< minRequiredPoints)', () {
        final threePoints = List.generate(
          3,
          (i) => GesturePoint(x: 50.0, y: 50.0, timestampMs: i * 16),
        );

        expect(
          () => RubineFeatureExtractor.extractFeaturesStatic(threePoints),
          throwsA(isA<FormatException>()),
        );
      });

      test('micro-displacement chatter (< 1e-12) handled safely under epsilon threshold', () {
        final microPoints = List.generate(
          64,
          (i) => GesturePoint(x: 100.0 + (i * 1e-14), y: 100.0 + (i * 1e-14), timestampMs: i * 16),
        );

        final features = RubineFeatureExtractor.extractFeaturesStatic(microPoints);
        expect(features.length, 7);
        for (final f in features) {
          expect(f.isNaN, isFalse);
          expect(f.isInfinite, isFalse);
        }
        expect(features[6], closeTo(0.0, 1e-6)); // f7 = 0.0
      });

      test('perfectly collinear horizontal stroke (left-to-right) yields f5 = 1.0, f6 = 0.5, f7 = 0.0', () {
        final hLineLR = createCollinearStroke(
          startX: -125.0,
          startY: 0.0,
          endX: 125.0,
          endY: 0.0,
          count: 64,
        );

        final features = RubineFeatureExtractor.extractFeaturesStatic(hLineLR);
        // Heading is 0 rad -> cos=1, sin=0 -> f1 = (1+1)/2 = 1.0, f2 = (0+1)/2 = 0.5
        expect(features[0], closeTo(1.0, 1e-6)); // f1
        expect(features[1], closeTo(0.5, 1e-6)); // f2
        expect(features[2], closeTo(1.0, 1e-6)); // f3
        expect(features[3], closeTo(0.5, 1e-6)); // f4
        expect(features[4], closeTo(1.0, 1e-6)); // f5 = net / L = 1.0
        expect(features[5], closeTo(0.5, 1e-6)); // f6 = (0 + 4pi)/(8pi) = 0.5
        expect(features[6], closeTo(0.0, 1e-6)); // f7 = 0.0 (no curvature peak)
      });

      test('perfectly collinear horizontal stroke (right-to-left) yields f1 = 0.0, f5 = 1.0, f7 = 0.0', () {
        final hLineRL = createCollinearStroke(
          startX: 125.0,
          startY: 0.0,
          endX: -125.0,
          endY: 0.0,
          count: 64,
        );

        final features = RubineFeatureExtractor.extractFeaturesStatic(hLineRL);
        // Heading is pi rad -> cos=-1, sin=0 -> f1 = (-1+1)/2 = 0.0, f2 = 0.5
        expect(features[0], closeTo(0.0, 1e-6)); // f1
        expect(features[1], closeTo(0.5, 1e-6)); // f2
        expect(features[2], closeTo(0.0, 1e-6)); // f3
        expect(features[3], closeTo(0.5, 1e-6)); // f4
        expect(features[4], closeTo(1.0, 1e-6)); // f5 = 1.0
        expect(features[5], closeTo(0.5, 1e-6)); // f6 = 0.5
        expect(features[6], closeTo(0.0, 1e-6)); // f7 = 0.0
      });

      test('perfectly collinear vertical stroke (bottom-to-top) yields f2 = 1.0, f5 = 1.0, f7 = 0.0', () {
        final vLineBT = createCollinearStroke(
          startX: 0.0,
          startY: -125.0,
          endX: 0.0,
          endY: 125.0,
          count: 64,
        );

        final features = RubineFeatureExtractor.extractFeaturesStatic(vLineBT);
        // Heading is pi/2 rad -> cos=0, sin=1 -> f1 = 0.5, f2 = (1+1)/2 = 1.0
        expect(features[0], closeTo(0.5, 1e-6)); // f1
        expect(features[1], closeTo(1.0, 1e-6)); // f2
        expect(features[2], closeTo(0.5, 1e-6)); // f3
        expect(features[3], closeTo(1.0, 1e-6)); // f4
        expect(features[4], closeTo(1.0, 1e-6)); // f5 = 1.0
        expect(features[5], closeTo(0.5, 1e-6)); // f6 = 0.5
        expect(features[6], closeTo(0.0, 1e-6)); // f7 = 0.0
      });

      test('perfectly collinear vertical stroke (top-to-bottom) yields f2 = 0.0, f5 = 1.0, f7 = 0.0', () {
        final vLineTB = createCollinearStroke(
          startX: 0.0,
          startY: 125.0,
          endX: 0.0,
          endY: -125.0,
          count: 64,
        );

        final features = RubineFeatureExtractor.extractFeaturesStatic(vLineTB);
        // Heading is -pi/2 rad -> cos=0, sin=-1 -> f1 = 0.5, f2 = (-1+1)/2 = 0.0
        expect(features[0], closeTo(0.5, 1e-6)); // f1
        expect(features[1], closeTo(0.0, 1e-6)); // f2
        expect(features[2], closeTo(0.5, 1e-6)); // f3
        expect(features[3], closeTo(0.0, 1e-6)); // f4
        expect(features[4], closeTo(1.0, 1e-6)); // f5 = 1.0
        expect(features[5], closeTo(0.5, 1e-6)); // f6 = 0.5
        expect(features[6], closeTo(0.0, 1e-6)); // f7 = 0.0
      });

      test('zero-norm vector cosine similarity defense returns 0.0 without division by zero', () {
        final zeroVec = List<double>.filled(7, 0.0);
        final nonZeroVec = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];

        final simA = RubineFeatureExtractor.computeCosineSimilarityStatic(zeroVec, nonZeroVec);
        final simB = RubineFeatureExtractor.computeCosineSimilarityStatic(nonZeroVec, zeroVec);
        final simBothZero = RubineFeatureExtractor.computeCosineSimilarityStatic(zeroVec, zeroVec);

        expect(simA, 0.0);
        expect(simB, 0.0);
        expect(simBothZero, 0.0);
      });

      test('matchBidirectional on collinear stroke completes without NaN or exception', () {
        final hLineLR = createCollinearStroke(
          startX: -125.0,
          startY: 0.0,
          endX: 125.0,
          endY: 0.0,
          count: 64,
        );
        final templateFeatures = RubineFeatureExtractor.extractFeaturesStatic(hLineLR);

        final similarity = RubineFeatureExtractor.matchBidirectionalStatic(
          hLineLR,
          templateFeatures,
        );

        expect(similarity.isNaN, isFalse);
        expect(similarity.isInfinite, isFalse);
        expect(similarity, closeTo(1.0, 1e-6));
      });
    });

    // =========================================================================
    // 3. Empirical Latency Benchmark (50 Iterations <= 35ms)
    // =========================================================================
    group('Empirical Isolate Latency Benchmark (50 Iterations <= 35ms)', () {
      late GestureTemplate template;
      late List<GesturePoint> rawPoints;
      late GestureRecognitionIsolatePayload payload;

      setUp(() {
        template = createVShapeTemplate();
        rawPoints = createRawVShape();
        payload = GestureRecognitionIsolatePayload(
          rawPoints: rawPoints,
          templateNormalizedPoints: template.normalizedPoints,
          templateRubineVector: template.rubineFeatureVector,
          sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
        );
      });

      test('50 back-to-back isolate evaluations maintain worst-case latency <= 35ms', () async {
        // 1. Warm-up iterations (3 runs to warm JIT / VM isolate pool)
        for (int w = 0; w < 3; w++) {
          await Isolate.run(() => runGestureRecognitionPipeline(payload));
        }

        // 2. Measure 50 consecutive isolate evaluations
        const int iterations = 50;
        final latenciesMs = <double>[];

        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()..start();
          final score = await Isolate.run(() => runGestureRecognitionPipeline(payload));
          stopwatch.stop();

          final double elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
          latenciesMs.add(elapsedMs);

          expect(score.decision, GestureMatchDecisionEnum.matched);
        }

        latenciesMs.sort();
        final double minLatency = latenciesMs.first;
        final double medianLatency = latenciesMs[iterations ~/ 2];
        final double p95Latency = latenciesMs[(iterations * 0.95).floor()];
        final double maxLatency = latenciesMs.last;

        // Print benchmark telemetry for verification and auditing
        // ignore: avoid_print
        print(
          'Latency Benchmark (50 runs inside Isolate.run): '
          'min=${minLatency.toStringAsFixed(2)}ms, '
          'median=${medianLatency.toStringAsFixed(2)}ms, '
          'p95=${p95Latency.toStringAsFixed(2)}ms, '
          'max=${maxLatency.toStringAsFixed(2)}ms',
        );

        // Assert worst-case latency budget is strictly respected (<= 35ms)
        expect(
          maxLatency,
          lessThanOrEqualTo(35.0),
          reason: 'Worst-case isolate latency exceeded 35ms SLA: ${maxLatency}ms',
        );
        expect(medianLatency, lessThan(20.0));
      });

      test('50 back-to-back GestureRecognizerService.evaluateStroke runs maintain worst-case latency <= 35ms', () async {
        final service = GestureRecognizerService();
        final sample = GestureSample(
          points: rawPoints,
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );

        // Warm up
        for (int w = 0; w < 3; w++) {
          await service.evaluateStroke(
            liveStroke: sample,
            template: template,
            sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
          );
        }

        const int iterations = 50;
        final latenciesMs = <double>[];

        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()..start();
          final result = await service.evaluateStroke(
            liveStroke: sample,
            template: template,
            sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
          );
          stopwatch.stop();

          final double elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
          latenciesMs.add(elapsedMs);

          expect(result, isA<VaultSuccess<RecognitionScore>>());
        }

        latenciesMs.sort();
        final double maxLatency = latenciesMs.last;
        final double p95Latency = latenciesMs[(iterations * 0.95).floor()];
        final double medianLatency = latenciesMs[iterations ~/ 2];

        // ignore: avoid_print
        print(
          'Service Benchmark (50 runs via evaluateStroke): '
          'min=${latenciesMs.first.toStringAsFixed(2)}ms, '
          'median=${medianLatency.toStringAsFixed(2)}ms, '
          'p95=${p95Latency.toStringAsFixed(2)}ms, '
          'max=${maxLatency.toStringAsFixed(2)}ms',
        );

        expect(
          maxLatency,
          lessThanOrEqualTo(35.0),
          reason: 'Service worst-case latency exceeded 35ms SLA: ${maxLatency}ms',
        );
      });
    });

    // =========================================================================
    // 4. Concurrency Stress & Rapid Cancellation / Superseding
    // =========================================================================
    group('Concurrency Stress: Rapid Evaluations & cancelActiveEvaluation()', () {
      late GestureRecognizerService service;
      late GestureTemplate template;
      late GestureSample sample;

      setUp(() {
        service = GestureRecognizerService();
        template = createVShapeTemplate();
        final rawPoints = createRawVShape();
        sample = GestureSample(
          points: rawPoints,
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );
      });

      test('rapid burst of 10 concurrent evaluations with cancelActiveEvaluation() yields zero stale results or corruption', () async {
        const int burstCount = 10;
        final futures = <Future<VaultResult<RecognitionScore>>>[];

        // Dispatch 10 rapid evaluations interleaved with cancellations
        for (int i = 0; i < burstCount; i++) {
          final f = service.evaluateStroke(
            liveStroke: sample,
            template: template,
            sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
          );
          futures.add(f);

          // Rapid cancellation simulating pointer down event interrupting previous stroke evaluation
          service.cancelActiveEvaluation();
        }

        final results = await Future.wait(futures);

        expect(results.length, burstCount);
        for (int i = 0; i < burstCount; i++) {
          final res = results[i];
          expect(
            res,
            isA<VaultFailureResult<RecognitionScore>>(),
            reason: 'Evaluation index $i was cancelled and should have failed.',
          );
          final failure = (res as VaultFailureResult<RecognitionScore>).failure;
          expect(failure, isA<VaultGestureFailure>());
          expect(failure.message, contains('superseded'));
        }

        // Verify epoch advanced by 2 * burstCount (1 on evaluateStroke + 1 on cancelActiveEvaluation)
        expect(service.currentEpoch, burstCount * 2);
      });

      test('valid evaluation immediately following cancelled burst completes with VaultSuccess', () async {
        // Canceled evaluations burst
        for (int i = 0; i < 5; i++) {
          // ignore: unawaited_futures
          service.evaluateStroke(
            liveStroke: sample,
            template: template,
            sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
          );
          service.cancelActiveEvaluation();
        }

        // Immediate subsequent valid stroke evaluation without cancellation
        final result = await service.evaluateStroke(
          liveStroke: sample,
          template: template,
          sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
        );

        expect(result, isA<VaultSuccess<RecognitionScore>>());
        final score = (result as VaultSuccess<RecognitionScore>).data;
        expect(score.decision, GestureMatchDecisionEnum.matched);
        expect(score.ensembleScore, greaterThan(0.85));
      });

      test('monotonic epoch counter guarantees strictly ordered non-overlapping execution state', () async {
        expect(service.currentEpoch, 0);

        service.cancelActiveEvaluation();
        expect(service.currentEpoch, 1);

        service.cancelActiveEvaluation();
        expect(service.currentEpoch, 2);

        final future = service.evaluateStroke(
          liveStroke: sample,
          template: template,
          sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
        );
        expect(service.currentEpoch, 3);

        final result = await future;
        expect(result, isA<VaultSuccess<RecognitionScore>>());
      });
    });
  });
}
