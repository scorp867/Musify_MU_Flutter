import 'command_options.dart';
import 'context_track.dart';
import 'player_queue.dart';

/// 1:1 with com.spotify.player.model.command.SetQueueCommand
class SetQueueCommand {
  const SetQueueCommand({
    required this.queueRevision,
    required this.nextTracks,
    this.prevTracks = const [],
    this.options = CommandOptions.empty,
  });

  final String queueRevision;
  final List<ContextTrack> nextTracks;
  final List<ContextTrack> prevTracks;
  final CommandOptions options;

  static SetQueueCommandBuilder builder(PlayerQueue playerQueue) {
    return SetQueueCommandBuilder()
      ..queueRevision(playerQueue.revision)
      ..nextTracks(playerQueue.nextTracks)
      ..prevTracks(playerQueue.prevTracks);
  }

  static SetQueueCommandBuilder builderWithTracks(
    String queueRevision,
    List<ContextTrack> nextTracks,
    List<ContextTrack> prevTracks,
  ) {
    return SetQueueCommandBuilder()
      ..queueRevision(queueRevision)
      ..nextTracks(nextTracks)
      ..prevTracks(prevTracks);
  }

  static SetQueueCommand create(PlayerQueue playerQueue) {
    return builder(playerQueue).build();
  }

  Map<String, dynamic> toJson() => {
        'queue_revision': queueRevision,
        'next_tracks': nextTracks.map((t) => t.toJson()).toList(),
        'prev_tracks': prevTracks.map((t) => t.toJson()).toList(),
        'options': options.toJson(),
      };
}

/// 1:1 with com.spotify.player.model.command.SetQueueCommand.Builder
class SetQueueCommandBuilder {
  String _queueRevision = '';
  List<ContextTrack> _nextTracks = const [];
  List<ContextTrack> _prevTracks = const [];
  CommandOptions _options = CommandOptions.empty;

  SetQueueCommandBuilder queueRevision(String queueRevision) {
    _queueRevision = queueRevision;
    return this;
  }

  SetQueueCommandBuilder nextTracks(List<ContextTrack> nextTracks) {
    _nextTracks = nextTracks;
    return this;
  }

  SetQueueCommandBuilder prevTracks(List<ContextTrack> prevTracks) {
    _prevTracks = prevTracks;
    return this;
  }

  SetQueueCommandBuilder options(CommandOptions options) {
    _options = options;
    return this;
  }

  SetQueueCommand build() {
    return SetQueueCommand(
      queueRevision: _queueRevision,
      nextTracks: _nextTracks,
      prevTracks: _prevTracks,
      options: _options,
    );
  }
}
