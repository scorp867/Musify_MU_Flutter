import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/protocol/generated/spotify/collection/collection_paging.pb.dart'
    as col_pb;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Network layer for library structure endpoints (rootlist, collections,
/// artist decorations). Returns raw bytes. No parsing, no business logic.
class LibraryRemoteSource {
  final SpotifyTransport _webTransport;
  final SpotifyTransport _androidTransport;
  final RuntimeContext _ctx;
  final String _userId;

  const LibraryRemoteSource({
    required SpotifyTransport webTransport,
    required SpotifyTransport androidTransport,
    required RuntimeContext ctx,
    required String userId,
  })  : _webTransport = webTransport,
        _androidTransport = androidTransport,
        _ctx = ctx,
        _userId = userId;

  /// GET rootlist -> raw protobuf bytes.
  Future<Uint8List?> fetchRootlist({CancelToken? cancelToken}) {
    final path =
        '/playlist/v2/user/$_userId/rootlist'
        '?decorate=revision%2Cattributes%2Clength%2Cowner%2Ccapabilities'
        '%2Cstatus_code%2Ctimestamp'
        '&from=0&length=120';

    return _androidTransport.get(
      path,
      tag: 'library_rootlist_$_userId',
      ttl: const Duration(seconds: 45),
      cancelToken: cancelToken,
      extraHeaders: {
        'spotify-playlist-sync-reason': 'CAU=',
        'spotify-dsa-mode-enabled': 'false',
        'spotify-accept-geoblock': 'dummy',
      },
    );
  }

  /// POST collection paging -> raw protobuf bytes.
  Future<Uint8List?> fetchCollection(String setName, {CancelToken? cancelToken}) {
    final request = col_pb.PageRequest()
      ..username = _userId
      ..setName = setName
      ..limit = 150;

    return _webTransport.post(
      '/collection/v2/paging',
      Uint8List.fromList(request.writeToBuffer()),
      tag: 'library_collection_$setName',
      ttl: const Duration(seconds: 45),
      cancelToken: cancelToken,
      contentType: 'application/vnd.collection-v2.spotify.proto',
      extraHeaders: {
        'accept': 'application/vnd.collection-v2.spotify.proto',
      },
    );
  }

  /// POST extended-metadata for artist URIs -> raw protobuf bytes.
  Future<Uint8List?> fetchArtistDecorations(List<String> uris) {
    final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = _ctx.country
        ..catalogue = _ctx.catalogue
        ..taskId = taskId);

    for (final uri in uris) {
      final entityReq = EntityRequest()..entityUri = uri;
      entityReq.query.addAll([
        ExtensionQuery()..extensionKind = ExtensionKind.IDENTITY_TRAIT,
        ExtensionQuery()
          ..extensionKind = ExtensionKind.PUBLISHING_METADATA_TRAIT,
        ExtensionQuery()..extensionKind = ExtensionKind.ARTIST_V4,
      ]);
      request.entityRequest.add(entityReq);
    }

    return _webTransport.post(
      '/extended-metadata/v0/extended-metadata',
      Uint8List.fromList(request.writeToBuffer()),
      priority: NetworkPriority.background,
      tag: 'library_artist_decorations',
      ttl: const Duration(seconds: 45),
    );
  }
}
