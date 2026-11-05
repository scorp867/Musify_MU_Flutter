// 1:1 replica of com.spotify.player.model.command.SetSleepTimerCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';
import 'options/timer_type.dart';

class SetSleepTimerCommand implements Command {
  static const String endpointName = 'set_sleep_timer';

  final TimerType timerType;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetSleepTimerCommand({
    required this.timerType,
    this.options,
    this.loggingParams,
  });

  static SetSleepTimerCommand create([TimerType? timerType]) =>
      builder(timerType).build();

  static SetSleepTimerCommandBuilder builder([TimerType? timerType]) {
    if (timerType case final validTimer?) {
      return SetSleepTimerCommandBuilder(timerType: validTimer);
    }
    return SetSleepTimerCommandBuilder(timerType: TimerType.endOfTrack());
  }

  SetSleepTimerCommandBuilder toBuilder() => SetSleepTimerCommandBuilder(
        timerType: timerType,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetSleepTimerCommand &&
          other.timerType == timerType &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(timerType, options, loggingParams);

  @override
  String toString() =>
      'SetSleepTimerCommand{timerType=$timerType, options=$options, loggingParams=$loggingParams}';
}

class SetSleepTimerCommandBuilder {
  TimerType _timerType;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SetSleepTimerCommandBuilder({
    TimerType? timerType,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _timerType = switch (timerType) {
          final validTimer? => validTimer,
          null => TimerType.endOfTrack(),
        },
        _options = options,
        _loggingParams = loggingParams;

  static SetSleepTimerCommandBuilder builder() =>
      SetSleepTimerCommand.builder(TimerType.endOfTrack());

  SetSleepTimerCommandBuilder timerType(TimerType val) {
    _timerType = val;
    return this;
  }

  SetSleepTimerCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SetSleepTimerCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SetSleepTimerCommand build() => SetSleepTimerCommand(
        timerType: _timerType,
        options: _options,
        loggingParams: _loggingParams,
      );
}
