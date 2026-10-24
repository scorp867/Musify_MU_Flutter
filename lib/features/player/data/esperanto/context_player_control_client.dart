import 'dart:async';
import 'dart:convert';
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
import '../../domain/models/pause_resume_origin.dart';
import 'esperanto_transport.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;
import 'queue_proto_mappers.dart';

/// 1:1 replica of Spotify ContextPlayer Control Client (p.j4v, p.f4v, p.g4v, p.b4v, p.c4v, p.d4v, p.e4v).
/// Emits 100% binary Protobuf payloads matching the Spotify Esperanto wire specification.
class ContextPlayerControlClient extends EsperantoClientBase {
  static const String serviceName = 'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerControlClient(super.transport);

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

  static proto.PauseResumeOrigin? _pauseResumeOriginToProto(PauseResumeOrigin? origin) {
    if (origin == null) return null;
    return proto.PauseResumeOrigin()..featureIdentifier = origin.action;
  }

  /// Executes pause command on ContextPlayer via binary Protobuf (from Spotify j4v & g4v).
  Future<void> pause(PauseCommand command) async {
    final req = proto.PauseRequest();
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;
    final po = _pauseResumeOriginToProto(command.pauseOrigin);
    if (po != null) req.pauseOrigin = po;

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'Pause', payloadBytes);
  }

  /// Executes resume command on ContextPlayer via binary Protobuf (from Spotify j4v & f4v).
  Future<void> resume(ResumeCommand command) async {
    final req = proto.ResumeRequest();
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;
    final ro = _pauseResumeOriginToProto(command.resumeOrigin);
    if (ro != null) req.resumeOrigin = ro;

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'Resume', payloadBytes);
  }

  /// Executes stop command on ContextPlayer via binary Protobuf (from Spotify j4v & e4v case 0).
  Future<void> stop(StopCommand command) async {
    final req = proto.StopRequest();
    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'Stop', payloadBytes);
  }

  /// Executes skip to next track command on ContextPlayer via binary Protobuf (from Spotify j4v & d4v).
  Future<void> skipToNext(SkipToNextTrackCommand command) async {
    final req = proto.SkipNextRequest();
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;
    if (command.track != null) {
      req.track = QueueProtoMappers.toContextTrackProto(command.track!);
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'SkipNext', payloadBytes);
  }

  /// Executes skip to previous track command on ContextPlayer via binary Protobuf (from Spotify j4v & e4v).
  Future<void> skipToPrev(SkipToPrevTrackCommand command) async {
    final req = proto.SkipPrevRequest();
    final opts = _commandOptionsToProto(command.options?.commandOptions);
    if (opts != null) req.options = opts;
    if (command.options?.allowSeeking != null) {
      req.allowSeeking = command.options!.allowSeeking!;
    }
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;
    if (command.track != null) {
      req.track = QueueProtoMappers.toContextTrackProto(command.track!);
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'SkipPrev', payloadBytes);
  }

  /// Executes seek to command on ContextPlayer via binary Protobuf (from Spotify j4v & b4v / c4v).
  Future<void> seekTo(SeekToCommand command) async {
    final req = proto.SeekToRequest()..position = Int64(command.value);
    final opts = _commandOptionsToProto(command.options);
    if (opts != null) req.options = opts;
    final lp = _loggingParamsToProto(command.loggingParams);
    if (lp != null) req.loggingParams = lp;

    if (command.relative == SeekToCommandRelative.end) {
      req.relative = proto.SeekToRequest_Relative.END;
    } else if (command.relative == SeekToCommandRelative.current) {
      req.relative = proto.SeekToRequest_Relative.CURRENT;
    } else {
      req.relative = proto.SeekToRequest_Relative.BEGINNING;
    }

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    await callSingle(serviceName, 'SeekTo', payloadBytes);
  }

  /// Executes signal command on ContextPlayer (from Spotify j4v & c4v default / d4v case 0).
  Future<void> signal(SignalCommand command) async {
    final payloadMap = {
      'signal_id': command.signalId,
      if (command.parameters != null) 'parameters': command.parameters,
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'Signal', payloadBytes);
  }

  /// Executes play as next in queue command on ContextPlayer (from Spotify j4v & yvn / qul0).
  Future<void> playAsNextInQueue(PlayAsNextInQueueCommand command) async {
    final payloadMap = {
      'tracks': command.tracks.map(QueueProtoMappers.contextTrackToProto).toList(),
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'PlayAsNextInQueue', payloadBytes);
  }
}
