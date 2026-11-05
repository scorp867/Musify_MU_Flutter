import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/options/timer_type.dart';
import '../../domain/commands/set_options_command.dart';
import '../../domain/commands/set_repeating_context_command.dart';
import '../../domain/commands/set_repeating_track_command.dart';
import '../../domain/commands/set_shuffling_context_command.dart';
import '../../domain/commands/set_sleep_timer_command.dart';
import '../../domain/models/player_response.dart';
import 'esperanto_transport.dart';
import 'proto/es_command_options.pb.dart' as proto_cmd;
import 'proto/es_logging_params.pb.dart' as proto_log;
import 'proto/es_optional.pb.dart' as proto_opt;
import 'proto/es_response_with_reasons.pb.dart' as proto_resp;
import 'proto/es_set_options.pb.dart' as proto_set_opts;
import 'proto/es_set_shuffling_context.pb.dart' as proto_shuf;
import 'proto/es_set_sleep_timer_request.pb.dart' as proto_sleep;

enum RepeatMode {
  none,
  context,
  track,
}

/// 1:1 replica of Spotify ContextPlayer Options Client (p.ovy & p.qvy).
/// Emits 100% binary Protobuf payloads matching the Spotify Esperanto wire specification.
class ContextPlayerOptionsClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerOptionsClient(super.transport);

  /// 1:1 with Spotify ovy.m69792b (SetOptions)
  Future<PlayerResponse> setOptions(SetOptionsCommand command) async {
    final req = proto_set_opts.SetOptionsRequest();

    if (command.repeatingTrack case final repeatingTrack?) {
      req.repeatingTrack = proto_opt.OptionalBoolean()..value = repeatingTrack;
    }

    if (command.repeatingContext case final repeatingContext?) {
      req.repeatingContext =
          proto_opt.OptionalBoolean()..value = repeatingContext;
    }

    if (command.shufflingContext case final shufflingContext?) {
      req.shufflingContext =
          proto_opt.OptionalBoolean()..value = shufflingContext;
    }

    if (command.playbackSpeed case final playbackSpeed?) {
      req.playbackSpeed = playbackSpeed;
    }

    if (command.modes.isNotEmpty) {
      req.modes.addEntries(command.modes.entries);
    }

    if (command.options case final options?) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes =
        await callSingle(serviceName, 'SetOptions', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify ovy.m69794d (SetShufflingContext)
  Future<PlayerResponse> setShufflingContext(
      SetShufflingContextCommand command) async {
    final req = proto_shuf.SetShufflingContextRequest()
      ..shufflingContext = command.value;

    if (command.options case final options?) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes =
        await callSingle(serviceName, 'SetShufflingContext', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  /// 1:1 with Spotify ovy.mo69791a: setShuffling(value)
  Future<PlayerResponse> setShuffle(bool shuffle) {
    return setShufflingContext(SetShufflingContextCommand.create(shuffle));
  }

  /// 1:1 with Spotify ovy.m69793c: setRepeating(repeatingContext, repeatingTrack)
  Future<PlayerResponse> setRepeating({
    required bool repeatingContext,
    required bool repeatingTrack,
  }) {
    final command = SetOptionsCommand.builder()
        .repeatingContext(repeatingContext)
        .repeatingTrack(repeatingTrack)
        .build();
    return setOptions(command);
  }

  /// 1:1 with Spotify ovy.setRepeatMode
  /// Mode 0 (None): repeatingContext=false, repeatingTrack=false
  /// Mode 1 (Context): repeatingContext=true, repeatingTrack=false
  /// Mode 2 (Track): repeatingContext=true, repeatingTrack=true
  Future<PlayerResponse> setRepeatMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none:
        return setRepeating(repeatingContext: false, repeatingTrack: false);
      case RepeatMode.context:
        return setRepeating(repeatingContext: true, repeatingTrack: false);
      case RepeatMode.track:
        return setRepeating(repeatingContext: true, repeatingTrack: true);
    }
  }

  /// Delegated repeating context setter matching SetRepeatingContextCommand
  Future<PlayerResponse> setRepeatingContext(
      SetRepeatingContextCommand command) {
    final builder = SetOptionsCommand.builder()
        .repeatingContext(command.value);
    if (command.options case final options?) {
      builder.options(options);
    }
    if (command.loggingParams case final lp?) {
      builder.loggingParams(lp);
    }
    return setOptions(builder.build());
  }

  /// Delegated repeating track setter matching SetRepeatingTrackCommand
  Future<PlayerResponse> setRepeatingTrack(SetRepeatingTrackCommand command) {
    final builder = SetOptionsCommand.builder()
        .repeatingTrack(command.value);
    if (command.options case final options?) {
      builder.options(options);
    }
    if (command.loggingParams case final lp?) {
      builder.loggingParams(lp);
    }
    return setOptions(builder.build());
  }

  /// 1:1 with Spotify gps0 / qvy (SetSleepTimer) via binary Protobuf
  Future<PlayerResponse> setSleepTimer(SetSleepTimerCommand command) async {
    final req = proto_sleep.SetSleepTimerRequest();

    if (command.options case final options?) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    final timerType = command.timerType;
    if (timerType is TimerTypeDuration) {
      req.duration = proto_sleep.SetSleepTimerRequest_Duration(
        seconds: Int64(timerType.durationSeconds),
      );
    } else if (timerType is TimerTypeEndOfTrack) {
      req.endOfTrack = proto_sleep.SetSleepTimerRequest_EndOfTrack();
    } else {
      req.clear_3 = proto_sleep.SetSleepTimerRequest_Clear();
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes =
        await callSingle(serviceName, 'SetSleepTimer', payloadBytes);
    final resp = proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(resp);
  }

  // 1:1 with yjd0.m94430a: LoggingParams decorator
  static LoggingParams _decorateLoggingParams(LoggingParams? params) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (params case final validParams?) {
      return validParams.toBuilder().commandInitiatedTime(now).build();
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

  // 1:1 with dsl1.m39189n
  static PlayerResponse _parseResponseWithReasons(
      proto_resp.ResponseWithReasons resp) {
    if (resp.error == proto_resp.ResponseWithReasons_Error.OK) {
      return const PlayerResponseSuccess();
    }
    return PlayerResponseFailure(resp.reasons);
  }
}
