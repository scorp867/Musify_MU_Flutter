// 1:1 replica of com.spotify.player.model.command.PlayAsNextInQueueCommand

import '../models/context_track.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class PlayAsNextInQueueCommand implements Command {
  final List<ContextTrack> tracks;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const PlayAsNextInQueueCommand({
    this.tracks = const <ContextTrack>[],
    this.options,
    this.loggingParams,
  });

  static PlayAsNextInQueueCommand create(List<ContextTrack> tracks) =>
      builder(tracks).build();

  static PlayAsNextInQueueCommandBuilder builder([
    List<ContextTrack> tracks = const <ContextTrack>[],
  ]) =>
      PlayAsNextInQueueCommandBuilder(tracks: tracks);

  PlayAsNextInQueueCommandBuilder toBuilder() =>
      PlayAsNextInQueueCommandBuilder(
        tracks: tracks,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayAsNextInQueueCommand &&
          other.options == options &&
          other.loggingParams == loggingParams &&
          _listEquals(other.tracks, tracks));

  @override
  int get hashCode => Object.hash(
        options,
        loggingParams,
        Object.hashAll(tracks),
      );

  @override
  String toString() =>
      'PlayAsNextInQueueCommand{tracks=$tracks, options=$options, loggingParams=$loggingParams}';

  static bool _listEquals(List<ContextTrack> a, List<ContextTrack> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class PlayAsNextInQueueCommandBuilder {
  List<ContextTrack> _tracks;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  PlayAsNextInQueueCommandBuilder({
    List<ContextTrack> tracks = const <ContextTrack>[],
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _tracks = List<ContextTrack>.from(tracks),
        _options = options,
        _loggingParams = loggingParams;

  PlayAsNextInQueueCommandBuilder tracks(List<ContextTrack> val) {
    _tracks = List<ContextTrack>.from(val);
    return this;
  }

  PlayAsNextInQueueCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  PlayAsNextInQueueCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  PlayAsNextInQueueCommand build() => PlayAsNextInQueueCommand(
        tracks: List<ContextTrack>.unmodifiable(_tracks),
        options: _options,
        loggingParams: _loggingParams,
      );
}
