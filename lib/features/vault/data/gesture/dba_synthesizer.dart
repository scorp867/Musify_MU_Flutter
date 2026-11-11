import 'dart:math' as math;
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/data/gesture/fast_dtw_recognizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_normalizer.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_resampler.dart';
import 'package:musify_mu/features/vault/data/gesture/kinematic_sanity_gate.dart';
import 'package:musify_mu/features/vault/data/gesture/raw_touch_filter.dart';
import 'package:musify_mu/features/vault/data/gesture/rubine_feature_extractor.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';

/// Lightweight immutable value object representing a discrete point on a DTW warping path.
@immutable
class DtwPathPoint extends Equatable {
  /// Zero-based coordinate index on sequence 1 (reference template).
  final int index1;

  /// Zero-based coordinate index on sequence 2 (candidate sample).
  final int index2;

  const DtwPathPoint(this.index1, this.index2);

  @override
  List<Object?> get props => [index1, index2];
}

/// Detailed diagnostics emitted by pairwise DTW consistency checking.
@immutable
class PairwiseConsistencyResult extends Equatable {
  /// Whether all evaluated sample pairs satisfied the DTW consistency threshold.
  final bool isConsistent;

  /// Index of the most divergent outlier sample if consistency failed.
  final int? outlierIndex;

  /// Minimal pairwise DTW similarity score observed across all pairs.
  final double minimumPairScore;

  /// Mapping of sample pair indices to their bidirectional DTW similarity scores.
  final Map<String, double> pairScores;

  const PairwiseConsistencyResult({
    required this.isConsistent,
    required this.outlierIndex,
    required this.minimumPairScore,
    required this.pairScores,
  });

  @override
  List<Object?> get props => [
        isConsistent,
        outlierIndex,
        minimumPairScore,
        pairScores,
      ];
}

/// Pure mathematical engine for DTW Barycenter Averaging (DBA) multi-sample
/// master template synthesis and pairwise consistency checking.
///
/// Implements Job 9 of the Single-Stroke Stealth Gesture Recognition Pipeline
/// (Harel Region D: Gesture Engine).
@immutable
class DbaSynthesizer {
  /// Default exponential decay scaling parameter for DTW consistency checks.
  static const double defaultSigmaDtw = FastDtwRecognizer.defaultSigmaDtw;

  /// Default Sakoe-Chiba constraint window radius.
  static const int defaultWindowRadius = FastDtwRecognizer.defaultWindowRadius;

  /// Minimum bidirectional DTW consistency score required across all sample pairs.
  static const double defaultMinConsistencyDtwScore = 0.70;

  /// Maximum DBA convergence iterations.
  static const int defaultMaxIterations = 5;

  /// RMS coordinate shift convergence threshold in logical pixels.
  static const double defaultConvergenceTolerance = 0.5;

  /// Pre-filtering touch filter instance.
  final RawTouchFilter filter;

  /// Kinematic sanity and anti-scribble gate instance.
  final KinematicSanityGate kinematicGate;

  /// Constructs a stateless [DbaSynthesizer] with injectable dependencies.
  const DbaSynthesizer({
    this.filter = const RawTouchFilter(),
    this.kinematicGate = KinematicSanityGate.standard,
  });

  /// Standardizes a raw [sample] through filtering, kinematic gating,
  /// N = 64 resampling, and canonical coordinate normalization.
  ///
  /// Throws [FormatException] if the sample is empty or fails kinematic gating.
  static List<GesturePoint> standardizeSample(
    GestureSample sample, {
    double referenceDimension = GestureNormalizer.canonicalReferenceDimension,
    double deadbandThreshold = RawTouchFilter.defaultDeadbandThreshold,
    RawTouchFilter filter = const RawTouchFilter(),
    KinematicSanityGate gate = KinematicSanityGate.standard,
  }) {
    if (sample.points.isEmpty) {
      throw const FormatException('Cannot standardize empty gesture sample.');
    }

    final List<GesturePoint> filtered = filter.filterRawPoints(
      sample.points,
      deadbandThreshold: deadbandThreshold,
    );

    final KinematicGateDecision decision = gate.evaluate(filtered);
    switch (decision) {
      case KinematicGateRejected(:final reason):
        throw FormatException(
          'Sample failed kinematic sanity gate: $reason',
        );
      case KinematicGatePassed():
        break;
    }

    final List<GesturePoint> resampled = GestureResampler.resample(
      filtered,
      targetCount: GestureTemplate.requiredPointCount,
    );

    return GestureNormalizer.normalizeCoordinates(
      resampled,
      referenceDimension: referenceDimension,
    );
  }

  /// Computes the exact DTW warping path between [seq1] and [seq2] with Sakoe-Chiba window band.
  ///
  /// Returns ordered list of coordinate index pairs (u, v) from (0, 0) to (N-1, M-1).
  static List<DtwPathPoint> extractWarpingPath(
    List<GesturePoint> seq1,
    List<GesturePoint> seq2, {
    int windowRadius = defaultWindowRadius,
  }) {
    final int n = seq1.length;
    final int m = seq2.length;

    if (n == 0 || m == 0) {
      throw const FormatException(
        'Sequences must not be empty for warping path extraction.',
      );
    }

    final Float64List dMatrix = Float64List((n + 1) * (m + 1));
    final Int8List pMatrix = Int8List((n + 1) * (m + 1));

    // Initialize boundary cells
    for (int i = 0; i <= n; i++) {
      for (int j = 0; j <= m; j++) {
        dMatrix[i * (m + 1) + j] = double.infinity;
      }
    }
    dMatrix[0] = 0.0;

    for (int i = 1; i <= n; i++) {
      final int rowOffset = i * (m + 1);
      final int prevRowOffset = (i - 1) * (m + 1);
      final GesturePoint p1 = seq1[i - 1];

      final int jMin = (i - windowRadius < 1) ? 1 : (i - windowRadius);
      final int jMax = (i + windowRadius > m) ? m : (i + windowRadius);

      for (int j = jMin; j <= jMax; j++) {
        final GesturePoint p2 = seq2[j - 1];
        final double dx = p1.x - p2.x;
        final double dy = p1.y - p2.y;
        final double localDist = math.sqrt(dx * dx + dy * dy);

        final double diagCost = dMatrix[prevRowOffset + (j - 1)];
        final double vertCost = dMatrix[prevRowOffset + j];
        final double horizCost = dMatrix[rowOffset + (j - 1)];

        // Tie-breaking preference: Diagonal (0) > Vertical (1) > Horizontal (2)
        double minCost = diagCost;
        int pred = 0;

        if (vertCost < minCost) {
          minCost = vertCost;
          pred = 1;
        }
        if (horizCost < minCost) {
          minCost = horizCost;
          pred = 2;
        }

        if (minCost.isFinite) {
          dMatrix[rowOffset + j] = minCost + localDist;
          pMatrix[rowOffset + j] = pred;
        }
      }
    }

    // Backtrack from (n, m) to (0, 0)
    final List<DtwPathPoint> path = <DtwPathPoint>[];
    int currI = n;
    int currJ = m;

    while (currI > 0 && currJ > 0) {
      path.add(DtwPathPoint(currI - 1, currJ - 1));
      final int pred = pMatrix[currI * (m + 1) + currJ];
      if (pred == 0) {
        currI--;
        currJ--;
      } else if (pred == 1) {
        currI--;
      } else {
        currJ--;
      }
    }

    while (currI > 0) {
      path.add(DtwPathPoint(currI - 1, 0));
      currI--;
    }
    while (currJ > 0) {
      path.add(DtwPathPoint(0, currJ - 1));
      currJ--;
    }

    return List<DtwPathPoint>.unmodifiable(path.reversed);
  }

  /// Evaluates detailed pairwise DTW consistency across pre-standardized [normalizedSamples].
  static PairwiseConsistencyResult evaluateNormalizedConsistency({
    required List<List<GesturePoint>> normalizedSamples,
    double minDtwScore = defaultMinConsistencyDtwScore,
    int windowRadius = defaultWindowRadius,
    double sigmaDtw = defaultSigmaDtw,
  }) {
    final int k = normalizedSamples.length;
    if (k < 2) {
      throw FormatException(
        'Pairwise consistency evaluation requires at least 2 samples, got: $k',
      );
    }

    final Map<String, double> pairScores = <String, double>{};
    final List<double> sumScores = List<double>.filled(k, 0.0);
    double lowestScore = 1.0;
    bool allPass = true;

    for (int a = 0; a < k; a++) {
      for (int b = a + 1; b < k; b++) {
        final List<GesturePoint> seqA = normalizedSamples[a];
        final List<GesturePoint> seqB = normalizedSamples[b];

        final double dFwd = FastDtwRecognizer.computeDtwDistance(
          seqA,
          seqB,
          windowRadius: windowRadius,
        );
        final double dRev = FastDtwRecognizer.computeDtwDistance(
          seqA,
          List<GesturePoint>.unmodifiable(seqB.reversed),
          windowRadius: windowRadius,
        );

        final double dBi = (dFwd <= dRev) ? dFwd : dRev;
        final double score = math.exp(
          -dBi / (GestureTemplate.requiredPointCount * sigmaDtw),
        );

        pairScores['$a-$b'] = score;
        sumScores[a] += score;
        sumScores[b] += score;

        if (score < lowestScore) {
          lowestScore = score;
        }
        if (score < minDtwScore) {
          allPass = false;
        }
      }
    }

    int? outlierIndex;
    if (!allPass) {
      int candidateOutlier = 0;
      double minAvgScore = double.infinity;
      for (int i = 0; i < k; i++) {
        final double avg = sumScores[i] / (k - 1);
        if (avg < minAvgScore) {
          minAvgScore = avg;
          candidateOutlier = i;
        }
      }
      outlierIndex = candidateOutlier;
    }

    return PairwiseConsistencyResult(
      isConsistent: allPass,
      outlierIndex: outlierIndex,
      minimumPairScore: lowestScore,
      pairScores: Map<String, double>.unmodifiable(pairScores),
    );
  }

  /// Evaluates pairwise DTW consistency across recorded raw [samples].
  ///
  /// Standardizes each sample through pre-filtering, sanity gating, resampling, and normalization.
  /// Returns `true` if all pairwise bidirectional DTW scores satisfy [minDtwScore].
  bool checkConsistency({
    required List<GestureSample> samples,
    double minDtwScore = defaultMinConsistencyDtwScore,
    int windowRadius = defaultWindowRadius,
    double sigmaDtw = defaultSigmaDtw,
    double referenceDimension = GestureNormalizer.canonicalReferenceDimension,
  }) {
    if (samples.length < 2) {
      throw FormatException(
        'checkConsistency requires at least 2 samples, got: ${samples.length}',
      );
    }

    final List<List<GesturePoint>> normalized = <List<GesturePoint>>[];
    for (int i = 0; i < samples.length; i++) {
      normalized.add(
        standardizeSample(
          samples[i],
          referenceDimension: referenceDimension,
          filter: filter,
          gate: kinematicGate,
        ),
      );
    }

    final PairwiseConsistencyResult result = evaluateNormalizedConsistency(
      normalizedSamples: normalized,
      minDtwScore: minDtwScore,
      windowRadius: windowRadius,
      sigmaDtw: sigmaDtw,
    );

    return result.isConsistent;
  }

  /// Synthesizes a golden master [GestureTemplate] from recorded [samples] using DTW Barycenter Averaging.
  ///
  /// Enforces:
  /// 1. Exactly/at least 2 samples (typically 3).
  /// 2. Pre-filtering, kinematic sanity gate, N = 64 resampling, and normalization.
  /// 3. Pairwise DTW consistency check (rejecting divergent strokes with outlier index diagnostics).
  /// 4. Inversion of reverse-drawn samples to align along Sample 0's trajectory.
  /// 5. Iterative barycenter coordinate averaging up to [maxIterations] with early convergence termination.
  /// 6. Post-DBA arc-length resampling and normalization.
  /// 7. 7D Rubine geometric feature vector extraction.
  GestureTemplate synthesize({
    required List<GestureSample> samples,
    required String id,
    int? createdAtEpochMs,
    int maxIterations = defaultMaxIterations,
    double convergenceTolerance = defaultConvergenceTolerance,
    int windowRadius = defaultWindowRadius,
    double minDtwScore = defaultMinConsistencyDtwScore,
    double sigmaDtw = defaultSigmaDtw,
    double referenceDimension = GestureNormalizer.canonicalReferenceDimension,
  }) {
    return synthesizeStatic(
      samples: samples,
      id: id,
      createdAtEpochMs: createdAtEpochMs,
      maxIterations: maxIterations,
      convergenceTolerance: convergenceTolerance,
      windowRadius: windowRadius,
      minDtwScore: minDtwScore,
      sigmaDtw: sigmaDtw,
      referenceDimension: referenceDimension,
      filter: filter,
      gate: kinematicGate,
    );
  }

  /// Static pure mathematical entry point for DTW Barycenter Averaging synthesis.
  static GestureTemplate synthesizeStatic({
    required List<GestureSample> samples,
    required String id,
    int? createdAtEpochMs,
    int maxIterations = defaultMaxIterations,
    double convergenceTolerance = defaultConvergenceTolerance,
    int windowRadius = defaultWindowRadius,
    double minDtwScore = defaultMinConsistencyDtwScore,
    double sigmaDtw = defaultSigmaDtw,
    double referenceDimension = GestureNormalizer.canonicalReferenceDimension,
    RawTouchFilter filter = const RawTouchFilter(),
    KinematicSanityGate gate = KinematicSanityGate.standard,
  }) {
    if (samples.length < 2) {
      throw FormatException(
        'DBA synthesis requires at least 2 samples, got: ${samples.length}',
      );
    }
    if (id.trim().isEmpty) {
      throw const FormatException('Template id must not be empty.');
    }

    final int effectiveEpoch;
    if (createdAtEpochMs case final int epoch) {
      effectiveEpoch = epoch;
    } else {
      effectiveEpoch = DateTime.now().millisecondsSinceEpoch;
    }

    // 1. Standardize all input samples
    final List<List<GesturePoint>> standardizedSamples = <List<GesturePoint>>[];
    for (int i = 0; i < samples.length; i++) {
      standardizedSamples.add(
        standardizeSample(
          samples[i],
          referenceDimension: referenceDimension,
          filter: filter,
          gate: gate,
        ),
      );
    }

    // 2. Validate pairwise DTW consistency across all samples
    final PairwiseConsistencyResult consistency = evaluateNormalizedConsistency(
      normalizedSamples: standardizedSamples,
      minDtwScore: minDtwScore,
      windowRadius: windowRadius,
      sigmaDtw: sigmaDtw,
    );

    if (!consistency.isConsistent) {
      final String outlierMsg;
      if (consistency.outlierIndex case final int idx) {
        outlierMsg = ' Outlier sample index: $idx.';
      } else {
        outlierMsg = '';
      }
      throw FormatException(
        'Cannot synthesize template: samples failed pairwise DTW consistency check '
        '(min score: ${consistency.minimumPairScore.toStringAsFixed(3)} < $minDtwScore).$outlierMsg',
      );
    }

    // 3. Orient all samples along Sample 0's trajectory (invert reverse-drawn samples)
    final List<List<GesturePoint>> orientedSamples = <List<GesturePoint>>[];
    final List<GesturePoint> anchorSample = standardizedSamples[0];
    orientedSamples.add(anchorSample);

    for (int k = 1; k < standardizedSamples.length; k++) {
      final List<GesturePoint> candidate = standardizedSamples[k];
      final double dFwd = FastDtwRecognizer.computeDtwDistance(
        anchorSample,
        candidate,
        windowRadius: windowRadius,
      );
      final double dRev = FastDtwRecognizer.computeDtwDistance(
        anchorSample,
        List<GesturePoint>.unmodifiable(candidate.reversed),
        windowRadius: windowRadius,
      );

      if (dRev < dFwd) {
        orientedSamples.add(
          List<GesturePoint>.unmodifiable(candidate.reversed),
        );
      } else {
        orientedSamples.add(candidate);
      }
    }

    // 4. Initialize barycenter with Sample 0
    List<GesturePoint> currentTemplate = List<GesturePoint>.from(anchorSample);
    const int pointCount = GestureTemplate.requiredPointCount;

    // 5. Iterative DBA refinement
    for (int iter = 0; iter < maxIterations; iter++) {
      final Float64List sumX = Float64List(pointCount);
      final Float64List sumY = Float64List(pointCount);
      final Int32List counts = Int32List(pointCount);

      for (int k = 0; k < orientedSamples.length; k++) {
        final List<GesturePoint> samplePoints = orientedSamples[k];
        final List<DtwPathPoint> warpingPath = extractWarpingPath(
          currentTemplate,
          samplePoints,
          windowRadius: windowRadius,
        );

        for (int p = 0; p < warpingPath.length; p++) {
          final DtwPathPoint pt = warpingPath[p];
          final int u = pt.index1;
          final int v = pt.index2;

          sumX[u] += samplePoints[v].x;
          sumY[u] += samplePoints[v].y;
          counts[u] += 1;
        }
      }

      final List<GesturePoint> nextTemplate = <GesturePoint>[];
      double sumSqDiff = 0.0;

      for (int i = 0; i < pointCount; i++) {
        final int cnt = counts[i];
        final double prevX = currentTemplate[i].x;
        final double prevY = currentTemplate[i].y;

        final double newX = (cnt > 0) ? (sumX[i] / cnt) : prevX;
        final double newY = (cnt > 0) ? (sumY[i] / cnt) : prevY;

        final double dx = newX - prevX;
        final double dy = newY - prevY;
        sumSqDiff += (dx * dx + dy * dy);

        nextTemplate.add(
          GesturePoint(
            x: newX,
            y: newY,
            timestampMs: anchorSample[i].timestampMs,
          ),
        );
      }

      final double rmsShift = math.sqrt(sumSqDiff / pointCount);
      currentTemplate = nextTemplate;

      if (rmsShift < convergenceTolerance) {
        break;
      }
    }

    // 6. Post-DBA arc-length resampling to ensure equidistant spatial distribution
    final List<GesturePoint> resampledPoints = GestureResampler.resample(
      currentTemplate,
      targetCount: pointCount,
    );

    // 7. Post-DBA coordinate normalization to canonical reference dimension
    final List<GesturePoint> normalizedPoints =
        GestureNormalizer.normalizeCoordinates(
      resampledPoints,
      referenceDimension: referenceDimension,
    );

    // 8. Extract authoritative 7D Rubine geometric feature vector
    final List<double> rubineVector =
        RubineFeatureExtractor.extractFeaturesStatic(normalizedPoints);

    return GestureTemplate(
      id: id,
      normalizedPoints: normalizedPoints,
      rubineFeatureVector: rubineVector,
      createdAtEpochMs: effectiveEpoch,
    );
  }
}
