/// Priority levels for network requests across Musify_MU.
///
/// Ensures audio playback traffic is never queued behind bulk background
/// syncs (e.g., 30+ playlist diffs or Kodiak viewport trait batches).
enum NetworkPriority {
  /// Priority 0: Immediate dispatch, bypasses background throttling.
  /// Used for playback tokens, audio stream CDN URLs, and decryption keys.
  playback(0),

  /// Priority 1: High-priority interactive requests triggered by explicit user actions.
  /// Used for search queries, screen navigation, and tab switches.
  interactive(1),

  /// Priority 2: Background tasks that can tolerate queue delays and throttling.
  /// Used for Kodiak viewport trait batching, library playlist syncs, and prefetching.
  background(2);

  final int value;

  const NetworkPriority(this.value);

  bool operator <(NetworkPriority other) => value < other.value;
  bool operator <=(NetworkPriority other) => value <= other.value;
  bool operator >(NetworkPriority other) => value > other.value;
  bool operator >=(NetworkPriority other) => value >= other.value;
}
