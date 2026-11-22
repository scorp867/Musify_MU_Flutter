// ============================================================================
// Remote Connect Playback Duration, Timestamp Position Ticker & Queue Delimiter
// Filtering Verification Suite
// Sources:
// - Decompiled Java:
//   - `com/spotify/player/model/PlayerState.java:140-145` (`position(long)`)
//   - `p199p/o2l1.java:1289-1291` (`EsContextPlayerState.duration` -> `PlayerState.duration`)
//   - `p199p/rrs0.java:28-31` -> `p199p/jhe0.java:46-79` -> `p199p/srs0.java:13-16`
//     -> `p199p/ihe0.java:25-39` -> `p199p/e9o0.java:133-145` -> `p199p/p1r0.java:209`
//   - `p199p/bh10.java:339-361` -> `p199p/erl.java:16,40-69` (`spotify:delimiter`,
//     `spotify:meta:delimiter`, `spotify:meta*`, banned, hidden, 19+)
//   - `p199p/wos0.java:40-87` (visible-index reorder mapped onto raw `nextTracks`)
//   - `p199p/fi31.java:42-88` (next track skips/stops at delimiter)
// - Native binary (`liborbit-jni-spotify.so` arm64):
//   - `ConnectManager::onClusterUpdate` @ `0xdb3260..0xdb329c`
//   - `adjustTimestamps` @ `0xdb28c0..0xdb2968`, `0xdb35cc..0xdb3690`
//   - `ConnectPlayer::playerState` @ `0xda97a0..0xda97b4`
//   - `parseClusterProto` @ `0xdc7e84..0xdc7ed0`, `0x13bd38c..0x13bd404`
// ============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_queue_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_state_client.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/data/esperanto/player_state_proto_mappers.dart';
import 'package:musify_mu/features/player/data/esperanto/proto/spotify_esperanto_proto.dart'
    as proto;
import 'package:musify_mu/features/player/data/esperanto/queue_proto_mappers.dart';
import 'package:musify_mu/features/player/data/queue/queue_membership_checker.dart';
import 'package:musify_mu/features/player/data/queue/queue_track_filter.dart';
import 'package:musify_mu/features/player/domain/commands/set_queue_command.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';
import 'package:musify_mu/features/player/presentation/screens/queue_sheet_screen.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player.dart';

final class _FakeEsperantoStateTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStream =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> queueStream =
      StreamController<Uint8List>.broadcast();

  @override
  Future<Uint8List> callSingle(String s, String m, Uint8List p) async =>
      Uint8List(0);

  @override
  Stream<Uint8List> callStream(String service, String method, Uint8List p) {
    if (method == 'GetState') {
      return stateStream.stream;
    }
    if (method == 'GetQueue') {
      return queueStream.stream;
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String s, String m, Uint8List p) => Uint8List(0);

  Future<void> close() async {
    await stateStream.close();
    await queueStream.close();
  }
}

final class _NoopTransport implements EsperantoTransport {
  @override
  Future<Uint8List> callSingle(String s, String m, Uint8List p) async =>
      Uint8List(0);

  @override
  Stream<Uint8List> callStream(String s, String m, Uint8List p) =>
      const Stream<Uint8List>.empty();

  @override
  Uint8List callSync(String s, String m, Uint8List p) => Uint8List(0);
}

final class _RecordingQueueClient extends ContextPlayerQueueClient {
  _RecordingQueueClient() : super(_NoopTransport());

  final List<SetQueueCommand> recordedSetQueue = <SetQueueCommand>[];

  @override
  Future<PlayerResponse> setQueue(SetQueueCommand command) async {
    recordedSetQueue.add(command);
    return const PlayerResponseSuccess();
  }
}

proto.ProvidedTrack _wireProvidedTrack({
  required String uri,
  required String uid,
  String provider = 'context',
  Map<String, String> metadata = const {},
}) {
  return proto.ProvidedTrack(
    contextTrack: proto.ContextTrack(
      uri: uri,
      uid: uid,
      metadata: metadata.entries,
    ),
    provider: provider,
  );
}

void main() {
  group('Issue 1: Remote Connect Duration & Dealer Timestamp Position Interpolation', () {
    test('EsContextPlayerState protobuf decodes total duration and interpolates live position from Dealer timestamp', () {
      const int anchorEpochMs = 1700000000000;
      const int anchorPosMs = 30000;
      const int totalDurationMs = 215000;

      final wire = proto.ContextPlayerState(
        timestamp: $fixnum.Int64(anchorEpochMs),
        contextUri: 'spotify:playlist:remote123',
        track: _wireProvidedTrack(
          uri: 'spotify:track:remote_song_1',
          uid: 'rem_uid_1',
          provider: 'context',
          metadata: const {
            ContextTrackMetadata.keyTitle: 'Remote Track',
            ContextTrackMetadata.keyArtistName: 'Remote Artist',
            ContextTrackMetadata.keyDuration: '215000',
          },
        ),
        playbackSpeed: proto.OptionalDouble(value: 1.0),
        positionAsOfTimestamp: proto.OptionalInt64(
          value: $fixnum.Int64(anchorPosMs),
        ),
        duration: proto.OptionalInt64(
          value: $fixnum.Int64(totalDurationMs),
        ),
        isPlaying: true,
        isPaused: false,
        isBuffering: false,
      );

      final decoded = PlayerStateProtoMappers.fromBuffer(
        Uint8List.fromList(wire.writeToBuffer()),
      );

      expect(decoded.duration, equals(totalDurationMs));
      expect(decoded.timestamp, equals(anchorEpochMs));
      expect(decoded.positionAsOfTimestamp, equals(anchorPosMs));
      expect(decoded.playbackSpeed, equals(1.0));

      // Live position advances linearly from Dealer timestamp anchor
      expect(decoded.position(anchorEpochMs), equals(30000));
      expect(decoded.position(anchorEpochMs + 12500), equals(42500));
      // Caps cleanly at total duration (p199p/e9o0.java:138-143)
      expect(decoded.position(anchorEpochMs + 300000), equals(totalDurationMs));

      // Propagated into QueueModel via PlayerStateChangedEvent
      final next = queueMobiusUpdate(
        QueueModel.empty(),
        PlayerStateChangedEvent(decoded),
      );
      final model = next.model;
      expect(model, isNotNull);
      if (model != null) {
        expect(model.currentTrack?.uri, equals('spotify:track:remote_song_1'));
        expect(model.trackDurationMs, equals(totalDurationMs));
        expect(model.positionAt(anchorEpochMs + 10000), equals(40000));
        expect(
          model.progressAt(anchorEpochMs + 10000),
          closeTo(40000 / totalDurationMs, 0.0001),
        );
      }
    });

    test('PlayerState.position handles paused/buffering with speed=1.0, zero timestamp, clock skew, and playbackSpeed != 1.0', () {
      const int anchorMs = 1700000010000;

      // Remote paused while wire still had playbackSpeed=1.0 must stay frozen
      const pausedWithSpeed = PlayerState(
        timestamp: anchorMs,
        positionAsOfTimestamp: 45000,
        duration: 180000,
        isPlaying: true,
        isPaused: true,
        isBuffering: false,
        playbackSpeed: 1.0,
      );
      expect(pausedWithSpeed.position(anchorMs + 15000), equals(45000));

      // Remote buffering while wire had playbackSpeed=1.0 must stay frozen
      const bufferingWithSpeed = PlayerState(
        timestamp: anchorMs,
        positionAsOfTimestamp: 45000,
        duration: 180000,
        isPlaying: true,
        isPaused: false,
        isBuffering: true,
        playbackSpeed: 1.0,
      );
      expect(bufferingWithSpeed.position(anchorMs + 15000), equals(45000));

      // Zero/missing timestamp must NOT subtract 0 and slam to duration
      const missingTimestamp = PlayerState(
        timestamp: 0,
        positionAsOfTimestamp: 12000,
        duration: 180000,
        isPlaying: true,
        isPaused: false,
        isBuffering: false,
        playbackSpeed: 1.0,
      );
      expect(missingTimestamp.position(anchorMs), equals(12000));

      // Clock skew (now < timestamp) floors elapsed delta at 0 (p199p/ihe0.java:29-33)
      const futureTimestamp = PlayerState(
        timestamp: anchorMs + 5000,
        positionAsOfTimestamp: 20000,
        duration: 180000,
        isPlaying: true,
        isPaused: false,
        isBuffering: false,
        playbackSpeed: 1.0,
      );
      expect(futureTimestamp.position(anchorMs), equals(20000));

      // 1.5x podcast speed interpolates accurately
      const fastSpeed = PlayerState(
        timestamp: anchorMs,
        positionAsOfTimestamp: 10000,
        duration: 300000,
        isPlaying: true,
        isPaused: false,
        isBuffering: false,
        playbackSpeed: 1.5,
      );
      expect(fastSpeed.position(anchorMs + 10000), equals(25000));
    });

    test('QueueModel resolves duration fallback from playerState.track metadata and caps positionAt', () {
      const int anchorMs = 1700000050000;
      final trackWithMetaDuration = ContextTrack.builder('spotify:track:meta_dur')
          .uid('u_meta')
          .metadata(const {
            ContextTrackMetadata.keyTitle: 'Metadata Duration Track',
            ContextTrackMetadata.keyDuration: '120000',
          })
          .build();

      final ps = PlayerState(
        timestamp: anchorMs,
        positionAsOfTimestamp: 115000,
        duration: 0,
        isPlaying: true,
        isPaused: false,
        isBuffering: false,
        playbackSpeed: 1.0,
        track: trackWithMetaDuration,
      );

      final model = queueMobiusUpdate(
        QueueModel.empty(),
        PlayerStateChangedEvent(ps),
      ).model;
      expect(model, isNotNull);
      if (model != null) {
        expect(model.trackDurationMs, equals(120000));
        expect(model.positionAt(anchorMs + 20000), equals(120000));
        expect(model.progressAt(anchorMs + 20000), equals(1.0));
      }
    });

    testWidgets(
      'PlayerScreen updates remote total duration and resumes live position ticking immediately after pause/buffering -> resume (regression for _lastTick freeze)',
      (tester) async {
        int fakeNowMs = 1700000100000;
        final controller = PlayerQueueMobiusController(
          initialModel: const QueueModel(isLoading: false),
        );
        final scrollController = NowPlayingScrollController();
        addTearDown(() async {
          await controller.close();
          await scrollController.close();
        });

        final remoteTrack1 = ContextTrack.builder('spotify:track:remote_a')
            .uid('rem_a')
            .metadata(const {
              ContextTrackMetadata.keyTitle: 'Remote Song A',
              ContextTrackMetadata.keyArtistName: 'Desktop Artist',
              ContextTrackMetadata.keyDuration: '200000',
            })
            .build();

        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 10000, // 0:10
              duration: 200000, // 3:20
              isPlaying: true,
              isPaused: false,
              isBuffering: false,
              playbackSpeed: 1.0,
              track: remoteTrack1,
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: PlayerScreen(
              queueBloc: controller,
              scrollController: scrollController,
              nowEpochMsProvider: () => fakeNowMs,
            ),
          ),
        );
        await tester.pump();

        // Initial elapsed = 0:10, total duration = 3:20
        expect(find.text('0:10'), findsOneWidget);
        expect(find.text('3:20'), findsOneWidget);

        // Advance ticker for 6 seconds so old `_lastTick` would be stuck at ~6s
        for (int i = 0; i < 12; i++) {
          fakeNowMs += 500;
          await tester.pump(const Duration(milliseconds: 500));
        }
        // 10s + 6s = 0:16
        expect(find.text('0:16'), findsOneWidget);

        // Remote device pauses (stops _positionTicker)
        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 16000,
              duration: 200000,
              isPlaying: true,
              isPaused: true,
              isBuffering: false,
              playbackSpeed: 0.0,
              track: remoteTrack1,
            ),
          ),
        );
        await tester.pump();
        fakeNowMs += 4000;
        await tester.pump(const Duration(milliseconds: 500));
        // Must remain frozen at 0:16 while paused
        expect(find.text('0:16'), findsOneWidget);

        // Remote device resumes (restarts _positionTicker where elapsed resets to 0)
        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 16000,
              duration: 200000,
              isPlaying: true,
              isPaused: false,
              isBuffering: false,
              playbackSpeed: 1.0,
              track: remoteTrack1,
            ),
          ),
        );
        await tester.pump();

        // Advance wall clock by 5s and pump only 150ms of Ticker elapsed time.
        // Previously this froze for >6s because `_lastTick` was never reset!
        fakeNowMs += 5000;
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('0:21'), findsOneWidget);

        // Transition through buffering -> playing on a new remote track with different duration (4:05 = 245000ms)
        final remoteTrack2 = ContextTrack.builder('spotify:track:remote_b')
            .uid('rem_b')
            .metadata(const {
              ContextTrackMetadata.keyTitle: 'Remote Song B',
              ContextTrackMetadata.keyArtistName: 'Desktop Artist',
            })
            .build();
        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 0,
              duration: 0,
              isPlaying: true,
              isPaused: false,
              isBuffering: true,
              playbackSpeed: 0.0,
              track: remoteTrack2,
            ),
          ),
        );
        await tester.pump();

        // Remote track starts playing with duration=245000ms (4:05)
        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 2000,
              duration: 245000,
              isPlaying: true,
              isPaused: false,
              isBuffering: false,
              playbackSpeed: 1.0,
              track: remoteTrack2,
            ),
          ),
        );
        await tester.pump();
        expect(find.text('4:05'), findsOneWidget);

        fakeNowMs += 7000;
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('0:09'), findsOneWidget);
      },
    );

    testWidgets(
      'MiniPlayer advances remote playback progress live and pauses progress ticker during buffering',
      (tester) async {
        int fakeNowMs = 1700000200000;
        final controller = PlayerQueueMobiusController(
          initialModel: const QueueModel(isLoading: false),
        );
        addTearDown(() async {
          await controller.close();
        });

        final remoteTrack = ContextTrack.builder('spotify:track:mini_remote')
            .uid('mini_1')
            .metadata(const {
              ContextTrackMetadata.keyTitle: 'Mini Remote Song',
              ContextTrackMetadata.keyArtistName: 'Remote Artist',
            })
            .build();

        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 10000,
              duration: 100000,
              isPlaying: true,
              isPaused: false,
              isBuffering: false,
              playbackSpeed: 1.0,
              track: remoteTrack,
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: MiniPlayer(
                  queueBloc: controller,
                  nowEpochMsProvider: () => fakeNowMs,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        String readProgressValue() {
          final semantics = tester.widget<Semantics>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('mini_player_progress_bar')),
              matching: find.byType(Semantics),
            ),
          );
          return switch (semantics.properties.value) {
            final v? => v,
            null => '',
          };
        }

        expect(readProgressValue(), equals('10%'));

        // Advance remote clock by 25s -> progress ticks to 35%
        fakeNowMs += 25000;
        await tester.pump(const Duration(milliseconds: 100));
        expect(readProgressValue(), equals('35%'));

        // Buffering pauses progress advancement
        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 35000,
              duration: 100000,
              isPlaying: true,
              isPaused: false,
              isBuffering: true,
              playbackSpeed: 0.0,
              track: remoteTrack,
            ),
          ),
        );
        await tester.pump();
        fakeNowMs += 20000;
        await tester.pump(const Duration(milliseconds: 200));
        expect(readProgressValue(), equals('35%'));

        // Resume playing -> advances immediately again
        controller.dispatch(
          PlayerStateChangedEvent(
            PlayerState(
              timestamp: fakeNowMs,
              positionAsOfTimestamp: 35000,
              duration: 100000,
              isPlaying: true,
              isPaused: false,
              isBuffering: false,
              playbackSpeed: 1.0,
              track: remoteTrack,
            ),
          ),
        );
        await tester.pump();
        fakeNowMs += 15000;
        await tester.pump(const Duration(milliseconds: 100));
        expect(readProgressValue(), equals('50%'));
      },
    );
  });

  group('Issue 2: Queue Delimiter Filtering (Local & Remote Connect Queues)', () {
    test('QueueTrackFilter & queueMobiusUpdate exclude spotify:delimiter, spotify:meta:delimiter, post-delimiter tracks, spotify:meta*, banned, and hidden tracks', () {
      final wireQueue = proto.Queue(
        queueRevision: $fixnum.Int64(42),
        track: _wireProvidedTrack(
          uri: 'spotify:track:now_playing',
          uid: 'np_1',
          provider: 'context',
          metadata: const {
            ContextTrackMetadata.keyTitle: 'Now Playing',
          },
        ),
        nextTracks: [
          _wireProvidedTrack(
            uri: 'spotify:track:user_q1',
            uid: 'uq_1',
            provider: 'queue',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'User Queued Track',
              ContextTrackMetadata.keyIsQueued: 'true',
            },
          ),
          _wireProvidedTrack(
            uri: 'spotify:track:ctx_1',
            uid: 'c_1',
            provider: 'context',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'Context Track 1',
            },
          ),
          _wireProvidedTrack(
            uri: 'spotify:meta:ad_break',
            uid: 'meta_1',
            provider: 'context',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'Meta Placeholder',
            },
          ),
          _wireProvidedTrack(
            uri: 'spotify:track:hidden_1',
            uid: 'hid_1',
            provider: 'context',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'Hidden Track',
              ContextTrackMetadata.keyHidden: 'true',
            },
          ),
          _wireProvidedTrack(
            uri: 'spotify:track:banned_1',
            uid: 'ban_1',
            provider: 'context',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'Banned Track',
              ContextTrackMetadata.keyCollectionIsBanned: 'true',
            },
          ),
          _wireProvidedTrack(
            uri: 'spotify:track:ctx_2',
            uid: 'c_2',
            provider: 'context',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'Context Track 2',
            },
          ),
          _wireProvidedTrack(
            uri: 'spotify:delimiter',
            uid: 'delim_0',
            provider: 'delimiter',
          ),
          _wireProvidedTrack(
            uri: 'spotify:track:post_delim_1',
            uid: 'post_1',
            provider: 'autoplay',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'After Delimiter 1',
            },
          ),
          _wireProvidedTrack(
            uri: 'spotify:track:post_delim_2',
            uid: 'post_2',
            provider: 'context',
            metadata: const {
              ContextTrackMetadata.keyTitle: 'After Delimiter 2',
            },
          ),
        ],
      );

      final domainQueue = QueueProtoMappers.fromQueueProto(
        proto.Queue.fromBuffer(wireQueue.writeToBuffer()),
      );
      final next = queueMobiusUpdate(
        QueueModel.empty(),
        QueueUpdatedEvent(domainQueue),
      );
      final model = next.model;
      expect(model, isNotNull);
      if (model != null) {
        expect(model.userQueue.map((t) => t.uid), equals(['uq_1']));
        expect(model.contextTracks.map((t) => t.uid), equals(['c_1', 'c_2']));
        expect(
          model.visibleTracks.map((t) => t.uid),
          equals(['uq_1', 'c_1', 'c_2']),
        );
        expect(model.nextTrack?.uid, equals('uq_1'));
        expect(model.totalQueuedCount, equals(1));
        // Raw queue preserves delimiter & post-delimiter items for SetQueue
        expect(model.playerQueue.nextTracks.length, equals(9));
      }

      // Also verify spotify:meta:delimiter cuts off everything after it
      final metaDelimQueue = PlayerQueue(
        nextTracks: [
          ContextTrack.builder('spotify:meta:delimiter').uid('d0').build(),
          ContextTrack.builder('spotify:track:after_meta_delim').uid('p0').build(),
        ],
      );
      final metaNext = queueMobiusUpdate(
        QueueModel.empty(),
        QueueUpdatedEvent(metaDelimQueue),
      ).model;
      expect(metaNext?.visibleTracks, isEmpty);
      expect(metaNext?.nextTrack, isNull);

      // Verify QueueMembershipChecker honors delimiter & filter rules
      final queuedAfterDelim = PlayerQueue(
        nextTracks: [
          ContextTrack.builder('spotify:track:q_visible')
              .uid('qv')
              .provider('queue')
              .metadata(const {ContextTrackMetadata.keyIsQueued: 'true'})
              .build(),
          ContextTrack.builder('spotify:delimiter').uid('d1').build(),
        ],
      );
      expect(
        QueueMembershipChecker.isTrackQueuedByUser(
          queuedAfterDelim,
          'spotify:track:q_visible',
        ),
        isTrue,
      );
      expect(
        QueueMembershipChecker.isTrackQueuedByUser(
          queuedAfterDelim,
          'spotify:delimiter',
        ),
        isFalse,
      );

      // Verify 19+ filter option in QueueTrackFilter.partitionAndFilter
      final ageTrack = ContextTrack.builder('spotify:track:age19')
          .uid('a19')
          .metadata(const {ContextTrackMetadata.keyIs19Plus: 'true'})
          .build();
      final filteredWithAge = QueueTrackFilter.partitionAndFilter(
        [ageTrack],
        filter19Plus: true,
      );
      expect(filteredWithAge.contextTracks, isEmpty);
    });

    test('ReorderTrackEffect maps visible destination index onto raw nextTracks without crossing or losing delimiters', () async {
      final queueClient = _RecordingQueueClient();
      final u1 = ContextTrack.builder('spotify:track:u1')
          .uid('u1')
          .provider('queue')
          .metadata(const {
            ContextTrackMetadata.keyTitle: 'User 1',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();
      final c1 = ContextTrack.builder('spotify:track:c1')
          .uid('c1')
          .provider('context')
          .metadata(const {ContextTrackMetadata.keyTitle: 'Ctx 1'})
          .build();
      final c2 = ContextTrack.builder('spotify:track:c2')
          .uid('c2')
          .provider('context')
          .metadata(const {ContextTrackMetadata.keyTitle: 'Ctx 2'})
          .build();
      final delimiter = ContextTrack.builder('spotify:delimiter')
          .uid('delim')
          .provider('delimiter')
          .build();
      final post1 = ContextTrack.builder('spotify:track:post1')
          .uid('post1')
          .provider('autoplay')
          .metadata(const {ContextTrackMetadata.keyTitle: 'Post 1'})
          .build();

      final rawQueue = PlayerQueue(
        revision: 'rev_1',
        nextTracks: [u1, c1, c2, delimiter, post1],
      );
      final nextModel = queueMobiusUpdate(
        QueueModel.empty(),
        QueueUpdatedEvent(rawQueue),
      ).model;
      expect(nextModel, isNotNull);
      if (nextModel == null) {
        return;
      }

      final handler = QueueMobiusEffectHandler(
        queueClient: queueClient,
        getCurrentQueue: () => rawQueue,
        getCurrentModel: () => nextModel,
      );

      // Drag u1 (visible index 0) to end of visible queue (visible index 2 = c2)
      await handler.handleEffect(
        ReorderTrackEffect(track: u1, destinationIndex: 2),
      );

      expect(queueClient.recordedSetQueue.length, equals(1));
      final mutatedNext = queueClient.recordedSetQueue.single.nextTracks;
      // u1 lands BEFORE delimiter; delimiter and post1 stay intact at tail
      expect(
        mutatedNext.map((t) => t.uid),
        equals(['c1', 'c2', 'u1', 'delim', 'post1']),
      );
      expect(mutatedNext[2].metadata[ContextTrackMetadata.keyIsQueued], equals('false'));
    });

    testWidgets(
      'QueueSheetScreen bound to PlayerQueueMobiusController never renders spotify:delimiter or post-delimiter tracks',
      (tester) async {
        final controller = PlayerQueueMobiusController(
          initialModel: const QueueModel(isLoading: false),
        );
        addTearDown(() async {
          await controller.close();
        });

        controller.dispatch(
          QueueUpdatedEvent(
            PlayerQueue(
              revision: 'remote_rev_9',
              track: ContextTrack.builder('spotify:track:curr')
                  .uid('curr_1')
                  .metadata(const {
                    ContextTrackMetadata.keyTitle: 'Current Remote Song',
                    ContextTrackMetadata.keyArtistName: 'Remote Artist',
                  })
                  .build(),
              nextTracks: [
                ContextTrack.builder('spotify:track:uq_1')
                    .uid('uq_1')
                    .provider('queue')
                    .metadata(const {
                      ContextTrackMetadata.keyTitle: 'Visible Queued Song',
                      ContextTrackMetadata.keyArtistName: 'Artist Q',
                      ContextTrackMetadata.keyIsQueued: 'true',
                    })
                    .build(),
                ContextTrack.builder('spotify:track:ctx_1')
                    .uid('ctx_1')
                    .provider('context')
                    .metadata(const {
                      ContextTrackMetadata.keyTitle: 'Visible Context Song',
                      ContextTrackMetadata.keyArtistName: 'Artist C',
                    })
                    .build(),
                ContextTrack.builder('spotify:delimiter')
                    .uid('delim_1')
                    .provider('delimiter')
                    .metadata(const {
                      ContextTrackMetadata.keyTitle: 'Delimiter Sentinel',
                    })
                    .build(),
                ContextTrack.builder('spotify:track:post_1')
                    .uid('post_1')
                    .provider('autoplay')
                    .metadata(const {
                      ContextTrackMetadata.keyTitle: 'Post Delimiter Leak Song',
                      ContextTrackMetadata.keyArtistName: 'Hidden Artist',
                    })
                    .build(),
              ],
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: QueueSheetScreen(bloc: controller),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Current Remote Song'), findsOneWidget);
        expect(find.text('Visible Queued Song'), findsOneWidget);
        expect(find.text('Visible Context Song'), findsOneWidget);
        expect(find.text('Delimiter Sentinel'), findsNothing);
        expect(find.text('Post Delimiter Leak Song'), findsNothing);
        expect(find.text('Untitled'), findsNothing);
      },
    );
  });

  group('Task A: Remote Device Takeover Play/Pause State Transitions', () {
    test('NowPlayingViewModel maps paused-while-buffering to paused, never playing/buffering Pause icon', () {
      const pausedBufferingState = QueueModel(
        playerState: PlayerState(
          isPlaying: true,
          isPaused: true,
          isBuffering: true,
          duration: 180000,
          positionAsOfTimestamp: 30000,
        ),
      );
      final vm = NowPlayingViewModel.fromPlayerQueueState(pausedBufferingState);
      expect(vm.isPlaying, isFalse);
      expect(vm.transportPhase, equals(NowPlayingTransportPhase.paused));

      const playingBufferingState = QueueModel(
        playerState: PlayerState(
          isPlaying: true,
          isPaused: false,
          isBuffering: true,
          duration: 180000,
          positionAsOfTimestamp: 30000,
        ),
      );
      final vmPlayingBuf =
          NowPlayingViewModel.fromPlayerQueueState(playingBufferingState);
      expect(vmPlayingBuf.isPlaying, isTrue);
      expect(
        vmPlayingBuf.transportPhase,
        equals(NowPlayingTransportPhase.bufferingUnplayedSegment),
      );
    });

    test('PlayerStateProtoMappers decodes proto3 omitted-false isPaused & full EsRestrictions tags 22-30 cleanly', () {
      final remotePlayingWire = proto.ContextPlayerState(
        timestamp: $fixnum.Int64(1700000500000),
        contextUri: 'spotify:playlist:takeover',
        track: _wireProvidedTrack(
          uri: 'spotify:track:remote_takeover_1',
          uid: 'rt_1',
          metadata: const {
            ContextTrackMetadata.keyTitle: 'Takeover Track',
            ContextTrackMetadata.keyArtistName: 'Remote Artist',
            ContextTrackMetadata.keyDuration: '240000',
          },
        ),
        playbackSpeed: proto.OptionalDouble(value: 1.0),
        positionAsOfTimestamp: proto.OptionalInt64(value: $fixnum.Int64(15000)),
        duration: proto.OptionalInt64(value: $fixnum.Int64(240000)),
        isPlaying: true,
        // Proto3 zero-omission: isPaused=false and isBuffering=false omitted on wire
        restrictions: proto.Restrictions(
          disallowAddToQueueReasons: const ['not_supported'],
          disallowSettingPlaybackSpeedReasons: const ['not_supported_by_content_type'],
          disallowSettingModes: [
            MapEntry(
              'context_enhancement',
              proto.ModeRestrictions(
                values: [
                  MapEntry(
                    'NONE',
                    proto.RestrictionReasons(reasons: const ['not_supported']),
                  ),
                ],
              ),
            ),
          ],
          disallowSignals: [
            MapEntry(
              'signal_a',
              proto.RestrictionReasons(reasons: const ['unavailable']),
            ),
          ],
          disallowPlayAsNextInQueueReasons: const ['remote_only'],
          disallowSleepTimerClearReasons: const ['no_timer'],
          disallowSleepTimerDurationReasons: const ['remote_device'],
          disallowSleepTimerEndOfTrackReasons: const ['remote_device'],
        ),
      );

      final decoded = PlayerStateProtoMappers.fromBuffer(
        Uint8List.fromList(remotePlayingWire.writeToBuffer()),
      );
      expect(decoded.isPlaying, isTrue);
      expect(decoded.isPaused, isFalse);
      expect(decoded.isBuffering, isFalse);
      expect(decoded.duration, equals(240000));
      expect(
        decoded.restrictions.disallowSettingPlaybackSpeedReasons,
        contains('not_supported_by_content_type'),
      );
      expect(
        decoded.restrictions.disallowSettingModes.containsKey('context_enhancement'),
        isTrue,
      );
      expect(
        decoded.restrictions.disallowSignals.containsKey('signal_a'),
        isTrue,
      );
    });

    testWidgets(
      'Remote takeover transitions PlayerScreen and MiniPlayer cleanly from local paused -> remote playing -> remote paused -> remote playing without sticking in paused state',
      (tester) async {
        int fakeNowMs = 1700000600000;
        final transport = _FakeEsperantoStateTransport();
        final stateClient = ContextPlayerStateClient(transport);
        final queueClient = ContextPlayerQueueClient(transport);
        final controller = PlayerQueueMobiusController(
          stateClient: stateClient,
          queueClient: queueClient,
          initialModel: const QueueModel(isLoading: false),
        );
        final scrollController = NowPlayingScrollController();
        addTearDown(() async {
          await controller.close();
          await scrollController.close();
          await transport.close();
        });

        void emitWireState({
          required String trackUri,
          required String uid,
          required String title,
          required bool isPlaying,
          required bool isPaused,
          required int posMs,
          required int durationMs,
          double speed = 1.0,
          bool includeRestrictions = false,
        }) {
          final msg = proto.ContextPlayerState(
            timestamp: $fixnum.Int64(fakeNowMs),
            track: _wireProvidedTrack(
              uri: trackUri,
              uid: uid,
              metadata: {
                ContextTrackMetadata.keyTitle: title,
                ContextTrackMetadata.keyArtistName: 'Artist',
                ContextTrackMetadata.keyDuration: durationMs.toString(),
              },
            ),
            playbackSpeed: proto.OptionalDouble(value: speed),
            positionAsOfTimestamp: proto.OptionalInt64(value: $fixnum.Int64(posMs)),
            duration: proto.OptionalInt64(value: $fixnum.Int64(durationMs)),
            isPlaying: isPlaying,
            isPaused: isPaused,
            isBuffering: false,
            restrictions: includeRestrictions
                ? proto.Restrictions(
                    disallowSettingPlaybackSpeedReasons: const [
                      'not_supported_by_content_type',
                    ],
                  )
                : null,
          );
          transport.stateStream.add(Uint8List.fromList(msg.writeToBuffer()));
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Column(
              children: [
                Expanded(
                  child: PlayerScreen(
                    queueBloc: controller,
                    scrollController: scrollController,
                    nowEpochMsProvider: () => fakeNowMs,
                  ),
                ),
                MiniPlayer(
                  queueBloc: controller,
                  nowEpochMsProvider: () => fakeNowMs,
                ),
              ],
            ),
          ),
        );

        // 1. Local playback active
        emitWireState(
          trackUri: 'spotify:track:local_1',
          uid: 'loc_1',
          title: 'Local Track',
          isPlaying: true,
          isPaused: false,
          posMs: 20000,
          durationMs: 180000,
          speed: 1.0,
        );
        await tester.pump();
        await tester.pump();
        expect(controller.state.isPlaying, isTrue);
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byTooltip('Pause'), findsOneWidget);

        // 2. Remote takeover: local pauses briefly, then mirrored remote playing state arrives
        emitWireState(
          trackUri: 'spotify:track:local_1',
          uid: 'loc_1',
          title: 'Local Track',
          isPlaying: true,
          isPaused: true,
          posMs: 20000,
          durationMs: 180000,
          speed: 0.0,
        );
        await tester.pump();
        await tester.pump();
        expect(controller.state.isPlaying, isFalse);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byTooltip('Play'), findsOneWidget);

        emitWireState(
          trackUri: 'spotify:track:remote_1',
          uid: 'rem_1',
          title: 'Remote Takeover Song',
          isPlaying: true,
          isPaused: false,
          posMs: 30000,
          durationMs: 210000,
          speed: 1.0,
          includeRestrictions: true,
        );
        await tester.pump();
        await tester.pump();

        // Both PlayerScreen and MiniPlayer must immediately show Playing (Pause icon) & new duration
        expect(controller.state.isPlaying, isTrue);
        expect(controller.state.isPaused, isFalse);
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byTooltip('Pause'), findsOneWidget);
        expect(find.text('3:30'), findsOneWidget);

        // Live ticker advances remote position immediately
        fakeNowMs += 5000;
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('0:35'), findsOneWidget);

        // 3. Remote pauses -> UI shows Play icon
        emitWireState(
          trackUri: 'spotify:track:remote_1',
          uid: 'rem_1',
          title: 'Remote Takeover Song',
          isPlaying: true,
          isPaused: true,
          posMs: 35000,
          durationMs: 210000,
          speed: 0.0,
          includeRestrictions: true,
        );
        await tester.pump();
        await tester.pump();
        expect(controller.state.isPlaying, isFalse);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byTooltip('Play'), findsOneWidget);

        // 4. Remote resumes -> UI immediately switches back to Pause icon & ticks
        emitWireState(
          trackUri: 'spotify:track:remote_1',
          uid: 'rem_1',
          title: 'Remote Takeover Song',
          isPlaying: true,
          isPaused: false,
          posMs: 35000,
          durationMs: 210000,
          speed: 1.0,
          includeRestrictions: true,
        );
        await tester.pump();
        await tester.pump();
        expect(controller.state.isPlaying, isTrue);
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byTooltip('Pause'), findsOneWidget);

        fakeNowMs += 10000;
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('0:45'), findsOneWidget);
      },
    );
  });
}
