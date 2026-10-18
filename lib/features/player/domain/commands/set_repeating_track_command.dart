// 1:1 replica of com.spotify.player.model.command.SetRepeatingTrackCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SetRepeatingTrackCommand implements Command {
  final bool value;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetRepeatingTrackCommand({
    required this.value,
    this.options,
    this.loggingParams,
  });

  static SetRepeatingTrackCommand create(bool value) =>
      builder(value).build();

  static SetRepeatingTrackCommandBuilder builder([bool value = false]) =>
      SetRepeatingTrackCommandBuilder(value: value);

  SetRepeatingTrackCommandBuilder toBuilder() =>
      SetRepeatingTrackCommandBuilder(
        value: value,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetRepeatingTrackCommand &&
          other.value == value &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(value, options, loggingParams);

  @override
  String toString() =>
      'SetRepeatingTrackCommand{value=$value, options=$options, loggingParams=$loggingParams}';
}

class SetRepeatingTrackCommandBuilder {
  bool _value;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SetRepeatingTrackCommandBuilder({
    bool value = false,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _value = value,
        _options = options,
        _loggingParams = loggingParams;

  SetRepeatingTrackCommandBuilder value(bool val) {
    _value = val;
    return this;
  }

  SetRepeatingTrackCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SetRepeatingTrackCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SetRepeatingTrackCommand build() => SetRepeatingTrackCommand(
        value: _value,
        options: _options,
        loggingParams: _loggingParams,
      );
}
