import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('FastDtwRecognizer', () {
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

    // Helper to generate a temporally warped V-shape (non-uniform drawing speed)
    List<GesturePoint> createTemporallyWarpedVShape() {
      final points = <GesturePoint>[];
      // Left arm with dense clustering near bottom (apex)
      for (int i = 0; i < 32; i++) {
        final t = math.pow(i / 31.0, 1.5).toDouble();
        final x = -125.0 + (t * 125.0);
        final y = 125.0 - (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Right arm with dense clustering near bottom (apex)
      for (int i = 0; i < 32; i++) {
        final t = math.pow(i / 31.0, 0.67).toDouble();
        final x = 0.0 + (t * 125.0);
        final y = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (32 + i) * 16));
      }
      return points;
    }

    // Helper to generate a horizontal line
    List<GesturePoint> createHorizontalLine() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 64; i++) {
        final t = i / 63.0;
        final x = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: 0.0, timestampMs: i * 16));
      }
      return points;
    }

    test('constants match specifications', () {
      expect(FastDtwRecognizer.defaultSigmaDtw, 35.0);
      expect(FastDtwRecognizer.defaultWindowRadius, 10);
    });

    group('Boundary & Validation Invariants', () {
      final valid64 = createCanonicalVShape();

      test('throws FormatException if candidate length != 64', () {
        final shortPoints = List<GesturePoint>.from(valid64.take(63));
        expect(
          () => FastDtwRecognizer.matchStatic(shortPoints, valid64),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException if template length != 64', () {
        final shortPoints = List<GesturePoint>.from(valid64.take(63));
        expect(
          () => FastDtwRecognizer.matchStatic(valid64, shortPoints),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException if sigmaDtw is non-positive or non-finite', () {
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
      });

      test('throws FormatException if windowRadius is < 1', () {
        expect(
          () => FastDtwRecognizer.matchStatic(valid64, valid64, windowRadius: 0),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => FastDtwRecognizer.matchStatic(valid64, valid64, windowRadius: -1),
          throwsA(isA<FormatException>()),
        );
      });

      test('computeDtwDistance throws FormatException on empty sequences', () {
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

    group('Algorithmic Matching Correctness', () {
      final vShape = createCanonicalVShape();

      test('identical candidate and template yields distance 0.0 and score 1.0', () {
        final dist = FastDtwRecognizer.computeBidirectionalDtwDistance(vShape, vShape);
        expect(dist, 0.0);

        final score = FastDtwRecognizer.matchStatic(vShape, vShape);
        expect(score, 1.0);
      });

      test('reverse drawn stroke yields distance 0.0 and score 1.0', () {
        final reversedV = List<GesturePoint>.unmodifiable(vShape.reversed);
        final dist = FastDtwRecognizer.computeBidirectionalDtwDistance(reversedV, vShape);
        expect(dist, 0.0);

        final score = FastDtwRecognizer.matchStatic(reversedV, vShape);
        expect(score, 1.0);
      });

      test('temporally warped V-shape absorbs pacing discrepancies with score > 0.85', () {
        final warpedV = createTemporallyWarpedVShape();
        final score = FastDtwRecognizer.matchStatic(warpedV, vShape);
        expect(score, greaterThan(0.85));
      });

      test('moderate alignment error (~10px mean) yields expected score ~0.75', () {
        // Shift all points uniformly by (7.0, 7.0) -> Euclidean offset ~9.9px
        final shiftedV = vShape
            .map((p) => GesturePoint(x: p.x + 7.0, y: p.y + 7.0, timestampMs: p.timestampMs))
            .toList();
        final score = FastDtwRecognizer.matchStatic(shiftedV, vShape);
        expect(score, greaterThan(0.70));
        expect(score, lessThan(0.85));
      });

      test('exponential score formula directly maps DTW distance: S_dtw = exp(-DTW / (N * sigma))', () {
        final shifted18 = vShape
            .map((p) => GesturePoint(x: p.x + 12.65, y: p.y + 12.65, timestampMs: p.timestampMs))
            .toList();
        final dist = FastDtwRecognizer.computeBidirectionalDtwDistance(shifted18, vShape);
        final expectedScore = math.exp(-dist / (64 * 35.0));
        final actualScore = FastDtwRecognizer.matchStatic(shifted18, vShape);
        expect(actualScore, closeTo(expectedScore, 1e-6));
      });

      test('dissimilar shapes (V shape vs horizontal line) scores well below safety floor 0.60', () {
        final hLine = createHorizontalLine();
        final score = FastDtwRecognizer.matchStatic(hLine, vShape);
        expect(score, lessThan(0.60));
      });

      test('unconstrained windowRadius (null) works correctly', () {
        final score = FastDtwRecognizer.matchStatic(vShape, vShape, windowRadius: null);
        expect(score, 1.0);
      });

      test('instance method matches static evaluation', () {
        const recognizer = FastDtwRecognizer();
        final scoreInstance = recognizer.match(vShape, vShape);
        final scoreStatic = FastDtwRecognizer.matchStatic(vShape, vShape);
        expect(scoreInstance, scoreStatic);
      });
    });

    test('executes cleanly inside Isolate.run', () async {
      final vShape = createCanonicalVShape();
      final score = await Isolate.run(() {
        const recognizer = FastDtwRecognizer();
        return recognizer.match(vShape, vShape);
      });
      expect(score, 1.0);
    });
  });
}
