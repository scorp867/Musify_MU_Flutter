// 1:1 replica of com.spotify.player.model.command.SetRepeatingContextCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SetRepeatingContextCommand implements Command {
  final bool value;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetRepeatingContextCommand({
    required this.value,
    this.options,
    this.loggingParams,
  });

  static SetRepeatingContextCommand create(bool value) =>
      builder(value).build();

  static SetRepeatingContextCommandBuilder builder([bool value = false]) =>
      SetRepeatingContextCommandBuilder(value: value);

  SetRepeatingContextCommandBuilder toBuilder() =>
      SetRepeatingContextCommandBuilder(
        value: value,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetRepeatingContextCommand &&
          other.value == value &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(value, options, loggingParams);

  @override
  String toString() =>
      'SetRepeatingContextCommand{value=$value, options=$options, loggingParams=$loggingParams}';
}

class SetRepeatingContextCommandBuilder {
  bool _value;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SetRepeatingContextCommandBuilder({
    bool value = false,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _value = value,
        _options = options,
        _loggingParams = loggingParams;

  SetRepeatingContextCommandBuilder value(bool val) {
    _value = val;
    return this;
  }

  SetRepeatingContextCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SetRepeatingContextCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SetRepeatingContextCommand build() => SetRepeatingContextCommand(
        value: _value,
        options: _options,
        loggingParams: _loggingParams,
      );
}
