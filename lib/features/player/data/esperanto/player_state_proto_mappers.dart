import 'dart:typed_data';

import '../../domain/models/audio_stream.dart';
import '../../domain/models/bitrate_level.dart';
import '../../domain/models/bitrate_strategy.dart';
import '../../domain/models/context_index.dart';
import '../../domain/models/hifi_status.dart';
import '../../domain/models/play_origin.dart';
import '../../domain/models/playback_quality.dart';
import '../../domain/models/player_options.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/restrictions.dart';
import '../../domain/models/suppressions.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;
import 'queue_proto_mappers.dart';

/// 1:1 Spotify PlayerState Protobuf Mappers.
/// Sources of Truth:
/// - o2l1.java (case 28: EsContextPlayerState -> PlayerState)
/// - m250.java (case 18: byte[] -> EsContextPlayerState)
/// - f111.java (m43130a: EsRestrictions -> Restrictions)
/// - lrs0.java (m61087a: BitrateLevel mapper)
abstract class PlayerStateProtoMappers {
  /// Converts a binary protobuf ContextPlayerState to domain PlayerState (o2l1.java case 28).
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
    if (p.hasContextRestrictions()) {
      builder.contextRestrictions(
          restrictionsFromProtoMessage(p.contextRestrictions));
    }
    if (p.hasPlayOrigin()) {
      final po = p.playOrigin;
      final poBuilder = PlayOrigin.builder(po.featureIdentifier);
      if (po.hasFeatureVersion()) poBuilder.featureVersion(po.featureVersion);
      if (po.hasViewUri()) poBuilder.viewUri(po.viewUri);
      if (po.hasExternalReferrer()) {
        poBuilder.externalReferrer(po.externalReferrer);
      }
      if (po.hasReferrerIdentifier()) {
        poBuilder.referrerIdentifier(po.referrerIdentifier);
      }
      if (po.hasRestrictionIdentifier()) {
        poBuilder.restrictionIdentifier(po.restrictionIdentifier);
      }
      if (po.hasDeviceIdentifier()) {
        poBuilder.deviceIdentifier(po.deviceIdentifier);
      }
      if (po.featureClasses.isNotEmpty) {
        poBuilder.featureClasses(po.featureClasses.toSet());
      }
      builder.playOrigin(poBuilder.build());
    }
    if (p.hasIndex()) {
      builder.index(
          ContextIndex.create(p.index.page.toInt(), p.index.track.toInt()));
    }
    if (p.hasTrack()) {
      builder.track(QueueProtoMappers.fromProvidedTrackProto(p.track));
    }
    if (p.playbackId.isNotEmpty) {
      builder.playbackId(
        p.playbackId
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join('')
            .toLowerCase(),
      );
    }
    if (p.hasPlaybackQuality()) {
      builder.playbackQuality(mapPlaybackQuality(p.playbackQuality));
    }
    if (p.hasPlaybackSpeed()) {
      builder.playbackSpeed(p.playbackSpeed.value);
    }
    if (p.hasPositionAsOfTimestamp()) {
      builder.positionAsOfTimestamp(p.positionAsOfTimestamp.value.toInt());
    }
    if (p.hasDuration()) {
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
      final optsBuilder = PlayerOptions.builder()
        ..shufflingContext(opts.shufflingContext)
        ..repeatingContext(opts.repeatingContext)
        ..repeatingTrack(opts.repeatingTrack);
      if (opts.playbackSpeed != 0.0) {
        optsBuilder.playbackSpeed(opts.playbackSpeed);
      }
      optsBuilder.modes(Map<String, String>.from(opts.modes));
      builder.options(optsBuilder.build());
    }
    if (p.hasRestrictions()) {
      builder.restrictions(restrictionsFromProtoMessage(p.restrictions));
    }
    if (p.suppressions.isNotEmpty) {
      builder.suppressions(Suppressions.create(p.suppressions.toSet()));
    }
    if (p.nextTracks.isNotEmpty) {
      builder.nextTracks(
        p.nextTracks.map(QueueProtoMappers.fromProvidedTrackProto).toList(),
      );
    }
    if (p.prevTracks.isNotEmpty) {
      builder.prevTracks(
        p.prevTracks.map(QueueProtoMappers.fromProvidedTrackProto).toList(),
      );
    }
    if (p.contextMetadata.isNotEmpty) {
      builder.contextMetadata(Map<String, String>.from(p.contextMetadata));
    }
    if (p.pageMetadata.isNotEmpty) {
      builder.pageMetadata(Map<String, String>.from(p.pageMetadata));
    }
    if (p.hasSessionId() && p.sessionId.isNotEmpty) {
      builder.sessionId(p.sessionId);
    }
    if (p.hasSessionCommandId() && p.sessionCommandId.isNotEmpty) {
      builder.sessionCommandId(p.sessionCommandId);
    }
    if (p.hasQueueRevision()) {
      builder.queueRevision(p.queueRevision.toString());
    }
    if (p.hasAudioStream()) {
      switch (p.audioStream) {
        case proto.PreparePlayOptions_AudioStream.ALARM:
          builder.audioStream(AudioStream.alarm);
        case proto.PreparePlayOptions_AudioStream.DEFAULT:
        default:
          builder.audioStream(AudioStream.defaultStream);
      }
    }
    if (p.signals.isNotEmpty) {
      builder.signals(List<String>.from(p.signals));
    }
    return builder.build();
  }

  /// Maps binary PlaybackQuality protobuf message (o2l1.java lines 1205-1281).
  static PlaybackQuality mapPlaybackQuality(proto.PlaybackQuality pq) {
    return PlaybackQuality.builder()
        .bitrateLevel(_mapBitrateLevel(pq.bitrateLevel))
        .strategy(_mapBitrateStrategy(pq.strategy))
        .targetBitrateLevel(_mapBitrateLevel(pq.targetBitrateLevel))
        .targetBitrateAvailable(pq.targetBitrateAvailable)
        .hifiStatus(_mapHiFiStatus(pq.hifiStatus))
        .build();
  }

  static BitrateLevel _mapBitrateLevel(proto.PlaybackQuality_BitrateLevel level) {
    switch (level) {
      case proto.PlaybackQuality_BitrateLevel.LOW:
        return BitrateLevel.low;
      case proto.PlaybackQuality_BitrateLevel.NORMAL:
        return BitrateLevel.normal;
      case proto.PlaybackQuality_BitrateLevel.HIGH:
        return BitrateLevel.high;
      case proto.PlaybackQuality_BitrateLevel.VERY_HIGH:
        return BitrateLevel.veryHigh;
      case proto.PlaybackQuality_BitrateLevel.HIFI:
        return BitrateLevel.hifi;
      case proto.PlaybackQuality_BitrateLevel.HIFI24:
        return BitrateLevel.hifi24;
      case proto.PlaybackQuality_BitrateLevel.UNKNOWN:
      default:
        return BitrateLevel.unknown;
    }
  }

  static BitrateStrategy _mapBitrateStrategy(
      proto.PlaybackQuality_BitrateStrategy strategy) {
    switch (strategy) {
      case proto.PlaybackQuality_BitrateStrategy.BEST_MATCHING:
        return BitrateStrategy.bestMatching;
      case proto.PlaybackQuality_BitrateStrategy.BACKEND_ADVISED:
        return BitrateStrategy.backendAdvised;
      case proto.PlaybackQuality_BitrateStrategy.OFFLINED_FILE:
        return BitrateStrategy.offlinedFile;
      case proto.PlaybackQuality_BitrateStrategy.CACHED_FILE:
        return BitrateStrategy.cachedFile;
      case proto.PlaybackQuality_BitrateStrategy.LOCAL_FILE:
        return BitrateStrategy.localFile;
      case proto.PlaybackQuality_BitrateStrategy.UNKNOWN_STRATEGY:
      default:
        return BitrateStrategy.unknown;
    }
  }

  static HiFiStatus _mapHiFiStatus(proto.PlaybackQuality_HiFiStatus status) {
    switch (status) {
      case proto.PlaybackQuality_HiFiStatus.ON:
        return HiFiStatus.on;
      case proto.PlaybackQuality_HiFiStatus.OFF:
        return HiFiStatus.off;
      case proto.PlaybackQuality_HiFiStatus.NONE:
      default:
        return HiFiStatus.none;
    }
  }

  /// Maps a proto.Restrictions protobuf message into domain Restrictions (f111.java).
  static Restrictions restrictionsFromProtoMessage(proto.Restrictions p) {
    final builder = Restrictions.builder()
      ..disallowPausingReasons(p.disallowPausingReasons.toSet())
      ..disallowResumingReasons(p.disallowResumingReasons.toSet())
      ..disallowSeekingReasons(p.disallowSeekingReasons.toSet())
      ..disallowPeekingPrevReasons(p.disallowPeekingPrevReasons.toSet())
      ..disallowPeekingNextReasons(p.disallowPeekingNextReasons.toSet())
      ..disallowSkippingPrevReasons(p.disallowSkippingPrevReasons.toSet())
      ..disallowSkippingNextReasons(p.disallowSkippingNextReasons.toSet())
      ..disallowTogglingRepeatContextReasons(
          p.disallowTogglingRepeatContextReasons.toSet())
      ..disallowTogglingRepeatTrackReasons(
          p.disallowTogglingRepeatTrackReasons.toSet())
      ..disallowTogglingShuffleReasons(p.disallowTogglingShuffleReasons.toSet())
      ..disallowSetQueueReasons(p.disallowSetQueueReasons.toSet())
      ..disallowAddToQueueReasons(p.disallowAddToQueueReasons.toSet())
      ..disallowInterruptingPlaybackReasons(
          p.disallowInterruptingPlaybackReasons.toSet())
      ..disallowTransferringPlaybackReasons(
          p.disallowTransferringPlaybackReasons.toSet())
      ..disallowRemoteControlReasons(p.disallowRemoteControlReasons.toSet())
      ..disallowInsertingIntoNextTracksReasons(
          p.disallowInsertingIntoNextTracksReasons.toSet())
      ..disallowInsertingIntoContextTracksReasons(
          p.disallowInsertingIntoContextTracksReasons.toSet())
      ..disallowReorderingInNextTracksReasons(
          p.disallowReorderingInNextTracksReasons.toSet())
      ..disallowReorderingInContextTracksReasons(
          p.disallowReorderingInContextTracksReasons.toSet())
      ..disallowRemovingFromNextTracksReasons(
          p.disallowRemovingFromNextTracksReasons.toSet())
      ..disallowRemovingFromContextTracksReasons(
          p.disallowRemovingFromContextTracksReasons.toSet())
      ..disallowUpdatingContextReasons(p.disallowUpdatingContextReasons.toSet())
      ..disallowSettingPlaybackSpeedReasons(
          p.disallowSettingPlaybackSpeedReasons.toSet());

    if (p.disallowSignals.isNotEmpty) {
      final signalsMap = <String, RestrictionReasons>{};
      for (final entry in p.disallowSignals.entries) {
        signalsMap[entry.key] = RestrictionReasons.builder()
            .reasons(entry.value.reasons.toSet())
            .build();
      }
      builder.disallowSignals(signalsMap);
    }

    if (p.disallowSettingModes.isNotEmpty) {
      final modesMap = <String, ModeRestrictions>{};
      for (final entry in p.disallowSettingModes.entries) {
        final modeVals = <String, RestrictionReasons>{};
        for (final valEntry in entry.value.values.entries) {
          modeVals[valEntry.key] = RestrictionReasons.builder()
              .reasons(valEntry.value.reasons.toSet())
              .build();
        }
        modesMap[entry.key] =
            ModeRestrictions.builder().values(modeVals).build();
      }
      builder.disallowSettingModes(modesMap);
    }

    return builder.build();
  }

  /// Decodes PlayerState from raw binary Protobuf wire bytes (m250.java case 18).
  static PlayerState fromBuffer(Uint8List bytes) {
    if (bytes.isEmpty) {
      return PlayerState.empty;
    }
    return fromContextPlayerStateProto(
        proto.ContextPlayerState.fromBuffer(bytes));
  }
}
