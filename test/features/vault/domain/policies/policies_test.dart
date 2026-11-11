import 'package:flutter_test/flutter_test.dart';
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

void main() {
  group('VaultThemePalettePolicyEnum', () {
    test('warmEspresso defines correct hex and ARGB constants', () {
      const palette = VaultThemePalettePolicyEnum.warmEspresso;
      expect(palette.id, 'WARM_ESPRESSO');
      expect(palette.scaffoldColorValue, 0xFF1A120E);
      expect(palette.backgroundColorValue, 0xFF3A2418);
      expect(palette.surfaceColorValue, 0xFF6B4A2E);
      expect(palette.textHighSalienceColorValue, 0xFFA88462);
      expect(palette.scaffoldHex, '#1A120E');
      expect(palette.backgroundHex, '#3A2418');
      expect(palette.surfaceHex, '#6B4A2E');
      expect(palette.textHighSalienceHex, '#A88462');
    });

    test('forestNoir defines correct hex and ARGB constants', () {
      const palette = VaultThemePalettePolicyEnum.forestNoir;
      expect(palette.id, 'FOREST_NOIR');
      expect(palette.scaffoldColorValue, 0xFF0F1F17);
      expect(palette.backgroundColorValue, 0xFF1E3A2E);
      expect(palette.surfaceColorValue, 0xFF3E5A3F);
      expect(palette.textHighSalienceColorValue, 0xFF6B7F67);
      expect(palette.scaffoldHex, '#0F1F17');
      expect(palette.backgroundHex, '#1E3A2E');
      expect(palette.surfaceHex, '#3E5A3F');
      expect(palette.textHighSalienceHex, '#6B7F67');
    });

    test('round trip serialization and deserialization', () {
      for (final palette in VaultThemePalettePolicyEnum.values) {
        expect(VaultThemePalettePolicyEnum.fromId(palette.toJson()), palette);
        expect(VaultThemePalettePolicyEnum.fromJson(palette.id), palette);
      }
    });

    test('fromId throws FormatException on invalid identifier', () {
      expect(
        () => VaultThemePalettePolicyEnum.fromId('INVALID_PALETTE'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('BiometricAuthPolicyEnum', () {
    test('pinOnly vs pinAndBiometricStrong getters', () {
      expect(BiometricAuthPolicyEnum.pinOnly.allowsBiometrics, isFalse);
      expect(BiometricAuthPolicyEnum.pinOnly.requiresPinOnly, isTrue);

      expect(BiometricAuthPolicyEnum.pinAndBiometricStrong.allowsBiometrics, isTrue);
      expect(BiometricAuthPolicyEnum.pinAndBiometricStrong.requiresPinOnly, isFalse);
    });

    test('round trip serialization and deserialization', () {
      for (final policy in BiometricAuthPolicyEnum.values) {
        expect(BiometricAuthPolicyEnum.fromId(policy.toJson()), policy);
        expect(BiometricAuthPolicyEnum.fromJson(policy.id), policy);
      }
    });

    test('throws FormatException on invalid id', () {
      expect(
        () => BiometricAuthPolicyEnum.fromId('UNKNOWN'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ActiveReauthIntervalEnum', () {
    test('duration and milliseconds mappings', () {
      expect(ActiveReauthIntervalEnum.every5Minutes.milliseconds, 300000);
      expect(ActiveReauthIntervalEnum.every5Minutes.minutes, 5);
      expect(ActiveReauthIntervalEnum.every5Minutes.hasTimeout, isTrue);

      expect(ActiveReauthIntervalEnum.every15Minutes.milliseconds, 900000);
      expect(ActiveReauthIntervalEnum.every15Minutes.minutes, 15);
      expect(ActiveReauthIntervalEnum.every15Minutes.hasTimeout, isTrue);

      expect(ActiveReauthIntervalEnum.every30Minutes.milliseconds, 1800000);
      expect(ActiveReauthIntervalEnum.every30Minutes.minutes, 30);
      expect(ActiveReauthIntervalEnum.every30Minutes.hasTimeout, isTrue);

      expect(ActiveReauthIntervalEnum.never.milliseconds, isNull);
      expect(ActiveReauthIntervalEnum.never.minutes, isNull);
      expect(ActiveReauthIntervalEnum.never.hasTimeout, isFalse);
    });

    test('isExpired monotonic checks', () {
      expect(ActiveReauthIntervalEnum.every5Minutes.isExpired(elapsedMonotonicMs: 299999), isFalse);
      expect(ActiveReauthIntervalEnum.every5Minutes.isExpired(elapsedMonotonicMs: 300000), isTrue);
      expect(ActiveReauthIntervalEnum.every5Minutes.isExpired(elapsedMonotonicMs: 300001), isTrue);

      expect(ActiveReauthIntervalEnum.never.isExpired(elapsedMonotonicMs: 99999999), isFalse);
    });

    test('round trip serialization and error on invalid', () {
      for (final interval in ActiveReauthIntervalEnum.values) {
        expect(ActiveReauthIntervalEnum.fromId(interval.toJson()), interval);
      }
      expect(() => ActiveReauthIntervalEnum.fromId('EVERY_10_MINUTES'), throwsFormatException);
    });
  });

  group('BackgroundGraceTimeoutEnum', () {
    test('durations and milliseconds', () {
      expect(BackgroundGraceTimeoutEnum.immediate.milliseconds, 0);
      expect(BackgroundGraceTimeoutEnum.immediate.isImmediate, isTrue);

      expect(BackgroundGraceTimeoutEnum.thirtySeconds.milliseconds, 30000);
      expect(BackgroundGraceTimeoutEnum.thirtySeconds.isImmediate, isFalse);

      expect(BackgroundGraceTimeoutEnum.oneMinute.milliseconds, 60000);
      expect(BackgroundGraceTimeoutEnum.fiveMinutes.milliseconds, 300000);
    });

    test('isExpired monotonic checks', () {
      expect(BackgroundGraceTimeoutEnum.immediate.isExpired(elapsedBackgroundMs: 0), isTrue);
      expect(BackgroundGraceTimeoutEnum.thirtySeconds.isExpired(elapsedBackgroundMs: 29999), isFalse);
      expect(BackgroundGraceTimeoutEnum.thirtySeconds.isExpired(elapsedBackgroundMs: 30000), isTrue);
    });

    test('round trip serialization', () {
      for (final timeout in BackgroundGraceTimeoutEnum.values) {
        expect(BackgroundGraceTimeoutEnum.fromId(timeout.toJson()), timeout);
      }
      expect(() => BackgroundGraceTimeoutEnum.fromId('TEN_SECONDS'), throwsFormatException);
    });
  });

  group('ScreenSecurityPolicyEnum', () {
    test('requiresSecureFlag evaluation', () {
      expect(ScreenSecurityPolicyEnum.allowCapture.requiresSecureFlag, isFalse);
      expect(ScreenSecurityPolicyEnum.blockScreenshotsAndRecents.requiresSecureFlag, isTrue);
    });

    test('round trip serialization', () {
      for (final policy in ScreenSecurityPolicyEnum.values) {
        expect(ScreenSecurityPolicyEnum.fromId(policy.toJson()), policy);
      }
      expect(() => ScreenSecurityPolicyEnum.fromId('UNKNOWN'), throwsFormatException);
    });
  });

  group('MetadataVisibilityPolicyEnum', () {
    test('decoy default constants', () {
      expect(MetadataVisibilityPolicyEnum.defaultDecoyTitle, 'System Audio');
      expect(MetadataVisibilityPolicyEnum.defaultDecoyArtist, 'Media Service');
      expect(MetadataVisibilityPolicyEnum.defaultDecoyAlbum, 'Internal Playback');
    });

    test('isMasked and isActualMetadataVisible', () {
      expect(MetadataVisibilityPolicyEnum.maskWithPlaceholder.isMasked, isTrue);
      expect(MetadataVisibilityPolicyEnum.maskWithPlaceholder.isActualMetadataVisible, isFalse);

      expect(MetadataVisibilityPolicyEnum.showActualMetadata.isMasked, isFalse);
      expect(MetadataVisibilityPolicyEnum.showActualMetadata.isActualMetadataVisible, isTrue);
    });

    test('round trip serialization', () {
      for (final policy in MetadataVisibilityPolicyEnum.values) {
        expect(MetadataVisibilityPolicyEnum.fromId(policy.toJson()), policy);
      }
      expect(() => MetadataVisibilityPolicyEnum.fromId('UNKNOWN'), throwsFormatException);
    });
  });

  group('LockPlaybackBehaviorEnum', () {
    test('behavior getters', () {
      expect(LockPlaybackBehaviorEnum.stopImmediately.shouldStopImmediately, isTrue);
      expect(LockPlaybackBehaviorEnum.stopImmediately.allowsTrackCompletion, isFalse);
      expect(LockPlaybackBehaviorEnum.stopImmediately.allowsBackgroundPlayback, isFalse);

      expect(LockPlaybackBehaviorEnum.finishCurrentTrack.allowsTrackCompletion, isTrue);
      expect(LockPlaybackBehaviorEnum.continueMaskedInBackground.allowsBackgroundPlayback, isTrue);
    });

    test('round trip serialization', () {
      for (final behavior in LockPlaybackBehaviorEnum.values) {
        expect(LockPlaybackBehaviorEnum.fromId(behavior.toJson()), behavior);
      }
      expect(() => LockPlaybackBehaviorEnum.fromId('PAUSE'), throwsFormatException);
    });
  });

  group('GestureSensitivityTierEnum', () {
    test('thresholds and constants', () {
      expect(GestureSensitivityTierEnum.strict92Percent.thresholdScore, 0.88);
      expect(GestureSensitivityTierEnum.balanced84Percent.thresholdScore, 0.78);
      expect(GestureSensitivityTierEnum.relaxed76Percent.thresholdScore, 0.68);

      expect(GestureSensitivityTierEnum.minimumStructuralGate, 0.68);
      expect(GestureSensitivityTierEnum.safetyFloorDollar1, 0.65);
      expect(GestureSensitivityTierEnum.safetyFloorDtw, 0.60);
    });

    test('isSatisfiedBy evaluation', () {
      expect(GestureSensitivityTierEnum.strict92Percent.isSatisfiedBy(0.88), isTrue);
      expect(GestureSensitivityTierEnum.strict92Percent.isSatisfiedBy(0.8799), isFalse);

      expect(GestureSensitivityTierEnum.balanced84Percent.isSatisfiedBy(0.78), isTrue);
      expect(GestureSensitivityTierEnum.balanced84Percent.isSatisfiedBy(0.7799), isFalse);

      expect(GestureSensitivityTierEnum.relaxed76Percent.isSatisfiedBy(0.68), isTrue);
      expect(GestureSensitivityTierEnum.relaxed76Percent.isSatisfiedBy(0.6799), isFalse);
    });

    test('round trip serialization', () {
      for (final tier in GestureSensitivityTierEnum.values) {
        expect(GestureSensitivityTierEnum.fromId(tier.toJson()), tier);
      }
      expect(() => GestureSensitivityTierEnum.fromId('TIER_ULTRA'), throwsFormatException);
    });
  });

  group('GestureVisibilityPolicyEnum', () {
    test('getters', () {
      expect(GestureVisibilityPolicyEnum.invisibleStealth.isInvisible, isTrue);
      expect(GestureVisibilityPolicyEnum.invisibleStealth.isInkVisible, isFalse);

      expect(GestureVisibilityPolicyEnum.faintDissipatingHairline.isInvisible, isFalse);
      expect(GestureVisibilityPolicyEnum.faintDissipatingHairline.isInkVisible, isTrue);
    });

    test('round trip serialization', () {
      for (final policy in GestureVisibilityPolicyEnum.values) {
        expect(GestureVisibilityPolicyEnum.fromId(policy.toJson()), policy);
      }
      expect(() => GestureVisibilityPolicyEnum.fromId('GLOWING'), throwsFormatException);
    });
  });

  group('KeypadLayoutPolicyEnum', () {
    test('standardOrdered returns standard digits', () {
      final digits = KeypadLayoutPolicyEnum.standardOrdered.resolveDigits();
      expect(digits, [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
      expect(KeypadLayoutPolicyEnum.standardOrdered.isRandomized, isFalse);
    });

    test('randomizedPerAttempt validates input', () {
      expect(KeypadLayoutPolicyEnum.randomizedPerAttempt.isRandomized, isTrue);

      expect(
        () => KeypadLayoutPolicyEnum.randomizedPerAttempt.resolveDigits(),
        throwsArgumentError,
      );

      expect(
        () => KeypadLayoutPolicyEnum.randomizedPerAttempt.resolveDigits(
          shuffledDigits: [0, 1, 2, 3, 4],
        ),
        throwsArgumentError,
      );

      expect(
        () => KeypadLayoutPolicyEnum.randomizedPerAttempt.resolveDigits(
          shuffledDigits: [0, 1, 2, 3, 4, 5, 6, 7, 8, 8],
        ),
        throwsArgumentError,
      );

      final valid = [9, 8, 7, 6, 5, 4, 3, 2, 1, 0];
      final resolved = KeypadLayoutPolicyEnum.randomizedPerAttempt.resolveDigits(
        shuffledDigits: valid,
      );
      expect(resolved, valid);
    });

    test('round trip serialization', () {
      for (final layout in KeypadLayoutPolicyEnum.values) {
        expect(KeypadLayoutPolicyEnum.fromId(layout.toJson()), layout);
      }
      expect(() => KeypadLayoutPolicyEnum.fromId('ALPHA'), throwsFormatException);
    });
  });
}
