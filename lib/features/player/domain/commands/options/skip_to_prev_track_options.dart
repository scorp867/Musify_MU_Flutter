// 1:1 replica of com.spotify.player.model.command.options.SkipToPrevTrackOptions

import 'command_options.dart';

class SkipToPrevTrackOptions {
  static final SkipToPrevTrackOptions empty = builder().build();

  final bool? allowSeeking;
  final CommandOptions commandOptions;

  const SkipToPrevTrackOptions({
    this.allowSeeking,
    this.commandOptions = const CommandOptions(),
  });

  static SkipToPrevTrackOptionsBuilder builder() =>
      SkipToPrevTrackOptionsBuilder();

  SkipToPrevTrackOptionsBuilder toBuilder() => SkipToPrevTrackOptionsBuilder(
        allowSeeking: allowSeeking,
        commandOptions: commandOptions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkipToPrevTrackOptions &&
          other.allowSeeking == allowSeeking &&
          other.commandOptions == commandOptions);

  @override
  int get hashCode => Object.hash(allowSeeking, commandOptions);

  @override
  String toString() =>
      'SkipToPrevTrackOptions{allowSeeking=$allowSeeking, commandOptions=$commandOptions}';
}

class SkipToPrevTrackOptionsBuilder {
  bool? _allowSeeking;
  CommandOptions _commandOptions;

  SkipToPrevTrackOptionsBuilder({
    bool? allowSeeking,
    CommandOptions commandOptions = const CommandOptions(),
  })  : _allowSeeking = allowSeeking,
        _commandOptions = commandOptions;

  SkipToPrevTrackOptionsBuilder allowSeeking(bool? val) {
    _allowSeeking = val;
    return this;
  }

  SkipToPrevTrackOptionsBuilder commandOptions(CommandOptions val) {
    _commandOptions = val;
    return this;
  }

  SkipToPrevTrackOptions build() => SkipToPrevTrackOptions(
        allowSeeking: _allowSeeking,
        commandOptions: _commandOptions,
      );
}
