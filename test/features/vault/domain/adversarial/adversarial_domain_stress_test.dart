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
import 'package:musify_mu/features/vault/domain/states/crypto_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/gesture_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/playback_privacy_mode.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

void main() {
  group('Adversarial Stress Suite: GesturePoint Value Object', () {
    test('Rejects NaN and Infinite coordinates with FormatException', () {
      expect(
        () => GesturePoint(x: double.nan, y: 10.0, timestampMs: 100),
        throwsFormatException,
      );
      expect(
        () => GesturePoint(x: 10.0, y: double.nan, timestampMs: 100),
        throwsFormatException,
      );
      expect(
        () => GesturePoint(x: double.infinity, y: 10.0, timestampMs: 100),
        throwsFormatException,
      );
      expect(
        () => GesturePoint(x: -double.infinity, y: 10.0, timestampMs: 100),
        throwsFormatException,
      );
      expect(
        () => GesturePoint(x: 10.0, y: double.infinity, timestampMs: 100),
        throwsFormatException,
      );
      expect(
        () => GesturePoint(x: 10.0, y: -double.infinity, timestampMs: 100),
        throwsFormatException,
      );
    });

    test('Rejects negative timestamps with FormatException', () {
      expect(
        () => GesturePoint(x: 10.0, y: 20.0, timestampMs: -1),
        throwsFormatException,
      );
      expect(
        () => GesturePoint(x: 10.0, y: 20.0, timestampMs: -99999),
        throwsFormatException,
      );
    });

    test('Accepts extreme finite values and zero boundary', () {
      final p1 = GesturePoint(x: 0.0, y: 0.0, timestampMs: 0);
      expect(p1.x, equals(0.0));
      expect(p1.y, equals(0.0));
      expect(p1.timestampMs, equals(0));

      final p2 = GesturePoint(x: -1e10, y: 1e10, timestampMs: 999999999);
      expect(p2.x, equals(-1e10));
      expect(p2.y, equals(1e10));
    });

    test('GesturePoint.constant constructor asserts non-negative timestamp', () {
      expect(
        () => GesturePoint.constant(x: 1.0, y: 2.0, timestampMs: -1),
        throwsAssertionError,
      );
    });
  });

  group('Adversarial Stress Suite: GestureSample & Immutability', () {
    test('Rejects empty points collection with FormatException', () {
      expect(
        () => GestureSample(
          points: const [],
          sampledAtEpochMs: 1000,
          totalLength: 100.0,
        ),
        throwsFormatException,
      );
    });

    test('Rejects non-positive sampledAtEpochMs with FormatException', () {
      final validPoint = GesturePoint(x: 1.0, y: 1.0, timestampMs: 0);
      expect(
        () => GestureSample(
          points: [validPoint],
          sampledAtEpochMs: 0,
          totalLength: 10.0,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureSample(
          points: [validPoint],
          sampledAtEpochMs: -100,
          totalLength: 10.0,
        ),
        throwsFormatException,
      );
    });

    test('Rejects NaN, infinite, or negative totalLength with FormatException', () {
      final validPoint = GesturePoint(x: 1.0, y: 1.0, timestampMs: 0);
      expect(
        () => GestureSample(
          points: [validPoint],
          sampledAtEpochMs: 1000,
          totalLength: double.nan,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureSample(
          points: [validPoint],
          sampledAtEpochMs: 1000,
          totalLength: double.infinity,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureSample(
          points: [validPoint],
          sampledAtEpochMs: 1000,
          totalLength: -0.0001,
        ),
        throwsFormatException,
      );
    });

    test('Deep Immutability: Mutating source list does not affect sample', () {
      final mutablePoints = [
        GesturePoint(x: 10.0, y: 10.0, timestampMs: 0),
        GesturePoint(x: 20.0, y: 20.0, timestampMs: 10),
      ];

      final sample = GestureSample(
        points: mutablePoints,
        sampledAtEpochMs: 1000,
        totalLength: 14.14,
      );

      // Attempt mutating external list
      mutablePoints.add(GesturePoint(x: 30.0, y: 30.0, timestampMs: 20));
      expect(sample.pointCount, equals(2));
      expect(sample.points.length, equals(2));

      // Attempt mutating internal unmodifiable list
      expect(
        () => sample.points.add(GesturePoint(x: 40.0, y: 40.0, timestampMs: 30)),
        throwsUnsupportedError,
      );
    });
  });

  group('Adversarial Stress Suite: GestureTemplate Strict Constraints', () {
    List<GesturePoint> generatePoints(int count) {
      return List.generate(
        count,
        (i) => GesturePoint(x: i.toDouble(), y: (i * 2).toDouble(), timestampMs: i * 5),
      );
    }

    test('Rejects template id with empty or whitespace string', () {
      expect(
        () => GestureTemplate(
          id: '',
          normalizedPoints: generatePoints(64),
          rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureTemplate(
          id: '   \t\n  ',
          normalizedPoints: generatePoints(64),
          rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
    });

    test('Rejects point counts not exactly equal to 64', () {
      expect(
        () => GestureTemplate(
          id: 'template_1',
          normalizedPoints: generatePoints(63),
          rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureTemplate(
          id: 'template_1',
          normalizedPoints: generatePoints(65),
          rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
    });

    test('Rejects Rubine feature vector length != 7 or containing NaN/Inf', () {
      expect(
        () => GestureTemplate(
          id: 'template_1',
          normalizedPoints: generatePoints(64),
          rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureTemplate(
          id: 'template_1',
          normalizedPoints: generatePoints(64),
          rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureTemplate(
          id: 'template_1',
          normalizedPoints: generatePoints(64),
          rubineFeatureVector: const [1.0, 2.0, double.nan, 4.0, 5.0, 6.0, 7.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
      expect(
        () => GestureTemplate(
          id: 'template_1',
          normalizedPoints: generatePoints(64),
          rubineFeatureVector: const [1.0, 2.0, 3.0, double.infinity, 5.0, 6.0, 7.0],
          createdAtEpochMs: 1000,
        ),
        throwsFormatException,
      );
    });

    test('Deep Immutability: Mutating source Rubine vector does not mutate template', () {
      final mutableVector = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0];
      final template = GestureTemplate(
        id: 'template_immutability',
        normalizedPoints: generatePoints(64),
        rubineFeatureVector: mutableVector,
        createdAtEpochMs: 1000,
      );

      mutableVector[0] = 999.0;
      expect(template.rubineFeatureVector[0], equals(1.0));

      expect(
        () => template.rubineFeatureVector.add(8.0),
        throwsUnsupportedError,
      );
      expect(
        () => template.normalizedPoints.add(GesturePoint(x: 0, y: 0, timestampMs: 0)),
        throwsUnsupportedError,
      );
    });
  });

  group('Adversarial Stress Suite: PrivatePlaylist & PrivateTrackRef Invariants', () {
    test('Rejects invalid PrivatePlaylist fields with FormatException', () {
      // Empty id
      expect(
        () => PrivatePlaylist(
          id: '   ',
          name: 'My Vault Tracks',
          description: 'Secret list',
          totalDurationMs: 1000,
          createdAtEpochMs: 500,
          updatedAtEpochMs: 600,
          trackRefs: const [],
        ),
        throwsFormatException,
      );

      // Empty name
      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: '',
          description: 'Secret list',
          totalDurationMs: 1000,
          createdAtEpochMs: 500,
          updatedAtEpochMs: 600,
          trackRefs: const [],
        ),
        throwsFormatException,
      );

      // Negative duration
      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: 'My Vault Tracks',
          description: 'Secret list',
          totalDurationMs: -1,
          createdAtEpochMs: 500,
          updatedAtEpochMs: 600,
          trackRefs: const [],
        ),
        throwsFormatException,
      );

      // Non-positive createdAtEpochMs
      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: 'My Vault Tracks',
          description: 'Secret list',
          totalDurationMs: 0,
          createdAtEpochMs: 0,
          updatedAtEpochMs: 600,
          trackRefs: const [],
        ),
        throwsFormatException,
      );

      // updatedAtEpochMs earlier than createdAtEpochMs
      expect(
        () => PrivatePlaylist(
          id: 'pl_1',
          name: 'My Vault Tracks',
          description: 'Secret list',
          totalDurationMs: 0,
          createdAtEpochMs: 500,
          updatedAtEpochMs: 499,
          trackRefs: const [],
        ),
        throwsFormatException,
      );
    });

    test('PrivatePlaylist deep immutability on trackRefs', () {
      final track = PrivateTrackRef(
        id: 't_1',
        playlistId: 'pl_1',
        trackUri: 'spotify:track:abc',
        title: 'Title',
        artistName: 'Artist',
        albumTitle: 'Album',
        durationMs: 180000,
        sourceType: TrackSourceTypeEnum.spotify,
        sortOrder: 0,
        addedAtEpochMs: 1000,
      );

      final mutableTracks = [track];
      final playlist = PrivatePlaylist(
        id: 'pl_1',
        name: 'Private Playlist',
        description: 'Test',
        totalDurationMs: 180000,
        createdAtEpochMs: 1000,
        updatedAtEpochMs: 1000,
        trackRefs: mutableTracks,
      );

      // External mutation
      mutableTracks.clear();
      expect(playlist.trackCount, equals(1));
      expect(playlist.trackRefs.length, equals(1));

      // Direct mutation on property
      expect(
        () => playlist.trackRefs.add(track),
        throwsUnsupportedError,
      );
    });

    test('PrivateTrackRef source type constraints: Spotify vs LocalSandbox', () {
      // LocalSandbox requires non-empty localRelativePath
      expect(
        () => PrivateTrackRef(
          id: 't_local_invalid_1',
          playlistId: 'pl_1',
          trackUri: 'file:///vault/track1.mp3',
          title: 'Local Song',
          artistName: 'Local Artist',
          albumTitle: 'Local Album',
          durationMs: 120000,
          sourceType: TrackSourceTypeEnum.localSandbox,
          localRelativePath: null,
          sortOrder: 0,
          addedAtEpochMs: 1000,
        ),
        throwsFormatException,
      );

      expect(
        () => PrivateTrackRef(
          id: 't_local_invalid_2',
          playlistId: 'pl_1',
          trackUri: 'file:///vault/track1.mp3',
          title: 'Local Song',
          artistName: 'Local Artist',
          albumTitle: 'Local Album',
          durationMs: 120000,
          sourceType: TrackSourceTypeEnum.localSandbox,
          localRelativePath: '   ',
          sortOrder: 0,
          addedAtEpochMs: 1000,
        ),
        throwsFormatException,
      );

      // Spotify MUST have null localRelativePath
      expect(
        () => PrivateTrackRef(
          id: 't_spotify_invalid',
          playlistId: 'pl_1',
          trackUri: 'spotify:track:xyz',
          title: 'Spotify Song',
          artistName: 'Spotify Artist',
          albumTitle: 'Spotify Album',
          durationMs: 150000,
          sourceType: TrackSourceTypeEnum.spotify,
          localRelativePath: 'vault_media/.nomedia/xyz.mp3',
          sortOrder: 0,
          addedAtEpochMs: 1000,
        ),
        throwsFormatException,
      );

      // Valid LocalSandbox
      final validLocal = PrivateTrackRef(
        id: 't_local_valid',
        playlistId: 'pl_1',
        trackUri: 'file:///vault/track1.mp3',
        title: 'Local Song',
        artistName: 'Local Artist',
        albumTitle: 'Local Album',
        durationMs: 120000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/track1.mp3',
        sortOrder: 0,
        addedAtEpochMs: 1000,
      );
      expect(validLocal.sourceType, equals(TrackSourceTypeEnum.localSandbox));
      expect(validLocal.localRelativePath, equals('vault_media/.nomedia/track1.mp3'));
    });

    test('TrackSourceTypeEnum serialization rejects unknown id', () {
      expect(
        () => TrackSourceTypeEnum.fromId('UNKNOWN_SOURCE'),
        throwsFormatException,
      );
    });
  });

  group('Adversarial Stress Suite: VaultConfig Decoy Validation & Constant Constructor', () {
    test('Rejects empty or whitespace decoy persona fields in standard constructor', () {
      expect(() => VaultConfig(decoyTitle: ''), throwsFormatException);
      expect(() => VaultConfig(decoyTitle: '   '), throwsFormatException);
      expect(() => VaultConfig(decoyArtist: ''), throwsFormatException);
      expect(() => VaultConfig(decoyArtist: ' \t '), throwsFormatException);
      expect(() => VaultConfig(decoyAlbum: ''), throwsFormatException);
      expect(() => VaultConfig(decoyAlbum: ' \n '), throwsFormatException);
    });

    test('Constant constructor asserts non-empty strings', () {
      expect(
        () => VaultConfig.constant(decoyTitle: ''),
        throwsAssertionError,
      );
      expect(
        () => VaultConfig.constant(decoyArtist: ''),
        throwsAssertionError,
      );
      expect(
        () => VaultConfig.constant(decoyAlbum: ''),
        throwsAssertionError,
      );
    });

    test('Default constructor provides valid defaults conforming to §5.H', () {
      final config = VaultConfig();
      expect(config.decoyTitle, equals('System Audio'));
      expect(config.decoyArtist, equals('Media Service'));
      expect(config.decoyAlbum, equals('Internal Playback'));
      expect(config.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));
      expect(config.screenSecurity, equals(ScreenSecurityPolicyEnum.blockScreenshotsAndRecents));
    });
  });

  group('Adversarial Stress Suite: RecognitionScore & Bounds', () {
    test('Rejects classifier scores outside [0.0, 1.0]', () {
      expect(
        () => RecognitionScore(
          dollarOneScore: -0.01,
          dtwScore: 0.8,
          featureScore: 0.8,
          ensembleScore: 0.8,
          decision: GestureMatchDecisionEnum.matched,
        ),
        throwsFormatException,
      );
      expect(
        () => RecognitionScore(
          dollarOneScore: 1.01,
          dtwScore: 0.8,
          featureScore: 0.8,
          ensembleScore: 0.8,
          decision: GestureMatchDecisionEnum.matched,
        ),
        throwsFormatException,
      );
      expect(
        () => RecognitionScore(
          dollarOneScore: 0.8,
          dtwScore: double.nan,
          featureScore: 0.8,
          ensembleScore: 0.8,
          decision: GestureMatchDecisionEnum.matched,
        ),
        throwsFormatException,
      );
      expect(
        () => RecognitionScore(
          dollarOneScore: 0.8,
          dtwScore: 0.8,
          featureScore: -0.1,
          ensembleScore: 0.8,
          decision: GestureMatchDecisionEnum.matched,
        ),
        throwsFormatException,
      );
      expect(
        () => RecognitionScore(
          dollarOneScore: 0.8,
          dtwScore: 0.8,
          featureScore: 0.8,
          ensembleScore: 1.0001,
          decision: GestureMatchDecisionEnum.matched,
        ),
        throwsFormatException,
      );
    });

    test('computeEnsembleScore matches formula: 0.50 * \$1 + 0.35 * DTW + 0.15 * feat', () {
      final score = RecognitionScore.computeEnsembleScore(
        dollarOneScore: 0.90,
        dtwScore: 0.80,
        featureScore: 0.70,
      );
      // 0.50*0.90 (0.45) + 0.35*0.80 (0.28) + 0.15*0.70 (0.105) = 0.835
      expect(score, closeTo(0.835, 1e-6));
    });

    test('GestureMatchDecisionEnum deserialization rejects invalid identifiers', () {
      expect(
        () => GestureMatchDecisionEnum.fromId('UNKNOWN_DECISION'),
        throwsFormatException,
      );
    });
  });

  group('Adversarial Stress Suite: AuthSession & LockoutCooldownInfo', () {
    test('AuthSession rejects invalid tokens and chronologically corrupted timestamps', () {
      expect(
        () => AuthSession(
          sessionToken: '   ',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
        throwsFormatException,
      );
      expect(
        () => AuthSession(
          sessionToken: 'token123',
          sessionStartedEpochMs: 0,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
        throwsFormatException,
      );
      expect(
        () => AuthSession(
          sessionToken: 'token123',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 999,
          authMethod: AuthMethodEnum.pin,
        ),
        throwsFormatException,
      );
    });

    test('LockoutCooldownInfo rejects negative parameters', () {
      expect(
        () => LockoutCooldownInfo(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          consecutiveFailedAttempts: -1,
          deadlineMonotonicMs: 30000,
          remainingCooldownSeconds: 30,
        ),
        throwsFormatException,
      );
      expect(
        () => LockoutCooldownInfo(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          consecutiveFailedAttempts: 5,
          deadlineMonotonicMs: -1,
          remainingCooldownSeconds: 30,
        ),
        throwsFormatException,
      );
      expect(
        () => LockoutCooldownInfo(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          consecutiveFailedAttempts: 5,
          deadlineMonotonicMs: 30000,
          remainingCooldownSeconds: -1,
        ),
        throwsFormatException,
      );
    });
  });

  group('Adversarial Stress Suite: KeypadLayoutPolicy Digit Resolution & Shuffling', () {
    test('standardOrdered returns canonical telephone digits unmodifiable', () {
      final digits = KeypadLayoutPolicyEnum.standardOrdered.resolveDigits();
      expect(digits, equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));
      expect(() => digits.add(10), throwsUnsupportedError);
    });

    test('randomizedPerAttempt validates input permutation strictly', () {
      const policy = KeypadLayoutPolicyEnum.randomizedPerAttempt;

      // Null shuffled digits
      expect(
        () => policy.resolveDigits(shuffledDigits: null),
        throwsArgumentError,
      );

      // Wrong length (9 digits)
      expect(
        () => policy.resolveDigits(shuffledDigits: [0, 1, 2, 3, 4, 5, 6, 7, 8]),
        throwsArgumentError,
      );

      // Wrong length (11 digits)
      expect(
        () => policy.resolveDigits(shuffledDigits: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0]),
        throwsArgumentError,
      );

      // Duplicate digit (8 appears twice, 9 missing)
      expect(
        () => policy.resolveDigits(shuffledDigits: [0, 1, 2, 3, 4, 5, 6, 7, 8, 8]),
        throwsArgumentError,
      );

      // Valid permutation returns unmodifiable copy
      final shuffled = [9, 3, 8, 2, 7, 1, 6, 0, 5, 4];
      final resolved = policy.resolveDigits(shuffledDigits: shuffled);
      expect(resolved, equals(shuffled));
      expect(() => resolved.add(10), throwsUnsupportedError);
    });
  });

  group('Adversarial Stress Suite: State Invariant Assertion Gates', () {
    test('VaultSessionState assertion gates', () {
      expect(
        () => VaultLockedState(lockedAtMonotonicMs: -1),
        throwsAssertionError,
      );

      expect(
        () => VaultAuthenticatingState(
          authSessionId: '',
          attemptNumber: 1,
          remainingAttemptsBeforeCooldown: 5,
        ),
        throwsAssertionError,
      );

      expect(
        () => VaultAuthenticatingState(
          authSessionId: 'sess_1',
          attemptNumber: 0,
          remainingAttemptsBeforeCooldown: 5,
        ),
        throwsAssertionError,
      );

      final session = AuthSession(
        sessionToken: 'token',
        sessionStartedEpochMs: 100,
        lastActiveEpochMs: 100,
        authMethod: AuthMethodEnum.pin,
      );

      expect(
        () => VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: -1,
          reauthDeadlineMonotonicMs: 100,
        ),
        throwsAssertionError,
      );

      expect(
        () => VaultBackgroundGraceState(
          session: session,
          enteredBackgroundMonotonicMs: 100,
          graceTimeoutMs: 30000,
          graceDeadlineMonotonicMs: 99, // deadline < entered
        ),
        throwsAssertionError,
      );

      expect(
        () => VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          cooldownStartedMonotonicMs: 100,
          durationMs: 30000,
          deadlineMonotonicMs: 30100,
          failedAttemptsCount: 4, // Must be >= 5 for lockout
        ),
        throwsAssertionError,
      );
    });

    test('GestureEnrollmentState assertion gates and immutability', () {
      expect(
        () => GestureRecordingSampleState(
          sampleIndex: 0,
          totalRequiredSamples: 3,
        ),
        throwsAssertionError,
      );

      expect(
        () => GestureRecordingSampleState(
          sampleIndex: 4,
          totalRequiredSamples: 3,
        ),
        throwsAssertionError,
      );

      // previousSamples.length != sampleIndex - 1
      expect(
        () => GestureRecordingSampleState(
          sampleIndex: 2,
          totalRequiredSamples: 3,
          previousSamples: const [], // Expected 1 sample
        ),
        throwsAssertionError,
      );

      // Synthesizing empty samples
      expect(
        () => GestureSynthesizingTemplateState(samples: const []),
        throwsAssertionError,
      );
    });

    test('PinPadState assertion gates and mutations', () {
      expect(
        () => PinPadIdleInputState(
          enteredDigitsCount: -1,
          keypadLayout: KeypadLayoutPolicyEnum.standardOrdered,
        ),
        throwsAssertionError,
      );

      expect(
        () => PinPadIdleInputState(
          enteredDigitsCount: 7,
          keypadLayout: KeypadLayoutPolicyEnum.standardOrdered,
        ),
        throwsAssertionError,
      );

      const idle = PinPadIdleInputState(
        enteredDigitsCount: 5,
        keypadLayout: KeypadLayoutPolicyEnum.standardOrdered,
      );

      final appended = idle.appendDigit();
      expect(appended.enteredDigitsCount, equals(6));

      // Append beyond 6 is idempotent
      final capped = appended.appendDigit();
      expect(capped.enteredDigitsCount, equals(6));

      // Remove digit floors at 0
      final empty = capped.clearDigits();
      expect(empty.enteredDigitsCount, equals(0));
      final floored = empty.removeDigit();
      expect(floored.enteredDigitsCount, equals(0));
    });
  });

  group('Adversarial Stress Suite: Exhaustive Pattern Matching Without Wildcards', () {
    test('Exhaustive pattern match on VaultSessionState', () {
      final states = <VaultSessionState>[
        const VaultUninitializedState(),
        const VaultLockedState(lockedAtMonotonicMs: 100),
        const VaultAuthenticatingState(
          authSessionId: 'sess_1',
          attemptNumber: 1,
          remainingAttemptsBeforeCooldown: 5,
        ),
        VaultUnlockedState(
          session: AuthSession(
            sessionToken: 'token',
            sessionStartedEpochMs: 100,
            lastActiveEpochMs: 100,
            authMethod: AuthMethodEnum.pin,
          ),
          unlockedAtMonotonicMs: 100,
          reauthDeadlineMonotonicMs: 400000,
        ),
        VaultBackgroundGraceState(
          session: AuthSession(
            sessionToken: 'token',
            sessionStartedEpochMs: 100,
            lastActiveEpochMs: 100,
            authMethod: AuthMethodEnum.pin,
          ),
          enteredBackgroundMonotonicMs: 100,
          graceTimeoutMs: 30000,
          graceDeadlineMonotonicMs: 30100,
        ),
        VaultPendingReauthState(
          session: AuthSession(
            sessionToken: 'token',
            sessionStartedEpochMs: 100,
            lastActiveEpochMs: 100,
            authMethod: AuthMethodEnum.pin,
          ),
          reauthTriggeredAtMonotonicMs: 100,
          remainingAttempts: 3,
        ),
        const VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          cooldownStartedMonotonicMs: 100,
          durationMs: 30000,
          deadlineMonotonicMs: 30100,
          failedAttemptsCount: 5,
        ),
      ];

      for (final state in states) {
        final label = switch (state) {
          VaultUninitializedState() => 'uninitialized',
          VaultProvisioningState() => 'provisioning',
          VaultLockedState() => 'locked',
          VaultAuthenticatingState() => 'authenticating',
          VaultUnlockedState() => 'unlocked',
          VaultBackgroundGraceState() => 'backgroundGrace',
          VaultPendingReauthState() => 'pendingReauth',
          VaultLockoutCooldownState() => 'lockoutCooldown',
        };
        expect(label.isNotEmpty, isTrue);
      }
    });

    test('Exhaustive pattern match on VaultFailure hierarchy', () {
      final failures = <VaultFailure>[
        const VaultAuthFailure('Auth failed', remainingAttempts: 2),
        const VaultLockoutFailure('Lockout', remainingCooldownSeconds: 30, deadlineMonotonicMs: 30000),
        const VaultCryptoFailure('Crypto failure'),
        const VaultStorageFailure('Storage error'),
        const VaultGestureFailure('Gesture failed'),
        const VaultValidationFailure('Validation failed'),
      ];

      for (final failure in failures) {
        final category = switch (failure) {
          VaultAuthFailure() => 'auth',
          VaultLockoutFailure() => 'lockout',
          VaultCryptoFailure() => 'crypto',
          VaultStorageFailure() => 'storage',
          VaultGestureFailure() => 'gesture',
          VaultValidationFailure() => 'validation',
        };
        expect(category.isNotEmpty, isTrue);
      }
    });

    test('Exhaustive pattern match on CryptoEngineState hierarchy', () {
      final states = <CryptoEngineState>[
        const CryptoEngineUnprovisionedState(),
        const CryptoEngineKeyWrappedAtRestState(),
        const CryptoEngineUnwrappingMasterKeyState(slot: CryptoWrappingSlotEnum.slot1PinPbkdf2),
        const CryptoEngineMasterKeyUnwrappedInRamState(unwrappedAtMonotonicMs: 100),
        const CryptoEngineRotatingWrappingKeyState(targetSlot: CryptoWrappingSlotEnum.slot2BiometricHardwareKeyStore),
        const CryptoEnginePurgingAllVaultDataState(),
        const CryptoEngineCryptoFaultState(
          faultReason: CryptoFaultReasonEnum.keyStoreInvalidated,
          errorMessage: 'KeyStore invalidated',
        ),
      ];

      for (final state in states) {
        final label = switch (state) {
          CryptoEngineUnprovisionedState() => 'unprovisioned',
          CryptoEngineKeyWrappedAtRestState() => 'keyWrappedAtRest',
          CryptoEngineUnwrappingMasterKeyState() => 'unwrapping',
          CryptoEngineMasterKeyUnwrappedInRamState() => 'unwrappedInRam',
          CryptoEngineRotatingWrappingKeyState() => 'rotating',
          CryptoEnginePurgingAllVaultDataState() => 'purging',
          CryptoEngineCryptoFaultState() => 'fault',
        };
        expect(label.isNotEmpty, isTrue);
      }
    });

    test('Exhaustive pattern match on PlaybackPrivacyState hierarchy', () {
      final states = <PlaybackPrivacyState>[
        const PlaybackPrivacyPublicPassthroughState(),
        const PlaybackPrivacyVaultTrackActiveState(
          vaultTrackId: 'vt_1',
          maskingStatus: PlaybackMaskingStatusEnum.decoyPersonaProjected,
          visibilityPolicy: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        ),
        const PlaybackPrivacyExecutingLockStrategyState(
          activeVaultTrackId: 'vt_1',
          executingBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
        ),
      ];

      for (final state in states) {
        final label = switch (state) {
          PlaybackPrivacyPublicPassthroughState() => 'public',
          PlaybackPrivacyVaultTrackActiveState() => 'vaultTrack',
          PlaybackPrivacyExecutingLockStrategyState() => 'executingLock',
        };
        expect(label.isNotEmpty, isTrue);
      }
    });

    test('Exhaustive pattern match on ScreenPrivacyState hierarchy', () {
      final states = <ScreenPrivacyState>[
        const ScreenPrivacyPublicUnrestrictedState(),
        const ScreenPrivacySecureFlagEngagedState(reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive),
        const ScreenPrivacyPlatformSyncPendingState(
          targetState: ScreenPrivacyStateEnum.secureFlagEngaged,
          requestedAtMonotonicMs: 200,
        ),
      ];

      for (final state in states) {
        final label = switch (state) {
          ScreenPrivacyPublicUnrestrictedState() => 'unrestricted',
          ScreenPrivacySecureFlagEngagedState() => 'engaged',
          ScreenPrivacyPlatformSyncPendingState() => 'pending',
        };
        expect(label.isNotEmpty, isTrue);
      }
    });

    test('Exhaustive pattern match on SettingsMutationState hierarchy', () {
      final states = <SettingsMutationState>[
        const SettingsMutationSyncedIdleState(),
        const SettingsMutationAwaitingStepUpAuthState(
          mutationType: SensitiveSettingMutationEnum.pinRotation,
          requestedAtMonotonicMs: 300,
        ),
        const SettingsMutationPersistingConfigState(
          mutationType: SensitiveSettingMutationEnum.biometricPolicyChange,
        ),
        const SettingsMutationMutationRejectedState(
          mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
          rejectionReason: 'Authentication failed',
        ),
      ];

      for (final state in states) {
        final label = switch (state) {
          SettingsMutationSyncedIdleState() => 'idle',
          SettingsMutationAwaitingStepUpAuthState() => 'awaitingStepUp',
          SettingsMutationPersistingConfigState() => 'persisting',
          SettingsMutationMutationRejectedState() => 'rejected',
        };
        expect(label.isNotEmpty, isTrue);
      }
    });

    test('Policy domain methods and invariant evaluation', () {
      // ActiveReauthIntervalEnum
      expect(ActiveReauthIntervalEnum.every5Minutes.hasTimeout, isTrue);
      expect(ActiveReauthIntervalEnum.never.hasTimeout, isFalse);
      expect(ActiveReauthIntervalEnum.every5Minutes.isExpired(elapsedMonotonicMs: 300000), isTrue);
      expect(ActiveReauthIntervalEnum.every5Minutes.isExpired(elapsedMonotonicMs: 299999), isFalse);
      expect(ActiveReauthIntervalEnum.never.isExpired(elapsedMonotonicMs: 999999999), isFalse);

      // BackgroundGraceTimeoutEnum
      expect(BackgroundGraceTimeoutEnum.immediate.isImmediate, isTrue);
      expect(BackgroundGraceTimeoutEnum.thirtySeconds.isImmediate, isFalse);
      expect(BackgroundGraceTimeoutEnum.thirtySeconds.isExpired(elapsedBackgroundMs: 30000), isTrue);
      expect(BackgroundGraceTimeoutEnum.thirtySeconds.isExpired(elapsedBackgroundMs: 29999), isFalse);

      // BiometricAuthPolicyEnum
      expect(BiometricAuthPolicyEnum.pinAndBiometricStrong.allowsBiometrics, isTrue);
      expect(BiometricAuthPolicyEnum.pinOnly.allowsBiometrics, isFalse);
      expect(BiometricAuthPolicyEnum.pinOnly.requiresPinOnly, isTrue);

      // GestureSensitivityTierEnum
      expect(GestureSensitivityTierEnum.strict92Percent.isSatisfiedBy(0.88), isTrue);
      expect(GestureSensitivityTierEnum.strict92Percent.isSatisfiedBy(0.879), isFalse);

      // GestureVisibilityPolicyEnum
      expect(GestureVisibilityPolicyEnum.invisibleStealth.isInvisible, isTrue);
      expect(GestureVisibilityPolicyEnum.faintDissipatingHairline.isInkVisible, isTrue);

      // LockPlaybackBehaviorEnum
      expect(LockPlaybackBehaviorEnum.stopImmediately.shouldStopImmediately, isTrue);
      expect(LockPlaybackBehaviorEnum.finishCurrentTrack.allowsTrackCompletion, isTrue);
      expect(LockPlaybackBehaviorEnum.continueMaskedInBackground.allowsBackgroundPlayback, isTrue);

      // MetadataVisibilityPolicyEnum
      expect(MetadataVisibilityPolicyEnum.maskWithPlaceholder.isMasked, isTrue);
      expect(MetadataVisibilityPolicyEnum.showActualMetadata.isActualMetadataVisible, isTrue);
    });
  });
}
