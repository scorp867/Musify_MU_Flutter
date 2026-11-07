import 'package:flutter/painting.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';

/// Exhaustive operational status of gesture recognition evaluation.
enum GestureRecognitionStatus {
  idle,
  capturing,
  matched,
  mismatched,
}

/// Pure domain abstraction for gesture sensor quantization and unistroke pattern matching.
abstract interface class IGestureRecognizerService {
  /// Evaluates a raw drawn trajectory against a reference [template].
  GestureRecognitionStatus evaluate({
    required List<Offset> rawPoints,
    required Size canvasSize,
    required GesturePattern template,
    double threshold = 0.70,
  });

  /// Normalizes a continuous list of raw touch points into a 64-point scale-invariant [GesturePattern].
  GesturePattern normalizeStroke({
    required List<Offset> rawPoints,
    required Size canvasSize,
  });

  /// Computes bidirectional geometric similarity between two patterns in the range [0.0, 1.0].
  double calculateSimilarity(GesturePattern patternA, GesturePattern patternB);
}
