/// Domain-level diff operations. No protobuf dependency.
sealed class DiffOp {
  const DiffOp();
}

/// Insert tracks at a position (or at the start/end).
class AddOp extends DiffOp {
  final int fromIndex;
  final List<String> uris;
  final bool addFirst;
  final bool addLast;

  const AddOp({
    required this.fromIndex,
    required this.uris,
    this.addFirst = false,
    this.addLast = false,
  });
}

/// Remove [length] tracks starting at [fromIndex].
class RemOp extends DiffOp {
  final int fromIndex;
  final int length;

  const RemOp({required this.fromIndex, required this.length});
}

/// Move [length] tracks from [fromIndex] to [toIndex].
///
/// [toIndex] uses Spotify's OT convention: it refers to the position
/// in the **original** array (before removal). When fromIndex < toIndex,
/// the actual insertion point after removal is `toIndex - length`.
class MovOp extends DiffOp {
  final int fromIndex;
  final int toIndex;
  final int length;

  const MovOp({
    required this.fromIndex,
    required this.toIndex,
    required this.length,
  });
}
