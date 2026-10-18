// 1:1 replica of com.spotify.player.model.command.UpdateContextCommand

import '../models/context.dart';
import 'command.dart';

class UpdateContextCommand implements Command {
  final Context context;

  const UpdateContextCommand({
    required this.context,
  });

  static UpdateContextCommand create(Context context) =>
      builder(context).build();

  static UpdateContextCommandBuilder builder([Context? context]) =>
      UpdateContextCommandBuilder(context: context);

  UpdateContextCommandBuilder toBuilder() =>
      UpdateContextCommandBuilder(context: context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UpdateContextCommand && other.context == context);

  @override
  int get hashCode => context.hashCode;

  @override
  String toString() => 'UpdateContextCommand{context=$context}';
}

class UpdateContextCommandBuilder {
  Context? _context;

  UpdateContextCommandBuilder({Context? context}) : _context = context;

  UpdateContextCommandBuilder context(Context val) {
    _context = val;
    return this;
  }

  UpdateContextCommand build() => UpdateContextCommand(
        context: _context ?? Context.builder('').build(),
      );
}
