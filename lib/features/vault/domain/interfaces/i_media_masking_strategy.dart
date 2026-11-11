import 'dart:async';

import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';

/// Pure strategy interface defining audio metadata transformation for public surfaces
/// (Harel Region B: Playback Privacy Proxy).
///
/// Dictates whether outgoing track metadata broadcast to OS MediaSession, Android Auto,
/// lockscreen, and Bluetooth AVRCP is projected with user-customizable decoy persona fields
/// or original decrypted metadata.
abstract interface class IMediaMaskingStrategy {
  /// The metadata visibility policy variant associated with this strategy.
  MetadataVisibilityPolicyEnum get policy;

  /// Transforms the [originalMetadata] map according to the strategy's rule and [config].
  ///
  /// Under placeholder masking, substitutes decoy persona strings (`decoyTitle`, `decoyArtist`,
  /// `decoyAlbum`). Under actual metadata visibility, retains decrypted track values.
  Map<String, String> maskMetadata({
    required Map<String, String> originalMetadata,
    required VaultConfig config,
  });

  /// Projects [originalTrack] into a sanitized or transparent [ContextTrack]
  /// for consumption by the native audio engine and OS notification bridges.
  ContextTrack projectTrack({
    required ContextTrack originalTrack,
    required VaultConfig config,
  });
}

/// Pure strategy interface defining playback response when the Secure Vault transitions
/// to the locked state while private media is playing (Harel Region B: Playback Privacy Proxy).
///
/// Concrete implementations model `stopImmediately`, `finishCurrentTrack`, and
/// `continueMaskedInBackground`.
abstract interface class ILockPlaybackStrategy {
  /// The lock playback behavior variant associated with this strategy.
  LockPlaybackBehaviorEnum get behavior;

  /// Executes the lock behavior utilizing Musify's established [mobiusController]
  /// and [playerControlClient].
  Future<void> executeLock({
    required PlayerQueueMobiusController mobiusController,
    required ContextPlayerControlClient playerControlClient,
  });
}
