// 1:1 replica of com.spotify.player.model.command.SeekToCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

enum SeekToCommandRelative {
  beginning,
  end,
  current,
}

class SeekToCommand implements Command {
  final int value;
  final SeekToCommandRelative? relative;
  final CommandOptions? options;
  final LoggingParams? loggingParams;
  final int? creatorTimestampPositionMs;

  const SeekToCommand({
    required this.value,
    this.relative,
    this.options,
    this.loggingParams,
    this.creatorTimestampPositionMs,
  });

  static SeekToCommand create(int value) => builder(value).build();

  static SeekToCommandBuilder builder([int value = 0]) =>
      SeekToCommandBuilder(value: value);

  SeekToCommandBuilder toBuilder() => SeekToCommandBuilder(
        value: value,
        relative: relative,
        options: options,
        loggingParams: loggingParams,
        creatorTimestampPositionMs: creatorTimestampPositionMs,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeekToCommand &&
          other.value == value &&
          other.relative == relative &&
          other.options == options &&
          other.loggingParams == loggingParams &&
          other.creatorTimestampPositionMs == creatorTimestampPositionMs);

  @override
  int get hashCode => Object.hash(
        value,
        relative,
        options,
        loggingParams,
        creatorTimestampPositionMs,
      );

  @override
  String toString() =>
      'SeekToCommand{value=$value, relative=$relative, options=$options, loggingParams=$loggingParams, creatorTimestampPositionMs=$creatorTimestampPositionMs}';
}

class SeekToCommandBuilder {
  int _value;
  SeekToCommandRelative? _relative;
  CommandOptions? _options;
  LoggingParams? _loggingParams;
  int? _creatorTimestampPositionMs;

  SeekToCommandBuilder({
    int value = 0,
    SeekToCommandRelative? relative,
    CommandOptions? options,
    LoggingParams? loggingParams,
    int? creatorTimestampPositionMs,
  })  : _value = value,
        _relative = relative,
        _options = options,
        _loggingParams = loggingParams,
        _creatorTimestampPositionMs = creatorTimestampPositionMs;

  SeekToCommandBuilder value(int val) {
    _value = val;
    return this;
  }

  SeekToCommandBuilder relative(SeekToCommandRelative val) {
    _relative = val;
    return this;
  }

  SeekToCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SeekToCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SeekToCommandBuilder creatorTimestampPositionMs(int val) {
    _creatorTimestampPositionMs = val;
    return this;
  }

  SeekToCommand build() => SeekToCommand(
        value: _value,
        relative: _relative,
        options: _options,
        loggingParams: _loggingParams,
        creatorTimestampPositionMs: _creatorTimestampPositionMs,
      );
}
