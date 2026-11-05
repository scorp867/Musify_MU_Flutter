// 1:1 replica of com.spotify.player.model.command.SetOptionsCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SetOptionsCommand implements Command {
  final bool? repeatingTrack;
  final bool? repeatingContext;
  final bool? shufflingContext;
  final double? playbackSpeed;
  final Map<String, String> modes;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetOptionsCommand({
    this.repeatingTrack,
    this.repeatingContext,
    this.shufflingContext,
    this.playbackSpeed,
    this.modes = const <String, String>{},
    this.options,
    this.loggingParams,
  });

  static SetOptionsCommand create() => builder().build();

  static SetOptionsCommandBuilder builder() => SetOptionsCommandBuilder();

  SetOptionsCommandBuilder toBuilder() => SetOptionsCommandBuilder(
        repeatingTrack: repeatingTrack,
        repeatingContext: repeatingContext,
        shufflingContext: shufflingContext,
        playbackSpeed: playbackSpeed,
        modes: modes,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetOptionsCommand &&
          other.repeatingTrack == repeatingTrack &&
          other.repeatingContext == repeatingContext &&
          other.shufflingContext == shufflingContext &&
          other.playbackSpeed == playbackSpeed &&
          other.options == options &&
          other.loggingParams == loggingParams &&
          _mapsEqual(other.modes, modes));

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        repeatingTrack,
        repeatingContext,
        shufflingContext,
        playbackSpeed,
        options,
        loggingParams,
        Object.hashAll(modes.entries),
      );

  @override
  String toString() =>
      'SetOptionsCommand{repeatingTrack=$repeatingTrack, repeatingContext=$repeatingContext, shufflingContext=$shufflingContext, playbackSpeed=$playbackSpeed, modes=$modes, options=$options, loggingParams=$loggingParams}';
}

class SetOptionsCommandBuilder {
  bool? _repeatingTrack;
  bool? _repeatingContext;
  bool? _shufflingContext;
  double? _playbackSpeed;
  Map<String, String> _modes;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SetOptionsCommandBuilder({
    bool? repeatingTrack,
    bool? repeatingContext,
    bool? shufflingContext,
    double? playbackSpeed,
    Map<String, String>? modes,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _repeatingTrack = repeatingTrack,
        _repeatingContext = repeatingContext,
        _shufflingContext = shufflingContext,
        _playbackSpeed = playbackSpeed,
        _modes = switch (modes) {
          final validModes? => Map<String, String>.from(validModes),
          null => const <String, String>{},
        },
        _options = options,
        _loggingParams = loggingParams;

  static SetOptionsCommandBuilder builder() => SetOptionsCommand.builder();

  SetOptionsCommandBuilder repeatingTrack(bool val) {
    _repeatingTrack = val;
    return this;
  }

  SetOptionsCommandBuilder repeatingContext(bool val) {
    _repeatingContext = val;
    return this;
  }

  SetOptionsCommandBuilder shufflingContext(bool val) {
    _shufflingContext = val;
    return this;
  }

  SetOptionsCommandBuilder playbackSpeed(double val) {
    _playbackSpeed = val;
    return this;
  }

  SetOptionsCommandBuilder modes(Map<String, String> val) {
    _modes = Map<String, String>.unmodifiable(val);
    return this;
  }

  SetOptionsCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SetOptionsCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SetOptionsCommand build() => SetOptionsCommand(
        repeatingTrack: _repeatingTrack,
        repeatingContext: _repeatingContext,
        shufflingContext: _shufflingContext,
        playbackSpeed: _playbackSpeed,
        modes: _modes,
        options: _options,
        loggingParams: _loggingParams,
      );
}
