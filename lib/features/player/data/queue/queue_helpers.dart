import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import 'context_track_extensions.dart';

abstract class QueueHelpers {
  /// Builds a SetQueueCommand from a PlayerQueue with overrideRestrictions=true (from Spotify xos0.d / hxl0.a).
  static SetQueueCommand createSetQueueCommand(PlayerQueue playerQueue) {
    return SetQueueCommand.builder(playerQueue: playerQueue)
        .options(CommandOptions.builder().overrideRestrictions(true).build())
        .build();
  }

  /// Filters playerQueue.nextTracks returning only context tracks (not queued by user) (from Spotify xos0.a / hxl0.b).
  static List<ContextTrack> getContextTracks(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => !track.isQueued)
        .toList(growable: true);
  }

  /// Filters playerQueue.nextTracks returning only tracks explicitly queued by user (from Spotify xos0.c / hxl0.d).
  static List<ContextTrack> getUserQueuedTracks(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => track.isQueued)
        .toList(growable: true);
  }

  /// Updates the track's metadata to set KEY_IS_QUEUED = isQueued.toString() (from Spotify xos0.e / hxl0.e).
  static ContextTrack setQueuedMetadata(ContextTrack contextTrack, bool isQueued) {
    final updatedMetadata = Map<String, String>.from(contextTrack.metadata);
    updatedMetadata[ContextTrackMetadata.keyIsQueued] = isQueued.toString();
    updatedMetadata['provider'] = isQueued ? 'queue' : 'context';
    return contextTrack.toBuilder()
        .provider(isQueued ? 'queue' : 'context')
        .metadata(updatedMetadata)
        .build();
  }
}
