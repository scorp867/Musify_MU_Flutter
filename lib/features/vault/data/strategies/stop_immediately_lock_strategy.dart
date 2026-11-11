import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';

/// Concrete lock strategy that halts audio playback immediately and purges
/// private queue entries from memory upon vault lock.
///
/// Dispatches a stop command to the native audio engine via [ContextPlayerControlClient.stop]
/// and flushes upcoming tracks from [PlayerQueueMobiusController] to prevent unauthorized replay.
class StopImmediatelyLockStrategy implements ILockPlaybackStrategy {
  /// Default const constructor.
  const StopImmediatelyLockStrategy();

  @override
  LockPlaybackBehaviorEnum get behavior =>
      LockPlaybackBehaviorEnum.stopImmediately;

  @override
  Future<void> executeLock({
    required PlayerQueueMobiusController mobiusController,
    required ContextPlayerControlClient playerControlClient,
  }) async {
    await playerControlClient.stop(const StopCommand());
    mobiusController.dispatch(const ClearQueueEvent());
    mobiusController.dispatch(const ResetQueueEvent());
  }
}
