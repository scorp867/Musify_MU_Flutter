import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import 'context_track_extensions.dart';
import 'queue_helpers.dart';

enum QueueInsertMode {
  /// Play next: inserts tracks at the top of the user queue before existing user-queued tracks.
  playNext,

  /// Add to end of queue: appends tracks at the end of the existing user-queued tracks.
  addToEndOfQueue,
}

abstract class QueueAddHandler {
  /// Adds tracks to nextTracks based on the specified mode with deduplication (from Spotify zfy case 25).
  static PlayerQueue addTracks(
    PlayerQueue playerQueue,
    List<ContextTrack> tracksToAdd, {
    QueueInsertMode mode = QueueInsertMode.addToEndOfQueue,
  }) {
    // 1. Mark all tracksToAdd as queued (is_queued = true)
    final markedTracks = tracksToAdd
        .map((t) => QueueHelpers.setQueuedMetadata(t, true))
        .toList(growable: true);

    if (mode == QueueInsertMode.addToEndOfQueue) {
      // Mode 1 (y == 1): append after existing user queue, before context tracks
      final existingUserQueue = QueueHelpers.getUserQueuedTracks(playerQueue);
      final contextTracks = QueueHelpers.getContextTracks(playerQueue);

      final combined = <ContextTrack>[
        ...existingUserQueue,
        ...markedTracks,
        ...contextTracks,
      ];

      return playerQueue.toBuilder().nextTracks(combined).build();
    } else {
      // Mode 0 (y == 0): Play Next - deduplicate against existing tracks and place at the head of user queue
      final newTrackKeys = markedTracks.map((t) => t.queueKey).toSet();

      final existingUserQueue = QueueHelpers.getUserQueuedTracks(playerQueue)
          .where((t) => !newTrackKeys.contains(t.queueKey))
          .toList(growable: true);

      final contextTracks = QueueHelpers.getContextTracks(playerQueue)
          .where((t) => !newTrackKeys.contains(t.queueKey))
          .toList(growable: true);

      final combined = <ContextTrack>[
        ...markedTracks,
        ...existingUserQueue,
        ...contextTracks,
      ];

      return playerQueue.toBuilder().nextTracks(combined).build();
    }
  }

  /// Creates the SetQueueCommand to update the queue in Esperanto ContextPlayer.
  static SetQueueCommand createAddTracksCommand(
    PlayerQueue playerQueue,
    List<ContextTrack> tracksToAdd, {
    QueueInsertMode mode = QueueInsertMode.addToEndOfQueue,
  }) {
    final updatedQueue = addTracks(playerQueue, tracksToAdd, mode: mode);
    return QueueHelpers.createSetQueueCommand(updatedQueue);
  }
}
