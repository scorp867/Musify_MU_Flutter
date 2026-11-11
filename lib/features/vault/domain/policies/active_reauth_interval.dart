/// Policy governing periodic step-up re-authentication intervals during active vault sessions.
///
/// Evaluated against the OS monotonic clock (CLOCK_MONOTONIC via Stopwatch)
/// to prevent clock tampering. When elapsed duration exceeds this policy,
/// VaultSessionState transitions from unlocked to pendingReauth.
enum ActiveReauthIntervalEnum {
  /// Re-authenticate every 5 minutes (300,000 milliseconds).
  every5Minutes(
    id: 'EVERY_5_MINUTES',
    displayName: 'Every 5 Minutes',
    duration: Duration(minutes: 5),
    milliseconds: 300000,
    minutes: 5,
  ),

  /// Re-authenticate every 15 minutes (900,000 milliseconds).
  every15Minutes(
    id: 'EVERY_15_MINUTES',
    displayName: 'Every 15 Minutes',
    duration: Duration(minutes: 15),
    milliseconds: 900000,
    minutes: 15,
  ),

  /// Re-authenticate every 30 minutes (1,800,000 milliseconds).
  every30Minutes(
    id: 'EVERY_30_MINUTES',
    displayName: 'Every 30 Minutes',
    duration: Duration(minutes: 30),
    milliseconds: 1800000,
    minutes: 30,
  ),

  /// Re-authentication is never required periodically while the app remains active.
  never(
    id: 'NEVER',
    displayName: 'Never',
    duration: null,
    milliseconds: null,
    minutes: null,
  );

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Timeout [Duration], or null if re-authentication is disabled ([never]).
  final Duration? duration;

  /// Timeout in milliseconds, or null if re-authentication is disabled ([never]).
  final int? milliseconds;

  /// Timeout in integer minutes, or null if re-authentication is disabled ([never]).
  final int? minutes;

  const ActiveReauthIntervalEnum({
    required this.id,
    required this.displayName,
    required this.duration,
    required this.milliseconds,
    required this.minutes,
  });

  /// Whether this policy requires re-authentication after an interval.
  bool get hasTimeout => this != ActiveReauthIntervalEnum.never;

  /// Evaluates whether the interval has expired given the [elapsedMonotonicMs].
  ///
  /// Always returns false for [never].
  bool isExpired({required int elapsedMonotonicMs}) {
    final limit = milliseconds;
    if (limit == null) {
      return false;
    }
    return elapsedMonotonicMs >= limit;
  }

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [ActiveReauthIntervalEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static ActiveReauthIntervalEnum fromId(String id) {
    for (final interval in ActiveReauthIntervalEnum.values) {
      if (interval.id == id || interval.name == id) {
        return interval;
      }
    }
    throw FormatException(
      'Invalid ActiveReauthIntervalEnum identifier: "$id". '
      'Valid options are: ${ActiveReauthIntervalEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static ActiveReauthIntervalEnum fromJson(String json) => fromId(json);
}
