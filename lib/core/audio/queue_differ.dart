import 'dart:math';

/// A minimal edit transforming the current queue into the target queue.
sealed class QueueEdit {
  const QueueEdit();
}

/// Insert a new item at [index] of the working list.
/// [targetIndex] is its position in the target list.
final class QueueEditInsert extends QueueEdit {
  final int index;
  final int targetIndex;

  const QueueEditInsert(this.index, this.targetIndex);

  @override
  String toString() => 'QueueEditInsert(index: $index, targetIndex: $targetIndex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueEditInsert &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          targetIndex == other.targetIndex;

  @override
  int get hashCode => Object.hash(index, targetIndex);
}

/// Remove the item currently at [index] of the working list.
final class QueueEditRemove extends QueueEdit {
  final int index;

  const QueueEditRemove(this.index);

  @override
  String toString() => 'QueueEditRemove(index: $index)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueEditRemove &&
          runtimeType == other.runtimeType &&
          index == other.index;

  @override
  int get hashCode => index.hashCode;
}

/// Move the item currently at [from] so that it ends up at [to] of the working list.
final class QueueEditMove extends QueueEdit {
  final int from;
  final int to;

  const QueueEditMove(this.from, this.to);

  @override
  String toString() => 'QueueEditMove(from: $from, to: $to)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueEditMove &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Identity of a queue slot used for occurrence-aware keying.
final class KeySource {
  final String uri;
  final String? uid;

  const KeySource({
    required this.uri,
    this.uid,
  });

  @override
  String toString() => 'KeySource(uri: $uri, uid: $uid)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeySource &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          uid == other.uid;

  @override
  int get hashCode => Object.hash(uri, uid);
}

/// Pure Dart queue diff engine.
///
/// Computes a minimal edit script (Insert, Remove, Move) that transforms the
/// current queue into the target queue while:
///   - preserving exact order
///   - preserving duplicate entries (occurrence-aware keying)
///   - executing moves based on Longest Increasing Subsequence (LIS)
abstract final class QueueDiffer {
  static const String _occurrenceSep = '#';
  static const String _dupSep = ' dup';

  /// Computes occurrence-aware keys: `"u:<uid>#<n>"` when uid is present,
  /// `"r:<uri>#<n>"` otherwise, where `n` counts prior occurrences.
  static List<String> computeKeys(List<KeySource> items) {
    final occurrence = <String, int>{};
    final keys = <String>[];

    for (final item in items) {
      final uid = item.uid;
      final identity = (uid != null && uid.isNotEmpty) ? 'u:$uid' : 'r:${item.uri}';
      final n = occurrence[identity] ?? 0;
      occurrence[identity] = n + 1;
      keys.add('$identity$_occurrenceSep$n');
    }

    return keys;
  }

  /// Convenience method: compute keys for both sides and diff them.
  static List<QueueEdit> diffSources(List<KeySource> current, List<KeySource> target) {
    return diff(computeKeys(current), computeKeys(target));
  }

  /// Disambiguate duplicate keys by occurrence.
  static List<String> dedupe(List<String> keys) {
    final seen = <String, int>{};
    var duplicated = false;

    for (final k in keys) {
      final n = seen[k] ?? 0;
      if (n > 0) {
        duplicated = true;
        break;
      }
      seen[k] = n + 1;
    }

    if (!duplicated) return keys;

    seen.clear();
    final out = <String>[];
    for (final k in keys) {
      final n = seen[k] ?? 0;
      seen[k] = n + 1;
      out.add(n == 0 ? k : '$k$_dupSep$n');
    }
    return out;
  }

  /// Indices of a longest strictly increasing subsequence of [values].
  /// Patience sorting with predecessor links: O(n log n).
  static List<int> lisIndices(List<int> values) {
    final n = values.length;
    if (n == 0) return const [];

    final tails = List<int>.filled(n, 0);
    final prev = List<int>.filled(n, -1);
    var len = 0;

    for (var i = 0; i < n; i++) {
      var lo = 0;
      var hi = len;
      while (lo < hi) {
        final mid = (lo + hi) >>> 1;
        if (values[tails[mid]] < values[i]) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      prev[i] = lo > 0 ? tails[lo - 1] : -1;
      tails[lo] = i;
      if (lo == len) len++;
    }

    final out = List<int>.filled(len, 0);
    if (len == 0) return const [];
    var k = tails[len - 1];
    for (var p = len - 1; p >= 0; p--) {
      out[p] = k;
      k = prev[k];
    }
    return out;
  }

  /// The provably minimal number of [QueueEditMove]s: `keptCount - |LIS|`.
  static int minimumMoveCount(List<String> current, List<String> target) {
    final cur = dedupe(current);
    final tgt = dedupe(target);
    final targetRank = <String, int>{};
    for (var i = 0; i < tgt.length; i++) {
      targetRank.putIfAbsent(tgt[i], () => i);
    }
    final ranks = <int>[];
    final seen = <String>{};
    for (final k in cur) {
      final r = targetRank[k];
      if (r != null && seen.add(k)) {
        ranks.add(r);
      }
    }
    return ranks.length - lisIndices(ranks).length;
  }

  /// Compute the minimal edit script transforming [current] into [target].
  static List<QueueEdit> diff(List<String> current, List<String> target) {
    if (current.isEmpty && target.isEmpty) return const [];

    final cur = dedupe(current);
    final tgt = dedupe(target);

    final edits = <QueueEdit>[];

    // Target position of each key
    final targetRank = <String, int>{};
    for (var i = 0; i < tgt.length; i++) {
      targetRank.putIfAbsent(tgt[i], () => i);
    }

    // Phase 1: Removals
    // Drop every current key absent from the target. `idx` tracks position in the shrinking list.
    final work = <String>[];
    final kept = <String>{};
    var idx = 0;
    for (final k in cur) {
      if (targetRank.containsKey(k) && kept.add(k)) {
        work.add(k);
        idx++;
      } else {
        edits.add(QueueEditRemove(idx));
      }
    }

    if (tgt.isEmpty) return edits;

    // Phase 2: Choose anchored items that must NOT move (LIS on target ranks)
    final ranks = List<int>.generate(work.length, (i) => targetRank[work[i]]!);
    final anchored = List<bool>.filled(tgt.length, false);
    for (final i in lisIndices(ranks)) {
      anchored[ranks[i]] = true;
    }

    final keyOfRank = List<String?>.filled(tgt.length, null);
    for (var i = 0; i < work.length; i++) {
      keyOfRank[ranks[i]] = work[i];
    }

    // Phase 3: Placement (right-to-left, anchor-relative)
    final pos = <String, int>{};
    for (var i = 0; i < work.length; i++) {
      pos[work[i]] = i;
    }

    for (var j = tgt.length - 1; j >= 0; j--) {
      final anchor = (j + 1 < tgt.length) ? pos[tgt[j + 1]]! : work.length;
      final key = keyOfRank[j];
      if (key == null) {
        edits.add(QueueEditInsert(anchor, j));
        _insertAt(work, pos, anchor, tgt[j]);
      } else if (!anchored[j]) {
        final from = pos[key]!;
        final to = from < anchor ? anchor - 1 : anchor;
        if (from != to) {
          edits.add(QueueEditMove(from, to));
          _moveAt(work, pos, from, to);
        }
      }
    }

    return edits;
  }

  static void _insertAt(List<String> work, Map<String, int> pos, int at, String key) {
    work.insert(at, key);
    for (var i = at; i < work.length; i++) {
      pos[work[i]] = i;
    }
  }

  static void _moveAt(List<String> work, Map<String, int> pos, int from, int to) {
    final moved = work.removeAt(from);
    work.insert(to, moved);
    final lo = min(from, to);
    final hi = max(from, to);
    for (var i = lo; i <= hi; i++) {
      pos[work[i]] = i;
    }
  }

  /// Reference application of an edit script onto a list.
  static List<T> applyEdits<T>(
    List<T> current,
    List<T> target,
    List<QueueEdit> edits,
  ) {
    final work = List<T>.from(current);
    for (final edit in edits) {
      switch (edit) {
        case QueueEditRemove(:final index):
          work.removeAt(index);
        case QueueEditInsert(:final index, :final targetIndex):
          work.insert(index, target[targetIndex]);
        case QueueEditMove(:final from, :final to):
          final moved = work.removeAt(from);
          work.insert(to, moved);
      }
    }
    return work;
  }

  /// Returns true iff [edits] transforms [current] into [target].
  static bool validate(
    List<String> current,
    List<String> target,
    List<QueueEdit> edits,
  ) {
    try {
      final result = applyEdits(current, target, edits);
      if (result.length != target.length) return false;
      for (var i = 0; i < target.length; i++) {
        if (result[i] != target[i]) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
