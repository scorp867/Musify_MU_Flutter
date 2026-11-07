import 'package:flutter/painting.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/services/unistroke_recognizer.dart';

export 'package:musify_mu/features/private_vault/domain/services/i_gesture_recognizer_service.dart';
export 'package:musify_mu/features/private_vault/domain/services/unistroke_recognizer.dart';

/// Legacy adapter ensuring backwards compatibility by delegating to the production [UnistrokeRecognizer].
final class GestureGridRecognizer implements IGestureRecognizerService {
  final UnistrokeRecognizer _engine;

  const GestureGridRecognizer([this._engine = const UnistrokeRecognizer()]);

  @override
  GestureRecognitionStatus evaluate({
    required List<Offset> rawPoints,
    required Size canvasSize,
    required GesturePattern template,
    double threshold = 0.70,
  }) {
    return _engine.evaluate(
      rawPoints: rawPoints,
      canvasSize: canvasSize,
      template: template,
      threshold: threshold,
    );
  }

  @override
  GesturePattern normalizeStroke({
    required List<Offset> rawPoints,
    required Size canvasSize,
  }) {
    return _engine.normalizeStroke(
      rawPoints: rawPoints,
      canvasSize: canvasSize,
    );
  }

  @override
  double calculateSimilarity(GesturePattern patternA, GesturePattern patternB) {
    return _engine.calculateSimilarity(patternA, patternB);
  }
}
