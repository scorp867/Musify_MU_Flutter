import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';

/// Models the privacy boundary between public playback and encrypted vault playback.
enum PlaybackPrivacyModeEnum {
  /// Playing standard public tracks; zero proxy interception.
  publicPassthrough,

  /// Playing a vault track; proxy intercepts and sanitizes metadata.
  vaultTrackActive;

  /// Returns whether the active playback belongs to the secure vault.
  bool get isVaultTrack => this == PlaybackPrivacyModeEnum.vaultTrackActive;

  /// Returns whether public passthrough is active with zero metadata masking.
  bool get isPublicPassthrough => this == PlaybackPrivacyModeEnum.publicPassthrough;
}

/// Models the active projection state of outgoing metadata for private playback.
enum PlaybackMaskingStatusEnum {
  /// Unmasked; original decrypted title, artist, album projected to media session.
  unmasked,

  /// Masked; user-configured decoy persona fields projected to media session and AVRCP.
  decoyPersonaProjected,
}

/// Deeply immutable sealed state hierarchy for David Harel Statechart Region B (Playback Privacy Proxy).
@immutable
sealed class PlaybackPrivacyState extends Equatable {
  const PlaybackPrivacyState();

  /// The active privacy mode discriminator.
  PlaybackPrivacyModeEnum get modeEnum;

  @override
  List<Object?> get props => [];
}

/// Standard public track playback with zero interception.
@immutable
final class PlaybackPrivacyPublicPassthroughState extends PlaybackPrivacyState {
  const PlaybackPrivacyPublicPassthroughState();

  @override
  PlaybackPrivacyModeEnum get modeEnum => PlaybackPrivacyModeEnum.publicPassthrough;
}

/// Private vault track is actively playing or paused.
@immutable
final class PlaybackPrivacyVaultTrackActiveState extends PlaybackPrivacyState {
  const PlaybackPrivacyVaultTrackActiveState({
    required this.vaultTrackId,
    required this.maskingStatus,
    required this.visibilityPolicy,
  });

  /// The unique identifier of the private track being played.
  final String vaultTrackId;

  /// The active projection status (unmasked vs decoy persona).
  final PlaybackMaskingStatusEnum maskingStatus;

  /// The configured metadata visibility policy.
  final MetadataVisibilityPolicyEnum visibilityPolicy;

  @override
  PlaybackPrivacyModeEnum get modeEnum => PlaybackPrivacyModeEnum.vaultTrackActive;

  @override
  List<Object?> get props => [vaultTrackId, maskingStatus, visibilityPolicy];
}

/// Vault was locked while a private track was playing; executing configured lock strategy.
@immutable
final class PlaybackPrivacyExecutingLockStrategyState extends PlaybackPrivacyState {
  const PlaybackPrivacyExecutingLockStrategyState({
    required this.activeVaultTrackId,
    required this.executingBehavior,
  });

  /// The unique identifier of the vault track that was playing when lock occurred.
  final String activeVaultTrackId;

  /// The active lock playback behavior being executed.
  final LockPlaybackBehaviorEnum executingBehavior;

  @override
  PlaybackPrivacyModeEnum get modeEnum => PlaybackPrivacyModeEnum.vaultTrackActive;

  @override
  List<Object?> get props => [activeVaultTrackId, executingBehavior];
}
