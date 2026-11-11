import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';

/// Concrete lock strategy that maintains uninterrupted background audio playback
/// upon vault lock, while enforcing decoy persona metadata masking across OS surfaces.
///
/// Permits continuous playback of the private audio stream while the vault UI is secured,
/// relying on [PlaybackPrivacyProxy] in [PlaybackPrivacyExecutingLockStrategyState] to project
/// configured decoy metadata to OS media controls, Android Auto, and Bluetooth AVRCP.
class ContinueMaskedLockStrategy implements ILockPlaybackStrategy {
  /// Default const constructor.
  const ContinueMaskedLockStrategy();

  @override
  LockPlaybackBehaviorEnum get behavior =>
      LockPlaybackBehaviorEnum.continueMaskedInBackground;

  @override
  Future<void> executeLock({
    required PlayerQueueMobiusController mobiusController,
    required ContextPlayerControlClient playerControlClient,
  }) async {
    // Playback continues uninterrupted in the native audio engine.
    // Decoy persona masking is strictly enforced by PlaybackPrivacyProxy.
  }
}
