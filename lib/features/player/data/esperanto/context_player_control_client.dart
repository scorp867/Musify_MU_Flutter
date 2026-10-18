import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/pause_command.dart';
import '../../domain/commands/resume_command.dart';
import '../../domain/commands/seek_to_command.dart';
import '../../domain/commands/skip_to_next_track_command.dart';
import '../../domain/commands/skip_to_prev_track_command.dart';
import '../../domain/commands/stop_command.dart';
import '../../domain/models/pause_resume_origin.dart';
import 'esperanto_transport.dart';
import 'queue_proto_mappers.dart';

class ContextPlayerControlClient extends EsperantoClientBase {
  static const String serviceName = 'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerControlClient(super.transport);

  static Map<String, dynamic> _commandOptionsToProto(CommandOptions? options) {
    if (options == null) return const {};
    return {
      if (options.overrideRestrictions != null)
        'override_restrictions': options.overrideRestrictions,
      if (options.onlyForPlaybackId != null)
        'only_for_playback_id': options.onlyForPlaybackId,
      if (options.systemInitiated != null)
        'system_initiated': options.systemInitiated,
      if (options.onlyForLocalDevice != null)
        'only_for_local_device': options.onlyForLocalDevice,
    };
  }

  static Map<String, dynamic> _loggingParamsToProto(LoggingParams? params) {
    if (params == null) return const {};
    return {
      if (params.commandId != null) 'command_id': params.commandId,
      if (params.commandInitiatedTime != null)
        'command_initiated_time': params.commandInitiatedTime,
      if (params.commandReceivedTime != null)
        'command_received_time': params.commandReceivedTime,
      if (params.pageInstanceIds.isNotEmpty)
        'page_instance_ids': params.pageInstanceIds.toList(),
      if (params.interactionIds.isNotEmpty)
        'interaction_ids': params.interactionIds.toList(),
    };
  }

  static Map<String, dynamic> _pauseResumeOriginToProto(PauseResumeOrigin? origin) {
    if (origin == null) return const {};
    return {
      'action': origin.action,
    };
  }

  /// Executes pause command on ContextPlayer (from Spotify j4v & g4v).
  Future<void> pause(PauseCommand command) async {
    final payloadMap = {
      if (command.options != null)
        'options': _commandOptionsToProto(command.options),
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
      if (command.pauseOrigin != null)
        'pause_origin': _pauseResumeOriginToProto(command.pauseOrigin),
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'Pause', payloadBytes);
  }

  /// Executes resume command on ContextPlayer (from Spotify j4v & f4v).
  Future<void> resume(ResumeCommand command) async {
    final payloadMap = {
      if (command.options != null)
        'options': _commandOptionsToProto(command.options),
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
      if (command.resumeOrigin != null)
        'resume_origin': _pauseResumeOriginToProto(command.resumeOrigin),
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'Resume', payloadBytes);
  }

  /// Executes stop command on ContextPlayer (from Spotify j4v & f4v default).
  Future<void> stop(StopCommand command) async {
    await callSingle(serviceName, 'Stop', Uint8List(0));
  }

  /// Executes skip to next track command on ContextPlayer (from Spotify j4v).
  Future<void> skipToNext(SkipToNextTrackCommand command) async {
    final payloadMap = {
      if (command.options != null)
        'options': _commandOptionsToProto(command.options),
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
      if (command.track != null)
        'track': QueueProtoMappers.contextTrackToProto(command.track!),
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'SkipNext', payloadBytes);
  }

  /// Executes skip to previous track command on ContextPlayer (from Spotify j4v).
  Future<void> skipToPrev(SkipToPrevTrackCommand command) async {
    final payloadMap = {
      if (command.options != null)
        'options': _commandOptionsToProto(command.options?.commandOptions),
      if (command.options?.allowSeeking != null)
        'allow_seeking': command.options!.allowSeeking,
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
      if (command.track != null)
        'track': QueueProtoMappers.contextTrackToProto(command.track!),
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'SkipPrev', payloadBytes);
  }

  /// Executes seek to command on ContextPlayer (from Spotify j4v).
  Future<void> seekTo(SeekToCommand command) async {
    int relativeVal = 0;
    if (command.relative == SeekToCommandRelative.end) {
      relativeVal = 1;
    } else if (command.relative == SeekToCommandRelative.current) {
      relativeVal = 2;
    }

    final payloadMap = {
      if (command.options != null)
        'options': _commandOptionsToProto(command.options),
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
      'position': command.value,
      'relative': relativeVal,
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'SeekTo', payloadBytes);
  }
}
