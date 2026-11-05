// 1:1 replica of com.spotify.player.model.command.UpdateTrackCommand

import '../models/context_track.dart';
import 'command.dart';

class UpdateTrackCommand implements Command {
  final ContextTrack track;

  const UpdateTrackCommand({
    required this.track,
  });

  static UpdateTrackCommand create(ContextTrack track) => builder(track).build();

  static UpdateTrackCommandBuilder builder([ContextTrack? track]) {
    if (track case final validTrack?) {
      return UpdateTrackCommandBuilder(track: validTrack);
    }
    return UpdateTrackCommandBuilder(track: ContextTrack.create(''));
  }

  UpdateTrackCommandBuilder toBuilder() =>
      UpdateTrackCommandBuilder(track: track);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UpdateTrackCommand && other.track == track);

  @override
  int get hashCode => track.hashCode;

  @override
  String toString() => 'UpdateTrackCommand{track=$track}';
}

class UpdateTrackCommandBuilder {
  ContextTrack? _track;

  UpdateTrackCommandBuilder({ContextTrack? track}) : _track = track;

  static UpdateTrackCommandBuilder builder() =>
      UpdateTrackCommand.builder(ContextTrack.create(''));

  UpdateTrackCommandBuilder track(ContextTrack val) {
    _track = val;
    return this;
  }

  UpdateTrackCommand build() {
    if (_track case final validTrack?) {
      return UpdateTrackCommand(track: validTrack);
    }
    return UpdateTrackCommand(track: ContextTrack.create(''));
  }
}
