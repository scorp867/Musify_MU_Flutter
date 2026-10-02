/// Standardized cache expiration policy.
///
/// Each feature cache declares its policy as a first-class object
/// instead of scattering magic Duration constants across files.
class CachePolicy {
  final Duration ttl;
  final int? maxEntries;

  const CachePolicy({required this.ttl, this.maxEntries});

  /// Structure data that changes frequently (library rootlist, collections).
  static const frequent = CachePolicy(ttl: Duration(hours: 1));

  /// View-level data with moderate freshness (home feed, decorations, playlists).
  static const standard = CachePolicy(ttl: Duration(hours: 24));

  /// Stable reference data (browse genre traits, track metadata).
  static const durable = CachePolicy(ttl: Duration(days: 7));

  /// Returns true if an entry cached at [cachedAtMs] has exceeded the TTL.
  bool isExpired(int cachedAtMs) {
    return DateTime.now().millisecondsSinceEpoch - cachedAtMs >
        ttl.inMilliseconds;
  }
}
