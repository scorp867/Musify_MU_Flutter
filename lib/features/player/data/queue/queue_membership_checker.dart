// ============================================================================
// 1:1 Replica of Spotify Queue Membership Checker (`p199p/vnl0.java` / `p199p/erl.java`)
// Sources:
// - Decompiled Java:
//   - `p199p/bh10.java:339-361` (partitions `playerQueue.nextTracks()` by `ock1.m68146V`)
//   - `p199p/erl.java:40-69` (`m42237b`: stops at `isDelimiter()` and filters hidden/banned)
//   - `p199p/ock1.java:204-206` (`m68146V`: `isQueued`)
// ============================================================================

import '../../domain/models/player_queue.dart';
import 'queue_track_filter.dart';

abstract class QueueMembershipChecker {
  /// Checks whether a given track URI is currently visible in the user queue
  /// (`playerQueue.nextTracks` partitioned & delimiter-filtered per `bh10.java` + `erl.java`).
  static bool isTrackQueuedByUser(PlayerQueue playerQueue, String trackUri) {
    if (playerQueue.nextTracks.isEmpty) {
      return false;
    }
    final filtered = QueueTrackFilter.partitionAndFilter(playerQueue.nextTracks);
    for (final track in filtered.userQueue) {
      if (track.uri == trackUri) {
        return true;
      }
    }
    return false;
  }
}
