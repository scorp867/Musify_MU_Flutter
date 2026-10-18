import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/options/play_options.dart';
import '../../domain/commands/options/prepare_play_options.dart';
import '../../domain/commands/play_command.dart';
import '../../domain/commands/prepare_play_command.dart';
import '../../domain/models/context.dart';
import '../../domain/models/play_origin.dart';
import 'esperanto_transport.dart';

class ContextPlayerPlayClient extends EsperantoClientBase {
  static const String serviceName = 'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerPlayClient(super.transport);

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

  static Map<String, dynamic> _contextToProto(Context context) {
    return {
      'uri': context.uri,
      'url': context.url,
      if (context.metadata.isNotEmpty) 'metadata': context.metadata,
      if (context.pages != null && context.pages!.isNotEmpty)
        'pages': context.pages!.map((p) => {
              if (p.pageUrl.isNotEmpty) 'page_url': p.pageUrl,
              if (p.nextPageUrl.isNotEmpty) 'next_page_url': p.nextPageUrl,
              if (p.metadata.isNotEmpty) 'metadata': p.metadata,
              if (p.tracks != null && p.tracks!.isNotEmpty)
                'tracks': p.tracks!.map((t) => {
                      if (t.uri.isNotEmpty) 'uri': t.uri,
                      if (t.uid.isNotEmpty) 'uid': t.uid,
                      if (t.metadata.isNotEmpty) 'metadata': t.metadata,
                    }).toList(),
            }).toList(),
    };
  }

  static Map<String, dynamic> _playOriginToProto(PlayOrigin origin) {
    return {
      'feature_identifier': origin.featureIdentifier,
      if (origin.featureVersion.isNotEmpty)
        'feature_version': origin.featureVersion,
      if (origin.viewUri.isNotEmpty) 'view_uri': origin.viewUri,
      if (origin.externalReferrer.isNotEmpty)
        'external_referrer': origin.externalReferrer,
      if (origin.referrerIdentifier.isNotEmpty)
        'referrer_identifier': origin.referrerIdentifier,
      if (origin.deviceIdentifier.isNotEmpty)
        'device_identifier': origin.deviceIdentifier,
      if (origin.restrictionIdentifier.isNotEmpty)
        'restriction_identifier': origin.restrictionIdentifier,
      if (origin.featureClasses.isNotEmpty)
        'feature_classes': origin.featureClasses.toList(),
    };
  }

  static Map<String, dynamic> _preparePlayOptionsToProto(PreparePlayOptions? options) {
    if (options == null) return const {};
    return {
      if (options.alwaysPlaySomething != null)
        'always_play_something': options.alwaysPlaySomething,
      if (options.skipTo != null)
        'skip_to': {
          if (options.skipTo!.pageIndex != null)
            'page_index': options.skipTo!.pageIndex,
          if (options.skipTo!.pageUrl != null)
            'page_url': options.skipTo!.pageUrl,
          if (options.skipTo!.trackIndex != null)
            'track_index': options.skipTo!.trackIndex,
          if (options.skipTo!.trackUid != null)
            'track_uid': options.skipTo!.trackUid,
          if (options.skipTo!.trackUri != null)
            'track_uri': options.skipTo!.trackUri,
        },
      if (options.seekTo != null) 'seek_to': options.seekTo,
      if (options.initiallyPaused != null)
        'initially_paused': options.initiallyPaused,
      if (options.systemInitiated != null)
        'system_initiated': options.systemInitiated,
    };
  }

  static Map<String, dynamic> _playOptionsToProto(PlayOptions? options) {
    if (options == null) return const {};
    return {
      if (options.operation != null)
        'operation': options.operation!.name,
      if (options.trigger != null) 'trigger': options.trigger!.name,
    };
  }

  /// Executes PlayCommand matching Spotify y3v.a.
  Future<void> play(PlayCommand command) async {
    final preparePlayRequest = {
      'context': _contextToProto(command.context),
      if (command.options != null)
        'options': _preparePlayOptionsToProto(command.options),
      'play_origin': _playOriginToProto(command.playOrigin),
    };

    final payloadMap = {
      'prepare_play_request': preparePlayRequest,
      if (command.playOptions != null)
        'play_options': _playOptionsToProto(command.playOptions),
      if (command.loggingParams != null)
        'logging_params': _loggingParamsToProto(command.loggingParams),
    };

    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'Play', payloadBytes);
  }

  /// Executes PreparePlayCommand matching Spotify y3v.b.
  Future<void> preparePlay(PreparePlayCommand command) async {
    final payloadMap = {
      'context': _contextToProto(command.context),
      if (command.options != null)
        'options': _preparePlayOptionsToProto(command.options),
      'play_origin': _playOriginToProto(command.playOrigin),
    };

    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));
    await callSingle(serviceName, 'PreparePlay', payloadBytes);
  }
}
