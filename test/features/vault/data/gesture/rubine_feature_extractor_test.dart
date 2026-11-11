import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/rubine_feature_extractor.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('RubineFeatureExtractor', () {
    // Helper to generate a canonical V-shape 64-point sequence
    List<GesturePoint> createCanonicalVShape() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 32; i++) {
        final t = i / 31.0;
        final x = -125.0 + (t * 125.0);
        final y = 125.0 - (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      for (int i = 0; i < 32; i++) {
        final t = i / 31.0;
        final x = 0.0 + (t * 125.0);
        final y = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (32 + i) * 16));
      }
      return points;
    }

    // Helper to generate a horizontal line across 64 points
    List<GesturePoint> createHorizontalLine() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 64; i++) {
        final t = i / 63.0;
        final x = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: 0.0, timestampMs: i * 16));
      }
      return points;
    }

    test('constants match specification', () {
      expect(RubineFeatureExtractor.featureDimensions, 7);
      expect(RubineFeatureExtractor.minRequiredPoints, 4);
      expect(RubineFeatureExtractor.epsilon, 1e-12);
    });

    group('Boundary & Validation Invariants', () {
      test('throws FormatException if points count < 4', () {
        final threePoints = [
          GesturePoint(x: 0, y: 0, timestampMs: 0),
          GesturePoint(x: 10, y: 10, timestampMs: 16),
          GesturePoint(x: 20, y: 20, timestampMs: 32),
        ];
        expect(
          () => RubineFeatureExtractor.extractFeaturesStatic(threePoints),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException if points contain non-finite coordinates', () {
        final pointsWithNan = [
          const GesturePoint.constant(x: 0, y: 0, timestampMs: 0),
          const GesturePoint.constant(x: 10, y: 10, timestampMs: 16),
          const GesturePoint.constant(x: 20, y: 20, timestampMs: 32),
          const GesturePoint.constant(x: double.nan, y: 30, timestampMs: 48),
        ];
        expect(
          () => RubineFeatureExtractor.extractFeaturesStatic(pointsWithNan),
          throwsA(isA<FormatException>()),
        );
      });

      test('computeCosineSimilarity throws FormatException if vector length != 7', () {
        final vec6 = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6];
        final vec7 = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];
        expect(
          () => RubineFeatureExtractor.computeCosineSimilarityStatic(vec6, vec7),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => RubineFeatureExtractor.computeCosineSimilarityStatic(vec7, vec6),
          throwsA(isA<FormatException>()),
        );
      });

      test('computeCosineSimilarity throws FormatException on non-finite values', () {
        final vecA = [0.1, 0.2, double.nan, 0.4, 0.5, 0.6, 0.7];
        final vecB = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];
        expect(
          () => RubineFeatureExtractor.computeCosineSimilarityStatic(vecA, vecB),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Feature Vector Mathematical Extraction', () {
      final vShape = createCanonicalVShape();

      test('extractFeatures produces exactly 7 normalized values in [0.0, 1.0]', () {
        final features = RubineFeatureExtractor.extractFeaturesStatic(vShape);
        expect(features.length, 7);
        for (int i = 0; i < 7; i++) {
          expect(features[i], greaterThanOrEqualTo(0.0));
          expect(features[i], lessThanOrEqualTo(1.0));
        }
      });

      test('V-shape peak curvature f_7 is located at apex vertex (~0.50)', () {
        final features = RubineFeatureExtractor.extractFeaturesStatic(vShape);
        // Apex is at index 31 out of 64 -> ~31/64 = 0.484375
        expect(features[6], closeTo(31.0 / 64.0, 0.05));
      });

      test('straight horizontal line yields f_5 = 1.0, f_6 = 0.50, and f_7 = 0.0', () {
        final hLine = createHorizontalLine();
        final features = RubineFeatureExtractor.extractFeaturesStatic(hLine);
        expect(features[4], closeTo(1.0, 1e-5)); // D_net / L = 1.0
        expect(features[5], closeTo(0.5, 1e-5)); // Theta_signed = 0 -> (0 + 4pi)/(8pi) = 0.5
        expect(features[6], closeTo(0.0, 1e-5)); // No curvature peak
      });
    });

    group('Cosine Similarity & Bidirectional Matching', () {
      final vShape = createCanonicalVShape();

      test('identical feature vectors yield cosine similarity of 1.0', () {
        final features = RubineFeatureExtractor.extractFeaturesStatic(vShape);
        final similarity = RubineFeatureExtractor.computeCosineSimilarityStatic(features, features);
        expect(similarity, closeTo(1.0, 1e-5));
      });

      test('zero-norm feature vector safely yields 0.0 without division by zero', () {
        final zeroVec = List<double>.filled(7, 0.0);
        final normalVec = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
        final similarity = RubineFeatureExtractor.computeCosineSimilarityStatic(zeroVec, normalVec);
        expect(similarity, 0.0);
      });

      test('bidirectional matching correctly handles both forward and reverse strokes', () {
        final templateFeatures = RubineFeatureExtractor.extractFeaturesStatic(vShape);

        // Forward stroke
        final forwardScore = RubineFeatureExtractor.matchBidirectionalStatic(
          vShape,
          templateFeatures,
        );
        expect(forwardScore, closeTo(1.0, 1e-5));

        // Reverse stroke
        final reversePoints = List<GesturePoint>.unmodifiable(vShape.reversed);
        final reverseScore = RubineFeatureExtractor.matchBidirectionalStatic(
          reversePoints,
          templateFeatures,
        );
        // Reverse V-shape has same topology, cosine similarity against template should be high (> 0.68)
        expect(reverseScore, greaterThan(0.68));
      });

      test('dissimilar feature vector falls below structural gate (0.68)', () {
        final vFeatures = RubineFeatureExtractor.extractFeaturesStatic(vShape);
        // Vector with opposed characteristics (e.g. inverted angles and zero peak)
        final divergentVector = [0.0, 1.0, 0.0, 0.0, 0.0, 0.1, 0.0];
        final similarity = RubineFeatureExtractor.computeCosineSimilarityStatic(
          vFeatures,
          divergentVector,
        );
        expect(similarity, lessThan(0.68));
      });

      test('instance methods match static evaluations', () {
        const extractor = RubineFeatureExtractor();
        final featuresInst = extractor.extractFeatures(vShape);
        final featuresStat = RubineFeatureExtractor.extractFeaturesStatic(vShape);
        expect(featuresInst, featuresStat);

        final simInst = extractor.computeCosineSimilarity(featuresInst, featuresInst);
        final simStat = RubineFeatureExtractor.computeCosineSimilarityStatic(featuresStat, featuresStat);
        expect(simInst, simStat);

        final biInst = extractor.matchBidirectional(vShape, featuresInst);
        final biStat = RubineFeatureExtractor.matchBidirectionalStatic(vShape, featuresStat);
        expect(biInst, biStat);
      });
    });

    test('executes cleanly inside Isolate.run', () async {
      final vShape = createCanonicalVShape();
      final score = await Isolate.run(() {
        const extractor = RubineFeatureExtractor();
        final templateVector = extractor.extractFeatures(vShape);
        return extractor.matchBidirectional(vShape, templateVector);
      });
      expect(score, closeTo(1.0, 1e-5));
    });
  });
}
