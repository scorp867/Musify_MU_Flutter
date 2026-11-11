import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/gesture/dollar_one_b_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_isolate_payloads.dart';
import 'package:musify_mu/features/vault/data/gesture/rubine_feature_extractor.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

void main() {
  group('DefaultGestureTemplate Invariants & Canonical Properties', () {
    test('canonicalVShape adheres to strict domain invariants', () {
      final GestureTemplate template = DefaultGestureTemplate.canonicalVShape;

      expect(template.id, DefaultGestureTemplate.canonicalId);
      expect(template.id, DefaultGestureTemplate.defaultTemplateId);
      expect(template.createdAtEpochMs, DefaultGestureTemplate.defaultCreationEpochMs);
      expect(template.normalizedPoints.length, GestureTemplate.requiredPointCount);
      expect(
        template.rubineFeatureVector.length,
        GestureTemplate.requiredFeatureVectorDimensions,
      );

      // Verify deep immutability
      expect(
        () => (template.normalizedPoints as dynamic).add(
          GesturePoint(x: 0, y: 0, timestampMs: 0),
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => (template.rubineFeatureVector as dynamic).add(0.5),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('canonicalPoints coordinates match exact mathematical formula', () {
      final points = DefaultGestureTemplate.canonicalPoints;
      expect(points.length, 64);

      // Bounding box span
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;
      double sumX = 0.0;

      for (int i = 0; i < 64; i++) {
        final pt = points[i];
        if (pt.x < minX) minX = pt.x;
        if (pt.x > maxX) maxX = pt.x;
        if (pt.y < minY) minY = pt.y;
        if (pt.y > maxY) maxY = pt.y;
        sumX += pt.x;

        // Check analytical formula
        final double expectedX = -125.0 + (i * (250.0 / 63.0));
        final int armIndex = (i <= 31) ? i : (63 - i);
        final double expectedY = -125.0 + (armIndex * (250.0 / 31.0));

        expect(pt.x, closeTo(expectedX, 1e-9));
        expect(pt.y, closeTo(expectedY, 1e-9));
      }

      // Origin centering and bounding box dimensions
      expect(minX, closeTo(-125.0, 1e-9));
      expect(maxX, closeTo(125.0, 1e-9));
      expect(minY, closeTo(-125.0, 1e-9));
      expect(maxY, closeTo(125.0, 1e-9));
      expect(sumX / 64.0, closeTo(0.0, 1e-9));

      // Endpoints and apex
      expect(points.first.x, closeTo(-125.0, 1e-9));
      expect(points.first.y, closeTo(-125.0, 1e-9));
      expect(points.last.x, closeTo(125.0, 1e-9));
      expect(points.last.y, closeTo(-125.0, 1e-9));
      expect(points[31].y, closeTo(125.0, 1e-9));
    });

    test('canonicalRubineVector matches RubineFeatureExtractor extracted vector', () {
      final expectedVector = DefaultGestureTemplate.canonicalRubineVector;
      final extractedVector = RubineFeatureExtractor.extractFeaturesStatic(
        DefaultGestureTemplate.canonicalPoints,
      );

      expect(extractedVector.length, 7);
      for (int i = 0; i < 7; i++) {
        expect(extractedVector[i], closeTo(expectedVector[i], 1e-7));
      }

      final double cosineSim = RubineFeatureExtractor.computeCosineSimilarityStatic(
        expectedVector,
        extractedVector,
      );
      expect(cosineSim, closeTo(1.0, 1e-9));
    });

    test('Self-matching on canonical template achieves perfect scores across engines', () {
      final points = DefaultGestureTemplate.canonicalPoints;
      final template = DefaultGestureTemplate.canonicalVShape;

      final double dollarOneScore = const DollarOneBRecognizer().match(
        points,
        template.normalizedPoints,
      );
      expect(dollarOneScore, closeTo(1.0, 1e-4));

      final double dtwDistance = FastDtwRecognizer.computeDtwDistance(
        points,
        template.normalizedPoints,
      );
      expect(dtwDistance, closeTo(0.0, 1e-9));

      final double dtwScore = const FastDtwRecognizer().match(
        points,
        template.normalizedPoints,
      );
      expect(dtwScore, closeTo(1.0, 1e-4));

      final double rubineScore = const RubineFeatureExtractor().matchBidirectional(
        points,
        template.rubineFeatureVector,
      );
      expect(rubineScore, closeTo(1.0, 1e-4));
    });

    test('Matches simulated human-drawn V stroke achieving strict92Percent threshold >= 0.88', () {
      final template = DefaultGestureTemplate.canonicalVShape;

      // Simulate human drawn "V" gesture with slight hand tremor
      final rawPoints = <GesturePoint>[];
      // Left arm downwards: (60, 60) -> (175, 300) with 30 points
      for (int i = 0; i < 30; i++) {
        final double t = i / 29.0;
        final double noiseX = math.sin(i * 1.5) * 1.2;
        final double noiseY = math.cos(i * 1.2) * 1.2;
        rawPoints.add(
          GesturePoint(
            x: 60.0 + (t * 115.0) + noiseX,
            y: 60.0 + (t * 240.0) + noiseY,
            timestampMs: i * 16,
          ),
        );
      }
      // Right arm upwards: (175, 300) -> (290, 60) with 30 points
      for (int i = 0; i < 30; i++) {
        final double t = i / 29.0;
        final double noiseX = math.cos(i * 1.1) * 1.2;
        final double noiseY = math.sin(i * 1.4) * 1.2;
        rawPoints.add(
          GesturePoint(
            x: 175.0 + (t * 115.0) + noiseX,
            y: 300.0 - (t * 240.0) + noiseY,
            timestampMs: (30 + i) * 16,
          ),
        );
      }

      final payload = GestureRecognitionIsolatePayload(
        rawPoints: rawPoints,
        templateNormalizedPoints: template.normalizedPoints,
        templateRubineVector: template.rubineFeatureVector,
        sensitivityTier: GestureSensitivityTierEnum.strict92Percent,
      );

      final RecognitionScore score = runGestureRecognitionPipeline(payload);

      expect(score.decision, GestureMatchDecisionEnum.matched);
      expect(score.ensembleScore, greaterThanOrEqualTo(0.88));
      expect(score.dollarOneScore, greaterThan(0.90));
      expect(score.dtwScore, greaterThan(0.85));
      expect(score.featureScore, greaterThan(0.90));
    });

    test('Decisively rejects non-V adversarial strokes at classifier safety floor', () {
      final template = DefaultGestureTemplate.canonicalVShape;

      // 1. Horizontal straight line
      final horizontalPoints = List.generate(
        50,
        (i) => GesturePoint(x: 50.0 + (i * 5.0), y: 150.0, timestampMs: i * 16),
      );
      final horizPayload = GestureRecognitionIsolatePayload(
        rawPoints: horizontalPoints,
        templateNormalizedPoints: template.normalizedPoints,
        templateRubineVector: template.rubineFeatureVector,
        sensitivityTier: GestureSensitivityTierEnum.strict92Percent,
      );
      final horizScore = runGestureRecognitionPipeline(horizPayload);
      expect(horizScore.decision, isNot(GestureMatchDecisionEnum.matched));
      expect(horizScore.dtwScore, lessThan(0.60));

      // 2. Circle / closed loop
      final circlePoints = <GesturePoint>[];
      for (int i = 0; i < 60; i++) {
        final double angle = (i / 60.0) * 2 * math.pi;
        circlePoints.add(
          GesturePoint(
            x: 150.0 + (80.0 * math.cos(angle)),
            y: 150.0 + (80.0 * math.sin(angle)),
            timestampMs: i * 16,
          ),
        );
      }
      final circlePayload = GestureRecognitionIsolatePayload(
        rawPoints: circlePoints,
        templateNormalizedPoints: template.normalizedPoints,
        templateRubineVector: template.rubineFeatureVector,
        sensitivityTier: GestureSensitivityTierEnum.strict92Percent,
      );
      final circleScore = runGestureRecognitionPipeline(circlePayload);
      expect(circleScore.decision, isNot(GestureMatchDecisionEnum.matched));
      expect(circleScore.dtwScore, lessThan(0.60));
    });
  });
}
