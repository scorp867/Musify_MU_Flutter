import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/options/play_operation.dart';
import '../../domain/commands/options/play_options.dart';
import '../../domain/commands/options/play_trigger.dart';
import '../../domain/commands/play_session_command.dart';
import '../../domain/models/player_response.dart';
import 'esperanto_transport.dart';
import 'proto/es_command_options.pb.dart' as proto_cmd;
import 'proto/es_delete_session.pb.dart' as proto_del;
import 'proto/es_logging_params.pb.dart' as proto_lp;
import 'proto/es_optional.pb.dart' as proto_opt;
import 'proto/es_play.pb.dart' as proto_play;
import 'proto/es_play_options.pb.dart' as proto_plo;
import 'proto/es_response_with_reasons.pb.dart' as proto_resp;

/// 1:1 replica of Spotify ContextPlayer Play Prepared Client (p.svy).
/// Communicates using 100% binary Protobuf payloads matching the Spotify Esperanto wire specification.
class ContextPlayerPlayPreparedClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.player.esperanto.proto.ContextPlayer';

  final String sessionId;
  final bool isDeferred;
  bool isDestroyed = false;

  ContextPlayerPlayPreparedClient({
    required EsperantoTransport transport,
    required this.sessionId,
    this.isDeferred = false,
  }) : super(transport);

  static LoggingParams _decorateLoggingParams(LoggingParams? params) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (params case final validParams?) {
      if (validParams.commandInitiatedTime == null) {
        return validParams.toBuilder().commandInitiatedTime(now).build();
      }
      return validParams;
    }
    return LoggingParams.builder().commandInitiatedTime(now).build();
  }

  static proto_lp.LoggingParams _loggingParamsToProto(LoggingParams params) {
    final p = proto_lp.LoggingParams();
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

  static proto_cmd.CommandOptions _toCommandOptionsProto(
      CommandOptions options) {
    final p = proto_cmd.CommandOptions();
    if (options.overrideRestrictions case final overrideRestrictions?) {
      p.overrideRestrictions = overrideRestrictions;
    }
    if (options.onlyForPlaybackId case final onlyForPlaybackId?) {
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

  static proto_plo.PlayOptions _playOptionsToProto(PlayOptions options) {
    final p = proto_plo.PlayOptions();
    if (options.operation case final op?) {
      switch (op) {
        case PlayOperation.replace:
          p.operation = proto_plo.PlayOptions_Operation.REPLACE;
        case PlayOperation.enqueue:
          p.operation = proto_plo.PlayOptions_Operation.ENQUEUE;
        case PlayOperation.push:
          p.operation = proto_plo.PlayOptions_Operation.PUSH;
      }
    }
    if (options.trigger case final tr?) {
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

  static PlayerResponse _parseResponseWithReasons(
      proto_resp.ResponseWithReasons resp) {
    if (resp.error == proto_resp.ResponseWithReasons_Error.OK) {
      return const PlayerResponseSuccess();
    }
    return PlayerResponseFailure(resp.reasons);
  }

  /// 1:1 with Spotify svy.m79862a(PlaySessionCommand)
  Future<PlayerResponse> play([PlaySessionCommand? playSessionCommand]) async {
    final command = switch (playSessionCommand) {
      final cmd? => cmd,
      null => PlaySessionCommand.create(),
    };
    final req = proto_play.PlayPreparedRequest()..sessionId = sessionId;

    if (command.playOptions case final playOptions?) {
      req.playOptions = _playOptionsToProto(playOptions);
      req.options = _toCommandOptionsProto(playOptions.commandOptions);
    }

    final decoratedParams = _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _loggingParamsToProto(decoratedParams);

    isDestroyed = true;
    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes =
        await callSingle(serviceName, 'PlayPrepared', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify a8u0: DeleteSession esperanto endpoint
  Future<void> deleteSession() async {
    final req = proto_del.DeleteSessionRequest()..sessionId = sessionId;
    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'DeleteSession', payloadBytes);
    isDestroyed = true;
  }
}
