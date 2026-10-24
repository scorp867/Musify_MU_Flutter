import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import 'context_track_extensions.dart';
import 'queue_helpers.dart';

abstract class QueueRemoveHandler {
  /// Removes specific tracks from playerQueue.nextTracks using the Spotify compound queueKey (uid+uri+provider+iteration) (from Spotify ycg0 case 19).
  static PlayerQueue removeTracks(
    PlayerQueue playerQueue,
    List<ContextTrack> tracksToRemove,
  ) {
    final remainingTracks = List<ContextTrack>.from(playerQueue.nextTracks);

    for (final trackToRemove in tracksToRemove) {
      final key = trackToRemove.queueKey;
      final index = remainingTracks.indexWhere((t) => t.queueKey == key);
      if (index != -1) {
        remainingTracks.removeAt(index);
      }
    }

    return playerQueue.toBuilder().nextTracks(remainingTracks).build();
  }

  /// Creates the SetQueueCommand to execute the remove operation on Esperanto ContextPlayer.
  static SetQueueCommand createRemoveTracksCommand(
    PlayerQueue playerQueue,
    List<ContextTrack> tracksToRemove,
  ) {
    final updatedQueue = removeTracks(playerQueue, tracksToRemove);
    return QueueHelpers.createSetQueueCommand(updatedQueue);
  }
}
