import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

/// Sealed event hierarchy driving David Harel Statechart Region A (VaultSessionBloc).
@immutable
sealed class VaultSessionEvent extends Equatable {
  const VaultSessionEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on app bootstrap to inspect enrollment and active lockout status.
@immutable
final class VaultInitializeRequested extends VaultSessionEvent {
  const VaultInitializeRequested();
}

/// Dispatched when the user opens the PIN pad or authentication screen.
@immutable
final class VaultAuthStarted extends VaultSessionEvent {
  final String authSessionId;

  const VaultAuthStarted({
    required this.authSessionId,
  });

  @override
  List<Object?> get props => [authSessionId];
}

/// Dispatched when authentication (PIN or Biometric) successfully derives keys and unwraps MVK.
@immutable
final class VaultAuthSucceeded extends VaultSessionEvent {
  final AuthSession session;

  const VaultAuthSucceeded({
    required this.session,
  });

  @override
  List<Object?> get props => [session];
}

/// Dispatched when an authentication attempt fails.
@immutable
final class VaultAuthFailed extends VaultSessionEvent {
  final int attemptNumber;
  final int remainingAttemptsBeforeCooldown;

  const VaultAuthFailed({
    required this.attemptNumber,
    required this.remainingAttemptsBeforeCooldown,
  });

  @override
  List<Object?> get props => [attemptNumber, remainingAttemptsBeforeCooldown];
}

/// Dispatched when user cancels or dismisses the authentication screen.
@immutable
final class VaultAuthCanceled extends VaultSessionEvent {
  const VaultAuthCanceled();
}

/// Dispatched when the application lifecycle transitions to paused or inactive.
@immutable
class VaultAppBackgrounded extends VaultSessionEvent {
  final int? pausedAtMonotonicMs;

  const VaultAppBackgrounded({this.pausedAtMonotonicMs});

  @override
  List<Object?> get props => [pausedAtMonotonicMs];
}

/// Dispatched when the application lifecycle transitions to resumed.
@immutable
class VaultAppForegrounded extends VaultSessionEvent {
  final int? resumedAtMonotonicMs;

  const VaultAppForegrounded({this.resumedAtMonotonicMs});

  @override
  List<Object?> get props => [resumedAtMonotonicMs];
}

/// Dispatched by the active re-auth timer when the cool-off deadline expires mid-session.
@immutable
final class VaultReauthDeadlineElapsed extends VaultSessionEvent {
  const VaultReauthDeadlineElapsed();
}

/// Dispatched when step-up re-authentication succeeds on the blurred overlay.
@immutable
final class VaultStepUpAuthSucceeded extends VaultSessionEvent {
  final AuthSession session;

  const VaultStepUpAuthSucceeded({
    required this.session,
  });

  @override
  List<Object?> get props => [session];
}

/// Dispatched when step-up re-authentication attempt fails.
@immutable
final class VaultStepUpAuthFailed extends VaultSessionEvent {
  const VaultStepUpAuthFailed();
}

/// Dispatched when user cancels step-up re-authentication.
@immutable
final class VaultStepUpAuthCanceled extends VaultSessionEvent {
  const VaultStepUpAuthCanceled();
}

/// Dispatched by the background grace countdown timer when the allowed window elapses.
@immutable
final class VaultGraceDeadlineElapsed extends VaultSessionEvent {
  const VaultGraceDeadlineElapsed();
}

/// Dispatched by the lockout timer when the brute-force cooldown period expires.
@immutable
final class VaultLockoutDeadlineElapsed extends VaultSessionEvent {
  const VaultLockoutDeadlineElapsed();
}

/// Dispatched when user taps the quick-lock action icon.
@immutable
class VaultQuickLockRequested extends VaultSessionEvent {
  final String? reason;

  const VaultQuickLockRequested({this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Dispatched when VaultConfig is mutated by SettingsMutationCubit.
@immutable
class VaultConfigUpdated extends VaultSessionEvent {
  final VaultConfig config;

  const VaultConfigUpdated({
    required this.config,
  });

  @override
  List<Object?> get props => [config];
}

/// Dispatched when underlying IVaultAuthService emits a session state transition.
@immutable
final class VaultServiceStateChanged extends VaultSessionEvent {
  final VaultSessionState serviceState;

  const VaultServiceStateChanged(this.serviceState);

  @override
  List<Object?> get props => [serviceState];
}

/// Dispatched when destructive data purge completes, returning state to uninitialized.
@immutable
final class VaultPurged extends VaultSessionEvent {
  const VaultPurged();
}

/// Dispatched when the stealth gesture matches on an uninitialized vault,
/// initiating the first-time PIN creation setup flow.
@immutable
final class VaultSetupRequested extends VaultSessionEvent {
  const VaultSetupRequested();
}

/// Dispatched when the user cancels the first-time setup flow.
@immutable
final class VaultSetupCanceled extends VaultSessionEvent {
  const VaultSetupCanceled();
}

/// Convenient aliases for coordinator integration
typedef VaultSessionAppPausedEvent = VaultAppBackgrounded;
typedef VaultSessionAppResumedEvent = VaultAppForegrounded;
typedef VaultSessionLockRequestedEvent = VaultQuickLockRequested;
typedef VaultSessionConfigUpdatedEvent = VaultConfigUpdated;

/// Harel Statechart Region A Root Security Authority governing the Private Vault lifecycle.
///
/// Coordinates session transitions, background grace timeouts, active re-auth cool-offs,
/// persistent brute-force lockout countdowns, and RAM key buffer wiping.
class VaultSessionBloc extends Bloc<VaultSessionEvent, VaultSessionState> {
  final IVaultAuthService _authService;
  final IVaultStorageRepository _storageRepository;
  final IMonotonicClock _monotonicClock;
  final VerifySessionCoolOffUseCase _verifyCoolOffUseCase;

  VaultConfig _config;
  StreamSubscription<VaultSessionState>? _authServiceSubscription;
  Timer? _graceTimer;
  Timer? _reauthTimer;
  Timer? _lockoutTimer;

  VaultSessionBloc({
    required IVaultAuthService authService,
    required IVaultStorageRepository storageRepository,
    required IMonotonicClock monotonicClock,
    required VerifySessionCoolOffUseCase verifyCoolOffUseCase,
    VaultConfig initialConfig = const VaultConfig.constant(),
    VaultSessionState initialState = const VaultUninitializedState(),
  })  : _authService = authService,
        _storageRepository = storageRepository,
        _monotonicClock = monotonicClock,
        _verifyCoolOffUseCase = verifyCoolOffUseCase,
        _config = initialConfig,
        super(initialState) {
    on<VaultInitializeRequested>(_onInitializeRequested, transformer: sequential());
    on<VaultAuthStarted>(_onAuthStarted, transformer: sequential());
    on<VaultAuthSucceeded>(_onAuthSucceeded, transformer: sequential());
    on<VaultAuthFailed>(_onAuthFailed, transformer: sequential());
    on<VaultAuthCanceled>(_onAuthCanceled, transformer: sequential());
    on<VaultAppBackgrounded>(_onAppBackgrounded, transformer: sequential());
    on<VaultAppForegrounded>(_onAppForegrounded, transformer: sequential());
    on<VaultReauthDeadlineElapsed>(_onReauthDeadlineElapsed, transformer: sequential());
    on<VaultStepUpAuthSucceeded>(_onStepUpAuthSucceeded, transformer: sequential());
    on<VaultStepUpAuthFailed>(_onStepUpAuthFailed, transformer: sequential());
    on<VaultStepUpAuthCanceled>(_onStepUpAuthCanceled, transformer: sequential());
    on<VaultGraceDeadlineElapsed>(_onGraceDeadlineElapsed, transformer: sequential());
    on<VaultLockoutDeadlineElapsed>(_onLockoutDeadlineElapsed, transformer: sequential());
    on<VaultQuickLockRequested>(_onQuickLockRequested, transformer: sequential());
    on<VaultConfigUpdated>(_onConfigUpdated, transformer: sequential());
    on<VaultServiceStateChanged>(_onServiceStateChanged, transformer: sequential());
    on<VaultPurged>(_onPurged, transformer: sequential());
    on<VaultSetupRequested>(_onSetupRequested, transformer: sequential());
    on<VaultSetupCanceled>(_onSetupCanceled, transformer: sequential());

    _authServiceSubscription = _authService.sessionStateStream.listen((serviceState) {
      add(VaultServiceStateChanged(serviceState));
    });
  }

  /// Current cached vault configuration.
  VaultConfig get config => _config;

  Future<void> _onInitializeRequested(
    VaultInitializeRequested event,
    Emitter<VaultSessionState> emit,
  ) async {
    final nowMs = _monotonicClock.currentMonotonicMs;

    final configResult = await _storageRepository.loadVaultConfig();
    switch (configResult) {
      case VaultSuccess<VaultConfig>(data: final loadedConfig):
        _config = loadedConfig;
      case VaultFailureResult<VaultConfig>():
        break;
    }

    final persistedDeadline = await _storageRepository.getPersistedLockoutDeadlineMs();
    if (persistedDeadline case final deadline?) {
      if (deadline > nowMs) {
        final remainingMs = deadline - nowMs;
        final tier = remainingMs > 30000
            ? LockoutCooldownTierEnum.tier2FiveMinutes
            : LockoutCooldownTierEnum.tier1ThirtySeconds;

        _scheduleLockoutTimer(remainingMs);
        emit(
          VaultLockoutCooldownState(
            tier: tier,
            cooldownStartedMonotonicMs: nowMs,
            durationMs: tier.durationMs,
            deadlineMonotonicMs: deadline,
            failedAttemptsCount: tier.thresholdAttempts,
          ),
        );
        return;
      } else {
        await _storageRepository.clearPersistedLockoutDeadline();
        await _authService.resetFailedAttempts();
      }
    }

    final templateResult = await _storageRepository.loadGestureTemplate();
    switch (templateResult) {
      case VaultSuccess():
        emit(VaultLockedState(lockedAtMonotonicMs: nowMs));
      case VaultFailureResult():
        emit(const VaultUninitializedState());
    }
  }

  void _onAuthStarted(
    VaultAuthStarted event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultLockedState) {
      emit(
        VaultAuthenticatingState(
          authSessionId: event.authSessionId,
          attemptNumber: 1,
          remainingAttemptsBeforeCooldown: 5,
        ),
      );
    }
  }

  void _onAuthSucceeded(
    VaultAuthSucceeded event,
    Emitter<VaultSessionState> emit,
  ) {
    _cancelAllTimers();
    final nowMs = _monotonicClock.currentMonotonicMs;
    final reauthDeadline = _calculateReauthDeadline(nowMs);

    emit(
      VaultUnlockedState(
        session: event.session,
        unlockedAtMonotonicMs: nowMs,
        reauthDeadlineMonotonicMs: reauthDeadline,
      ),
    );

    _scheduleReauthTimer(reauthDeadline - nowMs);
  }

  void _onAuthFailed(
    VaultAuthFailed event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultAuthenticatingState) {
      emit(
        VaultAuthenticatingState(
          authSessionId: (state as VaultAuthenticatingState).authSessionId,
          attemptNumber: event.attemptNumber,
          remainingAttemptsBeforeCooldown: event.remainingAttemptsBeforeCooldown,
        ),
      );
    }
  }

  void _onAuthCanceled(
    VaultAuthCanceled event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultAuthenticatingState) {
      emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
    }
  }

  void _onAppBackgrounded(
    VaultAppBackgrounded event,
    Emitter<VaultSessionState> emit,
  ) {
    final currentState = state;
    if (currentState is! VaultActiveSessionState) {
      if (currentState is VaultAuthenticatingState) {
        emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
      } else if (currentState is VaultProvisioningState) {
        emit(const VaultUninitializedState());
      }
      return;
    }

    _cancelReauthTimer();

    if (_config.backgroundGraceTimeout.isImmediate) {
      _cancelAllTimers();
      _authService.clearSessionKeysFromRam();
      emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
      return;
    }

    final nowMs = _monotonicClock.currentMonotonicMs;
    final timeoutMs = _config.backgroundGraceTimeout.milliseconds;
    final deadlineMs = nowMs + timeoutMs;

    emit(
      VaultBackgroundGraceState(
        session: currentState.session,
        enteredBackgroundMonotonicMs: nowMs,
        graceTimeoutMs: timeoutMs,
        graceDeadlineMonotonicMs: deadlineMs,
      ),
    );

    _scheduleGraceTimer(timeoutMs);
  }

  void _onAppForegrounded(
    VaultAppForegrounded event,
    Emitter<VaultSessionState> emit,
  ) {
    final currentState = state;
    final nowMs = _monotonicClock.currentMonotonicMs;

    if (currentState is VaultBackgroundGraceState) {
      _cancelGraceTimer();

      if (nowMs >= currentState.graceDeadlineMonotonicMs) {
        _authService.clearSessionKeysFromRam();
        emit(VaultLockedState(lockedAtMonotonicMs: nowMs));
        return;
      }

      final decisionResult = _verifyCoolOffUseCase.execute(
        VerifyCoolOffParams(currentState: currentState, config: _config),
      );

      switch (decisionResult) {
        case VaultSuccess(data: CoolOffDecisionEnum.graceExpiredLock):
          _authService.clearSessionKeysFromRam();
          emit(VaultLockedState(lockedAtMonotonicMs: nowMs));
          return;
        case VaultSuccess(data: CoolOffDecisionEnum.sessionValid):
        case VaultSuccess(data: CoolOffDecisionEnum.reauthRequired):
        case VaultSuccess(data: CoolOffDecisionEnum.lockoutElapsedReset):
        case VaultSuccess(data: CoolOffDecisionEnum.lockoutActive):
        case VaultFailureResult():
          break;
      }

      final reauthDeadline = _calculateReauthDeadline(nowMs);
      emit(
        VaultUnlockedState(
          session: currentState.session,
          unlockedAtMonotonicMs: nowMs,
          reauthDeadlineMonotonicMs: reauthDeadline,
        ),
      );
      _scheduleReauthTimer(reauthDeadline - nowMs);
    } else if (currentState is VaultLockoutCooldownState) {
      if (nowMs >= currentState.deadlineMonotonicMs) {
        _cancelLockoutTimer();
        unawaited(_storageRepository.clearPersistedLockoutDeadline());
        unawaited(_authService.resetFailedAttempts());
        emit(VaultLockedState(lockedAtMonotonicMs: nowMs));
      }
    }
  }

  void _onReauthDeadlineElapsed(
    VaultReauthDeadlineElapsed event,
    Emitter<VaultSessionState> emit,
  ) {
    final currentState = state;
    if (currentState is VaultUnlockedState) {
      emit(
        VaultPendingReauthState(
          session: currentState.session,
          reauthTriggeredAtMonotonicMs: _monotonicClock.currentMonotonicMs,
          remainingAttempts: 3,
        ),
      );
    }
  }

  void _onStepUpAuthSucceeded(
    VaultStepUpAuthSucceeded event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultPendingReauthState) {
      final nowMs = _monotonicClock.currentMonotonicMs;
      final reauthDeadline = _calculateReauthDeadline(nowMs);

      emit(
        VaultUnlockedState(
          session: event.session,
          unlockedAtMonotonicMs: nowMs,
          reauthDeadlineMonotonicMs: reauthDeadline,
        ),
      );

      _scheduleReauthTimer(reauthDeadline - nowMs);
    }
  }

  void _onStepUpAuthFailed(
    VaultStepUpAuthFailed event,
    Emitter<VaultSessionState> emit,
  ) {
    final currentState = state;
    if (currentState is VaultPendingReauthState) {
      final updatedRemaining = currentState.remainingAttempts - 1;
      if (updatedRemaining <= 0) {
        _cancelAllTimers();
        _authService.clearSessionKeysFromRam();
        unawaited(_authService.recordFailedAttempt());
        emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
      } else {
        emit(currentState.copyWith(remainingAttempts: updatedRemaining));
      }
    }
  }

  void _onStepUpAuthCanceled(
    VaultStepUpAuthCanceled event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultPendingReauthState) {
      _cancelAllTimers();
      _authService.clearSessionKeysFromRam();
      emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
    }
  }

  void _onGraceDeadlineElapsed(
    VaultGraceDeadlineElapsed event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultBackgroundGraceState) {
      _cancelAllTimers();
      _authService.clearSessionKeysFromRam();
      emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
    }
  }

  Future<void> _onLockoutDeadlineElapsed(
    VaultLockoutDeadlineElapsed event,
    Emitter<VaultSessionState> emit,
  ) async {
    if (state is VaultLockoutCooldownState) {
      _cancelLockoutTimer();
      await _storageRepository.clearPersistedLockoutDeadline();
      await _authService.resetFailedAttempts();
      emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
    }
  }

  void _onQuickLockRequested(
    VaultQuickLockRequested event,
    Emitter<VaultSessionState> emit,
  ) {
    _cancelAllTimers();
    _authService.clearSessionKeysFromRam();
    emit(VaultLockedState(lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs));
  }

  void _onConfigUpdated(
    VaultConfigUpdated event,
    Emitter<VaultSessionState> emit,
  ) {
    _config = event.config;
    final currentState = state;
    final nowMs = _monotonicClock.currentMonotonicMs;

    if (currentState is VaultUnlockedState) {
      _cancelReauthTimer();
      final newDeadline = _calculateReauthDeadline(nowMs);
      emit(currentState.copyWith(reauthDeadlineMonotonicMs: newDeadline));
      _scheduleReauthTimer(newDeadline - nowMs);
    }
  }

  void _onServiceStateChanged(
    VaultServiceStateChanged event,
    Emitter<VaultSessionState> emit,
  ) {
    final nextState = event.serviceState;
    switch (nextState) {
      case VaultUnlockedState():
        _cancelAllTimers();
        final nowMs = _monotonicClock.currentMonotonicMs;
        final deadline = _calculateReauthDeadline(nowMs);
        emit(
          VaultUnlockedState(
            session: nextState.session,
            unlockedAtMonotonicMs: nowMs,
            reauthDeadlineMonotonicMs: deadline,
          ),
        );
        _scheduleReauthTimer(deadline - nowMs);

      case VaultLockoutCooldownState():
        _cancelAllTimers();
        final nowMs = _monotonicClock.currentMonotonicMs;
        final remainingMs = nextState.deadlineMonotonicMs - nowMs;
        _scheduleLockoutTimer(remainingMs);
        emit(nextState);

      case VaultLockedState():
        _cancelAllTimers();
        emit(nextState);

      case VaultAuthenticatingState():
        emit(nextState);

      case VaultUninitializedState():
        _cancelAllTimers();
        emit(nextState);

      case VaultProvisioningState():
        emit(nextState);

      case VaultBackgroundGraceState():
      case VaultPendingReauthState():
        emit(nextState);
    }
  }

  void _onPurged(
    VaultPurged event,
    Emitter<VaultSessionState> emit,
  ) {
    _cancelAllTimers();
    emit(const VaultUninitializedState());
  }

  void _onSetupRequested(
    VaultSetupRequested event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultUninitializedState) {
      emit(const VaultProvisioningState());
    }
  }

  void _onSetupCanceled(
    VaultSetupCanceled event,
    Emitter<VaultSessionState> emit,
  ) {
    if (state is VaultProvisioningState) {
      emit(const VaultUninitializedState());
    }
  }

  int _calculateReauthDeadline(int nowMs) {
    final intervalMs = _config.activeReauthInterval.milliseconds;
    if (intervalMs == null) {
      return 0;
    }
    return nowMs + intervalMs;
  }

  void _scheduleReauthTimer(int delayMs) {
    _cancelReauthTimer();
    if (delayMs > 0 && _config.activeReauthInterval != ActiveReauthIntervalEnum.never) {
      _reauthTimer = Timer(Duration(milliseconds: delayMs), () {
        add(const VaultReauthDeadlineElapsed());
      });
    }
  }

  void _scheduleGraceTimer(int delayMs) {
    _cancelGraceTimer();
    if (delayMs > 0) {
      _graceTimer = Timer(Duration(milliseconds: delayMs), () {
        add(const VaultGraceDeadlineElapsed());
      });
    }
  }

  void _scheduleLockoutTimer(int delayMs) {
    _cancelLockoutTimer();
    if (delayMs > 0) {
      _lockoutTimer = Timer(Duration(milliseconds: delayMs), () {
        add(const VaultLockoutDeadlineElapsed());
      });
    }
  }

  void _cancelReauthTimer() {
    _reauthTimer?.cancel();
    _reauthTimer = null;
  }

  void _cancelGraceTimer() {
    _graceTimer?.cancel();
    _graceTimer = null;
  }

  void _cancelLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
  }

  void _cancelAllTimers() {
    _cancelReauthTimer();
    _cancelGraceTimer();
    _cancelLockoutTimer();
  }

  @override
  Future<void> close() {
    _cancelAllTimers();
    _authServiceSubscription?.cancel();
    return super.close();
  }
}
