import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/set_options_command.dart';
import '../../domain/commands/set_shuffling_context_command.dart';
import 'esperanto_transport.dart';

enum RepeatMode {
  none,
  context,
  track,
}

class ContextPlayerOptionsClient extends EsperantoClientBase {
  static const String serviceName = 'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerOptionsClient(super.transport);

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

  /// Sets player options matching Spotify k4v.b.
  Future<void> setOptions(SetOptionsCommand command) async {
    final payloadMap = {
      if (command.repeatingTrack != null)
        'repeating_track': {'value': command.repeatingTrack},
      if (command.repeatingContext != null)
        'repeating_context': {'value': command.repeatingContext},
      if (command.shufflingContext != null)
        'shuffling_context': {'value': command.shufflingContext},
      if (command.playbackSpeed != null)
        'playback_speed': command.playbackSpeed,
      if (command.modes.isNotEmpty) 'modes': command.modes,
      if (command.options != null)
        'options': _commandOptionsToProto(command.options),
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'SetOptions', payloadBytes);
  }

  /// Sets shuffling context matching Spotify k4v.d.
  Future<void> setShufflingContext(SetShufflingContextCommand command) async {
    final payloadMap = {
      'shuffling_context': command.value,
      if (command.options != null)
        'options': _commandOptionsToProto(command.options),
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'SetShufflingContext', payloadBytes);
  }

  /// Convenience toggle for shuffle.
  Future<void> setShuffle(bool shuffle) {
    return setShufflingContext(SetShufflingContextCommand.create(shuffle));
  }

  /// Sets repeat mode according to Spotify k4v.setRepeatMode:
  /// Mode 0 (None): repeatingContext=false, repeatingTrack=false
  /// Mode 1 (Context): repeatingContext=true, repeatingTrack=false
  /// Mode 2 (Track): repeatingContext=true, repeatingTrack=true
  Future<void> setRepeatMode(RepeatMode mode) {
    final bool repeatingContext;
    final bool repeatingTrack;

    switch (mode) {
      case RepeatMode.none:
        repeatingContext = false;
        repeatingTrack = false;
        break;
      case RepeatMode.context:
        repeatingContext = true;
        repeatingTrack = false;
        break;
      case RepeatMode.track:
        repeatingContext = true;
        repeatingTrack = true;
        break;
    }

    final command = SetOptionsCommand.builder()
        .repeatingContext(repeatingContext)
        .repeatingTrack(repeatingTrack)
        .build();

    return setOptions(command);
  }
}
