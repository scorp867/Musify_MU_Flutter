// 1:1 replica of com.spotify.player.model.command.StopCommand

import 'command.dart';
import 'options/logging_params.dart';

class StopCommand implements Command {
  final LoggingParams? loggingParams;

  const StopCommand({this.loggingParams});

  static StopCommand create() => builder().build();

  static StopCommandBuilder builder() => StopCommandBuilder();

  StopCommandBuilder toBuilder() =>
      StopCommandBuilder(loggingParams: loggingParams);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopCommand && other.loggingParams == loggingParams);

  @override
  int get hashCode => loggingParams.hashCode;

  @override
  String toString() => 'StopCommand{loggingParams=$loggingParams}';
}

class StopCommandBuilder {
  LoggingParams? _loggingParams;

  StopCommandBuilder({LoggingParams? loggingParams})
      : _loggingParams = loggingParams;

  StopCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  StopCommand build() => StopCommand(loggingParams: _loggingParams);
}
