import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
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

class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();
  GestureTemplate? template;
  int? persistedDeadlineMs;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    if (template != null) {
      return VaultResult.success(template!);
    }
    return const VaultResult.failure(VaultStorageFailure('Not enrolled'));
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => persistedDeadlineMs;

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    persistedDeadlineMs = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> sessionController =
      StreamController<VaultSessionState>.broadcast();

  bool keysClearedFromRam = false;
  int resetAttemptsCount = 0;
  int failedAttemptsRecorded = 0;

  @override
  Stream<VaultSessionState> get sessionStateStream => sessionController.stream;

  @override
  void clearSessionKeysFromRam() {
    keysClearedFromRam = true;
  }

  @override
  Future<void> resetFailedAttempts() async {
    resetAttemptsCount++;
  }

  @override
  Future<void> recordFailedAttempt() async {
    failedAttemptsRecorded++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeVaultAuthService fakeAuthService;
  late FakeVaultStorageRepository fakeStorage;
  late FakeMonotonicClock fakeClock;
  late VerifySessionCoolOffUseCase verifyCoolOffUseCase;
  late VaultSessionBloc bloc;

  final testSession = AuthSession(
    sessionToken: 'test_token',
    sessionStartedEpochMs: 10000,
    lastActiveEpochMs: 10000,
    authMethod: AuthMethodEnum.pin,
  );

  setUp(() {
    fakeAuthService = FakeVaultAuthService();
    fakeStorage = FakeVaultStorageRepository();
    fakeClock = FakeMonotonicClock();
    verifyCoolOffUseCase = VerifySessionCoolOffUseCase(clock: fakeClock);
    bloc = VaultSessionBloc(
      authService: fakeAuthService,
      storageRepository: fakeStorage,
      monotonicClock: fakeClock,
      verifyCoolOffUseCase: verifyCoolOffUseCase,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('VaultSessionBloc Lifecycle & Initialization', () {
    test('starts with VaultUninitializedState', () {
      expect(bloc.state, isA<VaultUninitializedState>());
    });

    test('initialize emits VaultUninitializedState if no template enrolled', () async {
      bloc.add(const VaultInitializeRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<VaultUninitializedState>());
    });

    test('initialize emits VaultLockedState if template is enrolled', () async {
      fakeStorage.template = DefaultGestureTemplate.canonicalVShape;

      bloc.add(const VaultInitializeRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<VaultLockedState>());
      final locked = bloc.state as VaultLockedState;
      expect(locked.lockedAtMonotonicMs, equals(10000));
    });

    test('initialize restores active lockout if monotonic deadline survives restart', () async {
      fakeStorage.template = DefaultGestureTemplate.canonicalVShape;
      fakeStorage.persistedDeadlineMs = 25000; // Future: 25000 > 10000

      bloc.add(const VaultInitializeRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<VaultLockoutCooldownState>());
      final lockout = bloc.state as VaultLockoutCooldownState;
      expect(lockout.deadlineMonotonicMs, equals(25000));
    });
  });

  group('Authentication Flow (Started, Succeeded, Failed, Canceled)', () {
    setUp(() async {
      fakeStorage.template = DefaultGestureTemplate.canonicalVShape;
      bloc.add(const VaultInitializeRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    test('VaultAuthStarted transitions from Locked to Authenticating', () async {
      bloc.add(const VaultAuthStarted(authSessionId: 'session_1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultAuthenticatingState>());
      final authState = bloc.state as VaultAuthenticatingState;
      expect(authState.authSessionId, equals('session_1'));
      expect(authState.attemptNumber, equals(1));
    });

    test('VaultAuthFailed updates attempt count in AuthenticatingState', () async {
      bloc.add(const VaultAuthStarted(authSessionId: 'session_1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const VaultAuthFailed(
        attemptNumber: 2,
        remainingAttemptsBeforeCooldown: 3,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final authState = bloc.state as VaultAuthenticatingState;
      expect(authState.attemptNumber, equals(2));
      expect(authState.remainingAttemptsBeforeCooldown, equals(3));
    });

    test('VaultAuthCanceled returns from Authenticating to Locked', () async {
      bloc.add(const VaultAuthStarted(authSessionId: 'session_1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const VaultAuthCanceled());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultLockedState>());
    });

    test('VaultAuthSucceeded transitions to VaultUnlockedState and schedules reauth timer', () async {
      bloc.add(const VaultAuthStarted(authSessionId: 'session_1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultUnlockedState>());
      final unlocked = bloc.state as VaultUnlockedState;
      expect(unlocked.session, equals(testSession));
      expect(unlocked.unlockedAtMonotonicMs, equals(10000));
      expect(unlocked.reauthDeadlineMonotonicMs, greaterThan(10000));
    });
  });

  group('Background Grace Countdown Timer', () {
    test('immediate grace timeout locks and clears RAM keys instantly on background', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.immediate,
      );
      bloc.add(VaultConfigUpdated(config: config));
      bloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultUnlockedState>());

      bloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultLockedState>());
      expect(fakeAuthService.keysClearedFromRam, isTrue);
    });

    test('non-immediate grace timeout enters BackgroundGraceState and restores on resume', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      bloc.add(VaultConfigUpdated(config: config));
      bloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultBackgroundGraceState>());
      final grace = bloc.state as VaultBackgroundGraceState;
      expect(grace.graceTimeoutMs, equals(30000));
      expect(grace.graceDeadlineMonotonicMs, equals(40000));

      // Resume within grace period
      fakeClock.timeMs = 20000; // 20s < 40s
      bloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultUnlockedState>());
      expect(fakeAuthService.keysClearedFromRam, isFalse);
    });

    test('resuming after grace deadline has elapsed locks session and clears keys', () async {
      final config = const VaultConfig.constant().copyWith(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      bloc.add(VaultConfigUpdated(config: config));
      bloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const VaultAppBackgrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Advance clock past deadline (40000)
      fakeClock.timeMs = 45000;
      bloc.add(const VaultAppForegrounded());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultLockedState>());
      expect(fakeAuthService.keysClearedFromRam, isTrue);
    });
  });

  group('Active Re-Auth Interval & Mid-Session Overlay', () {
    setUp(() async {
      bloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('reauth deadline elapsing transitions to PendingReauthState', () async {
      bloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultPendingReauthState>());
      final pending = bloc.state as VaultPendingReauthState;
      expect(pending.remainingAttempts, equals(3));
    });

    test('StepUpAuthSucceeded restores UnlockedState without route drop', () async {
      bloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(VaultStepUpAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultUnlockedState>());
    });

    test('StepUpAuthFailed decrements attempts and locks on exhaustion', () async {
      bloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 1st failure
      bloc.add(const VaultStepUpAuthFailed());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((bloc.state as VaultPendingReauthState).remainingAttempts, equals(2));

      // 2nd failure
      bloc.add(const VaultStepUpAuthFailed());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((bloc.state as VaultPendingReauthState).remainingAttempts, equals(1));

      // 3rd failure: exhaustion
      bloc.add(const VaultStepUpAuthFailed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultLockedState>());
      expect(fakeAuthService.keysClearedFromRam, isTrue);
    });

    test('StepUpAuthCanceled locks immediately and clears RAM keys', () async {
      bloc.add(const VaultReauthDeadlineElapsed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const VaultStepUpAuthCanceled());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultLockedState>());
      expect(fakeAuthService.keysClearedFromRam, isTrue);
    });
  });

  group('Manual Quick-Lock & Data Purge', () {
    test('VaultQuickLockRequested clears RAM keys and emits LockedState', () async {
      bloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const VaultQuickLockRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultLockedState>());
      expect(fakeAuthService.keysClearedFromRam, isTrue);
    });

    test('VaultPurged transitions to VaultUninitializedState', () async {
      bloc.add(VaultAuthSucceeded(session: testSession));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const VaultPurged());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<VaultUninitializedState>());
    });
  });
}
