import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
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

/// Data Transfer Object for serializing and deserializing [VaultConfig] with fail-fast validation.
///
/// Strictly enforces the Layer 3 boundary: all fields are validated explicitly.
/// Missing, null, or malformed fields trigger a descriptive [FormatException].
abstract final class VaultConfigDto {
  /// Serializes [VaultConfig] to a JSON-compatible Map.
  static Map<String, Object> toJson(VaultConfig config) {
    return <String, Object>{
      'themePalette': config.themePalette.id,
      'biometricAuth': config.biometricAuth.id,
      'activeReauthInterval': config.activeReauthInterval.id,
      'backgroundGraceTimeout': config.backgroundGraceTimeout.id,
      'screenSecurity': config.screenSecurity.id,
      'metadataVisibility': config.metadataVisibility.id,
      'decoyTitle': config.decoyTitle,
      'decoyArtist': config.decoyArtist,
      'decoyAlbum': config.decoyAlbum,
      'lockPlaybackBehavior': config.lockPlaybackBehavior.id,
      'gestureSensitivity': config.gestureSensitivity.id,
      'gestureVisibility': config.gestureVisibility.id,
      'keypadLayout': config.keypadLayout.id,
    };
  }

  /// Deserializes a JSON Map into a validated [VaultConfig] instance.
  ///
  /// Throws [FormatException] if [json] is not a Map or if any required field is missing or invalid.
  static VaultConfig fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Expected JSON Map for VaultConfigDto.');
    }

    final themePaletteRaw = json['themePalette'];
    if (themePaletteRaw is! String) {
      throw const FormatException('Missing or invalid "themePalette" in VaultConfigDto.');
    }

    final biometricAuthRaw = json['biometricAuth'];
    if (biometricAuthRaw is! String) {
      throw const FormatException('Missing or invalid "biometricAuth" in VaultConfigDto.');
    }

    final activeReauthIntervalRaw = json['activeReauthInterval'];
    if (activeReauthIntervalRaw is! String) {
      throw const FormatException('Missing or invalid "activeReauthInterval" in VaultConfigDto.');
    }

    final backgroundGraceTimeoutRaw = json['backgroundGraceTimeout'];
    if (backgroundGraceTimeoutRaw is! String) {
      throw const FormatException('Missing or invalid "backgroundGraceTimeout" in VaultConfigDto.');
    }

    final screenSecurityRaw = json['screenSecurity'];
    if (screenSecurityRaw is! String) {
      throw const FormatException('Missing or invalid "screenSecurity" in VaultConfigDto.');
    }

    final metadataVisibilityRaw = json['metadataVisibility'];
    if (metadataVisibilityRaw is! String) {
      throw const FormatException('Missing or invalid "metadataVisibility" in VaultConfigDto.');
    }

    final decoyTitleRaw = json['decoyTitle'];
    if (decoyTitleRaw is! String || decoyTitleRaw.trim().isEmpty) {
      throw const FormatException('Missing or invalid "decoyTitle" in VaultConfigDto.');
    }

    final decoyArtistRaw = json['decoyArtist'];
    if (decoyArtistRaw is! String || decoyArtistRaw.trim().isEmpty) {
      throw const FormatException('Missing or invalid "decoyArtist" in VaultConfigDto.');
    }

    final decoyAlbumRaw = json['decoyAlbum'];
    if (decoyAlbumRaw is! String || decoyAlbumRaw.trim().isEmpty) {
      throw const FormatException('Missing or invalid "decoyAlbum" in VaultConfigDto.');
    }

    final lockPlaybackBehaviorRaw = json['lockPlaybackBehavior'];
    if (lockPlaybackBehaviorRaw is! String) {
      throw const FormatException('Missing or invalid "lockPlaybackBehavior" in VaultConfigDto.');
    }

    final gestureSensitivityRaw = json['gestureSensitivity'];
    if (gestureSensitivityRaw is! String) {
      throw const FormatException('Missing or invalid "gestureSensitivity" in VaultConfigDto.');
    }

    final gestureVisibilityRaw = json['gestureVisibility'];
    if (gestureVisibilityRaw is! String) {
      throw const FormatException('Missing or invalid "gestureVisibility" in VaultConfigDto.');
    }

    final keypadLayoutRaw = json['keypadLayout'];
    if (keypadLayoutRaw is! String) {
      throw const FormatException('Missing or invalid "keypadLayout" in VaultConfigDto.');
    }

    return VaultConfig(
      themePalette: VaultThemePalettePolicyEnum.fromId(themePaletteRaw),
      biometricAuth: BiometricAuthPolicyEnum.fromId(biometricAuthRaw),
      activeReauthInterval: ActiveReauthIntervalEnum.fromId(activeReauthIntervalRaw),
      backgroundGraceTimeout: BackgroundGraceTimeoutEnum.fromId(backgroundGraceTimeoutRaw),
      screenSecurity: ScreenSecurityPolicyEnum.fromId(screenSecurityRaw),
      metadataVisibility: MetadataVisibilityPolicyEnum.fromId(metadataVisibilityRaw),
      decoyTitle: decoyTitleRaw,
      decoyArtist: decoyArtistRaw,
      decoyAlbum: decoyAlbumRaw,
      lockPlaybackBehavior: LockPlaybackBehaviorEnum.fromId(lockPlaybackBehaviorRaw),
      gestureSensitivity: GestureSensitivityTierEnum.fromId(gestureSensitivityRaw),
      gestureVisibility: GestureVisibilityPolicyEnum.fromId(gestureVisibilityRaw),
      keypadLayout: KeypadLayoutPolicyEnum.fromId(keypadLayoutRaw),
    );
  }
}
