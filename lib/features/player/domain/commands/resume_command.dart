// 1:1 replica of com.spotify.player.model.command.ResumeCommand

import '../models/pause_resume_origin.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class ResumeCommand implements Command {
  final PauseResumeOrigin? resumeOrigin;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const ResumeCommand({
    this.resumeOrigin,
    this.options,
    this.loggingParams,
  });

  static ResumeCommand create() => builder().build();

  static ResumeCommandBuilder builder() => ResumeCommandBuilder();

  ResumeCommandBuilder toBuilder() => ResumeCommandBuilder(
        resumeOrigin: resumeOrigin,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResumeCommand &&
          other.resumeOrigin == resumeOrigin &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(resumeOrigin, options, loggingParams);

  @override
  String toString() =>
      'ResumeCommand{resumeOrigin=$resumeOrigin, options=$options, loggingParams=$loggingParams}';
}

class ResumeCommandBuilder {
  PauseResumeOrigin? _resumeOrigin;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  ResumeCommandBuilder({
    PauseResumeOrigin? resumeOrigin,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _resumeOrigin = resumeOrigin,
        _options = options,
        _loggingParams = loggingParams;

  ResumeCommandBuilder resumeOrigin(PauseResumeOrigin val) {
    _resumeOrigin = val;
    return this;
  }

  ResumeCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  ResumeCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  ResumeCommand build() => ResumeCommand(
        resumeOrigin: _resumeOrigin,
        options: _options,
        loggingParams: _loggingParams,
      );
}
