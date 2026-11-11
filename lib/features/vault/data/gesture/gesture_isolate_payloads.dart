import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_normalizer.dart';
import 'package:musify_mu/features/vault/data/gesture/raw_touch_filter.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

/// Deeply immutable data transfer object sent across the isolate boundary
/// to execute single-stroke gesture recognition.
///
/// Follows Layer 3 Invariants (STRICT_DTO_BOUNDARY): strictly validates external
/// collections and primitives at the boundary, ensuring zero corrupted state can enter
/// the background isolate pipeline.
@immutable
class GestureRecognitionIsolatePayload extends Equatable {
  /// Raw touch points captured during the single stroke.
  final List<GesturePoint> rawPoints;

  /// Normalized 64 equidistant points of the reference golden template.
  final List<GesturePoint> templateNormalizedPoints;

  /// 7-dimensional normalized Rubine geometric feature vector of the reference template.
  final List<double> templateRubineVector;

  /// Active gesture sensitivity tier determining the match threshold.
  final GestureSensitivityTierEnum sensitivityTier;

  /// Spatial deadband Euclidean threshold in logical pixels (default: 2.5px).
  final double deadbandThreshold;

  /// Canonical reference dimension in logical pixels (default: 250.0px).
  final double referenceDimension;

  /// Constructs a validated [GestureRecognitionIsolatePayload].
  ///
  /// Throws [FormatException] if constraints are violated.
  GestureRecognitionIsolatePayload({
    required List<GesturePoint> rawPoints,
    required List<GesturePoint> templateNormalizedPoints,
    required List<double> templateRubineVector,
    required this.sensitivityTier,
    this.deadbandThreshold = RawTouchFilter.defaultDeadbandThreshold,
    this.referenceDimension = GestureNormalizer.canonicalReferenceDimension,
  })  : rawPoints = List<GesturePoint>.unmodifiable(rawPoints),
        templateNormalizedPoints =
            List<GesturePoint>.unmodifiable(templateNormalizedPoints),
        templateRubineVector = List<double>.unmodifiable(templateRubineVector) {
    if (rawPoints.isEmpty) {
      throw const FormatException('rawPoints must not be empty.');
    }
    if (templateNormalizedPoints.length != GestureTemplate.requiredPointCount) {
      throw FormatException(
        'templateNormalizedPoints must contain exactly '
        '${GestureTemplate.requiredPointCount} points, got: ${templateNormalizedPoints.length}',
      );
    }
    if (templateRubineVector.length !=
        GestureTemplate.requiredFeatureVectorDimensions) {
      throw FormatException(
        'templateRubineVector must contain exactly '
        '${GestureTemplate.requiredFeatureVectorDimensions} elements, got: ${templateRubineVector.length}',
      );
    }
    if (deadbandThreshold <= 0.0 ||
        deadbandThreshold.isNaN ||
        deadbandThreshold.isInfinite) {
      throw FormatException(
        'deadbandThreshold must be a positive finite number, got: $deadbandThreshold',
      );
    }
    if (referenceDimension <= 0.0 ||
        referenceDimension.isNaN ||
        referenceDimension.isInfinite) {
      throw FormatException(
        'referenceDimension must be a positive finite number, got: $referenceDimension',
      );
    }
  }

  /// Convenience factory constructing the payload directly from domain entities.
  factory GestureRecognitionIsolatePayload.fromDomain({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
    double deadbandThreshold = RawTouchFilter.defaultDeadbandThreshold,
    double referenceDimension = GestureNormalizer.canonicalReferenceDimension,
  }) {
    return GestureRecognitionIsolatePayload(
      rawPoints: liveStroke.points,
      templateNormalizedPoints: template.normalizedPoints,
      templateRubineVector: template.rubineFeatureVector,
      sensitivityTier: sensitivityTier,
      deadbandThreshold: deadbandThreshold,
      referenceDimension: referenceDimension,
    );
  }

  @override
  List<Object?> get props => [
        rawPoints,
        templateNormalizedPoints,
        templateRubineVector,
        sensitivityTier,
        deadbandThreshold,
        referenceDimension,
      ];
}

/// Deeply immutable data transfer object sent across the isolate boundary
/// to execute pairwise DTW consistency checking across recorded enrollment samples.
@immutable
class GestureConsistencyIsolatePayload extends Equatable {
  /// Unmodifiable list of recorded gesture stroke samples (minimum 2).
  final List<GestureSample> samples;

  /// Canonical reference dimension in logical pixels (default: 250.0px).
  final double referenceDimension;

  /// Pairwise DTW consistency similarity threshold (default: 0.70).
  final double consistencyThreshold;

  /// Sakoe-Chiba constraint window radius (default: 10).
  final int windowRadius;

  /// Exponential decay scaling parameter for DTW distance (default: 35.0).
  final double sigmaDtw;

  GestureConsistencyIsolatePayload({
    required List<GestureSample> samples,
    this.referenceDimension = GestureNormalizer.canonicalReferenceDimension,
    this.consistencyThreshold = 0.70,
    this.windowRadius = FastDtwRecognizer.defaultWindowRadius,
    this.sigmaDtw = FastDtwRecognizer.defaultSigmaDtw,
  }) : samples = List<GestureSample>.unmodifiable(samples) {
    if (samples.length < 2) {
      throw FormatException(
        'GestureConsistencyIsolatePayload requires at least 2 samples, got: ${samples.length}',
      );
    }
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].points.isEmpty) {
        throw FormatException('Sample at index $i must not contain empty points.');
      }
    }
    if (referenceDimension <= 0.0 ||
        referenceDimension.isNaN ||
        referenceDimension.isInfinite) {
      throw FormatException(
        'referenceDimension must be positive and finite: $referenceDimension',
      );
    }
    if (consistencyThreshold <= 0.0 ||
        consistencyThreshold >= 1.0 ||
        consistencyThreshold.isNaN) {
      throw FormatException(
        'consistencyThreshold must be in (0.0, 1.0), got: $consistencyThreshold',
      );
    }
    if (windowRadius < 1) {
      throw FormatException('windowRadius must be >= 1, got: $windowRadius');
    }
    if (sigmaDtw <= 0.0 || sigmaDtw.isNaN || sigmaDtw.isInfinite) {
      throw FormatException(
        'sigmaDtw must be positive and finite, got: $sigmaDtw',
      );
    }
  }

  /// Convenience factory constructing the payload directly from domain entities.
  factory GestureConsistencyIsolatePayload.fromDomain({
    required List<GestureSample> samples,
    double referenceDimension = GestureNormalizer.canonicalReferenceDimension,
    double consistencyThreshold = 0.70,
    int windowRadius = FastDtwRecognizer.defaultWindowRadius,
    double sigmaDtw = FastDtwRecognizer.defaultSigmaDtw,
  }) {
    return GestureConsistencyIsolatePayload(
      samples: samples,
      referenceDimension: referenceDimension,
      consistencyThreshold: consistencyThreshold,
      windowRadius: windowRadius,
      sigmaDtw: sigmaDtw,
    );
  }

  @override
  List<Object?> get props => [
        samples,
        referenceDimension,
        consistencyThreshold,
        windowRadius,
        sigmaDtw,
      ];
}

/// Deeply immutable data transfer object sent across the isolate boundary
/// to execute DTW Barycenter Averaging (DBA) multi-sample master template synthesis.
@immutable
class GestureSynthesisIsolatePayload extends Equatable {
  /// Unmodifiable list of recorded gesture stroke samples (minimum 2, typically 3).
  final List<GestureSample> samples;

  /// Identifier assigned to the synthesized master template.
  final String templateId;

  /// Epoch timestamp in milliseconds when the template was synthesized.
  final int createdAtEpochMs;

  /// Canonical reference dimension in logical pixels (default: 250.0px).
  final double referenceDimension;

  /// Pairwise DTW consistency similarity threshold (default: 0.70).
  final double consistencyThreshold;

  /// Maximum DBA barycenter update iterations (default: 5).
  final int maxIterations;

  /// Convergence tolerance in logical pixels (default: 0.5px).
  final double convergenceTolerance;

  /// Sakoe-Chiba constraint window radius (default: 10).
  final int windowRadius;

  /// Exponential decay scaling parameter for DTW distance (default: 35.0).
  final double sigmaDtw;

  GestureSynthesisIsolatePayload({
    required List<GestureSample> samples,
    required this.templateId,
    required this.createdAtEpochMs,
    this.referenceDimension = GestureNormalizer.canonicalReferenceDimension,
    this.consistencyThreshold = 0.70,
    this.maxIterations = 5,
    this.convergenceTolerance = 0.5,
    this.windowRadius = FastDtwRecognizer.defaultWindowRadius,
    this.sigmaDtw = FastDtwRecognizer.defaultSigmaDtw,
  }) : samples = List<GestureSample>.unmodifiable(samples) {
    if (samples.length < 2) {
      throw FormatException(
        'GestureSynthesisIsolatePayload requires at least 2 samples, got: ${samples.length}',
      );
    }
    if (templateId.trim().isEmpty) {
      throw const FormatException('templateId must not be empty.');
    }
    if (createdAtEpochMs <= 0) {
      throw FormatException(
        'createdAtEpochMs must be positive: $createdAtEpochMs',
      );
    }
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].points.isEmpty) {
        throw FormatException('Sample at index $i must not contain empty points.');
      }
    }
    if (referenceDimension <= 0.0 ||
        referenceDimension.isNaN ||
        referenceDimension.isInfinite) {
      throw FormatException(
        'referenceDimension must be positive and finite: $referenceDimension',
      );
    }
    if (consistencyThreshold <= 0.0 ||
        consistencyThreshold >= 1.0 ||
        consistencyThreshold.isNaN) {
      throw FormatException(
        'consistencyThreshold must be in (0.0, 1.0), got: $consistencyThreshold',
      );
    }
    if (maxIterations < 1) {
      throw FormatException(
        'maxIterations must be at least 1, got: $maxIterations',
      );
    }
    if (convergenceTolerance <= 0.0 ||
        convergenceTolerance.isNaN ||
        convergenceTolerance.isInfinite) {
      throw FormatException(
        'convergenceTolerance must be positive and finite: $convergenceTolerance',
      );
    }
    if (windowRadius < 1) {
      throw FormatException('windowRadius must be >= 1, got: $windowRadius');
    }
    if (sigmaDtw <= 0.0 || sigmaDtw.isNaN || sigmaDtw.isInfinite) {
      throw FormatException(
        'sigmaDtw must be positive and finite, got: $sigmaDtw',
      );
    }
  }

  /// Convenience factory constructing the payload directly from domain entities.
  factory GestureSynthesisIsolatePayload.fromDomain({
    required List<GestureSample> samples,
    required String templateId,
    int? createdAtEpochMs,
    double referenceDimension = GestureNormalizer.canonicalReferenceDimension,
    double consistencyThreshold = 0.70,
    int maxIterations = 5,
    double convergenceTolerance = 0.5,
    int windowRadius = FastDtwRecognizer.defaultWindowRadius,
    double sigmaDtw = FastDtwRecognizer.defaultSigmaDtw,
  }) {
    final int effectiveEpoch;
    if (createdAtEpochMs case final int epoch) {
      effectiveEpoch = epoch;
    } else {
      effectiveEpoch = DateTime.now().millisecondsSinceEpoch;
    }

    return GestureSynthesisIsolatePayload(
      samples: samples,
      templateId: templateId,
      createdAtEpochMs: effectiveEpoch,
      referenceDimension: referenceDimension,
      consistencyThreshold: consistencyThreshold,
      maxIterations: maxIterations,
      convergenceTolerance: convergenceTolerance,
      windowRadius: windowRadius,
      sigmaDtw: sigmaDtw,
    );
  }

  @override
  List<Object?> get props => [
        samples,
        templateId,
        createdAtEpochMs,
        referenceDimension,
        consistencyThreshold,
        maxIterations,
        convergenceTolerance,
        windowRadius,
        sigmaDtw,
      ];
}
