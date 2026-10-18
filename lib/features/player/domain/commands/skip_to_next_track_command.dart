// 1:1 replica of com.spotify.player.model.command.SkipToNextTrackCommand

import '../models/context_track.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SkipToNextTrackCommand implements Command {
  final ContextTrack? track;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SkipToNextTrackCommand({
    this.track,
    this.options,
    this.loggingParams,
  });

  static SkipToNextTrackCommand create() => builder().build();

  static SkipToNextTrackCommandBuilder builder() => SkipToNextTrackCommandBuilder();

  SkipToNextTrackCommandBuilder toBuilder() => SkipToNextTrackCommandBuilder(
        track: track,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkipToNextTrackCommand &&
          other.track == track &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(track, options, loggingParams);

  @override
  String toString() =>
      'SkipToNextTrackCommand{track=$track, options=$options, loggingParams=$loggingParams}';
}

class SkipToNextTrackCommandBuilder {
  ContextTrack? _track;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SkipToNextTrackCommandBuilder({
    ContextTrack? track,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _track = track,
        _options = options,
        _loggingParams = loggingParams;

  SkipToNextTrackCommandBuilder track(ContextTrack val) {
    _track = val;
    return this;
  }

  SkipToNextTrackCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SkipToNextTrackCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SkipToNextTrackCommand build() => SkipToNextTrackCommand(
        track: _track,
        options: _options,
        loggingParams: _loggingParams,
      );
}
