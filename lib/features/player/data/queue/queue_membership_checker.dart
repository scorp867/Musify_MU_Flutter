import '../../domain/models/player_queue.dart';
import 'context_track_extensions.dart';

abstract class QueueMembershipChecker {
  /// Checks whether a given track URI is currently queued by the user in nextTracks (from Spotify vnl0.a).
  static bool isTrackQueuedByUser(PlayerQueue playerQueue, String trackUri) {
    if (playerQueue.nextTracks.isEmpty) {
      return false;
    }
    for (final track in playerQueue.nextTracks) {
      if (track.isQueued && track.uri == trackUri) {
        return true;
      }
    }
    return false;
  }
}
