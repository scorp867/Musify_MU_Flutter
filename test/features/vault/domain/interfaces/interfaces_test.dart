import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
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
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

/// Test implementation of IVaultAuthService for contract validation.
final class TestVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _stateController =
      StreamController<VaultSessionState>.broadcast();
  int failedAttempts = 0;
  bool ramKeysCleared = false;

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'test_token',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(VaultAuthFailure('Invalid PIN', remainingAttempts: 4));
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async {
    return VaultResult.success(
      AuthSession(
        sessionToken: 'bio_token',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 1000,
        authMethod: AuthMethodEnum.biometric,
      ),
    );
  }

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async {
    if (oldPin == newPin) {
      return const VaultResult.failure(
        VaultValidationFailure('New PIN must differ from current PIN.'),
      );
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> enrollInitialCredentials({
    required String pin,
    required GestureTemplate template,
  }) async {
    return const VaultResult.success(null);
  }

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async {
    return LockoutCooldownInfo.none();
  }

  @override
  Future<void> recordFailedAttempt() async {
    failedAttempts++;
  }

  @override
  Future<void> resetFailedAttempts() async {
    failedAttempts = 0;
  }

  @override
  void clearSessionKeysFromRam() {
    ramKeysCleared = true;
  }

  @override
  Stream<VaultSessionState> get sessionStateStream => _stateController.stream;

  void emitState(VaultSessionState state) {
    _stateController.add(state);
  }

  void dispose() {
    _stateController.close();
  }
}

/// Test implementation of IVaultStorageRepository for contract validation.
final class TestVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig _config = VaultConfig();
  final Map<String, PrivatePlaylist> _playlists = {};
  GestureTemplate? _template;
  int? _lockoutDeadline;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async {
    return VaultResult.success(_config);
  }

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config) async {
    _config = config;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    return VaultResult.success(_playlists.values.toList());
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final playlist = _playlists[id];
    if (playlist == null) {
      return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
    }
    return VaultResult.success(playlist);
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    final playlist = PrivatePlaylist(
      id: 'pl_1',
      name: name,
      description: description,
      coverUri: coverUri,
      totalDurationMs: 0,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: const [],
    );
    _playlists[playlist.id] = playlist;
    return VaultResult.success(playlist);
  }

  @override
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist) async {
    _playlists[playlist.id] = playlist;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    _playlists.remove(playlistId);
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async {
    final playlist = _playlists[playlistId];
    if (playlist == null) {
      return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
    }
    _playlists[playlistId] = playlist.copyWith(
      trackRefs: [...playlist.trackRefs, trackRef],
    );
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    final playlist = _playlists[playlistId];
    if (playlist == null) {
      return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
    }
    _playlists[playlistId] = playlist.copyWith(
      trackRefs: playlist.trackRefs.where((t) => t.id != trackId).toList(),
    );
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    final t = _template;
    if (t == null) {
      return const VaultResult.failure(VaultStorageFailure('No template enrolled'));
    }
    return VaultResult.success(t);
  }

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async {
    _template = template;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> purgeAllVaultData() async {
    _playlists.clear();
    _template = null;
    _lockoutDeadline = null;
    return const VaultResult.success(null);
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => _lockoutDeadline;

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) async {
    _lockoutDeadline = deadlineMonotonicMs;
  }

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    _lockoutDeadline = null;
  }
}

/// Test implementation of IGestureRecognizer for contract validation.
final class TestGestureRecognizer implements IGestureRecognizer {
  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    final score = RecognitionScore(
      dollarOneScore: 0.90,
      dtwScore: 0.85,
      featureScore: 0.80,
      ensembleScore: RecognitionScore.computeEnsembleScore(
        dollarOneScore: 0.90,
        dtwScore: 0.85,
        featureScore: 0.80,
      ),
      decision: GestureMatchDecisionEnum.matched,
    );
    return VaultResult.success(score);
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async {
    final template = GestureTemplate(
      id: 'template_1',
      normalizedPoints: List.generate(
        64,
        (i) => GesturePoint(x: i.toDouble(), y: 0.0, timestampMs: i * 10),
      ),
      rubineFeatureVector: const [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
      createdAtEpochMs: 1000,
    );
    return VaultResult.success(template);
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    return const VaultResult.success(null);
  }
}

/// Test implementation of IMediaMaskingStrategy for contract validation.
final class TestMediaMaskingStrategy implements IMediaMaskingStrategy {
  @override
  MetadataVisibilityPolicyEnum get policy => MetadataVisibilityPolicyEnum.maskWithPlaceholder;

  @override
  Map<String, String> maskMetadata({
    required Map<String, String> originalMetadata,
    required VaultConfig config,
  }) {
    return {
      'title': config.decoyTitle,
      'artist_name': config.decoyArtist,
      'album_title': config.decoyAlbum,
    };
  }

  @override
  ContextTrack projectTrack({
    required ContextTrack originalTrack,
    required VaultConfig config,
  }) {
    return ContextTrack(
      uri: originalTrack.uri,
      uid: originalTrack.uid,
      provider: originalTrack.provider,
      metadata: maskMetadata(
        originalMetadata: originalTrack.metadata,
        config: config,
      ),
    );
  }
}

/// Test implementation of ILockPlaybackStrategy for contract validation.
final class TestLockPlaybackStrategy implements ILockPlaybackStrategy {
  bool executed = false;

  @override
  LockPlaybackBehaviorEnum get behavior => LockPlaybackBehaviorEnum.stopImmediately;

  @override
  Future<void> executeLock({
    required PlayerQueueMobiusController mobiusController,
    required ContextPlayerControlClient playerControlClient,
  }) async {
    executed = true;
  }
}

/// Test implementation of IScreenPrivacyController for contract validation.
final class TestScreenPrivacyController implements IScreenPrivacyController {
  final StreamController<ScreenPrivacyStateEnum> _controller =
      StreamController<ScreenPrivacyStateEnum>.broadcast();
  ScreenPrivacyStateEnum _current = ScreenPrivacyStateEnum.publicUnrestricted;

  @override
  Future<void> enableSecureFlag() async {
    _current = ScreenPrivacyStateEnum.secureFlagEngaged;
    _controller.add(_current);
  }

  @override
  Future<void> disableSecureFlag() async {
    _current = ScreenPrivacyStateEnum.publicUnrestricted;
    _controller.add(_current);
  }

  @override
  ScreenPrivacyStateEnum get currentState => _current;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

/// Test implementation of IMonotonicClock for contract validation.
final class TestMonotonicClock implements IMonotonicClock {
  int _monotonicMs = 50000;

  void advance(int deltaMs) {
    _monotonicMs += deltaMs;
  }

  @override
  int get elapsedMilliseconds => _monotonicMs;

  @override
  int get currentMonotonicMs => _monotonicMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

void main() {
  group('IVaultAuthService Contract Tests', () {
    late TestVaultAuthService authService;

    setUp(() {
      authService = TestVaultAuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('authenticateWithPin returns AuthSession on valid PIN', () async {
      final result = await authService.authenticateWithPin(pin: '123456');
      expect(result, isA<VaultSuccess<AuthSession>>());
      final session = (result as VaultSuccess<AuthSession>).data;
      expect(session.sessionToken, 'test_token');
      expect(session.authMethod, AuthMethodEnum.pin);
    });

    test('authenticateWithPin returns VaultAuthFailure on invalid PIN', () async {
      final result = await authService.authenticateWithPin(pin: '000000');
      expect(result, isA<VaultFailureResult<AuthSession>>());
      final failure = (result as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultAuthFailure>());
    });

    test('authenticateWithBiometrics returns biometric AuthSession', () async {
      final result = await authService.authenticateWithBiometrics();
      expect(result, isA<VaultSuccess<AuthSession>>());
      final session = (result as VaultSuccess<AuthSession>).data;
      expect(session.authMethod, AuthMethodEnum.biometric);
    });

    test('rotatePin validates old vs new PIN', () async {
      final successResult = await authService.rotatePin(oldPin: '123456', newPin: '654321');
      expect(successResult, isA<VaultSuccess<void>>());

      final failResult = await authService.rotatePin(oldPin: '123456', newPin: '123456');
      expect(failResult, isA<VaultFailureResult<void>>());
    });

    test('getLockoutStatus returns unthrottled status', () async {
      final status = await authService.getLockoutStatus();
      expect(status.tier, LockoutCooldownTierEnum.none);
      expect(status.consecutiveFailedAttempts, 0);
    });

    test('failed attempt tracking and reset', () async {
      expect(authService.failedAttempts, 0);
      await authService.recordFailedAttempt();
      expect(authService.failedAttempts, 1);
      await authService.resetFailedAttempts();
      expect(authService.failedAttempts, 0);
    });

    test('clearSessionKeysFromRam executes without error', () {
      expect(authService.ramKeysCleared, isFalse);
      authService.clearSessionKeysFromRam();
      expect(authService.ramKeysCleared, isTrue);
    });

    test('sessionStateStream emits state transitions', () async {
      final states = <VaultSessionState>[];
      final subscription = authService.sessionStateStream.listen(states.add);

      const locked = VaultLockedState(lockedAtMonotonicMs: 100);
      const authenticating = VaultAuthenticatingState(
        authSessionId: 'auth_1',
        attemptNumber: 1,
        remainingAttemptsBeforeCooldown: 5,
      );

      authService.emitState(locked);
      authService.emitState(authenticating);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(states, [locked, authenticating]);

      await subscription.cancel();
    });
  });

  group('IVaultStorageRepository Contract Tests', () {
    late TestVaultStorageRepository repository;

    setUp(() {
      repository = TestVaultStorageRepository();
    });

    test('load and save VaultConfig', () async {
      final initial = await repository.loadVaultConfig();
      expect(initial, isA<VaultSuccess<VaultConfig>>());

      final updatedConfig = (initial as VaultSuccess<VaultConfig>).data.copyWith(
            decoyTitle: 'Custom Decoy',
          );
      final saveResult = await repository.saveVaultConfig(updatedConfig);
      expect(saveResult, isA<VaultSuccess<void>>());

      final reloaded = await repository.loadVaultConfig();
      expect((reloaded as VaultSuccess<VaultConfig>).data.decoyTitle, 'Custom Decoy');
    });

    test('playlist CRUD operations', () async {
      final createResult = await repository.createPlaylist(
        name: 'Private Favorites',
        description: 'Secret tracks',
      );
      expect(createResult, isA<VaultSuccess<PrivatePlaylist>>());
      final created = (createResult as VaultSuccess<PrivatePlaylist>).data;

      final fetchResult = await repository.getPlaylistById(created.id);
      expect(fetchResult, isA<VaultSuccess<PrivatePlaylist>>());

      final listResult = await repository.getPlaylists();
      expect((listResult as VaultSuccess<List<PrivatePlaylist>>).data.length, 1);

      final track = PrivateTrackRef(
        id: 't_1',
        playlistId: 'pl_1',
        trackUri: 'spotify:track:123',
        title: 'Secret Song',
        artistName: 'Secret Artist',
        albumTitle: 'Secret Album',
        durationMs: 200000,
        sourceType: TrackSourceTypeEnum.spotify,
        sortOrder: 0,
        addedAtEpochMs: 1000,
      );

      final addResult = await repository.addTrackToPlaylist(
        playlistId: created.id,
        trackRef: track,
      );
      expect(addResult, isA<VaultSuccess<void>>());

      final afterAdd = await repository.getPlaylistById(created.id);
      expect((afterAdd as VaultSuccess<PrivatePlaylist>).data.trackRefs.length, 1);

      final removeResult = await repository.removeTrackFromPlaylist(
        playlistId: created.id,
        trackId: 't_1',
      );
      expect(removeResult, isA<VaultSuccess<void>>());

      final afterRemove = await repository.getPlaylistById(created.id);
      expect((afterRemove as VaultSuccess<PrivatePlaylist>).data.trackRefs.length, 0);

      final deleteResult = await repository.deletePlaylist(created.id);
      expect(deleteResult, isA<VaultSuccess<void>>());

      final afterDelete = await repository.getPlaylistById(created.id);
      expect(afterDelete, isA<VaultFailureResult<PrivatePlaylist>>());
    });

    test('lockout deadline persistence and clear', () async {
      expect(await repository.getPersistedLockoutDeadlineMs(), isNull);

      await repository.persistLockoutDeadlineMs(123456789);
      expect(await repository.getPersistedLockoutDeadlineMs(), 123456789);

      await repository.clearPersistedLockoutDeadline();
      expect(await repository.getPersistedLockoutDeadlineMs(), isNull);
    });

    test('purgeAllVaultData clears all stored entities', () async {
      await repository.createPlaylist(name: 'A', description: 'B');
      await repository.persistLockoutDeadlineMs(999);
      expect((await repository.getPlaylists() as VaultSuccess).data.length, 1);

      final purgeResult = await repository.purgeAllVaultData();
      expect(purgeResult, isA<VaultSuccess<void>>());
      expect((await repository.getPlaylists() as VaultSuccess).data.isEmpty, isTrue);
      expect(await repository.getPersistedLockoutDeadlineMs(), isNull);
    });
  });

  group('IGestureRecognizer Contract Tests', () {
    late TestGestureRecognizer recognizer;

    setUp(() {
      recognizer = TestGestureRecognizer();
    });

    test('evaluateStroke returns valid RecognitionScore', () async {
      final sample = GestureSample(
        points: [
          GesturePoint(x: 0, y: 0, timestampMs: 0),
          GesturePoint(x: 10, y: 10, timestampMs: 50),
        ],
        sampledAtEpochMs: 1000,
        totalLength: 14.14,
      );
      final template = GestureTemplate(
        id: 't_1',
        normalizedPoints: List.generate(
          64,
          (i) => GesturePoint(x: i.toDouble(), y: 0.0, timestampMs: i * 10),
        ),
        rubineFeatureVector: const [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
        createdAtEpochMs: 1000,
      );

      final result = await recognizer.evaluateStroke(
        liveStroke: sample,
        template: template,
        sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
      );

      expect(result, isA<VaultSuccess<RecognitionScore>>());
      final score = (result as VaultSuccess<RecognitionScore>).data;
      expect(score.dollarOneScore, 0.90);
      expect(score.dtwScore, 0.85);
      expect(score.featureScore, 0.80);
      expect(score.ensembleScore, closeTo(0.8675, 0.001));
    });

    test('synthesizeMasterTemplate creates 64-point golden template', () async {
      final sample = GestureSample(
        points: [
          GesturePoint(x: 0, y: 0, timestampMs: 0),
          GesturePoint(x: 10, y: 10, timestampMs: 50),
        ],
        sampledAtEpochMs: 1000,
        totalLength: 14.14,
      );

      final result = await recognizer.synthesizeMasterTemplate(samples: [sample]);
      expect(result, isA<VaultSuccess<GestureTemplate>>());
      final template = (result as VaultSuccess<GestureTemplate>).data;
      expect(template.normalizedPoints.length, 64);
      expect(template.rubineFeatureVector.length, 7);
    });

    test('validateSampleConsistency returns success', () async {
      final result = await recognizer.validateSampleConsistency(samples: []);
      expect(result, isA<VaultSuccess<void>>());
    });
  });

  group('IMediaMaskingStrategy & ILockPlaybackStrategy Contract Tests', () {
    test('IMediaMaskingStrategy masks metadata and projects ContextTrack', () {
      final strategy = TestMediaMaskingStrategy();
      expect(strategy.policy, MetadataVisibilityPolicyEnum.maskWithPlaceholder);

      final config = VaultConfig(
        decoyTitle: 'Decoy Song',
        decoyArtist: 'Decoy Artist',
        decoyAlbum: 'Decoy Album',
      );

      final originalMeta = {
        'title': 'Real Secret Song',
        'artist_name': 'Real Artist',
        'album_title': 'Real Album',
      };

      final masked = strategy.maskMetadata(
        originalMetadata: originalMeta,
        config: config,
      );
      expect(masked['title'], 'Decoy Song');
      expect(masked['artist_name'], 'Decoy Artist');
      expect(masked['album_title'], 'Decoy Album');

      const originalTrack = ContextTrack(
        uri: 'spotify:track:private123',
        uid: 'uid_1',
        provider: 'context',
        metadata: {
          'title': 'Real Secret Song',
        },
      );

      final projected = strategy.projectTrack(
        originalTrack: originalTrack,
        config: config,
      );
      expect(projected.uri, 'spotify:track:private123');
      expect(projected.metadata['title'], 'Decoy Song');
    });

    test('ILockPlaybackStrategy behavior getter', () {
      final lockStrategy = TestLockPlaybackStrategy();
      expect(lockStrategy.behavior, LockPlaybackBehaviorEnum.stopImmediately);
    });
  });

  group('IScreenPrivacyController Contract Tests', () {
    late TestScreenPrivacyController controller;

    setUp(() {
      controller = TestScreenPrivacyController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('enableSecureFlag and disableSecureFlag mutate state and stream', () async {
      expect(controller.currentState, ScreenPrivacyStateEnum.publicUnrestricted);

      final states = <ScreenPrivacyStateEnum>[];
      final sub = controller.stateStream.listen(states.add);

      await controller.enableSecureFlag();
      expect(controller.currentState, ScreenPrivacyStateEnum.secureFlagEngaged);

      await controller.disableSecureFlag();
      expect(controller.currentState, ScreenPrivacyStateEnum.publicUnrestricted);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(states, [
        ScreenPrivacyStateEnum.secureFlagEngaged,
        ScreenPrivacyStateEnum.publicUnrestricted,
      ]);

      await sub.cancel();
    });
  });

  group('IMonotonicClock Contract Tests', () {
    test('IMonotonicClock elapsedMilliseconds and createStopwatch', () {
      final clock = TestMonotonicClock();
      expect(clock.elapsedMilliseconds, 50000);
      expect(clock.currentMonotonicMs, 50000);

      clock.advance(1500);
      expect(clock.elapsedMilliseconds, 51500);
      expect(clock.currentMonotonicMs, 51500);

      final sw = clock.createStopwatch();
      expect(sw, isA<Stopwatch>());
      expect(sw.isRunning, isFalse);
    });
  });
}
