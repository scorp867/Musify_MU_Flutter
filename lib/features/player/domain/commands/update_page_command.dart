// 1:1 replica of com.spotify.player.model.command.UpdatePageCommand

import '../models/context_page.dart';
import 'command.dart';

class UpdatePageCommand implements Command {
  final ContextPage page;

  const UpdatePageCommand({
    required this.page,
  });

  static UpdatePageCommand create(ContextPage page) => builder(page).build();

  static UpdatePageCommandBuilder builder([ContextPage? page]) {
    if (page case final validPage?) {
      return UpdatePageCommandBuilder(page: validPage);
    }
    return UpdatePageCommandBuilder(page: ContextPage.empty);
  }

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

  static UpdatePageCommandBuilder builder() =>
      UpdatePageCommand.builder(ContextPage.empty);

  UpdatePageCommandBuilder page(ContextPage val) {
    _page = val;
    return this;
  }

  UpdatePageCommand build() {
    if (_page case final validPage?) {
      return UpdatePageCommand(page: validPage);
    }
    return UpdatePageCommand(page: ContextPage.empty);
  }
}
