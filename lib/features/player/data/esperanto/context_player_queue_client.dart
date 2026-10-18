import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/commands/add_to_queue_command.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/player_queue.dart';
import 'esperanto_transport.dart';
import 'queue_proto_mappers.dart';

class ContextPlayerQueueClient extends EsperantoClientBase {
  static const String serviceName = 'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerQueueClient(super.transport);

  /// Subscribes to the live queue stream matching Spotify l4v.c.
  Stream<PlayerQueue> getQueueStream() {
    return callStream(
      serviceName,
      'GetQueue',
      Uint8List(0),
    ).map((bytes) {
      if (bytes.isEmpty) return PlayerQueue.empty;
      final jsonMap = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return QueueProtoMappers.queueFromProto(jsonMap);
    });
  }

  /// Appends a track to the queue matching Spotify l4v.a.
  Future<void> addToQueue(AddToQueueCommand command) async {
    final payloadMap = QueueProtoMappers.addToQueueToProto(
      track: command.track,
      options: command.options,
      loggingParams: command.loggingParams,
    );
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));

    await callSingle(
      serviceName,
      'AddToQueue',
      payloadBytes,
    );
  }

  /// Atomically updates the entire queue state matching Spotify l4v.b.
  Future<void> setQueue(SetQueueCommand command) async {
    final payloadMap = QueueProtoMappers.setQueueCommandToProto(command);
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));

    await callSingle(
      serviceName,
      'SetQueue',
      payloadBytes,
    );
  }
}
