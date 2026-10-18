// 1:1 replica of com.spotify.player.model.command.SkipToPrevTrackCommand

import '../models/context_track.dart';
import 'command.dart';
import 'options/logging_params.dart';
import 'options/skip_to_prev_track_options.dart';

class SkipToPrevTrackCommand implements Command {
  final ContextTrack? track;
  final SkipToPrevTrackOptions? options;
  final LoggingParams? loggingParams;

  const SkipToPrevTrackCommand({
    this.track,
    this.options,
    this.loggingParams,
  });

  static SkipToPrevTrackCommand create() => builder().build();

  static SkipToPrevTrackCommandBuilder builder() => SkipToPrevTrackCommandBuilder();

  SkipToPrevTrackCommandBuilder toBuilder() => SkipToPrevTrackCommandBuilder(
        track: track,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkipToPrevTrackCommand &&
          other.track == track &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(track, options, loggingParams);

  @override
  String toString() =>
      'SkipToPrevTrackCommand{track=$track, options=$options, loggingParams=$loggingParams}';
}

class SkipToPrevTrackCommandBuilder {
  ContextTrack? _track;
  SkipToPrevTrackOptions? _options;
  LoggingParams? _loggingParams;

  SkipToPrevTrackCommandBuilder({
    ContextTrack? track,
    SkipToPrevTrackOptions? options,
    LoggingParams? loggingParams,
  })  : _track = track,
        _options = options,
        _loggingParams = loggingParams;

  SkipToPrevTrackCommandBuilder track(ContextTrack val) {
    _track = val;
    return this;
  }

  SkipToPrevTrackCommandBuilder options(SkipToPrevTrackOptions val) {
    _options = val;
    return this;
  }

  SkipToPrevTrackCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SkipToPrevTrackCommand build() => SkipToPrevTrackCommand(
        track: _track,
        options: _options,
        loggingParams: _loggingParams,
      );
}
