import 'package:musify_mu/features/library/domain/services/diff_op.dart';

/// Pure-function diff engine. Applies Spotify's sequential OT ops
/// to a track URI list. Zero external dependencies.
///
/// Each op's indices are relative to the list state AFTER all
/// previous ops have been applied (sequential OT protocol).
class PlaylistDiffEngine {
  const PlaylistDiffEngine._();

  /// Applies [ops] to a copy of [tracks] and returns the new list.
  static List<String> apply(List<String> tracks, List<DiffOp> ops) {
    final result = List<String>.from(tracks);

    for (final op in ops) {
      switch (op) {
        case AddOp():
          _applyAdd(result, op);
        case RemOp():
          _applyRem(result, op);
        case MovOp():
          _applyMov(result, op);
      }
    }

    return result;
  }

  static void _applyAdd(List<String> tracks, AddOp op) {
    if (op.uris.isEmpty) return;

    if (op.addLast) {
      tracks.addAll(op.uris);
    } else if (op.addFirst) {
      tracks.insertAll(0, op.uris);
    } else {
      final insertAt = op.fromIndex.clamp(0, tracks.length);
      tracks.insertAll(insertAt, op.uris);
    }
  }

  static void _applyRem(List<String> tracks, RemOp op) {
    final start = op.fromIndex.clamp(0, tracks.length);
    final removeCount = op.length.clamp(0, tracks.length - start);
    if (removeCount > 0) {
      tracks.removeRange(start, start + removeCount);
    }
  }

  static void _applyMov(List<String> tracks, MovOp op) {
    final start = op.fromIndex.clamp(0, tracks.length);
    final moveCount = op.length.clamp(0, tracks.length - start);
    if (moveCount <= 0) return;

    final moved = tracks.sublist(start, start + moveCount);
    tracks.removeRange(start, start + moveCount);

    // Spotify's toIndex refers to the position in the ORIGINAL array
    // (before removal). When fromIndex < toIndex, removing items
    // before toIndex shifts everything left by moveCount.
    int target;
    if (start < op.toIndex) {
      target = (op.toIndex - moveCount).clamp(0, tracks.length);
    } else {
      target = op.toIndex.clamp(0, tracks.length);
    }
    tracks.insertAll(target, moved);
  }
}
