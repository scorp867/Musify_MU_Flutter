import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/commands/add_to_queue_command.dart';
import '../../domain/commands/options/command_options.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import '../../domain/models/player_response.dart';
import 'esperanto_transport.dart';
import 'proto/es_add_to_queue_request.pb.dart' as proto_add;
import 'proto/es_command_options.pb.dart' as proto_cmd;
import 'proto/es_context_track.pb.dart' as proto_track;
import 'proto/es_get_queue_request.pb.dart' as proto_get;
import 'proto/es_logging_params.pb.dart' as proto_log;
import 'proto/es_optional.pb.dart' as proto_opt;
import 'proto/es_provided_track.pb.dart' as proto_prov;
import 'proto/es_queue.pb.dart' as proto_q;
import 'proto/es_response_with_reasons.pb.dart' as proto_resp;
import 'proto/es_set_queue_request.pb.dart' as proto_set;

/// 1:1 replica of Spotify ContextPlayer Queue Client (p.pvy).
class ContextPlayerQueueClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.player.esperanto.proto.ContextPlayer';

  /// 1:1 with pvy.f188965c
  final Stream<PlayerQueue> queueStream;

  ContextPlayerQueueClient(super.transport)
      : queueStream = _createQueueStream(transport);

  static Stream<PlayerQueue> _createQueueStream(EsperantoTransport transport) {
    // 1:1 with pvy constructor line 31:
    // FlowableRefCount(callStream("GetQueue").map(ynu).map(dal0).toFlowable().refCount())
    return transport
        .callStream(
          serviceName,
          'GetQueue',
          proto_get.GetQueueRequest().writeToBuffer(),
        )
        .map((bytes) {
          if (bytes.isEmpty) {
            throw const FormatException('Empty queue payload received');
          }
          final queueProto = proto_q.Queue.fromBuffer(bytes);
          final builder = PlayerQueue.builder()
              .revision(queueProto.queueRevision.toString());
          if (queueProto.hasTrack()) {
            builder.track(_fromProvidedTrackProto(queueProto.track));
          }
          if (queueProto.nextTracks.isNotEmpty) {
            builder.nextTracks(
              queueProto.nextTracks.map(_fromProvidedTrackProto).toList(),
            );
          }
          if (queueProto.prevTracks.isNotEmpty) {
            builder.prevTracks(
              queueProto.prevTracks.map(_fromProvidedTrackProto).toList(),
            );
          }
          return builder.build();
        })
        .asBroadcastStream();
  }

  /// Backward-compatible alias matching queueStream
  Stream<PlayerQueue> getQueueStream() => queueStream;

  /// 1:1 with pvy.m72158a(ContextTrack contextTrack)
  Future<PlayerResponse> addToQueue(
    Object trackOrCommand, {
    CommandOptions? options,
    LoggingParams? loggingParams,
  }) async {
    final AddToQueueCommand command;
    if (trackOrCommand is ContextTrack) {
      final builder = AddToQueueCommand.builder(trackOrCommand);
      if (options case final opt?) {
        builder.options(opt);
      }
      if (loggingParams case final lp?) {
        builder.loggingParams(lp);
      }
      command = builder.build();
    } else if (trackOrCommand is AddToQueueCommand) {
      command = trackOrCommand;
    } else {
      throw ArgumentError(
        'Expected ContextTrack or AddToQueueCommand, got ${trackOrCommand.runtimeType}',
      );
    }
    return addToQueueWithCommand(command);
  }

  /// 1:1 with pvy.m72158a via AddToQueueCommand
  Future<PlayerResponse> addToQueueWithCommand(
      AddToQueueCommand command) async {
    final req = proto_add.AddToQueueRequest();
    if (command.options case final options?) {
      req.options = _toCommandOptionsProto(options);
    }

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);
    req.track = _toContextTrackProto(command.track);

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'AddToQueue',
      payloadBytes,
    );

    // 1:1 with j1g.f110845T0 -> b1l0.f20856c1 -> dsl1.m39189n
    final responseProto =
        proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(responseProto);
  }

  /// 1:1 with pvy.m72159b(SetQueueCommand setQueueCommand)
  Future<PlayerResponse> setQueue(SetQueueCommand command) async {
    final req = proto_set.SetQueueRequest();
    if (command.options case final options?) {
      req.options = _toCommandOptionsProto(options);
    }

    final queueRevisionInt64 =
        switch (Int64.tryParseInt(command.queueRevision)) {
      final rev? => rev,
      null => null,
    };
    if (queueRevisionInt64 == null) {
      // 1:1 with pvy.java line 70-71: catch (NumberFormatException) -> png.m71652b("Invalid revision")
      return const PlayerResponseFailure('Invalid revision');
    }

    req.queueRevision = queueRevisionInt64;

    final decoratedLoggingParams =
        _decorateLoggingParams(command.loggingParams);
    req.loggingParams = _toLoggingParamsProto(decoratedLoggingParams);

    // 1:1 with pvy.java lines 55-61: nextTracks
    final nextList = <proto_prov.ProvidedTrack>[];
    for (final track in command.nextTracks) {
      nextList.add(_toProvidedTrackProto(track));
    }
    req.nextTracks.addAll(nextList);

    // 1:1 with pvy.java lines 62-68: prevTracks
    final prevList = <proto_prov.ProvidedTrack>[];
    for (final track in command.prevTracks) {
      prevList.add(_toProvidedTrackProto(track));
    }
    req.prevTracks.addAll(prevList);

    final payloadBytes = Uint8List.fromList(req.writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'SetQueue',
      payloadBytes,
    );

    // 1:1 with o2l1.f168640S0 -> a170.f9778S0 -> dsl1.m39189n
    final responseProto =
        proto_resp.ResponseWithReasons.fromBuffer(responseBytes);
    return _parseResponseWithReasons(responseProto);
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
    return p;
  }

  // 1:1 with frl.m45006c: ContextTrack -> EsProvidedTrack
  static proto_prov.ProvidedTrack _toProvidedTrackProto(ContextTrack track) {
    final p = proto_prov.ProvidedTrack()
      ..contextTrack = _toContextTrackProto(track);
    if (track.provider.isNotEmpty) {
      p.provider = track.provider;
    }
    return p;
  }

  // 1:1 with frl.m45004a: EsProvidedTrack -> ContextTrack
  static ContextTrack _fromProvidedTrackProto(proto_prov.ProvidedTrack p) {
    final trackProto = p.contextTrack;
    final builder = ContextTrack.builder(trackProto.uri);
    if (trackProto.uid.isNotEmpty) {
      builder.uid(trackProto.uid);
    }
    if (trackProto.metadata.isNotEmpty) {
      builder.metadata(Map<String, String>.from(trackProto.metadata));
    }
    final built = builder.build().toBuilder();
    if (p.provider.isNotEmpty) {
      built.provider(p.provider);
    }
    return built.build();
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
