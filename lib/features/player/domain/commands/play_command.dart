// 1:1 replica of com.spotify.player.model.command.PlayCommand

import '../models/context.dart';
import '../models/play_origin.dart';
import 'command.dart';
import 'options/logging_params.dart';
import 'options/play_options.dart';
import 'options/prepare_play_options.dart';

class PlayCommand implements Command {
  final Context context;
  final PlayOrigin playOrigin;
  final PreparePlayOptions? options;
  final PlayOptions? playOptions;
  final LoggingParams? loggingParams;

  const PlayCommand({
    required this.context,
    required this.playOrigin,
    this.options,
    this.playOptions,
    this.loggingParams,
  });

  static PlayCommand create(Context context, PlayOrigin playOrigin) =>
      builder(context, playOrigin).build();

  static PlayCommandBuilder builder(Context context, PlayOrigin playOrigin) =>
      PlayCommandBuilder(context: context, playOrigin: playOrigin);

  PlayCommandBuilder toBuilder() => PlayCommandBuilder(
        context: context,
        playOrigin: playOrigin,
        options: options,
        playOptions: playOptions,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayCommand &&
          other.context == context &&
          other.playOrigin == playOrigin &&
          other.options == options &&
          other.playOptions == playOptions &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(
        context,
        playOrigin,
        options,
        playOptions,
        loggingParams,
      );

  @override
  String toString() =>
      'PlayCommand{context=$context, playOrigin=$playOrigin, options=$options, playOptions=$playOptions, loggingParams=$loggingParams}';
}

class PlayCommandBuilder {
  Context _context;
  PlayOrigin _playOrigin;
  PreparePlayOptions? _options;
  PlayOptions? _playOptions;
  LoggingParams? _loggingParams;

  PlayCommandBuilder({
    required Context context,
    required PlayOrigin playOrigin,
    PreparePlayOptions? options,
    PlayOptions? playOptions,
    LoggingParams? loggingParams,
  })  : _context = context,
        _playOrigin = playOrigin,
        _options = options,
        _playOptions = playOptions,
        _loggingParams = loggingParams;

  PlayCommandBuilder context(Context val) {
    _context = val;
    return this;
  }

  PlayCommandBuilder playOrigin(PlayOrigin val) {
    _playOrigin = val;
    return this;
  }

  PlayCommandBuilder options(PreparePlayOptions val) {
    _options = val;
    return this;
  }

  PlayCommandBuilder playOptions(PlayOptions val) {
    _playOptions = val;
    return this;
  }

  PlayCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  PlayCommand build() => PlayCommand(
        context: _context,
        playOrigin: _playOrigin,
        options: _options,
        playOptions: _playOptions,
        loggingParams: _loggingParams,
      );
}
