import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';

/// Sub-Service 6: PIN Authentication Controller.
///
/// Governs digit entry (0..6), auto-submission on the 6th digit, layout arrangement
/// policies (standard ordered vs randomized per attempt), PBKDF2 isolate derivation,
/// tactile failure animations, and monotonic brute-force lockouts.
class PinPadCubit extends Cubit<PinPadState> {
  final UnlockVaultUseCase _unlockVaultUseCase;
  final IVaultAuthService _authService;
  final IMonotonicClock _monotonicClock;
  final VaultSessionBloc? _sessionBloc;
  KeypadLayoutPolicyEnum _keypadLayout;
  final Future<VaultResult<dynamic>> Function(String pin)? _customPinSubmitter;

  final List<int> _digits = <int>[];
  List<int> _currentKeypadDigits = const <int>[];
  Timer? _lockoutCountdownTimer;
  final Random _secureRandom;

  PinPadCubit({
    required UnlockVaultUseCase unlockVaultUseCase,
    required IVaultAuthService authService,
    required IMonotonicClock monotonicClock,
    VaultSessionBloc? sessionBloc,
    KeypadLayoutPolicyEnum initialLayout = KeypadLayoutPolicyEnum.standardOrdered,
    Future<VaultResult<dynamic>> Function(String pin)? customPinSubmitter,
    Random? secureRandom,
  })  : _unlockVaultUseCase = unlockVaultUseCase,
        _authService = authService,
        _monotonicClock = monotonicClock,
        _sessionBloc = sessionBloc,
        _keypadLayout = initialLayout,
        _customPinSubmitter = customPinSubmitter,
        _secureRandom = switch (secureRandom) {
          final rng? => rng,
          null => Random.secure(),
        },
        super(PinPadIdleInputState(
        enteredDigitsCount: 0,
        keypadLayout: initialLayout,
        digits: initialLayout == KeypadLayoutPolicyEnum.randomizedPerAttempt
            ? (List<int>.from(KeypadLayoutPolicyEnum.standardDigits)
          ..shuffle(switch (secureRandom) {
            final rng? => rng,
            null => Random.secure(),
          }))
            : KeypadLayoutPolicyEnum.standardDigits,
      )) {
    _regenerateKeypadDigits();
  }

  /// Current digit arrangement to display on the keypad buttons.
  List<int> get currentKeypadDigits => _currentKeypadDigits;

  /// Active layout policy.
  KeypadLayoutPolicyEnum get keypadLayout => _keypadLayout;

  /// Checks brute-force lockout status and enters lockout countdown if active.
  Future<void> checkLockoutStatus() async {
    final lockout = await _authService.getLockoutStatus();
    if (lockout.tier != LockoutCooldownTierEnum.none && lockout.remainingCooldownSeconds > 0) {
      _startLockoutCountdown(
        deadlineMonotonicMs: lockout.deadlineMonotonicMs,
        initialRemainingSeconds: lockout.remainingCooldownSeconds,
      );
    }
  }

  /// Instructs the cubit to enter lockout mode with the specified monotonic deadline.
  void enterLockout({
    required int deadlineMonotonicMs,
    int? initialRemainingSeconds,
  }) {
    final remainingMs = deadlineMonotonicMs - _monotonicClock.currentMonotonicMs;
    final remainingSec = switch (initialRemainingSeconds) {
      final sec? => sec,
      null => (remainingMs + 999) ~/ 1000,
    };
    if (remainingSec > 0) {
      _startLockoutCountdown(
        deadlineMonotonicMs: deadlineMonotonicMs,
        initialRemainingSeconds: remainingSec,
      );
    } else {
      _forceResetToIdle();
    }
  }

  /// Handles digit button taps from the user.
  ///
  /// Enforces digit bounds (0..9), length bounds (0..6), and initiates auto-submission
  /// upon capturing the 6th digit.
  void onDigitEntered(int digit) {
    if (state is! PinPadIdleInputState) {
      return;
    }
    if (digit < 0 || digit > 9) {
      return;
    }
    if (_digits.length >= 6) {
      return;
    }

    _digits.add(digit);

    if (_digits.length < 6) {
      emit(PinPadIdleInputState(
        enteredDigitsCount: _digits.length,
        keypadLayout: _keypadLayout,
        digits: _currentKeypadDigits,
      ));
    } else {
      emit(const PinPadEvaluatingState());
      _evaluatePin();
    }
  }

  /// Removes the most recently entered digit.
  void onBackspace() {
    if (state is! PinPadIdleInputState) {
      return;
    }
    if (_digits.isEmpty) {
      return;
    }

    _digits.removeLast();
    emit(PinPadIdleInputState(
      enteredDigitsCount: _digits.length,
      keypadLayout: _keypadLayout,
      digits: _currentKeypadDigits,
    ));
  }

  /// Clears all entered digits back to length 0.
  void clear() {
    if (state is! PinPadIdleInputState) {
      return;
    }
    _digits.clear();
    emit(PinPadIdleInputState(
      enteredDigitsCount: 0,
      keypadLayout: _keypadLayout,
      digits: _currentKeypadDigits,
    ));
  }

  /// Resets the controller back to [PinPadIdleInputState], regenerating layout if randomized.
  ///
  /// Protected against resetting while in [PinPadEvaluatingState] or [PinPadLockedOutState]
  /// to prevent premature cancellation of cryptographic evaluation or brute-force cooldowns.
  void resetToIdle() {
    if (state is PinPadLockedOutState || state is PinPadEvaluatingState) {
      return;
    }
    _forceResetToIdle();
  }

  void _forceResetToIdle() {
    _lockoutCountdownTimer?.cancel();
    _lockoutCountdownTimer = null;
    _digits.clear();
    _regenerateKeypadDigits();
    emit(PinPadIdleInputState(
      enteredDigitsCount: 0,
      keypadLayout: _keypadLayout,
      digits: _currentKeypadDigits,
    ));
  }

  /// Updates the keypad arrangement policy dynamically.
  void updateKeypadLayout(KeypadLayoutPolicyEnum newLayout) {
    _keypadLayout = newLayout;
    _regenerateKeypadDigits();
    if (state is PinPadIdleInputState) {
      emit(PinPadIdleInputState(
        enteredDigitsCount: _digits.length,
        keypadLayout: _keypadLayout,
        digits: _currentKeypadDigits,
      ));
    }
  }

  /// Evaluates the 6-digit PIN string via PBKDF2 derivation.
  Future<void> _evaluatePin() async {
    final pin = _digits.join();
    _digits.clear();

    final VaultResult<dynamic> result;
    final submitter = _customPinSubmitter;
    if (submitter != null) {
      result = await submitter(pin);
    } else {
      result = await _unlockVaultUseCase.execute(PinUnlockParams(pin));
    }

    if (isClosed) return;

    switch (result) {
      case VaultSuccess<dynamic>(:final data):
        final session = data is AuthSession ? data : null;
        if (session != null) {
          _sessionBloc?.add(VaultAuthSucceeded(session: session));
        }
        emit(PinPadSuccessState(session: session));
      case VaultFailureResult<dynamic>(:final failure):
        if (failure is VaultLockoutFailure) {
          final nowMs = _monotonicClock.currentMonotonicMs;
          _sessionBloc?.add(
            VaultLockoutTriggered(
              tier: failure.remainingCooldownSeconds > 30
                  ? LockoutCooldownTierEnum.tier2FiveMinutes
                  : LockoutCooldownTierEnum.tier1ThirtySeconds,
              cooldownStartedMonotonicMs: nowMs,
              durationMs: failure.remainingCooldownSeconds * 1000,
              deadlineMonotonicMs: failure.deadlineMonotonicMs,
              failedAttemptsCount: failure.remainingCooldownSeconds > 30 ? 10 : 5,
            ),
          );
          _startLockoutCountdown(
            deadlineMonotonicMs: failure.deadlineMonotonicMs,
            initialRemainingSeconds: failure.remainingCooldownSeconds,
          );
        } else {
          final remaining = switch (failure) {
            VaultAuthFailure(:final remainingAttempts) => remainingAttempts,
            VaultLockoutFailure() ||
            VaultCryptoFailure() ||
            VaultStorageFailure() ||
            VaultGestureFailure() ||
            VaultValidationFailure() =>
            0,
          };
          final lockout = await _authService.getLockoutStatus();
          if (isClosed) return;

          _sessionBloc?.add(
            VaultAuthFailed(
              attemptNumber: lockout.consecutiveFailedAttempts,
              remainingAttemptsBeforeCooldown: remaining,
            ),
          );
          emit(PinPadFailureShakeState(
            failedAttemptsCount: lockout.consecutiveFailedAttempts,
            remainingAttemptsBeforeCooldown: remaining,
          ));
        }
    }
  }

  /// Initiates the monotonic lockout countdown timer.
  void _startLockoutCountdown({
    required int deadlineMonotonicMs,
    required int initialRemainingSeconds,
  }) {
    _lockoutCountdownTimer?.cancel();

    emit(PinPadLockedOutState(
      cooldownRemainingSeconds: initialRemainingSeconds,
      deadlineMonotonicMs: deadlineMonotonicMs,
    ));

    _lockoutCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (isClosed) return;

      final remainingMs = deadlineMonotonicMs - _monotonicClock.currentMonotonicMs;
      final remainingSec = (remainingMs + 999) ~/ 1000;

      if (remainingSec <= 0) {
        _lockoutCountdownTimer?.cancel();
        _lockoutCountdownTimer = null;
        await _authService.resetFailedAttempts();
        _forceResetToIdle();
      } else {
        emit(PinPadLockedOutState(
          cooldownRemainingSeconds: remainingSec,
          deadlineMonotonicMs: deadlineMonotonicMs,
        ));
      }
    });
  }

  /// Regenerates digits layout according to [_keypadLayout].
  void _regenerateKeypadDigits() {
    switch (_keypadLayout) {
      case KeypadLayoutPolicyEnum.standardOrdered:
        _currentKeypadDigits = KeypadLayoutPolicyEnum.standardDigits;
      case KeypadLayoutPolicyEnum.randomizedPerAttempt:
        final shuffled = List<int>.from(KeypadLayoutPolicyEnum.standardDigits)
          ..shuffle(_secureRandom);
        _currentKeypadDigits = List<int>.unmodifiable(shuffled);
    }
  }

  @override
  Future<void> close() {
    _lockoutCountdownTimer?.cancel();
    _lockoutCountdownTimer = null;
    _digits.clear();
    return super.close();
  }
}
