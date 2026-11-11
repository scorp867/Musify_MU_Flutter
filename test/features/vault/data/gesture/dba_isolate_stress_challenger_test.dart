import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/dba_synthesizer.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_isolate_payloads.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

void main() {
  group('Empirical Challenger: DBA Isolate Concurrency & Stress Suite', () {
    // -------------------------------------------------------------------------
    // Helper Generators
    // -------------------------------------------------------------------------

    /// Generates a realistic raw single-stroke "V" shape with [pointCountPerArm] points per arm.
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

    /// Generates a straight horizontal line sample of [pointCount] points.
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

    // =========================================================================
    // 1. Background Isolate Latency & Stress Benchmarking
    // =========================================================================
    group('Background Isolate Latency Benchmarks (SLA <= 35ms synthesis, <= 20ms consistency)', () {
      late GestureRecognizerService service;
      late List<GestureSample> consistentSamples;

      setUp(() {
        service = GestureRecognizerService();
        consistentSamples = [
          createSampleV(jitter: 0.5, scale: 1.0, epoch: 1700000000100),
          createSampleV(jitter: 0.8, scale: 1.04, epoch: 1700000000200),
          createSampleV(jitter: 0.6, scale: 0.96, epoch: 1700000000300),
        ];
      });

      test('synthesizeMasterTemplate execution latency inside Isolate.run completes in <= 35ms (excluding warmup)', () async {
        // Warm-up isolate pool and JIT compiler
        for (int w = 0; w < 3; w++) {
          final warmResult = await service.synthesizeMasterTemplate(
            samples: consistentSamples,
            templateId: 'warmup_template_$w',
          );
          expect(warmResult, isA<VaultSuccess<GestureTemplate>>());
        }

        const int iterations = 20;
        final latenciesMs = <double>[];

        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()..start();
          final result = await service.synthesizeMasterTemplate(
            samples: consistentSamples,
            templateId: 'benchmark_template_$i',
          );
          stopwatch.stop();

          final double elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
          latenciesMs.add(elapsedMs);

          expect(result, isA<VaultSuccess<GestureTemplate>>());
        }

        latenciesMs.sort();
        final double minLatency = latenciesMs.first;
        final double medianLatency = latenciesMs[iterations ~/ 2];
        final double p95Latency = latenciesMs[(iterations * 0.95).floor()];
        final double maxLatency = latenciesMs.last;

        // Telemetry logging for audit trail
        // ignore: avoid_print
        print(
          'synthesizeMasterTemplate Latency (20 runs via Isolate.run): '
          'min=${minLatency.toStringAsFixed(2)}ms, '
          'median=${medianLatency.toStringAsFixed(2)}ms, '
          'p95=${p95Latency.toStringAsFixed(2)}ms, '
          'max=${maxLatency.toStringAsFixed(2)}ms',
        );

        expect(
          maxLatency,
          lessThanOrEqualTo(35.0),
          reason: 'Worst-case isolate synthesis latency exceeded 35ms SLA: ${maxLatency.toStringAsFixed(2)}ms',
        );
        expect(medianLatency, lessThan(25.0));
      });

      test('validateSampleConsistency execution latency inside Isolate.run completes in <= 20ms (excluding warmup)', () async {
        // Warm-up
        for (int w = 0; w < 3; w++) {
          final warmResult = await service.validateSampleConsistency(
            samples: consistentSamples,
          );
          expect(warmResult, isA<VaultSuccess<void>>());
        }

        const int iterations = 20;
        final latenciesMs = <double>[];

        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()..start();
          final result = await service.validateSampleConsistency(
            samples: consistentSamples,
          );
          stopwatch.stop();

          final double elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
          latenciesMs.add(elapsedMs);

          expect(result, isA<VaultSuccess<void>>());
        }

        latenciesMs.sort();
        final double minLatency = latenciesMs.first;
        final double medianLatency = latenciesMs[iterations ~/ 2];
        final double p95Latency = latenciesMs[(iterations * 0.95).floor()];
        final double maxLatency = latenciesMs.last;

        // ignore: avoid_print
        print(
          'validateSampleConsistency Latency (20 runs via Isolate.run): '
          'min=${minLatency.toStringAsFixed(2)}ms, '
          'median=${medianLatency.toStringAsFixed(2)}ms, '
          'p95=${p95Latency.toStringAsFixed(2)}ms, '
          'max=${maxLatency.toStringAsFixed(2)}ms',
        );

        expect(
          maxLatency,
          lessThanOrEqualTo(20.0),
          reason: 'Worst-case isolate consistency latency exceeded 20ms SLA: ${maxLatency.toStringAsFixed(2)}ms',
        );
        expect(medianLatency, lessThan(15.0));
      });

      test('runGestureSynthesisPipeline directly inside Isolate.run meets latency constraint', () async {
        final payload = GestureSynthesisIsolatePayload.fromDomain(
          samples: consistentSamples,
          templateId: 'direct_isolate_synthesis',
        );

        // Warmup
        await Isolate.run(() => runGestureSynthesisPipeline(payload));

        final stopwatch = Stopwatch()..start();
        final GestureTemplate template = await Isolate.run(
          () => runGestureSynthesisPipeline(payload),
        );
        stopwatch.stop();

        final double elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
        expect(template.id, 'direct_isolate_synthesis');
        expect(template.normalizedPoints.length, 64);
        expect(elapsedMs, lessThanOrEqualTo(35.0));
      });

      test('runGestureConsistencyPipeline directly inside Isolate.run meets latency constraint', () async {
        final payload = GestureConsistencyIsolatePayload.fromDomain(
          samples: consistentSamples,
        );

        // Warmup
        await Isolate.run(() => runGestureConsistencyPipeline(payload));

        final stopwatch = Stopwatch()..start();
        await Isolate.run(() => runGestureConsistencyPipeline(payload));
        stopwatch.stop();

        final double elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
        expect(elapsedMs, lessThanOrEqualTo(20.0));
      });
    });

    // =========================================================================
    // 2. Parallel Synthesis & Concurrency Stress
    // =========================================================================
    group('Parallel Synthesis & Concurrency Stress (Thread Pool Safety)', () {
      late GestureRecognizerService service;
      late List<GestureSample> consistentSamples;

      setUp(() {
        service = GestureRecognizerService();
        consistentSamples = [
          createSampleV(jitter: 0.5, scale: 1.0, epoch: 1700000000100),
          createSampleV(jitter: 0.8, scale: 1.04, epoch: 1700000000200),
          createSampleV(jitter: 0.6, scale: 0.96, epoch: 1700000000300),
        ];
      });

      test('dispatch 5 parallel synthesis requests simultaneously without deadlock or race conditions', () async {
        const int concurrentCount = 5;
        final futures = <Future<VaultResult<GestureTemplate>>>[];

        for (int i = 0; i < concurrentCount; i++) {
          final f = service.synthesizeMasterTemplate(
            samples: consistentSamples,
            templateId: 'parallel_template_$i',
          );
          futures.add(f);
        }

        final List<VaultResult<GestureTemplate>> results = await Future.wait(futures);

        expect(results.length, concurrentCount);
        for (int i = 0; i < concurrentCount; i++) {
          final res = results[i];
          expect(res, isA<VaultSuccess<GestureTemplate>>());
          final template = (res as VaultSuccess<GestureTemplate>).data;
          expect(template.id, 'parallel_template_$i');
          expect(template.normalizedPoints.length, 64);
          expect(template.rubineFeatureVector.length, 7);

          // Verify normalization coordinates sanity
          double sumX = 0.0;
          double sumY = 0.0;
          for (final pt in template.normalizedPoints) {
            sumX += pt.x;
            sumY += pt.y;
          }
          expect(sumX / 64.0, closeTo(0.0, 1e-3));
          expect(sumY / 64.0, closeTo(0.0, 1e-3));
        }
      });

      test('dispatch 10 mixed parallel requests (5 synthesis + 5 consistency) safely', () async {
        final synthesisFutures = <Future<VaultResult<GestureTemplate>>>[];
        final consistencyFutures = <Future<VaultResult<void>>>[];

        for (int i = 0; i < 5; i++) {
          synthesisFutures.add(
            service.synthesizeMasterTemplate(
              samples: consistentSamples,
              templateId: 'mixed_synthesis_$i',
            ),
          );
          consistencyFutures.add(
            service.validateSampleConsistency(samples: consistentSamples),
          );
        }

        final synResults = await Future.wait(synthesisFutures);
        final conResults = await Future.wait(consistencyFutures);

        expect(synResults.length, 5);
        expect(conResults.length, 5);

        for (final res in synResults) {
          expect(res, isA<VaultSuccess<GestureTemplate>>());
        }
        for (final res in conResults) {
          expect(res, isA<VaultSuccess<void>>());
        }
      });
    });

    // =========================================================================
    // 3. Payload Boundary Validation & DTO Invariants
    // =========================================================================
    group('Payload Boundary Validation & DTO Invariants', () {
      late GestureSample sample1;
      late GestureSample sample2;

      setUp(() {
        sample1 = createSampleV(scale: 1.0, epoch: 1700000000100);
        sample2 = createSampleV(scale: 1.05, epoch: 1700000000200);
      });

      test('GestureConsistencyIsolatePayload rejects empty samples with FormatException', () {
        expect(
          () => GestureConsistencyIsolatePayload(samples: []),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('requires at least 2 samples'),
            ),
          ),
        );
      });

      test('GestureConsistencyIsolatePayload rejects single sample with FormatException', () {
        expect(
          () => GestureConsistencyIsolatePayload(samples: [sample1]),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('requires at least 2 samples'),
            ),
          ),
        );
      });

      test('GestureConsistencyIsolatePayload rejects invalid referenceDimension with FormatException', () {
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            referenceDimension: 0.0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            referenceDimension: -100.0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            referenceDimension: double.nan,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureConsistencyIsolatePayload rejects invalid consistencyThreshold with FormatException', () {
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            consistencyThreshold: 0.0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            consistencyThreshold: 1.0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            consistencyThreshold: 1.5,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureConsistencyIsolatePayload rejects invalid windowRadius and sigmaDtw with FormatException', () {
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            windowRadius: 0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureConsistencyIsolatePayload(
            samples: [sample1, sample2],
            sigmaDtw: 0.0,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureConsistencyIsolatePayload collections are deeply unmodifiable', () {
        final payload = GestureConsistencyIsolatePayload(
          samples: [sample1, sample2],
        );
        expect(
          () => (payload.samples as List).add(sample1),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('GestureSynthesisIsolatePayload rejects empty or single sample with FormatException', () {
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [],
            templateId: 'test_id',
            createdAtEpochMs: 1700000000000,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1],
            templateId: 'test_id',
            createdAtEpochMs: 1700000000000,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureSynthesisIsolatePayload rejects blank templateId with FormatException', () {
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: '',
            createdAtEpochMs: 1700000000000,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('templateId must not be empty'),
            ),
          ),
        );
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: '   ',
            createdAtEpochMs: 1700000000000,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureSynthesisIsolatePayload rejects non-positive createdAtEpochMs with FormatException', () {
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: 'valid_id',
            createdAtEpochMs: 0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: 'valid_id',
            createdAtEpochMs: -500,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureSynthesisIsolatePayload rejects invalid numerical parameters with FormatException', () {
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: 'valid_id',
            createdAtEpochMs: 1700000000000,
            maxIterations: 0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: 'valid_id',
            createdAtEpochMs: 1700000000000,
            convergenceTolerance: 0.0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: 'valid_id',
            createdAtEpochMs: 1700000000000,
            windowRadius: 0,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureSynthesisIsolatePayload(
            samples: [sample1, sample2],
            templateId: 'valid_id',
            createdAtEpochMs: 1700000000000,
            sigmaDtw: -1.0,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('GestureRecognizerService boundary returns VaultValidationFailure on malformed payloads', () async {
        final service = GestureRecognizerService();

        // Fewer than 2 samples
        final synthResult = await service.synthesizeMasterTemplate(
          samples: [sample1],
          templateId: 'valid_id',
        );
        expect(synthResult, isA<VaultFailureResult<GestureTemplate>>());
        final synthFailure = (synthResult as VaultFailureResult<GestureTemplate>).failure;
        expect(synthFailure, isA<VaultValidationFailure>());

        final conResult = await service.validateSampleConsistency(
          samples: [sample1],
        );
        expect(conResult, isA<VaultFailureResult<void>>());
        final conFailure = (conResult as VaultFailureResult<void>).failure;
        expect(conFailure, isA<VaultValidationFailure>());
      });

      test('GestureRecognizerService returns VaultGestureFailure on divergent samples', () async {
        final service = GestureRecognizerService();
        final divergentSample = createSampleHorizontal();

        final synthResult = await service.synthesizeMasterTemplate(
          samples: [sample1, sample2, divergentSample],
          templateId: 'valid_id',
        );
        expect(synthResult, isA<VaultFailureResult<GestureTemplate>>());
        final synthFailure = (synthResult as VaultFailureResult<GestureTemplate>).failure;
        expect(synthFailure, isA<VaultGestureFailure>());

        final conResult = await service.validateSampleConsistency(
          samples: [sample1, sample2, divergentSample],
        );
        expect(conResult, isA<VaultFailureResult<void>>());
        final conFailure = (conResult as VaultFailureResult<void>).failure;
        expect(conFailure, isA<VaultGestureFailure>());
      });
    });

    // =========================================================================
    // 4. Cancellation & Active Evaluation Cleanliness
    // =========================================================================
    group('Cancellation & Active Evaluation Cleanliness', () {
      late GestureRecognizerService service;
      late GestureTemplate template;
      late GestureSample sample;

      setUp(() {
        service = GestureRecognizerService();
        template = DefaultGestureTemplate.canonicalVShape;
        final rawPoints = [
          ...List.generate(
            25,
            (i) => GesturePoint(
              x: 50.0 + (i / 24.0 * 100.0),
              y: 50.0 + (i / 24.0 * 200.0),
              timestampMs: i * 16,
            ),
          ),
          ...List.generate(
            25,
            (i) => GesturePoint(
              x: 150.0 + (i / 24.0 * 100.0),
              y: 250.0 - (i / 24.0 * 200.0),
              timestampMs: (25 + i) * 16,
            ),
          ),
        ];
        sample = GestureSample(
          points: rawPoints,
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );
      });

      test('initial currentEpoch is 0 and cancelActiveEvaluation increments it cleanly and monotonically', () {
        expect(service.currentEpoch, 0);

        service.cancelActiveEvaluation();
        expect(service.currentEpoch, 1);

        service.cancelActiveEvaluation();
        expect(service.currentEpoch, 2);

        for (int i = 0; i < 8; i++) {
          service.cancelActiveEvaluation();
        }
        expect(service.currentEpoch, 10);
      });

      test('cancelActiveEvaluation renders active in-flight evaluateStroke dead-on-arrival with VaultGestureFailure', () async {
        final future = service.evaluateStroke(
          liveStroke: sample,
          template: template,
          sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
        );

        // Cancel immediately
        service.cancelActiveEvaluation();

        final result = await future;
        expect(result, isA<VaultFailureResult<RecognitionScore>>());
        final failure = (result as VaultFailureResult<RecognitionScore>).failure;
        expect(failure, isA<VaultGestureFailure>());
        expect(failure.message, contains('superseded'));
      });

      test('cancelActiveEvaluation does not corrupt or abort independent master template synthesis', () async {
        final sample1 = createSampleV(scale: 1.0, epoch: 1700000000100);
        final sample2 = createSampleV(scale: 1.05, epoch: 1700000000200);
        final sample3 = createSampleV(scale: 0.95, epoch: 1700000000300);

        final synthFuture = service.synthesizeMasterTemplate(
          samples: [sample1, sample2, sample3],
          templateId: 'independent_synthesis',
        );

        // Active stroke evaluation cancellation during enrollment does not affect synthesis
        service.cancelActiveEvaluation();
        service.cancelActiveEvaluation();

        final synthResult = await synthFuture;
        expect(synthResult, isA<VaultSuccess<GestureTemplate>>());
        final synthesized = (synthResult as VaultSuccess<GestureTemplate>).data;
        expect(synthesized.id, 'independent_synthesis');
        expect(synthesized.normalizedPoints.length, 64);
      });
    });

    // =========================================================================
    // 5. Adversarial Geometry Alignment & Outlier Diagnostics
    // =========================================================================
    group('Adversarial Geometry Alignment & Outlier Diagnostics', () {
      test('Synthesis correctly inverts reverse-drawn stroke and aligns with forward orientation', () {
        final sampleForward1 = createSampleV(scale: 1.0, reverse: false, epoch: 1700000000100);
        // Reverse-drawn sample (starts from right arm down to vertex, then up left arm)
        final sampleReverse = createSampleV(scale: 1.05, reverse: true, epoch: 1700000000200);
        final sampleForward2 = createSampleV(scale: 0.95, reverse: false, epoch: 1700000000300);

        const synthesizer = DbaSynthesizer();
        final template = synthesizer.synthesize(
          samples: [sampleForward1, sampleReverse, sampleForward2],
          id: 'aligned_reversed_test',
        );

        expect(template.id, 'aligned_reversed_test');
        expect(template.normalizedPoints.length, 64);

        // Point 0 should be at top-left (negative x, negative y in centered space)
        final p0 = template.normalizedPoints.first;
        final pLast = template.normalizedPoints.last;

        expect(p0.x, lessThan(0.0), reason: 'Point 0 should be on left side');
        expect(pLast.x, greaterThan(0.0), reason: 'Last point should be on right side');

        // Check vertex occurs near middle (index 28-36) with maximum positive y (bottom)
        int maxYIndex = 0;
        double maxY = -double.infinity;
        for (int i = 0; i < template.normalizedPoints.length; i++) {
          if (template.normalizedPoints[i].y > maxY) {
            maxY = template.normalizedPoints[i].y;
            maxYIndex = i;
          }
        }
        expect(maxYIndex, inInclusiveRange(28, 36));
      });

      test('Outlier diagnostics accurately identifies divergent stroke index in 3 samples', () {
        final sampleV1 = createSampleV(scale: 1.0);
        final sampleV2 = createSampleV(scale: 1.05);
        final sampleHoriz = createSampleHorizontal();

        // Sample 2 is outlier
        final normSamples1 = [
          DbaSynthesizer.standardizeSample(sampleV1),
          DbaSynthesizer.standardizeSample(sampleV2),
          DbaSynthesizer.standardizeSample(sampleHoriz),
        ];
        final res1 = DbaSynthesizer.evaluateNormalizedConsistency(
          normalizedSamples: normSamples1,
        );
        expect(res1.isConsistent, isFalse);
        expect(res1.outlierIndex, 2);

        // Sample 0 is outlier
        final normSamples2 = [
          DbaSynthesizer.standardizeSample(sampleHoriz),
          DbaSynthesizer.standardizeSample(sampleV1),
          DbaSynthesizer.standardizeSample(sampleV2),
        ];
        final res2 = DbaSynthesizer.evaluateNormalizedConsistency(
          normalizedSamples: normSamples2,
        );
        expect(res2.isConsistent, isFalse);
        expect(res2.outlierIndex, 0);
      });

      test('DBA early stops in 1 iteration when given identical samples', () {
        final sample = createSampleV(scale: 1.0);
        const synthesizer = DbaSynthesizer();

        // Synthesize with 3 identical samples
        final template = synthesizer.synthesize(
          samples: [sample, sample, sample],
          id: 'identical_samples_test',
          maxIterations: 5,
          convergenceTolerance: 0.5,
        );

        expect(template.id, 'identical_samples_test');
        expect(template.normalizedPoints.length, 64);
      });

      test('Scaling to K = 5 samples synthesizes cleanly and preserves performance', () async {
        final samples = List.generate(
          5,
          (i) => createSampleV(
            scale: 0.95 + (i * 0.025),
            jitter: 0.2 * i,
            epoch: 1700000000000 + (i * 100),
          ),
        );

        final service = GestureRecognizerService();
        final stopwatch = Stopwatch()..start();
        final result = await service.synthesizeMasterTemplate(
          samples: samples,
          templateId: 'five_sample_template',
        );
        stopwatch.stop();

        expect(result, isA<VaultSuccess<GestureTemplate>>());
        final template = (result as VaultSuccess<GestureTemplate>).data;
        expect(template.id, 'five_sample_template');
        expect(template.normalizedPoints.length, 64);
        expect(template.rubineFeatureVector.length, 7);

        // ignore: avoid_print
        print('5-sample synthesis elapsed: ${(stopwatch.elapsedMicroseconds / 1000.0).toStringAsFixed(2)}ms');
      });
    });
  });
}
