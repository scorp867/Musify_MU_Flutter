// 1:1 replica of com.spotify.player.model.command.PlaySessionCommand

import 'command.dart';
import 'options/logging_params.dart';
import 'options/play_options.dart';

class PlaySessionCommand implements Command {
  final PlayOptions? playOptions;
  final LoggingParams? loggingParams;

  const PlaySessionCommand({
    this.playOptions,
    this.loggingParams,
  });

  static PlaySessionCommand create() => builder().build();

  static PlaySessionCommandBuilder builder() => PlaySessionCommandBuilder();

  PlaySessionCommandBuilder toBuilder() => PlaySessionCommandBuilder(
        playOptions: playOptions,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySessionCommand &&
          other.playOptions == playOptions &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(playOptions, loggingParams);

  @override
  String toString() =>
      'PlaySessionCommand{playOptions=$playOptions, loggingParams=$loggingParams}';
}

class PlaySessionCommandBuilder {
  PlayOptions? _playOptions;
  LoggingParams? _loggingParams;

  PlaySessionCommandBuilder({
    PlayOptions? playOptions,
    LoggingParams? loggingParams,
  })  : _playOptions = playOptions,
        _loggingParams = loggingParams;

  static PlaySessionCommandBuilder builder() => PlaySessionCommand.builder();

  PlaySessionCommandBuilder playOptions(PlayOptions val) {
    _playOptions = val;
    return this;
  }

  PlaySessionCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  PlaySessionCommand build() => PlaySessionCommand(
        playOptions: _playOptions,
        loggingParams: _loggingParams,
      );
}
