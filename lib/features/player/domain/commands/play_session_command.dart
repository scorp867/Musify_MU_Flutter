// 1:1 replica of com.spotify.player.model.command.PlaySessionCommand

import 'command.dart';
import 'options/logging_params.dart';
import 'options/play_options.dart';

class PlaySessionCommand implements Command {
  final LoggingParams? loggingParams;
  final PlayOptions? playOptions;

  const PlaySessionCommand({
    this.loggingParams,
    this.playOptions,
  });

  static PlaySessionCommand create() => builder().build();

  static PlaySessionCommandBuilder builder() => PlaySessionCommandBuilder();

  PlaySessionCommandBuilder toBuilder() => PlaySessionCommandBuilder(
        loggingParams: loggingParams,
        playOptions: playOptions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySessionCommand &&
          other.loggingParams == loggingParams &&
          other.playOptions == playOptions);

  @override
  int get hashCode => Object.hash(loggingParams, playOptions);

  @override
  String toString() =>
      'PlaySessionCommand{loggingParams=$loggingParams, playOptions=$playOptions}';
}

class PlaySessionCommandBuilder {
  LoggingParams? _loggingParams;
  PlayOptions? _playOptions;

  PlaySessionCommandBuilder({
    LoggingParams? loggingParams,
    PlayOptions? playOptions,
  })  : _loggingParams = loggingParams,
        _playOptions = playOptions;

  PlaySessionCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  PlaySessionCommandBuilder playOptions(PlayOptions val) {
    _playOptions = val;
    return this;
  }

  PlaySessionCommand build() => PlaySessionCommand(
        loggingParams: _loggingParams,
        playOptions: _playOptions,
      );
}
