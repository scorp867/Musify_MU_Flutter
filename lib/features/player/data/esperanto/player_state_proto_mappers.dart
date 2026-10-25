import 'dart:convert';
import 'dart:typed_data';

import '../../domain/models/ad_break_context.dart';
import '../../domain/models/audio_stream.dart';
import '../../domain/models/bitrate_level.dart';
import '../../domain/models/bitrate_strategy.dart';
import '../../domain/models/context_index.dart';
import '../../domain/models/file_origin.dart';
import '../../domain/models/format.dart';
import '../../domain/models/hifi_status.dart';
import '../../domain/models/play_origin.dart';
import '../../domain/models/playback_quality.dart';
import '../../domain/models/player_options.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/restrictions.dart';
import '../../domain/models/sleep_timer.dart';
import '../../domain/models/suppressions.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;
import 'queue_proto_mappers.dart';

abstract class PlayerStateProtoMappers {
  /// Converts a binary protobuf ContextPlayerState to domain PlayerState.
  static PlayerState fromContextPlayerStateProto(proto.ContextPlayerState p) {
    final builder = PlayerState.builder();
    if (p.hasTimestamp()) {
      builder.timestamp(p.timestamp.toInt());
    }
    if (p.hasContextUri()) {
      builder.contextUri(p.contextUri);
    }
    if (p.hasContextUrl()) {
      builder.contextUrl(p.contextUrl);
    }
    if (p.hasTrack()) {
      builder.track(QueueProtoMappers.fromProvidedTrackProto(p.track));
    }
    if (p.nextTracks.isNotEmpty) {
      builder.nextTracks(
          p.nextTracks.map(QueueProtoMappers.fromProvidedTrackProto).toList());
    }
    if (p.prevTracks.isNotEmpty) {
      builder.prevTracks(
          p.prevTracks.map(QueueProtoMappers.fromProvidedTrackProto).toList());
    }
    if (p.hasIndex()) {
      builder.index(
          ContextIndex.create(p.index.page.toInt(), p.index.track.toInt()));
    }
    if (p.hasPositionAsOfTimestamp() && p.positionAsOfTimestamp.hasValue()) {
      builder.positionAsOfTimestamp(p.positionAsOfTimestamp.value.toInt());
    }
    if (p.hasDuration() && p.duration.hasValue()) {
      builder.duration(p.duration.value.toInt());
    }
    if (p.hasIsPlaying()) {
      builder.isPlaying(p.isPlaying);
    }
    if (p.hasIsPaused()) {
      builder.isPaused(p.isPaused);
    }
    if (p.hasIsBuffering()) {
      builder.isBuffering(p.isBuffering);
    }
    if (p.hasIsSystemInitiated()) {
      builder.isSystemInitiated(p.isSystemInitiated);
    }
    if (p.hasOptions()) {
      final opts = p.options;
      builder.options(PlayerOptions.builder()
          .shufflingContext(opts.shufflingContext)
          .repeatingContext(opts.repeatingContext)
          .repeatingTrack(opts.repeatingTrack)
          .playbackSpeed(opts.playbackSpeed != 0.0 ? opts.playbackSpeed : 1.0)
          .modes(Map<String, String>.from(opts.modes))
          .build());
    }
    if (p.hasRestrictions()) {
      builder.restrictions(restrictionsFromProtoMessage(p.restrictions));
    }
    if (p.hasContextRestrictions()) {
      builder.contextRestrictions(restrictionsFromProtoMessage(p.contextRestrictions));
    }
    if (p.hasSessionId()) {
      builder.sessionId(p.sessionId);
    }
    if (p.hasSessionCommandId()) {
      builder.sessionCommandId(p.sessionCommandId);
    }
    if (p.hasQueueRevision()) {
      builder.queueRevision(p.queueRevision.toString());
    }
    if (p.contextMetadata.isNotEmpty) {
      builder.contextMetadata(Map<String, String>.from(p.contextMetadata));
    }
    if (p.pageMetadata.isNotEmpty) {
      builder.pageMetadata(Map<String, String>.from(p.pageMetadata));
    }
    if (p.signals.isNotEmpty) {
      builder.signals(List<String>.from(p.signals));
    }
    if (p.suppressions.isNotEmpty) {
      builder.suppressions(Suppressions.create(Set<String>.from(p.suppressions)));
    }
    if (p.hasPlaybackQuality()) {
      final pq = p.playbackQuality;
      builder.playbackQuality(PlaybackQuality.builder()
          .bitrateLevel(BitrateLevel.values.firstWhere(
              (b) => b.index == pq.bitrateLevel.value,
              orElse: () => BitrateLevel.unknown))
          .strategy(BitrateStrategy.values.firstWhere(
              (s) => s.index == pq.strategy.value,
              orElse: () => BitrateStrategy.unknown))
          .targetBitrateLevel(BitrateLevel.values.firstWhere(
              (b) => b.index == pq.targetBitrateLevel.value,
              orElse: () => BitrateLevel.unknown))
          .targetBitrateAvailable(pq.targetBitrateAvailable)
          .hifiStatus(HiFiStatus.values.firstWhere(
              (h) => h.index == pq.hifiStatus.value,
              orElse: () => HiFiStatus.none))
          .build());
    }
    return builder.build();
  }

  /// Decodes PlayerState from either binary Protobuf wire bytes or JSON.
  static PlayerState playerStateFromBinaryOrJson(Uint8List bytes) {
    if (bytes.isEmpty) return PlayerState.empty;
    try {
      final p = proto.ContextPlayerState.fromBuffer(bytes);
      if (p.hasTimestamp() ||
          p.hasContextUri() ||
          p.hasTrack() ||
          p.hasIsPlaying() ||
          p.hasIsPaused()) {
        return fromContextPlayerStateProto(p);
      }
    } catch (_) {
      // Fall through to JSON
    }

    try {
      final jsonMap = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return playerStateFromProto(jsonMap);
    } catch (_) {
      return PlayerState.empty;
    }
  }

  /// Maps a proto.Restrictions protobuf message into domain Restrictions.
  static Restrictions restrictionsFromProtoMessage(proto.Restrictions p) {
    final builder = Restrictions.builder()
      ..disallowPausingReasons(p.disallowPausingReasons.toSet())
      ..disallowResumingReasons(p.disallowResumingReasons.toSet())
      ..disallowSeekingReasons(p.disallowSeekingReasons.toSet())
      ..disallowPeekingPrevReasons(p.disallowPeekingPrevReasons.toSet())
      ..disallowPeekingNextReasons(p.disallowPeekingNextReasons.toSet())
      ..disallowSkippingPrevReasons(p.disallowSkippingPrevReasons.toSet())
      ..disallowSkippingNextReasons(p.disallowSkippingNextReasons.toSet())
      ..disallowTogglingRepeatContextReasons(p.disallowTogglingRepeatContextReasons.toSet())
      ..disallowTogglingRepeatTrackReasons(p.disallowTogglingRepeatTrackReasons.toSet())
      ..disallowTogglingShuffleReasons(p.disallowTogglingShuffleReasons.toSet())
      ..disallowSetQueueReasons(p.disallowSetQueueReasons.toSet())
      ..disallowAddToQueueReasons(p.disallowAddToQueueReasons.toSet())
      ..disallowInterruptingPlaybackReasons(p.disallowInterruptingPlaybackReasons.toSet())
      ..disallowTransferringPlaybackReasons(p.disallowTransferringPlaybackReasons.toSet())
      ..disallowRemoteControlReasons(p.disallowRemoteControlReasons.toSet())
      ..disallowInsertingIntoNextTracksReasons(p.disallowInsertingIntoNextTracksReasons.toSet())
      ..disallowInsertingIntoContextTracksReasons(p.disallowInsertingIntoContextTracksReasons.toSet())
      ..disallowReorderingInNextTracksReasons(p.disallowReorderingInNextTracksReasons.toSet())
      ..disallowReorderingInContextTracksReasons(p.disallowReorderingInContextTracksReasons.toSet())
      ..disallowRemovingFromNextTracksReasons(p.disallowRemovingFromNextTracksReasons.toSet())
      ..disallowRemovingFromContextTracksReasons(p.disallowRemovingFromContextTracksReasons.toSet())
      ..disallowUpdatingContextReasons(p.disallowUpdatingContextReasons.toSet())
      ..disallowSettingPlaybackSpeedReasons(p.disallowSettingPlaybackSpeedReasons.toSet());
    return builder.build();
  }

  /// Maps an EsRestrictions protobuf structure into domain Restrictions (from Spotify fat0.a).
  static Restrictions restrictionsFromProto(Map<String, dynamic>? proto) {
    if (proto == null) return Restrictions.empty;

    Set<String> parseReasons(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toSet();
      }
      return const {};
    }

    final builder = Restrictions.builder()
      ..disallowPausingReasons(parseReasons(proto['disallow_pausing_reasons'] ?? proto['disallowPausingReasons']))
      ..disallowResumingReasons(parseReasons(proto['disallow_resuming_reasons'] ?? proto['disallowResumingReasons']))
      ..disallowSeekingReasons(parseReasons(proto['disallow_seeking_reasons'] ?? proto['disallowSeekingReasons']))
      ..disallowPeekingPrevReasons(parseReasons(proto['disallow_peeking_prev_reasons'] ?? proto['disallowPeekingPrevReasons']))
      ..disallowPeekingNextReasons(parseReasons(proto['disallow_peeking_next_reasons'] ?? proto['disallowPeekingNextReasons']))
      ..disallowSkippingPrevReasons(parseReasons(proto['disallow_skipping_prev_reasons'] ?? proto['disallowSkippingPrevReasons']))
      ..disallowSkippingNextReasons(parseReasons(proto['disallow_skipping_next_reasons'] ?? proto['disallowSkippingNextReasons']))
      ..disallowSwipePrevReasons(parseReasons(proto['disallow_swipe_prev_reasons'] ?? proto['disallowSwipePrevReasons']))
      ..disallowSwipeNextReasons(parseReasons(proto['disallow_swipe_next_reasons'] ?? proto['disallowSwipeNextReasons']))
      ..disallowTogglingRepeatContextReasons(parseReasons(proto['disallow_toggling_repeat_context_reasons'] ?? proto['disallowTogglingRepeatContextReasons']))
      ..disallowTogglingRepeatTrackReasons(parseReasons(proto['disallow_toggling_repeat_track_reasons'] ?? proto['disallowTogglingRepeatTrackReasons']))
      ..disallowTogglingShuffleReasons(parseReasons(proto['disallow_toggling_shuffle_reasons'] ?? proto['disallowTogglingShuffleReasons']))
      ..disallowSetQueueReasons(parseReasons(proto['disallow_set_queue_reasons'] ?? proto['disallowSetQueueReasons']))
      ..disallowAddToQueueReasons(parseReasons(proto['disallow_add_to_queue_reasons'] ?? proto['disallowAddToQueueReasons']))
      ..disallowAddToQueueTrackReasons(parseReasons(proto['disallow_add_to_queue_track_reasons'] ?? proto['disallowAddToQueueTrackReasons']))
      ..disallowInterruptingPlaybackReasons(parseReasons(proto['disallow_interrupting_playback_reasons'] ?? proto['disallowInterruptingPlaybackReasons']))
      ..disallowTransferringPlaybackReasons(parseReasons(proto['disallow_transferring_playback_reasons'] ?? proto['disallowTransferringPlaybackReasons']))
      ..disallowRemoteControlReasons(parseReasons(proto['disallow_remote_control_reasons'] ?? proto['disallowRemoteControlReasons']))
      ..disallowInsertingIntoNextTracksReasons(parseReasons(proto['disallow_inserting_into_next_tracks_reasons'] ?? proto['disallowInsertingIntoNextTracksReasons']))
      ..disallowInsertingIntoContextTracksReasons(parseReasons(proto['disallow_inserting_into_context_tracks_reasons'] ?? proto['disallowInsertingIntoContextTracksReasons']))
      ..disallowReorderingInNextTracksReasons(parseReasons(proto['disallow_reordering_in_next_tracks_reasons'] ?? proto['disallowReorderingInNextTracksReasons']))
      ..disallowReorderingInContextTracksReasons(parseReasons(proto['disallow_reordering_in_context_tracks_reasons'] ?? proto['disallowReorderingInContextTracksReasons']))
      ..disallowRemovingFromNextTracksReasons(parseReasons(proto['disallow_removing_from_next_tracks_reasons'] ?? proto['disallowRemovingFromNextTracksReasons']))
      ..disallowRemovingFromContextTracksReasons(parseReasons(proto['disallow_removing_from_context_tracks_reasons'] ?? proto['disallowRemovingFromContextTracksReasons']))
      ..disallowUpdatingContextReasons(parseReasons(proto['disallow_updating_context_reasons'] ?? proto['disallowUpdatingContextReasons']))
      ..disallowSettingPlaybackSpeedReasons(parseReasons(proto['disallow_setting_playback_speed_reasons'] ?? proto['disallowSettingPlaybackSpeedReasons']))
      ..disallowSleepTimerClearReasons(parseReasons(proto['disallow_sleep_timer_clear_reasons'] ?? proto['disallowSleepTimerClearReasons']))
      ..disallowSleepTimerDurationReasons(parseReasons(proto['disallow_sleep_timer_duration_reasons'] ?? proto['disallowSleepTimerDurationReasons']))
      ..disallowSleepTimerEndOfTrackReasons(parseReasons(proto['disallow_sleep_timer_end_of_track_reasons'] ?? proto['disallowSleepTimerEndOfTrackReasons']))
      ..disallowTapToPlayTrackInNextTracksReasons(parseReasons(proto['disallow_tap_to_play_track_in_next_tracks_reasons'] ?? proto['disallowTapToPlayTrackInNextTracksReasons']))
      ..disallowReorderingTrackInNextTracksReasons(parseReasons(proto['disallow_reordering_track_in_next_tracks_reasons'] ?? proto['disallowReorderingTrackInNextTracksReasons']))
      ..disallowReorderingEpisodeInNextTracksReasons(parseReasons(proto['disallow_reordering_episode_in_next_tracks_reasons'] ?? proto['disallowReorderingEpisodeInNextTracksReasons']))
      ..disallowReorderingEnqueuedTrackInNextTracksReasons(parseReasons(proto['disallow_reordering_enqueued_track_in_next_tracks_reasons'] ?? proto['disallowReorderingEnqueuedTrackInNextTracksReasons']))
      ..disallowReorderingEnqueuedEpisodeInNextTracksReasons(parseReasons(proto['disallow_reordering_enqueued_episode_in_next_tracks_reasons'] ?? proto['disallowReorderingEnqueuedEpisodeInNextTracksReasons']))
      ..disallowViewingQueueReasons(parseReasons(proto['disallow_viewing_queue_reasons'] ?? proto['disallowViewingQueueReasons']))
      ..disallowViewingOrderedTracksInNextTracksReasons(parseReasons(proto['disallow_viewing_ordered_tracks_in_next_tracks_reasons'] ?? proto['disallowViewingOrderedTracksInNextTracksReasons']));

    final disallowSignalsRaw = proto['disallow_signals'] ?? proto['disallowSignals'];
    if (disallowSignalsRaw is Map) {
      final signalsMap = <String, RestrictionReasons>{};
      disallowSignalsRaw.forEach((k, v) {
        if (k != null) {
          final reasons = (v is Map && v['reasons'] is List)
              ? (v['reasons'] as List).map((e) => e.toString()).toSet()
              : <String>{};
          signalsMap[k.toString()] = RestrictionReasons.builder().reasons(reasons).build();
        }
      });
      builder.disallowSignals(signalsMap);
    }

    return builder.build();
  }

  /// Maps an EsPlaybackQuality protobuf structure (from Spotify qta1 case 28 & izl0.a).
  static PlaybackQuality playbackQualityFromProto(Map<String, dynamic> proto) {
    BitrateLevel parseBitrateLevel(dynamic val) {
      if (val is int) {
        switch (val) {
          case 1:
            return BitrateLevel.low;
          case 2:
            return BitrateLevel.normal;
          case 3:
            return BitrateLevel.high;
          case 4:
            return BitrateLevel.veryHigh;
          case 5:
            return BitrateLevel.hifi;
          case 6:
            return BitrateLevel.hifi24;
          default:
            return BitrateLevel.unknown;
        }
      }
      return BitrateLevel.unknown;
    }

    BitrateStrategy parseStrategy(dynamic val) {
      if (val is int) {
        switch (val) {
          case 1:
            return BitrateStrategy.bestMatching;
          case 2:
            return BitrateStrategy.backendAdvised;
          case 3:
            return BitrateStrategy.offlinedFile;
          case 4:
            return BitrateStrategy.cachedFile;
          case 5:
            return BitrateStrategy.localFile;
          default:
            return BitrateStrategy.unknown;
        }
      }
      return BitrateStrategy.unknown;
    }

    HiFiStatus parseHiFiStatus(dynamic val) {
      if (val is int) {
        switch (val) {
          case 1:
            return HiFiStatus.off;
          case 2:
            return HiFiStatus.on;
          default:
            return HiFiStatus.none;
        }
      }
      return HiFiStatus.none;
    }

    FileOrigin parseFileOrigin(dynamic val) {
      if (val is int) {
        switch (val) {
          case 1:
            return FileOrigin.internal;
          case 2:
            return FileOrigin.external;
          case 3:
            return FileOrigin.local;
          case 4:
            return FileOrigin.generated;
          default:
            return FileOrigin.unknown;
        }
      }
      return FileOrigin.unknown;
    }

    return PlaybackQuality.builder()
        .bitrateLevel(parseBitrateLevel(proto['bitrate_level'] ?? proto['bitrateLevel']))
        .strategy(parseStrategy(proto['strategy']))
        .targetBitrateLevel(parseBitrateLevel(proto['target_bitrate_level'] ?? proto['targetBitrateLevel']))
        .targetBitrateAvailable(proto['target_bitrate_available'] as bool? ?? proto['targetBitrateAvailable'] as bool? ?? false)
        .hifiStatus(parseHiFiStatus(proto['hifi_status'] ?? proto['hifiStatus']))
        .fileOrigin(parseFileOrigin(proto['file_origin'] ?? proto['fileOrigin']))
        .highestAvailableQuality(parseBitrateLevel(proto['highest_available_quality'] ?? proto['highestAvailableQuality']))
        .build();
  }

  /// Maps an EsContextPlayerState protobuf response to domain PlayerState (from Spotify qta1 case 28).
  static PlayerState playerStateFromProto(Map<String, dynamic> proto) {
    final builder = PlayerState.builder();

    if (proto['timestamp'] != null) {
      builder.timestamp((proto['timestamp'] as num).toInt());
    }

    final formatOrdinal = proto['format'];
    if (formatOrdinal is int) {
      switch (formatOrdinal) {
        case 1:
          builder.format(Format.defaultFormat);
          break;
        case 2:
          builder.format(Format.parrot);
          break;
        case 3:
        default:
          builder.format(Format.unknown);
          break;
      }
    }

    builder.contextUri(proto['context_uri'] as String? ?? proto['contextUri'] as String? ?? '');
    builder.contextUrl(proto['context_url'] as String? ?? proto['contextUrl'] as String? ?? '');

    final contextRestrictionsProto = proto['context_restrictions'] as Map<String, dynamic>? ??
        proto['contextRestrictions'] as Map<String, dynamic>?;
    builder.contextRestrictions(restrictionsFromProto(contextRestrictionsProto));

    final playOriginProto = proto['play_origin'] as Map<String, dynamic>? ??
        proto['playOrigin'] as Map<String, dynamic>?;
    if (playOriginProto != null) {
      final originBuilder = PlayOrigin.builder(
        playOriginProto['feature_identifier'] as String? ??
            playOriginProto['featureIdentifier'] as String? ??
            '',
      );
      originBuilder.featureVersion(playOriginProto['feature_version'] as String? ?? playOriginProto['featureVersion'] as String? ?? '');
      originBuilder.viewUri(playOriginProto['view_uri'] as String? ?? playOriginProto['viewUri'] as String? ?? '');
      originBuilder.externalReferrer(playOriginProto['external_referrer'] as String? ?? playOriginProto['externalReferrer'] as String? ?? '');
      originBuilder.referrerIdentifier(playOriginProto['referrer_identifier'] as String? ?? playOriginProto['referrerIdentifier'] as String? ?? '');
      originBuilder.deviceIdentifier(playOriginProto['device_identifier'] as String? ?? playOriginProto['deviceIdentifier'] as String? ?? '');
      originBuilder.restrictionIdentifier(playOriginProto['restriction_identifier'] as String? ?? playOriginProto['restrictionIdentifier'] as String? ?? '');
      final featureClasses = playOriginProto['feature_classes'] as List? ?? playOriginProto['featureClasses'] as List?;
      if (featureClasses != null) {
        originBuilder.featureClasses(featureClasses.map((e) => e.toString()).toSet());
      }
      builder.playOrigin(originBuilder.build());
    }

    final indexProto = proto['index'] as Map<String, dynamic>?;
    if (indexProto != null) {
      builder.index(ContextIndex.create(
        (indexProto['page'] as num?)?.toInt() ?? 0,
        (indexProto['track'] as num?)?.toInt() ?? 0,
      ));
    }

    final trackProto = proto['track'] as Map<String, dynamic>?;
    if (trackProto != null) {
      builder.track(QueueProtoMappers.providedTrackToContextTrack(trackProto));
    }

    final playbackId = proto['playback_id'] ?? proto['playbackId'];
    if (playbackId != null) {
      builder.playbackId(playbackId.toString().toLowerCase());
    }

    final qualityProto = proto['playback_quality'] as Map<String, dynamic>? ??
        proto['playbackQuality'] as Map<String, dynamic>?;
    if (qualityProto != null) {
      builder.playbackQuality(playbackQualityFromProto(qualityProto));
    }

    final speed = proto['playback_speed'] ?? proto['playbackSpeed'];
    if (speed is Map && speed['value'] != null) {
      builder.playbackSpeed((speed['value'] as num).toDouble());
    } else if (speed is num) {
      builder.playbackSpeed(speed.toDouble());
    }

    final pos = proto['position_as_of_timestamp'] ?? proto['positionAsOfTimestamp'];
    if (pos is Map && pos['value'] != null) {
      builder.positionAsOfTimestamp((pos['value'] as num).toInt());
    } else if (pos is num) {
      builder.positionAsOfTimestamp(pos.toInt());
    }

    final dur = proto['duration'];
    if (dur is Map && dur['value'] != null) {
      builder.duration((dur['value'] as num).toInt());
    } else if (dur is num) {
      builder.duration(dur.toInt());
    }

    builder.isPlaying(proto['is_playing'] as bool? ?? proto['isPlaying'] as bool? ?? false);
    builder.isPaused(proto['is_paused'] as bool? ?? proto['isPaused'] as bool? ?? false);
    builder.isBuffering(proto['is_buffering'] as bool? ?? proto['isBuffering'] as bool? ?? false);
    builder.isSystemInitiated(proto['is_system_initiated'] as bool? ?? proto['isSystemInitiated'] as bool? ?? false);

    final optionsProto = proto['options'] as Map<String, dynamic>?;
    if (optionsProto != null) {
      final optBuilder = PlayerOptions.builder();
      optBuilder.shufflingContext(optionsProto['shuffling_context'] as bool? ?? optionsProto['shufflingContext'] as bool? ?? false);
      optBuilder.repeatingContext(optionsProto['repeating_context'] as bool? ?? optionsProto['repeatingContext'] as bool? ?? false);
      optBuilder.repeatingTrack(optionsProto['repeating_track'] as bool? ?? optionsProto['repeatingTrack'] as bool? ?? false);
      final optSpeed = optionsProto['playback_speed'] ?? optionsProto['playbackSpeed'];
      if (optSpeed is num && optSpeed != 0.0) {
        optBuilder.playbackSpeed(optSpeed.toDouble());
      }
      final modes = optionsProto['modes'] as Map?;
      if (modes != null) {
        optBuilder.modes(Map<String, String>.from(modes));
      }
      builder.options(optBuilder.build());
    }

    final restrictionsProto = proto['restrictions'] as Map<String, dynamic>?;
    builder.restrictions(restrictionsFromProto(restrictionsProto));

    final suppressions = proto['suppressions'] as List?;
    if (suppressions != null && suppressions.isNotEmpty) {
      builder.suppressions(Suppressions.create(suppressions.map((e) => e.toString()).toSet()));
    }

    final nextTracksList = proto['next_tracks'] as List? ?? proto['nextTracks'] as List?;
    if (nextTracksList != null && nextTracksList.isNotEmpty) {
      builder.nextTracks(nextTracksList
          .map((item) => QueueProtoMappers.providedTrackToContextTrack(item as Map<String, dynamic>))
          .toList(growable: true));
    }

    final prevTracksList = proto['prev_tracks'] as List? ?? proto['prevTracks'] as List?;
    if (prevTracksList != null && prevTracksList.isNotEmpty) {
      builder.prevTracks(prevTracksList
          .map((item) => QueueProtoMappers.providedTrackToContextTrack(item as Map<String, dynamic>))
          .toList(growable: true));
    }

    final contextMetadata = proto['context_metadata'] as Map? ?? proto['contextMetadata'] as Map?;
    if (contextMetadata != null) {
      builder.contextMetadata(Map<String, String>.from(contextMetadata));
    }

    final pageMetadata = proto['page_metadata'] as Map? ?? proto['pageMetadata'] as Map?;
    if (pageMetadata != null) {
      builder.pageMetadata(Map<String, String>.from(pageMetadata));
    }

    final sessionId = proto['session_id'] as String? ?? proto['sessionId'] as String?;
    if (sessionId != null && sessionId.isNotEmpty) {
      builder.sessionId(sessionId);
    }

    final sessionCommandId = proto['session_command_id'] as String? ?? proto['sessionCommandId'] as String?;
    if (sessionCommandId != null && sessionCommandId.isNotEmpty) {
      builder.sessionCommandId(sessionCommandId);
    }

    final revision = proto['queue_revision'] ?? proto['queueRevision'];
    if (revision != null) {
      builder.queueRevision(revision.toString());
    }

    final streamOrdinal = proto['audio_stream'] ?? proto['audioStream'];
    if (streamOrdinal == 1) {
      builder.audioStream(AudioStream.alarm);
    } else {
      builder.audioStream(AudioStream.defaultStream);
    }

    final signals = proto['signals'] as List?;
    if (signals != null) {
      builder.signals(signals.map((e) => e.toString()).toList());
    }

    final adBreak = proto['ad_break_context'] as Map<String, dynamic>? ?? proto['adBreakContext'] as Map<String, dynamic>?;
    if (adBreak != null) {
      builder.adBreakContext(AdBreakContext.builder()
          .positionInCurrentAdBreak((adBreak['position_in_current_ad_break'] as num?)?.toInt() ?? 0)
          .totalAdsInBreakEstimate((adBreak['total_ads_in_break_estimate'] as num?)?.toInt() ?? 0)
          .maxSecondsRemaining((adBreak['max_seconds_remaining'] as num?)?.toInt() ?? 0)
          .build());
    }

    final sleepTimerProto = proto['sleep_timer'] as Map<String, dynamic>? ?? proto['sleepTimer'] as Map<String, dynamic>?;
    if (sleepTimerProto != null) {
      if (sleepTimerProto['timestamp'] != null) {
        builder.sleepTimer(SleepTimerTimestamp.create((sleepTimerProto['timestamp'] as num).toInt()));
      } else if (sleepTimerProto['end_of_track'] == true || sleepTimerProto['endOfTrack'] == true) {
        builder.sleepTimer(SleepTimerEndOfTrack.create());
      } else {
        builder.sleepTimer(SleepTimerNone.create());
      }
    }

    return builder.build();
  }
}
