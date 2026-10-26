library;

import 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_options_client.dart';
import 'package:musify_mu/features/player/domain/commands/resume_command.dart';
import 'package:musify_mu/features/player/domain/commands/set_shuffling_context_command.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'playlist_mobius_types.dart';

/// Mobius effect handler coordinating side-effects for the Playlist state loop.
class PlaylistMobiusEffectHandler
    implements MobiusEffectHandler<PlaylistEffect, PlaylistEvent> {
  final PlaylistRepository _repository;
  final ContextPlayerOptionsClient _optionsClient;
  final ContextPlayerControlClient _controlClient;

  const PlaylistMobiusEffectHandler({
    required PlaylistRepository repository,
    required ContextPlayerOptionsClient optionsClient,
    required ContextPlayerControlClient controlClient,
  })  : _repository = repository,
        _optionsClient = optionsClient,
        _controlClient = controlClient;

  @override
  Future<PlaylistEvent?> handleEffect(PlaylistEffect effect) async {
    try {
      switch (effect) {
        case SubscribePlaylistEffect(:final playlistUri, :final sortOrder):
          final playlist = await _repository.getPlaylist(
            playlistUri,
            sortOrder: sortOrder,
          );
          return PlaylistLoadedEvent(playlist);

        case PlayContextEffect(:final playlistUri, :final trackUri, :final shuffle):
          if (trackUri == null && playlistUri.isNotEmpty) {
            // Resume if currently paused on this playlist context
            try {
              await _controlClient.resume(const ResumeCommand());
              return null;
            } catch (_) {
              // Fallthrough to play context
            }
          }
          await _repository.playPlaylist(
            playlistUri: playlistUri,
            skipToUri: trackUri,
            shuffle: shuffle,
          );
          return null;

        case ToggleShuffleEffect(:final enable):
          await _optionsClient.setShufflingContext(
            SetShufflingContextCommand(value: enable),
          );
          return null;

        case ToggleFollowEffect(:final playlistUri, :final follow):
          await _repository.setFollowed(
            playlistUri: playlistUri,
            follow: follow,
          );
          return null;

        case ToggleDownloadEffect():
          // Offline sync toggle
          return null;

        case ModifyTracksEffect(:final playlistUri, :final addUris, :final removeUris):
          await _repository.modifyPlaylist(
            playlistUri: playlistUri,
            addUris: addUris,
            removeUris: removeUris,
          );
          final updated = await _repository.getPlaylist(playlistUri);
          return PlaylistLoadedEvent(updated);
      }
    } catch (e) {
      return PlaylistErrorEvent(e.toString());
    }
  }
}
