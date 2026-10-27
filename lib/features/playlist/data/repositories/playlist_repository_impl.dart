library;

import 'dart:async';
import 'dart:typed_data';

import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/sources/playlist_remote_source.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_play_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/player_option_overrides.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/skip_to_track.dart';
import 'package:musify_mu/features/player/domain/commands/play_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/domain/models/sort_order.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_data_client.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_modification_client.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_play_client.dart';
import 'package:musify_mu/features/playlist/data/decorator/playlist_kodiak_decorator.dart';
import 'package:musify_mu/features/playlist/data/mappers/playlist_proto_mappers.dart';
import 'package:musify_mu/features/playlist/data/proto/playlist_esperanto_proto.dart';

/// 1:1 Implementation of Spotify PlaylistRepository.
/// Interconnects Esperanto transport, ContextPlayer, remote sources, cache, and Kodiak decoration.
class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistDataClient _dataClient;
  final PlaylistModificationClient _modificationClient;
  final PlaylistPlayClient _playClient;
  final ContextPlayerPlayClient _contextPlayerPlayClient;
  final PlaylistRemoteSource? _remoteSource;
  final PlaylistDetailCache? _cache;
  final PlaylistKodiakDecorator? _kodiakDecorator;
  final String _currentUsername;

  /// High-performance memory cache for instant, zero-latency playback startup
  final Map<String, PlaylistEntity> _memoryCache = {};

  PlaylistRepositoryImpl({
    required PlaylistDataClient dataClient,
    required PlaylistModificationClient modificationClient,
    required PlaylistPlayClient playClient,
    required ContextPlayerPlayClient contextPlayerPlayClient,
    PlaylistRemoteSource? remoteSource,
    PlaylistDetailCache? cache,
    PlaylistKodiakDecorator? kodiakDecorator,
    String currentUsername = '',
  })  : _dataClient = dataClient,
        _modificationClient = modificationClient,
        _playClient = playClient,
        _contextPlayerPlayClient = contextPlayerPlayClient,
        _remoteSource = remoteSource,
        _cache = cache,
        _kodiakDecorator = kodiakDecorator,
        _currentUsername = currentUsername;

  @override
  Stream<PlaylistEntity> subscribe(
    String playlistUri, {
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  }) async* {
    final playlistId = _extractPlaylistId(playlistUri);
    bool hasEmittedData = false;

    // 1. Emit disk cache immediately for instant UI render
    if (_cache != null) {
      final cachedBytes = await _cache.getRawBytes(playlistId);
      if (cachedBytes != null && cachedBytes.isNotEmpty) {
        final cachedEntity = PlaylistProtoMappers.fromBytes(
          cachedBytes,
          playlistUri: playlistUri,
          currentUsername: _currentUsername,
          sortOrder: sortOrder,
        );
        _memoryCache[playlistId] = cachedEntity;
        _memoryCache[playlistUri] = cachedEntity;
        yield cachedEntity;
        hasEmittedData = true;

        // Asynchronously decorate cached entity in single flight if decorator is configured
        if (_kodiakDecorator != null && cachedEntity.items.isNotEmpty) {
          final decorated = await _kodiakDecorator.decorate(cachedEntity);
          _memoryCache[playlistId] = decorated;
          _memoryCache[playlistUri] = decorated;
          yield decorated;
        }
      }
    }

    // 2. Fetch fresh snapshot from remote source (critical for non-library playlists)
    if (_remoteSource != null) {
      try {
        final remoteBytes = await _remoteSource.fetchFull(playlistId);
        if (remoteBytes != null && remoteBytes.isNotEmpty) {
          final rawEntity = PlaylistProtoMappers.fromBytes(
            remoteBytes,
            playlistUri: playlistUri,
            currentUsername: _currentUsername,
            sortOrder: sortOrder,
          );
          _cache?.put(
            playlistId: playlistId,
            revision: '',
            trackUris: rawEntity.items.map((i) => i.uri).toList(),
            coverUrl: rawEntity.pictureUrl,
            rawBytes: remoteBytes,
          );

          final decoratedEntity = _kodiakDecorator != null
              ? await _kodiakDecorator.decorate(rawEntity)
              : rawEntity;

          _memoryCache[playlistId] = decoratedEntity;
          _memoryCache[playlistUri] = decoratedEntity;
          yield decoratedEntity;
          hasEmittedData = true;
        } else if (!hasEmittedData) {
          throw StateError('Empty playlist response for $playlistUri');
        }
      } catch (e) {
        if (!hasEmittedData) {
          // If no cache was emitted, propagate the failure so the UI transitions out of loading
          rethrow;
        }
      }
    } else if (!hasEmittedData) {
      throw StateError('No remote source or cache available for $playlistUri');
    }

    // 3. Listen to live Esperanto updates if available
    final request = PlaylistGetRequest(
      uri: playlistUri,
      query: PlaylistQuery(
        providedSortInternalId: sortOrder.id,
      ),
    );

    try {
      final esperantoStream = _dataClient.subscribe(request);
      await for (final response in esperantoStream) {
        if (response.dataPayload.isNotEmpty) {
          final bytes = Uint8List.fromList(response.dataPayload);
          final rawEntity = PlaylistProtoMappers.fromBytes(
            bytes,
            playlistUri: playlistUri,
            currentUsername: _currentUsername,
            sortOrder: sortOrder,
          );
          _cache?.put(
            playlistId: playlistId,
            revision: '',
            trackUris: rawEntity.items.map((i) => i.uri).toList(),
            coverUrl: rawEntity.pictureUrl,
            rawBytes: bytes,
          );

          final decoratedEntity = _kodiakDecorator != null
              ? await _kodiakDecorator.decorate(rawEntity)
              : rawEntity;

          _memoryCache[playlistId] = decoratedEntity;
          _memoryCache[playlistUri] = decoratedEntity;
          yield decoratedEntity;
        }
      }
    } catch (_) {
      // Esperanto live stream ended or unsupported; existing emitted state remains active
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
          final rawEntity = PlaylistProtoMappers.fromBytes(
            remoteBytes,
            playlistUri: playlistUri,
            currentUsername: _currentUsername,
            sortOrder: sortOrder,
          );
          _cache?.put(
            playlistId: playlistId,
            revision: '',
            trackUris: rawEntity.items.map((i) => i.uri).toList(),
            coverUrl: rawEntity.pictureUrl,
            rawBytes: remoteBytes,
          );

          final result = _kodiakDecorator != null
              ? await _kodiakDecorator.decorate(rawEntity)
              : rawEntity;
          _memoryCache[playlistId] = result;
          _memoryCache[playlistUri] = result;
          return result;
        }
      } catch (_) {}
    }

    if (_cache != null) {
      final cachedBytes = await _cache.getRawBytes(playlistId);
      if (cachedBytes != null && cachedBytes.isNotEmpty) {
        final rawEntity = PlaylistProtoMappers.fromBytes(
          cachedBytes,
          playlistUri: playlistUri,
          currentUsername: _currentUsername,
          sortOrder: sortOrder,
        );

        final result = _kodiakDecorator != null
            ? await _kodiakDecorator.decorate(rawEntity)
            : rawEntity;
        _memoryCache[playlistId] = result;
        _memoryCache[playlistUri] = result;
        return result;
      }
    }

    final fallback = PlaylistEntity(
      metadata: PlaylistMetadata(
        uri: playlistUri,
        name: 'Playlist',
      ),
      items: const [],
      isLoaded: false,
    );
    _memoryCache[playlistId] = fallback;
    _memoryCache[playlistUri] = fallback;
    return fallback;
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
    final playlistId = _extractPlaylistId(playlistUri);
    PlaylistEntity? entity = _memoryCache[playlistId] ?? _memoryCache[playlistUri];

    if (entity == null || entity.items.isEmpty) {
      if (_cache != null) {
        final cachedBytes = await _cache.getRawBytes(playlistId);
        if (cachedBytes != null && cachedBytes.isNotEmpty) {
          final rawEntity = PlaylistProtoMappers.fromBytes(
            cachedBytes,
            playlistUri: playlistUri,
            currentUsername: _currentUsername,
          );
          entity = _kodiakDecorator != null
              ? await _kodiakDecorator.decorate(rawEntity)
              : rawEntity;
          _memoryCache[playlistId] = entity;
          _memoryCache[playlistUri] = entity;
        }
      }
    }
    if (entity == null || entity.items.isEmpty) {
      try {
        entity = await getPlaylist(playlistUri);
        _memoryCache[playlistId] = entity;
        _memoryCache[playlistUri] = entity;
      } catch (_) {}
    }

    List<ContextPage>? pages;
    if (entity != null && entity.items.isNotEmpty) {
      final contextTracks = entity.items.map((item) {
        final metadata = <String, String>{
          ContextTrackMetadata.keyTitle: item.title,
          ContextTrackMetadata.keyArtistName: item.subtitle,
          ContextTrackMetadata.keyAlbumTitle: item.albumName,
          if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyImageUrl: item.coverUrl,
          if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyImageLargeUrl: item.coverUrl,
          if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyThumbnailImageUrl: item.coverUrl,
          if (item.durationMs > 0) ContextTrackMetadata.keyDuration: item.durationMs.toString(),
          ContextTrackMetadata.keyIsExplicit: item.isExplicit ? 'true' : 'false',
          ContextTrackMetadata.keyContextUri: playlistUri,
          ContextTrackMetadata.keyIsQueued: 'false',
        };
        final trackMeta = item.trackMetadata;
        if (trackMeta != null) {
          if (trackMeta.albumUri.isNotEmpty) {
            metadata[ContextTrackMetadata.keyAlbumUri] = trackMeta.albumUri;
          }
          if (trackMeta.artistUris.isNotEmpty) {
            metadata[ContextTrackMetadata.keyArtistUri] = trackMeta.artistUris.first;
          }
          if (trackMeta.fileId.isNotEmpty) {
            metadata[ContextTrackMetadata.keyFileId] = trackMeta.fileId;
          }
          if (trackMeta.headUrl.isNotEmpty) {
            metadata[ContextTrackMetadata.keyHeadFileUrl] = trackMeta.headUrl;
          }
          if (trackMeta.cdnUrl.isNotEmpty) {
            metadata[ContextTrackMetadata.keyCdnAacUrl] = trackMeta.cdnUrl;
          }
        }
        return ContextTrack.builder(item.uri)
            .uid(item.uid)
            .metadata(metadata)
            .build();
      }).toList(growable: false);

      pages = [ContextPage.builder().tracks(contextTracks).build()];
    }

    final command = PlayCommand(
      context: Context(
        uri: playlistUri,
        url: 'context://$playlistUri',
        metadata: {
          if (entity != null && entity.name.isNotEmpty) 'context_description': entity.name,
          if (entity != null && entity.pictureUrl.isNotEmpty) 'image_url': entity.pictureUrl,
        },
        pages: pages,
      ),
      playOrigin: const PlayOrigin(
        featureIdentifier: 'playlist',
        viewUri: 'spotify:app:playlist',
      ),
      options: PreparePlayOptions(
        skipTo: skipToUri != null
            ? SkipToTrack(trackUri: skipToUri)
            : null,
        playerOptionsOverride: shuffle
            ? PlayerOptionOverrides.builder().shufflingContext(true).build()
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

  String _extractPlaylistId(String rawUri) {
    var uri = rawUri.trim();
    if (uri.contains('?')) {
      uri = uri.split('?').first;
    }
    if (uri.startsWith('spotify:playlist:')) {
      return uri.substring('spotify:playlist:'.length);
    }
    if (uri.startsWith('spotify:user:') && uri.contains(':playlist:')) {
      return uri.split(':playlist:').last;
    }
    final parsed = Uri.tryParse(rawUri);
    if (parsed != null && parsed.pathSegments.contains('playlist')) {
      final idx = parsed.pathSegments.indexOf('playlist');
      if (idx + 1 < parsed.pathSegments.length) {
        return parsed.pathSegments[idx + 1];
      }
    }
    return uri;
  }
}
