import 'dart:isolate';

import 'package:musify_mu/features/vault/data/gesture/dba_synthesizer.dart';
import 'package:musify_mu/features/vault/data/gesture/dollar_one_b_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_ensemble_fusion.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_isolate_payloads.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_normalizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_resampler.dart';
import 'package:musify_mu/features/vault/data/gesture/kinematic_sanity_gate.dart';
import 'package:musify_mu/features/vault/data/gesture/raw_touch_filter.dart';
import 'package:musify_mu/features/vault/data/gesture/rubine_feature_extractor.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

/// Top-level pure functional pipeline entry point executed inside [Isolate.run].
///
/// Encapsulates all 6 processing jobs in strict deterministic sequence:
/// RawTouchFilter -> KinematicSanityGate -> GestureResampler ->
/// GestureNormalizer -> [$1-B + FastDTW + Rubine] -> GestureEnsembleFusion.
@pragma('vm:entry-point')
RecognitionScore runGestureRecognitionPipeline(
  GestureRecognitionIsolatePayload payload, {
  RawTouchFilter filter = const RawTouchFilter(),
  KinematicSanityGate gate = KinematicSanityGate.standard,
  DollarOneBRecognizer dollarOneRecognizer = const DollarOneBRecognizer(),
  FastDtwRecognizer dtwRecognizer = const FastDtwRecognizer(),
  RubineFeatureExtractor rubineExtractor = const RubineFeatureExtractor(),
  GestureEnsembleFusion ensembleFusion = const GestureEnsembleFusion(),
}) {
  // 1. Raw Touch Pre-Filtering (Deadband + Gaussian)
  final List<GesturePoint> filteredPoints = filter.filterRawPoints(
    payload.rawPoints,
    deadbandThreshold: payload.deadbandThreshold,
  );

  // 2. Kinematic Sanity & Anti-Scribble Gate (< 0.1ms fail-fast)
  final KinematicGateDecision gateDecision = gate.evaluate(filteredPoints);
  switch (gateDecision) {
    case KinematicGateRejected():
      return GestureEnsembleFusion.rejectedAntiScribble();
    case KinematicGatePassed():
      break;
  }

  // 3. Equidistant Arc-Length Resampling to N = 64
  final List<GesturePoint> resampledPoints = GestureResampler.resample(
    filteredPoints,
    targetCount: GestureTemplate.requiredPointCount,
  );

  // 4. Centroid Centering & Aspect-Preserving Scaling to B = 250.0px
  final List<GesturePoint> normalizedPoints =
      GestureNormalizer.normalizeCoordinates(
    resampledPoints,
    referenceDimension: payload.referenceDimension,
  );

  // 5. Multi-Algorithm Matching Engines
  // 5.1 Rubine 7D Feature Cosine Similarity (Bidirectional)
  final double featureScore = rubineExtractor.matchBidirectional(
    normalizedPoints,
    payload.templateRubineVector,
  );

  // 5.2 Bidirectional $1-B Recognizer with Golden Section Search
  final double dollarOneScore = dollarOneRecognizer.match(
    normalizedPoints,
    payload.templateNormalizedPoints,
    referenceDimension: payload.referenceDimension,
  );

  // 5.3 Bidirectional FastDTW Sequence Alignment
  final double dtwScore = dtwRecognizer.match(
    normalizedPoints,
    payload.templateNormalizedPoints,
  );

  // 6. Multi-Stage Decision Fusion
  return ensembleFusion.fuse(
    dollarOneScore: dollarOneScore,
    dtwScore: dtwScore,
    featureScore: featureScore,
    sensitivityTier: payload.sensitivityTier,
  );
}

/// Top-level isolate pipeline entry point for pairwise DTW consistency checking.
@pragma('vm:entry-point')
void runGestureConsistencyPipeline(
  GestureConsistencyIsolatePayload payload, {
  DbaSynthesizer dbaSynthesizer = const DbaSynthesizer(),
}) {
  final bool isConsistent = dbaSynthesizer.checkConsistency(
    samples: payload.samples,
    minDtwScore: payload.consistencyThreshold,
    windowRadius: payload.windowRadius,
    sigmaDtw: payload.sigmaDtw,
    referenceDimension: payload.referenceDimension,
  );

  if (!isConsistent) {
    throw const FormatException(
      'Recorded samples exhibit divergent trajectory geometry failing pairwise DTW consistency threshold.',
    );
  }
}

/// Top-level isolate pipeline entry point for DTW Barycenter Averaging template synthesis.
@pragma('vm:entry-point')
GestureTemplate runGestureSynthesisPipeline(
  GestureSynthesisIsolatePayload payload, {
  DbaSynthesizer dbaSynthesizer = const DbaSynthesizer(),
}) {
  return dbaSynthesizer.synthesize(
    samples: payload.samples,
    id: payload.templateId,
    createdAtEpochMs: payload.createdAtEpochMs,
    maxIterations: payload.maxIterations,
    convergenceTolerance: payload.convergenceTolerance,
    windowRadius: payload.windowRadius,
    minDtwScore: payload.consistencyThreshold,
    sigmaDtw: payload.sigmaDtw,
    referenceDimension: payload.referenceDimension,
  );
}

/// Production implementation of [IGestureRecognizer] executing the stealth
/// single-stroke recognition pipeline inside background isolates via [Isolate.run].
///
/// Features:
/// 1. Zero UI Thread Contention: All heavy geometry, dynamic programming, and DBA offloaded.
/// 2. Atomic Monotonic Epoch Counter: Cancels or supersedes in-flight evaluations
///    cleanly when a subsequent pointer down arrives, eliminating loose boolean locks.
/// 3. Strict Domain Result Wrapping: Emits [VaultResult<RecognitionScore>] and
///    [VaultResult<GestureTemplate>] with exhaustive failure mapping and zero data leakage.
class GestureRecognizerService implements IGestureRecognizer {
  /// Pre-filtering touch filter.
  final RawTouchFilter filter;

  /// Kinematic sanity and anti-scribble gate.
  final KinematicSanityGate kinematicGate;

  /// Bidirectional $1-B recognizer.
  final DollarOneBRecognizer dollarOneRecognizer;

  /// Bidirectional FastDTW recognizer.
  final FastDtwRecognizer dtwRecognizer;

  /// 7D Rubine geometric feature extractor.
  final RubineFeatureExtractor rubineExtractor;

  /// Multi-stage ensemble decision fusion engine.
  final GestureEnsembleFusion ensembleFusion;

  /// DTW Barycenter Averaging synthesizer.
  final DbaSynthesizer dbaSynthesizer;

  /// Monotonic evaluation epoch counter for atomic superseding of in-flight evaluations.
  int _currentEpoch = 0;

  /// Constructs a [GestureRecognizerService] instance with injectable dependencies.
  GestureRecognizerService({
    this.filter = const RawTouchFilter(),
    this.kinematicGate = KinematicSanityGate.standard,
    this.dollarOneRecognizer = const DollarOneBRecognizer(),
    this.dtwRecognizer = const FastDtwRecognizer(),
    this.rubineExtractor = const RubineFeatureExtractor(),
    this.ensembleFusion = const GestureEnsembleFusion(),
    this.dbaSynthesizer = const DbaSynthesizer(),
  });

  /// Current monotonic evaluation epoch for testing and diagnostics.
  int get currentEpoch => _currentEpoch;

  /// Cancels or supersedes any currently active background isolate evaluation.
  ///
  /// Called immediately on pointer down by StealthGesturePad to reclaim the arena
  /// and render in-flight isolate results dead-on-arrival.
  void cancelActiveEvaluation() {
    _currentEpoch++;
  }

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    final int callEpoch = ++_currentEpoch;

    // Fail-fast input validation
    if (liveStroke.points.isEmpty) {
      return const VaultResult.failure(
        VaultValidationFailure('liveStroke points must not be empty.'),
      );
    }
    if (template.normalizedPoints.length != GestureTemplate.requiredPointCount) {
      return VaultResult.failure(
        VaultValidationFailure(
          'template points length must be ${GestureTemplate.requiredPointCount}, got: ${template.normalizedPoints.length}',
        ),
      );
    }
    if (template.rubineFeatureVector.length !=
        GestureTemplate.requiredFeatureVectorDimensions) {
      return VaultResult.failure(
        VaultValidationFailure(
          'template feature vector length must be ${GestureTemplate.requiredFeatureVectorDimensions}, got: ${template.rubineFeatureVector.length}',
        ),
      );
    }

    try {
      final payload = GestureRecognitionIsolatePayload.fromDomain(
        liveStroke: liveStroke,
        template: template,
        sensitivityTier: sensitivityTier,
      );

      final score = await Isolate.run(
        () => runGestureRecognitionPipeline(
          payload,
          filter: filter,
          gate: kinematicGate,
          dollarOneRecognizer: dollarOneRecognizer,
          dtwRecognizer: dtwRecognizer,
          rubineExtractor: rubineExtractor,
          ensembleFusion: ensembleFusion,
        ),
      );

      // Concurrency Gate: Check if this evaluation was superseded while isolate was running
      if (callEpoch != _currentEpoch) {
        return const VaultResult.failure(
          VaultGestureFailure(
            'Gesture evaluation was superseded by subsequent touch event.',
          ),
        );
      }

      return VaultResult.success(score);
    } on FormatException catch (e) {
      return VaultResult.failure(
        VaultValidationFailure(
          'Invalid gesture data format: ${e.message}',
          cause: e,
        ),
      );
    } catch (e) {
      return VaultResult.failure(
        VaultGestureFailure(
          'Gesture recognition pipeline failed: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
    String? templateId,
    double consistencyThreshold = 0.70,
    int maxIterations = 5,
  }) async {
    if (samples.length < 2) {
      return const VaultResult.failure(
        VaultValidationFailure(
          'At least 2 gesture samples are required for template synthesis.',
        ),
      );
    }
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].points.isEmpty) {
        return VaultResult.failure(
          VaultValidationFailure(
            'Gesture sample at index $i contains no touch points.',
          ),
        );
      }
    }

    final String effectiveId;
    if (templateId case final String id when id.trim().isNotEmpty) {
      effectiveId = id.trim();
    } else {
      effectiveId =
          'master_gesture_template_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final payload = GestureSynthesisIsolatePayload.fromDomain(
        samples: samples,
        templateId: effectiveId,
        consistencyThreshold: consistencyThreshold,
        maxIterations: maxIterations,
      );

      final GestureTemplate template = await Isolate.run(
        () => runGestureSynthesisPipeline(
          payload,
          dbaSynthesizer: dbaSynthesizer,
        ),
      );

      return VaultResult.success(template);
    } on FormatException catch (e) {
      if (e.message.contains('requires at least') ||
          e.message.contains('must not be empty') ||
          e.message.contains('must be positive')) {
        return VaultResult.failure(
          VaultValidationFailure(e.message, cause: e),
        );
      }
      return VaultResult.failure(
        VaultGestureFailure(e.message, cause: e),
      );
    } catch (e) {
      return VaultResult.failure(
        VaultGestureFailure('Master template synthesis failed: $e', cause: e),
      );
    }
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
    double consistencyThreshold = 0.70,
  }) async {
    if (samples.length < 2) {
      return const VaultResult.failure(
        VaultValidationFailure(
          'At least 2 gesture samples are required for consistency validation.',
        ),
      );
    }
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].points.isEmpty) {
        return VaultResult.failure(
          VaultValidationFailure(
            'Gesture sample at index $i contains no touch points.',
          ),
        );
      }
    }

    try {
      final payload = GestureConsistencyIsolatePayload.fromDomain(
        samples: samples,
        consistencyThreshold: consistencyThreshold,
      );

      await Isolate.run(
        () => runGestureConsistencyPipeline(
          payload,
          dbaSynthesizer: dbaSynthesizer,
        ),
      );

      return const VaultResult.success(null);
    } on FormatException catch (e) {
      if (e.message.contains('requires at least') ||
          e.message.contains('must not contain empty')) {
        return VaultResult.failure(
          VaultValidationFailure(e.message, cause: e),
        );
      }
      return VaultResult.failure(
        VaultGestureFailure(e.message, cause: e),
      );
    } catch (e) {
      return VaultResult.failure(
        VaultGestureFailure('Sample consistency check failed: $e', cause: e),
      );
    }
  }
}
