import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;

abstract class QueueProtoMappers {
  /// Converts a binary protobuf ContextTrack to domain ContextTrack.
  static ContextTrack fromContextTrackProto(proto.ContextTrack p) {
    return ContextTrack.builder(p.uri)
        .uid(p.uid)
        .metadata(Map<String, String>.from(p.metadata))
        .build();
  }

  /// Converts a domain ContextTrack to binary protobuf ContextTrack.
  static proto.ContextTrack toContextTrackProto(ContextTrack track) {
    final p = proto.ContextTrack()
      ..uri = track.uri
      ..uid = track.uid;
    if (track.metadata.isNotEmpty) {
      p.metadata.addAll(track.metadata);
    }
    return p;
  }

  /// Converts a binary protobuf ProvidedTrack to domain ContextTrack.
  static ContextTrack fromProvidedTrackProto(proto.ProvidedTrack p) {
    final builder = p.hasContextTrack()
        ? fromContextTrackProto(p.contextTrack).toBuilder()
        : ContextTrack.builder('');
    if (p.hasProvider() && p.provider.isNotEmpty) {
      builder.provider(p.provider);
    }
    return builder.build();
  }

  /// Converts a domain ContextTrack to binary protobuf ProvidedTrack.
  static proto.ProvidedTrack toProvidedTrackProto(ContextTrack track) {
    final p = proto.ProvidedTrack()
      ..contextTrack = toContextTrackProto(track);
    if (track.provider.isNotEmpty) {
      p.provider = track.provider;
    }
    return p;
  }

  /// Converts a binary protobuf Queue to domain PlayerQueue.
  static PlayerQueue fromQueueProto(proto.Queue p) {
    final builder = PlayerQueue.builder();
    if (p.hasQueueRevision()) {
      builder.revision(p.queueRevision.toString());
    }
    if (p.hasTrack()) {
      builder.track(fromProvidedTrackProto(p.track));
    }
    if (p.nextTracks.isNotEmpty) {
      builder.nextTracks(p.nextTracks.map(fromProvidedTrackProto).toList());
    }
    if (p.prevTracks.isNotEmpty) {
      builder.prevTracks(p.prevTracks.map(fromProvidedTrackProto).toList());
    }
    return builder.build();
  }

  /// Converts a domain PlayerQueue to binary protobuf Queue.
  static proto.Queue toQueueProto(PlayerQueue queue) {
    final p = proto.Queue();
    final rev = int.tryParse(queue.revision) ?? 0;
    p.queueRevision = Int64(rev);
    if (queue.track != null) {
      p.track = toProvidedTrackProto(queue.track!);
    }
    if (queue.nextTracks.isNotEmpty) {
      p.nextTracks.addAll(queue.nextTracks.map(toProvidedTrackProto));
    }
    if (queue.prevTracks.isNotEmpty) {
      p.prevTracks.addAll(queue.prevTracks.map(toProvidedTrackProto));
    }
    return p;
  }

  /// Converts a SetQueueCommand to binary protobuf SetQueueRequest.
  static proto.SetQueueRequest toSetQueueRequestProto(SetQueueCommand command) {
    final p = proto.SetQueueRequest();
    final rev = int.tryParse(command.queueRevision) ?? 0;
    p.queueRevision = Int64(rev);
    if (command.nextTracks.isNotEmpty) {
      p.nextTracks.addAll(command.nextTracks.map(toProvidedTrackProto));
    }
    if (command.prevTracks.isNotEmpty) {
      p.prevTracks.addAll(command.prevTracks.map(toProvidedTrackProto));
    }
    if (command.options != null) {
      final opts = proto.CommandOptions();
      if (command.options!.overrideRestrictions != null) {
        opts.overrideRestrictions = command.options!.overrideRestrictions!;
      }
      if (command.options!.onlyForPlaybackId != null) {
        opts.onlyForPlaybackId = utf8.encode(command.options!.onlyForPlaybackId!);
      }
      if (command.options!.systemInitiated != null) {
        opts.systemInitiated = command.options!.systemInitiated!;
      }
      if (command.options!.onlyForLocalDevice != null) {
        opts.onlyForLocalDevice = command.options!.onlyForLocalDevice!;
      }
      p.options = opts;
    }
    if (command.loggingParams != null) {
      final lp = proto.LoggingParams();
      if (command.loggingParams!.commandInitiatedTime != null) {
        lp.commandInitiatedTime = proto.OptionalInt64()
          ..value = Int64(command.loggingParams!.commandInitiatedTime!);
      }
      if (command.loggingParams!.commandReceivedTime != null) {
        lp.commandReceivedTime = proto.OptionalInt64()
          ..value = Int64(command.loggingParams!.commandReceivedTime!);
      }
      if (command.loggingParams!.pageInstanceIds.isNotEmpty) {
        lp.pageInstanceIds.addAll(command.loggingParams!.pageInstanceIds);
      }
      if (command.loggingParams!.interactionIds.isNotEmpty) {
        lp.interactionIds.addAll(command.loggingParams!.interactionIds);
      }
      p.loggingParams = lp;
    }
    return p;
  }

  /// Converts AddToQueueCommand to binary protobuf AddToQueueRequest.
  static proto.AddToQueueRequest toAddToQueueRequestProto({
    required ContextTrack track,
    CommandOptions? options,
    LoggingParams? loggingParams,
  }) {
    final p = proto.AddToQueueRequest()
      ..track = toContextTrackProto(track);
    if (options != null) {
      final opts = proto.CommandOptions();
      if (options.overrideRestrictions != null) {
        opts.overrideRestrictions = options.overrideRestrictions!;
      }
      if (options.onlyForPlaybackId != null) {
        opts.onlyForPlaybackId = utf8.encode(options.onlyForPlaybackId!);
      }
      if (options.systemInitiated != null) {
        opts.systemInitiated = options.systemInitiated!;
      }
      if (options.onlyForLocalDevice != null) {
        opts.onlyForLocalDevice = options.onlyForLocalDevice!;
      }
      p.options = opts;
    }
    if (loggingParams != null) {
      final lp = proto.LoggingParams();
      if (loggingParams.commandInitiatedTime != null) {
        lp.commandInitiatedTime = proto.OptionalInt64()
          ..value = Int64(loggingParams.commandInitiatedTime!);
      }
      if (loggingParams.commandReceivedTime != null) {
        lp.commandReceivedTime = proto.OptionalInt64()
          ..value = Int64(loggingParams.commandReceivedTime!);
      }
      if (loggingParams.pageInstanceIds.isNotEmpty) {
        lp.pageInstanceIds.addAll(loggingParams.pageInstanceIds);
      }
      if (loggingParams.interactionIds.isNotEmpty) {
        lp.interactionIds.addAll(loggingParams.interactionIds);
      }
      p.loggingParams = lp;
    }
    return p;
  }

  /// Decodes a PlayerQueue from either raw binary Protobuf wire bytes or JSON.
  static PlayerQueue queueFromBinaryOrJson(Uint8List bytes) {
    if (bytes.isEmpty) return PlayerQueue.empty;
    try {
      final p = proto.Queue.fromBuffer(bytes);
      if (p.hasQueueRevision() || p.nextTracks.isNotEmpty || p.hasTrack()) {
        return fromQueueProto(p);
      }
    } catch (_) {
      // Fall through to JSON decoder
    }

    try {
      final jsonMap = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return queueFromProto(jsonMap);
    } catch (_) {
      return PlayerQueue.empty;
    }
  }

  /// Maps a ProvidedTrack structure into a domain ContextTrack (from Spotify t5j.a).
  static ContextTrack providedTrackToContextTrack(Map<String, dynamic> providedTrack) {
    final contextTrackMap = providedTrack['context_track'] as Map<String, dynamic>? ??
        providedTrack['contextTrack'] as Map<String, dynamic>? ??
        providedTrack;

    final uri = contextTrackMap['uri'] as String? ?? '';
    final uid = contextTrackMap['uid'] as String? ?? '';
    final metadataRaw = contextTrackMap['metadata'] as Map<dynamic, dynamic>?;
    final metadata = <String, String>{};
    if (metadataRaw != null) {
      metadataRaw.forEach((k, v) {
        if (k != null && v != null) {
          metadata[k.toString()] = v.toString();
        }
      });
    }

    final provider = providedTrack['provider'] as String? ?? '';

    return ContextTrack.builder(uri)
        .uid(uid)
        .metadata(metadata)
        .provider(provider)
        .build();
  }

  /// Maps a domain ContextTrack into a ContextTrack proto map (from Spotify t5j.b).
  static Map<String, dynamic> contextTrackToProto(ContextTrack track) {
    return {
      if (track.uri.isNotEmpty) 'uri': track.uri,
      if (track.uid.isNotEmpty) 'uid': track.uid,
      if (track.metadata.isNotEmpty) 'metadata': track.metadata,
    };
  }

  /// Maps a domain ContextTrack into a ProvidedTrack proto map.
  static Map<String, dynamic> contextTrackToProvidedTrack(ContextTrack track) {
    return {
      'context_track': contextTrackToProto(track),
      if (track.provider.isNotEmpty) 'provider': track.provider,
    };
  }

  /// Maps an EsQueue protobuf response into a domain PlayerQueue (from Spotify y0c0 case 28).
  static PlayerQueue queueFromProto(Map<String, dynamic> queueProto) {
    final builder = PlayerQueue.builder();

    final revision = queueProto['queue_revision'] ??
        queueProto['queueRevision'] ??
        queueProto['revision'];
    if (revision != null) {
      builder.revision(revision.toString());
    }

    final trackProto = queueProto['track'] as Map<String, dynamic>?;
    if (trackProto != null) {
      builder.track(providedTrackToContextTrack(trackProto));
    }

    final nextTracksList = queueProto['next_tracks'] as List? ??
        queueProto['nextTracks'] as List?;
    if (nextTracksList != null && nextTracksList.isNotEmpty) {
      final nextTracks = nextTracksList
          .map((item) =>
              providedTrackToContextTrack(item as Map<String, dynamic>))
          .toList(growable: true);
      builder.nextTracks(nextTracks);
    }

    final prevTracksList = queueProto['prev_tracks'] as List? ??
        queueProto['prevTracks'] as List?;
    if (prevTracksList != null && prevTracksList.isNotEmpty) {
      final prevTracks = prevTracksList
          .map((item) =>
              providedTrackToContextTrack(item as Map<String, dynamic>))
          .toList(growable: true);
      builder.prevTracks(prevTracks);
    }

    return builder.build();
  }

  /// Maps a SetQueueCommand into a SetQueueRequest proto payload (from Spotify l4v.b).
  static Map<String, dynamic> setQueueCommandToProto(SetQueueCommand command) {
    final revision = int.tryParse(command.queueRevision) ?? 0;

    return {
      'next_tracks': command.nextTracks.map(contextTrackToProvidedTrack).toList(),
      'prev_tracks': command.prevTracks.map(contextTrackToProvidedTrack).toList(),
      'queue_revision': revision,
      if (command.options != null)
        'options': {
          if (command.options!.overrideRestrictions != null)
            'override_restrictions': command.options!.overrideRestrictions,
          if (command.options!.onlyForPlaybackId != null)
            'only_for_playback_id': command.options!.onlyForPlaybackId,
          if (command.options!.systemInitiated != null)
            'system_initiated': command.options!.systemInitiated,
          if (command.options!.onlyForLocalDevice != null)
            'only_for_local_device': command.options!.onlyForLocalDevice,
        },
      if (command.loggingParams != null)
        'logging_params': {
          if (command.loggingParams!.commandId != null)
            'command_id': command.loggingParams!.commandId,
          if (command.loggingParams!.commandInitiatedTime != null)
            'command_initiated_time': command.loggingParams!.commandInitiatedTime,
          if (command.loggingParams!.commandReceivedTime != null)
            'command_received_time': command.loggingParams!.commandReceivedTime,
          if (command.loggingParams!.pageInstanceIds.isNotEmpty)
            'page_instance_ids': command.loggingParams!.pageInstanceIds.toList(),
          if (command.loggingParams!.interactionIds.isNotEmpty)
            'interaction_ids': command.loggingParams!.interactionIds.toList(),
        },
    };
  }

  /// Maps an AddToQueueCommand into an AddToQueueRequest proto payload (from Spotify l4v.a).
  static Map<String, dynamic> addToQueueToProto({
    required ContextTrack track,
    CommandOptions? options,
    LoggingParams? loggingParams,
  }) {
    return {
      'track': contextTrackToProto(track),
      if (options != null)
        'options': {
          if (options.overrideRestrictions != null)
            'override_restrictions': options.overrideRestrictions,
          if (options.onlyForPlaybackId != null)
            'only_for_playback_id': options.onlyForPlaybackId,
          if (options.systemInitiated != null)
            'system_initiated': options.systemInitiated,
          if (options.onlyForLocalDevice != null)
            'only_for_local_device': options.onlyForLocalDevice,
        },
      if (loggingParams != null)
        'logging_params': {
          if (loggingParams.commandId != null)
            'command_id': loggingParams.commandId,
          if (loggingParams.commandInitiatedTime != null)
            'command_initiated_time': loggingParams.commandInitiatedTime,
          if (loggingParams.commandReceivedTime != null)
            'command_received_time': loggingParams.commandReceivedTime,
          if (loggingParams.pageInstanceIds.isNotEmpty)
            'page_instance_ids': loggingParams.pageInstanceIds.toList(),
          if (loggingParams.interactionIds.isNotEmpty)
            'interaction_ids': loggingParams.interactionIds.toList(),
        },
    };
  }
}
