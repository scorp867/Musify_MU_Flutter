import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/options/timer_type.dart';
import '../../domain/commands/set_options_command.dart';
import '../../domain/commands/set_repeating_context_command.dart';
import '../../domain/commands/set_repeating_track_command.dart';
import '../../domain/commands/set_shuffling_context_command.dart';
import '../../domain/commands/set_sleep_timer_command.dart';
import 'esperanto_transport.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;

enum RepeatMode {
  none,
  context,
  track,
}

/// 1:1 replica of Spotify ContextPlayer Options Client (p.k4v).
/// Emits 100% binary Protobuf payloads matching the Spotify Esperanto wire specification.
class ContextPlayerOptionsClient extends EsperantoClientBase {
  static const String serviceName = 'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerOptionsClient(super.transport);

  static proto.CommandOptions? _commandOptionsToProto(CommandOptions? options) {
    if (options == null) return null;
    final p = proto.CommandOptions();
    if (options.overrideRestrictions != null) {
      p.overrideRestrictions = options.overrideRestrictions!;
    }
    if (options.onlyForPlaybackId != null) {
      p.onlyForPlaybackId = utf8.encode(options.onlyForPlaybackId!);
    }
    if (options.systemInitiated != null) {
      p.systemInitiated = options.systemInitiated!;
    }
    if (options.onlyForLocalDevice != null) {
      p.onlyForLocalDevice = options.onlyForLocalDevice!;
    }
    return p;
  }

  static proto.LoggingParams? _loggingParamsToProto(LoggingParams? params) {
    if (params == null) return null;
    final p = proto.LoggingParams();
    if (params.pageInstanceIds.isNotEmpty) {
      p.pageInstanceIds.addAll(params.pageInstanceIds);
    }
    if (params.interactionIds.isNotEmpty) {
      p.interactionIds.addAll(params.interactionIds);
    }
    return p;
  }

  /// Sets player options matching Spotify k4v.b via binary Protobuf.
  Future<void> setOptions(SetOptionsCommand command) async {
    final req = proto.SetOptionsRequest();
    if (command.repeatingTrack != null) {
      req.repeatingTrack = proto.OptionalBoolean()
        ..value = command.repeatingTrack!;
    }
    if (command.repeatingContext != null) {
      req.repeatingContext = proto.OptionalBoolean()
        ..value = command.repeatingContext!;
    }
    if (command.shufflingContext != null) {
      req.shufflingContext = proto.OptionalBoolean()
        ..value = command.shufflingContext!;
    }
    if (command.playbackSpeed != null) {
      req.playbackSpeed = command.playbackSpeed!;
    }
    if (command.modes.isNotEmpty) {
      req.modes.addEntries(command.modes.entries);
    }
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'SetOptions', payloadBytes);
  }

  /// Sets shuffling context matching Spotify k4v.d via binary Protobuf.
  Future<void> setShufflingContext(SetShufflingContextCommand command) async {
    final req = proto.SetShufflingContextRequest()
      ..shufflingContext = command.value;
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'SetShufflingContext', payloadBytes);
  }

  /// Sets repeating context matching Spotify k4v.c via binary Protobuf.
  Future<void> setRepeatingContext(SetRepeatingContextCommand command) async {
    final req = proto.SetRepeatingContextRequest()
      ..repeatingContext = command.value;
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'SetRepeatingContext', payloadBytes);
  }

  /// Sets repeating track matching Spotify k4v.c via binary Protobuf.
  Future<void> setRepeatingTrack(SetRepeatingTrackCommand command) async {
    final req = proto.SetRepeatingTrackRequest()
      ..repeatingTrack = command.value;
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'SetRepeatingTrack', payloadBytes);
  }

  /// Sets sleep timer matching Spotify sleep timer command.
  Future<void> setSleepTimer(SetSleepTimerCommand command) async {
    final Map<String, dynamic> timerMap;
    final timerType = command.timerType;
    if (timerType is TimerTypeDuration) {
      timerMap = {'duration': timerType.durationSeconds};
    } else if (timerType is TimerTypeEndOfTrack) {
      timerMap = {'end_of_track': true};
    } else {
      timerMap = {'clear': true};
    }

    final payloadMap = {
      'timer_type': timerMap,
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
          if (command.loggingParams!.pageInstanceIds.isNotEmpty)
            'page_instance_ids': command.loggingParams!.pageInstanceIds.toList(),
          if (command.loggingParams!.interactionIds.isNotEmpty)
            'interaction_ids': command.loggingParams!.interactionIds.toList(),
        },
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'SetSleepTimer', payloadBytes);
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
