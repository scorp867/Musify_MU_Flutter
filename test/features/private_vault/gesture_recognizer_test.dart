import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/services/unistroke_recognizer.dart';

void main() {
  group('UnistrokeRecognizer Tests', () {
    const recognizer = UnistrokeRecognizer();
    const canvasSize = Size(300, 300);

    test('calculateSimilarity returns 1.0 for identical patterns', () {
      final template = GesturePattern.defaultPattern;
      final similarity = recognizer.calculateSimilarity(template, template);
      expect(similarity, closeTo(1.0, 0.001));
    });

    test('normalizeStroke produces exactly 64 normalized points', () {
      final rawPoints = [
        for (double y = 10; y <= 200; y += 10) Offset(50, y),
      ];

      final pattern = recognizer.normalizeStroke(
        rawPoints: rawPoints,
        canvasSize: canvasSize,
      );

      expect(pattern.points.length, 64);
    });

    test('recognizer matches "P" stroke against default template with high accuracy', () {
      final rawP = <Offset>[
        const Offset(20, 20),
        const Offset(20, 50),
        const Offset(20, 100),
        const Offset(20, 150),
        const Offset(20, 180),
        const Offset(20, 100),
        const Offset(20, 20),
        const Offset(50, 20),
        const Offset(80, 40),
        const Offset(90, 60),
        const Offset(80, 80),
        const Offset(50, 100),
        const Offset(20, 100),
      ];

      final status = recognizer.evaluate(
        rawPoints: rawP,
        canvasSize: canvasSize,
        template: GesturePattern.defaultPattern,
      );

      expect(status, GestureRecognitionStatus.matched);
    });

    test('recognizer is scale-invariant (small P matches default template)', () {
      final smallP = <Offset>[
        const Offset(200, 200),
        const Offset(200, 210),
        const Offset(200, 220),
        const Offset(200, 230),
        const Offset(200, 240),
        const Offset(200, 220),
        const Offset(200, 200),
        const Offset(210, 200),
        const Offset(220, 205),
        const Offset(225, 210),
        const Offset(220, 215),
        const Offset(210, 220),
        const Offset(200, 220),
      ];

      final status = recognizer.evaluate(
        rawPoints: smallP,
        canvasSize: canvasSize,
        template: GesturePattern.defaultPattern,
      );

      expect(status, GestureRecognitionStatus.matched);
    });

    test('recognizer supports bidirectional drawing (reverse drawn P matches)', () {
      final reverseP = <Offset>[
        const Offset(20, 100),
        const Offset(50, 100),
        const Offset(80, 80),
        const Offset(90, 60),
        const Offset(80, 40),
        const Offset(50, 20),
        const Offset(20, 20),
        const Offset(20, 100),
        const Offset(20, 180),
        const Offset(20, 150),
        const Offset(20, 100),
        const Offset(20, 50),
        const Offset(20, 20),
      ];

      final status = recognizer.evaluate(
        rawPoints: reverseP,
        canvasSize: canvasSize,
        template: GesturePattern.defaultPattern,
      );

      expect(status, GestureRecognitionStatus.matched);
    });

    test('recognizer rejects dissimilar scribbles and shapes', () {
      final scribble = <Offset>[
        const Offset(10, 10),
        const Offset(90, 20),
        const Offset(20, 60),
        const Offset(80, 80),
        const Offset(10, 120),
      ];

      final status = recognizer.evaluate(
        rawPoints: scribble,
        canvasSize: canvasSize,
        template: GesturePattern.defaultPattern,
      );

      expect(status, GestureRecognitionStatus.mismatched);
    });
  });
}
