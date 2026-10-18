import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import 'context_track_extensions.dart';

abstract class QueueHelpers {
  /// Builds a SetQueueCommand from a PlayerQueue with overrideRestrictions=true (from Spotify hxl0.a).
  static SetQueueCommand createSetQueueCommand(PlayerQueue playerQueue) {
    return SetQueueCommand.builderFromQueue(playerQueue)
        .options(CommandOptions.builder().overrideRestrictions(true).build())
        .build();
  }

  /// Filters playerQueue.nextTracks returning only context tracks (not queued by user) (from Spotify hxl0.b).
  static List<ContextTrack> getContextTracks(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => !track.isQueued)
        .toList(growable: true);
  }

  /// Filters playerQueue.nextTracks returning only tracks explicitly queued by user (from Spotify hxl0.d).
  static List<ContextTrack> getUserQueuedTracks(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => track.isQueued)
        .toList(growable: true);
  }

  /// Updates the track's metadata to set KEY_IS_QUEUED = isQueued.toString() (from Spotify hxl0.e).
  static ContextTrack setQueuedMetadata(ContextTrack contextTrack, bool isQueued) {
    final updatedMetadata = Map<String, String>.from(contextTrack.metadata);
    updatedMetadata[ContextTrackMetadata.keyIsQueued] = isQueued.toString();
    return contextTrack.toBuilder().metadata(updatedMetadata).build();
  }
}
