/// Sensitivity threshold policy for the Stealth Gesture Recognizer ensemble.
///
/// Controls the minimum ensemble consensus score (S_ensemble) required to confirm
/// a stealth gesture match and transition to the authenticating state.
///
/// Mathematical fusion formula per specification §7 Job 8:
/// S_ensemble = 0.50 * S_$1 + 0.35 * S_DTW + 0.15 * S_feat
///
/// Minimum classifier gates:
/// - Structural Gate: S_feat >= 0.68
/// - Safety Floors: S_$1 >= 0.65 and S_DTW >= 0.60
enum GestureSensitivityTierEnum {
  /// Strict tier requiring 88% ensemble consensus (S_ensemble >= 0.88).
  /// High security mode; rejects subtle inaccuracies in stroke geometry.
  strict92Percent(
    id: 'STRICT_92_PERCENT',
    displayName: 'Strict (High Security)',
    thresholdScore: 0.88,
    nominalPercentage: 92,
  ),

  /// Balanced tier requiring 78% ensemble consensus (S_ensemble >= 0.78).
  /// Recommended default mode balancing security and recognition reliability.
  balanced84Percent(
    id: 'BALANCED_84_PERCENT',
    displayName: 'Balanced (Recommended)',
    thresholdScore: 0.78,
    nominalPercentage: 84,
  ),

  /// Relaxed tier requiring 68% ensemble consensus (S_ensemble >= 0.68).
  /// Accommodates natural motor tremor and variable drawing speeds.
  relaxed76Percent(
    id: 'RELAXED_76_PERCENT',
    displayName: 'Relaxed (Easy Recognition)',
    thresholdScore: 0.68,
    nominalPercentage: 76,
  );

  /// Minimum structural feature gate required for any match decision.
  static const double minimumStructuralGate = 0.68;

  /// Safety floor for $1-B classifier score.
  static const double safetyFloorDollar1 = 0.65;

  /// Safety floor for FastDTW classifier score.
  static const double safetyFloorDtw = 0.60;

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Minimum ensemble consensus score required for a match decision.
  final double thresholdScore;

  /// Nominal percentage label.
  final int nominalPercentage;

  const GestureSensitivityTierEnum({
    required this.id,
    required this.displayName,
    required this.thresholdScore,
    required this.nominalPercentage,
  });

  /// Evaluates whether the given [ensembleScore] meets or exceeds this tier's threshold.
  bool isSatisfiedBy(double ensembleScore) => ensembleScore >= thresholdScore;

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [GestureSensitivityTierEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static GestureSensitivityTierEnum fromId(String id) {
    for (final tier in GestureSensitivityTierEnum.values) {
      if (tier.id == id || tier.name == id) {
        return tier;
      }
    }
    throw FormatException(
      'Invalid GestureSensitivityTierEnum identifier: "$id". '
      'Valid options are: ${GestureSensitivityTierEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static GestureSensitivityTierEnum fromJson(String json) => fromId(json);
}
