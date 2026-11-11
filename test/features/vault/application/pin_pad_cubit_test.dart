import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  int consecutiveFailedAttempts = 0;
  LockoutCooldownTierEnum activeTier = LockoutCooldownTierEnum.none;
  int lockoutDeadlineMs = 0;

  @override
  Stream<VaultSessionState> get sessionStateStream => _sessionController.stream;

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async {
    final remainingSec = activeTier == LockoutCooldownTierEnum.none
        ? 0
        : max(0, (lockoutDeadlineMs - 10000) ~/ 1000);
    return LockoutCooldownInfo(
      tier: activeTier,
      remainingCooldownSeconds: remainingSec,
      deadlineMonotonicMs: lockoutDeadlineMs,
      consecutiveFailedAttempts: consecutiveFailedAttempts,
    );
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (activeTier != LockoutCooldownTierEnum.none) {
      return VaultResult.failure(
        VaultLockoutFailure(
          'Locked out',
          remainingCooldownSeconds: 30,
          deadlineMonotonicMs: lockoutDeadlineMs,
        ),
      );
    }

    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'valid_session',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }

    return const VaultResult.failure(VaultAuthFailure('Invalid PIN'));
  }

  @override
  Future<void> recordFailedAttempt() async {
    consecutiveFailedAttempts++;
    if (consecutiveFailedAttempts >= 5) {
      activeTier = LockoutCooldownTierEnum.tier1ThirtySeconds;
      lockoutDeadlineMs = 40000; // 10000 + 30000
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    consecutiveFailedAttempts = 0;
    activeTier = LockoutCooldownTierEnum.none;
    lockoutDeadlineMs = 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeVaultAuthService fakeAuthService;
  late FakeMonotonicClock fakeClock;
  late UnlockVaultUseCase unlockUseCase;
  late PinPadCubit cubit;

  setUp(() {
    fakeAuthService = FakeVaultAuthService();
    fakeClock = FakeMonotonicClock();
    unlockUseCase = UnlockVaultUseCase(authService: fakeAuthService);
    cubit = PinPadCubit(
      unlockVaultUseCase: unlockUseCase,
      authService: fakeAuthService,
      monotonicClock: fakeClock,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('PinPadCubit Lifecycle & Layout Policies', () {
    test('initial state is PinPadIdleInputState with 0 digits and standardOrdered layout', () {
      expect(cubit.state, isA<PinPadIdleInputState>());
      final idle = cubit.state as PinPadIdleInputState;
      expect(idle.enteredDigitsCount, equals(0));
      expect(idle.keypadLayout, equals(KeypadLayoutPolicyEnum.standardOrdered));
      expect(cubit.currentKeypadDigits, equals(KeypadLayoutPolicyEnum.standardDigits));
    });

    test('randomizedPerAttempt layout shuffles 10 digits without duplicates', () {
      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.randomizedPerAttempt);

      expect(cubit.keypadLayout, equals(KeypadLayoutPolicyEnum.randomizedPerAttempt));
      final digits = cubit.currentKeypadDigits;
      expect(digits.length, equals(10));
      expect(digits.toSet().length, equals(10));
      expect(digits.toSet(), equals({0, 1, 2, 3, 4, 5, 6, 7, 8, 9}));
    });

    test('updateKeypadLayout back to standardOrdered restores standard telephone layout', () {
      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.randomizedPerAttempt);
      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.standardOrdered);

      expect(cubit.currentKeypadDigits, equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));
    });
  });

  group('Input Operations (Digit Entry, Backspace, Clear, Bounds)', () {
    test('onDigitEntered increments enteredDigitsCount bounded to 6', () {
      cubit.onDigitEntered(1);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(1));

      cubit.onDigitEntered(2);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(2));

      cubit.onDigitEntered(3);
      cubit.onDigitEntered(4);
      cubit.onDigitEntered(5);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(5));
    });

    test('onDigitEntered ignores digits outside 0..9 range', () {
      cubit.onDigitEntered(-1);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      cubit.onDigitEntered(10);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });

    test('onBackspace decrements entered count and does not go below 0', () {
      cubit.onDigitEntered(5);
      cubit.onDigitEntered(8);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(2));

      cubit.onBackspace();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(1));

      cubit.onBackspace();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      cubit.onBackspace();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });

    test('clear resets entered count to 0', () {
      cubit.onDigitEntered(1);
      cubit.onDigitEntered(2);
      cubit.onDigitEntered(3);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(3));

      cubit.clear();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });

    test('resetToIdle resets buffer and regenerates layout', () {
      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.randomizedPerAttempt);
      cubit.onDigitEntered(4);

      cubit.resetToIdle();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
      expect(cubit.currentKeypadDigits.length, equals(10));
    });
  });

  group('Auto-Submission & Verification Lifecycle', () {
    test('entering 6th digit auto-submits and transitions to success on valid PIN', () async {
      final states = <PinPadState>[];
      final sub = cubit.stream.listen(states.add);

      // Enter 1 2 3 4 5 6
      cubit.onDigitEntered(1);
      cubit.onDigitEntered(2);
      cubit.onDigitEntered(3);
      cubit.onDigitEntered(4);
      cubit.onDigitEntered(5);
      cubit.onDigitEntered(6);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(states.any((s) => s is PinPadEvaluatingState), isTrue);
      expect(states.last, isA<PinPadSuccessState>());

      await sub.cancel();
    });

    test('entering invalid PIN triggers failure shake and remaining attempts decrement', () async {
      final states = <PinPadState>[];
      final sub = cubit.stream.listen(states.add);

      // Enter 6 5 4 3 2 1 (wrong)
      cubit.onDigitEntered(6);
      cubit.onDigitEntered(5);
      cubit.onDigitEntered(4);
      cubit.onDigitEntered(3);
      cubit.onDigitEntered(2);
      cubit.onDigitEntered(1);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(states.last, isA<PinPadFailureShakeState>());
      final failure = states.last as PinPadFailureShakeState;
      expect(failure.failedAttemptsCount, equals(1));
      expect(failure.remainingAttemptsBeforeCooldown, equals(4));

      await sub.cancel();
    });

    test('customPinSubmitter delegates evaluation and handles success', () async {
      bool customCalled = false;
      final customCubit = PinPadCubit(
        unlockVaultUseCase: unlockUseCase,
        authService: fakeAuthService,
        monotonicClock: fakeClock,
        customPinSubmitter: (pin) async {
          customCalled = true;
          return pin == '999999'
              ? const VaultResult.success(null)
              : const VaultResult.failure(VaultAuthFailure('Wrong custom PIN'));
        },
      );

      final states = <PinPadState>[];
      final sub = customCubit.stream.listen(states.add);

      for (var i = 0; i < 6; i++) {
        customCubit.onDigitEntered(9);
      }

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(customCalled, isTrue);
      expect(states.last, isA<PinPadSuccessState>());

      await sub.cancel();
      await customCubit.close();
    });
  });

  group('Brute-Force Lockout & Monotonic Countdown Timer', () {
    test('5 consecutive failures trigger PinPadLockedOutState with monotonic countdown', () async {
      fakeAuthService.consecutiveFailedAttempts = 4;

      final states = <PinPadState>[];
      final sub = cubit.stream.listen(states.add);

      // 5th failure
      for (var i = 0; i < 6; i++) {
        cubit.onDigitEntered(0);
      }

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(states.any((s) => s is PinPadLockedOutState), isTrue);
      final lockedOut = states.firstWhere((s) => s is PinPadLockedOutState) as PinPadLockedOutState;
      expect(lockedOut.cooldownRemainingSeconds, equals(30));
      expect(lockedOut.deadlineMonotonicMs, equals(40000));

      await sub.cancel();
    });

    test('enterLockout starts countdown and resets to idle when deadline expires', () async {
      final states = <PinPadState>[];
      final sub = cubit.stream.listen(states.add);

      // Lockout deadline 12000 ms (2 seconds from clock at 10000 ms)
      cubit.enterLockout(deadlineMonotonicMs: 12000, initialRemainingSeconds: 2);

      expect(cubit.state, isA<PinPadLockedOutState>());
      final lockedOut = cubit.state as PinPadLockedOutState;
      expect(lockedOut.cooldownRemainingSeconds, equals(2));

      // Advance clock past deadline
      fakeClock.timeMs = 13000;

      // Wait 1.1s for periodic timer to tick
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(cubit.state, isA<PinPadIdleInputState>());
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      await sub.cancel();
    });

    test('resetToIdle does not bypass active lockout', () {
      cubit.enterLockout(deadlineMonotonicMs: 40000, initialRemainingSeconds: 30);
      expect(cubit.state, isA<PinPadLockedOutState>());

      cubit.resetToIdle();
      expect(cubit.state, isA<PinPadLockedOutState>());
      final lockedOut = cubit.state as PinPadLockedOutState;
      expect(lockedOut.cooldownRemainingSeconds, equals(30));
    });
  });
}
