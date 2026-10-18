// 1:1 replica of com.spotify.player.model.command.SetOptionsCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SetOptionsCommand implements Command {
  final bool? shufflingContext;
  final bool? repeatingContext;
  final bool? repeatingTrack;
  final double? playbackSpeed;
  final Map<String, String> modes;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SetOptionsCommand({
    this.shufflingContext,
    this.repeatingContext,
    this.repeatingTrack,
    this.playbackSpeed,
    this.modes = const <String, String>{},
    this.options,
    this.loggingParams,
  });

  static SetOptionsCommand create() => builder().build();

  static SetOptionsCommandBuilder builder() => SetOptionsCommandBuilder();

  SetOptionsCommandBuilder toBuilder() => SetOptionsCommandBuilder(
        shufflingContext: shufflingContext,
        repeatingContext: repeatingContext,
        repeatingTrack: repeatingTrack,
        playbackSpeed: playbackSpeed,
        modes: modes,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetOptionsCommand &&
          other.shufflingContext == shufflingContext &&
          other.repeatingContext == repeatingContext &&
          other.repeatingTrack == repeatingTrack &&
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
        shufflingContext,
        repeatingContext,
        repeatingTrack,
        playbackSpeed,
        options,
        loggingParams,
        Object.hashAll(modes.entries),
      );

  @override
  String toString() =>
      'SetOptionsCommand{shufflingContext=$shufflingContext, repeatingContext=$repeatingContext, repeatingTrack=$repeatingTrack, playbackSpeed=$playbackSpeed, modes=$modes, options=$options, loggingParams=$loggingParams}';
}

class SetOptionsCommandBuilder {
  bool? _shufflingContext;
  bool? _repeatingContext;
  bool? _repeatingTrack;
  double? _playbackSpeed;
  Map<String, String> _modes;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SetOptionsCommandBuilder({
    bool? shufflingContext,
    bool? repeatingContext,
    bool? repeatingTrack,
    double? playbackSpeed,
    Map<String, String>? modes,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _shufflingContext = shufflingContext,
        _repeatingContext = repeatingContext,
        _repeatingTrack = repeatingTrack,
        _playbackSpeed = playbackSpeed,
        _modes = modes != null ? Map<String, String>.from(modes) : const <String, String>{},
        _options = options,
        _loggingParams = loggingParams;

  SetOptionsCommandBuilder shufflingContext(bool val) {
    _shufflingContext = val;
    return this;
  }

  SetOptionsCommandBuilder repeatingContext(bool val) {
    _repeatingContext = val;
    return this;
  }

  SetOptionsCommandBuilder repeatingTrack(bool val) {
    _repeatingTrack = val;
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
        shufflingContext: _shufflingContext,
        repeatingContext: _repeatingContext,
        repeatingTrack: _repeatingTrack,
        playbackSpeed: _playbackSpeed,
        modes: _modes,
        options: _options,
        loggingParams: _loggingParams,
      );
}
