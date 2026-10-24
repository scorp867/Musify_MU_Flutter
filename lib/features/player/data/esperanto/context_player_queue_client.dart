import 'dart:async';
import 'dart:typed_data';

import '../../domain/commands/add_to_queue_command.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/player_queue.dart';
import 'esperanto_transport.dart';
import 'queue_proto_mappers.dart';

/// 1:1 replica of Spotify ContextPlayer Queue Client (p.l4v).
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
      return QueueProtoMappers.queueFromBinaryOrJson(bytes);
    });
  }

  /// Appends a track to the queue matching Spotify l4v.a.
  Future<void> addToQueue(AddToQueueCommand command) async {
    final protoReq = QueueProtoMappers.toAddToQueueRequestProto(
      track: command.track,
      options: command.options,
      loggingParams: command.loggingParams,
    );
    final payloadBytes = protoReq.writeToBuffer();

    await callSingle(
      serviceName,
      'AddToQueue',
      payloadBytes,
    );
  }

  /// Atomically updates the entire queue state matching Spotify l4v.b.
  Future<void> setQueue(SetQueueCommand command) async {
    final protoReq = QueueProtoMappers.toSetQueueRequestProto(command);
    final payloadBytes = protoReq.writeToBuffer();

    await callSingle(
      serviceName,
      'SetQueue',
      payloadBytes,
    );
  }
}
