import 'package:equatable/equatable.dart';
import 'context_page.dart';

/// 1:1 with Spotify's com.spotify.player.model.command.UpdatePageCommand
class UpdatePageCommand extends Equatable {
  final ContextPage page;

  const UpdatePageCommand({required this.page});

  factory UpdatePageCommand.create(ContextPage page) =>
      UpdatePageCommand(page: page);

  @override
  List<Object?> get props => [page];
}
