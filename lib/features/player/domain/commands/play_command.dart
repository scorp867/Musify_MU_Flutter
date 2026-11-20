// 1:1 replica of com.spotify.player.model.command.PlayCommand

import 'package:meta/meta.dart';

import '../models/context.dart';
import '../models/play_origin.dart';
import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';
import 'options/play_options.dart';
import 'options/prepare_play_options.dart';

@immutable
class PlayCommand implements Command {
  final Context context;
  final PlayOrigin playOrigin;
  final PreparePlayOptions? options;
  final PlayOptions? playOptions;
  final CommandOptions? commandOptions;
  final LoggingParams? loggingParams;

  const PlayCommand({
    required this.context,
    required this.playOrigin,
    this.options,
    this.playOptions,
    this.commandOptions,
    this.loggingParams,
  });

  static PlayCommand create(Context context, PlayOrigin playOrigin) =>
      builder(context, playOrigin).build();

  static PlayCommandBuilder builder([Context? context, PlayOrigin? playOrigin]) {
    final c = switch (context) {
      final valid? => valid,
      null => Context.builder('').build(),
    };
    final o = switch (playOrigin) {
      final valid? => valid,
      null => PlayOrigin.create(''),
    };
    return PlayCommandBuilder(context: c, playOrigin: o);
  }

  PlayCommandBuilder toBuilder() => PlayCommandBuilder(
        context: context,
        playOrigin: playOrigin,
        options: options,
        playOptions: playOptions,
        commandOptions: commandOptions,
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
          other.commandOptions == commandOptions &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(
        context,
        playOrigin,
        options,
        playOptions,
        commandOptions,
        loggingParams,
      );

  @override
  String toString() =>
      'PlayCommand{context=$context, playOrigin=$playOrigin, options=$options, playOptions=$playOptions, commandOptions=$commandOptions, loggingParams=$loggingParams}';
}

class PlayCommandBuilder {
  Context _context;
  PlayOrigin _playOrigin;
  PreparePlayOptions? _options;
  PlayOptions? _playOptions;
  CommandOptions? _commandOptions;
  LoggingParams? _loggingParams;

  PlayCommandBuilder({
    required Context context,
    required PlayOrigin playOrigin,
    PreparePlayOptions? options,
    PlayOptions? playOptions,
    CommandOptions? commandOptions,
    LoggingParams? loggingParams,
  })  : _context = context,
        _playOrigin = playOrigin,
        _options = options,
        _playOptions = playOptions,
        _commandOptions = commandOptions,
        _loggingParams = loggingParams;

  static PlayCommandBuilder builder() => PlayCommand.builder();

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

  PlayCommandBuilder commandOptions(CommandOptions val) {
    _commandOptions = val;
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
        commandOptions: _commandOptions,
        loggingParams: _loggingParams,
      );
}
