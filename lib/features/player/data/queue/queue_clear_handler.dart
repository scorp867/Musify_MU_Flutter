import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/player_queue.dart';
import 'queue_helpers.dart';

abstract class QueueClearHandler {
  /// Clears user-queued tracks from the queue, preserving only context tracks (from Spotify pml0 case 2).
  static PlayerQueue clearUserQueue(PlayerQueue playerQueue) {
    final contextTracks = QueueHelpers.getContextTracks(playerQueue);
    return playerQueue.toBuilder().nextTracks(contextTracks).build();
  }

  /// Creates the SetQueueCommand to execute the clear operation on Esperanto ContextPlayer.
  static SetQueueCommand createClearQueueCommand(PlayerQueue playerQueue) {
    final clearedQueue = clearUserQueue(playerQueue);
    return QueueHelpers.createSetQueueCommand(clearedQueue);
  }
}
