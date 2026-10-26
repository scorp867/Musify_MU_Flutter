library;

import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import '../proto/playlist_esperanto_proto.dart';

/// 1:1 replica of Spotify's `wjb0.java` / `s77.java` PlaylistDataService Esperanto client.
class PlaylistDataClient {
  static const String serviceName =
      'spotify.playlist_esperanto.proto.PlaylistDataService';
  static const String methodSubscribe = 'Subscribe';
  static const String methodGet = 'Get';

  final EsperantoTransport _transport;

  const PlaylistDataClient(this._transport);

  /// Subscribes to playlist updates via `PlaylistDataService/Subscribe`.
  /// Emits binary stream of `PlaylistGetResponse`.
  Stream<PlaylistGetResponse> subscribe(PlaylistGetRequest request) {
    final payload = request.writeToBuffer();
    final stream = _transport.callStream(serviceName, methodSubscribe, payload);
    return stream.map((bytes) => PlaylistGetResponse.fromBuffer(bytes));
  }

  /// Single snapshot fetch via `PlaylistDataService/Get`.
  Future<PlaylistGetResponse> get(PlaylistGetRequest request) async {
    final payload = request.writeToBuffer();
    final responseBytes =
        await _transport.callSingle(serviceName, methodGet, payload);
    return PlaylistGetResponse.fromBuffer(responseBytes);
  }
}
