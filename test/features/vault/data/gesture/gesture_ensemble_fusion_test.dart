import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_ensemble_fusion.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

void main() {
  group('GestureEnsembleFusion', () {
    const tierStrict = GestureSensitivityTierEnum.strict92Percent; // 0.88
    const tierBalanced = GestureSensitivityTierEnum.balanced84Percent; // 0.78
    const tierRelaxed = GestureSensitivityTierEnum.relaxed76Percent; // 0.68

    group('Validation Invariants', () {
      test('throws FormatException if any score is NaN, infinite, or out of [0.0, 1.0]', () {
        expect(
          () => GestureEnsembleFusion.fuseStatic(
            dollarOneScore: -0.1,
            dtwScore: 0.8,
            featureScore: 0.8,
            sensitivityTier: tierBalanced,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureEnsembleFusion.fuseStatic(
            dollarOneScore: 0.8,
            dtwScore: 1.1,
            featureScore: 0.8,
            sensitivityTier: tierBalanced,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureEnsembleFusion.fuseStatic(
            dollarOneScore: 0.8,
            dtwScore: 0.8,
            featureScore: double.nan,
            sensitivityTier: tierBalanced,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => GestureEnsembleFusion.fuseStatic(
            dollarOneScore: double.infinity,
            dtwScore: 0.8,
            featureScore: 0.8,
            sensitivityTier: tierBalanced,
          ),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Stage 1: Structural Cosine Gate (S_feat >= 0.68)', () {
      test('rejects with rejectedStructuralGate if featureScore < 0.68 even when other scores are high', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.95,
          dtwScore: 0.95,
          featureScore: 0.679,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedStructuralGate);
        expect(score.dollarOneScore, 0.95);
        expect(score.dtwScore, 0.95);
        expect(score.featureScore, 0.679);
      });

      test('passes structural gate when featureScore == 0.68 boundary', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.70,
          dtwScore: 0.70,
          featureScore: 0.68,
          sensitivityTier: tierRelaxed,
        );

        // 0.50*0.70 + 0.35*0.70 + 0.15*0.68 = 0.35 + 0.245 + 0.102 = 0.697 >= 0.68
        expect(score.decision, GestureMatchDecisionEnum.matched);
      });
    });

    group('Stage 2: Classifier Safety Floors (\$1 >= 0.65, DTW >= 0.60)', () {
      test('rejects with rejectedClassifierFloor if dollarOneScore < 0.65', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.649,
          dtwScore: 0.85,
          featureScore: 0.85,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedClassifierFloor);
      });

      test('rejects with rejectedClassifierFloor if dtwScore < 0.60', () {
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.85,
          dtwScore: 0.599,
          featureScore: 0.85,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedClassifierFloor);
      });

      test('passes safety floors when scores are at exact floor boundaries (0.65, 0.60)', () {
        // S_$1 = 0.65, S_DTW = 0.60, S_feat = 0.90
        // Ensemble = 0.50*0.65 + 0.35*0.60 + 0.15*0.90 = 0.325 + 0.210 + 0.135 = 0.67
        // Falls below relaxed threshold 0.68, but passes floor!
        final score = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.65,
          dtwScore: 0.60,
          featureScore: 0.90,
          sensitivityTier: tierRelaxed,
        );

        expect(score.decision, GestureMatchDecisionEnum.rejectedBelowSensitivityTier);
      });
    });

    group('Stage 3 & 4: Sensitivity Tiers & Confirmed Match', () {
      test('strict tier (threshold 0.88) rejects below and accepts at/above threshold', () {
        // 0.50*0.87 + 0.35*0.87 + 0.15*0.87 = 0.87 < 0.88
        final scoreBelow = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.87,
          dtwScore: 0.87,
          featureScore: 0.87,
          sensitivityTier: tierStrict,
        );
        expect(scoreBelow.decision, GestureMatchDecisionEnum.rejectedBelowSensitivityTier);

        // 0.50*0.89 + 0.35*0.89 + 0.15*0.89 = 0.89 >= 0.88
        final scoreAbove = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.89,
          dtwScore: 0.89,
          featureScore: 0.89,
          sensitivityTier: tierStrict,
        );
        expect(scoreAbove.decision, GestureMatchDecisionEnum.matched);
      });

      test('balanced tier (threshold 0.78) rejects below and accepts at/above threshold', () {
        // 0.50*0.77 + 0.35*0.77 + 0.15*0.77 = 0.77 < 0.78
        final scoreBelow = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.77,
          dtwScore: 0.77,
          featureScore: 0.77,
          sensitivityTier: tierBalanced,
        );
        expect(scoreBelow.decision, GestureMatchDecisionEnum.rejectedBelowSensitivityTier);

        // 0.50*0.80 + 0.35*0.78 + 0.15*0.75 = 0.40 + 0.273 + 0.1125 = 0.7855 >= 0.78
        final scoreAbove = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.80,
          dtwScore: 0.78,
          featureScore: 0.75,
          sensitivityTier: tierBalanced,
        );
        expect(scoreAbove.decision, GestureMatchDecisionEnum.matched);
      });

      test('relaxed tier (threshold 0.68) rejects below and accepts at/above threshold', () {
        // 0.50*0.66 + 0.35*0.66 + 0.15*0.70 = 0.33 + 0.231 + 0.105 = 0.666 < 0.68
        final scoreBelow = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.66,
          dtwScore: 0.66,
          featureScore: 0.70,
          sensitivityTier: tierRelaxed,
        );
        expect(scoreBelow.decision, GestureMatchDecisionEnum.rejectedBelowSensitivityTier);

        // 0.50*0.70 + 0.35*0.70 + 0.15*0.70 = 0.70 >= 0.68
        final scoreAbove = GestureEnsembleFusion.fuseStatic(
          dollarOneScore: 0.70,
          dtwScore: 0.70,
          featureScore: 0.70,
          sensitivityTier: tierRelaxed,
        );
        expect(scoreAbove.decision, GestureMatchDecisionEnum.matched);
      });
    });

    test('rejectedAntiScribble helper returns expected zeroed score and decision', () {
      final score = GestureEnsembleFusion.rejectedAntiScribble();
      expect(score.dollarOneScore, 0.0);
      expect(score.dtwScore, 0.0);
      expect(score.featureScore, 0.0);
      expect(score.ensembleScore, 0.0);
      expect(score.decision, GestureMatchDecisionEnum.rejectedAntiScribble);
    });

    test('instance method matches static evaluation', () {
      const fusion = GestureEnsembleFusion();
      final scoreInst = fusion.fuse(
        dollarOneScore: 0.85,
        dtwScore: 0.80,
        featureScore: 0.75,
        sensitivityTier: tierBalanced,
      );
      final scoreStat = GestureEnsembleFusion.fuseStatic(
        dollarOneScore: 0.85,
        dtwScore: 0.80,
        featureScore: 0.75,
        sensitivityTier: tierBalanced,
      );
      expect(scoreInst, scoreStat);
    });
  });
}
