import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';

abstract class QueueProtoMappers {
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
