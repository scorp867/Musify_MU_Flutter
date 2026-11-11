import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';

/// Concrete lock strategy that permits the currently playing private track to complete,
/// while purging subsequent queued tracks so audio ceases naturally at track end.
///
/// Prevents upcoming tracks from beginning by dispatching [ClearQueueEvent] to
/// [PlayerQueueMobiusController], while allowing the currently decoding native buffer
/// to finish uninterrupted.
class FinishCurrentTrackLockStrategy implements ILockPlaybackStrategy {
  /// Default const constructor.
  const FinishCurrentTrackLockStrategy();

  @override
  LockPlaybackBehaviorEnum get behavior =>
      LockPlaybackBehaviorEnum.finishCurrentTrack;

  @override
  Future<void> executeLock({
    required PlayerQueueMobiusController mobiusController,
    required ContextPlayerControlClient playerControlClient,
  }) async {
    mobiusController.dispatch(const ClearQueueEvent());
  }
}
