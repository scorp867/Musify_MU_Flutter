import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/options/play_operation.dart';
import '../../domain/commands/options/play_options.dart';
import '../../domain/commands/options/play_trigger.dart';
import '../../domain/commands/options/prefetch_level.dart';
import '../../domain/commands/options/prepare_play_options.dart';
import '../../domain/commands/play_command.dart';
import '../../domain/commands/prepare_play_command.dart';
import '../../domain/commands/update_context_command.dart';
import '../../domain/commands/update_page_command.dart';
import '../../domain/commands/update_track_command.dart';
import '../../domain/commands/update_view_uri_command.dart';
import '../../domain/models/audio_stream.dart';
import '../../domain/models/context.dart';
import '../../domain/models/context_page.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/play_origin.dart';
import '../../domain/models/player_response.dart';
import '../../domain/models/restrictions.dart';
import 'context_player_play_prepared_client.dart';
import 'esperanto_transport.dart';
import 'proto/es_context.pb.dart' as proto_ctx;
import 'proto/es_context_page.pb.dart' as proto_page;
import 'proto/es_context_player_options.pb.dart' as proto_cpo;
import 'proto/es_context_track.pb.dart' as proto_ct;
import 'proto/es_logging_params.pb.dart' as proto_lp;
import 'proto/es_optional.pb.dart' as proto_opt;
import 'proto/es_play.pb.dart' as proto_play;
import 'proto/es_play_options.pb.dart' as proto_plo;
import 'proto/es_play_origin.pb.dart' as proto_po;
import 'proto/es_prepare_play.pb.dart' as proto_prep;
import 'proto/es_prepare_play_options.pb.dart' as proto_ppo;
import 'proto/es_response_with_reasons.pb.dart' as proto_resp;
import 'proto/es_restrictions.pb.dart' as proto_res;
import 'proto/es_session_response.pb.dart' as proto_sess;
import 'proto/es_skip_to_track.pb.dart' as proto_stt;

/// 1:1 replica of Spotify ContextPlayer Play Client (p.avy, p.ztv case 3, p.n8y case 5, p.zy0 case 15).
/// Emits 100% binary Protobuf payloads matching the Spotify Esperanto wire specification.
class ContextPlayerPlayClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerPlayClient(super.transport);

  static LoggingParams _decorateLoggingParams(LoggingParams? params) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (params == null) {
      return LoggingParams.builder().commandInitiatedTime(now).build();
    }
    if (params.commandInitiatedTime == null) {
      return params.toBuilder().commandInitiatedTime(now).build();
    }
    return params;
  }

  static proto_lp.LoggingParams _loggingParamsToProto(LoggingParams params) {
    final p = proto_lp.LoggingParams();
    final cit = params.commandInitiatedTime;
    if (cit != null) {
      p.commandInitiatedTime = proto_opt.OptionalInt64()..value = Int64(cit);
    }
    final crt = params.commandReceivedTime;
    if (crt != null) {
      p.commandReceivedTime = proto_opt.OptionalInt64()..value = Int64(crt);
    }
    if (params.pageInstanceIds.isNotEmpty) {
      p.pageInstanceIds.addAll(params.pageInstanceIds);
    }
    if (params.interactionIds.isNotEmpty) {
      p.interactionIds.addAll(params.interactionIds);
    }
    return p;
  }

  static proto_ct.ContextTrack _contextTrackToProto(ContextTrack track) {
    final p = proto_ct.ContextTrack();
    if (track.uri.isNotEmpty) p.uri = track.uri;
    if (track.uid.isNotEmpty) p.uid = track.uid;
    if (track.metadata.isNotEmpty) p.metadata.addAll(track.metadata);
    return p;
  }

  static proto_page.ContextPage _contextPageToProto(ContextPage page) {
    final p = proto_page.ContextPage()
      ..pageUrl = page.pageUrl
      ..nextPageUrl = page.nextPageUrl;
    if (page.metadata.isNotEmpty) {
      p.metadata.addAll(page.metadata);
    }
    final tracks = page.tracks;
    if (tracks != null) {
      p.isLoading = false;
      p.tracks.addAll(tracks.map(_contextTrackToProto));
    } else {
      p.isLoading = true;
    }
    return p;
  }

  static proto_res.Restrictions _restrictionsToProto(
      Restrictions restrictions) {
    final p = proto_res.Restrictions();
    if (restrictions.disallowPausingReasons.isNotEmpty) {
      p.disallowPausingReasons.addAll(restrictions.disallowPausingReasons);
    }
    if (restrictions.disallowResumingReasons.isNotEmpty) {
      p.disallowResumingReasons.addAll(restrictions.disallowResumingReasons);
    }
    if (restrictions.disallowSeekingReasons.isNotEmpty) {
      p.disallowSeekingReasons.addAll(restrictions.disallowSeekingReasons);
    }
    if (restrictions.disallowPeekingPrevReasons.isNotEmpty) {
      p.disallowPeekingPrevReasons.addAll(restrictions.disallowPeekingPrevReasons);
    }
    if (restrictions.disallowPeekingNextReasons.isNotEmpty) {
      p.disallowPeekingNextReasons.addAll(restrictions.disallowPeekingNextReasons);
    }
    if (restrictions.disallowSkippingPrevReasons.isNotEmpty) {
      p.disallowSkippingPrevReasons
          .addAll(restrictions.disallowSkippingPrevReasons);
    }
    if (restrictions.disallowSkippingNextReasons.isNotEmpty) {
      p.disallowSkippingNextReasons
          .addAll(restrictions.disallowSkippingNextReasons);
    }
    if (restrictions.disallowTogglingRepeatContextReasons.isNotEmpty) {
      p.disallowTogglingRepeatContextReasons
          .addAll(restrictions.disallowTogglingRepeatContextReasons);
    }
    if (restrictions.disallowTogglingRepeatTrackReasons.isNotEmpty) {
      p.disallowTogglingRepeatTrackReasons
          .addAll(restrictions.disallowTogglingRepeatTrackReasons);
    }
    if (restrictions.disallowTogglingShuffleReasons.isNotEmpty) {
      p.disallowTogglingShuffleReasons
          .addAll(restrictions.disallowTogglingShuffleReasons);
    }
    if (restrictions.disallowSetQueueReasons.isNotEmpty) {
      p.disallowSetQueueReasons.addAll(restrictions.disallowSetQueueReasons);
    }
    if (restrictions.disallowInterruptingPlaybackReasons.isNotEmpty) {
      p.disallowInterruptingPlaybackReasons
          .addAll(restrictions.disallowInterruptingPlaybackReasons);
    }
    if (restrictions.disallowTransferringPlaybackReasons.isNotEmpty) {
      p.disallowTransferringPlaybackReasons
          .addAll(restrictions.disallowTransferringPlaybackReasons);
    }
    if (restrictions.disallowRemoteControlReasons.isNotEmpty) {
      p.disallowRemoteControlReasons
          .addAll(restrictions.disallowRemoteControlReasons);
    }
    if (restrictions.disallowInsertingIntoNextTracksReasons.isNotEmpty) {
      p.disallowInsertingIntoNextTracksReasons
          .addAll(restrictions.disallowInsertingIntoNextTracksReasons);
    }
    if (restrictions.disallowInsertingIntoContextTracksReasons.isNotEmpty) {
      p.disallowInsertingIntoContextTracksReasons
          .addAll(restrictions.disallowInsertingIntoContextTracksReasons);
    }
    if (restrictions.disallowReorderingInNextTracksReasons.isNotEmpty) {
      p.disallowReorderingInNextTracksReasons
          .addAll(restrictions.disallowReorderingInNextTracksReasons);
    }
    if (restrictions.disallowReorderingInContextTracksReasons.isNotEmpty) {
      p.disallowReorderingInContextTracksReasons
          .addAll(restrictions.disallowReorderingInContextTracksReasons);
    }
    if (restrictions.disallowRemovingFromNextTracksReasons.isNotEmpty) {
      p.disallowRemovingFromNextTracksReasons
          .addAll(restrictions.disallowRemovingFromNextTracksReasons);
    }
    if (restrictions.disallowRemovingFromContextTracksReasons.isNotEmpty) {
      p.disallowRemovingFromContextTracksReasons
          .addAll(restrictions.disallowRemovingFromContextTracksReasons);
    }
    if (restrictions.disallowUpdatingContextReasons.isNotEmpty) {
      p.disallowUpdatingContextReasons
          .addAll(restrictions.disallowUpdatingContextReasons);
    }
    if (restrictions.disallowAddToQueueReasons.isNotEmpty) {
      p.disallowAddToQueueReasons.addAll(restrictions.disallowAddToQueueReasons);
    }
    if (restrictions.disallowSettingPlaybackSpeedReasons.isNotEmpty) {
      p.disallowSettingPlaybackSpeedReasons
          .addAll(restrictions.disallowSettingPlaybackSpeedReasons);
    }
    if (restrictions.disallowSignals.isNotEmpty) {
      final signalMap = <String, proto_res.RestrictionReasons>{};
      for (final entry in restrictions.disallowSignals.entries) {
        final reasonsProto = proto_res.RestrictionReasons()
          ..reasons.addAll(entry.value.reasons);
        signalMap[entry.key] = reasonsProto;
      }
      p.disallowSignals.addAll(signalMap);
    }
    return p;
  }

  static proto_ctx.Context _contextToProto(Context context) {
    final p = proto_ctx.Context()
      ..uri = context.uri
      ..url = context.url;
    if (context.metadata.isNotEmpty) {
      p.metadata.addAll(context.metadata);
    }
    final pages = context.pages;
    if (pages != null) {
      p.isLoading = false;
      p.pages.addAll(pages.map(_contextPageToProto));
    } else {
      p.isLoading = true;
    }
    final restrictions = context.restrictions;
    if (restrictions != null) {
      p.restrictions = _restrictionsToProto(restrictions);
    }
    return p;
  }

  static proto_po.PlayOrigin _playOriginToProto(PlayOrigin origin) {
    final p = proto_po.PlayOrigin();
    if (origin.featureIdentifier.isNotEmpty) {
      p.featureIdentifier = origin.featureIdentifier;
    }
    if (origin.featureVersion.isNotEmpty) {
      p.featureVersion = origin.featureVersion;
    }
    if (origin.viewUri.isNotEmpty) {
      p.viewUri = origin.viewUri;
    }
    if (origin.externalReferrer.isNotEmpty) {
      p.externalReferrer = origin.externalReferrer;
    }
    if (origin.referrerIdentifier.isNotEmpty) {
      p.referrerIdentifier = origin.referrerIdentifier;
    }
    if (origin.deviceIdentifier.isNotEmpty) {
      p.deviceIdentifier = origin.deviceIdentifier;
    }
    if (origin.restrictionIdentifier.isNotEmpty) {
      p.restrictionIdentifier = origin.restrictionIdentifier;
    }
    if (origin.featureClasses.isNotEmpty) {
      p.featureClasses.addAll(origin.featureClasses);
    }
    return p;
  }

  static proto_ppo.PreparePlayOptions _preparePlayOptionsToProto(
      PreparePlayOptions options) {
    final p = proto_ppo.PreparePlayOptions();
    final pid = options.playbackId;
    if (pid != null) {
      p.playbackId = utf8.encode(pid);
    }
    final aps = options.alwaysPlaySomething;
    if (aps != null) {
      p.alwaysPlaySomething = aps;
    }
    final skipTo = options.skipTo;
    if (skipTo != null) {
      final st = proto_stt.SkipToTrack();
      final pageUrl = skipTo.pageUrl;
      if (pageUrl != null) st.pageUrl = pageUrl;
      final pageIndex = skipTo.pageIndex;
      if (pageIndex != null) {
        st.pageIndex = proto_opt.OptionalInt64()..value = Int64(pageIndex);
      }
      final trackUid = skipTo.trackUid;
      if (trackUid != null) st.trackUid = trackUid;
      final trackUri = skipTo.trackUri;
      if (trackUri != null) st.trackUri = trackUri;
      final trackIndex = skipTo.trackIndex;
      if (trackIndex != null) {
        st.trackIndex = proto_opt.OptionalInt64()..value = Int64(trackIndex);
      }
      p.skipTo = st;
    }
    final seekTo = options.seekTo;
    if (seekTo != null) {
      p.seekTo = proto_opt.OptionalInt64()..value = Int64(seekTo);
    }
    final initiallyPaused = options.initiallyPaused;
    if (initiallyPaused != null) {
      p.initiallyPaused = initiallyPaused;
    }
    final systemInitiated = options.systemInitiated;
    if (systemInitiated != null) {
      p.systemInitiated = systemInitiated;
    }
    final override = options.playerOptionsOverride;
    if (override != null) {
      final cpo = proto_cpo.ContextPlayerOptionOverrides();
      final sc = override.shufflingContext;
      if (sc != null) {
        cpo.shufflingContext = proto_opt.OptionalBoolean()..value = sc;
      }
      final rc = override.repeatingContext;
      if (rc != null) {
        cpo.repeatingContext = proto_opt.OptionalBoolean()..value = rc;
      }
      final rt = override.repeatingTrack;
      if (rt != null) {
        cpo.repeatingTrack = proto_opt.OptionalBoolean()..value = rt;
      }
      final ps = override.playbackSpeed;
      if (ps != null) {
        cpo.playbackSpeed = proto_opt.OptionalDouble()..value = ps;
      }
      if (override.modes.isNotEmpty) {
        cpo.modes.addAll(override.modes);
      }
      p.playerOptionsOverride = cpo;
    }
    final suppressions = options.suppressions;
    if (suppressions != null && suppressions.providers.isNotEmpty) {
      p.suppressions.addAll(suppressions.providers);
    }
    final prefetchLevel = options.prefetchLevel;
    if (prefetchLevel != null) {
      switch (prefetchLevel) {
        case PrefetchLevel.none:
          p.prefetchLevel = proto_ppo.PreparePlayOptions_PrefetchLevel.NONE;
        case PrefetchLevel.media:
          p.prefetchLevel = proto_ppo.PreparePlayOptions_PrefetchLevel.MEDIA;
      }
    }
    final audioStream = options.audioStream;
    if (audioStream != null) {
      switch (audioStream) {
        case AudioStream.defaultStream:
          p.audioStream = proto_ppo.PreparePlayOptions_AudioStream.DEFAULT;
        case AudioStream.alarm:
          p.audioStream = proto_ppo.PreparePlayOptions_AudioStream.ALARM;
      }
    }
    final sessionId = options.sessionId;
    if (sessionId != null) {
      p.sessionId = sessionId;
    }
    final license = options.license;
    if (license != null) {
      p.license = license;
    }
    if (options.configurationOverride.isNotEmpty) {
      p.configurationOverride.addAll(options.configurationOverride);
    }
    return p;
  }

  static proto_plo.PlayOptions _playOptionsToProto(PlayOptions options) {
    final p = proto_plo.PlayOptions();
    final op = options.operation;
    if (op != null) {
      switch (op) {
        case PlayOperation.replace:
          p.operation = proto_plo.PlayOptions_Operation.REPLACE;
        case PlayOperation.enqueue:
          p.operation = proto_plo.PlayOptions_Operation.ENQUEUE;
        case PlayOperation.push:
          p.operation = proto_plo.PlayOptions_Operation.PUSH;
      }
    }
    final tr = options.trigger;
    if (tr != null) {
      switch (tr) {
        case PlayTrigger.immediately:
          p.trigger = proto_plo.PlayOptions_Trigger.IMMEDIATELY;
        case PlayTrigger.advancedPastTrack:
          p.trigger = proto_plo.PlayOptions_Trigger.ADVANCED_PAST_TRACK;
        case PlayTrigger.advancedPastContext:
          p.trigger = proto_plo.PlayOptions_Trigger.ADVANCED_PAST_CONTEXT;
      }
    }
    return p;
  }

  // 1:1 with dsl1.m39189n
  static PlayerResponse _parseResponseWithReasons(
      proto_resp.ResponseWithReasons resp) {
    if (resp.error == proto_resp.ResponseWithReasons_Error.OK) {
      return const PlayerResponseSuccess();
    }
    return PlayerResponseFailure(resp.reasons);
  }

  /// Executes PlayCommand matching Spotify avy.m28532a -> n8y case 5 -> zy0 case 15.
  Future<PlayerResponse> play(PlayCommand command) async {
    final preparePlayReq = proto_prep.PreparePlayRequest()
      ..context = _contextToProto(command.context)
      ..playOrigin = _playOriginToProto(command.playOrigin);

    final options = command.options;
    if (options != null) {
      preparePlayReq.options = _preparePlayOptionsToProto(options);
    }

    final playReq = proto_play.PlayRequest()
      ..preparePlayRequest = preparePlayReq;

    final playOptions = command.playOptions;
    if (playOptions != null) {
      playReq.playOptions = _playOptionsToProto(playOptions);
    }

    final decoratedParams = _decorateLoggingParams(command.loggingParams);
    playReq.loggingParams = _loggingParamsToProto(decoratedParams);

    final responseBytes = await callSingle(
      serviceName,
      'Play',
      playReq.writeToBuffer(),
    );

    final responseProto =
        proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(responseProto);
  }

  /// Executes PreparePlayCommand matching Spotify ze7 -> krl1.m58276t -> cqq case 29.
  Future<ContextPlayerPlayPreparedClient> preparePlay(
      PreparePlayCommand command) async {
    final preparePlayReq = proto_prep.PreparePlayRequest()
      ..context = _contextToProto(command.context)
      ..playOrigin = _playOriginToProto(command.playOrigin);

    final options = command.options;
    if (options != null) {
      preparePlayReq.options = _preparePlayOptionsToProto(options);
    }

    final responseBytes = await callSingle(
      serviceName,
      'PreparePlay',
      preparePlayReq.writeToBuffer(),
    );

    final sess = proto_sess.SessionResponse.fromBuffer(responseBytes);
    return ContextPlayerPlayPreparedClient(
      transport: transport,
      sessionId: sess.sessionId,
    );
  }

  /// Executes UpdateContextCommand matching Spotify context metadata update.
  Future<void> updateContext(UpdateContextCommand command) async {
    final contextProto = _contextToProto(command.context);
    await callSingle(serviceName, 'UpdateContext', contextProto.writeToBuffer());
  }

  /// Executes UpdateTrackCommand matching Spotify active track metadata update.
  Future<void> updateTrack(UpdateTrackCommand command) async {
    final trackProto = _contextTrackToProto(command.track);
    await callSingle(serviceName, 'UpdateTrack', trackProto.writeToBuffer());
  }

  /// Executes UpdatePageCommand matching Spotify context page update.
  Future<void> updatePage(UpdatePageCommand command) async {
    final pageProto = _contextPageToProto(command.page);
    await callSingle(serviceName, 'UpdatePage', pageProto.writeToBuffer());
  }

  /// Executes UpdateViewUriCommand matching Spotify view URI update.
  Future<void> updateViewUri(UpdateViewUriCommand command) async {
    final payloadBytes = Uint8List.fromList(utf8.encode(command.viewUri));
    await callSingle(serviceName, 'UpdateViewUri', payloadBytes);
  }
}
