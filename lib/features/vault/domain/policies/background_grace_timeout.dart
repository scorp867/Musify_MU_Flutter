/// Policy defining the grace window allowed when the app is placed in background.
///
/// When the app enters paused/background lifecycle, VaultSessionState enters
/// backgroundGrace. If the user returns within this timeout, session resumes;
/// otherwise, the vault locks immediately and session keys are zeroed from RAM.
enum BackgroundGraceTimeoutEnum {
  /// Zero grace period: locks immediately upon losing foreground focus.
  immediate(
    id: 'IMMEDIATE',
    displayName: 'Immediate',
    duration: Duration.zero,
    milliseconds: 0,
    seconds: 0,
  ),

  /// 30 seconds grace period (30,000 milliseconds).
  thirtySeconds(
    id: 'THIRTY_SECONDS',
    displayName: '30 Seconds',
    duration: Duration(seconds: 30),
    milliseconds: 30000,
    seconds: 30,
  ),

  /// 1 minute grace period (60,000 milliseconds).
  oneMinute(
    id: 'ONE_MINUTE',
    displayName: '1 Minute',
    duration: Duration(minutes: 1),
    milliseconds: 60000,
    seconds: 60,
  ),

  /// 5 minutes grace period (300,000 milliseconds).
  fiveMinutes(
    id: 'FIVE_MINUTES',
    displayName: '5 Minutes',
    duration: Duration(minutes: 5),
    milliseconds: 300000,
    seconds: 300,
  );

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Timeout [Duration].
  final Duration duration;

  /// Timeout in milliseconds.
  final int milliseconds;

  /// Timeout in seconds.
  final int seconds;

  const BackgroundGraceTimeoutEnum({
    required this.id,
    required this.displayName,
    required this.duration,
    required this.milliseconds,
    required this.seconds,
  });

  /// Evaluates whether the policy requires immediate locking on background.
  bool get isImmediate => this == BackgroundGraceTimeoutEnum.immediate;

  /// Evaluates whether the grace timeout has expired given [elapsedBackgroundMs].
  bool isExpired({required int elapsedBackgroundMs}) {
    return elapsedBackgroundMs >= milliseconds;
  }

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [BackgroundGraceTimeoutEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static BackgroundGraceTimeoutEnum fromId(String id) {
    for (final timeout in BackgroundGraceTimeoutEnum.values) {
      if (timeout.id == id || timeout.name == id) {
        return timeout;
      }
    }
    throw FormatException(
      'Invalid BackgroundGraceTimeoutEnum identifier: "$id". '
      'Valid options are: ${BackgroundGraceTimeoutEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static BackgroundGraceTimeoutEnum fromJson(String json) => fromId(json);
}
