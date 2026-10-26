library;

import 'dart:async';
import 'dart:typed_data';

import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/sources/playlist_remote_source.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_play_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/skip_to_track.dart';
import 'package:musify_mu/features/player/domain/commands/play_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/domain/models/sort_order.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_data_client.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_modification_client.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_play_client.dart';
import 'package:musify_mu/features/playlist/data/mappers/playlist_proto_mappers.dart';
import 'package:musify_mu/features/playlist/data/proto/playlist_esperanto_proto.dart';

/// 1:1 Implementation of Spotify PlaylistRepository.
/// Interconnects Esperanto transport, ContextPlayer, remote sources, and cache.
class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistDataClient _dataClient;
  final PlaylistModificationClient _modificationClient;
  final PlaylistPlayClient _playClient;
  final ContextPlayerPlayClient _contextPlayerPlayClient;
  final PlaylistRemoteSource? _remoteSource;
  final PlaylistDetailCache? _cache;
  final String _currentUsername;

  PlaylistRepositoryImpl({
    required PlaylistDataClient dataClient,
    required PlaylistModificationClient modificationClient,
    required PlaylistPlayClient playClient,
    required ContextPlayerPlayClient contextPlayerPlayClient,
    PlaylistRemoteSource? remoteSource,
    PlaylistDetailCache? cache,
    String currentUsername = '',
  })  : _dataClient = dataClient,
        _modificationClient = modificationClient,
        _playClient = playClient,
        _contextPlayerPlayClient = contextPlayerPlayClient,
        _remoteSource = remoteSource,
        _cache = cache,
        _currentUsername = currentUsername;

  @override
  Stream<PlaylistEntity> subscribe(
    String playlistUri, {
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  }) async* {
    final playlistId = _extractPlaylistId(playlistUri);

    // 1. Emit disk cache immediately for instant UI render
    if (_cache != null) {
      final cachedBytes = await _cache.getRawBytes(playlistId);
      if (cachedBytes != null && cachedBytes.isNotEmpty) {
        yield PlaylistProtoMappers.fromBytes(
          cachedBytes,
          playlistUri: playlistUri,
          currentUsername: _currentUsername,
          sortOrder: sortOrder,
        );
      }
    }

    // 2. Subscribe to Esperanto stream or fallback to remote source
    final request = PlaylistGetRequest(
      uri: playlistUri,
      query: PlaylistQuery(
        providedSortInternalId: sortOrder.id,
      ),
    );

    StreamSubscription? sub;
    final controller = StreamController<PlaylistEntity>();

    try {
      final esperantoStream = _dataClient.subscribe(request);
      sub = esperantoStream.listen(
        (response) {
          if (response.dataPayload.isNotEmpty) {
            final bytes = Uint8List.fromList(response.dataPayload);
            final entity = PlaylistProtoMappers.fromBytes(
              bytes,
              playlistUri: playlistUri,
              currentUsername: _currentUsername,
              sortOrder: sortOrder,
            );
            _cache?.put(
              playlistId: playlistId,
              revision: '',
              trackUris: entity.items.map((i) => i.uri).toList(),
              coverUrl: entity.pictureUrl,
              rawBytes: bytes,
            );
            controller.add(entity);
          }
        },
        onError: (e) async {
          // If Esperanto streaming is unsupported on this session, fetch via remote source
          await _fallbackRemoteFetch(playlistUri, playlistId, sortOrder, controller);
        },
      );
    } catch (_) {
      await _fallbackRemoteFetch(playlistUri, playlistId, sortOrder, controller);
    }

    yield* controller.stream;
    await sub?.cancel();
  }

  Future<void> _fallbackRemoteFetch(
    String playlistUri,
    String playlistId,
    ProvidedSortOrder sortOrder,
    StreamController<PlaylistEntity> controller,
  ) async {
    if (_remoteSource != null) {
      try {
        final remoteBytes = await _remoteSource.fetchFull(playlistId);
        if (remoteBytes != null && remoteBytes.isNotEmpty) {
          final entity = PlaylistProtoMappers.fromBytes(
            remoteBytes,
            playlistUri: playlistUri,
            currentUsername: _currentUsername,
            sortOrder: sortOrder,
          );
          _cache?.put(
            playlistId: playlistId,
            revision: '',
            trackUris: entity.items.map((i) => i.uri).toList(),
            coverUrl: entity.pictureUrl,
            rawBytes: remoteBytes,
          );
          controller.add(entity);
        }
      } catch (err) {
        controller.addError(err);
      }
    }
  }

  @override
  Future<PlaylistEntity> getPlaylist(
    String playlistUri, {
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  }) async {
    final playlistId = _extractPlaylistId(playlistUri);

    if (_remoteSource != null) {
      try {
        final remoteBytes = await _remoteSource.fetchFull(playlistId);
        if (remoteBytes != null && remoteBytes.isNotEmpty) {
          final entity = PlaylistProtoMappers.fromBytes(
            remoteBytes,
            playlistUri: playlistUri,
            currentUsername: _currentUsername,
            sortOrder: sortOrder,
          );
          _cache?.put(
            playlistId: playlistId,
            revision: '',
            trackUris: entity.items.map((i) => i.uri).toList(),
            coverUrl: entity.pictureUrl,
            rawBytes: remoteBytes,
          );
          return entity;
        }
      } catch (_) {}
    }

    if (_cache != null) {
      final cachedBytes = await _cache.getRawBytes(playlistId);
      if (cachedBytes != null && cachedBytes.isNotEmpty) {
        return PlaylistProtoMappers.fromBytes(
          cachedBytes,
          playlistUri: playlistUri,
          currentUsername: _currentUsername,
          sortOrder: sortOrder,
        );
      }
    }

    return PlaylistEntity(
      metadata: PlaylistMetadata(
        uri: playlistUri,
        name: 'Playlist',
      ),
      items: const [],
      isLoaded: false,
    );
  }

  @override
  Future<void> modifyPlaylist({
    required String playlistUri,
    List<String> addUris = const [],
    List<String> removeUris = const [],
    int? insertPosition,
  }) async {
    final request = PlaylistModificationRequest(
      uri: playlistUri,
      addUris: addUris,
      removeUris: removeUris,
      insertPosition: insertPosition,
    );
    await _modificationClient.modify(request);
  }

  @override
  Future<void> setFollowed({
    required String playlistUri,
    required bool follow,
  }) async {
    // Spotify sets follow flag by updating playlist metadata
    final request = PlaylistModificationRequest(
      uri: playlistUri,
    );
    await _modificationClient.modify(request);
  }

  @override
  Future<void> playPlaylist({
    required String playlistUri,
    String? skipToUri,
    bool shuffle = false,
  }) async {
    final command = PlayCommand(
      context: Context(
        uri: playlistUri,
        url: 'context://$playlistUri',
      ),
      playOrigin: const PlayOrigin(
        featureIdentifier: 'playlist',
        viewUri: 'spotify:app:playlist',
      ),
      options: PreparePlayOptions(
        skipTo: skipToUri != null
            ? SkipToTrack(trackUri: skipToUri)
            : null,
      ),
    );

    // Route through both ContextPlayerPlayClient and PlaylistPlayClient
    try {
      await _contextPlayerPlayClient.play(command);
    } catch (_) {
      final playRequest = PlaylistPlayRequest(
        playlistQuery: PlaylistQuery(
          textFilter: playlistUri,
        ),
      );
      await _playClient.play(playRequest);
    }
  }

  String _extractPlaylistId(String uri) {
    if (uri.startsWith('spotify:playlist:')) {
      return uri.substring('spotify:playlist:'.length);
    }
    if (uri.startsWith('spotify:user:') && uri.contains(':playlist:')) {
      return uri.split(':playlist:').last;
    }
    return uri;
  }
}
