import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/pause_command.dart';
import 'package:musify_mu/features/player/domain/commands/resume_command.dart';
import 'package:musify_mu/features/player/domain/commands/skip_to_next_track_command.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/vault/application/coordinator/vault_coordinator.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

class AdversarialMonotonicClock implements IMonotonicClock {
  int timeMs;

  AdversarialMonotonicClock({this.timeMs = 10000});

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class AdversarialScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCount = 0;
  int disableCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
  }
}

class AdversarialGestureRecognizer implements IGestureRecognizer {
  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async =>
      VaultResult.success(
        RecognitionScore(
          dollarOneScore: 0.95,
          dtwScore: 0.90,
          featureScore: 0.88,
          ensembleScore: 0.92,
          decision: GestureMatchDecisionEnum.matched,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();
  GestureTemplate? template = DefaultGestureTemplate.canonicalVShape;
  int? persistedDeadlineMs;
  int saveCount = 0;
  int clearDeadlineCount = 0;

  @override
  Future<bool> hasEnrolledVault() async => template != null;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    saveCount++;
    config = newConfig;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    final t = template;
    if (t != null) {
      return VaultResult.success(t);
    }
    return const VaultResult.failure(VaultStorageFailure('Not enrolled'));
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => persistedDeadlineMs;

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMs) async {
    persistedDeadlineMs = deadlineMs;
  }

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    clearDeadlineCount++;
    persistedDeadlineMs = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> sessionController =
      StreamController<VaultSessionState>.broadcast();

  int clearSessionKeysCallCount = 0;
  int resetFailedAttemptsCallCount = 0;
  int recordFailedAttemptCallCount = 0;

  Stream<VaultSessionState> get sessionStateStream => sessionController.stream;

  @override
  void clearSessionKeysFromRam() {
    clearSessionKeysCallCount++;
  }

  @override
  Future<void> resetFailedAttempts() async {
    resetFailedAttemptsCallCount++;
  }

  @override
  Future<void> recordFailedAttempt() async {
    recordFailedAttemptCallCount++;
  }

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async =>
      LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.none,
        remainingCooldownSeconds: 0,
        deadlineMonotonicMs: 0,
        consecutiveFailedAttempts: 0,
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'adversarial_valid_token',
          sessionStartedEpochMs: 10000,
          lastActiveEpochMs: 10000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(VaultAuthFailure('Invalid PIN'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialControlClient implements ContextPlayerControlClient {
  int stopCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async {
    pauseCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async {
    resumeCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async =>
      PlayerResponse.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  QueueModel _model = const QueueModel();
  final AdversarialControlClient _controlClient = AdversarialControlClient();
  final List<QueueEvent> dispatchedEvents = <QueueEvent>[];

  @override
  ContextPlayerControlClient get controlClient => _controlClient;

  @override
  QueueModel get model => _model;

  @override
  QueueModel get state => _model;

  @override
  QueueModel get value => _model;

  @override
  Stream<QueueModel> get stream => _modelController.stream;

  @override
  bool get isClosed => false;

  void updateModel(QueueModel newModel) {
    _model = newModel;
    _modelController.add(newModel);
  }

  @override
  void dispatch(QueueEvent event) {
    dispatchedEvents.add(event);
  }

  @override
  void add(QueueEvent event) {
    dispatchedEvents.add(event);
  }

  @override
  Future<void> playContext(Context context, {PreparePlayOptions? options, PlayOrigin? playOrigin}) async {}

  @override
  Future<void> close() async {
    await _modelController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdversarialMonotonicClock clock;
  late AdversarialVaultStorageRepository storage;
  late AdversarialVaultAuthService authService;
  late AdversarialScreenPrivacyController privacyController;
  late AdversarialGestureRecognizer gestureRecognizer;
  late AdversarialMobiusController mobiusController;

  late VaultSessionBloc sessionBloc;
  late PlaybackPrivacyProxy playbackPrivacyProxy;
  late ScreenPrivacyCubit screenPrivacyCubit;
  late GestureEngineCubit gestureEngineCubit;
  late SettingsMutationCubit settingsMutationCubit;
  late PinPadCubit pinPadCubit;
  late VaultCoordinator coordinator;

  final testSession = AuthSession(
    sessionToken: 'stress_test_token',
    sessionStartedEpochMs: 10000,
    lastActiveEpochMs: 10000,
    authMethod: AuthMethodEnum.pin,
  );

  setUp(() {
    clock = AdversarialMonotonicClock(timeMs: 10000);
    storage = AdversarialVaultStorageRepository();
    authService = AdversarialVaultAuthService();
    privacyController = AdversarialScreenPrivacyController();
    gestureRecognizer = AdversarialGestureRecognizer();
    mobiusController = AdversarialMobiusController();

    sessionBloc = VaultSessionBloc(
      authService: authService,
      storageRepository: storage,
      monotonicClock: clock,
      verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: clock),
      initialState: const VaultLockedState(lockedAtMonotonicMs: 10000),
    );

    playbackPrivacyProxy = PlaybackPrivacyProxy(
      vaultAuthService: authService,
      mobiusController: mobiusController,
      storageRepository: storage,
      controlClient: mobiusController.controlClient,
    );

    screenPrivacyCubit = ScreenPrivacyCubit(
      privacyController: privacyController,
      monotonicClock: clock,
    );

    gestureEngineCubit = GestureEngineCubit(
      recognizer: gestureRecognizer,
      storageRepository: storage,
      vaultAuthService: authService,
    );

    settingsMutationCubit = SettingsMutationCubit(
      storageRepository: storage,
      mutateVaultConfigUseCase: MutateVaultConfigUseCase(
        authService: authService,
        storageRepository: storage,
      ),
      authService: authService,
      monotonicClock: clock,
    );

    pinPadCubit = PinPadCubit(
      unlockVaultUseCase: UnlockVaultUseCase(authService: authService),
      authService: authService,
      monotonicClock: clock,
    );

    coordinator = VaultCoordinator(
      sessionBloc: sessionBloc,
      playbackPrivacyProxy: playbackPrivacyProxy,
      screenPrivacyCubit: screenPrivacyCubit,
      gestureEngineCubit: gestureEngineCubit,
      settingsMutationCubit: settingsMutationCubit,
      pinPadCubit: pinPadCubit,
      monotonicClock: clock,
    );

    coordinator.initialize();
  });

  tearDown(() async {
    await coordinator.dispose();
    await sessionBloc.close();
    await playbackPrivacyProxy.dispose();
    await screenPrivacyCubit.close();
    await gestureEngineCubit.close();
    await settingsMutationCubit.close();
    await pinPadCubit.close();
    await mobiusController.close();
  });

  group('VaultSessionBloc Stress: Rapid App Pause/Resume Cycles & Exact Boundary Stress', () {
    test('rapid 50 pause/resume cycles within background grace window maintain unlocked state', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultUnlockedState>());
      expect(authService.clearSessionKeysCallCount, equals(0));

      // Rapidly cycle pause and resume 50 times within grace window (each tick +10ms)
      for (int i = 0; i < 50; i++) {
        clock.timeMs += 10;
        sessionBloc.add(VaultAppBackgrounded(pausedAtMonotonicMs: clock.currentMonotonicMs));
        await Future<void>.delayed(const Duration(milliseconds: 2));

        expect(sessionBloc.state, isA<VaultBackgroundGraceState>());

        clock.timeMs += 10;
        sessionBloc.add(VaultAppForegrounded(resumedAtMonotonicMs: clock.currentMonotonicMs));
        await Future<void>.delayed(const Duration(milliseconds: 2));

        expect(sessionBloc.state, isA<VaultUnlockedState>());
        expect(authService.clearSessionKeysCallCount, equals(0));
      }

      final finalState = sessionBloc.state as VaultUnlockedState;
      expect(finalState.session, equals(testSession));
      expect(authService.clearSessionKeysCallCount, equals(0));
    });

    test('exact boundary: resume at deadlineMonotonicMs - 1ms restores VaultUnlockedState', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      clock.timeMs = 10000;
      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final graceState = sessionBloc.state as VaultBackgroundGraceState;
      expect(graceState.graceDeadlineMonotonicMs, equals(40000));

      // Advance clock to exactly deadline - 1ms (39999)
      clock.timeMs = 39999;
      sessionBloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultUnlockedState>());
      expect(authService.clearSessionKeysCallCount, equals(0));
    });

    test('exact boundary: resume at exactly deadlineMonotonicMs locks and wipes RAM keys', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      clock.timeMs = 10000;
      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final graceState = sessionBloc.state as VaultBackgroundGraceState;
      expect(graceState.graceDeadlineMonotonicMs, equals(40000));

      // Advance clock to EXACT deadline (40000)
      clock.timeMs = 40000;
      sessionBloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      final locked = sessionBloc.state as VaultLockedState;
      expect(locked.lockedAtMonotonicMs, equals(40000));
      expect(authService.clearSessionKeysCallCount, equals(1));
    });

    test('exact boundary: resume at deadlineMonotonicMs + 1ms locks and wipes RAM keys', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      clock.timeMs = 10000;
      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Advance clock past deadline (40001)
      clock.timeMs = 40001;
      sessionBloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      final locked = sessionBloc.state as VaultLockedState;
      expect(locked.lockedAtMonotonicMs, equals(40001));
      expect(authService.clearSessionKeysCallCount, equals(1));
    });

    test('grace timer deadline elapsing while backgrounded triggers lock and wipes RAM keys', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      clock.timeMs = 10000;
      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultBackgroundGraceState>());

      // Grace timer fires in background
      sessionBloc.add(const VaultGraceDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));
    });

    test('immediate grace timeout locks and clears keys immediately without waiting', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.immediate,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));

      // Attempt foreground: should not recover unlocked state
      sessionBloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
    });
  });

  group('VaultSessionBloc Stress: Re-Auth Interval Expiration & Audio Preservation', () {
    test('expiration during active re-auth interval emits VaultPendingReauthState without stopping audio', () async {
      final config = const VaultConfig.constant().copyWith(
        activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes,
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Simulate a private vault track actively playing in PlaybackPrivacyProxy
      final vaultTrack = const ContextTrack(
        uri: 'vault_track_123',
        metadata: {'vaultId': 'private_track_1', 'isPrivateVault': 'true'},
      );
      playbackPrivacyProxy.notifyVaultTrackActivated(
        vaultTrackId: 'private_track_1',
        track: vaultTrack,
      );
      expect(playbackPrivacyProxy.isVaultTrackActive, isTrue);

      final navTargets = <VaultNavigationTarget>[];
      final navSub = coordinator.navigationStream.listen(navTargets.add);

      // Re-auth deadline elapses mid-session
      sessionBloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Region A transitions to pendingReauth
      expect(sessionBloc.state, isA<VaultPendingReauthState>());
      final pendingState = sessionBloc.state as VaultPendingReauthState;
      expect(pendingState.remainingAttempts, equals(3));

      // Region B does NOT stop audio on pendingReauth
      final controlClient = mobiusController.controlClient as AdversarialControlClient;
      expect(controlClient.stopCallCount, equals(0));
      expect(playbackPrivacyProxy.isVaultTrackActive, isTrue);
      expect(authService.clearSessionKeysCallCount, equals(0));

      // Coordinator emits reauthOverlay
      expect(navTargets.contains(VaultNavigationTarget.reauthOverlay), isTrue);

      await navSub.cancel();
    });

    test('step-up reauth success recovers VaultUnlockedState without stopping audio', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      sessionBloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultPendingReauthState>());

      final newSession = AuthSession(
        sessionToken: 'reauth_refreshed_token',
        sessionStartedEpochMs: 25000,
        lastActiveEpochMs: 25000,
        authMethod: AuthMethodEnum.pin,
      );

      sessionBloc.add(VaultStepUpAuthSucceeded(session: newSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultUnlockedState>());
      final unlocked = sessionBloc.state as VaultUnlockedState;
      expect(unlocked.session.sessionToken, equals('reauth_refreshed_token'));
      final controlClient = mobiusController.controlClient as AdversarialControlClient;
      expect(controlClient.stopCallCount, equals(0));
      expect(authService.clearSessionKeysCallCount, equals(0));
    });

    test('step-up reauth 3 failed attempts exhaust allowance, lock session, wipe RAM keys, and record failure', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      sessionBloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Attempt 1 fails
      sessionBloc.add(const VaultStepUpAuthFailed());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((sessionBloc.state as VaultPendingReauthState).remainingAttempts, equals(2));
      expect(authService.clearSessionKeysCallCount, equals(0));

      // Attempt 2 fails
      sessionBloc.add(const VaultStepUpAuthFailed());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((sessionBloc.state as VaultPendingReauthState).remainingAttempts, equals(1));
      expect(authService.clearSessionKeysCallCount, equals(0));

      // Attempt 3 fails: exhausted
      sessionBloc.add(const VaultStepUpAuthFailed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));
      expect(authService.recordFailedAttemptCallCount, equals(1));
    });

    test('step-up reauth cancellation immediately locks session and wipes RAM keys', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      sessionBloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      sessionBloc.add(const VaultStepUpAuthCanceled());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));
    });
  });

  group('VaultSessionBloc Stress: Lockout Deadline Persistence & Cooldown Across App Pause', () {
    test('lockout cooldown state survives app pause/resume before monotonic deadline', () async {
      clock.timeMs = 10000;
      final lockoutState = VaultLockoutCooldownState(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        cooldownStartedMonotonicMs: 10000,
        durationMs: 30000,
        deadlineMonotonicMs: 40000,
        failedAttemptsCount: 5,
      );
      storage.persistedDeadlineMs = 40000;

      // Transition to lockout
      sessionBloc.add(
        VaultLockoutTriggered(
          tier: lockoutState.tier,
          cooldownStartedMonotonicMs: lockoutState.cooldownStartedMonotonicMs,
          durationMs: lockoutState.durationMs,
          deadlineMonotonicMs: lockoutState.deadlineMonotonicMs,
          failedAttemptsCount: lockoutState.failedAttemptsCount,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultLockoutCooldownState>());

      // App goes to background at 15,000ms
      clock.timeMs = 15000;
      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // App resumes at 25,000ms (15s before deadline 40,000ms)
      clock.timeMs = 25000;
      sessionBloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockoutCooldownState>());
      final activeLockout = sessionBloc.state as VaultLockoutCooldownState;
      expect(activeLockout.deadlineMonotonicMs, equals(40000));
      expect(storage.persistedDeadlineMs, equals(40000));
      expect(authService.resetFailedAttemptsCallCount, equals(0));
    });

    test('app foregrounded exactly at or after lockout deadline unlocks to VaultLockedState and resets failures', () async {
      clock.timeMs = 10000;
      final lockoutState = VaultLockoutCooldownState(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        cooldownStartedMonotonicMs: 10000,
        durationMs: 30000,
        deadlineMonotonicMs: 40000,
        failedAttemptsCount: 5,
      );
      storage.persistedDeadlineMs = 40000;

      sessionBloc.add(
        VaultLockoutTriggered(
          tier: lockoutState.tier,
          cooldownStartedMonotonicMs: lockoutState.cooldownStartedMonotonicMs,
          durationMs: lockoutState.durationMs,
          deadlineMonotonicMs: lockoutState.deadlineMonotonicMs,
          failedAttemptsCount: lockoutState.failedAttemptsCount,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultLockoutCooldownState>());

      // App backgrounded
      clock.timeMs = 20000;
      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // App resumes after deadline (40000ms)
      clock.timeMs = 40000;
      sessionBloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(storage.clearDeadlineCount, equals(1));
      expect(authService.resetFailedAttemptsCallCount, equals(1));
    });

    test('lockout timer elapsed event clears persisted deadline and resets attempts', () async {
      clock.timeMs = 10000;
      final lockoutState = VaultLockoutCooldownState(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        cooldownStartedMonotonicMs: 10000,
        durationMs: 30000,
        deadlineMonotonicMs: 40000,
        failedAttemptsCount: 5,
      );
      storage.persistedDeadlineMs = 40000;

      sessionBloc.add(
        VaultLockoutTriggered(
          tier: lockoutState.tier,
          cooldownStartedMonotonicMs: lockoutState.cooldownStartedMonotonicMs,
          durationMs: lockoutState.durationMs,
          deadlineMonotonicMs: lockoutState.deadlineMonotonicMs,
          failedAttemptsCount: lockoutState.failedAttemptsCount,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultLockoutCooldownState>());

      sessionBloc.add(const VaultLockoutDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(storage.clearDeadlineCount, equals(1));
      expect(authService.resetFailedAttemptsCallCount, equals(1));
    });

    test('app cold boot with active persisted deadline restores VaultLockoutCooldownState directly', () async {
      final freshStorage = AdversarialVaultStorageRepository();
      final freshAuthService = AdversarialVaultAuthService();
      final freshClock = AdversarialMonotonicClock(timeMs: 15000);
      freshStorage.template = DefaultGestureTemplate.canonicalVShape;
      freshStorage.persistedDeadlineMs = 60000; // Remaining: 45000ms (> 30000ms -> tier 2)

      final coldBootBloc = VaultSessionBloc(
        authService: freshAuthService,
        storageRepository: freshStorage,
        monotonicClock: freshClock,
        verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: freshClock),
      );

      coldBootBloc.add(const VaultInitializeRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(coldBootBloc.state, isA<VaultLockoutCooldownState>());
      final restored = coldBootBloc.state as VaultLockoutCooldownState;
      expect(restored.tier, equals(LockoutCooldownTierEnum.tier2FiveMinutes));
      expect(restored.deadlineMonotonicMs, equals(60000));

      await coldBootBloc.close();
    });
  });

  group('VaultSessionBloc & Coordinator: Manual Quick-Lock & RAM Key Wiping', () {
    test('manual quick-lock from VaultUnlockedState wipes RAM keys immediately', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultUnlockedState>());
      expect(authService.clearSessionKeysCallCount, equals(0));

      sessionBloc.add(const VaultQuickLockRequested(reason: 'security panic'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));
    });

    test('manual quick-lock from VaultBackgroundGraceState wipes RAM keys immediately', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.oneMinute,
      );
      sessionBloc.add(VaultConfigUpdated(config: config));
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      sessionBloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sessionBloc.state, isA<VaultBackgroundGraceState>());

      sessionBloc.add(const VaultQuickLockRequested(reason: 'manual lock in grace'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));
    });

    test('manual quick-lock from VaultPendingReauthState wipes RAM keys immediately', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      sessionBloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sessionBloc.state, isA<VaultPendingReauthState>());

      sessionBloc.add(const VaultQuickLockRequested(reason: 'manual lock during reauth'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));
    });

    test('coordinator.requestQuickLock() locks session, wipes RAM keys, and resets PinPadCubit', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      pinPadCubit.onDigitEntered(5);
      pinPadCubit.onDigitEntered(8);
      expect((pinPadCubit.state as PinPadIdleInputState).enteredDigitsCount, equals(2));

      coordinator.requestQuickLock();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.clearSessionKeysCallCount, equals(1));
      expect(pinPadCubit.state, isA<PinPadIdleInputState>());
      expect((pinPadCubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });
  });

  group('VaultCoordinator Stress: Cross-Region Event Bursts & Concurrency Stress', () {
    test('stress test simultaneous burst of 50 cross-region events without crash or unhandled error', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final navTargets = <VaultNavigationTarget>[];
      final navSub = coordinator.navigationStream.listen(navTargets.add);

      // Concurrent event burst
      final futures = <Future<void>>[];
      for (int i = 0; i < 50; i++) {
        final cycle = i % 5;
        switch (cycle) {
          case 0:
            coordinator.onStealthGestureTriggered();
          case 1:
            coordinator.onAppLifecycleStateChanged(AppLifecycleState.inactive);
          case 2:
            coordinator.onAppLifecycleStateChanged(AppLifecycleState.resumed);
          case 3:
            final sensitivity = (i % 2 == 0)
                ? GestureSensitivityTierEnum.strict92Percent
                : GestureSensitivityTierEnum.relaxed76Percent;
            futures.add(
              settingsMutationCubit.updateGeneralPolicy(
                settingsMutationCubit.currentConfig.copyWith(
                  gestureSensitivity: sensitivity,
                ),
              ),
            );
          case 4:
            pinPadCubit.onDigitEntered(i % 10);
        }
      }

      await Future.wait(futures);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert coordinator and all regions survived cleanly without throwing
      expect(coordinator.isDisposed, isFalse);
      expect(navTargets.isNotEmpty, isTrue);

      await navSub.cancel();
    });

    test('simultaneous stealth gesture match and app pause resolves deterministically', () async {
      sessionBloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final navTargets = <VaultNavigationTarget>[];
      final navSub = coordinator.navigationStream.listen(navTargets.add);

      // Trigger gesture and pause at exact same time
      coordinator.onStealthGestureTriggered();
      coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Gesture matched while active session was unlocked emits dashboardScreen
      expect(navTargets.contains(VaultNavigationTarget.dashboardScreen), isTrue);
      // App pause transitions session to background grace
      expect(sessionBloc.state, isA<VaultBackgroundGraceState>());

      await navSub.cancel();
    });

    test('rapid multi-attribute settings mutations propagate consistently across regions', () async {
      final updatedConfig1 = settingsMutationCubit.currentConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
        gestureSensitivity: GestureSensitivityTierEnum.strict92Percent,
      );
      final updatedConfig2 = updatedConfig1.copyWith(
        themePalette: VaultThemePalettePolicyEnum.warmEspresso,
        screenSecurity: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
      );

      await settingsMutationCubit.updateGeneralPolicy(updatedConfig1);
      await settingsMutationCubit.updateGeneralPolicy(updatedConfig2);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(settingsMutationCubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));
      expect(settingsMutationCubit.currentConfig.screenSecurity, equals(ScreenSecurityPolicyEnum.blockScreenshotsAndRecents));
      expect(playbackPrivacyProxy.cachedConfig.screenSecurity, equals(ScreenSecurityPolicyEnum.blockScreenshotsAndRecents));
      expect(gestureEngineCubit.sensitivityTier, equals(GestureSensitivityTierEnum.strict92Percent));
    });
  });

  group('VaultCoordinator Stress: Proper Stream Closure, Safe Post-Disposal & Zero Leaks', () {
    test('coordinator.dispose() is fully idempotent and can be invoked multiple times', () async {
      expect(coordinator.isDisposed, isFalse);

      await coordinator.dispose();
      expect(coordinator.isDisposed, isTrue);

      // Second invocation should complete cleanly without error
      await coordinator.dispose();
      expect(coordinator.isDisposed, isTrue);
    });

    test('navigationStream closes cleanly upon coordinator disposal', () async {
      final streamDoneCompleter = Completer<void>();
      coordinator.navigationStream.listen(
        (_) {},
        onDone: () => streamDoneCompleter.complete(),
      );

      await coordinator.dispose();
      await expectLater(streamDoneCompleter.future, completes);
    });

    test('post-disposal operations are safe no-ops and never throw StateError or leak', () async {
      await coordinator.dispose();

      expect(() => coordinator.onStealthGestureTriggered(), returnsNormally);
      expect(() => coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused), returnsNormally);
      expect(() => coordinator.onAppLifecycleStateChanged(AppLifecycleState.resumed), returnsNormally);
      expect(() => coordinator.onAppLifecycleStateChanged(AppLifecycleState.detached), returnsNormally);
      expect(() => coordinator.requestQuickLock(), returnsNormally);
    });

    test('underlying BLoC emissions after coordinator disposal do not trigger orphaned callbacks', () async {
      await coordinator.dispose();

      // Emit on sessionBloc, gestureEngineCubit, and settingsMutationCubit
      sessionBloc.add(const VaultQuickLockRequested());
      gestureEngineCubit.onPointerDown();
      await settingsMutationCubit.updateGeneralPolicy(
        settingsMutationCubit.currentConfig.copyWith(
          themePalette: VaultThemePalettePolicyEnum.forestNoir,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      // No crashes, no errors, subscriptions properly cancelled
      expect(coordinator.isDisposed, isTrue);
    });
  });
}
