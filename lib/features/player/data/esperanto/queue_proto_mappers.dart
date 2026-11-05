import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/play_as_next_in_queue_command.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;

/// 1:1 Spotify Queue Protobuf Mappers.
/// Sources of Truth:
/// - dal0.java (case 28: EsQueue -> PlayerQueue)
/// - frl.java (m45004a: EsProvidedTrack -> ContextTrack, m45005b: ContextTrack -> EsContextTrack, m45006c: ContextTrack -> EsProvidedTrack)
/// - qrl1.java (m74301k: CommandOptions -> EsCommandOptions)
/// - ltl1.java (m61228o: LoggingParams -> EsLoggingParams)
/// - n8y.java (line 208: PlayAsNextInQueueCommand -> EsPlayAsNextInQueueRequest)
abstract class QueueProtoMappers {
  /// Converts a binary protobuf ContextTrack to domain ContextTrack (frl.java).
  static ContextTrack fromContextTrackProto(proto.ContextTrack p) {
    final builder = ContextTrack.builder(p.uri);
    final uid = p.uid;
    if (uid.isNotEmpty) {
      builder.uid(uid);
    }
    if (p.metadata.isNotEmpty) {
      builder.metadata(Map<String, String>.from(p.metadata));
    }
    final built = builder.build().toBuilder();
    final prov = p.metadata['provider'];
    if (prov != null && prov.isNotEmpty) {
      built.provider(prov);
    }
    return built.build();
  }

  /// Converts a domain ContextTrack to binary protobuf ContextTrack (frl.m45005b).
  static proto.ContextTrack toContextTrackProto(ContextTrack track) {
    final p = proto.ContextTrack();
    final uri = track.uri;
    if (uri.isNotEmpty) {
      p.uri = uri;
    }
    final uid = track.uid;
    if (uid.isNotEmpty) {
      p.uid = uid;
    }
    final metadata = track.metadata;
    if (metadata.isNotEmpty) {
      p.metadata.addAll(metadata);
    }
    final provider = track.provider;
    if (provider.isNotEmpty) {
      p.metadata['provider'] = provider;
    }
    return p;
  }

  /// Converts a binary protobuf ProvidedTrack to domain ContextTrack (frl.m45004a).
  static ContextTrack fromProvidedTrackProto(proto.ProvidedTrack p) {
    final trackProto = p.contextTrack;
    final builder = ContextTrack.builder(trackProto.uri);
    final uid = trackProto.uid;
    if (uid.isNotEmpty) {
      builder.uid(uid);
    }
    if (trackProto.metadata.isNotEmpty) {
      builder.metadata(Map<String, String>.from(trackProto.metadata));
    }
    final built = builder.build().toBuilder();
    final provider = p.provider;
    if (provider.isNotEmpty) {
      built.provider(provider);
    }
    return built.build();
  }

  /// Converts a domain ContextTrack to binary protobuf ProvidedTrack (frl.m45006c).
  static proto.ProvidedTrack toProvidedTrackProto(ContextTrack track) {
    final p = proto.ProvidedTrack()
      ..contextTrack = toContextTrackProto(track);
    final provider = track.provider;
    if (provider.isNotEmpty) {
      p.provider = provider;
    }
    return p;
  }

  /// Converts a binary protobuf Queue to domain PlayerQueue (dal0.java case 28).
  static PlayerQueue fromQueueProto(proto.Queue p) {
    final builder = PlayerQueue.builder()
        .revision(p.queueRevision.toString());
    if (p.hasTrack()) {
      builder.track(fromProvidedTrackProto(p.track));
    }
    if (p.nextTracks.isNotEmpty) {
      builder.nextTracks(
        p.nextTracks.map(fromProvidedTrackProto).toList(),
      );
    }
    if (p.prevTracks.isNotEmpty) {
      builder.prevTracks(
        p.prevTracks.map(fromProvidedTrackProto).toList(),
      );
    }
    return builder.build();
  }

  /// Converts a domain PlayerQueue to binary protobuf Queue.
  static proto.Queue toQueueProto(PlayerQueue queue) {
    final p = proto.Queue();
    final rev = switch (Int64.tryParseInt(queue.revision)) {
      final r? => r,
      null => Int64.ZERO,
    };
    p.queueRevision = rev;
    final track = queue.track;
    if (track != null) {
      p.track = toProvidedTrackProto(track);
    }
    if (queue.nextTracks.isNotEmpty) {
      p.nextTracks.addAll(queue.nextTracks.map(toProvidedTrackProto));
    }
    if (queue.prevTracks.isNotEmpty) {
      p.prevTracks.addAll(queue.prevTracks.map(toProvidedTrackProto));
    }
    return p;
  }

  /// Converts CommandOptions to binary protobuf CommandOptions (qrl1.m74301k).
  static proto.CommandOptions toCommandOptionsProto(CommandOptions options) {
    final p = proto.CommandOptions();
    if (options.overrideRestrictions case final overrideRestrictions?) {
      p.overrideRestrictions = overrideRestrictions;
    }
    if (options.onlyForPlaybackId case final onlyForPlaybackId?
        when onlyForPlaybackId.isNotEmpty) {
      p.onlyForPlaybackId = utf8.encode(onlyForPlaybackId);
    }
    if (options.systemInitiated case final systemInitiated?) {
      p.systemInitiated = systemInitiated;
    }
    if (options.onlyForLocalDevice case final onlyForLocalDevice?) {
      p.onlyForLocalDevice = onlyForLocalDevice;
    }
    return p;
  }

  /// Converts LoggingParams to binary protobuf LoggingParams (ltl1.m61228o).
  static proto.LoggingParams toLoggingParamsProto(LoggingParams params) {
    final p = proto.LoggingParams();
    if (params.commandInitiatedTime case final cit?) {
      p.commandInitiatedTime = proto.OptionalInt64()..value = Int64(cit);
    }
    if (params.commandReceivedTime case final crt?) {
      p.commandReceivedTime = proto.OptionalInt64()..value = Int64(crt);
    }
    if (params.pageInstanceIds.isNotEmpty) {
      p.pageInstanceIds.addAll(params.pageInstanceIds);
    }
    if (params.interactionIds.isNotEmpty) {
      p.interactionIds.addAll(params.interactionIds);
    }
    return p;
  }

  /// Converts SetQueueCommand to binary protobuf SetQueueRequest.
  static proto.SetQueueRequest toSetQueueRequestProto(SetQueueCommand command) {
    final rev = switch (Int64.tryParseInt(command.queueRevision)) {
      final r? => r,
      null => Int64.ZERO,
    };
    final p = proto.SetQueueRequest()..queueRevision = rev;
    if (command.nextTracks.isNotEmpty) {
      p.nextTracks.addAll(command.nextTracks.map(toProvidedTrackProto));
    }
    if (command.prevTracks.isNotEmpty) {
      p.prevTracks.addAll(command.prevTracks.map(toProvidedTrackProto));
    }
    final options = command.options;
    if (options != null) {
      p.options = toCommandOptionsProto(options);
    }
    final loggingParams = command.loggingParams;
    if (loggingParams != null) {
      p.loggingParams = toLoggingParamsProto(loggingParams);
    }
    return p;
  }

  /// Converts AddToQueueCommand parameters to binary protobuf AddToQueueRequest.
  static proto.AddToQueueRequest toAddToQueueRequestProto({
    required ContextTrack track,
    CommandOptions? options,
    LoggingParams? loggingParams,
  }) {
    final p = proto.AddToQueueRequest()
      ..track = toContextTrackProto(track);
    if (options != null) {
      p.options = toCommandOptionsProto(options);
    }
    if (loggingParams != null) {
      p.loggingParams = toLoggingParamsProto(loggingParams);
    }
    return p;
  }

  /// Converts PlayAsNextInQueueCommand to binary protobuf PlayAsNextInQueueRequest (n8y.java line 208).
  static proto.PlayAsNextInQueueRequest toPlayAsNextInQueueRequestProto(
      PlayAsNextInQueueCommand command) {
    final p = proto.PlayAsNextInQueueRequest();
    if (command.tracks.isNotEmpty) {
      p.tracks.addAll(command.tracks.map(toContextTrackProto));
    }
    final options = command.options;
    if (options != null) {
      p.options = toCommandOptionsProto(options);
    }
    final loggingParams = command.loggingParams;
    if (loggingParams != null) {
      p.loggingParams = toLoggingParamsProto(loggingParams);
    }
    return p;
  }

  /// Decodes a PlayerQueue directly from raw binary Protobuf wire bytes (dal0.java case 28).
  static PlayerQueue fromBuffer(Uint8List bytes) {
    if (bytes.isEmpty) {
      return PlayerQueue.empty;
    }
    return fromQueueProto(proto.Queue.fromBuffer(bytes));
  }
}
