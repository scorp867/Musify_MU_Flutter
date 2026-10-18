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
    final keysToRemove = tracksToRemove.map((t) => t.queueKey).toSet();
    final remainingTracks = playerQueue.nextTracks
        .where((track) => !keysToRemove.contains(track.queueKey))
        .toList(growable: true);

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
