// 1:1 replica of com.spotify.player.model.command.SetQueueCommand

import '../models/context_track.dart';
import '../models/player_queue.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SetQueueCommand implements Command {
  final String queueRevision;
  final List<ContextTrack> nextTracks;
  final List<ContextTrack> prevTracks;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetQueueCommand({
    required this.queueRevision,
    this.nextTracks = const <ContextTrack>[],
    this.prevTracks = const <ContextTrack>[],
    this.options,
    this.loggingParams,
  });

  static SetQueueCommand create(
    String queueRevision,
    List<ContextTrack> nextTracks,
    List<ContextTrack> prevTracks,
  ) =>
      builder(queueRevision, nextTracks, prevTracks).build();

  static SetQueueCommand fromQueue(PlayerQueue playerQueue) =>
      builderFromQueue(playerQueue).build();

  static SetQueueCommandBuilder builder([
    String queueRevision = '',
    List<ContextTrack> nextTracks = const <ContextTrack>[],
    List<ContextTrack> prevTracks = const <ContextTrack>[],
  ]) =>
      SetQueueCommandBuilder(
        queueRevision: queueRevision,
        nextTracks: nextTracks,
        prevTracks: prevTracks,
      );

  static SetQueueCommandBuilder builderFromQueue(PlayerQueue playerQueue) =>
      SetQueueCommandBuilder(
        queueRevision: playerQueue.revision,
        nextTracks: playerQueue.nextTracks,
        prevTracks: playerQueue.prevTracks,
      );

  SetQueueCommandBuilder toBuilder() => SetQueueCommandBuilder(
        queueRevision: queueRevision,
        nextTracks: nextTracks,
        prevTracks: prevTracks,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetQueueCommand &&
          other.queueRevision == queueRevision &&
          other.options == options &&
          other.loggingParams == loggingParams &&
          _listEquals(other.nextTracks, nextTracks) &&
          _listEquals(other.prevTracks, prevTracks));

  @override
  int get hashCode => Object.hash(
        queueRevision,
        options,
        loggingParams,
        Object.hashAll(nextTracks),
        Object.hashAll(prevTracks),
      );

  @override
  String toString() =>
      'SetQueueCommand{queueRevision=$queueRevision, nextTracks=$nextTracks, prevTracks=$prevTracks, options=$options, loggingParams=$loggingParams}';

  static bool _listEquals(List<ContextTrack> a, List<ContextTrack> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class SetQueueCommandBuilder {
  String _queueRevision;
  List<ContextTrack> _nextTracks;
  List<ContextTrack> _prevTracks;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SetQueueCommandBuilder({
    String queueRevision = '',
    List<ContextTrack> nextTracks = const <ContextTrack>[],
    List<ContextTrack> prevTracks = const <ContextTrack>[],
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _queueRevision = queueRevision,
        _nextTracks = List<ContextTrack>.from(nextTracks),
        _prevTracks = List<ContextTrack>.from(prevTracks),
        _options = options,
        _loggingParams = loggingParams;

  SetQueueCommandBuilder queueRevision(String val) {
    _queueRevision = val;
    return this;
  }

  SetQueueCommandBuilder nextTracks(List<ContextTrack> val) {
    _nextTracks = List<ContextTrack>.from(val);
    return this;
  }

  SetQueueCommandBuilder prevTracks(List<ContextTrack> val) {
    _prevTracks = List<ContextTrack>.from(val);
    return this;
  }

  SetQueueCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SetQueueCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SetQueueCommand build() => SetQueueCommand(
        queueRevision: _queueRevision,
        nextTracks: List<ContextTrack>.unmodifiable(_nextTracks),
        prevTracks: List<ContextTrack>.unmodifiable(_prevTracks),
        options: _options,
        loggingParams: _loggingParams,
      );
}
