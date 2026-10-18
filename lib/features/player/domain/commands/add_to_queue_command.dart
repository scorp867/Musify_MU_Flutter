// 1:1 replica of com.spotify.player.model.command.AddToQueueCommand

import '../models/context_track.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class AddToQueueCommand implements Command {
  final ContextTrack track;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const AddToQueueCommand({
    required this.track,
    this.options,
    this.loggingParams,
  });

  static AddToQueueCommand create(ContextTrack track) =>
      builder(track).build();

  static AddToQueueCommandBuilder builder(ContextTrack track) =>
      AddToQueueCommandBuilder(track: track);

  AddToQueueCommandBuilder toBuilder() => AddToQueueCommandBuilder(
        track: track,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AddToQueueCommand &&
          other.track == track &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(track, options, loggingParams);

  @override
  String toString() =>
      'AddToQueueCommand{track=$track, options=$options, loggingParams=$loggingParams}';
}

class AddToQueueCommandBuilder {
  ContextTrack _track;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  AddToQueueCommandBuilder({
    required ContextTrack track,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _track = track,
        _options = options,
        _loggingParams = loggingParams;

  AddToQueueCommandBuilder track(ContextTrack val) {
    _track = val;
    return this;
  }

  AddToQueueCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  AddToQueueCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  AddToQueueCommand build() => AddToQueueCommand(
        track: _track,
        options: _options,
        loggingParams: _loggingParams,
      );
}
