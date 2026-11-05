// 1:1 replica of com.spotify.player.model.command.SetQueueCommand

import '../models/context_track.dart';
import '../models/player_queue.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SetQueueCommand implements Command {
  final String queueRevision;
  final List<ContextTrack> prevTracks;
  final List<ContextTrack> nextTracks;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetQueueCommand({
    required this.queueRevision,
    this.prevTracks = const <ContextTrack>[],
    this.nextTracks = const <ContextTrack>[],
    this.options,
    this.loggingParams,
  });

  static SetQueueCommand create({
    PlayerQueue? playerQueue,
    String? queueRevision,
    List<ContextTrack>? nextTracks,
    List<ContextTrack>? prevTracks,
  }) {
    if (playerQueue case final validQueue?) {
      return builder(playerQueue: validQueue).build();
    }
    return builder(
      queueRevision: queueRevision,
      nextTracks: nextTracks,
      prevTracks: prevTracks,
    ).build();
  }

  static SetQueueCommandBuilder builder({
    PlayerQueue? playerQueue,
    String? queueRevision,
    List<ContextTrack>? nextTracks,
    List<ContextTrack>? prevTracks,
  }) {
    if (playerQueue case final validQueue?) {
      return SetQueueCommandBuilder(
        queueRevision: validQueue.revision,
        nextTracks: validQueue.nextTracks,
        prevTracks: validQueue.prevTracks,
      );
    }
    final rev = switch (queueRevision) {
      final valid? => valid,
      null => '',
    };
    final next = switch (nextTracks) {
      final valid? => valid,
      null => const <ContextTrack>[],
    };
    final prev = switch (prevTracks) {
      final valid? => valid,
      null => const <ContextTrack>[],
    };
    return SetQueueCommandBuilder(
      queueRevision: rev,
      nextTracks: next,
      prevTracks: prev,
    );
  }

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
          _listEquals(other.prevTracks, prevTracks) &&
          _listEquals(other.nextTracks, nextTracks));

  @override
  int get hashCode => Object.hash(
        queueRevision,
        options,
        loggingParams,
        Object.hashAll(prevTracks),
        Object.hashAll(nextTracks),
      );

  @override
  String toString() =>
      'SetQueueCommand{queueRevision=$queueRevision, prevTracks=$prevTracks, nextTracks=$nextTracks, options=$options, loggingParams=$loggingParams}';

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

  static SetQueueCommandBuilder builder() => SetQueueCommand.builder();

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
        prevTracks: List<ContextTrack>.unmodifiable(_prevTracks),
        nextTracks: List<ContextTrack>.unmodifiable(_nextTracks),
        options: _options,
        loggingParams: _loggingParams,
      );
}
