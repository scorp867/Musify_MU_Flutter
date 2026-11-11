import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/pause_command.dart';
import 'package:musify_mu/features/player/domain/commands/resume_command.dart';
import 'package:musify_mu/features/player/domain/commands/skip_to_next_track_command.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/vault/data/strategies/continue_masked_lock_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/finish_current_track_lock_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/stop_immediately_lock_strategy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';

/// Test double simulating [ContextPlayerControlClient] without native FFI transport.
class FakeControlClient implements ContextPlayerControlClient {
  int stopCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;
  int skipToNextCallCount = 0;
  StopCommand? lastStopCommand;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCallCount++;
    lastStopCommand = command;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async {
    pauseCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async {
    resumeCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async {
    skipToNextCallCount++;
    return PlayerResponse.success;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Test double simulating [PlayerQueueMobiusController] in memory.
class FakeMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final List<QueueEvent> dispatchedEvents = <QueueEvent>[];
  final StreamController<QueueModel> _streamController =
      StreamController<QueueModel>.broadcast();
  final QueueModel _model = const QueueModel();
  bool _closed = false;

  final FakeControlClient fakeControlClient = FakeControlClient();

  @override
  ContextPlayerControlClient get controlClient => fakeControlClient;

  @override
  QueueModel get model => _model;

  @override
  QueueModel get state => _model;

  @override
  QueueModel get value => _model;

  @override
  Stream<QueueModel> get stream => _streamController.stream;

  @override
  bool get isClosed => _closed;

  @override
  void dispatch(QueueEvent event) {
    dispatchedEvents.add(event);
  }

  @override
  void add(QueueEvent event) {
    dispatch(event);
  }

  @override
  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {}

  @override
  Future<void> close() async {
    _closed = true;
    await _streamController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StopImmediatelyLockStrategy Unit Tests', () {
    const strategy = StopImmediatelyLockStrategy();

    test('behavior is stopImmediately', () {
      expect(strategy.behavior, LockPlaybackBehaviorEnum.stopImmediately);
    });

    test('executeLock calls stop on control client and clears/resets queue', () async {
      final mobiusController = FakeMobiusController();
      final controlClient = mobiusController.fakeControlClient;

      await strategy.executeLock(
        mobiusController: mobiusController,
        playerControlClient: controlClient,
      );

      expect(controlClient.stopCallCount, 1);
      expect(mobiusController.dispatchedEvents.length, 2);
      expect(mobiusController.dispatchedEvents[0], isA<ClearQueueEvent>());
      expect(mobiusController.dispatchedEvents[1], isA<ResetQueueEvent>());

      await mobiusController.close();
    });
  });

  group('FinishCurrentTrackLockStrategy Unit Tests', () {
    const strategy = FinishCurrentTrackLockStrategy();

    test('behavior is finishCurrentTrack', () {
      expect(strategy.behavior, LockPlaybackBehaviorEnum.finishCurrentTrack);
    });

    test('executeLock clears lookahead queue but does NOT stop active playback', () async {
      final mobiusController = FakeMobiusController();
      final controlClient = mobiusController.fakeControlClient;

      await strategy.executeLock(
        mobiusController: mobiusController,
        playerControlClient: controlClient,
      );

      expect(controlClient.stopCallCount, 0);
      expect(mobiusController.dispatchedEvents.length, 1);
      expect(mobiusController.dispatchedEvents.first, isA<ClearQueueEvent>());

      await mobiusController.close();
    });
  });

  group('ContinueMaskedLockStrategy Unit Tests', () {
    const strategy = ContinueMaskedLockStrategy();

    test('behavior is continueMaskedInBackground', () {
      expect(
        strategy.behavior,
        LockPlaybackBehaviorEnum.continueMaskedInBackground,
      );
    });

    test('executeLock performs no stop and leaves queue untouched for continuous background playback', () async {
      final mobiusController = FakeMobiusController();
      final controlClient = mobiusController.fakeControlClient;

      await strategy.executeLock(
        mobiusController: mobiusController,
        playerControlClient: controlClient,
      );

      expect(controlClient.stopCallCount, 0);
      expect(mobiusController.dispatchedEvents.isEmpty, isTrue);

      await mobiusController.close();
    });
  });
}
