import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';

/// Deeply immutable aggregate configuration entity encapsulating all user policies,
/// security intervals, and decoy persona fields for the Secure Vault.
///
/// Strictly enforces the Zero Loose Booleans mandate: all configurations are governed
/// strictly by domain policy enums rather than loose booleans.
@immutable
class VaultConfig extends Equatable {
  /// Active visual theme palette policy.
  final VaultThemePalettePolicyEnum themePalette;

  /// Hardware biometric capability policy.
  final BiometricAuthPolicyEnum biometricAuth;

  /// Inactivity interval before requiring step-up re-authentication.
  final ActiveReauthIntervalEnum activeReauthInterval;

  /// Background grace period duration before auto-locking.
  final BackgroundGraceTimeoutEnum backgroundGraceTimeout;

  /// Android FLAG_SECURE window privacy policy.
  final ScreenSecurityPolicyEnum screenSecurity;

  /// Public media session metadata masking policy.
  final MetadataVisibilityPolicyEnum metadataVisibility;

  /// Decoy track title projected to OS media sessions when masking is active.
  final String decoyTitle;

  /// Decoy artist name projected to OS media sessions when masking is active.
  final String decoyArtist;

  /// Decoy album title projected to OS media sessions when masking is active.
  final String decoyAlbum;

  /// Behavior executed when the vault locks during active playback.
  final LockPlaybackBehaviorEnum lockPlaybackBehavior;

  /// Sensitivity threshold tier for the stealth gesture classifier ensemble.
  final GestureSensitivityTierEnum gestureSensitivity;

  /// Visual ink visibility policy for the stealth gesture sensor pad.
  final GestureVisibilityPolicyEnum gestureVisibility;

  /// Keypad digit layout randomization policy for the PIN pad.
  final KeypadLayoutPolicyEnum keypadLayout;

  /// Constructs a validated [VaultConfig] instance.
  ///
  /// Throws [FormatException] if any decoy persona field is empty or whitespace.
  VaultConfig({
    this.themePalette = VaultThemePalettePolicyEnum.warmEspresso,
    this.biometricAuth = BiometricAuthPolicyEnum.pinOnly,
    this.activeReauthInterval = ActiveReauthIntervalEnum.every15Minutes,
    this.backgroundGraceTimeout = BackgroundGraceTimeoutEnum.thirtySeconds,
    this.screenSecurity = ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
    this.metadataVisibility = MetadataVisibilityPolicyEnum.maskWithPlaceholder,
    this.decoyTitle = 'System Audio',
    this.decoyArtist = 'Media Service',
    this.decoyAlbum = 'Internal Playback',
    this.lockPlaybackBehavior = LockPlaybackBehaviorEnum.continueMaskedInBackground,
    this.gestureSensitivity = GestureSensitivityTierEnum.balanced84Percent,
    this.gestureVisibility = GestureVisibilityPolicyEnum.invisibleStealth,
    this.keypadLayout = KeypadLayoutPolicyEnum.standardOrdered,
  }) {
    if (decoyTitle.trim().isEmpty) {
      throw const FormatException('VaultConfig decoyTitle must not be empty.');
    }
    if (decoyArtist.trim().isEmpty) {
      throw const FormatException('VaultConfig decoyArtist must not be empty.');
    }
    if (decoyAlbum.trim().isEmpty) {
      throw const FormatException('VaultConfig decoyAlbum must not be empty.');
    }
  }

  /// Constant constructor with assertions for compile-time constants and test harnesses.
  const VaultConfig.constant({
    this.themePalette = VaultThemePalettePolicyEnum.warmEspresso,
    this.biometricAuth = BiometricAuthPolicyEnum.pinOnly,
    this.activeReauthInterval = ActiveReauthIntervalEnum.every15Minutes,
    this.backgroundGraceTimeout = BackgroundGraceTimeoutEnum.thirtySeconds,
    this.screenSecurity = ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
    this.metadataVisibility = MetadataVisibilityPolicyEnum.maskWithPlaceholder,
    this.decoyTitle = 'System Audio',
    this.decoyArtist = 'Media Service',
    this.decoyAlbum = 'Internal Playback',
    this.lockPlaybackBehavior = LockPlaybackBehaviorEnum.continueMaskedInBackground,
    this.gestureSensitivity = GestureSensitivityTierEnum.balanced84Percent,
    this.gestureVisibility = GestureVisibilityPolicyEnum.invisibleStealth,
    this.keypadLayout = KeypadLayoutPolicyEnum.standardOrdered,
  })  : assert(decoyTitle.length > 0, 'decoyTitle must not be empty'),
        assert(decoyArtist.length > 0, 'decoyArtist must not be empty'),
        assert(decoyAlbum.length > 0, 'decoyAlbum must not be empty');

  /// Creates a copy of this configuration with updated fields.
  VaultConfig copyWith({
    VaultThemePalettePolicyEnum? themePalette,
    BiometricAuthPolicyEnum? biometricAuth,
    ActiveReauthIntervalEnum? activeReauthInterval,
    BackgroundGraceTimeoutEnum? backgroundGraceTimeout,
    ScreenSecurityPolicyEnum? screenSecurity,
    MetadataVisibilityPolicyEnum? metadataVisibility,
    String? decoyTitle,
    String? decoyArtist,
    String? decoyAlbum,
    LockPlaybackBehaviorEnum? lockPlaybackBehavior,
    GestureSensitivityTierEnum? gestureSensitivity,
    GestureVisibilityPolicyEnum? gestureVisibility,
    KeypadLayoutPolicyEnum? keypadLayout,
  }) {
    return VaultConfig(
      themePalette: themePalette ?? this.themePalette,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      activeReauthInterval: activeReauthInterval ?? this.activeReauthInterval,
      backgroundGraceTimeout:
          backgroundGraceTimeout ?? this.backgroundGraceTimeout,
      screenSecurity: screenSecurity ?? this.screenSecurity,
      metadataVisibility: metadataVisibility ?? this.metadataVisibility,
      decoyTitle: decoyTitle ?? this.decoyTitle,
      decoyArtist: decoyArtist ?? this.decoyArtist,
      decoyAlbum: decoyAlbum ?? this.decoyAlbum,
      lockPlaybackBehavior: lockPlaybackBehavior ?? this.lockPlaybackBehavior,
      gestureSensitivity: gestureSensitivity ?? this.gestureSensitivity,
      gestureVisibility: gestureVisibility ?? this.gestureVisibility,
      keypadLayout: keypadLayout ?? this.keypadLayout,
    );
  }

  @override
  List<Object?> get props => [
        themePalette,
        biometricAuth,
        activeReauthInterval,
        backgroundGraceTimeout,
        screenSecurity,
        metadataVisibility,
        decoyTitle,
        decoyArtist,
        decoyAlbum,
        lockPlaybackBehavior,
        gestureSensitivity,
        gestureVisibility,
        keypadLayout,
      ];
}
