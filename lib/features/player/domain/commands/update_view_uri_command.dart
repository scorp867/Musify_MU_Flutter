// 1:1 replica of com.spotify.player.model.command.UpdateViewUriCommand

import 'command.dart';

class UpdateViewUriCommand implements Command {
  final String viewUri;

  const UpdateViewUriCommand({
    required this.viewUri,
  });

  static UpdateViewUriCommand create([String viewUri = '']) =>
      builder(viewUri).build();

  static UpdateViewUriCommandBuilder builder([String viewUri = '']) =>
      UpdateViewUriCommandBuilder(viewUri: viewUri);

  UpdateViewUriCommandBuilder toBuilder() =>
      UpdateViewUriCommandBuilder(viewUri: viewUri);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UpdateViewUriCommand && other.viewUri == viewUri);

  @override
  int get hashCode => viewUri.hashCode;

  @override
  String toString() => 'UpdateViewUriCommand{viewUri=$viewUri}';
}

class UpdateViewUriCommandBuilder {
  String _viewUri;

  UpdateViewUriCommandBuilder({String viewUri = ''}) : _viewUri = viewUri;

  UpdateViewUriCommandBuilder viewUri(String val) {
    _viewUri = val;
    return this;
  }

  UpdateViewUriCommand build() => UpdateViewUriCommand(
        viewUri: _viewUri,
      );
}
