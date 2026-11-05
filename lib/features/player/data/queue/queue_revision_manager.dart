/// 1:1 manager for Spotify queue revision lifecycle.
/// Spotify queue revisions are monotonic 64-bit integer counters starting at 0,
/// serialized as string representations in domain models and int64 on the wire.
abstract final class QueueRevisionManager {
  static const String initialRevision = '0';

  /// Parses a revision string into an integer value safely.
  static int parse(String? revision) {
    if (revision == null || revision.isEmpty) return 0;
    final parsed = int.tryParse(revision);
    if (parsed case final val?) return val;
    return 0;
  }

  /// Calculates the next incremented revision string.
  static String increment(String? currentRevision) {
    final current = parse(currentRevision);
    return (current + 1).toString();
  }

  /// Validates whether a revision string matches Spotify requirements (non-negative integer).
  static bool isValid(String? revision) {
    if (revision == null || revision.isEmpty) return false;
    final parsed = int.tryParse(revision);
    return parsed != null && parsed >= 0;
  }
}
