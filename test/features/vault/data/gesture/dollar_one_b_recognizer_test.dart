import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/dollar_one_b_recognizer.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('DollarOneBRecognizer', () {
    // Helper to generate a canonical V-shape 64-point sequence centered around (0, 0)
    List<GesturePoint> createCanonicalVShape() {
      final points = <GesturePoint>[];
      // Left arm: from (-125.0, 125.0) down to (0.0, -125.0) across 32 points
      for (int i = 0; i < 32; i++) {
        final t = i / 31.0;
        final x = -125.0 + (t * 125.0);
        final y = 125.0 - (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
      }
      // Right arm: from (0.0, -125.0) up to (125.0, 125.0) across 32 points
      for (int i = 0; i < 32; i++) {
        final t = i / 31.0;
        final x = 0.0 + (t * 125.0);
        final y = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: y, timestampMs: (32 + i) * 16));
      }
      return points;
    }

    // Helper to generate a straight horizontal line across 64 points
    List<GesturePoint> createHorizontalLine() {
      final points = <GesturePoint>[];
      for (int i = 0; i < 64; i++) {
        final t = i / 63.0;
        final x = -125.0 + (t * 250.0);
        points.add(GesturePoint(x: x, y: 0.0, timestampMs: i * 16));
      }
      return points;
    }

    // Helper to rotate a 64-point sequence by angle theta
    List<GesturePoint> rotatePoints(List<GesturePoint> input, double theta) {
      final cosT = math.cos(theta);
      final sinT = math.sin(theta);
      final rotated = <GesturePoint>[];
      for (final p in input) {
        final rx = (p.x * cosT) - (p.y * sinT);
        final ry = (p.x * sinT) + (p.y * cosT);
        rotated.add(GesturePoint(x: rx, y: ry, timestampMs: p.timestampMs));
      }
      return rotated;
    }

    test('constants and configuration match mathematical specifications', () {
      expect(DollarOneBRecognizer.canonicalReferenceDimension, 250.0);
      expect(DollarOneBRecognizer.phi, closeTo(0.6180339887, 1e-6));
      expect(DollarOneBRecognizer.oneMinusPhi, closeTo(0.3819660112, 1e-6));
      expect(
        DollarOneBRecognizer.canonicalHalfDiagonal,
        closeTo(125.0 * math.sqrt(2.0), 1e-6),
      );
      expect(DollarOneBRecognizer.defaultMaxAngleRad, math.pi / 4.0);
      expect(DollarOneBRecognizer.defaultAngleToleranceRad, math.pi / 360.0);
    });

    group('Boundary & Validation Invariants', () {
      final valid64 = createCanonicalVShape();

      test('throws FormatException if candidate length != 64', () {
        final shortCandidate = List<GesturePoint>.from(valid64.take(63));
        expect(
          () => DollarOneBRecognizer.matchStatic(shortCandidate, valid64),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException if template length != 64', () {
        final shortTemplate = List<GesturePoint>.from(valid64.take(63));
        expect(
          () => DollarOneBRecognizer.matchStatic(valid64, shortTemplate),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException if referenceDimension is non-positive or non-finite', () {
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
      });

      test('throws FormatException if maxAngleRad is non-positive, > pi, or non-finite', () {
        expect(
          () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: 0.0),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: 4.0),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => DollarOneBRecognizer.matchStatic(valid64, valid64, maxAngleRad: double.nan),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException if angleToleranceRad is non-positive or non-finite', () {
        expect(
          () => DollarOneBRecognizer.matchStatic(valid64, valid64, angleToleranceRad: 0.0),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => DollarOneBRecognizer.matchStatic(valid64, valid64, angleToleranceRad: -0.1),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Algorithmic Matching Correctness', () {
      final vShape = createCanonicalVShape();

      test('identical candidate and template yields score of 1.0', () {
        final score = DollarOneBRecognizer.matchStatic(vShape, vShape);
        expect(score, closeTo(1.0, 1e-5));
      });

      test('reverse drawn stroke yields score of 1.0 (bidirectional invariance)', () {
        final reversedV = List<GesturePoint>.unmodifiable(vShape.reversed);
        final score = DollarOneBRecognizer.matchStatic(reversedV, vShape);
        expect(score, closeTo(1.0, 1e-5));
      });

      test('optimal rotation within [-45 deg, +45 deg] recovers tilt', () {
        final rotated15 = rotatePoints(vShape, 15.0 * math.pi / 180.0);
        final score15 = DollarOneBRecognizer.matchStatic(rotated15, vShape);
        expect(score15, greaterThan(0.95));

        final rotatedMinus30 = rotatePoints(vShape, -30.0 * math.pi / 180.0);
        final scoreMinus30 = DollarOneBRecognizer.matchStatic(rotatedMinus30, vShape);
        expect(scoreMinus30, greaterThan(0.95));

        final rotated40 = rotatePoints(vShape, 40.0 * math.pi / 180.0);
        final score40 = DollarOneBRecognizer.matchStatic(rotated40, vShape);
        expect(score40, greaterThan(0.90));
      });

      test('tilt beyond search bracket (90 deg) is rejected below safety floor 0.65', () {
        final rotated90 = rotatePoints(vShape, math.pi / 2.0);
        final score90 = DollarOneBRecognizer.matchStatic(rotated90, vShape);
        expect(score90, lessThan(0.65));
      });

      test('dissimilar shapes (V shape vs horizontal line) produces low score below 0.65', () {
        final hLine = createHorizontalLine();
        final score = DollarOneBRecognizer.matchStatic(hLine, vShape);
        expect(score, lessThan(0.65));
      });

      test('instance method matches static evaluation', () {
        const recognizer = DollarOneBRecognizer();
        final scoreInstance = recognizer.match(vShape, vShape);
        final scoreStatic = DollarOneBRecognizer.matchStatic(vShape, vShape);
        expect(scoreInstance, scoreStatic);
      });
    });

    test('executes cleanly inside Isolate.run', () async {
      final vShape = createCanonicalVShape();
      final score = await Isolate.run(() {
        const recognizer = DollarOneBRecognizer();
        return recognizer.match(vShape, vShape);
      });
      expect(score, closeTo(1.0, 1e-5));
    });
  });
}
