// 1:1 replica of com.spotify.player.model.command.SetShufflingContextCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SetShufflingContextCommand implements Command {
  final bool value;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetShufflingContextCommand({
    required this.value,
    this.options,
    this.loggingParams,
  });

  static SetShufflingContextCommand create(bool value) =>
      builder(value).build();

  static SetShufflingContextCommandBuilder builder([bool value = false]) =>
      SetShufflingContextCommandBuilder(value: value);

  SetShufflingContextCommandBuilder toBuilder() =>
      SetShufflingContextCommandBuilder(
        value: value,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetShufflingContextCommand &&
          other.value == value &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(value, options, loggingParams);

  @override
  String toString() =>
      'SetShufflingContextCommand{value=$value, options=$options, loggingParams=$loggingParams}';
}

class SetShufflingContextCommandBuilder {
  bool _value;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SetShufflingContextCommandBuilder({
    bool value = false,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _value = value,
        _options = options,
        _loggingParams = loggingParams;

  SetShufflingContextCommandBuilder value(bool val) {
    _value = val;
    return this;
  }

  SetShufflingContextCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SetShufflingContextCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SetShufflingContextCommand build() => SetShufflingContextCommand(
        value: _value,
        options: _options,
        loggingParams: _loggingParams,
      );
}
