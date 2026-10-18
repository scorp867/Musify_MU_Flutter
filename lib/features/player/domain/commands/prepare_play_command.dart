// 1:1 replica of com.spotify.player.model.command.PreparePlayCommand

import '../models/context.dart';
import '../models/play_origin.dart';
import 'command.dart';
import 'options/prepare_play_options.dart';

class PreparePlayCommand implements Command {
  final Context context;
  final PlayOrigin playOrigin;
  final PreparePlayOptions? options;

  const PreparePlayCommand({
    required this.context,
    required this.playOrigin,
    this.options,
  });

  static PreparePlayCommand create(Context context, PlayOrigin playOrigin) =>
      builder(context, playOrigin).build();

  static PreparePlayCommandBuilder builder(Context context, PlayOrigin playOrigin) =>
      PreparePlayCommandBuilder(context: context, playOrigin: playOrigin);

  PreparePlayCommandBuilder toBuilder() => PreparePlayCommandBuilder(
        context: context,
        playOrigin: playOrigin,
        options: options,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreparePlayCommand &&
          other.context == context &&
          other.playOrigin == playOrigin &&
          other.options == options);

  @override
  int get hashCode => Object.hash(context, playOrigin, options);

  @override
  String toString() =>
      'PreparePlayCommand{context=$context, playOrigin=$playOrigin, options=$options}';
}

class PreparePlayCommandBuilder {
  Context _context;
  PlayOrigin _playOrigin;
  PreparePlayOptions? _options;

  PreparePlayCommandBuilder({
    required Context context,
    required PlayOrigin playOrigin,
    PreparePlayOptions? options,
  })  : _context = context,
        _playOrigin = playOrigin,
        _options = options;

  PreparePlayCommandBuilder context(Context val) {
    _context = val;
    return this;
  }

  PreparePlayCommandBuilder playOrigin(PlayOrigin val) {
    _playOrigin = val;
    return this;
  }

  PreparePlayCommandBuilder options(PreparePlayOptions val) {
    _options = val;
    return this;
  }

  PreparePlayCommand build() => PreparePlayCommand(
        context: _context,
        playOrigin: _playOrigin,
        options: _options,
      );
}
