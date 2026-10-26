library;

import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import '../proto/playlist_esperanto_proto.dart';

/// 1:1 replica of Spotify's `s77.java` PlaylistPlayService Play Esperanto client.
class PlaylistPlayClient {
  static const String serviceName =
      'spotify.playlist_esperanto.proto.PlaylistPlayService';
  static const String methodPlay = 'Play';

  final EsperantoTransport _transport;

  const PlaylistPlayClient(this._transport);

  /// Initiates playback of a playlist context via PlaylistPlayService.
  Future<PlaylistPlayResponse> play(PlaylistPlayRequest request) async {
    final payload = request.writeToBuffer();
    final responseBytes =
        await _transport.callSingle(serviceName, methodPlay, payload);
    return PlaylistPlayResponse.fromBuffer(responseBytes);
  }
}
