import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Network layer for playlist full-fetch and diff endpoints.
/// Returns raw bytes. No parsing, no business logic.
class PlaylistRemoteSource {
  final SpotifyTransport _client;

  const PlaylistRemoteSource({required SpotifyTransport client})
      : _client = client;

  /// GET /playlist/v2/playlist/{id} -> full snapshot bytes.
  Future<Uint8List?> fetchFull(String playlistId, {CancelToken? cancelToken}) {
    return _client.get(
      '/playlist/v2/playlist/$playlistId',
      tag: 'playlist_$playlistId',
      ttl: const Duration(seconds: 45),
      cancelToken: cancelToken,
    );
  }

  /// GET /playlist/v2/playlist/{id}/diff?revision={rev} -> diff bytes.
  Future<Uint8List?> fetchDiff(
    String playlistId,
    String revision, {
    CancelToken? cancelToken,
  }) {
    final encodedRev = Uri.encodeComponent(revision);
    return _client.get(
      '/playlist/v2/playlist/$playlistId/diff'
      '?revision=$encodedRev'
      '&handlesContent=',
      tag: 'playlist_diff_$playlistId',
      ttl: const Duration(seconds: 45),
      cancelToken: cancelToken,
    );
  }
}
