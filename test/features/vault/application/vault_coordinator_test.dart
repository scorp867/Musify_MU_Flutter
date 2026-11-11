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
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeScreenPrivacyController implements IScreenPrivacyController {
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

class FakeGestureRecognizer implements IGestureRecognizer {
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

class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();
  GestureTemplate? template = DefaultGestureTemplate.canonicalVShape;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    config = newConfig;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async =>
      VaultResult.success(template ?? DefaultGestureTemplate.canonicalVShape);

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => null;

  @override
  Future<void> clearPersistedLockoutDeadline() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  bool keysCleared = false;

  @override
  Stream<VaultSessionState> get sessionStateStream => _sessionController.stream;

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
          sessionToken: 'test_token',
          sessionStartedEpochMs: 10000,
          lastActiveEpochMs: 10000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(VaultAuthFailure('Invalid PIN'));
  }

  @override
  Future<void> recordFailedAttempt() async {}

  @override
  Future<void> resetFailedAttempts() async {}

  @override
  void clearSessionKeysFromRam() {
    keysCleared = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeControlClient implements ContextPlayerControlClient {
  int stopCount = 0;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async => PlayerResponse.success;

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async => PlayerResponse.success;

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async =>
      PlayerResponse.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  final QueueModel _model = const QueueModel();
  final FakeControlClient _controlClient = FakeControlClient();

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

  @override
  void dispatch(QueueEvent event) {}

  @override
  void add(QueueEvent event) {}

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

  late FakeVaultAuthService fakeAuthService;
  late FakeVaultStorageRepository fakeStorage;
  late FakeMonotonicClock fakeClock;
  late FakeScreenPrivacyController fakePrivacyController;
  late FakeGestureRecognizer fakeGestureRecognizer;
  late FakeMobiusController fakeMobius;

  late VaultSessionBloc sessionBloc;
  late PlaybackPrivacyProxy playbackPrivacyProxy;
  late ScreenPrivacyCubit screenPrivacyCubit;
  late GestureEngineCubit gestureEngineCubit;
  late SettingsMutationCubit settingsMutationCubit;
  late PinPadCubit pinPadCubit;
  late VaultCoordinator coordinator;

  setUp(() {
    fakeAuthService = FakeVaultAuthService();
    fakeStorage = FakeVaultStorageRepository();
    fakeClock = FakeMonotonicClock();
    fakePrivacyController = FakeScreenPrivacyController();
    fakeGestureRecognizer = FakeGestureRecognizer();
    fakeMobius = FakeMobiusController();

    sessionBloc = VaultSessionBloc(
      authService: fakeAuthService,
      storageRepository: fakeStorage,
      monotonicClock: fakeClock,
      verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: fakeClock),
      initialState: const VaultLockedState(lockedAtMonotonicMs: 10000),
    );

    playbackPrivacyProxy = PlaybackPrivacyProxy(
      vaultAuthService: fakeAuthService,
      mobiusController: fakeMobius,
      storageRepository: fakeStorage,
      controlClient: fakeMobius.controlClient,
    );

    screenPrivacyCubit = ScreenPrivacyCubit(
      privacyController: fakePrivacyController,
      monotonicClock: fakeClock,
    );

    gestureEngineCubit = GestureEngineCubit(
      recognizer: fakeGestureRecognizer,
      storageRepository: fakeStorage,
      vaultAuthService: fakeAuthService,
    );

    settingsMutationCubit = SettingsMutationCubit(
      storageRepository: fakeStorage,
      mutateVaultConfigUseCase: MutateVaultConfigUseCase(
        authService: fakeAuthService,
        storageRepository: fakeStorage,
      ),
      authService: fakeAuthService,
      monotonicClock: fakeClock,
    );

    pinPadCubit = PinPadCubit(
      unlockVaultUseCase: UnlockVaultUseCase(authService: fakeAuthService),
      authService: fakeAuthService,
      monotonicClock: fakeClock,
    );

    coordinator = VaultCoordinator(
      sessionBloc: sessionBloc,
      playbackPrivacyProxy: playbackPrivacyProxy,
      screenPrivacyCubit: screenPrivacyCubit,
      gestureEngineCubit: gestureEngineCubit,
      settingsMutationCubit: settingsMutationCubit,
      pinPadCubit: pinPadCubit,
      monotonicClock: fakeClock,
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
    await fakeMobius.close();
  });

  group('VaultCoordinator Navigation Routing & Stealth Gesture', () {
    test('stealth gesture match while locked routes to unlockScreen', () async {
      final targets = <VaultNavigationTarget>[];
      final sub = coordinator.navigationStream.listen(targets.add);

      coordinator.onStealthGestureTriggered();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(targets.length, equals(1));
      expect(targets.first, equals(VaultNavigationTarget.unlockScreen));

      await sub.cancel();
    });

    test('stealth gesture match while unlocked routes to dashboardScreen', () async {
      final targets = <VaultNavigationTarget>[];
      final sub = coordinator.navigationStream.listen(targets.add);

      // Transition session to unlocked
      sessionBloc.add(
        VaultAuthSucceeded(
          session: AuthSession(
            sessionToken: 'token',
            sessionStartedEpochMs: 10000,
            lastActiveEpochMs: 10000,
            authMethod: AuthMethodEnum.pin,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Trigger gesture match
      coordinator.onStealthGestureTriggered();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(targets.length, equals(1));
      expect(targets.first, equals(VaultNavigationTarget.dashboardScreen));

      await sub.cancel();
    });
  });

  group('Session State Transitions Propagation', () {
    test('VaultSessionState.locked resets PinPadCubit to idle', () async {
      pinPadCubit.onDigitEntered(1);
      pinPadCubit.onDigitEntered(2);
      expect((pinPadCubit.state as PinPadIdleInputState).enteredDigitsCount, equals(2));

      sessionBloc.add(const VaultQuickLockRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(pinPadCubit.state, isA<PinPadIdleInputState>());
      expect((pinPadCubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });

    test('VaultSessionState.pendingReauth emits reauthOverlay navigation target', () async {
      final targets = <VaultNavigationTarget>[];
      final sub = coordinator.navigationStream.listen(targets.add);

      sessionBloc.add(
        VaultAuthSucceeded(
          session: AuthSession(
            sessionToken: 'token',
            sessionStartedEpochMs: 10000,
            lastActiveEpochMs: 10000,
            authMethod: AuthMethodEnum.pin,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      sessionBloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(targets.contains(VaultNavigationTarget.reauthOverlay), isTrue);

      await sub.cancel();
    });
  });

  group('App Lifecycle Integration', () {
    test('paused lifecycle event dispatches VaultAppBackgrounded and engages recents privacy', () async {
      sessionBloc.add(
        VaultAuthSucceeded(
          session: AuthSession(
            sessionToken: 'token',
            sessionStartedEpochMs: 10000,
            lastActiveEpochMs: 10000,
            authMethod: AuthMethodEnum.pin,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(screenPrivacyCubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded), isTrue);
    });

    test('detached lifecycle event dispatches quick lock', () async {
      sessionBloc.add(
        VaultAuthSucceeded(
          session: AuthSession(
            sessionToken: 'token',
            sessionStartedEpochMs: 10000,
            lastActiveEpochMs: 10000,
            authMethod: AuthMethodEnum.pin,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      coordinator.onAppLifecycleStateChanged(AppLifecycleState.detached);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultLockedState>());
    });
  });

  group('Manual Quick-Lock & Cross-Subsystem Config Sync', () {
    test('requestQuickLock locks session and resets pin pad', () async {
      pinPadCubit.onDigitEntered(7);

      coordinator.requestQuickLock();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect((pinPadCubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });

    test('settings config mutation propagates to PlaybackPrivacyProxy, ScreenPrivacy, and GestureEngine', () async {
      final updated = settingsMutationCubit.currentConfig.copyWith(
        gestureSensitivity: GestureSensitivityTierEnum.strict92Percent,
      );

      await settingsMutationCubit.updateGeneralPolicy(updated);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gestureEngineCubit.sensitivityTier, equals(GestureSensitivityTierEnum.strict92Percent));
      expect(playbackPrivacyProxy.cachedConfig.gestureSensitivity, equals(GestureSensitivityTierEnum.strict92Percent));
    });
  });
}
