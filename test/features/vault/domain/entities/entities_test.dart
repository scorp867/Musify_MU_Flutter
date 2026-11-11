import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
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
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

void main() {
  group('PrivatePlaylist & PrivateTrackRef Entities', () {
    PrivateTrackRef createValidTrackRef({
      String id = 'track_1',
      String playlistId = 'playlist_1',
      TrackSourceTypeEnum sourceType = TrackSourceTypeEnum.localSandbox,
      String? localRelativePath = 'vault_media/.nomedia/track_1.mp3',
    }) {
      return PrivateTrackRef(
        id: id,
        playlistId: playlistId,
        trackUri: 'file://local/track_1.mp3',
        title: 'Secret Song',
        artistName: 'Stealth Artist',
        albumTitle: 'Private Album',
        durationMs: 180000,
        sourceType: sourceType,
        localRelativePath: localRelativePath,
        sortOrder: 0,
        addedAtEpochMs: 1700000000000,
      );
    }

    test('PrivatePlaylist valid construction, unmodifiable list, and properties', () {
      final track = createValidTrackRef();
      final playlist = PrivatePlaylist(
        id: 'playlist_1',
        name: 'My Confidential Tracks',
        description: 'Vault only',
        coverUri: 'file://covers/1.jpg',
        totalDurationMs: 180000,
        createdAtEpochMs: 1700000000000,
        updatedAtEpochMs: 1700000005000,
        trackRefs: [track],
      );

      expect(playlist.id, 'playlist_1');
      expect(playlist.name, 'My Confidential Tracks');
      expect(playlist.description, 'Vault only');
      expect(playlist.coverUri, 'file://covers/1.jpg');
      expect(playlist.totalDurationMs, 180000);
      expect(playlist.trackCount, 1);
      expect(playlist.trackRefs.first, track);

      // Verify unmodifiable collection
      expect(() => playlist.trackRefs.add(createValidTrackRef(id: 'track_2')),
          throwsUnsupportedError);
    });

    test('PrivatePlaylist copyWith and Equatable equality', () {
      final track = createValidTrackRef();
      final playlist1 = PrivatePlaylist(
        id: 'pl_1',
        name: 'Original',
        description: 'Desc',
        totalDurationMs: 1000,
        createdAtEpochMs: 1000,
        updatedAtEpochMs: 2000,
        trackRefs: [track],
      );

      final playlist2 = playlist1.copyWith(name: 'Updated Name');
      expect(playlist2.name, 'Updated Name');
      expect(playlist2.id, playlist1.id);
      expect(playlist2.trackRefs, playlist1.trackRefs);

      final playlistIdentical = playlist1.copyWith();
      expect(playlistIdentical, equals(playlist1));
      expect(playlistIdentical.hashCode, playlist1.hashCode);
    });

    test('PrivatePlaylist validation exceptions', () {
      final track = createValidTrackRef();

      expect(
        () => PrivatePlaylist(
          id: '',
          name: 'Valid Name',
          description: 'Desc',
          totalDurationMs: 100,
          createdAtEpochMs: 100,
          updatedAtEpochMs: 100,
          trackRefs: [track],
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: '   ',
          description: 'Desc',
          totalDurationMs: 100,
          createdAtEpochMs: 100,
          updatedAtEpochMs: 100,
          trackRefs: [track],
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: 'Valid Name',
          description: 'Desc',
          totalDurationMs: -1,
          createdAtEpochMs: 100,
          updatedAtEpochMs: 100,
          trackRefs: [track],
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: 'Valid Name',
          description: 'Desc',
          totalDurationMs: 100,
          createdAtEpochMs: 0,
          updatedAtEpochMs: 100,
          trackRefs: [track],
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: 'Valid Name',
          description: 'Desc',
          totalDurationMs: 100,
          createdAtEpochMs: 200,
          updatedAtEpochMs: 100,
          trackRefs: [track],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('PrivateTrackRef source type constraints', () {
      // Local track requires non-null, non-empty localRelativePath
      expect(
        () => PrivateTrackRef(
          id: 't1',
          playlistId: 'p1',
          trackUri: 'file://uri',
          title: 'Title',
          artistName: 'Artist',
          albumTitle: 'Album',
          durationMs: 1000,
          sourceType: TrackSourceTypeEnum.localSandbox,
          localRelativePath: null,
          sortOrder: 0,
          addedAtEpochMs: 1000,
        ),
        throwsA(isA<FormatException>()),
      );

      // Spotify track requires null localRelativePath
      expect(
        () => PrivateTrackRef(
          id: 't2',
          playlistId: 'p1',
          trackUri: 'spotify:track:123',
          title: 'Title',
          artistName: 'Artist',
          albumTitle: 'Album',
          durationMs: 1000,
          sourceType: TrackSourceTypeEnum.spotify,
          localRelativePath: 'some/path.mp3',
          sortOrder: 0,
          addedAtEpochMs: 1000,
        ),
        throwsA(isA<FormatException>()),
      );

      // Valid Spotify track
      final spotifyTrack = PrivateTrackRef(
        id: 't2',
        playlistId: 'p1',
        trackUri: 'spotify:track:123',
        title: 'Title',
        artistName: 'Artist',
        albumTitle: 'Album',
        durationMs: 1000,
        sourceType: TrackSourceTypeEnum.spotify,
        localRelativePath: null,
        sortOrder: 0,
        addedAtEpochMs: 1000,
      );
      expect(spotifyTrack.sourceType, TrackSourceTypeEnum.spotify);
      expect(spotifyTrack.localRelativePath, isNull);
    });

    test('TrackSourceTypeEnum serialization', () {
      expect(TrackSourceTypeEnum.spotify.toJson(), 'SPOTIFY');
      expect(TrackSourceTypeEnum.localSandbox.toJson(), 'LOCAL_SANDBOX');
      expect(TrackSourceTypeEnum.fromId('SPOTIFY'), TrackSourceTypeEnum.spotify);
      expect(TrackSourceTypeEnum.fromId('LOCAL_SANDBOX'), TrackSourceTypeEnum.localSandbox);
      expect(() => TrackSourceTypeEnum.fromId('INVALID'), throwsA(isA<FormatException>()));
    });
  });

  group('VaultConfig Entity', () {
    test('Default configuration properties', () {
      final config = VaultConfig();
      expect(config.themePalette, VaultThemePalettePolicyEnum.warmEspresso);
      expect(config.biometricAuth, BiometricAuthPolicyEnum.pinOnly);
      expect(config.activeReauthInterval, ActiveReauthIntervalEnum.every15Minutes);
      expect(config.backgroundGraceTimeout, BackgroundGraceTimeoutEnum.thirtySeconds);
      expect(config.screenSecurity, ScreenSecurityPolicyEnum.blockScreenshotsAndRecents);
      expect(config.metadataVisibility, MetadataVisibilityPolicyEnum.maskWithPlaceholder);
      expect(config.decoyTitle, 'System Audio');
      expect(config.decoyArtist, 'Media Service');
      expect(config.decoyAlbum, 'Internal Playback');
      expect(config.lockPlaybackBehavior, LockPlaybackBehaviorEnum.continueMaskedInBackground);
      expect(config.gestureSensitivity, GestureSensitivityTierEnum.balanced84Percent);
      expect(config.gestureVisibility, GestureVisibilityPolicyEnum.invisibleStealth);
      expect(config.keypadLayout, KeypadLayoutPolicyEnum.standardOrdered);
    });

    test('Validation rejects empty decoy persona fields', () {
      expect(() => VaultConfig(decoyTitle: ''), throwsA(isA<FormatException>()));
      expect(() => VaultConfig(decoyArtist: '   '), throwsA(isA<FormatException>()));
      expect(() => VaultConfig(decoyAlbum: ''), throwsA(isA<FormatException>()));
    });

    test('copyWith updates specified policy fields', () {
      final initial = VaultConfig();
      final updated = initial.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
        decoyTitle: 'Decoy Title X',
      );

      expect(updated.themePalette, VaultThemePalettePolicyEnum.forestNoir);
      expect(updated.biometricAuth, BiometricAuthPolicyEnum.pinAndBiometricStrong);
      expect(updated.decoyTitle, 'Decoy Title X');
      expect(updated.decoyArtist, initial.decoyArtist);
    });

    test('Equatable value equality', () {
      final c1 = VaultConfig();
      final c2 = VaultConfig();
      expect(c1, equals(c2));
      expect(c1.hashCode, c2.hashCode);
    });
  });

  group('GesturePoint, GestureSample, and GestureTemplate Value Objects', () {
    test('GesturePoint validates finite numbers and non-negative timestamp', () {
      final point = GesturePoint(x: 100.5, y: 200.0, timestampMs: 1234);
      expect(point.x, 100.5);
      expect(point.y, 200.0);
      expect(point.timestampMs, 1234);

      expect(() => GesturePoint(x: double.nan, y: 10.0, timestampMs: 0),
          throwsA(isA<FormatException>()));
      expect(() => GesturePoint(x: 10.0, y: double.infinity, timestampMs: 0),
          throwsA(isA<FormatException>()));
      expect(() => GesturePoint(x: 10.0, y: 20.0, timestampMs: -1),
          throwsA(isA<FormatException>()));
    });

    test('GestureSample validates non-empty points and wraps unmodifiable list', () {
      final p1 = GesturePoint(x: 0, y: 0, timestampMs: 10);
      final p2 = GesturePoint(x: 10, y: 10, timestampMs: 20);
      final sample = GestureSample(
        points: [p1, p2],
        sampledAtEpochMs: 1700000000000,
        totalLength: 14.14,
      );

      expect(sample.pointCount, 2);
      expect(() => sample.points.add(p1), throwsUnsupportedError);

      expect(
        () => GestureSample(
          points: const [],
          sampledAtEpochMs: 1000,
          totalLength: 0.0,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => GestureSample(
          points: [p1],
          sampledAtEpochMs: -1,
          totalLength: 0.0,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => GestureSample(
          points: [p1],
          sampledAtEpochMs: 100,
          totalLength: -5.0,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('GestureTemplate enforces 64 points and 7 Rubine features', () {
      final valid64Points = List.generate(
        64,
        (i) => GesturePoint(x: i.toDouble(), y: i.toDouble(), timestampMs: i * 10),
      );
      final valid7Features = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];

      final template = GestureTemplate(
        id: 'template_alpha',
        normalizedPoints: valid64Points,
        rubineFeatureVector: valid7Features,
        createdAtEpochMs: 1700000000000,
      );

      expect(template.id, 'template_alpha');
      expect(template.normalizedPoints.length, 64);
      expect(template.rubineFeatureVector.length, 7);
      expect(() => template.normalizedPoints.add(valid64Points.first),
          throwsUnsupportedError);
      expect(() => template.rubineFeatureVector.add(0.8), throwsUnsupportedError);

      // Rejects non-64 point count
      expect(
        () => GestureTemplate(
          id: 'template_alpha',
          normalizedPoints: valid64Points.sublist(0, 63),
          rubineFeatureVector: valid7Features,
          createdAtEpochMs: 1000,
        ),
        throwsA(isA<FormatException>()),
      );

      // Rejects non-7 feature vector length
      expect(
        () => GestureTemplate(
          id: 'template_alpha',
          normalizedPoints: valid64Points,
          rubineFeatureVector: [0.1, 0.2, 0.3],
          createdAtEpochMs: 1000,
        ),
        throwsA(isA<FormatException>()),
      );

      // Rejects NaN feature
      expect(
        () => GestureTemplate(
          id: 'template_alpha',
          normalizedPoints: valid64Points,
          rubineFeatureVector: [0.1, double.nan, 0.3, 0.4, 0.5, 0.6, 0.7],
          createdAtEpochMs: 1000,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RecognitionScore and Decisions', () {
    test('Valid construction and bounds check in [0.0, 1.0]', () {
      final score = RecognitionScore(
        dollarOneScore: 0.95,
        dtwScore: 0.90,
        featureScore: 0.85,
        ensembleScore: 0.9175,
        decision: GestureMatchDecisionEnum.matched,
      );

      expect(score.decision, GestureMatchDecisionEnum.matched);
      expect(score.ensembleScore, 0.9175);

      expect(
        () => RecognitionScore(
          dollarOneScore: 1.05,
          dtwScore: 0.90,
          featureScore: 0.85,
          ensembleScore: 0.90,
          decision: GestureMatchDecisionEnum.matched,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => RecognitionScore(
          dollarOneScore: -0.01,
          dtwScore: 0.90,
          featureScore: 0.85,
          ensembleScore: 0.90,
          decision: GestureMatchDecisionEnum.matched,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Weighted ensemble score computation formula', () {
      final computed = RecognitionScore.computeEnsembleScore(
        dollarOneScore: 0.80,
        dtwScore: 0.70,
        featureScore: 0.60,
      );
      // 0.50 * 0.80 + 0.35 * 0.70 + 0.15 * 0.60 = 0.40 + 0.245 + 0.09 = 0.735
      expect(computed, closeTo(0.735, 1e-6));
    });

    test('GestureMatchDecisionEnum serialization', () {
      expect(GestureMatchDecisionEnum.matched.toJson(), 'MATCHED');
      expect(
        GestureMatchDecisionEnum.fromId('REJECTED_ANTI_SCRIBBLE'),
        GestureMatchDecisionEnum.rejectedAntiScribble,
      );
      expect(
        () => GestureMatchDecisionEnum.fromId('UNKNOWN_DECISION'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AuthSession & LockoutCooldownInfo', () {
    test('AuthSession validation and copyWith', () {
      final session = AuthSession(
        sessionToken: 'token_abc123',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 2000,
        authMethod: AuthMethodEnum.pin,
      );

      expect(session.sessionToken, 'token_abc123');
      expect(session.authMethod, AuthMethodEnum.pin);

      final updated = session.copyWith(lastActiveEpochMs: 3000);
      expect(updated.lastActiveEpochMs, 3000);
      expect(updated.sessionStartedEpochMs, 1000);

      expect(
        () => AuthSession(
          sessionToken: '   ',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 2000,
          authMethod: AuthMethodEnum.pin,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => AuthSession(
          sessionToken: 'token',
          sessionStartedEpochMs: 2000,
          lastActiveEpochMs: 1000, // earlier than started
          authMethod: AuthMethodEnum.pin,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('AuthMethodEnum serialization', () {
      expect(AuthMethodEnum.pin.toJson(), 'PIN');
      expect(AuthMethodEnum.biometric.toJson(), 'BIOMETRIC');
      expect(AuthMethodEnum.fromId('PIN'), AuthMethodEnum.pin);
      expect(AuthMethodEnum.fromId('BIOMETRIC'), AuthMethodEnum.biometric);
      expect(() => AuthMethodEnum.fromId('PASSWORD'), throwsA(isA<FormatException>()));
    });

    test('LockoutCooldownInfo properties and none factory', () {
      final clear = LockoutCooldownInfo.none();
      expect(clear.tier, LockoutCooldownTierEnum.none);
      expect(clear.consecutiveFailedAttempts, 0);
      expect(clear.deadlineMonotonicMs, 0);
      expect(clear.remainingCooldownSeconds, 0);

      final locked = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        consecutiveFailedAttempts: 5,
        deadlineMonotonicMs: 35000,
        remainingCooldownSeconds: 30,
      );
      expect(locked.tier, LockoutCooldownTierEnum.tier1ThirtySeconds);
      expect(locked.consecutiveFailedAttempts, 5);

      expect(
        () => LockoutCooldownInfo(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          consecutiveFailedAttempts: -1,
          deadlineMonotonicMs: 0,
          remainingCooldownSeconds: 0,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('VaultResult<T> & VaultFailure Hierarchy', () {
    test('VaultSuccess fold and Equatable equality', () {
      const VaultResult<int> result = VaultResult.success(42);

      final folded = result.fold(
        onSuccess: (val) => 'Success: $val',
        onFailure: (err) => 'Failure: ${err.message}',
      );
      expect(folded, 'Success: 42');

      const result2 = VaultSuccess<int>(42);
      expect(result, equals(result2));
      expect(result.hashCode, result2.hashCode);
    });

    test('VaultFailureResult fold and failure subtypes', () {
      const failure = VaultAuthFailure('Invalid PIN', remainingAttempts: 2);
      const VaultResult<String> result = VaultResult.failure(failure);

      final folded = result.fold(
        onSuccess: (val) => 'Got $val',
        onFailure: (err) => 'Error: ${err.message}',
      );
      expect(folded, 'Error: Invalid PIN');

      switch (result) {
        case VaultSuccess(:final data):
          fail('Should not be success: $data');
        case VaultFailureResult(:final failure):
          expect(failure, isA<VaultAuthFailure>());
          final authFail = failure as VaultAuthFailure;
          expect(authFail.remainingAttempts, 2);
      }
    });

    test('All VaultFailure subtypes instantiate with Equatable', () {
      const auth = VaultAuthFailure('Auth failed', remainingAttempts: 3);
      const lockout = VaultLockoutFailure(
        'Locked out',
        remainingCooldownSeconds: 30,
        deadlineMonotonicMs: 50000,
      );
      const crypto = VaultCryptoFailure('Key unwrap fault');
      const storage = VaultStorageFailure('Disk write failed');
      const gesture = VaultGestureFailure('Divergent samples');
      const validation = VaultValidationFailure('Schema corrupted');

      expect(auth.props, ['Auth failed', null, 3]);
      expect(lockout.remainingCooldownSeconds, 30);
      expect(crypto.message, 'Key unwrap fault');
      expect(storage.message, 'Disk write failed');
      expect(gesture.message, 'Divergent samples');
      expect(validation.message, 'Schema corrupted');
    });
  });
}
