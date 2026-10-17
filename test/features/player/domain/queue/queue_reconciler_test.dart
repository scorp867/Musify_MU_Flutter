import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/domain/queue/queue_reconciler.dart';

void main() {
  group('QueueReconciler Tests', () {
    test('exact uid matching claims cluster slots', () {
      final local = [
        const LocalSlot(uri: 'uri1', clusterUid: 'uid1', clusterGoverned: true),
        const LocalSlot(uri: 'uri2', clusterUid: 'uid2', clusterGoverned: true),
      ];
      final cluster = [
        const ClusterSlot(uri: 'uri2', uid: 'uid2'),
        const ClusterSlot(uri: 'uri1', uid: 'uid1'),
      ];

      final result = QueueReconciler.reconcile(local: local, cluster: cluster);
      expect(result.target.length, equals(2));
      expect(result.target[0], isA<TargetSlotKeep>());
      expect((result.target[0] as TargetSlotKeep).localIndex, equals(1)); // uri2 was local[1]
      expect((result.target[1] as TargetSlotKeep).localIndex, equals(0)); // uri1 was local[0]
      expect(result.droppedLocalIndices, isEmpty);
    });

    test('awaiting echo claims queued cluster slot with same URI', () {
      final local = [
        const LocalSlot(uri: 'uri_add', awaitingEcho: true),
      ];
      final cluster = [
        const ClusterSlot(uri: 'uri_add', uid: 'spotify_assigned_uid', isQueued: true),
      ];

      final result = QueueReconciler.reconcile(local: local, cluster: cluster);
      expect(result.target.length, equals(1));
      expect(result.target[0], isA<TargetSlotKeep>());
      final keep = result.target[0] as TargetSlotKeep;
      expect(keep.localIndex, equals(0));
      expect(keep.adoptUid, equals('spotify_assigned_uid'));
      expect(result.echoResolvedLocalIndices, contains(0));
    });

    test('unmatched cluster-governed slots within window are dropped', () {
      final local = [
        const LocalSlot(uri: 'uri1', clusterUid: 'uid1', clusterGoverned: true),
        const LocalSlot(uri: 'uri_deleted', clusterUid: 'uid_del', clusterGoverned: true),
        const LocalSlot(uri: 'uri2', clusterUid: 'uid2', clusterGoverned: true),
      ];
      final cluster = [
        const ClusterSlot(uri: 'uri1', uid: 'uid1'),
        const ClusterSlot(uri: 'uri2', uid: 'uid2'),
      ];

      final result = QueueReconciler.reconcile(local: local, cluster: cluster);
      expect(result.droppedLocalIndices, contains(1));
      expect(result.target.length, equals(2));
    });
  });
}
