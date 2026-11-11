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

class StressMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class StressVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  int consecutiveFailedAttempts = 0;
  LockoutCooldownTierEnum activeTier = LockoutCooldownTierEnum.none;
  int lockoutDeadlineMs = 0;
  int resetAttemptsCallCount = 0;

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
          'Account locked out due to excessive failed attempts',
          remainingCooldownSeconds: 30,
          deadlineMonotonicMs: lockoutDeadlineMs,
        ),
      );
    }

    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'valid_session_token',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }

    return const VaultResult.failure(VaultAuthFailure('Invalid PIN entered'));
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
    resetAttemptsCallCount++;
    consecutiveFailedAttempts = 0;
    activeTier = LockoutCooldownTierEnum.none;
    lockoutDeadlineMs = 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StressVaultAuthService authService;
  late StressMonotonicClock clock;
  late UnlockVaultUseCase unlockUseCase;
  late PinPadCubit cubit;

  setUp(() {
    authService = StressVaultAuthService();
    clock = StressMonotonicClock();
    unlockUseCase = UnlockVaultUseCase(authService: authService);
    cubit = PinPadCubit(
      unlockVaultUseCase: unlockUseCase,
      authService: authService,
      monotonicClock: clock,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('Stress 1: Rapid Tapping (>6 Digits) & Length Bounds', () {
    test('100 rapid digit taps strictly cap at 6 digits and submit exactly first 6', () async {
      String? submittedPin;
      final recordingCubit = PinPadCubit(
        unlockVaultUseCase: unlockUseCase,
        authService: authService,
        monotonicClock: clock,
        customPinSubmitter: (pin) async {
          submittedPin = pin;
          return const VaultResult.success(null);
        },
      );

      final stateHistory = <PinPadState>[];
      final sub = recordingCubit.stream.listen(stateHistory.add);

      // Rapidly fire 100 taps: 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2...
      for (var i = 0; i < 100; i++) {
        recordingCubit.onDigitEntered((i % 10));
      }

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Assert submitted PIN is strictly the first 6 digits: '012345'
      expect(submittedPin, equals('012345'));

      // Assert enteredDigitsCount never exceeded 6 across all emitted states
      for (final state in stateHistory) {
        if (state is PinPadIdleInputState) {
          expect(state.enteredDigitsCount, inInclusiveRange(0, 6));
        }
      }

      expect(recordingCubit.state, isA<PinPadSuccessState>());

      await sub.cancel();
      await recordingCubit.close();
    });

    test('Rapid interleaved burst of taps, backspaces, and clears preserves exact counter', () {
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      // 5 taps
      for (var i = 1; i <= 5; i++) {
        cubit.onDigitEntered(i);
      }
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(5));

      // 3 backspaces
      cubit.onBackspace();
      cubit.onBackspace();
      cubit.onBackspace();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(2));

      // 10 redundant backspaces beyond 0
      for (var i = 0; i < 10; i++) {
        cubit.onBackspace();
      }
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      // Clear on empty
      cubit.clear();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      // Enter 4 digits, then clear
      cubit.onDigitEntered(1);
      cubit.onDigitEntered(2);
      cubit.onDigitEntered(3);
      cubit.onDigitEntered(4);
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(4));
      cubit.clear();
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });
  });

  group('Stress 2: Concurrency & Taps During In-Flight PBKDF2 Derivation', () {
    test('All taps, backspaces, and clears are dropped during in-flight evaluation', () async {
      final derivationCompleter = Completer<VaultResult<dynamic>>();

      final derivingCubit = PinPadCubit(
        unlockVaultUseCase: unlockUseCase,
        authService: authService,
        monotonicClock: clock,
        customPinSubmitter: (pin) => derivationCompleter.future,
      );

      final stateTransitions = <PinPadState>[];
      final sub = derivingCubit.stream.listen(stateTransitions.add);

      // Enter 6 digits to trigger derivation
      for (var i = 1; i <= 6; i++) {
        derivingCubit.onDigitEntered(i);
      }

      expect(derivingCubit.state, isA<PinPadEvaluatingState>());
      final countAtEvaluating = stateTransitions.length;

      // While derivation is in-flight: hammer with 50 digit taps, backspaces, and clears
      for (var i = 0; i < 50; i++) {
        derivingCubit.onDigitEntered(i % 10);
        derivingCubit.onBackspace();
        derivingCubit.clear();
      }

      // No new states should have been emitted while evaluating
      expect(stateTransitions.length, equals(countAtEvaluating));
      expect(derivingCubit.state, isA<PinPadEvaluatingState>());

      // Attempt to reset to idle while evaluating: MUST be ignored
      derivingCubit.resetToIdle();
      expect(derivingCubit.state, isA<PinPadEvaluatingState>());

      // Complete derivation successfully
      derivationCompleter.complete(const VaultResult.success(null));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(derivingCubit.state, isA<PinPadSuccessState>());

      await sub.cancel();
      await derivingCubit.close();
    });

    test('In-flight evaluation failure transitions to FailureShakeState and ignores concurrent taps', () async {
      final derivationCompleter = Completer<VaultResult<dynamic>>();

      final derivingCubit = PinPadCubit(
        unlockVaultUseCase: unlockUseCase,
        authService: authService,
        monotonicClock: clock,
        customPinSubmitter: (pin) => derivationCompleter.future,
      );

      for (var i = 1; i <= 6; i++) {
        derivingCubit.onDigitEntered(i);
      }
      expect(derivingCubit.state, isA<PinPadEvaluatingState>());

      // Fail derivation with auth failure
      derivationCompleter.complete(
        const VaultResult.failure(VaultAuthFailure('Incorrect PIN', remainingAttempts: 4)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(derivingCubit.state, isA<PinPadFailureShakeState>());
      final shakeState = derivingCubit.state as PinPadFailureShakeState;
      expect(shakeState.remainingAttemptsBeforeCooldown, equals(4));

      // While in failure shake state: taps should be ignored until resetToIdle
      derivingCubit.onDigitEntered(5);
      expect(derivingCubit.state, isA<PinPadFailureShakeState>());

      // Reset to idle restores input capability
      derivingCubit.resetToIdle();
      expect(derivingCubit.state, isA<PinPadIdleInputState>());
      expect((derivingCubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      await derivingCubit.close();
    });
  });

  group('Stress 3: Randomized Layout Oracle & Permutation Entropy', () {
    test('500 layout generations guarantee 0 duplicates and all 10 digits (0..9) present', () {
      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.randomizedPerAttempt);

      final expectedDigits = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
      final observedFirstDigits = <int>{};

      const sampleSize = 500;
      for (var i = 0; i < sampleSize; i++) {
        cubit.resetToIdle();
        final layout = cubit.currentKeypadDigits;

        // Invariant 1: Exactly 10 digits
        expect(layout.length, equals(10), reason: 'Layout must always have 10 buttons');

        // Invariant 2: 0 duplicates
        expect(layout.toSet().length, equals(10), reason: 'Layout must contain 0 duplicates');

        // Invariant 3: Contains all digits 0 through 9
        expect(layout.toSet(), equals(expectedDigits), reason: 'Layout must contain digits 0..9');

        observedFirstDigits.add(layout.first);
      }

      // Statistical entropy: Over 500 random shuffles, at least 8 distinct digits should appear in position 0
      expect(observedFirstDigits.length, greaterThanOrEqualTo(8),
          reason: 'Random layout generator must exhibit non-degenerate permutation entropy.');
    });

    test('UI button index to digit mapping reflects current randomized layout', () {
      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.randomizedPerAttempt);
      final activeLayout = cubit.currentKeypadDigits;

      // Simulate user clicking button at visual index 3
      final mappedDigit = activeLayout[3];
      cubit.onDigitEntered(mappedDigit);

      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(1));
    });
  });

  group('Stress 4: Monotonic Lockout Countdown & Auto-Recovery', () {
    test('Monotonic countdown strictly decreases without upward jumps or negative values', () async {
      final recordedRemainingSeconds = <int>[];
      final sub = cubit.stream.listen((state) {
        if (state is PinPadLockedOutState) {
          recordedRemainingSeconds.add(state.cooldownRemainingSeconds);
        }
      });

      // Enter lockout: 4 seconds remaining (deadline = 14000 ms at clock = 10000 ms)
      cubit.enterLockout(deadlineMonotonicMs: 14000, initialRemainingSeconds: 4);

      // Advance clock tick by tick and let timer fire
      for (var s = 0; s < 3; s++) {
        clock.timeMs += 1000;
        await Future<void>.delayed(const Duration(milliseconds: 1050));
      }

      // Advance past deadline to complete
      clock.timeMs = 15000;
      await Future<void>.delayed(const Duration(milliseconds: 1050));

      // Assert auto-recovery to idle
      expect(cubit.state, isA<PinPadIdleInputState>());
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
      expect(authService.resetAttemptsCallCount, equals(1));

      // Invariant: countdown sequence strictly decreases monotonically
      for (var i = 0; i < recordedRemainingSeconds.length - 1; i++) {
        expect(
          recordedRemainingSeconds[i],
          greaterThanOrEqualTo(recordedRemainingSeconds[i + 1]),
          reason: 'Countdown must be strictly monotonic non-increasing',
        );
        expect(
          recordedRemainingSeconds[i],
          greaterThan(0),
          reason: 'Cooldown remaining seconds must remain positive until expiry',
        );
      }

      await sub.cancel();
    });

    test('Entering lockout with already expired deadline immediately resets to idle', () {
      // Clock is at 10000, deadline in past: 9000
      cubit.enterLockout(deadlineMonotonicMs: 9000);

      expect(cubit.state, isA<PinPadIdleInputState>());
      expect((cubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));
    });

    test('Digit entry is completely blocked during active lockout', () {
      cubit.enterLockout(deadlineMonotonicMs: 20000, initialRemainingSeconds: 10);
      expect(cubit.state, isA<PinPadLockedOutState>());

      // Attempt digit entry, backspace, and clear
      cubit.onDigitEntered(1);
      cubit.onBackspace();
      cubit.clear();

      // State remains locked out
      expect(cubit.state, isA<PinPadLockedOutState>());
    });

    test('resetToIdle does not cancel active lockout or bypass deadline', () {
      // Enter lockout with 30 seconds remaining
      cubit.enterLockout(deadlineMonotonicMs: 40000, initialRemainingSeconds: 30);
      expect(cubit.state, isA<PinPadLockedOutState>());

      // Calling resetToIdle while in lockout must be ignored to protect the cooldown
      cubit.resetToIdle();

      expect(
        cubit.state,
        isA<PinPadLockedOutState>(),
        reason: 'resetToIdle is guarded and cannot circumvent PinPadLockedOutState.',
      );
      final lockedOut = cubit.state as PinPadLockedOutState;
      expect(lockedOut.cooldownRemainingSeconds, equals(30));
    });

    test('Closing cubit during active lockout cleanly disposes timer without leaking or throwing', () async {
      cubit.enterLockout(deadlineMonotonicMs: 30000, initialRemainingSeconds: 20);
      expect(cubit.state, isA<PinPadLockedOutState>());

      // Close cubit while periodic timer is ticking
      await cubit.close();

      // Advance clock and wait
      clock.timeMs += 5000;
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(cubit.isClosed, isTrue);
    });
  });
}
