import 'dart:collection';

/// A slot that currently exists in our local forward queue tail (after the current track).
final class LocalSlot {
  final String uri;
  final String? clusterUid;
  final bool clusterGoverned;
  final bool awaitingEcho;
  final int pendingMisses;

  const LocalSlot({
    required this.uri,
    this.clusterUid,
    this.clusterGoverned = false,
    this.awaitingEcho = false,
    this.pendingMisses = 0,
  });

  LocalSlot copyWith({
    String? uri,
    String? clusterUid,
    bool? clusterGoverned,
    bool? awaitingEcho,
    int? pendingMisses,
  }) {
    return LocalSlot(
      uri: uri ?? this.uri,
      clusterUid: clusterUid ?? this.clusterUid,
      clusterGoverned: clusterGoverned ?? this.clusterGoverned,
      awaitingEcho: awaitingEcho ?? this.awaitingEcho,
      pendingMisses: pendingMisses ?? this.pendingMisses,
    );
  }

  @override
  String toString() =>
      'LocalSlot(uri: $uri, clusterUid: $clusterUid, clusterGoverned: $clusterGoverned, awaitingEcho: $awaitingEcho)';
}

/// A playable entry from the audio engine / cluster's next tracks.
final class ClusterSlot {
  final String uri;
  final String? uid;
  final bool isQueued;

  const ClusterSlot({
    required this.uri,
    this.uid,
    this.isQueued = false,
  });

  @override
  String toString() => 'ClusterSlot(uri: $uri, uid: $uid, isQueued: $isQueued)';
}

/// One position in the reconciled target tail.
sealed class TargetSlot {
  const TargetSlot();
}

/// Reuse the existing local slot at [localIndex], preserving its identity.
/// [adoptUid] is non-null when the slot just claimed an engine identity and must record it.
final class TargetSlotKeep extends TargetSlot {
  final int localIndex;
  final String? adoptUid;

  const TargetSlotKeep(this.localIndex, [this.adoptUid]);

  @override
  String toString() => 'TargetSlotKeep(localIndex: $localIndex, adoptUid: $adoptUid)';
}

/// Materialize a new slot from the cluster entry at [clusterIndex].
final class TargetSlotNew extends TargetSlot {
  final int clusterIndex;

  const TargetSlotNew(this.clusterIndex);

  @override
  String toString() => 'TargetSlotNew(clusterIndex: $clusterIndex)';
}

/// Result of reconciling local queue tail against incoming engine tracks.
final class ReconcileResult {
  final List<TargetSlot> target;
  final Set<int> droppedLocalIndices;
  final Set<int> missedEchoLocalIndices;
  final Set<int> echoResolvedLocalIndices;
  final Set<int> claimedClusterIndices;

  const ReconcileResult({
    required this.target,
    required this.droppedLocalIndices,
    required this.missedEchoLocalIndices,
    required this.echoResolvedLocalIndices,
    required this.claimedClusterIndices,
  });
}

/// Pure reconciliation of our LOCAL forward queue tail against engine next tracks.
///
/// Decides what list B should be, preventing duplication of locally-pushed echoes
/// and preventing erroneous deletion of local intent.
abstract final class QueueReconciler {
  static const int defaultMaxPendingMisses = 2;

  /// Reconcile [local] against [cluster].
  static ReconcileResult reconcile({
    required List<LocalSlot> local,
    required List<ClusterSlot> cluster,
    bool clusterAuthoritative = true,
    bool clusterWindowIsPrefix = true,
    int maxPendingMisses = defaultMaxPendingMisses,
  }) {
    if (!clusterAuthoritative) {
      return ReconcileResult(
        target: List<TargetSlot>.generate(local.length, (i) => TargetSlotKeep(i)),
        droppedLocalIndices: const {},
        missedEchoLocalIndices: const {},
        echoResolvedLocalIndices: const {},
        claimedClusterIndices: const {},
      );
    }

    // clusterIndex -> localIndex that owns it, and localIndex -> clusterIndex it claimed.
    final ownerOfCluster = List<int>.filled(cluster.length, -1);
    final claimOfLocal = List<int>.filled(local.length, -1);
    final adoptedUid = List<String?>.filled(local.length, null);

    // Pass 1: exact uid match
    final clusterByUid = <String, Queue<int>>{};
    for (var ci = 0; ci < cluster.length; ci++) {
      final uid = cluster[ci].uid;
      if (uid != null && uid.isNotEmpty) {
        clusterByUid.putIfAbsent(uid, Queue.new).add(ci);
      }
    }

    for (var li = 0; li < local.length; li++) {
      final uid = local[li].clusterUid;
      if (uid == null || uid.isEmpty) continue;
      final candidates = clusterByUid[uid];
      if (candidates == null || candidates.isEmpty) continue;
      final ci = candidates.removeFirst();
      ownerOfCluster[ci] = li;
      claimOfLocal[li] = ci;
    }

    // Pass 2: URI claim (handles echo collapse)
    final unclaimedByUri = <String, List<int>>{};
    for (var ci = 0; ci < cluster.length; ci++) {
      if (ownerOfCluster[ci] == -1) {
        unclaimedByUri.putIfAbsent(cluster[ci].uri, () => <int>[]).add(ci);
      }
    }

    for (var li = 0; li < local.length; li++) {
      if (claimOfLocal[li] != -1) continue;
      final slot = local[li];
      if (!slot.clusterGoverned && !slot.awaitingEcho) continue;

      final candidates = unclaimedByUri[slot.uri];
      if (candidates == null || candidates.isEmpty) continue;

      final preferQueued = slot.awaitingEcho;
      var pickAt = candidates.indexWhere((ci) => cluster[ci].isQueued == preferQueued);
      if (pickAt < 0) pickAt = 0;
      final pick = candidates.removeAt(pickAt);

      ownerOfCluster[pick] = li;
      claimOfLocal[li] = pick;

      final clusterSlotUid = cluster[pick].uid;
      if (clusterSlotUid != null &&
          clusterSlotUid.isNotEmpty &&
          clusterSlotUid != slot.clusterUid) {
        adoptedUid[li] = clusterSlotUid;
      }
    }

    // Establish window bounds
    final lastMatchedLocalIndex = claimOfLocal.lastIndexWhere((ci) => ci != -1);
    bool windowCovers(int li) {
      if (!clusterWindowIsPrefix) return true;
      if (cluster.isEmpty) return true;
      if (lastMatchedLocalIndex < 0) return true;
      return li < lastMatchedLocalIndex;
    }

    // Decide fate of unmatched local slots
    final dropped = <int>{};
    final missedEcho = <int>{};
    final echoResolved = <int>{};
    final localIntentKept = <TargetSlot>[];
    final beyondWindow = <TargetSlot>[];

    for (var li = 0; li < local.length; li++) {
      final slot = local[li];
      if (claimOfLocal[li] != -1) {
        if (slot.awaitingEcho) echoResolved.add(li);
        continue;
      }

      if (slot.clusterGoverned) {
        if (windowCovers(li)) {
          dropped.add(li);
        } else {
          beyondWindow.add(TargetSlotKeep(li));
        }
      } else if (slot.awaitingEcho) {
        if (slot.pendingMisses < maxPendingMisses) {
          missedEcho.add(li);
          localIntentKept.add(TargetSlotKeep(li));
        } else {
          dropped.add(li);
        }
      } else {
        localIntentKept.add(TargetSlotKeep(li));
      }
    }

    // Assemble target: local intent ++ cluster order ++ continuation beyond window
    final target = <TargetSlot>[];
    target.addAll(localIntentKept);
    final claimedClusterIndices = <int>{};

    for (var ci = 0; ci < cluster.length; ci++) {
      final owner = ownerOfCluster[ci];
      if (owner == -1) {
        target.add(TargetSlotNew(ci));
      } else {
        claimedClusterIndices.add(ci);
        target.add(TargetSlotKeep(owner, adoptedUid[owner]));
      }
    }
    target.addAll(beyondWindow);

    return ReconcileResult(
      target: target,
      droppedLocalIndices: dropped,
      missedEchoLocalIndices: missedEcho,
      echoResolvedLocalIndices: echoResolved,
      claimedClusterIndices: claimedClusterIndices,
    );
  }
}
