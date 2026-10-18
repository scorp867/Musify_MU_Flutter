// 1:1 replica of com.spotify.player.model.command.UpdatePageCommand

import '../models/context_page.dart';
import 'command.dart';

class UpdatePageCommand implements Command {
  final ContextPage page;

  const UpdatePageCommand({
    required this.page,
  });

  static UpdatePageCommand create(ContextPage page) => builder(page).build();

  static UpdatePageCommandBuilder builder([ContextPage? page]) =>
      UpdatePageCommandBuilder(page: page);

  UpdatePageCommandBuilder toBuilder() => UpdatePageCommandBuilder(page: page);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UpdatePageCommand && other.page == page);

  @override
  int get hashCode => page.hashCode;

  @override
  String toString() => 'UpdatePageCommand{page=$page}';
}

class UpdatePageCommandBuilder {
  ContextPage? _page;

  UpdatePageCommandBuilder({ContextPage? page}) : _page = page;

  UpdatePageCommandBuilder page(ContextPage val) {
    _page = val;
    return this;
  }

  UpdatePageCommand build() => UpdatePageCommand(
        page: _page ?? ContextPage.empty,
      );
}
