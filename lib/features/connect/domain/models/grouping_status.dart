// 1:1 replica of p199p/im40.java (lines 6–46), p199p/z9k.java (lines 4–27),
// p199p/n8d.java (lines 820–854), and protos/spotify/connect/group.proto (lines 15–20).

/// Speaker group membership status matching `p199p/im40.java` in exact ordinal
/// order (0..3).
enum GroupingStatus {
  unknown, // 0: UNKNOWN / proto UNKNOWN_GROUPING_STATUS (0)
  grouped, // 1: GROUPED / proto GROUPED (1)
  groupable, // 2: GROUPABLE / proto GROUPABLE (2)
  connecting; // 3: CONNECTING / proto GROUPING (3)

  /// Maps a `spotify.connect.GroupingStatus` wire enum integer (0..3) to
  /// [GroupingStatus], matching `p199p/n8d.java` (lines 820–854).
  ///
  /// Throws [RangeError] if [value] is outside `0..3`.
  static GroupingStatus fromProtoIndex(int value) {
    switch (value) {
      case 0:
        return GroupingStatus.unknown;
      case 1:
        return GroupingStatus.grouped;
      case 2:
        return GroupingStatus.groupable;
      case 3:
        return GroupingStatus.connecting;
      default:
        throw RangeError.range(
          value,
          0,
          3,
          'value',
          'Invalid GroupingStatus proto index',
        );
    }
  }

  /// Parses a wire or domain string into [GroupingStatus].
  ///
  /// Throws [FormatException] if [raw] is empty or unrecognized.
  static GroupingStatus fromWireName(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw FormatException(
        'GroupingStatus wire name must not be empty',
        raw,
      );
    }

    switch (normalized) {
      case 'UNKNOWN':
      case 'UNKNOWN_GROUPING_STATUS':
        return GroupingStatus.unknown;
      case 'GROUPED':
        return GroupingStatus.grouped;
      case 'GROUPABLE':
        return GroupingStatus.groupable;
      case 'CONNECTING':
      case 'GROUPING':
        return GroupingStatus.connecting;
      default:
        throw FormatException('Unknown GroupingStatus wire name: $raw', raw);
    }
  }

  /// Canonical `p199p/im40.java` name for this status.
  String get wireName {
    switch (this) {
      case GroupingStatus.unknown:
        return 'UNKNOWN';
      case GroupingStatus.grouped:
        return 'GROUPED';
      case GroupingStatus.groupable:
        return 'GROUPABLE';
      case GroupingStatus.connecting:
        return 'CONNECTING';
    }
  }
}
