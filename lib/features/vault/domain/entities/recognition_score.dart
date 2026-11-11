import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Explicit decision outcome produced by the multi-stage stealth gesture recognition pipeline.
///
/// Strictly enforces the Zero Loose Booleans mandate: contains zero `bool isMatch` flags.
/// Decisions are categorized deterministically by failure stage or confirmed match.
enum GestureMatchDecisionEnum {
  /// Ensemble consensus score meets or exceeds the active sensitivity tier threshold.
  matched(id: 'MATCHED', displayName: 'Matched'),

  /// Rejected during kinematic sanity gate (insufficient bounding box span, tortuosity, or angular deviation).
  rejectedAntiScribble(id: 'REJECTED_ANTI_SCRIBBLE', displayName: 'Rejected: Anti-Scribble Gate'),

  /// Rejected by structural feature gate (cosine similarity < 0.68).
  rejectedStructuralGate(id: 'REJECTED_STRUCTURAL_GATE', displayName: 'Rejected: Structural Gate'),

  /// Rejected because individual classifier score fell below safe operational floors ($1-B < 0.65 or DTW < 0.60).
  rejectedClassifierFloor(id: 'REJECTED_CLASSIFIER_FLOOR', displayName: 'Rejected: Classifier Floor'),

  /// Structural gates and floors passed, but weighted ensemble score fell below the active sensitivity tier threshold.
  rejectedBelowSensitivityTier(id: 'REJECTED_BELOW_SENSITIVITY_TIER', displayName: 'Rejected: Below Sensitivity Tier');

  /// Canonical serialization identifier.
  final String id;

  /// Human-readable display label.
  final String displayName;

  const GestureMatchDecisionEnum({
    required this.id,
    required this.displayName,
  });

  /// Serializes the decision to its identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into a [GestureMatchDecisionEnum] instance.
  ///
  /// Throws [FormatException] if [id] does not match any valid enum variant.
  static GestureMatchDecisionEnum fromId(String id) {
    for (final decision in GestureMatchDecisionEnum.values) {
      if (decision.id == id || decision.name == id) {
        return decision;
      }
    }
    throw FormatException(
      'Invalid GestureMatchDecisionEnum identifier: "$id". '
      'Valid options are: ${GestureMatchDecisionEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static GestureMatchDecisionEnum fromJson(String json) => fromId(json);
}

/// Deeply immutable value object encapsulating individual classifier scores, weighted ensemble score,
/// and the final deterministic decision outcome.
///
/// All score values are bounded strictly within the closed interval [0.0, 1.0].
/// Strictly enforces zero boolean `isMatch`.
@immutable
class RecognitionScore extends Equatable {
  /// Normalized Bidirectional $1 Golden Section Search similarity score in [0.0, 1.0].
  final double dollarOneScore;

  /// Normalized Fast Dynamic Time Warping similarity score in [0.0, 1.0].
  final double dtwScore;

  /// Bidirectional cosine similarity of the 7-dimensional Rubine geometric feature vector in [0.0, 1.0].
  final double featureScore;

  /// Weighted ensemble consensus score: 0.50 * $1 + 0.35 * DTW + 0.15 * Rubine.
  final double ensembleScore;

  /// Final classification decision.
  final GestureMatchDecisionEnum decision;

  /// Constructs a validated [RecognitionScore] instance.
  ///
  /// Throws [FormatException] if any score is NaN, infinite, or falls outside [0.0, 1.0].
  RecognitionScore({
    required this.dollarOneScore,
    required this.dtwScore,
    required this.featureScore,
    required this.ensembleScore,
    required this.decision,
  }) {
    if (dollarOneScore.isNaN || dollarOneScore < 0.0 || dollarOneScore > 1.0) {
      throw FormatException(
        'RecognitionScore dollarOneScore must be in range [0.0, 1.0], got: $dollarOneScore',
      );
    }
    if (dtwScore.isNaN || dtwScore < 0.0 || dtwScore > 1.0) {
      throw FormatException(
        'RecognitionScore dtwScore must be in range [0.0, 1.0], got: $dtwScore',
      );
    }
    if (featureScore.isNaN || featureScore < 0.0 || featureScore > 1.0) {
      throw FormatException(
        'RecognitionScore featureScore must be in range [0.0, 1.0], got: $featureScore',
      );
    }
    if (ensembleScore.isNaN || ensembleScore < 0.0 || ensembleScore > 1.0) {
      throw FormatException(
        'RecognitionScore ensembleScore must be in range [0.0, 1.0], got: $ensembleScore',
      );
    }
  }

  /// Calculates the weighted ensemble score per the multi-algorithm fusion specification:
  /// S_ensemble = 0.50 * S_$1 + 0.35 * S_DTW + 0.15 * S_feat.
  static double computeEnsembleScore({
    required double dollarOneScore,
    required double dtwScore,
    required double featureScore,
  }) {
    return (0.50 * dollarOneScore) + (0.35 * dtwScore) + (0.15 * featureScore);
  }

  @override
  List<Object?> get props => [
        dollarOneScore,
        dtwScore,
        featureScore,
        ensembleScore,
        decision,
      ];
}
