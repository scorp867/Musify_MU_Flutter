library;

import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import '../proto/playlist_esperanto_proto.dart';

/// 1:1 replica of Spotify's `s77.java` PlaylistService Modify Esperanto client.
class PlaylistModificationClient {
  static const String serviceName =
      'spotify.playlist_esperanto.proto.PlaylistService';
  static const String methodModify = 'Modify';

  final EsperantoTransport _transport;

  const PlaylistModificationClient(this._transport);

  /// Executes modification (add, remove, reorder) on a playlist.
  Future<PlaylistModificationResponse> modify(
      PlaylistModificationRequest request) async {
    final payload = request.writeToBuffer();
    final responseBytes =
        await _transport.callSingle(serviceName, methodModify, payload);
    return PlaylistModificationResponse.fromBuffer(responseBytes);
  }
}
