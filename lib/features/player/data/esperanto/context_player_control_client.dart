import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/pause_command.dart';
import '../../domain/commands/play_as_next_in_queue_command.dart';
import '../../domain/commands/resume_command.dart';
import '../../domain/commands/seek_to_command.dart';
import '../../domain/commands/signal_command.dart';
import '../../domain/commands/skip_to_next_track_command.dart';
import '../../domain/commands/skip_to_prev_track_command.dart';
import '../../domain/commands/stop_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/pause_resume_origin.dart';
import '../../domain/models/player_response.dart';
import 'esperanto_transport.dart';
import 'proto/es_command_options.pb.dart' as proto_cmd;
import 'proto/es_context_track.pb.dart' as proto_track;
import 'proto/es_logging_params.pb.dart' as proto_log;
import 'proto/es_optional.pb.dart' as proto_opt;
import 'proto/es_pause.pb.dart' as proto_pause;
import 'proto/es_pauseresume_origin.pb.dart' as proto_pro;
import 'proto/es_play_as_next_in_queue_request.pb.dart' as proto_play_as_next;
import 'proto/es_response_with_reasons.pb.dart' as proto_resp;
import 'proto/es_resume.pb.dart' as proto_resume;
import 'proto/es_seek_to.pb.dart' as proto_seek;
import 'proto/es_signal_request.pb.dart' as proto_sig;
import 'proto/es_skip_next.pb.dart' as proto_skip_next;
import 'proto/es_skip_prev.pb.dart' as proto_skip_prev;
import 'proto/es_stop.pb.dart' as proto_stop;

/// 1:1 replica of Spotify ContextPlayer Control Client (p.nvy, p.hvy, p.ivy, p.jvy, p.dvy, p.evy, p.fvy, p.gvy).
/// Emits 100% binary Protobuf payloads matching the Spotify Esperanto wire specification.
class ContextPlayerControlClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerControlClient(super.transport);

  /// 1:1 with Spotify nvy -> n8y case 6 -> mvy case 0 (Pause)
  Future<PlayerResponse> pause(PauseCommand command) async {
    final req = proto_pause.PauseRequest();
    final options = command.options;
    if (options != null) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final pauseOrigin = command.pauseOrigin;
    if (pauseOrigin != null) {
      final po = proto_pro.PauseResumeOrigin()
        ..featureIdentifier = pauseOrigin.featureIdentifier;
      req.pauseOrigin = po;
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Pause', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify nvy -> jvy case 0 (Pause with featureIdentifier and systemInitiated)
  Future<PlayerResponse> pauseOrigin(
    String featureIdentifier, {
    bool systemInitiated = false,
  }) {
    return pause(
      PauseCommand.builder()
          .options(
            CommandOptions.builder().systemInitiated(systemInitiated).build(),
          )
          .pauseOrigin(PauseResumeOrigin.builder(featureIdentifier).build())
          .build(),
    );
  }

  /// 1:1 with Spotify nvy -> n8y case 8 -> evy case 1 (Resume)
  Future<PlayerResponse> resume(ResumeCommand command) async {
    final req = proto_resume.ResumeRequest();
    final options = command.options;
    if (options != null) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final resumeOrigin = command.resumeOrigin;
    if (resumeOrigin != null) {
      final ro = proto_pro.PauseResumeOrigin()
        ..featureIdentifier = resumeOrigin.featureIdentifier;
      req.resumeOrigin = ro;
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Resume', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify nvy -> ivy case 0 (Resume with featureIdentifier and systemInitiated)
  Future<PlayerResponse> resumeOrigin(
    String featureIdentifier, {
    bool systemInitiated = false,
  }) {
    return resume(
      ResumeCommand.builder()
          .options(
            CommandOptions.builder().systemInitiated(systemInitiated).build(),
          )
          .resumeOrigin(PauseResumeOrigin.builder(featureIdentifier).build())
          .build(),
    );
  }

  /// 1:1 with Spotify nvy -> hvy case 0 (Stop)
  Future<PlayerResponse> stop(StopCommand command) async {
    final req = proto_stop.StopRequest();
    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Stop', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify nvy -> n8y case 5 -> fvy case 0 (SkipToNextTrack)
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async {
    final req = proto_skip_next.SkipNextRequest();
    final options = command.options;
    if (options != null) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final track = command.track;
    if (track != null) {
      req.track = _toContextTrackProto(track);
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes =
        await callSingle(serviceName, 'SkipNext', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify nvy -> n8y case 4 -> evy case 0 (SkipToPrevTrack)
  Future<PlayerResponse> skipToPrev(SkipToPrevTrackCommand command) async {
    final req = proto_skip_prev.SkipPrevRequest();
    final options = command.options;
    if (options != null) {
      req.options = _toCommandOptionsProto(options.commandOptions);
      if (options.allowSeeking case final allowSeeking?) {
        req.allowSeeking = allowSeeking;
      }
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final track = command.track;
    if (track != null) {
      req.track = _toContextTrackProto(track);
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes =
        await callSingle(serviceName, 'SkipPrev', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify nvy -> cvy -> fvy case 1 (SeekTo)
  Future<PlayerResponse> seekTo(SeekToCommand command) async {
    final req = proto_seek.SeekToRequest()..position = Int64(command.value);
    final options = command.options;
    if (options != null) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final relative = command.relative;
    if (relative != null) {
      switch (relative) {
        case SeekToCommandRelative.beginning:
          req.relative = proto_seek.SeekToRequest_Relative.BEGINNING;
        case SeekToCommandRelative.current:
          req.relative = proto_seek.SeekToRequest_Relative.CURRENT;
        case SeekToCommandRelative.end:
          req.relative = proto_seek.SeekToRequest_Relative.END;
      }
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'SeekTo', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify nvy -> dvy case 0 (SeekToPosition)
  Future<PlayerResponse> seekToPosition(int position) {
    return seekTo(SeekToCommand.create(position));
  }

  /// 1:1 with Spotify nvy -> n8y case 9 -> gvy case 1 (Signal)
  Future<PlayerResponse> signal(SignalCommand command) async {
    final req = proto_sig.SignalRequest()..signalId = command.signalId;
    final params = command.parameters;
    if (params != null) {
      req.parameters = params;
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Signal', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify nvy -> n8y case 7 -> dvy case 1 (PlayAsNextInQueue)
  Future<PlayerResponse> playAsNextInQueue(
      PlayAsNextInQueueCommand command) async {
    final req = proto_play_as_next.PlayAsNextInQueueRequest();
    final options = command.options;
    if (options != null) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    for (final track in command.tracks) {
      req.tracks.add(_toContextTrackProto(track));
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes =
        await callSingle(serviceName, 'PlayAsNextInQueue', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  // 1:1 with yjd0.m94430a: LoggingParams decorator
  static LoggingParams _decorateLoggingParams(LoggingParams? params) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (params != null) {
      return params.toBuilder().commandInitiatedTime(now).build();
    }
    return LoggingParams.empty.toBuilder().commandInitiatedTime(now).build();
  }

  // 1:1 with qrl1.m74301k
  static proto_cmd.CommandOptions _toCommandOptionsProto(
      CommandOptions options) {
    final p = proto_cmd.CommandOptions();
    if (options.overrideRestrictions case final overrideRestrictions?) {
      p.overrideRestrictions = overrideRestrictions;
    }
    if (options.onlyForLocalDevice case final onlyForLocalDevice?) {
      p.onlyForLocalDevice = onlyForLocalDevice;
    }
    if (options.systemInitiated case final systemInitiated?) {
      p.systemInitiated = systemInitiated;
    }
    if (options.onlyForPlaybackId case final onlyForPlaybackId?
        when onlyForPlaybackId.isNotEmpty) {
      p.onlyForPlaybackId = onlyForPlaybackId.codeUnits;
    }
    return p;
  }

  // 1:1 with ltl1.m61228o
  static proto_log.LoggingParams _toLoggingParamsProto(LoggingParams params) {
    final p = proto_log.LoggingParams();
    if (params.commandInitiatedTime case final cit?) {
      p.commandInitiatedTime = proto_opt.OptionalInt64()..value = Int64(cit);
    }
    if (params.commandReceivedTime case final crt?) {
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

  // 1:1 with frl.m45005b: ContextTrack -> EsContextTrack
  static proto_track.ContextTrack _toContextTrackProto(ContextTrack track) {
    final p = proto_track.ContextTrack();
    if (track.uri.isNotEmpty) {
      p.uri = track.uri;
    }
    if (track.uid.isNotEmpty) {
      p.uid = track.uid;
    }
    if (track.metadata.isNotEmpty) {
      p.metadata.addAll(track.metadata);
    }
    if (track.provider.isNotEmpty) {
      p.metadata['provider'] = track.provider;
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
}
