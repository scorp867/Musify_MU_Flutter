// 1:1 replica of com.spotify.player.model.command.PauseCommand

import '../models/pause_resume_origin.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class PauseCommand implements Command {
  final PauseResumeOrigin? pauseOrigin;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const PauseCommand({
    this.pauseOrigin,
    this.options,
    this.loggingParams,
  });

  static PauseCommand create() => builder().build();

  static PauseCommandBuilder builder() => PauseCommandBuilder();

  PauseCommandBuilder toBuilder() => PauseCommandBuilder(
        pauseOrigin: pauseOrigin,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PauseCommand &&
          other.pauseOrigin == pauseOrigin &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(pauseOrigin, options, loggingParams);

  @override
  String toString() =>
      'PauseCommand{pauseOrigin=$pauseOrigin, options=$options, loggingParams=$loggingParams}';
}

class PauseCommandBuilder {
  PauseResumeOrigin? _pauseOrigin;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  PauseCommandBuilder({
    PauseResumeOrigin? pauseOrigin,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _pauseOrigin = pauseOrigin,
        _options = options,
        _loggingParams = loggingParams;

  PauseCommandBuilder pauseOrigin(PauseResumeOrigin val) {
    _pauseOrigin = val;
    return this;
  }

  PauseCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  PauseCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  PauseCommand build() => PauseCommand(
        pauseOrigin: _pauseOrigin,
        options: _options,
        loggingParams: _loggingParams,
      );
}
