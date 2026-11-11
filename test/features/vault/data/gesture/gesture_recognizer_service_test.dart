import 'package:flutter_test/flutter_test.dart';
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
  group('GestureRecognizerService & runGestureRecognitionPipeline', () {
    // Helper to generate a raw V-shape stroke with 50 points and span > 100px
    List<GesturePoint> createRawVShape({double scale = 1.0, double offsetY = 0.0}) {
      final points = <GesturePoint>[];
      // Downwards left arm: (50, 50) -> (150, 250) (25 points)
      for (int i = 0; i < 25; i++) {
        final t = i / 24.0;
        final x = 50.0 + (t * 100.0 * scale);
        final y = offsetY + 50.0 + (t * 200.0 * scale);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Upwards right arm: (150, 250) -> (250, 50) (25 points)
      for (int i = 0; i < 25; i++) {
        final t = i / 24.0;
        final x = (50.0 + (100.0 * scale)) + (t * 100.0 * scale);
        final y = offsetY + (50.0 + (200.0 * scale)) - (t * 200.0 * scale);
        points.add(GesturePoint(x: x, y: y, timestampMs: (25 + i) * 16));
      }
      return points;
    }

    // Helper to construct a canonical V-shape template
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

    test('runGestureRecognitionPipeline successfully matches matching stroke', () {
      final template = createVShapeTemplate();
      final rawPoints = createRawVShape();

      final payload = GestureRecognitionIsolatePayload(
        rawPoints: rawPoints,
        templateNormalizedPoints: template.normalizedPoints,
        templateRubineVector: template.rubineFeatureVector,
        sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
      );

      final score = runGestureRecognitionPipeline(payload);
      expect(score.decision, GestureMatchDecisionEnum.matched);
      expect(score.dollarOneScore, greaterThan(0.90));
      expect(score.dtwScore, greaterThan(0.85));
      expect(score.featureScore, greaterThan(0.90));
      expect(score.ensembleScore, greaterThan(0.85));
    });

    test('runGestureRecognitionPipeline silently rejects stroke failing kinematic sanity gate', () {
      final template = createVShapeTemplate();
      // Tiny micro-touch (span < 28px, 15 points)
      final tinyPoints = List.generate(
        15,
        (i) => GesturePoint(x: 100.0 + (i * 0.5), y: 100.0 + (i * 0.5), timestampMs: i * 16),
      );

      final payload = GestureRecognitionIsolatePayload(
        rawPoints: tinyPoints,
        templateNormalizedPoints: template.normalizedPoints,
        templateRubineVector: template.rubineFeatureVector,
        sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
      );

      final score = runGestureRecognitionPipeline(payload);
      expect(score.decision, GestureMatchDecisionEnum.rejectedAntiScribble);
      expect(score.ensembleScore, 0.0);
    });

    group('GestureRecognizerService Integration', () {
      late GestureRecognizerService service;
      late GestureTemplate template;

      setUp(() {
        service = GestureRecognizerService();
        template = createVShapeTemplate();
      });

      test('evaluateStroke succeeds on valid matching stroke', () async {
        final rawPoints = createRawVShape();
        final sample = GestureSample(
          points: rawPoints,
          sampledAtEpochMs: 1700000000500,
          totalLength: 447.2,
        );

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

      test('evaluateStroke returns VaultValidationFailure on empty points', () async {
        expect(
          () => GestureSample(
            points: [],
            sampledAtEpochMs: 1700000000500,
            totalLength: 0.0,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('evaluateStroke superseding via cancelActiveEvaluation invalidates in-flight computation', () async {
        final rawPoints = createRawVShape();
        final sample = GestureSample(
          points: rawPoints,
          sampledAtEpochMs: 1700000000500,
          totalLength: 447.2,
        );

        final future = service.evaluateStroke(
          liveStroke: sample,
          template: template,
          sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
        );
        service.cancelActiveEvaluation();

        final result = await future;
        expect(result, isA<VaultFailureResult<RecognitionScore>>());
        final failure = (result as VaultFailureResult<RecognitionScore>).failure;
        expect(failure, isA<VaultGestureFailure>());
        expect(failure.message, contains('superseded'));
      });

      test('validateSampleConsistency succeeds on 3 consistent samples', () async {
        final sample1 = GestureSample(
          points: createRawVShape(scale: 1.0),
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );
        final sample2 = GestureSample(
          points: createRawVShape(scale: 1.05),
          sampledAtEpochMs: 1700000000200,
          totalLength: 469.5,
        );
        final sample3 = GestureSample(
          points: createRawVShape(scale: 0.95),
          sampledAtEpochMs: 1700000000300,
          totalLength: 424.8,
        );

        final result = await service.validateSampleConsistency(
          samples: [sample1, sample2, sample3],
        );
        expect(result, isA<VaultSuccess<void>>());
      });

      test('validateSampleConsistency fails with VaultGestureFailure on divergent samples', () async {
        final sample1 = GestureSample(
          points: createRawVShape(scale: 1.0),
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );
        final sample2 = GestureSample(
          points: createRawVShape(scale: 1.05),
          sampledAtEpochMs: 1700000000200,
          totalLength: 469.5,
        );
        final sampleHorizontal = GestureSample(
          points: List.generate(
            50,
            (i) => GesturePoint(x: 50.0 + (i * 4.0), y: 150.0, timestampMs: i * 16),
          ),
          sampledAtEpochMs: 1700000000300,
          totalLength: 196.0,
        );

        final result = await service.validateSampleConsistency(
          samples: [sample1, sample2, sampleHorizontal],
        );
        expect(result, isA<VaultFailureResult<void>>());
        final failure = (result as VaultFailureResult<void>).failure;
        expect(failure, isA<VaultGestureFailure>());
      });

      test('validateSampleConsistency fails with VaultValidationFailure on fewer than 2 samples', () async {
        final sample1 = GestureSample(
          points: createRawVShape(scale: 1.0),
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );

        final result = await service.validateSampleConsistency(samples: [sample1]);
        expect(result, isA<VaultFailureResult<void>>());
        final failure = (result as VaultFailureResult<void>).failure;
        expect(failure, isA<VaultValidationFailure>());
      });

      test('synthesizeMasterTemplate succeeds on 3 consistent samples', () async {
        final sample1 = GestureSample(
          points: createRawVShape(scale: 1.0),
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );
        final sample2 = GestureSample(
          points: createRawVShape(scale: 1.05),
          sampledAtEpochMs: 1700000000200,
          totalLength: 469.5,
        );
        final sample3 = GestureSample(
          points: createRawVShape(scale: 0.95),
          sampledAtEpochMs: 1700000000300,
          totalLength: 424.8,
        );

        final result = await service.synthesizeMasterTemplate(
          samples: [sample1, sample2, sample3],
          templateId: 'enrolled_v_template',
        );

        expect(result, isA<VaultSuccess<GestureTemplate>>());
        final template = (result as VaultSuccess<GestureTemplate>).data;
        expect(template.id, 'enrolled_v_template');
        expect(template.normalizedPoints.length, 64);
        expect(template.rubineFeatureVector.length, 7);
      });

      test('synthesizeMasterTemplate fails with VaultGestureFailure on divergent samples', () async {
        final sample1 = GestureSample(
          points: createRawVShape(scale: 1.0),
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );
        final sample2 = GestureSample(
          points: createRawVShape(scale: 1.05),
          sampledAtEpochMs: 1700000000200,
          totalLength: 469.5,
        );
        final sampleHorizontal = GestureSample(
          points: List.generate(
            50,
            (i) => GesturePoint(x: 50.0 + (i * 4.0), y: 150.0, timestampMs: i * 16),
          ),
          sampledAtEpochMs: 1700000000300,
          totalLength: 196.0,
        );

        final result = await service.synthesizeMasterTemplate(
          samples: [sample1, sample2, sampleHorizontal],
        );
        expect(result, isA<VaultFailureResult<GestureTemplate>>());
        final failure = (result as VaultFailureResult<GestureTemplate>).failure;
        expect(failure, isA<VaultGestureFailure>());
      });

      test('synthesizeMasterTemplate fails with VaultValidationFailure on fewer than 2 samples', () async {
        final sample1 = GestureSample(
          points: createRawVShape(scale: 1.0),
          sampledAtEpochMs: 1700000000100,
          totalLength: 447.2,
        );

        final result = await service.synthesizeMasterTemplate(samples: [sample1]);
        expect(result, isA<VaultFailureResult<GestureTemplate>>());
        final failure = (result as VaultFailureResult<GestureTemplate>).failure;
        expect(failure, isA<VaultValidationFailure>());
      });
    });
  });
}
