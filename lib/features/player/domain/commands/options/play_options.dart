// 1:1 replica of com.spotify.player.model.command.options.PlayOptions

import 'command_options.dart';
import 'play_operation.dart';
import 'play_trigger.dart';

class PlayOptions {
  static final PlayOptions empty = builder().build();

  final CommandOptions commandOptions;
  final PlayOperation? operation;
  final PlayTrigger? trigger;

  const PlayOptions({
    this.commandOptions = const CommandOptions(),
    this.operation,
    this.trigger,
  });

  static PlayOptionsBuilder builder() => PlayOptionsBuilder();

  PlayOptionsBuilder toBuilder() => PlayOptionsBuilder(
        commandOptions: commandOptions,
        operation: operation,
        trigger: trigger,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayOptions &&
          other.commandOptions == commandOptions &&
          other.operation == operation &&
          other.trigger == trigger);

  @override
  int get hashCode => Object.hash(commandOptions, operation, trigger);

  @override
  String toString() =>
      'PlayOptions{commandOptions=$commandOptions, operation=$operation, trigger=$trigger}';
}

class PlayOptionsBuilder {
  CommandOptions _commandOptions;
  PlayOperation? _operation;
  PlayTrigger? _trigger;

  PlayOptionsBuilder({
    CommandOptions commandOptions = const CommandOptions(),
    PlayOperation? operation,
    PlayTrigger? trigger,
  })  : _commandOptions = commandOptions,
        _operation = operation,
        _trigger = trigger;

  PlayOptionsBuilder commandOptions(CommandOptions val) {
    _commandOptions = val;
    return this;
  }

  PlayOptionsBuilder operation(PlayOperation val) {
    _operation = val;
    return this;
  }

  PlayOptionsBuilder trigger(PlayTrigger val) {
    _trigger = val;
    return this;
  }

  PlayOptions build() => PlayOptions(
        commandOptions: _commandOptions,
        operation: _operation,
        trigger: _trigger,
      );
}
