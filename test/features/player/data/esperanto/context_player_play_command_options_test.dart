import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/navigation/spotify_navigator_impl.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_play_client.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/data/esperanto/proto/es_play.pb.dart'
    as proto_play;
import 'package:musify_mu/features/player/data/esperanto/proto/es_play_options.pb.dart'
    as proto_plo;
import 'package:musify_mu/features/player/data/esperanto/proto/es_response_with_reasons.pb.dart'
    as proto_resp;
import 'package:musify_mu/features/player/domain/commands/options/command_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/play_operation.dart';
import 'package:musify_mu/features/player/domain/commands/options/play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/play_trigger.dart';
import 'package:musify_mu/features/player/domain/commands/play_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';

final class _CapturingPlayTransport implements EsperantoTransport {
  proto_play.PlayRequest? lastPlayRequest;
  proto_resp.ResponseWithReasons nextResponse = proto_resp.ResponseWithReasons(
    error: proto_resp.ResponseWithReasons_Error.OK,
  );

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    if (method == 'Play') {
      lastPlayRequest = proto_play.PlayRequest.fromBuffer(payload);
    }
    return Uint8List.fromList(nextResponse.writeToBuffer());
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) =>
      const Stream<Uint8List>.empty();

  @override
  Uint8List callSync(String service, String method, Uint8List payload) =>
      Uint8List(0);
}

void main() {
  group('Bug 1 Dart Fixes: PlayCommand.commandOptions, PlayOptions(replace, immediately), and canonical standalone Context', () {
    test('PlayCommand preserves commandOptions across constructor, builder, toBuilder, and equality', () {
      const cmdOptions = CommandOptions(
        overrideRestrictions: true,
        onlyForLocalDevice: true,
        systemInitiated: false,
        onlyForPlaybackId: 'pb-123',
      );
      final cmd1 = PlayCommand.builder(
        Context.fromUri('spotify:track:abc'),
        PlayOrigin.create('home'),
      )
          .playOptions(
            const PlayOptions(
              operation: PlayOperation.replace,
              trigger: PlayTrigger.immediately,
            ),
          )
          .commandOptions(cmdOptions)
          .build();

      final cmd2 = cmd1.toBuilder().build();
      expect(cmd1.commandOptions, equals(cmdOptions));
      expect(cmd2, equals(cmd1));
      expect(cmd2.hashCode, equals(cmd1.hashCode));
    });

    test('ContextPlayerPlayClient.play serializes PlayCommand.commandOptions and PlayOptions(replace, immediately) into PlayRequest', () async {
      final transport = _CapturingPlayTransport();
      final client = ContextPlayerPlayClient(transport);

      final command = PlayCommand(
        context: Context.fromUri('spotify:track:standalone1'),
        playOrigin: PlayOrigin.create('search'),
        playOptions: const PlayOptions(
          operation: PlayOperation.replace,
          trigger: PlayTrigger.immediately,
        ),
        commandOptions: const CommandOptions(
          onlyForLocalDevice: true,
          systemInitiated: true,
          overrideRestrictions: true,
          onlyForPlaybackId: 'playback-99',
        ),
      );

      final response = await client.play(command);
      expect(response, isA<PlayerResponseSuccess>());

      final req = transport.lastPlayRequest;
      expect(req, isNotNull);
      if (req != null) {
        expect(req.hasOptions(), isTrue);
        expect(req.options.onlyForLocalDevice, isTrue);
        expect(req.options.systemInitiated, isTrue);
        expect(req.options.overrideRestrictions, isTrue);
        expect(utf8.decode(req.options.onlyForPlaybackId), equals('playback-99'));
        expect(
          req.playOptions.operation,
          equals(proto_plo.PlayOptions_Operation.REPLACE),
        );
        expect(
          req.playOptions.trigger,
          equals(proto_plo.PlayOptions_Trigger.IMMEDIATELY),
        );
      }

      // Fallback: when PlayCommand.commandOptions is null, serialize non-empty PlayOptions.commandOptions
      final fallbackCmd = PlayCommand(
        context: Context.fromUri('spotify:track:standalone2'),
        playOrigin: PlayOrigin.create('home'),
        playOptions: const PlayOptions(
          operation: PlayOperation.replace,
          trigger: PlayTrigger.immediately,
          commandOptions: CommandOptions(onlyForLocalDevice: true),
        ),
      );
      await client.play(fallbackCmd);
      expect(transport.lastPlayRequest?.hasOptions(), isTrue);
      expect(transport.lastPlayRequest?.options.onlyForLocalDevice, isTrue);
    });

    testWidgets('SpotifyNavigatorImpl.dispatchPlayUri dispatches canonical Context.fromUri(uri), PlayOptions(replace, immediately), and propagates PlayerResponseFailure', (tester) async {
      final transport = _CapturingPlayTransport();
      final playClient = ContextPlayerPlayClient(transport);

      final hadExisting = getIt.isRegistered<ContextPlayerPlayClient>();
      ContextPlayerPlayClient? existingClient;
      if (hadExisting) {
        existingClient = getIt<ContextPlayerPlayClient>();
        getIt.unregister<ContextPlayerPlayClient>();
      }
      getIt.registerSingleton<ContextPlayerPlayClient>(playClient);
      addTearDown(() {
        if (getIt.isRegistered<ContextPlayerPlayClient>()) {
          getIt.unregister<ContextPlayerPlayClient>();
        }
        if (existingClient case final prev?) {
          getIt.registerSingleton<ContextPlayerPlayClient>(prev);
        }
      });

      BuildContext? capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final ctx = capturedContext;
      expect(ctx, isNotNull);
      if (ctx == null) return;

      const trackUri = 'spotify:track:4uLU6hMCjMI75M1A2tKUQC';
      final ok = await SpotifyNavigatorImpl.dispatchPlayUri(
        ctx,
        trackUri,
        track: ContextTrack.builder(trackUri)
            .metadata(const <String, String>{'title': 'Never Gonna Give You Up'})
            .build(),
      );
      expect(ok, isTrue);

      final req = transport.lastPlayRequest;
      expect(req, isNotNull);
      if (req != null) {
        expect(req.preparePlayRequest.context.uri, equals(trackUri));
        expect(
          req.preparePlayRequest.context.url,
          equals('context://$trackUri'),
        );
        expect(req.preparePlayRequest.context.pages, hasLength(1));
        // Must NOT fabricate bogus ?page=0 URL on standalone inline page
        expect(req.preparePlayRequest.context.pages.single.pageUrl, isEmpty);
        expect(
          req.preparePlayRequest.context.pages.single.tracks.single.uri,
          equals(trackUri),
        );
        expect(
          req.playOptions.operation,
          equals(proto_plo.PlayOptions_Operation.REPLACE),
        );
        expect(
          req.playOptions.trigger,
          equals(proto_plo.PlayOptions_Trigger.IMMEDIATELY),
        );
      }

      // Failure response returns false instead of silently reporting true
      transport.nextResponse = proto_resp.ResponseWithReasons(
        error: proto_resp.ResponseWithReasons_Error.FAILED,
        reasons: 'REMOTE_COMMAND_FAILED',
      );
      final failed = await SpotifyNavigatorImpl.dispatchPlayUri(ctx, trackUri);
      expect(failed, isFalse);
    });
  });
}
