import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/models/error_type.dart';
import '../../domain/models/player_error.dart';
import '../../domain/models/player_state.dart';
import 'esperanto_transport.dart';
import 'player_state_proto_mappers.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;

/// 1:1 replica of Spotify ContextPlayer State Client (p.n4v).
class ContextPlayerStateClient extends EsperantoClientBase {
  static const String serviceName = 'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerStateClient(super.transport);

  /// Subscribes to live PlayerState changes with track capping matching Spotify n4v.b.
  Stream<PlayerState> getStateStream({
    int targetPrevTracksCap = 2,
    int targetNextTracksCap = 2,
  }) {
    if (targetPrevTracksCap < 0 || targetNextTracksCap < 0) {
      throw ArgumentError('Cap under zero');
    }

    final req = proto.GetStateRequest()
      ..prevTracksCap = (proto.OptionalInt64()..value = Int64(targetPrevTracksCap))
      ..nextTracksCap = (proto.OptionalInt64()..value = Int64(targetNextTracksCap));
    final payloadBytes = req.writeToBuffer();

    return callStream(serviceName, 'GetState', payloadBytes).map((bytes) {
      if (bytes.isEmpty) return PlayerState.empty;
      return PlayerStateProtoMappers.playerStateFromBinaryOrJson(bytes);
    });
  }

  /// Subscribes to the live stream of player errors matching Spotify n4v.a.
  Stream<PlayerError> getErrorStream() {
    return callStream(serviceName, 'GetError', Uint8List(0)).map((bytes) {
      if (bytes.isEmpty) return const PlayerError();
      try {
        final jsonMap = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final errorTypeStr = jsonMap['error'] as String? ?? 'SUCCESS';
        final errorType = ErrorType.values.firstWhere(
          (e) => e.name.toLowerCase() == errorTypeStr.toLowerCase(),
          orElse: () => ErrorType.unknown,
        );
        return PlayerError.builder(errorType)
            .trackUri(jsonMap['track_uri'] as String? ?? jsonMap['trackUri'] as String? ?? '')
            .contextUri(jsonMap['context_uri'] as String? ?? jsonMap['contextUri'] as String? ?? '')
            .viewUri(jsonMap['view_uri'] as String? ?? jsonMap['viewUri'] as String? ?? '')
            .reasons(jsonMap['reasons'] as String? ?? '')
            .build();
      } catch (_) {
        return const PlayerError();
      }
    });
  }
}
