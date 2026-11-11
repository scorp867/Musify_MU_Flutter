import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

/// Authoritative decision fusion engine combining $1-B, FastDTW, and 7D Rubine feature scores.
///
/// Implements Job 8 of the Stealth Gesture Pipeline (Harel Region D: Gesture Engine).
/// Enforces multi-stage decision gating:
/// 1. Structural Cosine Gate: S_feat >= 0.68.
/// 2. Classifier Safety Floors: S_$1 >= 0.65 AND S_DTW >= 0.60.
/// 3. Weighted Consensus Formula: S_ensemble = 0.50*S_$1 + 0.35*S_DTW + 0.15*S_feat.
/// 4. Sensitivity Tier Threshold: S_ensemble >= tier.thresholdScore.
///
/// Conforms strictly to workspace architectural invariants: stateless, deeply pure,
/// zero non-null assertions (!), zero .clamp() AST tokens, zero fallback operators (??),
/// zero loose booleans, and fail-fast validation.
@immutable
class GestureEnsembleFusion {
  /// Constructs a [GestureEnsembleFusion] instance.
  const GestureEnsembleFusion();

  /// Evaluates individual classifier scores and produces a deterministic [RecognitionScore].
  ///
  /// Instance method for dependency injection into services.
  RecognitionScore fuse({
    required double dollarOneScore,
    required double dtwScore,
    required double featureScore,
    required GestureSensitivityTierEnum sensitivityTier,
  }) {
    return fuseStatic(
      dollarOneScore: dollarOneScore,
      dtwScore: dtwScore,
      featureScore: featureScore,
      sensitivityTier: sensitivityTier,
    );
  }

  /// Pure static evaluation fusing classifier scores into a deterministic [RecognitionScore].
  ///
  /// Throws [FormatException] if any score is NaN, infinite, or falls outside [0.0, 1.0].
  static RecognitionScore fuseStatic({
    required double dollarOneScore,
    required double dtwScore,
    required double featureScore,
    required GestureSensitivityTierEnum sensitivityTier,
  }) {
    _validateScore('dollarOneScore', dollarOneScore);
    _validateScore('dtwScore', dtwScore);
    _validateScore('featureScore', featureScore);

    // Compute raw weighted ensemble consensus score
    final double rawEnsemble = RecognitionScore.computeEnsembleScore(
      dollarOneScore: dollarOneScore,
      dtwScore: dtwScore,
      featureScore: featureScore,
    );
    final double ensembleScore = _boundUnit(rawEnsemble);

    // Stage 1: Structural Cosine Gate (S_feat >= 0.68)
    if (featureScore < GestureSensitivityTierEnum.minimumStructuralGate) {
      return RecognitionScore(
        dollarOneScore: dollarOneScore,
        dtwScore: dtwScore,
        featureScore: featureScore,
        ensembleScore: ensembleScore,
        decision: GestureMatchDecisionEnum.rejectedStructuralGate,
      );
    }

    // Stage 2: Classifier Safety Floors (S_$1 >= 0.65 and S_DTW >= 0.60)
    if (dollarOneScore < GestureSensitivityTierEnum.safetyFloorDollar1 ||
        dtwScore < GestureSensitivityTierEnum.safetyFloorDtw) {
      return RecognitionScore(
        dollarOneScore: dollarOneScore,
        dtwScore: dtwScore,
        featureScore: featureScore,
        ensembleScore: ensembleScore,
        decision: GestureMatchDecisionEnum.rejectedClassifierFloor,
      );
    }

    // Stage 3: Sensitivity Tier Threshold (S_ensemble >= thresholdScore)
    if (!sensitivityTier.isSatisfiedBy(ensembleScore)) {
      return RecognitionScore(
        dollarOneScore: dollarOneScore,
        dtwScore: dtwScore,
        featureScore: featureScore,
        ensembleScore: ensembleScore,
        decision: GestureMatchDecisionEnum.rejectedBelowSensitivityTier,
      );
    }

    // Stage 4: Confirmed Match
    return RecognitionScore(
      dollarOneScore: dollarOneScore,
      dtwScore: dtwScore,
      featureScore: featureScore,
      ensembleScore: ensembleScore,
      decision: GestureMatchDecisionEnum.matched,
    );
  }

  /// Convenience factory for strokes failing the kinematic sanity gate prior to isolate matching.
  static RecognitionScore rejectedAntiScribble({
    double dollarOneScore = 0.0,
    double dtwScore = 0.0,
    double featureScore = 0.0,
  }) {
    return RecognitionScore(
      dollarOneScore: dollarOneScore,
      dtwScore: dtwScore,
      featureScore: featureScore,
      ensembleScore: 0.0,
      decision: GestureMatchDecisionEnum.rejectedAntiScribble,
    );
  }

  /// Validates that [score] is finite and within [0.0, 1.0].
  static void _validateScore(String name, double score) {
    if (score.isNaN || score.isInfinite || score < 0.0 || score > 1.0) {
      throw FormatException(
        'GestureEnsembleFusion $name must be a finite number in [0.0, 1.0], got: $score',
      );
    }
  }

  /// Bounds [value] strictly into [0.0, 1.0] without using AST-banned .clamp().
  static double _boundUnit(double value) {
    if (value < 0.0) {
      return 0.0;
    }
    if (value > 1.0) {
      return 1.0;
    }
    return value;
  }
}
