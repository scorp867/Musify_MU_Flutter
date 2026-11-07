import 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_options_client.dart';
import 'package:musify_mu/features/player/domain/commands/pause_command.dart';
import 'package:musify_mu/features/player/domain/commands/play_as_next_in_queue_command.dart';
import 'package:musify_mu/features/player/domain/commands/set_shuffling_context_command.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:musify_mu/features/playlist/presentation/extensions/track_item_metadata_presentation.dart';
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
  }) : _repository = repository,
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

        case PlayContextEffect(
          :final playlistUri,
          :final trackUri,
          :final shuffle,
          :final loggingParams,
        ):
          await _repository.playPlaylist(
            playlistUri: playlistUri,
            skipToUri: trackUri,
            shuffle: shuffle,
            loggingParams: loggingParams,
          );
          return null;

        case PausePlaybackEffect():
          await _controlClient.pause(PauseCommand.create());
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
          return null;

        case ModifyTracksEffect(
          :final playlistUri,
          :final addUris,
          :final removeUris,
        ):
          await _repository.modifyPlaylist(
            playlistUri: playlistUri,
            addUris: addUris,
            removeUris: removeUris,
          );
          final updated = await _repository.getPlaylist(playlistUri);
          return PlaylistLoadedEvent(updated);

        case AddToQueueEffect(:final item, :final loggingParams):
          final track = ContextTrack.builder(item.uri)
              .uid(item.uid.isNotEmpty ? item.uid : item.uri)
              .metadata({
                ContextTrackMetadata.keyTitle: item.title,
                ContextTrackMetadata.keyArtistName: item.subtitle,
                ContextTrackMetadata.keyAlbumTitle: item.albumName,
                if (item.imageXlargeUrl.isNotEmpty)
                  ContextTrackMetadata.keyImageXlargeUrl: item.imageXlargeUrl,
                if (item.imageLargeUrl.isNotEmpty)
                  ContextTrackMetadata.keyImageLargeUrl: item.imageLargeUrl,
                if (item.imageUrl.isNotEmpty)
                  ContextTrackMetadata.keyImageUrl: item.imageUrl,
                if (item.imageSmallUrl.isNotEmpty)
                  ContextTrackMetadata.keyImageSmallUrl: item.imageSmallUrl,
                if (item.durationMs > 0)
                  ContextTrackMetadata.keyDuration: item.durationMs.toString(),
                ContextTrackMetadata.keyIsExplicit: item.isExplicit
                    ? 'true'
                    : 'false',
                ContextTrackMetadata.keyEntityUri: item.uri,
                ContextTrackMetadata.keyIsQueued: 'true',
              })
              .build();
          final builder = PlayAsNextInQueueCommand.builder([track]);
          if (loggingParams case final validLog?) {
            builder.loggingParams(validLog);
          }
          await _controlClient.playAsNextInQueue(builder.build());
          return null;
      }
    } catch (e) {
      return PlaylistErrorEvent(e.toString());
    }
  }
}
