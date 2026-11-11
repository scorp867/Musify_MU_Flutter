import 'dart:async';

import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

/// Pure abstract interface defining the single-stroke stealth gesture recognition pipeline
/// and multi-sample template synthesis engine (Harel Region D: Gesture Engine).
///
/// Encapsulates all heavy geometric and time-series algorithms offloaded to background isolates:
/// de-jittering, kinematic anti-scribble validation, arc-length resampling (N=64),
/// Golden Section Search Bidirectional $1 ($1-B), FastDTW sequence alignment,
/// normalized 7D Rubine feature cosine similarity, and DTW Barycenter Averaging (DBA).
abstract interface class IGestureRecognizer {
  /// Evaluates a live [liveStroke] against the enrolled [template] under the configured
  /// [sensitivityTier].
  ///
  /// Executes the multi-algorithm ensemble pipeline in a background isolate:
  /// 1. Anti-scribble trajectory and kinematic sanity checks.
  /// 2. Equidistant arc-length resampling to N=64 points and centering.
  /// 3. Bidirectional $1 Golden Section Search distance calculation.
  /// 4. FastDTW sequence alignment score.
  /// 5. 7D Rubine feature vector cosine similarity.
  /// 6. Weighted consensus score fusion: S_ensemble = 0.50*S_$1 + 0.35*S_DTW + 0.15*S_feat.
  ///
  /// Returns [VaultResult.success] containing [RecognitionScore] with match decision,
  /// or [VaultResult.failure] on invalid input or calculation failure.
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  });

  /// Synthesizes a golden master [GestureTemplate] from a collection of consistent [samples]
  /// (typically 3 samples) via DTW Barycenter Averaging (DBA) on a background isolate.
  ///
  /// Returns [VaultResult.success] with the synthesized template or [VaultResult.failure]
  /// if samples cannot be converged.
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  });

  /// Validates pairwise consistency across multiple recorded [samples] during the enrollment wizard.
  ///
  /// Rejects inconsistent or divergent strokes early to ensure high-quality template synthesis.
  /// Returns [VaultResult.success] if all pairwise DTW distances satisfy the consistency threshold.
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  });
}
